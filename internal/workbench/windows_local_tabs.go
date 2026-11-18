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
	"path/filepath"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/gorilla/websocket"
	"github.com/sylvinus/agent-vm/internal/host"
)

type windowsLocalEpochKey struct{}

type windowsLocalEnvelope struct {
	ID               string          `json:"id"`
	Type             string          `json:"type,omitempty"`
	App              string          `json:"app,omitempty"`
	Project          string          `json:"project,omitempty"`
	Additional       []string        `json:"additional,omitempty"`
	Mount            string          `json:"mount,omitempty"`
	AdditionalMounts []string        `json:"additionalMounts,omitempty"`
	Kind             string          `json:"kind,omitempty"`
	CLIID            string          `json:"cliID,omitempty"`
	Account          string          `json:"account,omitempty"`
	Resume           bool            `json:"resume"`
	Event            json.RawMessage `json:"event,omitempty"`
}

type windowsLocalFrame struct {
	Type           string `json:"type"`
	Message        string `json:"message,omitempty"`
	WorkerUsername string `json:"workerUsername,omitempty"`
	WorkerSID      string `json:"workerSid,omitempty"`
	InstanceID     string `json:"instanceId,omitempty"`
	IntegrityLabel string `json:"integrityLabel,omitempty"`
	Code           int    `json:"code,omitempty"`
	Account        string `json:"account,omitempty"`
	AccountLabel   string `json:"accountLabel,omitempty"`
	PTYProtocol    int    `json:"ptyProtocol,omitempty"`
	ReopenedDraft  bool   `json:"reopenedDraft,omitempty"`
}

type windowsLocalEvent struct {
	windowsLocalFrame
	raw json.RawMessage
}

type windowsLocalTab struct {
	id       string
	app      string
	folders  []string
	frames   chan windowsLocalEvent
	ended    chan struct{}
	released chan struct{}
	end      sync.Once
	cancel   context.CancelCauseFunc
}

// All tabs of one account epoch share the same verified worker and network gate.
// The caller holding the last reference waits for Job and desktop ACL cleanup.
type windowsLocalHub struct {
	ctx         context.Context
	stop        context.CancelFunc
	epoch       context.Context
	binding     windowsLocalBinding
	writes      chan windowsLocalEnvelope
	ready       chan struct{}
	ptyProtocol int // published by closing ready
	done        chan struct{}
	err         error                       // published by closing done
	tabs        map[string]*windowsLocalTab // protected by prototype.tabsMu
}

func (s *Server) joinWindowsLocalTab(ctx context.Context, cancel context.CancelCauseFunc, app string) (*windowsLocalHub, *windowsLocalTab, error) {
	p := s.windowsLocal
	epoch, _ := ctx.Value(windowsLocalEpochKey{}).(context.Context)
retry:
	for {
		if epoch == nil || epoch.Err() != nil || ctx.Err() != nil {
			return nil, nil, errors.New("工作台已锁定或关闭。")
		}
		p.tabsMu.Lock()
		h := p.tabs
		if h != nil && (h.ctx.Err() != nil || h.epoch != epoch) {
			p.tabsMu.Unlock()
			select {
			case <-ctx.Done():
				return nil, nil, ctx.Err()
			case <-h.done:
				continue
			}
		}
		if h == nil {
			if !p.op.TryLock() {
				p.tabsMu.Unlock()
				return nil, nil, errors.New("正在检查隔离账户或准备组件，请稍后重新打开标签页。")
			}
			var err error
			h, err = s.startWindowsLocalHub(epoch)
			if err != nil {
				p.op.Unlock()
				p.tabsMu.Unlock()
				return nil, nil, err
			}
			p.tabs = h
		}
		// A pane can reconnect while its old socket is still closing. Give that
		// same app time to release its window without disturbing another user.
		for _, old := range h.tabs {
			if app == "terminal" || app == "pty" || old.app != app {
				continue
			}
			p.tabsMu.Unlock()
			select {
			case <-ctx.Done():
				return nil, nil, ctx.Err()
			case <-time.After(5 * time.Second):
				return nil, nil, errors.New("此应用已在其他标签页中打开。")
			case <-old.released:
				continue retry
			}
		}
		if len(h.tabs) >= 32 {
			p.tabsMu.Unlock()
			return nil, nil, errors.New("已达到会话标签页数量上限。")
		}
		t := &windowsLocalTab{id: randomToken()[:32], app: app, frames: make(chan windowsLocalEvent, 8), ended: make(chan struct{}), released: make(chan struct{}), cancel: cancel}
		h.tabs[t.id] = t
		p.tabsMu.Unlock()
		return h, t, nil
	}
}

func (s *Server) startWindowsLocalHub(epoch context.Context) (*windowsLocalHub, error) {
	p := s.windowsLocal
	binding := p.active.Load()
	if binding == nil {
		return nil, errors.New("请先在工作台中确认隔离账户。")
	}
	if err := p.checkPaths(); err != nil {
		return nil, err
	}
	ctx, cancel := context.WithCancel(epoch)
	onShutdown := context.AfterFunc(s.lifetimeContext(), cancel)
	stop := func() { onShutdown(); cancel() }
	cmd := exec.Command(p.helper, "workbench-tabs", "--profile", p.profile)
	host.HideCommandWindow(cmd)
	closeNet := s.prepareWindowsLocalNetwork(ctx, cmd)
	input, err := cmd.StdinPipe()
	if err != nil {
		stop()
		closeNet()
		return nil, err
	}
	output, err := cmd.StdoutPipe()
	if err != nil {
		input.Close()
		stop()
		closeNet()
		return nil, err
	}
	var diagnostic bytes.Buffer
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4096}
	if err := cmd.Start(); err != nil {
		input.Close()
		output.Close()
		stop()
		closeNet()
		return nil, errors.New("无法启动隔离工作台。")
	}
	h := &windowsLocalHub{ctx: ctx, stop: stop, epoch: epoch, binding: *binding, writes: make(chan windowsLocalEnvelope, 32),
		ready: make(chan struct{}), done: make(chan struct{}), tabs: make(map[string]*windowsLocalTab)}

	// EOF lets the controller close all child jobs and restore desktop ACLs.
	closeInput := context.AfterFunc(ctx, func() { input.Close() })
	go func() {
		enc := json.NewEncoder(input)
		enc.SetEscapeHTML(false)
		for ctx.Err() == nil {
			select {
			case <-ctx.Done():
				return
			case msg := <-h.writes:
				if enc.Encode(msg) != nil {
					stop()
					return
				}
			}
		}
	}()
	go func() {
		err := h.read(p, output)
		stop()
		closeInput()
		input.Close()
		output.Close()
		waitErr := cmd.Wait()
		closeNet()
		if err == nil {
			message, _, _ := strings.Cut(strings.TrimSpace(diagnostic.String()), "\n")
			if waitErr != nil && message != "" {
				err = errors.New("隔离工作台已中断：" + strings.TrimSpace(message))
			} else {
				err = errors.New("隔离工作台已关闭。")
			}
		}
		p.tabsMu.Lock()
		h.err = err
		p.tabs = nil
		p.op.Unlock()
		close(h.done)
		p.tabsMu.Unlock()
	}()
	return h, nil
}

func (h *windowsLocalHub) read(p *windowsLocalPrototype, output io.Reader) error {
	scanner := bufio.NewScanner(output)
	scanner.Buffer(make([]byte, 32768), (4<<20)+256)
	if !scanner.Scan() {
		return scanner.Err()
	}
	var hello windowsLocalFrame
	if json.Unmarshal(scanner.Bytes(), &hello) != nil || hello.Type != "ready" ||
		hello.InstanceID != h.binding.InstanceID || hello.WorkerSID != h.binding.WorkerSID {
		return errors.New("隔离工作台与已绑定的本地账户不一致。")
	}
	h.ptyProtocol = hello.PTYProtocol
	close(h.ready)
	for scanner.Scan() {
		var msg windowsLocalEnvelope
		var frame windowsLocalFrame
		if json.Unmarshal(scanner.Bytes(), &msg) != nil || msg.ID == "" ||
			json.Unmarshal(msg.Event, &frame) != nil || frame.Type == "" {
			return errors.New("隔离工作台返回了无效消息。")
		}
		p.tabsMu.Lock()
		tab := h.tabs[msg.ID]
		p.tabsMu.Unlock()
		if tab == nil {
			continue
		}
		if frame.Type == "exit" || frame.Type == "error" {
			tab.end.Do(func() { close(tab.ended) })
		}
		select {
		case tab.frames <- windowsLocalEvent{windowsLocalFrame: frame, raw: msg.Event}:
		default:
			tab.cancel(errors.New("标签页无法及时接收输出，请重新打开。"))
		}
	}
	return scanner.Err()
}

func (h *windowsLocalHub) send(ctx context.Context, msg windowsLocalEnvelope) bool {
	select {
	case <-ctx.Done():
		return false
	case <-h.ctx.Done():
		return false
	case h.writes <- msg:
		return true
	}
}

func (p *windowsLocalPrototype) leaveTab(h *windowsLocalHub, t *windowsLocalTab, opened bool) {
	defer close(t.released)
	p.tabsMu.Lock()
	if len(h.tabs) == 1 {
		delete(h.tabs, t.id)
		h.stop()
		p.tabsMu.Unlock()
		<-h.done
		return
	}
	p.tabsMu.Unlock()
	if opened {
		select {
		case <-t.ended:
		default:
			if h.send(h.ctx, windowsLocalEnvelope{ID: t.id, Type: "close"}) {
				select {
				case <-t.ended:
				case <-h.done:
				}
			}
		}
	}
	p.tabsMu.Lock()
	delete(h.tabs, t.id)
	last := len(h.tabs) == 0
	if last {
		h.stop()
	}
	p.tabsMu.Unlock()
	if last {
		<-h.done
	}
}

func (s *Server) serveWindowsLocalTab(w http.ResponseWriter, r *http.Request, app string) {
	ws, err := s.upgrade(w, r)
	if err != nil {
		return
	}
	defer ws.Close()
	err = s.runWindowsLocalTab(r.Context(), ws, app, r.URL.Query().Get("project"))
	frame := windowsLocalFrame{Type: "exit"}
	if err != nil && !errors.Is(err, context.Canceled) {
		frame = windowsLocalFrame{Type: "error", Message: err.Error()}
	}
	_ = ws.SetWriteDeadline(time.Now().Add(5 * time.Second))
	_ = ws.WriteJSON(frame)
}

func (s *Server) runWindowsLocalTab(parent context.Context, ws *websocket.Conn, app, project string) error {
	if project != "" && ((app != "editor" && app != "terminal") || len(project) > 16384 ||
		!filepath.IsAbs(project) || len(filepath.VolumeName(project)) != 2 || strings.ContainsAny(project, "\x00\r\n")) {
		return errors.New("请选择已授权的本机项目目录。")
	}
	ctx, cancel := context.WithCancelCause(parent)
	defer cancel(nil)
	h, t, err := s.joinWindowsLocalTab(ctx, cancel, app)
	if err != nil {
		return err
	}
	opened := false
	var releaseVolume func()
	defer func() {
		s.windowsLocal.leaveTab(h, t, opened)
		if releaseVolume != nil {
			releaseVolume()
		}
	}()
	var admitted atomic.Bool
	readDone := make(chan struct{})
	ws.SetReadLimit(32768)
	if app == "terminal" {
		ws.SetReadLimit(128 << 10)
	}
	go func() {
		defer close(readDone)
		defer cancel(nil)
		for {
			kind, raw, err := ws.ReadMessage()
			var input struct{ Type, Text string }
			if err != nil || kind != websocket.TextMessage || json.Unmarshal(raw, &input) != nil ||
				input.Type == "" || input.Type == "close" || !admitted.Load() {
				return
			}
			if app == "terminal" {
				if input.Type != "input" || len(input.Text) > 16<<10 || strings.ContainsAny(input.Text, "\x00\r\n") {
					return
				}
				raw, _ = json.Marshal(map[string]string{"type": "input", "text": input.Text})
			}
			if !h.send(ctx, windowsLocalEnvelope{ID: t.id, Type: "event", Event: raw}) {
				return
			}
		}
	}()
	defer func() {
		cancel(nil)
		_ = ws.UnderlyingConn().SetReadDeadline(time.Now())
		<-readDone
	}()
	select {
	case <-ctx.Done():
		return context.Cause(ctx)
	case <-h.done:
		return h.err
	case <-h.ready:
	}
	launch := windowsLocalEnvelope{ID: t.id, Type: "open", App: app, Project: project}
	if project != "" {
		s.windowsLocal.tabsMu.Lock()
		t.folders = []string{project}
		s.windowsLocal.tabsMu.Unlock()
		mount, release, err := s.openWindowsLocalVolume(ctx, project)
		if err != nil {
			return err
		}
		releaseVolume = release
		launch.Mount = mount
	}
	opened = h.send(ctx, launch)
	if !opened {
		if ctx.Err() != nil {
			return context.Cause(ctx)
		}
		<-h.done
		return h.err
	}
	for {
		select {
		case <-ctx.Done():
			return context.Cause(ctx)
		case <-h.done:
			return h.err
		case frame := <-t.frames:
			if frame.Type == "error" {
				return errors.New(frame.Message)
			}
			if !admitted.Load() {
				if frame.Type != "ready" || frame.InstanceID != h.binding.InstanceID || frame.WorkerSID != h.binding.WorkerSID ||
					(app == "terminal" && (frame.WorkerUsername == "" || frame.IntegrityLabel != "Low")) {
					return errors.New("未能核实标签页的隔离账户或权限。")
				}
				admitted.Store(true)
			} else {
				switch {
				case frame.Type == "exit":
					if app == "terminal" && frame.Code != 0 {
						return fmt.Errorf("PowerShell 已退出，退出码为 %d。", frame.Code)
					}
					return nil
				case frame.Type == "ready" || (app == "terminal" && frame.Type != "output"):
					return errors.New("隔离标签页返回了意外消息。")
				}
			}
			_ = ws.SetWriteDeadline(time.Now().Add(5 * time.Second))
			if err := ws.WriteMessage(websocket.TextMessage, frame.raw); err != nil {
				return err
			}
		}
	}
}
