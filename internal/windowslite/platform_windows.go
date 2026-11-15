//go:build windows

package windowslite

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"syscall"
	"time"

	"golang.org/x/sys/windows"
)

func hideProcess(cmd *exec.Cmd, detached bool) {
	flags := uint32(windows.CREATE_NO_WINDOW)
	if detached {
		flags |= windows.CREATE_NEW_PROCESS_GROUP
	}
	cmd.SysProcAttr = &syscall.SysProcAttr{CreationFlags: flags, HideWindow: true}
}

func lockProfile(path string) (func(), error) {
	file, err := os.OpenFile(path, os.O_CREATE|os.O_RDWR, 0600)
	if err != nil {
		return nil, err
	}
	var overlapped windows.Overlapped
	if err := windows.LockFileEx(windows.Handle(file.Fd()), windows.LOCKFILE_EXCLUSIVE_LOCK|windows.LOCKFILE_FAIL_IMMEDIATELY, 0, 1, 0, &overlapped); err != nil {
		file.Close()
		return nil, errors.New("此轻量空间已有管理进程，未启动第二个实例")
	}
	return func() { _ = windows.UnlockFileEx(windows.Handle(file.Fd()), 0, 1, 0, &overlapped); _ = file.Close() }, nil
}

func watchOwner(ctx context.Context, pid int, cancel context.CancelFunc) error {
	handle, err := windows.OpenProcess(windows.SYNCHRONIZE, false, uint32(pid))
	if err != nil {
		return errors.New("无法确认桌面窗口进程，未启动空间后台")
	}
	go func() {
		defer windows.CloseHandle(handle)
		ticker := time.NewTicker(time.Second)
		defer ticker.Stop()
		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				result, err := windows.WaitForSingleObject(handle, 0)
				if err != nil || result == windows.WAIT_OBJECT_0 {
					cancel()
					return
				}
			}
		}
	}()
	return nil
}
