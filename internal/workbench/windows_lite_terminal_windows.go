package workbench

import (
	"os/exec"
	"syscall"
)

func launchWindowsLiteTerminal(cmd *exec.Cmd) error {
	cmd.SysProcAttr = &syscall.SysProcAttr{HideWindow: true, CreationFlags: 0x08000000}
	return cmd.Start()
}
