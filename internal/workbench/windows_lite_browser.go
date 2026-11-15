package workbench

import (
	"context"
	"encoding/json"
	"errors"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/sylvinus/agent-vm/internal/host"
)

type windowsLiteBrowserLaunch struct {
	CDPURL        string `json:"cdpURL"`
	ProxyURL      string `json:"proxyURL"`
	DataDirectory string `json:"dataDirectory"`
	PID           int    `json:"pid"`
	SessionID     string `json:"sessionId"`
	ConfigHash    string `json:"configHash"`
}

func (s *Server) newWindowsLiteBrowserClient(parent context.Context) *windowsBrowserClient {
	ctx, cancel := context.WithCancel(parent)
	return &windowsBrowserClient{ctx: ctx, cancel: cancel, ownsBrowser: true, admit: func() error {
		if !windowsLiteAdmitted(s.windowsLiteState()) {
			return errBrowserNotReady
		}
		return nil
	}, start: func(ctx context.Context) (*exec.Cmd, error) {
		reply, err := s.windowsLiteRequest(ctx, "launch", map[string]any{"entry": "browser"})
		if err != nil {
			return nil, err
		}
		if !windowsLiteAdmitted(reply.State) || !reply.State.Capabilities["embedded_browser"] {
			return nil, errors.New("空间检查尚未通过，未连接浏览器")
		}
		var launch windowsLiteBrowserLaunch
		data := reply.Browser
		if len(data) == 0 {
			var wrapper struct {
				Browser json.RawMessage `json:"browser"`
			}
			if json.Unmarshal(reply.Launch, &wrapper) == nil {
				data = wrapper.Browser
			}
		}
		if json.Unmarshal(data, &launch) != nil || launch.PID <= 0 || !validLiteLoopbackURL(launch.CDPURL) || !validLiteLoopbackURL(launch.ProxyURL) ||
			launch.SessionID != reply.State.Monitor.SessionID || launch.ConfigHash != reply.State.Monitor.ConfigHash {
			return nil, errors.New("空间未返回可核验的浏览器连接，未启动宿主浏览器")
		}
		relative, err := filepath.Rel(s.windowsLiteProfile(), launch.DataDirectory)
		if err != nil || !filepath.IsAbs(launch.DataDirectory) || relative == "." || relative == ".." || strings.HasPrefix(relative, ".."+string(filepath.Separator)) {
			return nil, errors.New("浏览器数据目录不属于此轻量空间")
		}
		resources := filepath.Dir(s.exe)
		node := filepath.Join(resources, "node.exe")
		script := filepath.Join(resources, "windows-lite", "browser-controller.mjs")
		for _, file := range []string{node, script} {
			if info, err := os.Stat(file); err != nil || !info.Mode().IsRegular() {
				return nil, errors.New("轻量沙箱浏览器组件缺失，请重新准备运行组件")
			}
		}
		configuration, err := json.Marshal(map[string]any{"cdpURL": launch.CDPURL, "proxyURL": launch.ProxyURL, "directory": launch.DataDirectory, "displayScale": 1, "executable": "space-owned-browser"})
		if err != nil {
			return nil, err
		}
		cmd := exec.CommandContext(ctx, node, script)
		cmd.Dir = filepath.Dir(script)
		// Only the trusted controller sees its connection details. Do not pass
		// provider tokens, inherited NODE_OPTIONS, or host proxy variables.
		for _, key := range []string{"SystemRoot", "WINDIR", "TEMP", "TMP"} {
			if value := os.Getenv(key); value != "" {
				cmd.Env = append(cmd.Env, key+"="+value)
			}
		}
		cmd.Env = append(cmd.Env, "CAGE_LITE_BROWSER_CONFIG="+string(configuration))
		host.HideCommandWindow(cmd)
		return cmd, nil
	}}
}

func validLiteLoopbackURL(value string) bool {
	u, err := url.Parse(value)
	return err == nil && u.Scheme == "http" && u.Hostname() == "127.0.0.1" && u.Port() != "" && u.User == nil && (u.Path == "" || u.Path == "/") && u.RawQuery == "" && u.Fragment == ""
}
