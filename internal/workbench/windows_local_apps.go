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
	"strings"
	"time"

	agentvm "github.com/sylvinus/agent-vm"
	"github.com/sylvinus/agent-vm/internal/host"
)

func (s *Server) windowsLocalApp(w http.ResponseWriter, r *http.Request) {
	app := r.PathValue("app")
	if app != "desktop" && app != "editor" {
		http.NotFound(w, r)
		return
	}
	s.serveWindowsLocalTab(w, r, app)
}

func (s *Server) windowsLocalDesktopImport(w http.ResponseWriter, r *http.Request) {
	if !readJSON(w, r, &struct{}{}, 1024) {
		return
	}
	p := s.windowsLocal
	bound := p.active.Load()
	if bound == nil || !p.op.TryLock() {
		http.Error(w, "请先确认隔离账户并关闭当前会话。", http.StatusConflict)
		return
	}
	defer p.op.Unlock()
	verify := func() (string, error) {
		ctx, cancel := context.WithTimeout(r.Context(), 25*time.Second)
		defer cancel()
		cfg, err := s.checkLocalAppRoute(ctx)
		if err != nil {
			return "", err
		}
		return cfg.Fingerprint(), nil
	}
	applied, err := verify()
	if err != nil {
		requestError(w, err)
		return
	}
	dir, err := os.MkdirTemp(s.profile, ".desktop-import-")
	if err != nil {
		requestError(w, errors.New("无法准备工作台的临时目录。"))
		return
	}
	defer os.RemoveAll(dir)
	const importer = "tools/windows-local/Import-CageLocalDesktop.ps1"
	for _, name := range []string{importer, "scripts/guest-os/claude-desktop-windows.ps1"} {
		data, err := agentvm.WindowsLocalDesktopScripts.ReadFile(name)
		if err != nil || os.WriteFile(filepath.Join(dir, filepath.Base(name)), data, 0600) != nil {
			requestError(w, errors.New("无法读取内置的安装包核验工具。"))
			return
		}
	}
	run := func(ctx context.Context, args ...string) ([]byte, error) {
		ps := filepath.Join(os.Getenv("SystemRoot"), "System32", "WindowsPowerShell", "v1.0", "powershell.exe")
		options := []string{"-NoLogo", "-NoProfile", "-NonInteractive", "-STA", "-ExecutionPolicy", "Bypass", "-File", filepath.Join(dir, filepath.Base(importer))}
		cmd := exec.CommandContext(ctx, ps, append(options, args...)...)
		cmd.Dir = dir
		host.HideCommandWindow(cmd)
		var output, diagnostic bytes.Buffer
		cmd.Stdout = &boundedWindowsStatusWriter{buffer: &output, remaining: 128 << 10}
		cmd.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4 << 10}
		if err := cmd.Run(); err != nil {
			line, _, _ := strings.Cut(strings.TrimSpace(diagnostic.String()), "\n")
			return nil, errors.New("未能完成安装包操作。" + strings.TrimSpace(line))
		}
		return output.Bytes(), nil
	}
	choice, err := run(r.Context(), "-ChoosePackage")
	if err != nil {
		requestError(w, err)
		return
	}
	var picked struct{ Package *string }
	if json.Unmarshal(choice, &picked) != nil || picked.Package == nil {
		requestError(w, errors.New("未收到文件选择器的结果。"))
		return
	}
	if *picked.Package == "" {
		jsonReply(w, map[string]bool{"imported": false})
		return
	}
	if !filepath.IsAbs(*picked.Package) || len(filepath.VolumeName(*picked.Package)) != 2 || !strings.EqualFold(filepath.Ext(*picked.Package), ".msix") {
		requestError(w, errors.New("请选择本机磁盘上的官方 x64 .msix 安装包。"))
		return
	}
	current, err := verify()
	if err != nil || current != applied || !s.op.TryLock() {
		http.Error(w, "节点或工作台设置已变化，请重新应用节点后再试。", http.StatusConflict)
		return
	}
	defer s.op.Unlock()
	cfg, err := loadConfig(s.configPath)
	if err != nil || cfg.Fingerprint() != current || p.active.Load() != bound {
		http.Error(w, "节点或隔离账户已变化，请重新选择安装包。", http.StatusConflict)
		return
	}
	// Finish an admitted signature check and atomic directory move even when
	// the requesting page is closed, so the script can clean up its staging.
	_, err = run(context.Background(), "-PackagePath", *picked.Package, "-ProfilePath", p.profile, "-BoundInstance", bound.InstanceID, "-BoundWorkerSid", bound.WorkerSID)
	if err != nil {
		requestError(w, err)
		return
	}
	info := p.inspect(context.Background(), false)
	if !info.Available || !info.DesktopInstalled || info.InstanceID != bound.InstanceID || info.WorkerSID != bound.WorkerSID {
		http.Error(w, "未能确认此账户的 Claude Desktop 安装状态。", http.StatusConflict)
		return
	}
	p.components.Store(&info)
	jsonReply(w, map[string]bool{"imported": true})
}
