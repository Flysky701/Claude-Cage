// Package windowslite owns the isolated, single-space Windows Lite review UI.
// It does not modify or launch the user's regular Cage profile or VM.
package windowslite

import (
	"context"
	"crypto/rand"
	"crypto/subtle"
	"embed"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/fs"
	"net"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"runtime"
	"strconv"
	"strings"
	"time"

	"github.com/sylvinus/agent-vm/internal/host"
)

//go:embed web/*
var assets embed.FS

var Version = "development"

const cookieName = "cage_lite_session"

type controlRecord struct {
	PID        int    `json:"pid"`
	Port       int    `json:"port"`
	Token      string `json:"token"`
	ID         string `json:"id"`
	Executable string `json:"executable"`
}

type caller interface {
	Call(context.Context, json.RawMessage) (json.RawMessage, error)
	Close() error
}

type server struct {
	origin string
	token  string
	id     string
	worker caller
	cancel context.CancelFunc
}

func secret() string {
	var b [32]byte
	if _, err := rand.Read(b[:]); err != nil {
		panic(err)
	}
	return hex.EncodeToString(b[:])
}

func profilePath() (string, error) {
	if configured := os.Getenv("CLAUDE_CAGE_CONFIG"); configured != "" {
		full, err := filepath.Abs(configured)
		return filepath.Dir(full), err
	}
	home, err := os.UserHomeDir()
	return filepath.Join(home, ".claude-cage", "windows-lite"), err
}

func reply(w http.ResponseWriter, status int, value any) {
	w.Header().Set("Content-Type", "application/json; charset=utf-8")
	w.Header().Set("Cache-Control", "no-store")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(value)
}

func failure(w http.ResponseWriter, status int, message string) {
	reply(w, status, map[string]any{"ok": false, "error": message})
}

func equal(a, b string) bool {
	return len(a) > 0 && subtle.ConstantTimeCompare([]byte(a), []byte(b)) == 1
}

func (s *server) authenticated(r *http.Request) bool {
	if value := strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "); equal(value, s.token) {
		return true
	}
	cookie, err := r.Cookie(cookieName)
	return err == nil && equal(cookie.Value, s.token)
}

func (s *server) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("X-Content-Type-Options", "nosniff")
	w.Header().Set("Referrer-Policy", "no-referrer")
	w.Header().Set("Content-Security-Policy", "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'self'; object-src 'none'; base-uri 'none'; frame-ancestors 'none'")
	if "http://"+r.Host != s.origin {
		failure(w, http.StatusForbidden, "工作台地址不匹配")
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		if r.Header.Get("Origin") != s.origin || r.Header.Get("X-Cage-Lite") != "1" {
			failure(w, http.StatusForbidden, "请从 Cage 轻量空间窗口执行此操作")
			return
		}
	}
	if r.URL.Path == "/api/session" {
		if r.Method != http.MethodPost {
			failure(w, 405, "不支持此请求方式")
			return
		}
		var input struct {
			Token string `json:"token"`
		}
		if err := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096)).Decode(&input); err != nil || !equal(input.Token, s.token) {
			failure(w, 401, "工作台会话无效，请重新打开窗口")
			return
		}
		http.SetCookie(w, &http.Cookie{Name: cookieName, Value: s.token, Path: "/", HttpOnly: true, SameSite: http.SameSiteStrictMode})
		reply(w, 200, map[string]bool{"ok": true})
		return
	}
	if strings.HasPrefix(r.URL.Path, "/api/") {
		if !s.authenticated(r) {
			failure(w, 401, "工作台会话已失效，请重新打开窗口")
			return
		}
		if r.URL.Path == "/api/lite/ping" && r.Method == http.MethodGet {
			reply(w, 200, map[string]any{"ok": true, "id": s.id})
			return
		}
		action := strings.TrimPrefix(r.URL.Path, "/api/lite/")
		if action == "status" {
			if r.Method != http.MethodGet {
				failure(w, 405, "不支持此请求方式")
				return
			}
		} else if action == "configure" || action == "start" || action == "stop" || action == "launch" || action == "shutdown" {
			if r.Method != http.MethodPost {
				failure(w, 405, "不支持此请求方式")
				return
			}
		} else {
			failure(w, 404, "此测试包不支持该操作")
			return
		}
		input := map[string]json.RawMessage{}
		if r.Method == http.MethodPost {
			decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 65536))
			if err := decoder.Decode(&input); err != nil {
				failure(w, 400, "请求内容无效")
				return
			}
			if input == nil {
				failure(w, 400, "请求内容必须是对象")
				return
			}
			var extra any
			if decoder.Decode(&extra) != io.EOF {
				failure(w, 400, "请求只能包含一个对象")
				return
			}
		}
		workerAction := action
		if action == "shutdown" {
			workerAction = "stop"
		}
		input["action"], _ = json.Marshal(workerAction)
		body, _ := json.Marshal(input)
		ctx, cancel := context.WithTimeout(r.Context(), 45*time.Second)
		defer cancel()
		result, err := s.worker.Call(ctx, body)
		if err != nil {
			failure(w, 503, "空间管理进程暂不可用，未启动任何宿主应用。请重新打开测试窗口。")
			return
		}
		var outcome struct {
			OK bool `json:"ok"`
		}
		if json.Unmarshal(result, &outcome) != nil {
			failure(w, 502, "空间管理进程返回了无效状态")
			return
		}
		reply(w, 200, result)
		if action == "shutdown" && outcome.OK {
			time.AfterFunc(400*time.Millisecond, s.cancel)
		}
		return
	}
	if r.Method != http.MethodGet && r.Method != http.MethodHead {
		failure(w, 405, "不支持此请求方式")
		return
	}
	web, _ := fs.Sub(assets, "web")
	if r.URL.Path == "/" {
		r.URL.Path = "/windows-lite.html"
	}
	if r.URL.Path == "/README" {
		http.NotFound(w, r)
		return
	}
	http.FileServer(http.FS(web)).ServeHTTP(w, r)
}

func loadRecord(profile string) (controlRecord, error) {
	var record controlRecord
	path := filepath.Join(profile, "lite-control.json")
	if err := host.CheckPrivateFile(path); err != nil {
		return record, err
	}
	b, err := os.ReadFile(path)
	if err != nil {
		return record, err
	}
	if len(b) > 8192 || json.Unmarshal(b, &record) != nil || record.PID < 1 || record.Port < 1024 || record.Port > 65535 || len(record.Token) != 64 || len(record.ID) != 64 {
		return record, errors.New("轻量空间后台记录无效，请保留数据并检查原后台")
	}
	return record, nil
}

func request(record controlRecord, method, path string) ([]byte, error) {
	origin := fmt.Sprintf("http://localhost:%d", record.Port)
	r, _ := http.NewRequest(method, origin+path, strings.NewReader("{}"))
	r.Header.Set("Authorization", "Bearer "+record.Token)
	r.Header.Set("Origin", origin)
	r.Header.Set("X-Cage-Lite", "1")
	r.Header.Set("Content-Type", "application/json")
	client := &http.Client{Timeout: 12 * time.Second, Transport: &http.Transport{Proxy: nil}, CheckRedirect: func(*http.Request, []*http.Request) error { return errors.New("unexpected redirect") }}
	response, err := client.Do(r)
	if err != nil {
		return nil, err
	}
	defer response.Body.Close()
	if response.StatusCode != 200 {
		return nil, errors.New("轻量空间后台未接受请求")
	}
	return io.ReadAll(io.LimitReader(response.Body, 1<<20))
}

func recordReady(record controlRecord) bool {
	b, err := request(record, http.MethodGet, "/api/lite/ping")
	var result struct {
		ID string `json:"id"`
		OK bool   `json:"ok"`
	}
	return err == nil && json.Unmarshal(b, &result) == nil && result.OK && equal(result.ID, record.ID)
}

func desktop(profile string) (any, error) {
	exe, err := os.Executable()
	if err != nil {
		return nil, err
	}
	if record, err := loadRecord(profile); err == nil && recordReady(record) {
		if !strings.EqualFold(filepath.Clean(record.Executable), filepath.Clean(exe)) {
			return nil, errors.New("另一个测试包正在管理此空间，请先从原窗口退出")
		}
		return map[string]any{"status": "ready", "url": fmt.Sprintf("http://localhost:%d/#%s", record.Port, record.Token)}, nil
	}
	if err := host.EnsurePrivateDir(profile); err != nil {
		return nil, err
	}
	log, err := os.OpenFile(filepath.Join(profile, "lite-startup.log"), os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0600)
	if err != nil {
		return nil, err
	}
	defer log.Close()
	_ = host.ProtectFile(log.Name())
	cmd := exec.Command(exe, "serve")
	cmd.Dir = filepath.Dir(exe)
	cmd.Env = append(os.Environ(), "CLAUDE_CAGE_CONFIG="+filepath.Join(profile, "config.json"))
	cmd.Stdout, cmd.Stderr = log, log
	hideProcess(cmd, true)
	if err := cmd.Start(); err != nil {
		return nil, err
	}
	_ = cmd.Process.Release()
	deadline := time.Now().Add(25 * time.Second)
	for time.Now().Before(deadline) {
		if record, err := loadRecord(profile); err == nil && recordReady(record) {
			if !strings.EqualFold(filepath.Clean(record.Executable), filepath.Clean(exe)) {
				return nil, errors.New("原测试后台仍在运行，请先退出原窗口")
			}
			return map[string]any{"status": "ready", "url": fmt.Sprintf("http://localhost:%d/#%s", record.Port, record.Token)}, nil
		}
		time.Sleep(150 * time.Millisecond)
	}
	return nil, errors.New("轻量空间后台未能就绪，请查看测试数据目录中的 lite-startup.log")
}

func serve(profile string) error {
	if err := host.EnsurePrivateDir(profile); err != nil {
		return err
	}
	unlock, err := lockProfile(filepath.Join(profile, "lite-control.lock"))
	if err != nil {
		return err
	}
	defer unlock()
	if _, err := assets.ReadFile("web/windows-lite.html"); err != nil {
		return errors.New("测试工作台尚未构建")
	}
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	worker, err := newWorker(profile)
	if err != nil {
		return err
	}
	defer worker.Close()
	listener, err := net.Listen("tcp4", "127.0.0.1:0")
	if err != nil {
		return err
	}
	defer listener.Close()
	exe, _ := os.Executable()
	record := controlRecord{PID: os.Getpid(), Port: listener.Addr().(*net.TCPAddr).Port, Token: secret(), ID: secret(), Executable: exe}
	origin := fmt.Sprintf("http://localhost:%d", record.Port)
	if owner := os.Getenv("CAGE_DESKTOP_OWNER_PID"); owner != "" {
		pid, e := strconv.Atoi(owner)
		if e != nil || pid < 2 {
			return errors.New("桌面窗口身份无效")
		}
		if err := watchOwner(ctx, pid, cancel); err != nil {
			return err
		}
	}
	encoded, _ := json.Marshal(record)
	path := filepath.Join(profile, "lite-control.json")
	if err := os.WriteFile(path, encoded, 0600); err != nil {
		return err
	}
	if err := host.ProtectFile(path); err != nil {
		return err
	}
	defer func() {
		if current, e := loadRecord(profile); e == nil && current.ID == record.ID {
			_ = os.Remove(path)
		}
	}()
	api := &server{origin: origin, token: record.Token, id: record.ID, worker: worker, cancel: cancel}
	httpServer := &http.Server{Handler: api, ReadHeaderTimeout: 5 * time.Second, ReadTimeout: 15 * time.Second, IdleTimeout: 45 * time.Second, MaxHeaderBytes: 16 << 10}
	done := make(chan error, 1)
	go func() { done <- httpServer.Serve(listener) }()
	select {
	case <-ctx.Done():
	case err := <-done:
		if err != nil && !errors.Is(err, http.ErrServerClosed) {
			return err
		}
	}
	stop, stopCancel := context.WithTimeout(context.Background(), 8*time.Second)
	defer stopCancel()
	_, _ = worker.Call(stop, json.RawMessage(`{"action":"stop"}`))
	return httpServer.Shutdown(stop)
}

// Run exposes only this review build's own lifecycle, never VM or host launch commands.
func Run(args []string) int {
	if runtime.GOOS != "windows" {
		fmt.Fprintln(os.Stderr, "Windows Lite 仅支持 Windows；其他 Cage 模式不受影响。")
		return 1
	}
	if len(args) == 0 {
		args = []string{"desktop"}
	}
	if args[0] == "version" {
		fmt.Println(Version)
		return 0
	}
	if args[0] == "diagnostic-event" {
		_, _ = io.Copy(io.Discard, io.LimitReader(os.Stdin, 1<<20))
		return 0
	}
	profile, err := profilePath()
	var result any
	if err == nil {
		switch args[0] {
		case "desktop":
			result, err = desktop(profile)
		case "serve":
			err = serve(profile)
			if err == nil {
				return 0
			}
		case "prepare-update":
			if record, e := loadRecord(profile); e == nil && recordReady(record) {
				var b []byte
				b, err = request(record, http.MethodPost, "/api/lite/shutdown")
				var outcome struct {
					OK bool `json:"ok"`
				}
				if err == nil && (json.Unmarshal(b, &outcome) != nil || !outcome.OK) {
					err = errors.New("轻量空间未能安全停止，数据已保留")
				}
			} else if e == nil {
				err = errors.New("无法确认原轻量空间后台已停止，请保留数据并检查原窗口")
			} else if !os.IsNotExist(e) {
				err = e
			}
			result = map[string]any{"status": "prepared", "message": "测试空间已停止，数据保留"}
		case "verify-web-assets":
			_, err = assets.ReadFile("web/windows-lite.html")
			result = map[string]bool{"ok": err == nil}
		default:
			err = errors.New("此测试包仅提供 Windows 轻量空间入口")
		}
	}
	if err != nil {
		_ = json.NewEncoder(os.Stdout).Encode(map[string]any{"status": "error", "message": err.Error()})
		return 1
	}
	_ = json.NewEncoder(os.Stdout).Encode(result)
	return 0
}
