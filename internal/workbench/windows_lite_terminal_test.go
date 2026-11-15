package workbench

import (
	"bytes"
	"context"
	"encoding/binary"
	"errors"
	"io"
	"net"
	"path/filepath"
	"strings"
	"sync/atomic"
	"testing"
	"time"
)

func TestWindowsLiteTerminalRejectsStaleOrMismatchedPlan(t *testing.T) {
	profile := t.TempDir()
	directory := filepath.Join(t.TempDir(), "Sandboxie")
	now := time.Now()
	state := windowsLiteSnapshot{Phase: "running", Acceptance: "verified", Network: "open", Profile: profile, BoxName: "CageProbe_example", Settings: map[string]any{"sandboxieDirectory": directory}, Monitor: windowsLiteMonitor{Phase: "healthy", SessionID: "session", ConfigHash: strings.Repeat("a", 64), LastCheckedAt: now, ValidUntil: now.Add(45 * time.Second)}}
	plan := windowsLiteTerminalPlan{LeaseID: "lease", Command: []string{filepath.Join(directory, "Start.exe"), "/box:CageProbe_example", "/silent", "CageTerminal.exe"}, Environment: map[string]string{"SystemRoot": directory}, Cwd: directory, Profile: profile, BoxName: state.BoxName, Kind: "shell", SessionID: "session", ConfigurationHash: state.Monitor.ConfigHash}
	if err := validateWindowsLiteTerminalPlan(plan, state, profile, "shell", ""); err != nil {
		t.Fatal(err)
	}
	for _, change := range []func(*windowsLiteTerminalPlan, *windowsLiteSnapshot){
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) {
			s.Monitor.ValidUntil = time.Now().Add(-time.Second)
		},
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) { p.SessionID = "previous" },
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) {
			p.ConfigurationHash = strings.Repeat("b", 64)
		},
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) { p.BoxName = "OtherBox" },
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) {
			p.Command = []string{filepath.Join(directory, "powershell.exe"), "/box:" + p.BoxName, "a", "b"}
		},
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) { p.Profile = filepath.Join(profile, "other") },
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) { s.Profile = filepath.Join(profile, "other") },
		func(p *windowsLiteTerminalPlan, s *windowsLiteSnapshot) { p.Environment = nil },
	} {
		p, s := plan, state
		change(&p, &s)
		if validateWindowsLiteTerminalPlan(p, s, profile, "shell", "") == nil {
			t.Fatal("accepted stale or mismatched terminal authorization")
		}
	}
}

func TestWindowsLiteTerminalWireInputResizeOutputAndExit(t *testing.T) {
	host, guest := net.Pipe()
	defer guest.Close()
	var released atomic.Int32
	terminal := newWindowsLiteTerminal(host, []byte("first\n"), nil, func() { released.Add(1) })
	defer terminal.Close()
	checks := make(chan error, 1)
	go func() {
		kind, payload, err := readWindowsLiteTerminalFrame(guest)
		if err == nil && (kind != 'I' || string(payload) != "echo hi\r") {
			err = io.ErrUnexpectedEOF
		}
		if err == nil {
			kind, payload, err = readWindowsLiteTerminalFrame(guest)
		}
		if err == nil && (kind != 'R' || len(payload) != 4 || binary.LittleEndian.Uint16(payload) != 120 || binary.LittleEndian.Uint16(payload[2:]) != 40) {
			err = io.ErrUnexpectedEOF
		}
		if err == nil {
			err = writeWindowsLiteTerminalFrame(guest, 'O', []byte("hello\n"))
		}
		if err == nil {
			err = writeWindowsLiteTerminalFrame(guest, 'X', []byte{0, 0, 0, 0})
		}
		checks <- err
	}()
	if _, err := terminal.Write([]byte("echo hi\r")); err != nil {
		t.Fatal(err)
	}
	if err := terminal.Resize(120, 40); err != nil {
		t.Fatal(err)
	}
	output, err := io.ReadAll(terminal)
	if err != nil || string(output) != "first\nhello\n" {
		t.Fatalf("output=%q error=%v", output, err)
	}
	if err = <-checks; err != nil {
		t.Fatal(err)
	}
	if err = terminal.Wait(); err != nil {
		t.Fatal(err)
	}
	_ = terminal.Kill()
	_ = terminal.Close()
	if released.Load() != 1 {
		t.Fatal("terminal lease was not released exactly once")
	}
}

func TestWindowsLiteTerminalCloseUnblocksUnreadOutput(t *testing.T) {
	host, guest := net.Pipe()
	defer guest.Close()
	terminal := newWindowsLiteTerminal(host, bytes.Repeat([]byte("x"), 1024), nil, nil)
	_ = terminal.Close()
	done := make(chan struct{})
	go func() { _ = terminal.Wait(); close(done) }()
	select {
	case <-done:
	case <-time.After(time.Second):
		t.Fatal("unread terminal output blocked close")
	}
}

func TestWindowsLiteTerminalRejectsOversizedFrameAndManagedRequests(t *testing.T) {
	header := []byte{'O', 1, 0, 1, 0}
	if _, _, err := readWindowsLiteTerminalFrame(bytes.NewReader(header)); err == nil {
		t.Fatal("accepted oversized frame")
	}
	s := liteFixture(t)
	for _, input := range []terminalRequest{{Kind: "claude-login"}, {Kind: "shell", sharedID: "conversation"}, {Kind: "claude", ClaudeAccountID: "managed"}} {
		input.requestContext = context.Background()
		if _, err := s.createWindowsLiteTerminal(input); err == nil {
			t.Fatal("accepted unsupported managed terminal")
		}
	}
}

func TestWindowsLiteTerminalExpiryRejectsInputAndResize(t *testing.T) {
	for _, resize := range []bool{false, true} {
		host, guest := net.Pipe()
		var released atomic.Int32
		terminal := newWindowsLiteTerminal(host, nil, func() bool { return false }, func() { released.Add(1) })
		var err error
		if resize {
			err = terminal.Resize(120, 40)
		} else {
			_, err = terminal.Write([]byte("must-not-send"))
		}
		if !errors.Is(err, errTerminalNotReady) {
			t.Fatalf("expired authorization returned %v", err)
		}
		var data [1]byte
		if n, err := guest.Read(data[:]); n != 0 || err == nil {
			t.Fatal("expired terminal sent a frame")
		}
		if released.Load() != 1 {
			t.Fatal("expired terminal did not release its lease")
		}
		_ = guest.Close()
		_ = terminal.Wait()
	}
	s := liteFixture(t)
	if _, err := s.createWindowsLiteTerminal(terminalRequest{Kind: "shell"}); !errors.Is(err, errTerminalNotReady) {
		t.Fatalf("unready entry returned %v", err)
	}
}
