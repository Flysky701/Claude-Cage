package workbench

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"github.com/sylvinus/agent-vm/internal/host"
)

func (s *Server) windowsLocalBrowser(w http.ResponseWriter, r *http.Request) {
	s.serveWindowsLocalVisual(w, r, "workbench-browser")
}

// The selected command is fixed by each route. A viewer can only send native
// UI actions. Raw Edge protocol methods and host-window handles stay private.
func (s *Server) serveWindowsLocalVisual(w http.ResponseWriter, r *http.Request, command string) {
	ws, err := s.upgrade(w, r)
	if err != nil {
		return
	}
	defer ws.Close()
	project := ""
	if command == "workbench-editor" {
		project = r.URL.Query().Get("project")
		if len(project) > 16384 || strings.IndexByte(project, 0) >= 0 {
			_ = writeWindowsLocalFrame(ws, windowsLocalTerminalFrame{Type: "error", Message: "无效的项目路径。"})
			return
		}
	}
	if err := s.runWindowsLocalVisual(r.Context(), ws, command, project); err != nil {
		_ = writeWindowsLocalFrame(ws, windowsLocalTerminalFrame{Type: "error", Message: err.Error()})
		return
	}
	_ = writeWindowsLocalFrame(ws, windowsLocalTerminalFrame{Type: "exit"})
}

func (p *windowsLocalPrototype) waitForSession(ctx context.Context) error {
	// A switch of pane can briefly overlap the previous application's clean exit.
	// Never preempt an open terminal or another viewer.
	deadline := time.Now().Add(3 * time.Second)
	for !p.op.TryLock() {
		if ctx.Err() != nil || time.Now().After(deadline) {
			return errors.New("隔离账户仍在使用，请先关闭当前终端或应用，再重新连接。")
		}
		time.Sleep(60 * time.Millisecond)
	}
	return nil
}

func (s *Server) runWindowsLocalVisual(ctx context.Context, ws *websocket.Conn, command, project string) error {
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
	cmd := exec.Command(p.helper, command, "--profile", p.profile)
	if command == "workbench-editor" {
		cmd.Env = append(os.Environ(), "CAGE_LOCAL_EDITOR_PROJECT="+project)
	}
	host.HideCommandWindow(cmd)
	closeNet := s.prepareWindowsLocalNetwork(ctx, cmd)
	defer closeNet()
	input, err := cmd.StdinPipe()
	if err != nil {
		return err
	}
	defer input.Close()
	output, err := cmd.StdoutPipe()
	if err != nil {
		return err
	}
	defer output.Close()
	var diagnostic bytes.Buffer
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4096}
	if err := cmd.Start(); err != nil {
		return errors.New("隔离窗口工具启动失败。")
	}

	var admitted atomic.Bool
	ws.SetReadLimit(32768)
	readDone := make(chan struct{})
	go func() {
		defer close(readDone)
		defer input.Close()
		for {
			kind, raw, err := ws.ReadMessage()
			var frame struct {
				Type string `json:"type"`
			}
			if err != nil || kind != websocket.TextMessage || json.Unmarshal(raw, &frame) != nil ||
				frame.Type == "" || frame.Type == "close" || !admitted.Load() {
				return
			}
			// Compact valid JSON to keep one request per helper input line.
			var line bytes.Buffer
			if err := json.Compact(&line, raw); err != nil {
				return
			}
			line.WriteByte('\n')
			if _, err = io.Copy(input, &line); err != nil {
				return
			}
		}
	}()
	stop := context.AfterFunc(ctx, func() { input.Close(); ws.Close() })
	defer stop()
	forwardErr := func() error {
		scanner := bufio.NewScanner(output)
		scanner.Buffer(make([]byte, 32768), 4<<20)
		for scanner.Scan() {
			var frame struct {
				Type       string `json:"type"`
				InstanceID string `json:"instanceId"`
				WorkerSID  string `json:"workerSid"`
			}
			if json.Unmarshal(scanner.Bytes(), &frame) != nil || frame.Type == "" {
				return errors.New("隔离窗口返回了无效数据。")
			}
			if !admitted.Load() {
				if frame.Type != "ready" || frame.InstanceID != binding.InstanceID || frame.WorkerSID != binding.WorkerSID {
					return errors.New("隔离窗口的身份与已绑定账户不一致。")
				}
				admitted.Store(true)
			}
			_ = ws.SetWriteDeadline(time.Now().Add(5 * time.Second))
			if err := ws.WriteMessage(websocket.TextMessage, scanner.Bytes()); err != nil {
				return err
			}
		}
		return scanner.Err()
	}()
	input.Close()
	output.Close()
	waitErr := cmd.Wait()
	// Unblock the reader while keeping the write direction available for the
	// final cleanup acknowledgement or an actionable launch error.
	_ = ws.UnderlyingConn().SetReadDeadline(time.Now())
	<-readDone
	if forwardErr != nil {
		return forwardErr
	}
	if waitErr != nil || !admitted.Load() {
		message, _, _ := strings.Cut(strings.TrimSpace(diagnostic.String()), "\n")
		if message == "" {
			message = "请检查隔离账户、窗口组件和网络规则后重试。"
		}
		return errors.New("隔离窗口未能继续运行。" + strings.TrimSpace(message))
	}
	return nil
}
