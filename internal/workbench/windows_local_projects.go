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
	"slices"
	"strings"

	"github.com/sylvinus/agent-vm/internal/host"
	"github.com/sylvinus/agent-vm/internal/mounts"
)

type windowsLocalProjectGrant struct {
	Path   string `json:"path"`
	Access string `json:"access"`
}

type windowsLocalGrantChange struct {
	Path   string `json:"path"`
	Before string `json:"before"`
	After  string `json:"after"`
}

type windowsLocalProjectRequest struct {
	Path       string                    `json:"path,omitempty"`
	Access     string                    `json:"access,omitempty"`
	Action     string                    `json:"action,omitempty"`
	Changes    []windowsLocalGrantChange `json:"changes,omitempty"`
	WorkerSID  string                    `json:"workerSid,omitempty"`
	InstanceID string                    `json:"instanceId,omitempty"`
}

type windowsLocalProjectResult struct {
	InstanceID string                     `json:"instanceId"`
	WorkerSID  string                     `json:"workerSid"`
	Selected   string                     `json:"selected,omitempty"`
	Applied    bool                       `json:"applied,omitempty"`
	Projects   []windowsLocalProjectGrant `json:"projects"`
}

func cleanLocalProjectPath(path string) (string, error) {
	if !filepath.IsAbs(path) || len(filepath.VolumeName(path)) != 2 || strings.ContainsAny(path, "\x00\r\n") {
		return "", errors.New("请选择本机磁盘上的绝对项目目录。")
	}
	path = filepath.Clean(path)
	if filepath.Dir(path) == path {
		return "", errors.New("请选择具体项目文件夹。")
	}
	return path, nil
}

func (s *Server) localProjectPath(path string) (string, error) {
	path, err := cleanLocalProjectPath(path)
	if err != nil {
		return "", err
	}
	if mounts.UnderName(filepath.ToSlash(path), nil) {
		return "", errors.New("请选择项目文件夹，版本控制和凭据目录不能共享。")
	}
	for _, protected := range s.windowsLocalPrivateRoots() {
		if windowsLocalPathsOverlap(path, protected) {
			return "", errors.New("请选择 Cage 配置和程序目录以外的项目文件夹。")
		}
	}
	return path, nil
}

func (s *Server) windowsLocalPrivateRoots() []string {
	home, _ := os.UserHomeDir()
	roots := []string{s.profile, filepath.Dir(s.exe), filepath.Dir(s.windowsLocal.helper), filepath.Dir(s.windowsLocal.profile)}
	for _, path := range []string{home, os.Getenv("ProgramData"), os.Getenv("SystemRoot"), os.Getenv("ProgramFiles"), os.Getenv("ProgramFiles(x86)")} {
		if path != "" {
			roots = append(roots, path)
		}
	}
	return roots
}

func (s *Server) windowsLocalProjects(w http.ResponseWriter, r *http.Request) {
	var input struct {
		Path   string `json:"path,omitempty"`
		Access string `json:"access,omitempty"`
		Action string `json:"action,omitempty"`
	}
	if r.Method == http.MethodPost {
		if !readJSON(w, r, &input, 32768) {
			return
		}
		picking := input.Action == "choose" && input.Path == "" && input.Access == ""
		if !picking {
			if input.Action != "" || (input.Access != "ro" && input.Access != "rw" && input.Access != "revoke") {
				requestError(w, errors.New("请选择本机项目文件夹以及要应用的权限。"))
				return
			}
			var err error
			if input.Access == "revoke" {
				// Old grants can predate the picker rules. Keep them removable.
				input.Path, err = cleanLocalProjectPath(input.Path)
			} else {
				input.Path, err = s.localProjectPath(input.Path)
			}
			if err != nil {
				requestError(w, err)
				return
			}
		}
	}
	p := s.windowsLocal
	// A native folder chooser can stay open indefinitely. It never grants access.
	if input.Action != "choose" {
		p.projectMu.Lock()
		defer p.projectMu.Unlock()
		p.projectView = nil
	}
	if input.Access != "" && s.windowsLocalFoldersBusy([]string{input.Path}) {
		http.Error(w, "请先保存并关闭使用该项目的终端和编辑器，再修改其授权。", http.StatusConflict)
		return
	}
	if input.Access == "revoke" {
		receipt, err := p.projectRequest(r.Context(), windowsLocalProjectRequest{})
		if err != nil {
			requestError(w, err)
			return
		}
		if !slices.ContainsFunc(receipt.Projects, func(grant windowsLocalProjectGrant) bool { return strings.EqualFold(grant.Path, input.Path) }) {
			jsonReply(w, receipt)
			return
		}
	}
	result, err := p.projectRequest(r.Context(), windowsLocalProjectRequest{Path: input.Path, Access: input.Access, Action: input.Action})
	if err != nil {
		requestError(w, err)
		return
	}
	jsonReply(w, result)
}

func (p *windowsLocalPrototype) projectRequest(ctx context.Context, input windowsLocalProjectRequest) (*windowsLocalProjectResult, error) {
	binding := p.active.Load()
	if binding == nil {
		return nil, errors.New("请先确认 Windows 隔离账户。")
	}
	if err := p.checkPaths(); err != nil {
		return nil, err
	}
	input.WorkerSID, input.InstanceID = binding.WorkerSID, binding.InstanceID
	// Admitted mutations complete even if the page goes away. The helper owns
	// the cross-controller account lock through validation, ACL writes and rollback.
	if input.Access != "" || len(input.Changes) != 0 {
		ctx = context.WithoutCancel(ctx)
	}
	cmd := exec.CommandContext(ctx, p.helper, "workbench-projects", "--profile", p.profile)
	host.HideCommandWindow(cmd)
	body, err := json.Marshal(input)
	if err != nil {
		return nil, err
	}
	cmd.Stdin = bytes.NewReader(append(body, '\n'))
	var output, diagnostic bytes.Buffer
	cmd.Stdout = &boundedWindowsStatusWriter{buffer: &output, remaining: 1 << 20}
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4096}
	if err := cmd.Run(); err != nil {
		msg, _, _ := strings.Cut(strings.TrimSpace(diagnostic.String()), "\n")
		return nil, errors.New("读取或更改项目授权失败。" + msg)
	}
	var result windowsLocalProjectResult
	if json.Unmarshal(output.Bytes(), &result) != nil || result.WorkerSID != binding.WorkerSID || result.InstanceID != binding.InstanceID ||
		(len(input.Changes) > 0 && !result.Applied) || (len(input.Changes) == 0 && result.Projects == nil) {
		return nil, errors.New("项目权限回执与已绑定的 Windows 账户不一致。")
	}
	return &result, nil
}

func windowsLocalPathsOverlap(first, second string) bool {
	if second == "" {
		return false
	}
	a, b := strings.ToLower(filepath.Clean(first)), strings.ToLower(filepath.Clean(second))
	sep := string(filepath.Separator)
	return a == b || strings.HasPrefix(a, b+sep) || strings.HasPrefix(b, a+sep)
}
