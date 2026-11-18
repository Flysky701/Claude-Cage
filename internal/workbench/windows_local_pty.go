package workbench

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"os"
	"slices"
	"strings"

	"github.com/google/uuid"
)

// One native ConPTY is owned by the existing terminalManager. WebSockets only
// view the manager's buffered byte stream and may detach or reconnect freely.
type windowsLocalPTY struct {
	ctx          context.Context
	cancel       context.CancelCauseFunc
	hub          *windowsLocalHub
	tab          *windowsLocalTab
	reader       *io.PipeReader
	done         chan struct{}
	err          error
	account      string
	accountLabel string
	// The owning terminal session guards pending input with its mutex. It
	// wakes its writer once per batch instead of one helper RPC per key.
	pendingInput []byte
}

func (s *Server) localTerminalFolders(ctx context.Context, path string) ([]string, error) {
	if path == "" || path == "~" {
		return nil, nil
	}
	return s.windowsLocalProjectFolders(ctx, path)
}

func (s *Server) startLocalPTY(request context.Context, launch windowsLocalEnvelope, folders []string) (*windowsLocalPTY, error) {
	epoch, _ := request.Value(windowsLocalEpochKey{}).(context.Context)
	if epoch == nil || epoch.Err() != nil {
		return nil, errMobileLocked
	}
	ctx, cancel := context.WithCancelCause(context.WithValue(epoch, windowsLocalEpochKey{}, epoch))
	interrupt := context.AfterFunc(request, func() { cancel(request.Err()) })
	defer interrupt()
	h, t, err := s.joinWindowsLocalTab(ctx, cancel, "pty")
	if err != nil {
		cancel(err)
		return nil, err
	}
	var releases []func()
	opened := false
	cleanup := func() {
		s.windowsLocal.leaveTab(h, t, opened)
		for i := len(releases) - 1; i >= 0; i-- {
			releases[i]()
		}
	}
	success := false
	defer func() {
		if !success {
			cancel(nil)
			cleanup()
		}
	}()
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case <-h.done:
		return nil, h.err
	case <-h.ready:
	}
	if h.ptyProtocol != 1 {
		return nil, errors.New("当前活动会话使用旧版助手。请保存工作并在空闲时重新打开工作台。")
	}
	if len(folders) != 0 {
		p := s.windowsLocal
		p.projectMu.Lock()
		view, err := s.readLocalProjectView(ctx, true)
		if err == nil {
			group := view.group(folders[0])
			if group == nil || !slices.Equal(group.Folders, folders) {
				err = errors.New("项目目录已更改，请重新打开。")
			} else {
				p.tabsMu.Lock()
				t.folders = slices.Clone(folders)
				p.tabsMu.Unlock()
			}
		}
		p.projectMu.Unlock()
		if err != nil {
			return nil, err
		}
		// A previously independent project may now belong to a larger group.
		// Resume at its original cwd while keeping the other authorized folders.
		if launch.Project != "" {
			n := slices.IndexFunc(folders, func(path string) bool { return strings.EqualFold(path, launch.Project) })
			if n < 0 {
				return nil, errors.New("原会话的工作目录已撤销授权。")
			}
			folders = slices.Clone(folders)
			folder := folders[n]
			copy(folders[1:n+1], folders[:n])
			folders[0] = folder
		}
	}
	for i, folder := range folders {
		mount, release, err := s.openWindowsLocalVolume(ctx, folder)
		if err != nil {
			return nil, err
		}
		releases = append(releases, release)
		if i == 0 {
			launch.Project, launch.Mount = folder, mount
		} else {
			launch.Additional = append(launch.Additional, folder)
			launch.AdditionalMounts = append(launch.AdditionalMounts, mount)
		}
	}
	launch.Type, launch.App, launch.ID = "open", "pty", t.id
	opened = h.send(ctx, launch)
	if !opened {
		return nil, errors.New("工作台已断开。")
	}
	var hello windowsLocalEvent
	select {
	case <-ctx.Done():
		return nil, ctx.Err()
	case <-h.done:
		return nil, h.err
	case hello = <-t.frames:
	}
	if hello.Type == "error" {
		return nil, errors.New(hello.Message)
	}
	if hello.Type != "ready" || hello.IntegrityLabel != "Low" || hello.WorkerSID != h.binding.WorkerSID ||
		hello.InstanceID != h.binding.InstanceID || hello.WorkerUsername == "" ||
		(launch.Kind == "claude" && (!validNativeClaudeAccount(hello.Account) || launch.Account != "" && launch.Account != hello.Account)) {
		return nil, errors.New("无法核实终端、账号或权限。")
	}
	r, w := io.Pipe()
	p := &windowsLocalPTY{ctx: ctx, cancel: cancel, tab: t, hub: h, reader: r, done: make(chan struct{}), account: hello.Account, accountLabel: hello.AccountLabel}
	success = true
	go func() {
		if hello.ReopenedDraft {
			_, _ = io.WriteString(w, "此账号尚无该编号的 Claude 对话记录，已用原编号重新打开。\r\n")
		}
		p.err = p.pump(w)
		_ = w.CloseWithError(p.err)
		cancel(nil)
		cleanup()
		close(p.done)
	}()
	return p, nil
}

func (p *windowsLocalPTY) pump(w io.Writer) error {
	for {
		select {
		case <-p.ctx.Done():
			return context.Cause(p.ctx)
		case <-p.hub.done:
			return p.hub.err
		case frame := <-p.tab.frames:
			switch frame.Type {
			case "exit":
				if frame.Code != 0 {
					return fmt.Errorf("终端已退出（%d）", frame.Code)
				}
				return nil
			case "error":
				return errors.New(frame.Message)
			case "output":
				var packet struct{ Text []byte }
				if json.Unmarshal(frame.raw, &packet) != nil || len(packet.Text) > 16<<10 {
					return errors.New("终端输出无效。")
				}
				if _, err := w.Write(packet.Text); err != nil {
					return err
				}
			default:
				return errors.New("终端协议无效。")
			}
		}
	}
}

func (p *windowsLocalPTY) send(event any) error {
	raw, err := json.Marshal(event)
	if err != nil {
		return err
	}
	if !p.hub.send(p.ctx, windowsLocalEnvelope{ID: p.tab.id, Type: "event", Event: raw}) {
		return os.ErrClosed
	}
	return nil
}
func (p *windowsLocalPTY) Read(data []byte) (int, error) { return p.reader.Read(data) }
func (p *windowsLocalPTY) Write(data []byte) (int, error) {
	total := 0
	for len(data) > 0 {
		n := min(16<<10, len(data))
		if err := p.send(map[string]string{"type": "input", "text": base64.StdEncoding.EncodeToString(data[:n])}); err != nil {
			return total, err
		}
		total += n
		data = data[n:]
	}
	return total, nil
}
func (p *windowsLocalPTY) Resize(cols, rows uint16) error {
	return p.send(map[string]any{"type": "resize", "cols": cols, "rows": rows})
}
func (p *windowsLocalPTY) Close() error { p.cancel(nil); return p.reader.Close() }
func (p *windowsLocalPTY) Kill() error  { return p.Close() }
func (p *windowsLocalPTY) Wait() error  { <-p.done; return p.err }

func validNativeClaudeAccount(id string) bool {
	if id == "default" {
		return true
	}
	if len(id) != 32 || strings.Trim(id, "0123456789abcdef") != "" {
		return false
	}
	return true
}

func (s *Server) createWindowsLocalTerminal(in terminalRequest) (*terminalSession, error) {
	if in.requestContext == nil || s.windowsLocal.active.Load() == nil {
		return nil, errTerminalNotReady
	}
	if in.Kind == "" {
		in.Kind = "shell"
	}
	if in.Kind != "shell" && in.Kind != "claude" || in.Kind == "shell" && (in.ClaudeAccountID != "" || in.sharedID != "") {
		return nil, errors.New("Windows 原生终端支持 PowerShell 或 Claude。")
	}
	launch := windowsLocalEnvelope{Kind: in.Kind, Account: in.ClaudeAccountID}
	var record *mobileRecord
	if in.sharedID != "" {
		s.mobileCLI.mu.Lock()
		found, err := s.mobileCLI.record(s.profile, in.sharedID)
		s.mobileCLI.mu.Unlock()
		if err != nil {
			return nil, err
		}
		if !found.Terminal || found.Deleted || found.Deleting || found.Purged || found.Archived || found.Launcher != "windows-local-claude" {
			return nil, errors.New("当前账号无法打开这段会话。")
		}
		record = found
		in.Workspace = record.Workspace
		launch.CLIID, launch.Account, launch.Resume = record.CLIID, record.Account.ID, true
	}
	folders, err := s.localTerminalFolders(in.requestContext, in.Workspace)
	if err != nil {
		return nil, err
	}
	if len(folders) > 0 {
		if record != nil {
			launch.Project = record.Workspace
		} else {
			in.Workspace = folders[0]
		}
	} else {
		in.Workspace = "~"
	}
	if record != nil {
		if live := s.terminals.get(record.TerminalID); live != nil {
			if live.ownsConversation() {
				return live, nil
			}
			s.terminals.remove(record.TerminalID)
		}
	}
	if in.Kind == "claude" && record == nil {
		id := uuid.NewString()
		record = &mobileRecord{mobileSession: mobileSession{mobileSummary: mobileSummary{ID: id, Workspace: in.Workspace}, Turns: []mobileTurn{}},
			CLIID: id, Terminal: true, Launcher: "windows-local-claude"}
		launch.CLIID = id
	}
	if launch.Account != "" && !validNativeClaudeAccount(launch.Account) {
		return nil, errors.New("Windows Claude 账号无效。")
	}
	var pty *windowsLocalPTY
	var startErr error
	session, err := s.terminals.startSessionWithPTY(nil, in.Workspace, in.Kind, claudeSelection{}, nil, func() (terminalPTY, error) {
		pty, startErr = s.startLocalPTY(in.requestContext, launch, folders)
		return pty, startErr
	})
	if startErr != nil {
		return nil, startErr
	}
	if err != nil {
		return nil, err
	}
	if record == nil {
		return session, nil
	}
	session.mu.Lock()
	session.sharedID, session.claudeAccountID, session.claudeAccountLabel = record.ID, pty.account, pty.accountLabel
	session.claudeAccountSource = "managed"
	if pty.account == "default" {
		session.claudeAccountSource = "default"
	}
	title := session.title
	session.mu.Unlock()
	s.mobileCLI.mu.Lock()
	record.Generation = s.mobileCLI.epochLocked()
	record.Account = claudeSelection{ID: pty.account, GuestID: pty.account}
	record.AccountLabel = pty.accountLabel
	record.TerminalID = session.id
	if record.Title == "" {
		record.Title = title
	}
	record.changed()
	err = writePrivate(mobileRecordPath(s.profile, record.ID), record)
	if err == nil && s.mobileCLI.catalog != nil {
		s.mobileCLI.catalog[record.ID] = record.summary()
	}
	s.mobileCLI.mu.Unlock()
	if err != nil {
		s.terminals.remove(session.id)
		return nil, err
	}
	return session, nil
}

func (s *Server) windowsLocalSessions(w http.ResponseWriter, r *http.Request) {
	p := s.windowsLocal
	p.projectMu.Lock()
	view, err := s.readLocalProjectView(r.Context(), false)
	p.projectMu.Unlock()
	if err != nil {
		requestError(w, err)
		return
	}
	granted := map[string]bool{"~": true}
	for _, path := range view.paths {
		granted[path] = true
	}
	rows, err := s.mobileCLI.summaries(s.profile, granted, r.URL.Query().Get("archived") == "true")
	if err != nil {
		requestError(w, err)
		return
	}
	jsonReply(w, map[string]any{"sessions": rows})
}
