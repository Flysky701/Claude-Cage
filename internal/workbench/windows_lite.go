package workbench

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"time"

	"github.com/sylvinus/agent-vm/internal/cage"
	"github.com/sylvinus/agent-vm/internal/containerenv"
	"github.com/sylvinus/agent-vm/internal/guestos"
	"github.com/sylvinus/agent-vm/internal/windowslite"
)

const windowsLiteKind = "windows-lite"
const windowsLiteUnverified = "Windows 轻量空间尚未完成真实隔离与出口验证，应用保持未启动。"

var startWindowsLiteWorker = windowslite.StartWorker
var windowsLiteHostAvailable = func() bool { return runtime.GOOS == "windows" && runtime.GOARCH == "amd64" }

type windowsLiteMode struct {
	Version int    `json:"version"`
	Kind    string `json:"kind"`
}

type windowsLiteSnapshot struct {
	Phase        string             `json:"phase"`
	Message      string             `json:"message"`
	Profile      string             `json:"profile"`
	BoxName      string             `json:"boxName"`
	Network      string             `json:"network"`
	Checks       []map[string]any   `json:"checks"`
	Applications []map[string]any   `json:"applications"`
	Settings     map[string]any     `json:"settings"`
	ProcessCount int                `json:"processCount"`
	Acceptance   string             `json:"acceptance"`
	Capabilities map[string]bool    `json:"capabilities,omitempty"`
	Monitor      windowsLiteMonitor `json:"monitor"`
}

type windowsLiteMonitor struct {
	Phase         string           `json:"phase"`
	LastCheckedAt time.Time        `json:"lastCheckedAt"`
	ValidUntil    time.Time        `json:"validUntil"`
	SessionID     string           `json:"sessionId"`
	ConfigHash    string           `json:"configHash"`
	Reason        string           `json:"reason"`
	Checks        []map[string]any `json:"checks"`
}

func windowsLiteAdmitted(state windowsLiteSnapshot) bool {
	now := time.Now()
	return state.Phase == "running" && state.Acceptance == "verified" && state.Network == "open" &&
		state.Monitor.Phase == "healthy" && state.Monitor.SessionID != "" && len(state.Monitor.ConfigHash) == 64 &&
		!state.Monitor.LastCheckedAt.IsZero() && !state.Monitor.LastCheckedAt.After(now.Add(5*time.Second)) &&
		state.Monitor.ValidUntil.After(now) && state.Monitor.ValidUntil.Sub(state.Monitor.LastCheckedAt) <= 90*time.Second
}

type windowsLiteRuntime struct {
	mu      sync.Mutex
	stateMu sync.RWMutex
	worker  windowslite.Worker
	state   windowsLiteSnapshot
}

type windowsLiteReply struct {
	OK      bool                `json:"ok"`
	Error   string              `json:"error"`
	State   windowsLiteSnapshot `json:"state"`
	Launch  json.RawMessage     `json:"launch,omitempty"`
	Browser json.RawMessage     `json:"browser,omitempty"`
}

func decodeWindowsLiteReply(data []byte) (windowsLiteReply, error) {
	var reply windowsLiteReply
	var raw struct {
		State map[string]json.RawMessage `json:"state"`
	}
	if json.Unmarshal(data, &reply) != nil || json.Unmarshal(data, &raw) != nil {
		return reply, errors.New("空间管理组件返回了无效状态，未放行应用")
	}
	for _, field := range []string{"phase", "network", "processCount", "acceptance", "profile"} {
		if value, present := raw.State[field]; !present || string(value) == "null" {
			return reply, errors.New("空间状态证据不完整，网络状态待确认")
		}
	}
	state := reply.State
	if state.Network != "closed" && state.Network != "open" && state.Network != "unknown" || state.ProcessCount < -1 || state.Profile == "" {
		return reply, errors.New("空间网络或进程状态无效，未放行应用")
	}
	switch state.Phase {
	case "stopped", "starting", "running", "blocked", "stopping", "error":
	default:
		return reply, errors.New("空间运行状态无效，未放行应用")
	}
	if state.Acceptance != "not-verified" && state.Acceptance != "verified" ||
		state.Network == "open" && (state.Acceptance != "verified" || state.Phase != "running" || state.ProcessCount < 0) ||
		state.Phase == "stopped" && (state.ProcessCount != 0 || state.Network != "closed") {
		return reply, errors.New("空间验证状态不一致，未放行应用")
	}
	if state.Network == "open" && !windowsLiteAdmitted(state) {
		return reply, errors.New("应用监控证据已失效，禁止启动；请重新检查空间")
	}
	return reply, nil
}

func (s *Server) isWindowsLite() bool { return s.windowsLite.Load() != nil }

func (s *Server) windowsLiteProfile() string { return filepath.Join(s.profile, windowsLiteKind) }

func (s *Server) initialWindowsLiteState() windowsLiteSnapshot {
	return windowsLiteSnapshot{
		Phase: "blocked", Message: windowsLiteUnverified, Profile: s.windowsLiteProfile(),
		Network: "unknown", ProcessCount: -1, Acceptance: "not-verified",
		Checks:       []map[string]any{{"id": "isolation", "label": "隔离与出口实测", "ok": false, "message": windowsLiteUnverified}},
		Applications: []map[string]any{}, Settings: map[string]any{"connectionFile": s.configPath, "applications": map[string]any{}},
	}
}

func windowsLiteSelected(profile string) (bool, error) {
	data, err := os.ReadFile(filepath.Join(profile, "windows-lite.json"))
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	var mode windowsLiteMode
	decoder := json.NewDecoder(bytes.NewReader(data))
	decoder.DisallowUnknownFields()
	if len(data) > 4096 || decoder.Decode(&mode) != nil || mode.Version != 1 || mode.Kind != windowsLiteKind {
		return false, errors.New("轻量空间模式记录无效，请保留原文件并检查配置")
	}
	var extra any
	if decoder.Decode(&extra) != io.EOF {
		return false, errors.New("轻量空间模式记录包含多余内容，未切换运行后端")
	}
	return true, nil
}

func (s *Server) loadWindowsLiteMode() error {
	selected, err := windowsLiteSelected(s.profile)
	if err != nil || !selected {
		return err
	}
	// Backend selection survives unavailable Python/Sandboxie dependencies. Never
	// turn a failed worker start into a Linux or Hyper-V fallback.
	s.windowsLite.Store(&windowsLiteRuntime{state: s.initialWindowsLiteState()})
	return nil
}

func (s *Server) windowsLiteState() windowsLiteSnapshot {
	backend := s.windowsLite.Load()
	if backend == nil {
		return s.initialWindowsLiteState()
	}
	backend.stateMu.RLock()
	defer backend.stateMu.RUnlock()
	// Clone nested maps: HTTP rendering and subsequent worker calls are separate.
	data, _ := json.Marshal(backend.state)
	var result windowsLiteSnapshot
	_ = json.Unmarshal(data, &result)
	return result
}

func (s *Server) windowsLiteRunning() bool {
	state := s.windowsLiteState()
	return state.ProcessCount > 0 || state.Phase == "running"
}

func windowsLiteCapabilities(state windowsLiteSnapshot) map[string]bool {
	verified := windowsLiteAdmitted(state)
	capabilities := map[string]bool{"persistent_space": true, "application_entries": true,
		"sandbox_verified": verified, "network_verified": verified}
	for _, key := range []string{"embedded_browser", "embedded_desktop", "terminal_stream", "claude_terminal", "terminal_login", "cli_sessions", "embedded_editor", "project_sharing", "file_transfer", "shared_clipboard", "audio"} {
		capabilities[key] = verified && state.Capabilities[key]
	}
	return capabilities
}

func (s *Server) windowsLiteFeatureAvailable(feature string) bool {
	if !s.isWindowsLite() {
		return true
	}
	state := s.windowsLiteState()
	return windowsLiteAdmitted(state) && state.Capabilities[feature]
}

func (s *Server) windowsLiteCall(ctx context.Context, action string, extra map[string]any) (windowsLiteSnapshot, error) {
	reply, err := s.windowsLiteRequest(ctx, action, extra)
	s.mu.Lock()
	s.ready = err == nil && windowsLiteAdmitted(reply.State)
	s.mu.Unlock()
	return reply.State, err
}

// Internal launch plans never enter the public status endpoint.
func (s *Server) windowsLiteRequest(ctx context.Context, action string, extra map[string]any) (windowsLiteReply, error) {
	backend := s.windowsLite.Load()
	if backend == nil {
		return windowsLiteReply{State: s.initialWindowsLiteState()}, errors.New("当前环境未选择 Windows 轻量空间")
	}
	backend.mu.Lock()
	defer backend.mu.Unlock()
	fail := func(err error) (windowsLiteReply, error) {
		backend.stateMu.Lock()
		defer backend.stateMu.Unlock()
		backend.state.Phase, backend.state.Network = "blocked", "unknown"
		backend.state.ProcessCount = -1
		backend.state.Message, backend.state.Acceptance = err.Error(), "not-verified"
		return windowsLiteReply{State: backend.state}, err
	}
	if !windowsLiteHostAvailable() {
		return fail(errors.New("Windows 轻量空间仅支持 Windows x64；已保留模式和数据"))
	}
	if backend.worker == nil {
		worker, err := startWindowsLiteWorker(s.windowsLiteProfile())
		if err != nil {
			return fail(err)
		}
		backend.worker = worker
	}
	request := map[string]any{"action": action}
	for key, value := range extra {
		if key == "action" {
			return fail(errors.New("不允许覆盖空间操作类型"))
		}
		request[key] = value
	}
	data, err := json.Marshal(request)
	if err != nil {
		return fail(errors.New("空间请求无效"))
	}
	deadline := 15 * time.Second
	if action == "start" {
		deadline = 120 * time.Second
	}
	if action == "launch" || action == "prepare-terminal" || action == "attach-terminal" {
		deadline = 40 * time.Second
	}
	callContext, cancel := context.WithTimeout(ctx, deadline)
	defer cancel()
	response, err := backend.worker.Call(callContext, data)
	if err != nil {
		// A failed exchange cannot safely reuse the JSON-line stream. End that
		// worker and let the next user operation inspect the same persistent
		// space through a fresh controller; never repeat a mutation implicitly.
		_ = backend.worker.Close()
		backend.worker = nil
		return fail(errors.New("空间管理组件未能完成操作，网络状态待确认；原数据已保留"))
	}
	reply, err := decodeWindowsLiteReply(response)
	if err != nil {
		return fail(err)
	}
	backend.stateMu.Lock()
	backend.state = reply.State
	backend.stateMu.Unlock()
	if !reply.OK {
		if reply.Error == "" {
			reply.Error = reply.State.Message
		}
		if reply.Error == "" {
			reply.Error = windowsLiteUnverified
		}
		return reply, errors.New(reply.Error)
	}
	return reply, nil
}

func (s *Server) closeWindowsLite() error {
	backend := s.windowsLite.Load()
	if backend == nil {
		return nil
	}
	backend.mu.Lock()
	defer backend.mu.Unlock()
	if backend.worker == nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	response, stopErr := backend.worker.Call(ctx, json.RawMessage(`{"action":"stop"}`))
	cancel()
	if stopErr == nil {
		reply, err := decodeWindowsLiteReply(response)
		if err != nil {
			stopErr = err
		} else if !reply.OK || reply.State.Phase != "stopped" || reply.State.Network != "closed" || reply.State.ProcessCount != 0 {
			stopErr = errors.New("轻量空间未确认全部进程停止")
		} else {
			backend.stateMu.Lock()
			backend.state = reply.State
			backend.stateMu.Unlock()
		}
	}
	err := errors.Join(stopErr, backend.worker.Close())
	backend.worker = nil
	backend.stateMu.Lock()
	defer backend.stateMu.Unlock()
	if err != nil {
		backend.state.Phase, backend.state.Network = "error", "unknown"
		backend.state.ProcessCount = -1
		backend.state.Acceptance = "not-verified"
		backend.state.Message = "轻量空间未能确认完整停止，原数据已保留"
	} else {
		backend.state.Phase, backend.state.Network, backend.state.ProcessCount = "stopped", "closed", 0
	}
	return err
}

func (s *Server) startWindowsLite() error {
	if state, err := s.windowsLiteCall(s.operationContext(), "status", nil); err == nil && windowsLiteAdmitted(state) {
		s.setMessage("应用监控仍有效，空间继续运行")
		return nil
	}
	s.terminals.closeAll()
	s.closeWindowsBrowser()
	// The regular workbench's selected proxy remains the source of truth.
	_, err := s.windowsLiteCall(s.operationContext(), "configure", map[string]any{
		"settings": map[string]any{"connectionFile": s.configPath, "projectDirectory": s.workspace()},
	})
	if err != nil {
		return err
	}
	backend := s.windowsLite.Load()
	backend.stateMu.Lock()
	backend.state.Phase, backend.state.Network, backend.state.Acceptance = "starting", "closed", "not-verified"
	backend.state.Monitor = windowsLiteMonitor{Phase: "checking", Reason: "应用正在自动检查隔离、出口与断线阻断"}
	backend.state.Message = backend.state.Monitor.Reason
	backend.stateMu.Unlock()
	s.setMessage("应用正在自动检查隔离、出口与断线阻断…")
	_, err = s.windowsLiteCall(s.operationContext(), "start", nil)
	return err
}

func (s *Server) stopWindowsLite() error {
	s.terminals.closeAll()
	s.closeWindowsBrowser()
	_, err := s.windowsLiteCall(s.operationContext(), "stop", nil)
	return err
}

func (s *Server) selectEnvironmentRuntime(w http.ResponseWriter, r *http.Request) {
	if !s.hasTrustedView(r) || s.clientOnly || s.desktopEntry {
		http.Error(w, "请在本机 Cage 工作台选择运行模式", http.StatusForbidden)
		return
	}
	var input struct {
		Kind string `json:"kind"`
	}
	if !readJSON(w, r, &input) {
		return
	}
	if input.Kind != windowsLiteKind || !windowsLiteHostAvailable() {
		http.Error(w, "当前主机不支持所选运行模式", http.StatusBadRequest)
		return
	}
	if !s.op.TryLock() {
		http.Error(w, "环境操作正在进行，请稍后重试", http.StatusConflict)
		return
	}
	defer s.op.Unlock()
	if s.isWindowsLite() {
		jsonReply(w, map[string]any{"runtime_kind": windowsLiteKind, "state": s.windowsLiteState()})
		return
	}
	if s.busy() || s.macosGuest != nil || s.windowsGuest != nil || containerenv.Configured(s.profile) {
		http.Error(w, "已有运行环境，请使用独立配置测试轻量空间；原环境保持不变", http.StatusConflict)
		return
	}
	pending, err := guestos.LoadInstallation(s.profile)
	if err != nil || pending != nil {
		http.Error(w, "已有客户机安装记录，未切换运行模式；原数据已保留", http.StatusConflict)
		return
	}
	location, err := cage.GetStorageLocation(s.profile)
	if err != nil || location.HasEnvironment {
		http.Error(w, "已有环境数据或状态无法确认，请使用独立配置测试；原数据已保留", http.StatusConflict)
		return
	}
	if err := writePrivate(filepath.Join(s.profile, "windows-lite.json"), windowsLiteMode{Version: 1, Kind: windowsLiteKind}); err != nil {
		requestError(w, err)
		return
	}
	s.windowsLite.Store(&windowsLiteRuntime{state: s.initialWindowsLiteState()})
	s.mu.Lock()
	s.ready, s.safety.Gate, s.safety.Report = false, nil, nil
	s.mu.Unlock()
	jsonReply(w, map[string]any{"runtime_kind": windowsLiteKind, "state": s.windowsLiteState()})
}

func (s *Server) windowsLiteEndpoint(w http.ResponseWriter, r *http.Request) {
	if !s.isWindowsLite() {
		http.Error(w, "当前环境未选择 Windows 轻量空间", http.StatusConflict)
		return
	}
	if r.Method == http.MethodPost && r.URL.Path == "/api/windows-lite/check" {
		var input struct{}
		if !readJSON(w, r, &input) {
			return
		}
		s.launch(w, "start", s.startWindowsLite)
		return
	}
	action := "status"
	var extra map[string]any
	if r.Method != http.MethodGet {
		if !s.op.TryLock() {
			http.Error(w, "空间操作正在进行，请稍后重试", http.StatusConflict)
			return
		}
		defer s.op.Unlock()
		if s.busy() {
			http.Error(w, "环境操作正在进行，请稍后重试", http.StatusConflict)
			return
		}
		switch r.URL.Path {
		case "/api/windows-lite/check":
			action = "start"
			var input struct{}
			if !readJSON(w, r, &input) {
				return
			}
		case "/api/windows-lite/launch":
			action = "launch"
			var input struct {
				Entry string `json:"entry"`
			}
			if !readJSON(w, r, &input) {
				return
			}
			extra = map[string]any{"entry": input.Entry}
		default:
			action = "configure"
			var input struct {
				Settings map[string]any `json:"settings"`
			}
			if !readJSON(w, r, &input, 1<<20) {
				return
			}
			if input.Settings == nil {
				http.Error(w, "缺少空间设置", http.StatusBadRequest)
				return
			}
			input.Settings["connectionFile"] = s.configPath
			input.Settings["projectDirectory"] = s.workspace()
			extra = map[string]any{"settings": input.Settings}
		}
	}
	if action == "start" {
		_, err := s.windowsLiteCall(r.Context(), "configure", map[string]any{"settings": map[string]any{"connectionFile": s.configPath, "projectDirectory": s.workspace()}})
		if err != nil {
			http.Error(w, err.Error(), http.StatusConflict)
			return
		}
	}
	state, err := s.windowsLiteCall(r.Context(), action, extra)
	if err != nil && r.Method != http.MethodGet {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	reply := map[string]any{"ok": err == nil, "state": state}
	if err != nil {
		reply["error"] = err.Error()
	}
	jsonReply(w, reply)
}

// Keep the existing account, settings, proxy, projects, favorites and diagnostic
// control plane. Guest-specific routes require explicit Lite implementations.
func windowsLiteWorkbenchRoute(method, path string) bool {
	if !strings.HasPrefix(path, "/api/") {
		return true
	}
	for _, prefix := range []string{"/api/account/", "/api/proxy/", "/api/projects/", "/api/diagnostics/", "/api/windows-lite/", "/api/appearance/", "/api/browser/", "/api/terminals/"} {
		if strings.HasPrefix(path, prefix) {
			return true
		}
	}
	switch path {
	case "/api/browser", "/api/terminals", "/api/vnc", "/api/vnc-credentials", "/api/input":
		return true
	case "/api/status", "/api/settings", "/api/settings/probe", "/api/proxy", "/api/account", "/api/favorites", "/api/appearance", "/api/diagnostics", "/api/client/about", "/api/session", "/api/launch", "/api/handoff", "/api/remote/manifest", "/api/agent/routes", "/api/start", "/api/stop", "/api/restore", "/api/windows-lite", "/api/environment/runtime", "/api/environment/initialization", "/api/claude-accounts", "/api/vault", "/api/safety/check", "/api/safety/close", "/api/safety/report":
		return true
	case "/api/environment/guest-systems":
		return method == http.MethodGet
	}
	return false
}

func (s *Server) applyWindowsLiteSettings(v savedProfile) error {
	old, err := loadConfig(s.configPath)
	if err != nil {
		return err
	}
	v.Config.ProxyURL, v.Config.ProxyRevision = old.ProxyURL, old.ProxyRevision
	s.mu.Lock()
	previous := s.preferences
	s.mu.Unlock()
	if old != v.Config || previous.Workspace != v.Preferences.Workspace {
		if err := s.requireWindowsLiteStopped(s.operationContext()); err != nil {
			return err
		}
	}
	if err := writePrivate(filepath.Join(s.profile, "previous-profile.json"), savedProfile{old, previous}); err != nil {
		return err
	}
	if err := writePrivate(s.configPath, v.Config); err != nil {
		return err
	}
	if err := writePrivate(filepath.Join(s.profile, "workbench.json"), v.Preferences); err != nil {
		return err
	}
	s.mu.Lock()
	s.preferences = v.Preferences
	s.ready, s.safety.Gate, s.safety.Report = false, nil, nil
	s.mu.Unlock()
	return nil
}
