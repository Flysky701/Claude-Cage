//go:build !windows

package workbench

import (
	"context"
	"errors"
)

type windowsLocalVolume struct{}

func (s *Server) openWindowsLocalVolume(_ context.Context, project string) (string, func(), error) {
	if project == "" {
		return "", func() {}, nil
	}
	return "", nil, errors.New("本地账户项目文件通道需要 Windows。")
}
