//go:build windows

// Native probe for LPAC, which cannot initialize the .NET Framework probe
// without additional capabilities. No capabilities are added for this test.
package main

import (
	"errors"
	"fmt"
	"net"
	"os"
	"strconv"
	"strings"
	"syscall"
	"time"
	"unsafe"
)

var adv = syscall.NewLazyDLL("advapi32.dll")
var kernel = syscall.NewLazyDLL("kernel32.dll")
var userenv = syscall.NewLazyDLL("userenv.dll")

func wide(s string) *uint16 {
	p, err := syscall.UTF16PtrFromString(s)
	if err != nil {
		panic(err)
	}
	return p
}
func failCode(err error) int {
	if err == nil {
		return 0
	}
	fmt.Fprintln(os.Stderr, err)
	var code syscall.Errno
	if errors.As(err, &code) {
		return int(code)
	}
	if os.IsPermission(err) {
		return 5
	}
	return 70020
}

//go:uintptrescapes
func call(name string, args ...uintptr) uintptr {
	result, _, err := adv.NewProc(name).Call(args...)
	if result == 0 {
		panic(name + ": " + err.Error())
	}
	return result
}

func token() (string, bool) {
	var handle uintptr
	call("OpenProcessToken", ^uintptr(0), 10, uintptr(unsafe.Pointer(&handle)))
	defer syscall.CloseHandle(syscall.Handle(handle))
	buf := make([]byte, 4096)
	var used uint32
	for _, kind := range []uint32{29, 30} {
		call("GetTokenInformation", handle, uintptr(kind), uintptr(unsafe.Pointer(&buf[0])), uintptr(len(buf)), uintptr(unsafe.Pointer(&used)))
		value := *(*uint32)(unsafe.Pointer(&buf[0]))
		if (kind == 29 && value != 1) || (kind == 30 && value != 0) {
			panic("unexpected native token")
		}
	}
	call("GetTokenInformation", handle, 31, uintptr(unsafe.Pointer(&buf[0])), uintptr(len(buf)), uintptr(unsafe.Pointer(&used)))
	var sidText *uint16
	call("ConvertSidToStringSidW", *(*uintptr)(unsafe.Pointer(&buf[0])), uintptr(unsafe.Pointer(&sidText)))
	defer kernel.NewProc("LocalFree").Call(uintptr(unsafe.Pointer(sidText)))
	sid := syscall.UTF16ToString((*[256]uint16)(unsafe.Pointer(sidText))[:])
	if !tokenAccess(handle, sid) {
		panic("native exact SID access check failed")
	}
	return sid, !tokenAccess(handle, "S-1-15-2-1")
}

func tokenAccess(token uintptr, principal string) bool {
	var duplicate uintptr
	call("DuplicateToken", token, 2, uintptr(unsafe.Pointer(&duplicate)))
	defer syscall.CloseHandle(syscall.Handle(duplicate))
	buf := make([]byte, 4096)
	var used uint32
	call("GetTokenInformation", token, 1, uintptr(unsafe.Pointer(&buf[0])), uintptr(len(buf)), uintptr(unsafe.Pointer(&used)))
	var name *uint16
	call("ConvertSidToStringSidW", *(*uintptr)(unsafe.Pointer(&buf[0])), uintptr(unsafe.Pointer(&name)))
	user := syscall.UTF16ToString((*[256]uint16)(unsafe.Pointer(name))[:])
	kernel.NewProc("LocalFree").Call(uintptr(unsafe.Pointer(name)))
	sddl := "O:" + user + "G:" + user + "D:(A;;0x1;;;" + user + ")(A;;0x1;;;" + principal + ")"
	var descriptor uintptr
	var length uint32
	call("ConvertStringSecurityDescriptorToSecurityDescriptorW", uintptr(unsafe.Pointer(wide(sddl))), 1, uintptr(unsafe.Pointer(&descriptor)), uintptr(unsafe.Pointer(&length)))
	defer kernel.NewProc("LocalFree").Call(descriptor)
	mapping := [4]uint32{1, 2, 4, 7}
	privileges := make([]byte, 1024)
	size := uint32(1024)
	var granted, allowed uint32
	call("AccessCheck", descriptor, duplicate, 1, uintptr(unsafe.Pointer(&mapping[0])), uintptr(unsafe.Pointer(&privileges[0])), uintptr(unsafe.Pointer(&size)), uintptr(unsafe.Pointer(&granted)), uintptr(unsafe.Pointer(&allowed)))
	return allowed != 0 && granted&1 == 1
}

func registry(action, path string) int {
	var key uintptr
	if action == "registry-own" {
		r, _, _ := userenv.NewProc("GetAppContainerRegistryLocation").Call(0x2001f, uintptr(unsafe.Pointer(&key)))
		if int32(r) < 0 {
			return int(r & 65535)
		}
	} else {
		access := uintptr(0x20019)
		if action == "registry-write" {
			access = 0x2001f
		}
		r, _, _ := adv.NewProc("RegOpenKeyExW").Call(0x80000001, uintptr(unsafe.Pointer(wide(path))), 0, access, uintptr(unsafe.Pointer(&key)))
		if r != 0 {
			return int(r)
		}
	}
	defer adv.NewProc("RegCloseKey").Call(key)
	if action == "registry-read" {
		var kind uint32
		data := make([]uint16, 128)
		size := uint32(len(data) * 2)
		r, _, _ := adv.NewProc("RegQueryValueExW").Call(key, uintptr(unsafe.Pointer(wide("marker"))), 0, uintptr(unsafe.Pointer(&kind)), uintptr(unsafe.Pointer(&data[0])), uintptr(unsafe.Pointer(&size)))
		if r != 0 {
			return int(r)
		}
		if syscall.UTF16ToString(data) == "fixture" {
			return 0
		}
		return 70003
	}
	name := "marker"
	if action == "registry-own" {
		name = "CageFixture"
	}
	value, _ := syscall.UTF16FromString("child")
	r, _, _ := adv.NewProc("RegSetValueExW").Call(key, uintptr(unsafe.Pointer(wide(name))), 0, 1, uintptr(unsafe.Pointer(&value[0])), uintptr(len(value)*2))
	return int(r)
}

func fileOperation(path string, write bool) int {
	access, creation := uint32(syscall.GENERIC_READ), uint32(syscall.OPEN_EXISTING)
	if write {
		access = syscall.GENERIC_WRITE
		creation = syscall.CREATE_ALWAYS
	}
	handle, err := syscall.CreateFile(wide(path), access, syscall.FILE_SHARE_READ|syscall.FILE_SHARE_WRITE, nil, creation, 0, 0)
	if err != nil {
		return failCode(err)
	}
	defer syscall.CloseHandle(handle)
	var count uint32
	if write {
		return failCode(syscall.WriteFile(handle, []byte("child"), &count, nil))
	}
	buf := make([]byte, 64)
	if err = syscall.ReadFile(handle, buf, &count, nil); err != nil {
		return failCode(err)
	}
	if string(buf[:count]) == "fixture" {
		return 0
	}
	return 70003
}

func run(a []string) int {
	if len(a) < 4 || a[0] != "worker" {
		return 70001
	}
	sid, lpac := token()
	if (a[1] != "self" && sid != a[1]) || lpac != (a[2] == "lpac") {
		return 70002
	}
	action := a[3]
	switch action {
	// Use synchronous Win32 I/O: Go's ordinary os.File path initializes the
	// socket/IOCP layer and can fail with 10093 in a zero-capability LPAC.
	case "read":
		return fileOperation(a[4], false)
	case "write":
		return fileOperation(a[4], true)
	case "registry-read", "registry-write":
		return registry(action, a[4])
	case "registry-own":
		return registry(action, "")
	case "environment":
		if os.Getenv("CAGE_FAKE_HOST_SECRET") == "" && os.Getenv("ANTHROPIC_API_KEY") == "" {
			return 0
		}
		return 70004
	case "child":
		exe, err := os.Executable()
		if err != nil {
			return 70005
		}
		info := syscall.StartupInfo{}
		info.Cb = uint32(unsafe.Sizeof(info))
		var process syscall.ProcessInformation
		err = syscall.CreateProcess(wide(exe), wide("\""+exe+"\" worker "+sid+" "+a[2]+" environment"), nil, nil, false, 0x08000000, nil, nil, &info, &process)
		if err != nil {
			return failCode(err)
		}
		defer syscall.CloseHandle(process.Process)
		syscall.CloseHandle(process.Thread)
		wait, err := syscall.WaitForSingleObject(process.Process, 5000)
		if err != nil {
			return failCode(err)
		}
		if wait != 0 {
			syscall.TerminateProcess(process.Process, 70005)
			return 70005
		}
		var code uint32
		if err = syscall.GetExitCodeProcess(process.Process, &code); err != nil {
			return failCode(err)
		}
		return int(code)
	case "winsock-init":
		data := make([]byte, 1024)
		code, _, _ := syscall.NewLazyDLL("ws2_32.dll").NewProc("WSAStartup").Call(0x202, uintptr(unsafe.Pointer(&data[0])))
		if code == 0 {
			syscall.NewLazyDLL("ws2_32.dll").NewProc("WSACleanup").Call()
		}
		return int(code)
	case "tcp", "udp":
		port, err := strconv.Atoi(a[5])
		if err != nil {
			return 70006
		}
		target := net.JoinHostPort(a[4], strconv.Itoa(port))
		conn, err := net.DialTimeout(action, target, 1200*time.Millisecond)
		if err != nil {
			if e, ok := err.(net.Error); ok && e.Timeout() {
				return 10060
			}
			var code syscall.Errno
			if errors.As(err, &code) {
				return int(code)
			}
			if strings.Contains(err.Error(), "10013") || strings.Contains(strings.ToLower(err.Error()), "permission") {
				return 10013
			}
			fmt.Fprintln(os.Stderr, err)
			return 70007
		}
		defer conn.Close()
		if action == "udp" {
			_, err = conn.Write([]byte("CAGE"))
			if err != nil {
				fmt.Fprintln(os.Stderr, err)
				return 70008
			}
		}
		return 0
	}
	return 70006
}

func main() {
	code := 70000
	func() {
		defer func() {
			if err := recover(); err != nil {
				fmt.Fprintln(os.Stderr, err)
			}
		}()
		code = run(os.Args[1:])
	}()
	os.Exit(code)
}
