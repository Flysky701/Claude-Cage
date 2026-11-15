package workbench

import (
	"bytes"
	"context"
	"crypto/rand"
	"crypto/subtle"
	"encoding/binary"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"sync"
	"time"
)

const windowsLiteTerminalMaxFrame = 64 << 10

type windowsLiteTerminalPlan struct {
	LeaseID           string            `json:"leaseId"`
	Command           []string          `json:"command"`
	Environment       map[string]string `json:"environment"`
	Cwd               string            `json:"cwd"`
	BoxName           string            `json:"boxName"`
	Profile           string            `json:"profile"`
	Kind              string            `json:"kind"`
	Workspace         string            `json:"workspace"`
	SessionID         string            `json:"sessionId"`
	ConfigurationHash string            `json:"configurationHash"`
	PID               int               `json:"pid"`
}

func (s *Server) createWindowsLiteTerminal(input terminalRequest) (*terminalSession, error) {
	s.mu.Lock()
	closing, command := s.closing, claudeTerminalCommand(s.preferences)
	s.mu.Unlock()
	if closing {
		return nil, errTerminalsClosed
	}
	if input.Kind == "" {
		input.Kind = "shell"
	}
	if input.Kind != "shell" && input.Kind != "claude" || input.sharedID != "" || input.ClaudeAccountID != "" && input.ClaudeAccountID != "auto" {
		return nil, errors.New("轻量空间暂未接入托管账号登录和保存会话，请使用普通终端或默认 Claude 终端")
	}
	if input.Kind == "claude" && command != "claude" {
		return nil, errors.New("轻量空间 Claude 终端使用空间设置中的程序；自定义托管启动命令尚未接入")
	}
	state := s.windowsLiteState()
	capability := "terminal_stream"
	if input.Kind == "claude" {
		capability = "claude_terminal"
	}
	if !windowsLiteAdmitted(state) || !state.Capabilities[capability] || s.busy() {
		return nil, errTerminalNotReady
	}
	ctx := input.requestContext
	if ctx == nil {
		ctx = context.Background()
	}
	return s.terminals.startSessionWithPTY(nil, input.Workspace, input.Kind, claudeSelection{}, nil, func() (terminalPTY, error) {
		return s.startWindowsLiteTerminal(ctx, input)
	})
}

func windowsLiteTerminalIdentity(plan windowsLiteTerminalPlan, state windowsLiteSnapshot, profile string) bool {
	return windowsLiteAdmitted(state) && plan.LeaseID != "" && len(plan.LeaseID) <= 96 &&
		strings.EqualFold(filepath.Clean(state.Profile), filepath.Clean(profile)) &&
		strings.EqualFold(filepath.Clean(plan.Profile), filepath.Clean(profile)) &&
		strings.EqualFold(plan.BoxName, state.BoxName) && plan.BoxName != "" &&
		plan.SessionID == state.Monitor.SessionID && plan.ConfigurationHash == state.Monitor.ConfigHash
}

func validateWindowsLiteTerminalPlan(plan windowsLiteTerminalPlan, state windowsLiteSnapshot, profile, kind, workspace string) error {
	if !windowsLiteTerminalIdentity(plan, state, profile) || plan.Kind != kind || plan.Workspace != workspace || len(plan.Command) < 4 || !filepath.IsAbs(plan.Cwd) || len(plan.Environment) == 0 {
		return errors.New("终端启动授权不完整或已失效")
	}
	directory, _ := state.Settings["sandboxieDirectory"].(string)
	if directory == "" || !filepath.IsAbs(directory) || !strings.EqualFold(filepath.Clean(plan.Command[0]), filepath.Join(directory, "Start.exe")) || !strings.EqualFold(plan.Command[1], "/box:"+plan.BoxName) {
		return errors.New("终端启动器不属于当前轻量空间")
	}
	for _, arg := range plan.Command {
		if strings.ContainsRune(arg, 0) {
			return errors.New("终端启动参数无效")
		}
	}
	for key, value := range plan.Environment {
		if key == "" || strings.ContainsAny(key, "=\x00") || strings.ContainsRune(value, 0) {
			return errors.New("终端环境无效")
		}
	}
	return nil
}

func (s *Server) releaseWindowsLiteTerminal(lease string) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, _ = s.windowsLiteRequest(ctx, "release-terminal", map[string]any{"leaseId": lease})
}

func (s *Server) startWindowsLiteTerminal(ctx context.Context, input terminalRequest) (terminalPTY, error) {
	listener, err := net.ListenTCP("tcp4", &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1)})
	if err != nil {
		return nil, err
	}
	defer listener.Close()
	secret := make([]byte, 32)
	if _, err = rand.Read(secret); err != nil {
		return nil, err
	}
	token := hex.EncodeToString(secret)
	reply, err := s.windowsLiteRequest(ctx, "prepare-terminal", map[string]any{"bridgePort": listener.Addr().(*net.TCPAddr).Port, "bridgeToken": token, "cols": 100, "rows": 30, "kind": input.Kind, "workspace": input.Workspace})
	if err != nil {
		return nil, err
	}
	var plan windowsLiteTerminalPlan
	if json.Unmarshal(reply.Launch, &plan) != nil {
		return nil, errors.New("终端启动授权无效")
	}
	success := false
	defer func() {
		if !success && plan.LeaseID != "" {
			s.releaseWindowsLiteTerminal(plan.LeaseID)
		}
	}()
	if err = validateWindowsLiteTerminalPlan(plan, reply.State, s.windowsLiteProfile(), input.Kind, input.Workspace); err != nil {
		return nil, err
	}
	capability := "terminal_stream"
	if input.Kind == "claude" {
		capability = "claude_terminal"
	}
	if !reply.State.Capabilities[capability] {
		return nil, errTerminalNotReady
	}
	cmd := exec.Command(plan.Command[0], plan.Command[1:]...)
	cmd.Dir = plan.Cwd
	for key, value := range plan.Environment {
		cmd.Env = append(cmd.Env, key+"="+value)
	}
	sort.Strings(cmd.Env)
	if err = launchWindowsLiteTerminal(cmd); err != nil {
		return nil, err
	}
	launcherDone := make(chan struct{})
	go func() { _ = cmd.Wait(); close(launcherDone) }()
	defer func() {
		if !success {
			_ = cmd.Process.Kill()
			<-launcherDone
		}
	}()
	deadline := time.Now().Add(18 * time.Second)
	if value, ok := ctx.Deadline(); ok && value.Before(deadline) {
		deadline = value
	}
	_ = listener.SetDeadline(deadline)
	stopAccept := context.AfterFunc(ctx, func() { _ = listener.Close() })
	connection, err := listener.AcceptTCP()
	stopAccept()
	if err != nil {
		return nil, err
	}
	defer func() {
		if !success {
			_ = connection.Close()
		}
	}()
	_ = connection.SetDeadline(deadline)
	stopConnect := context.AfterFunc(ctx, func() { _ = connection.Close() })
	defer stopConnect()
	typeID, payload, err := readWindowsLiteTerminalFrame(connection)
	var hello struct {
		LeaseID string `json:"leaseId"`
		Token   string `json:"token"`
		PID     int    `json:"pid"`
		BoxName string `json:"boxName"`
	}
	if err != nil || typeID != 'H' || json.Unmarshal(payload, &hello) != nil || hello.LeaseID != plan.LeaseID || subtle.ConstantTimeCompare([]byte(hello.Token), []byte(token)) != 1 || hello.PID <= 0 || !strings.EqualFold(hello.BoxName, plan.BoxName) {
		return nil, errors.New("终端进程身份验证失败")
	}
	attached, err := s.windowsLiteRequest(ctx, "attach-terminal", map[string]any{"leaseId": plan.LeaseID, "pid": hello.PID, "boxName": hello.BoxName, "sessionId": plan.SessionID, "configurationHash": plan.ConfigurationHash})
	if err != nil {
		return nil, err
	}
	var attachedPlan windowsLiteTerminalPlan
	if json.Unmarshal(attached.Launch, &attachedPlan) != nil || !windowsLiteTerminalIdentity(attachedPlan, attached.State, s.windowsLiteProfile()) || attachedPlan.LeaseID != plan.LeaseID || attachedPlan.PID != hello.PID || attachedPlan.SessionID != plan.SessionID || attachedPlan.ConfigurationHash != plan.ConfigurationHash {
		return nil, errors.New("终端进程未获得当前空间授权")
	}
	if err = writeWindowsLiteTerminalFrame(connection, 'G', nil); err != nil {
		return nil, err
	}
	var pending bytes.Buffer
	for {
		typeID, payload, err = readWindowsLiteTerminalFrame(connection)
		if err != nil {
			return nil, err
		}
		if typeID == 'B' && len(payload) == 0 {
			break
		}
		if typeID != 'O' || pending.Len()+len(payload) > 256<<10 {
			return nil, errors.New("空间内终端未完成启动")
		}
		pending.Write(payload)
	}
	if err = ctx.Err(); err != nil {
		return nil, err
	}
	_ = connection.SetDeadline(time.Time{})
	pty := newWindowsLiteTerminal(connection, pending.Bytes(), func() bool {
		current := s.windowsLiteState()
		return windowsLiteTerminalIdentity(plan, current, s.windowsLiteProfile()) && current.Capabilities[capability]
	}, func() {
		s.releaseWindowsLiteTerminal(plan.LeaseID)
		_ = cmd.Process.Kill()
		<-launcherDone
	})
	success = true
	return pty, nil
}

func readWindowsLiteTerminalFrame(reader io.Reader) (byte, []byte, error) {
	var header [5]byte
	if _, err := io.ReadFull(reader, header[:]); err != nil {
		return 0, nil, err
	}
	size := binary.LittleEndian.Uint32(header[1:])
	if size > windowsLiteTerminalMaxFrame {
		return 0, nil, errors.New("终端帧过大")
	}
	payload := make([]byte, int(size))
	_, err := io.ReadFull(reader, payload)
	return header[0], payload, err
}

func writeWindowsLiteTerminalFrame(writer io.Writer, kind byte, payload []byte) error {
	if len(payload) > windowsLiteTerminalMaxFrame {
		return errors.New("终端帧过大")
	}
	frame := make([]byte, 5+len(payload))
	frame[0] = kind
	binary.LittleEndian.PutUint32(frame[1:], uint32(len(payload)))
	copy(frame[5:], payload)
	for len(frame) > 0 {
		n, err := writer.Write(frame)
		if err != nil {
			return err
		}
		if n == 0 {
			return io.ErrShortWrite
		}
		frame = frame[n:]
	}
	return nil
}

type windowsLiteTerminal struct {
	connection net.Conn
	output     *io.PipeReader
	writeMu    sync.Mutex
	closeOnce  sync.Once
	done       chan struct{}
	waitErr    error
	release    func()
	admit      func() bool
}

func newWindowsLiteTerminal(connection net.Conn, pending []byte, admit func() bool, release func()) *windowsLiteTerminal {
	output, writer := io.Pipe()
	terminal := &windowsLiteTerminal{connection: connection, output: output, done: make(chan struct{}), release: release, admit: admit}
	go func() {
		var failure error
		defer func() { terminal.waitErr = failure; _ = writer.CloseWithError(failure); close(terminal.done) }()
		if len(pending) > 0 {
			if _, failure = writer.Write(pending); failure != nil {
				return
			}
		}
		for {
			kind, payload, err := readWindowsLiteTerminalFrame(connection)
			if err != nil {
				failure = err
				return
			}
			switch kind {
			case 'O':
				if _, failure = writer.Write(payload); failure != nil {
					return
				}
			case 'X':
				if len(payload) != 4 {
					failure = errors.New("终端退出状态无效")
				} else if code := int32(binary.LittleEndian.Uint32(payload)); code != 0 {
					failure = fmt.Errorf("空间终端退出：%d", code)
				}
				return
			case 'E':
				failure = errors.New("空间内终端连接失败")
				return
			default:
				failure = errors.New("终端响应无效")
				return
			}
		}
	}()
	return terminal
}

func (t *windowsLiteTerminal) send(kind byte, payload []byte) error {
	if t.admit != nil && !t.admit() {
		_ = t.Close()
		return errTerminalNotReady
	}
	t.writeMu.Lock()
	defer t.writeMu.Unlock()
	_ = t.connection.SetWriteDeadline(time.Now().Add(10 * time.Second))
	return writeWindowsLiteTerminalFrame(t.connection, kind, payload)
}
func (t *windowsLiteTerminal) Read(data []byte) (int, error) { return t.output.Read(data) }
func (t *windowsLiteTerminal) Write(data []byte) (int, error) {
	written := 0
	for written < len(data) {
		end := min(written+windowsLiteTerminalMaxFrame, len(data))
		if err := t.send('I', data[written:end]); err != nil {
			return written, err
		}
		written = end
	}
	return written, nil
}
func (t *windowsLiteTerminal) Resize(cols, rows uint16) error {
	if cols < 2 || cols >= 600 || rows < 2 || rows >= 400 {
		return errors.New("终端尺寸无效")
	}
	var payload [4]byte
	binary.LittleEndian.PutUint16(payload[:2], cols)
	binary.LittleEndian.PutUint16(payload[2:], rows)
	return t.send('R', payload[:])
}
func (t *windowsLiteTerminal) Wait() error { <-t.done; return t.waitErr }
func (t *windowsLiteTerminal) Kill() error { return t.Close() }
func (t *windowsLiteTerminal) Close() error {
	t.closeOnce.Do(func() {
		_ = t.connection.Close()
		_ = t.output.Close()
		if t.release != nil {
			t.release()
		}
	})
	return nil
}

var _ terminalPTY = (*windowsLiteTerminal)(nil)
