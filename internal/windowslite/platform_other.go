//go:build !windows

package windowslite

import (
	"context"
	"errors"
	"os/exec"
)

func hideProcess(*exec.Cmd, bool)        {}
func lockProfile(string) (func(), error) { return nil, errors.New("Windows Lite 仅支持 Windows") }
func watchOwner(context.Context, int, context.CancelFunc) error {
	return errors.New("Windows Lite 仅支持 Windows")
}
