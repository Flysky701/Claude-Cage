//go:build windows

package workbench

import (
	"crypto/rand"
	"encoding/hex"
	"errors"
	"fmt"
	"os/exec"
	"unsafe"

	"golang.org/x/sys/windows"
)

// This candidate adapter is not selected by the production backend. The host
// owns package lifetime: per terminal for disposable runs, per environment for
// persistent runs. Killing a relay cannot accidentally delete a shared profile.
type windowsAppContainerTerminal struct {
	*windowsGuestTerminal
	profileName string
	cleaned     chan struct{}
	cleanupErr  error
}

func createTerminalAppContainer() (string, error) {
	var random [16]byte
	if _, err := rand.Read(random[:]); err != nil {
		return "", err
	}
	name := "Cage.TerminalCandidate." + hex.EncodeToString(random[:])
	wide, err := windows.UTF16PtrFromString(name)
	if err != nil {
		return "", err
	}
	var sid *windows.SID
	create := windows.NewLazySystemDLL("userenv.dll").NewProc("CreateAppContainerProfile")
	code, _, _ := create.Call(uintptr(unsafe.Pointer(wide)), uintptr(unsafe.Pointer(wide)), uintptr(unsafe.Pointer(wide)), 0, 0, uintptr(unsafe.Pointer(&sid)))
	if int32(code) < 0 {
		return "", fmt.Errorf("create terminal AppContainer: HRESULT 0x%08x", uint32(code))
	}
	if sid != nil {
		_ = windows.FreeSid(sid)
	}
	return name, nil
}

func deleteTerminalAppContainer(name string) error {
	wide, err := windows.UTF16PtrFromString(name)
	if err != nil {
		return err
	}
	remove := windows.NewLazySystemDLL("userenv.dll").NewProc("DeleteAppContainerProfile")
	code, _, _ := remove.Call(uintptr(unsafe.Pointer(wide)))
	if int32(code) < 0 {
		return fmt.Errorf("delete terminal AppContainer: HRESULT 0x%08x", uint32(code))
	}
	return nil
}

func startWindowsAppContainerTerminal(cmd *exec.Cmd, open any) (*windowsAppContainerTerminal, error) {
	if len(cmd.Args) < 5 || cmd.Args[1] != "terminal-rpc" || (cmd.Args[2] != "ac" && cmd.Args[2] != "lpac") {
		return nil, errors.New("invalid local terminal candidate command")
	}
	profile, err := createTerminalAppContainer()
	if err != nil {
		return nil, err
	}
	args := []string{cmd.Args[0], "terminal-rpc-owned", cmd.Args[2], cmd.Args[3], cmd.Args[4], profile}
	cmd.Args = append(args, cmd.Args[5:]...)
	return startOwnedWindowsAppContainerTerminal(cmd, open, profile, true)
}

// Persistent environments keep their package after each terminal exits. Each
// relay still owns an independent job and is reaped by its own transport.
func startOwnedWindowsAppContainerTerminal(cmd *exec.Cmd, open any, profile string, deleteOnExit bool) (*windowsAppContainerTerminal, error) {
	base, err := startWindowsGuestTerminalRequest(cmd, open)
	if err != nil {
		if deleteOnExit {
			err = errors.Join(err, deleteTerminalAppContainer(profile))
		}
		return nil, err
	}
	t := &windowsAppContainerTerminal{windowsGuestTerminal: base.(*windowsGuestTerminal), profileName: profile, cleaned: make(chan struct{})}
	go func() {
		_ = t.windowsGuestTerminal.Wait()
		if deleteOnExit {
			t.cleanupErr = deleteTerminalAppContainer(profile)
		}
		close(t.cleaned)
	}()
	return t, nil
}

func (t *windowsAppContainerTerminal) Wait() error {
	<-t.cleaned
	return errors.Join(t.windowsGuestTerminal.Wait(), t.cleanupErr)
}

func (t *windowsAppContainerTerminal) Kill() error {
	// Close the reader as well: a viewer may have stopped consuming output,
	// leaving the transport's writer blocked before it can reap the relay.
	_ = t.windowsGuestTerminal.Close()
	<-t.cleaned
	return t.cleanupErr
}

func (t *windowsAppContainerTerminal) Close() error { return t.Kill() }
