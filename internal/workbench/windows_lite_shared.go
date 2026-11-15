package workbench

import (
	"context"
	"errors"
)

// Shared control data may be edited before an application runtime is ready.
// Changes to project grants or the chosen egress still require a confirmed
// stopped space; an unavailable worker is not evidence that it stopped.
func (s *Server) requireWindowsLiteStopped(ctx context.Context) error {
	state, err := s.windowsLiteCall(ctx, "status", nil)
	if err != nil {
		return err
	}
	if state.ProcessCount != 0 || state.Network != "closed" || state.Phase == "running" || state.Phase == "starting" || state.Phase == "stopping" {
		return errors.New("请先停止 Windows 轻量空间并确认进程已退出，再修改项目或出口；现有数据保留")
	}
	return nil
}
