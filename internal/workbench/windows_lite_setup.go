package workbench

import (
	"context"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"time"

	"github.com/sylvinus/agent-vm/internal/cage"
	"github.com/sylvinus/agent-vm/internal/containerenv"
	"github.com/sylvinus/agent-vm/internal/guestos"
	"github.com/sylvinus/agent-vm/internal/host"
	"github.com/sylvinus/agent-vm/internal/hostproxy"
	"github.com/sylvinus/agent-vm/internal/windowslite"
)

type windowsLiteSetupRecord struct {
	Version          int       `json:"version"`
	Completed        bool      `json:"completed"`
	Directory        string    `json:"sandboxie_directory"`
	ComponentVersion string    `json:"component_version"`
	CompletedAt      time.Time `json:"completed_at"`
}

type windowsLiteSystemCheck struct {
	Installed       bool   `json:"installed"`
	ServicesRunning bool   `json:"servicesRunning"`
	WFPEnabled      bool   `json:"wfpEnabled"`
	Version         string `json:"version"`
	Directory       string `json:"directory"`
	Message         string `json:"message"`
}

func (s *Server) windowsLiteReview() bool {
	if !windowsLiteHostAvailable() {
		return false
	}
	info, err := os.Stat(filepath.Join(filepath.Dir(s.exe), "windows-lite-workbench"))
	return err == nil && info.Mode().IsRegular()
}

// Component installation is deliberately separate from application admission.
func (s *Server) windowsLiteComponentsPrepared() (bool, error) {
	data, err := os.ReadFile(filepath.Join(s.windowsLiteProfile(), "setup.json"))
	if errors.Is(err, os.ErrNotExist) {
		return false, nil
	}
	if err != nil {
		return false, err
	}
	var record windowsLiteSetupRecord
	if len(data) > 8192 || json.Unmarshal(data, &record) != nil || record.Version != 1 || !filepath.IsAbs(record.Directory) {
		return false, errors.New("轻量沙箱安装记录无效，原数据已保留，请重新检查组件")
	}
	return record.Completed, nil
}

// Caller owns the workbench operation lock. Never replace another environment.
func (s *Server) chooseWindowsLiteLocked() error {
	if s.isWindowsLite() {
		return nil
	}
	if !windowsLiteHostAvailable() {
		return errors.New("轻量沙箱目前仅支持 Windows x64")
	}
	mac, macErr := guestos.LoadMacOSProfile(s.profile)
	win, winErr := guestos.LoadWindowsProfile(s.profile)
	if macErr != nil || winErr != nil || mac != nil || win != nil || s.macosGuest != nil || s.windowsGuest != nil || containerenv.Configured(s.profile) {
		return errors.New("此配置已有运行环境，请使用独立配置安装轻量沙箱；原环境保留")
	}
	pending, err := guestos.LoadInstallation(s.profile)
	if err != nil || pending != nil {
		return errors.New("已有系统安装记录，未切换环境；原数据保留")
	}
	location, err := cage.GetStorageLocation(s.profile)
	if err != nil || location.HasEnvironment {
		return errors.New("已有环境数据或状态无法确认，未切换环境；原数据保留")
	}
	if err := writePrivate(filepath.Join(s.profile, "windows-lite.json"), windowsLiteMode{Version: 1, Kind: windowsLiteKind}); err != nil {
		return err
	}
	s.windowsLite.Store(&windowsLiteRuntime{state: s.initialWindowsLiteState()})
	s.mu.Lock()
	s.ready, s.safety.Gate, s.safety.Report = false, nil, nil
	s.mu.Unlock()
	return nil
}

func (s *Server) setupWindowsLiteEndpoint(w http.ResponseWriter, r *http.Request) {
	if !s.hasTrustedView(r) || s.clientOnly || s.desktopEntry || !windowsLiteHostAvailable() {
		http.Error(w, "请在 Windows x64 本机工作台安装轻量沙箱", http.StatusForbidden)
		return
	}
	var input struct{}
	if !readJSON(w, r, &input) {
		return
	}
	s.launch(w, "windows-lite-setup", s.setupWindowsLite)
}

func (s *Server) liteSetupStage(phase, label string) {
	s.setMessage(label)
	s.jobs.execution().setSetupProgress(&SetupProgress{Phase: phase, System: windowsLiteKind, Label: label})
}

func (s *Server) checkWindowsLiteSystem(ctx context.Context, directory, backup string) (windowsLiteSystemCheck, error) {
	var result windowsLiteSystemCheck
	resources := filepath.Dir(s.exe)
	python := filepath.Join(resources, "python", "python.exe")
	script := filepath.Join(resources, "windows-lite", "setup.py")
	args := []string{"-I", "-B", script, "--sandboxie-dir", directory, "--check"}
	if backup != "" {
		args = []string{"-I", "-B", script, "--sandboxie-dir", directory, "--enable-wfp", "--backup-dir", backup}
	}
	probeCtx, cancel := context.WithTimeout(ctx, 45*time.Second)
	defer cancel()
	cmd := exec.CommandContext(probeCtx, python, args...)
	host.HideCommandWindow(cmd)
	data, err := cmd.Output()
	if len(data) > 65536 || json.Unmarshal(data, &result) != nil {
		return result, errors.New("运行组件未返回有效检查结果，请重新下载完整测试包")
	}
	if err != nil {
		if result.Message != "" {
			return result, errors.New(result.Message)
		}
		return result, errors.New("轻量沙箱组件检查失败，原数据保留")
	}
	return result, nil
}

func (s *Server) setupWindowsLite() error {
	if runtime.GOOS != "windows" {
		return errors.New("轻量沙箱仅支持 Windows")
	}
	if err := s.chooseWindowsLiteLocked(); err != nil {
		return err
	}
	ctx := s.operationContext()
	profile := s.windowsLiteProfile()
	if err := host.EnsurePrivateDir(profile); err != nil {
		return err
	}
	if err := checkWindowsLiteInstaller(ctx, filepath.Join(profile, "downloads", "installer-running.json")); err != nil {
		return err
	}
	s.liteSetupStage("image", "正在检查轻量沙箱组件…")
	directory := filepath.Join(os.Getenv("ProgramFiles"), "Sandboxie-Plus")
	state, err := s.windowsLiteCall(ctx, "status", nil)
	if err != nil {
		return err
	}
	if state.ProcessCount != 0 || state.Network != "closed" {
		return errors.New("请先停止轻量空间，确认所属进程已退出后再安装组件")
	}
	if value, ok := state.Settings["sandboxieDirectory"].(string); ok && filepath.IsAbs(value) {
		directory = value
	}
	check, err := s.checkWindowsLiteSystem(ctx, directory, "")
	if err != nil {
		return err
	}
	if !check.Installed {
		artifact := windowslite.Dependency("sandboxie")
		cache := filepath.Join(profile, "downloads")
		if err := host.EnsurePrivateDir(cache); err != nil {
			return err
		}
		packagePath := filepath.Join(cache, artifact.File)
		valid, _ := liteArtifactMatches(packagePath, artifact.SHA256)
		if !valid {
			// Preserve an existing unexpected package for diagnosis; never execute it.
			if _, e := os.Lstat(packagePath); e == nil {
				packagePath = filepath.Join(cache, randomToken()[:12]+"-"+artifact.File)
			}
			s.liteSetupStage("image", "正在从官方来源下载轻量沙箱…")
			if err := hostproxy.Download(ctx, artifact.URL, packagePath, "Sandboxie", "application/octet-stream", cache, artifact.SHA256, s.jobs.execution()); err != nil {
				return fmt.Errorf("轻量沙箱下载失败，可重试继续下载：%w", err)
			}
		}
		valid, err = liteArtifactMatches(packagePath, artifact.SHA256)
		if err != nil || !valid {
			return errors.New("安装包摘要校验失败，未运行安装程序")
		}
		s.liteSetupStage("packages", "正在安装隔离组件，请确认 Windows 管理员授权…")
		if err := installWindowsLitePackage(ctx, packagePath, directory, filepath.Join(cache, "install-"+randomToken()[:12]+".log"), artifact.SHA256); err != nil {
			return err
		}
		check, err = s.checkWindowsLiteSystem(ctx, directory, "")
		if err != nil {
			return err
		}
	}
	if !check.Installed {
		return errors.New("安装后未找到完整组件，请查看安装记录；原空间数据保留")
	}
	if !check.ServicesRunning {
		s.liteSetupStage("packages", "正在启动隔离服务，请确认 Windows 管理员授权…")
		if err := startWindowsLiteServices(ctx); err != nil {
			return err
		}
	}
	s.liteSetupStage("tools", "正在启用并检查内核网络过滤…")
	check, err = s.checkWindowsLiteSystem(ctx, directory, filepath.Join(profile, "installation-backups"))
	if err != nil {
		return err
	}
	if !check.Installed || !check.ServicesRunning || !check.WFPEnabled {
		return errors.New("隔离服务或内核过滤未生效，安装尚未完成；请查看操作详情")
	}
	s.liteSetupStage("services", "正在接入原工作台并检查应用入口…")
	core := filepath.Join(filepath.Dir(s.exe), "mihomo.exe")
	if info, e := os.Stat(core); e != nil || !info.Mode().IsRegular() {
		return errors.New("测试包缺少代理组件，请重新下载完整包")
	}
	_, err = s.windowsLiteCall(ctx, "configure", map[string]any{"settings": map[string]any{"sandboxieDirectory": directory, "proxyCore": core, "connectionFile": s.configPath, "projectDirectory": s.workspace()}})
	if err != nil {
		return err
	}
	if err = writePrivate(filepath.Join(profile, "setup.json"), windowsLiteSetupRecord{Version: 1, Completed: true, Directory: directory, ComponentVersion: check.Version, CompletedAt: time.Now().UTC()}); err != nil {
		return err
	}
	s.liteSetupStage("services", "轻量沙箱组件已安装，进入工作台查看应用适配与隔离检查")
	return nil
}

func liteArtifactMatches(path, digest string) (bool, error) {
	info, err := os.Lstat(path)
	if err != nil {
		return false, err
	}
	if !info.Mode().IsRegular() {
		return false, errors.New("安装包不是普通文件")
	}
	f, err := os.Open(path)
	if err != nil {
		return false, err
	}
	defer f.Close()
	h := sha256.New()
	if _, err = io.Copy(h, f); err != nil {
		return false, err
	}
	return hex.EncodeToString(h.Sum(nil)) == digest, nil
}
