//go:build !windows

package workbench

import (
	"context"
	"errors"
)

func installWindowsLitePackage(context.Context, string, string, string, string) error {
	return errors.New("轻量沙箱安装仅支持 Windows")
}
func startWindowsLiteServices(context.Context) error {
	return errors.New("轻量沙箱安装仅支持 Windows")
}
func checkWindowsLiteInstaller(context.Context, string) error {
	return errors.New("轻量沙箱安装仅支持 Windows")
}
