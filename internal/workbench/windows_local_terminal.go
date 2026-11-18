package workbench

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os/exec"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"github.com/sylvinus/agent-vm/internal/host"
)

type windowsLocalTerminalFrame struct {
	Type           string `json:"type"`
	Text           string `json:"text,omitempty"`
	Message        string `json:"message,omitempty"`
	WorkerUsername string `json:"workerUsername,omitempty"`
	WorkerSID      string `json:"workerSid,omitempty"`
	InstanceID     string `json:"instanceId,omitempty"`
	IntegrityLabel string `json:"integrityLabel,omitempty"`
	Code           int    `json:"code,omitempty"`
}

type windowsLocalTerminalInput struct {
	Type string `json:"type"`
	Text string `json:"text"`
}

func writeWindowsLocalFrame(ws *websocket.Conn, frame windowsLocalTerminalFrame) error {
	_ = ws.SetWriteDeadline(time.Now().Add(10 * time.Second))
	return ws.WriteJSON(frame)
}

func (s *Server) windowsLocalTerminal(w http.ResponseWriter, r *http.Request) {
	ws, err := s.upgrade(w, r)
	if err != nil {
		return
	}
	defer ws.Close()
	ctx, cancel := context.WithCancel(r.Context())
	var workers sync.WaitGroup
	defer func() {
		cancel()
		ws.Close()
		workers.Wait()
	}()
	if err := s.runWindowsLocalTerminal(ctx, cancel, ws, &workers); err != nil {
		_ = writeWindowsLocalFrame(ws, windowsLocalTerminalFrame{Type: "error", Message: err.Error()})
		return
	}
	_ = writeWindowsLocalFrame(ws, windowsLocalTerminalFrame{Type: "exit"})
}

func (s *Server) runWindowsLocalTerminal(ctx context.Context, cancel context.CancelFunc, ws *websocket.Conn, workers *sync.WaitGroup) error {
	p := s.windowsLocal
	binding := p.active.Load()
	if binding == nil {
		return errors.New("请先在工作台中确认隔离账户。")
	}
	if err := p.waitForSession(ctx); err != nil {
		return err
	}
	defer p.op.Unlock()
	if err := p.checkPaths(); err != nil {
		return err
	}
	// EOF requests a graceful worker/job shutdown and restores desktop ACLs.
	// Killing the controller on browser disconnect would skip that restoration.
	cmd := exec.Command(p.helper, "workbench-terminal", "--profile", p.profile)
	host.HideCommandWindow(cmd)
	closeNet := s.prepareWindowsLocalNetwork(ctx, cmd)
	defer closeNet()
	stdin, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	defer stdin.Close()
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	defer stdout.Close()
	var stderr bytes.Buffer
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &stderr, remaining: 4096}
	if err := cmd.Start(); err != nil {
		return errors.New("无法启动本地账户终端工具。")
	}
	var ready atomic.Bool
	input := make(chan string, 8)
	ws.SetReadLimit(128 << 10)
	stopClose := context.AfterFunc(ctx, func() { stdin.Close() })
	defer stopClose()
	workers.Go(func() {
		defer cancel()
		readWindowsLocalInput(ctx, ws, &ready, input)
	})
	workers.Go(func() {
		defer cancel()
		encoder := json.NewEncoder(stdin)
		for ctx.Err() == nil {
			select {
			case <-ctx.Done():
				return
			case line := <-input:
				if encoder.Encode(windowsLocalTerminalInput{Type: "input", Text: line}) != nil {
					return
				}
			}
		}
	})
	streamErr := forwardWindowsLocalOutput(stdout, ws, &ready, binding)
	cancel()
	stdin.Close()
	stdout.Close()
	waitErr := cmd.Wait()
	if streamErr != nil {
		return streamErr
	}
	if waitErr != nil || !ready.Load() {
		if line, _, _ := strings.Cut(strings.TrimSpace(stderr.String()), "\n"); line != "" {
			return errors.New("隔离终端启动或运行失败：" + strings.TrimSpace(line))
		}
		return errors.New("隔离终端已中断，请重新打开。")
	}
	return nil
}

// Keep reading the socket even if a running command stops consuming input.
// A disconnect or a full input queue closes the helper's stdin promptly.
func readWindowsLocalInput(ctx context.Context, ws *websocket.Conn, ready *atomic.Bool, input chan<- string) {
	for {
		var frame windowsLocalTerminalInput
		if ws.ReadJSON(&frame) != nil || frame.Type == "close" {
			return
		}
		if !ready.Load() || frame.Type != "input" || len(frame.Text) > 16<<10 || strings.ContainsAny(frame.Text, "\x00\r\n") {
			return
		}
		select {
		case input <- frame.Text:
		case <-ctx.Done():
			return
		default:
			return
		}
	}
}

func forwardWindowsLocalOutput(stdout io.Reader, ws *websocket.Conn, ready *atomic.Bool, binding *windowsLocalBinding) error {
	scanner := bufio.NewScanner(stdout)
	scanner.Buffer(make([]byte, 4096), 256<<10)
	for scanner.Scan() {
		var frame windowsLocalTerminalFrame
		if json.Unmarshal(scanner.Bytes(), &frame) != nil {
			return errors.New("终端工具返回了无效数据。")
		}
		switch frame.Type {
		case "ready":
			if ready.Load() || frame.WorkerSID != binding.WorkerSID || frame.InstanceID != binding.InstanceID || frame.WorkerUsername == "" || frame.IntegrityLabel != "Low" {
				return errors.New("未核实终端的本地账户和低完整性权限。")
			}
			ready.Store(true)
		case "output":
			if !ready.Load() {
				return errors.New("终端尚未完成身份核验。")
			}
		case "error":
			return errors.New("隔离终端错误：" + frame.Message)
		case "exit":
			if frame.Code != 0 {
				return fmt.Errorf("PowerShell 已退出，退出码为 %d。", frame.Code)
			}
			return nil
		default:
			return errors.New("终端工具返回了未知消息。")
		}
		if err := writeWindowsLocalFrame(ws, frame); err != nil {
			return err
		}
	}
	return scanner.Err()
}
