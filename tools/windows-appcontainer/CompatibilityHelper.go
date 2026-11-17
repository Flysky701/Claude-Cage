//go:build ignore

// A native test-only helper: verify child tokens without depending on the CLR.
package main

import (
	"fmt"
	"os"
	"os/exec"
	"syscall"
	"unsafe"
)

var advapi = syscall.NewLazyDLL("advapi32.dll")
var kernel = syscall.NewLazyDLL("kernel32.dll")

//go:uintptrescapes
func call(proc *syscall.LazyProc, args ...uintptr) error {
	r, _, e := proc.Call(args...)
	if r == 0 {
		return fmt.Errorf("%s: %w", proc.Name, e)
	}
	return nil
}

func sidString(sid uintptr) (string, error) {
	var text *uint16
	if err := call(advapi.NewProc("ConvertSidToStringSidW"), sid, uintptr(unsafe.Pointer(&text))); err != nil {
		return "", err
	}
	defer kernel.NewProc("LocalFree").Call(uintptr(unsafe.Pointer(text)))
	return syscall.UTF16ToString(unsafe.Slice(text, 256)), nil
}

func access(token syscall.Handle, user, principal string) (bool, error) {
	var duplicate syscall.Handle
	if err := call(advapi.NewProc("DuplicateToken"), uintptr(token), 2, uintptr(unsafe.Pointer(&duplicate))); err != nil {
		return false, err
	}
	defer syscall.CloseHandle(duplicate)
	sddl, err := syscall.UTF16PtrFromString("O:" + user + "G:" + user + "D:(A;;0x1;;;" + user + ")(A;;0x1;;;" + principal + ")")
	if err != nil {
		return false, err
	}
	var descriptor uintptr
	var length uint32
	if err := call(advapi.NewProc("ConvertStringSecurityDescriptorToSecurityDescriptorW"), uintptr(unsafe.Pointer(sddl)), 1, uintptr(unsafe.Pointer(&descriptor)), uintptr(unsafe.Pointer(&length))); err != nil {
		return false, err
	}
	defer kernel.NewProc("LocalFree").Call(descriptor)
	mapping := [4]uint32{1, 2, 4, 7}
	privileges := [1024]byte{}
	size := uint32(len(privileges))
	var granted, allowed uint32
	err = call(advapi.NewProc("AccessCheck"), descriptor, uintptr(duplicate), 1, uintptr(unsafe.Pointer(&mapping)), uintptr(unsafe.Pointer(&privileges[0])), uintptr(unsafe.Pointer(&size)), uintptr(unsafe.Pointer(&granted)), uintptr(unsafe.Pointer(&allowed)))
	return allowed != 0 && granted&1 != 0, err
}

func token(process syscall.Handle, mode string) (string, error) {
	var handle syscall.Handle
	if err := call(advapi.NewProc("OpenProcessToken"), uintptr(process), 10, uintptr(unsafe.Pointer(&handle))); err != nil {
		return "", err
	}
	defer syscall.CloseHandle(handle)
	var user, packageSID string
	for _, kind := range []uint32{1, 29, 30, 31} {
		buffer := [4096]byte{}
		var used uint32
		if err := call(advapi.NewProc("GetTokenInformation"), uintptr(handle), uintptr(kind), uintptr(unsafe.Pointer(&buffer[0])), uintptr(len(buffer)), uintptr(unsafe.Pointer(&used))); err != nil {
			return "", err
		}
		if kind == 29 && *(*uint32)(unsafe.Pointer(&buffer[0])) != 1 || kind == 30 && *(*uint32)(unsafe.Pointer(&buffer[0])) != 0 {
			return "", fmt.Errorf("unexpected_appcontainer_token")
		}
		if kind == 1 || kind == 31 {
			value, err := sidString(*(*uintptr)(unsafe.Pointer(&buffer[0])))
			if err != nil {
				return "", err
			}
			if kind == 1 {
				user = value
			} else {
				packageSID = value
			}
		}
	}
	exact, err := access(handle, user, packageSID)
	if err != nil || !exact {
		return "", fmt.Errorf("exact_package_access_check_failed: %v", err)
	}
	allPackages, err := access(handle, user, "S-1-15-2-1")
	if err != nil || allPackages != (mode == "ac") {
		return "", fmt.Errorf("lpac_access_check_failed: %v", err)
	}
	return "CAGE_TOKEN_VERIFIED:" + mode + ":" + packageSID, nil
}

func run() error {
	args := os.Args[1:]
	if len(args) < 2 || args[1] != "ac" && args[1] != "lpac" {
		return fmt.Errorf("invalid_helper_arguments")
	}
	current, _ := syscall.GetCurrentProcess()
	identity, err := token(current, args[1])
	if err != nil {
		return err
	}
	if len(args) == 2 && args[0] == "token" {
		fmt.Println(identity)
		return nil
	}
	if (len(args) != 6 && len(args) != 7) || args[0] != "code-version" || len(args) == 7 && args[6] != "preserve-symlinks" {
		return fmt.Errorf("invalid_helper_operation")
	}
	cmd := exec.Command(args[2], args[3], "--version", "--user-data-dir", args[4], "--extensions-dir", args[5])
	cmd.Env = append(os.Environ(), "ELECTRON_RUN_AS_NODE=1", "VSCODE_CLI=1")
	if len(args) == 7 {
		cmd.Env = append(cmd.Env, "NODE_OPTIONS=--preserve-symlinks-main --preserve-symlinks")
	}
	cmd.Dir = os.Getenv("HOME")
	cmd.Stdin, cmd.Stdout, cmd.Stderr = os.Stdin, os.Stdout, os.Stderr
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true}
	if err := cmd.Start(); err != nil {
		return fmt.Errorf("code_create_process: %w", err)
	}
	process, err := syscall.OpenProcess(0x1000, false, uint32(cmd.Process.Pid))
	if err != nil {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		return fmt.Errorf("code_open_process: %w", err)
	}
	child, err := token(process, args[1])
	syscall.CloseHandle(process)
	if err != nil || child != identity {
		_ = cmd.Process.Kill()
		_ = cmd.Wait()
		return fmt.Errorf("code_child_token: %v", err)
	}
	fmt.Println(child)
	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("code_exit: %w", err)
	}
	return nil
}

func main() {
	if err := run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(3)
	}
}
