//go:build !windows

package workbench

import (
	"errors"
	"os/exec"
)

func launchWindowsLiteTerminal(_ *exec.Cmd) error {
	return errors.New("轻量空间终端只支持 Windows")
}
