package workbench

import (
	"bytes"
	"encoding/json"
	"errors"
	"net/http"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/sylvinus/agent-vm/internal/host"
)

func (s *Server) windowsLocalProjects(w http.ResponseWriter, r *http.Request) {
	p := s.windowsLocal
	binding := p.active.Load()
	if binding == nil {
		http.Error(w, "请先确认 Windows 隔离账户。", http.StatusConflict)
		return
	}
	var input struct {
		Path       string `json:"path,omitempty"`
		Access     string `json:"access,omitempty"`
		Action     string `json:"action,omitempty"`
		WorkerSID  string `json:"workerSid,omitempty"`
		InstanceID string `json:"instanceId,omitempty"`
	}
	if r.Method == http.MethodPost {
		if !readJSON(w, r, &input, 32768) {
			return
		}
		picking := input.Action == "choose" && input.Path == "" && input.Access == ""
		if !picking && (input.Action != "" || !filepath.IsAbs(input.Path) || len(filepath.VolumeName(input.Path)) != 2 || strings.IndexByte(input.Path, 0) >= 0 ||
			(input.Access != "ro" && input.Access != "rw" && input.Access != "revoke")) {
			http.Error(w, "请选择本机项目文件夹以及要应用的权限。", http.StatusBadRequest)
			return
		}
		if !picking && input.Access != "revoke" {
			for _, protected := range []string{s.profile, filepath.Dir(s.exe), filepath.Dir(p.helper), filepath.Dir(p.profile)} {
				if windowsLocalPathsOverlap(input.Path, protected) {
					http.Error(w, "请选择 Cage 配置和程序目录以外的项目文件夹。", http.StatusBadRequest)
					return
				}
			}
		}
	}
	if err := p.checkPaths(); err != nil {
		requestError(w, err)
		return
	}
	input.WorkerSID, input.InstanceID = binding.WorkerSID, binding.InstanceID
	// An admitted ACL mutation finishes even if the page goes away. The helper
	// serializes changes for this worker across every launcher/configuration.
	cmd := exec.Command(p.helper, "workbench-projects", "--profile", p.profile)
	if input.Access == "" {
		cmd = exec.CommandContext(r.Context(), p.helper, "workbench-projects", "--profile", p.profile)
	}
	host.HideCommandWindow(cmd)
	body, err := json.Marshal(input)
	if err != nil {
		requestError(w, err)
		return
	}
	cmd.Stdin = bytes.NewReader(append(body, '\n'))
	var output, diagnostic bytes.Buffer
	cmd.Stdout = &boundedWindowsStatusWriter{buffer: &output, remaining: 1 << 20}
	cmd.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4096}
	if err := cmd.Run(); err != nil {
		msg, _, _ := strings.Cut(strings.TrimSpace(diagnostic.String()), "\n")
		requestError(w, errors.New("读取或更改项目授权失败。"+msg))
		return
	}
	var result struct {
		InstanceID string `json:"instanceId"`
		WorkerSID  string `json:"workerSid"`
		Selected   string `json:"selected,omitempty"`
		Projects   []struct {
			Path   string `json:"path"`
			Access string `json:"access"`
		} `json:"projects"`
	}
	if json.Unmarshal(output.Bytes(), &result) != nil || result.WorkerSID != binding.WorkerSID || result.InstanceID != binding.InstanceID || result.Projects == nil {
		requestError(w, errors.New("项目权限回执与已绑定的 Windows 账户不一致。"))
		return
	}
	jsonReply(w, result)
}

func windowsLocalPathsOverlap(first, second string) bool {
	if second == "" {
		return false
	}
	a, b := strings.ToLower(filepath.Clean(first)), strings.ToLower(filepath.Clean(second))
	sep := string(filepath.Separator)
	return a == b || strings.HasPrefix(a, b+sep) || strings.HasPrefix(b, a+sep)
}
