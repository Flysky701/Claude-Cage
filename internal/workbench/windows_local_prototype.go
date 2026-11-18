package workbench

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strings"
	"sync"
	"sync/atomic"
	"time"

	"github.com/sylvinus/agent-vm/internal/host"
)

type windowsLocalPrototype struct {
	helper, profile, bindingPath string
	active                       atomic.Pointer[windowsLocalBinding]
	components                   atomic.Pointer[windowsLocalStatus]
	network                      windowsLocalNetwork
	op                           sync.Mutex
	volumeMu                     sync.Mutex
	volumes                      map[string]*windowsLocalVolume
	tabsMu                       sync.Mutex
	tabs                         *windowsLocalHub
	projectMu                    sync.Mutex
	projectView                  *windowsLocalProjectView
	projectViewUntil             time.Time
}

type windowsLocalBinding struct {
	InstanceID string `json:"instance_id"`
	WorkerSID  string `json:"worker_sid"`
}

func configuredWindowsLocal(workbenchProfile string) *windowsLocalPrototype {
	helper := os.Getenv("CAGE_WINDOWS_LOCAL_HELPER")
	if runtime.GOOS != "windows" || helper == "" {
		return nil
	}
	p := &windowsLocalPrototype{helper: helper, profile: os.Getenv("CAGE_WINDOWS_LOCAL_PROFILE"),
		bindingPath: filepath.Join(workbenchProfile, "windows-local-workbench.json")}
	p.network.readSelection(workbenchProfile)
	if _, err := os.Stat(p.bindingPath); err == nil {
		// A saved choice is effective only while the same isolated account verifies.
		_ = p.activate(context.Background(), false)
	}
	return p
}

func (p *windowsLocalPrototype) activate(ctx context.Context, firstSetup bool) error {
	receipt := p.inspect(ctx, false)
	if !receipt.Available {
		return errors.New(receipt.Message)
	}
	next := windowsLocalBinding{InstanceID: receipt.InstanceID, WorkerSID: receipt.WorkerSID}
	data, err := os.ReadFile(p.bindingPath)
	switch {
	case err == nil:
		var saved windowsLocalBinding
		if json.Unmarshal(data, &saved) != nil || saved != next {
			return errors.New("此工作台已绑定其他账户或绑定记录无法读取，请使用原来的账户档案。")
		}
	case firstSetup && errors.Is(err, os.ErrNotExist):
		if err := writePrivate(p.bindingPath, next); err != nil {
			return err
		}
	default:
		return err
	}
	p.components.Store(&receipt)
	p.active.Store(&next)
	return nil
}

func (p *windowsLocalPrototype) workbenchStatus() map[string]any {
	ready := p.active.Load() != nil
	components := p.components.Load()
	if components == nil {
		components = &windowsLocalStatus{}
	}
	network := p.network.state()
	mode := "offline"
	if network.Open {
		mode = "proxy"
	}
	return map[string]any{
		"guest_system": "windows-local", "windows_local_prototype": true, "ready": ready,
		"vm_running": false, "local_vm_storage": false, "workspace": "", "projects": []string{}, "project_groups": []projectGroup{},
		"local_network": network,
		"guest_capabilities": map[string]any{"network": mode, "available": map[string]bool{
			"network":  network.Open,
			"terminal": ready, "projects": ready, "browser": ready && components.BrowserInstalled, "claude-cli": ready && components.CLIInstalled,
			"editor": ready && components.EditorInstalled, "desktop": ready && components.DesktopInstalled,
			"claude-accounts": ready && components.CLIInstalled, "tailscale": ready && components.TailnetInstalled,
		}},
	}
}

// The opt-in controller has no guest VM. Only route operations backed by
// its actual local components. Remote destinations select their own handler.
func (p *windowsLocalPrototype) supports(r *http.Request) bool {
	path := r.URL.Path
	if windowsLocalSessionRoute(r.Method, path) {
		return p.active.Load() != nil
	}
	if !strings.HasPrefix(path, "/api/") || strings.HasPrefix(path, "/api/account/") ||
		strings.HasPrefix(path, "/api/diagnostics/") {
		return true
	}
	switch path {
	case "/api/projects/open", "/api/projects/save", "/api/projects/remove", "/api/projects/directories",
		"/api/windows-local/terminal", "/api/windows-local/browser", "/api/windows-local/apps/editor", "/api/windows-local/apps/desktop", "/api/windows-local/apps/desktop/import",
		"/api/windows-local/services/accounts", "/api/windows-local/services/tailnet", "/api/windows-local/network", "/api/windows-local/projects":
		return p.active.Load() != nil
	case "/api/proxy", "/api/proxy/select", "/api/proxy/route", "/api/proxy/import", "/api/proxy/refresh",
		"/api/proxy/delete", "/api/proxy/stop", "/api/proxy/restart", "/api/proxy/edit",
		"/api/proxy/logs", "/api/proxy/connections":
		return p.active.Load() != nil
	case "/api/windows-local/status", "/api/windows-local/probe", "/api/environment/initialization",
		"/api/status", "/api/account", "/api/session", "/api/launch", "/api/handoff", "/api/remote/manifest", "/api/appearance",
		"/api/appearance/codex", "/api/favorites", "/api/diagnostics":
		return true
	case "/api/settings":
		return r.Method == http.MethodGet
	}
	return false
}

// The shared terminal and Claude history UI also serves VM-backed environments.
// Admit only the operations implemented by the Windows local session provider.
func windowsLocalSessionRoute(method, path string) bool {
	switch path {
	case "/api/terminals":
		return method == http.MethodGet || method == http.MethodPost
	case "/api/cli/sessions":
		return method == http.MethodGet
	}
	if rest, ok := strings.CutPrefix(path, "/api/terminals/"); ok {
		id, action, more := strings.Cut(rest, "/")
		return id != "" && ((!more && method == http.MethodDelete) ||
			(action == "stream" && method == http.MethodGet) || (action == "metadata" && method == http.MethodPost))
	}
	if rest, ok := strings.CutPrefix(path, "/api/cli/sessions/"); ok {
		id, action, _ := strings.Cut(rest, "/")
		return id != "" && method == http.MethodPost && (action == "open" || action == "metadata" || action == "archive" || action == "restore")
	}
	return false
}

type windowsLocalStatus struct {
	BrowserInstalled  bool   `json:"browser_installed"`
	EditorInstalled   bool   `json:"editor_installed"`
	DesktopInstalled  bool   `json:"desktop_installed"`
	CLIInstalled      bool   `json:"cli_installed"`
	TailnetInstalled  bool   `json:"tailnet_installed"`
	Available         bool   `json:"available"`
	Message           string `json:"message"`
	InstanceID        string `json:"instance_id,omitempty"`
	WorkerUsername    string `json:"worker_username,omitempty"`
	WorkerSID         string `json:"worker_sid,omitempty"`
	RulesVerified     bool   `json:"rules_verified,omitempty"`
	ProbePassed       bool   `json:"probe_passed,omitempty"`
	PowerShellVersion string `json:"powershell_version,omitempty"`
}

func (p *windowsLocalPrototype) serve(w http.ResponseWriter, r *http.Request) {
	probe := r.Method == http.MethodPost
	if probe && !readJSON(w, r, &struct{}{}, 1024) {
		return
	}
	if probe {
		if !p.op.TryLock() {
			http.Error(w, "本地账户正在使用，请关闭当前终端或等待检查完成。", http.StatusConflict)
			return
		}
		defer p.op.Unlock()
	}
	receipt := p.inspect(r.Context(), probe)
	if bound := p.active.Load(); bound != nil && receipt.Available &&
		receipt.InstanceID == bound.InstanceID && receipt.WorkerSID == bound.WorkerSID {
		p.components.Store(&receipt)
	}
	jsonReply(w, receipt)
}

func (p *windowsLocalPrototype) checkPaths() error {
	for _, file := range []struct{ path, missing string }{
		{p.helper, "未找到本地账户工具，请重新构建原型。"},
		{p.profile, "未找到隔离账户档案。请先初始化专用 Windows 账户，或在启动时指定已有档案。"},
	} {
		if !filepath.IsAbs(file.path) || len(filepath.VolumeName(file.path)) != 2 {
			return errors.New("原型需要本机磁盘上的绝对工具路径和档案路径。")
		}
		info, err := os.Stat(file.path)
		if errors.Is(err, os.ErrNotExist) {
			return errors.New(file.missing)
		}
		if err != nil || !info.Mode().IsRegular() {
			return errors.New("无法读取本地账户工具或档案，请检查路径和权限。")
		}
	}
	return nil
}

func (p *windowsLocalPrototype) inspect(ctx context.Context, probe bool) windowsLocalStatus {
	if err := p.checkPaths(); err != nil {
		return windowsLocalStatus{Message: err.Error()}
	}
	if ctx.Err() != nil {
		return windowsLocalStatus{Message: "检查已取消。"}
	}
	ctx, cancel := context.WithTimeout(ctx, 30*time.Second)
	defer cancel()
	var cmd *exec.Cmd
	if probe {
		// The short-lived worker has its own timeouts. Once admitted, allow the
		// controller to restore desktop ACLs even if the browser closes.
		cmd = exec.Command(p.helper, "workbench-probe", "--profile", p.profile)
	} else {
		cmd = exec.CommandContext(ctx, p.helper, "workbench-inspect", "--profile", p.profile)
	}
	host.HideCommandWindow(cmd)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &boundedWindowsStatusWriter{buffer: &stdout, remaining: 16 << 10}
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &stderr, remaining: 4 << 10}
	cmd.WaitDelay = 2 * time.Second
	if err := cmd.Run(); err != nil {
		message := "本地账户检查失败。"
		if line, _, _ := strings.Cut(strings.TrimSpace(stderr.String()), "\n"); line != "" {
			message += " " + strings.TrimSpace(line)
		}
		return windowsLocalStatus{Message: message}
	}
	var receipt struct {
		BrowserInstalled, EditorInstalled, DesktopInstalled, CLIInstalled, TailnetInstalled                              bool
		InstanceID, WorkerUsername, WorkerSID, ObservedSID, ObservedUsername, IntegrityLabel, Desktop, PowerShellVersion string
		InstalledFilters, RequiredFilters                                                                                int
		RulesVerified                                                                                                    bool
	}
	if json.Unmarshal(stdout.Bytes(), &receipt) != nil || receipt.InstanceID == "" ||
		receipt.WorkerUsername == "" || receipt.WorkerSID == "" ||
		!receipt.RulesVerified || receipt.RequiredFilters != 7 || receipt.InstalledFilters != receipt.RequiredFilters {
		return windowsLocalStatus{Message: "工具未返回完整的账户信息和七条网络规则的核验结果。"}
	}
	result := windowsLocalStatus{Available: true, Message: "已核验专用账户、受保护的凭据和七条网络隔离规则。",
		BrowserInstalled: receipt.BrowserInstalled, EditorInstalled: receipt.EditorInstalled, DesktopInstalled: receipt.DesktopInstalled, CLIInstalled: receipt.CLIInstalled, TailnetInstalled: receipt.TailnetInstalled,
		InstanceID: receipt.InstanceID, WorkerUsername: receipt.WorkerUsername, WorkerSID: receipt.WorkerSID, RulesVerified: true}
	if probe {
		if !strings.EqualFold(receipt.ObservedSID, receipt.WorkerSID) || !strings.EqualFold(receipt.ObservedUsername, receipt.WorkerUsername) ||
			receipt.IntegrityLabel != "Medium" || receipt.Desktop == "" || receipt.PowerShellVersion == "" {
			return windowsLocalStatus{Message: "未能核实 PowerShell 所用的隔离身份。"}
		}
		result.Message = "PowerShell 已在专用账户的私有桌面上运行并退出。"
		result.ProbePassed = true
		result.PowerShellVersion = receipt.PowerShellVersion
	}
	return result
}
