//go:build windows

package workbench

import (
	"context"
	"encoding/json"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"testing"
	"time"
)

// Opt-in real integration: the existing workbench terminal transport talks to
// a disposable local AppContainer through its ordinary JSON protocol. This
// neither selects a new backend nor borrows the guest's isolation assertions.
func TestWindowsAppContainerTerminalTransport(t *testing.T) {
	launcher := os.Getenv("CAGE_TEST_APPCONTAINER_LAUNCHER")
	if launcher == "" {
		t.Skip("requires a locally built AppContainer candidate launcher")
	}
	fixture, err := os.MkdirTemp(filepath.Dir(launcher), "terminal-rpc-")
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("retained candidate evidence: %s", fixture)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, launcher, "terminal-rpc", "ac", fixture, filepath.Join(os.Getenv("SystemRoot"), "System32", "cmd.exe"), "/d", "/q")
	cmd.Env = append(os.Environ(), "CAGE_FAKE_HOST_SECRET=fixture-only")
	terminal, err := startWindowsAppContainerTerminal(cmd, map[string]any{
		"action": "open", "workspace": "home", "shell": "cmd", "cols": 80, "rows": 25,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer terminal.Close()
	if err := terminal.Resize(117, 41); err != nil {
		t.Fatal(err)
	}
	type readResult struct {
		data []byte
		err  error
	}
	output := make(chan readResult, 1)
	go func() { b, e := io.ReadAll(terminal); output <- readResult{b, e} }()
	// Computed answers cannot match the echoed input line accidentally.
	script := "@echo off\rset /a 91003*7 & echo.\rif defined CAGE_FAKE_HOST_SECRET (set /a 17*31 & echo.) else (set /a 19*41 & echo.)\rexit /b 0\r"
	if _, err := terminal.Write([]byte(script)); err != nil {
		t.Fatal(err)
	}
	select {
	case result := <-output:
		if result.err != nil {
			t.Fatal(result.err)
		}
		clean := regexp.MustCompile(`\x1b\[[0-?]*[ -/]*[@-~]`).ReplaceAllString(string(result.data), "")
		clean = strings.ReplaceAll(clean, "\r", "")
		for _, answer := range []string{"637021", "779"} {
			if !regexp.MustCompile(`(?m)^\s*` + answer + `\s*$`).MatchString(clean) {
				t.Fatalf("missing computed answer %s in terminal output: %q", answer, clean)
			}
		}
	case <-ctx.Done():
		t.Fatal("candidate terminal did not finish")
	}
	if err := terminal.Wait(); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(filepath.Join(fixture, "terminal-rpc.json"))
	if err != nil {
		t.Fatal(err)
	}
	var receipt struct {
		TokenVerified       bool   `json:"tokenVerified"`
		IsAppContainer      bool   `json:"isAppContainer"`
		CapabilityCount     int    `json:"capabilityCount"`
		IsLPAC              bool   `json:"isLPAC"`
		ProfileCleanupOwner string `json:"profileCleanupOwner"`
		Error               string `json:"error"`
	}
	if err := json.Unmarshal(data, &receipt); err != nil {
		t.Fatal(err)
	}
	if !receipt.TokenVerified || !receipt.IsAppContainer || receipt.CapabilityCount != 0 || receipt.IsLPAC || receipt.ProfileCleanupOwner != "host controller" || receipt.Error != "" {
		t.Fatalf("candidate did not preserve its own boundary: %s", data)
	}
}

func TestWindowsAppContainerTerminalActiveClose(t *testing.T) {
	launcher := os.Getenv("CAGE_TEST_APPCONTAINER_LAUNCHER")
	if launcher == "" {
		t.Skip("requires a locally built AppContainer candidate launcher")
	}
	fixture, err := os.MkdirTemp(filepath.Dir(launcher), "terminal-active-close-")
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("retained candidate evidence: %s", fixture)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cmd := exec.CommandContext(ctx, launcher, "terminal-rpc", "ac", fixture, filepath.Join(os.Getenv("SystemRoot"), "System32", "cmd.exe"), "/d", "/q")
	terminal, err := startWindowsAppContainerTerminal(cmd, map[string]any{
		"action": "open", "workspace": "home", "shell": "cmd", "cols": 80, "rows": 25,
	})
	if err != nil {
		t.Fatal(err)
	}
	defer terminal.Close()
	if _, err := terminal.Write([]byte("echo pending\r")); err != nil {
		t.Fatal(err)
	}
	// Deliberately do not read output and do not send exit. This models the
	// workbench closing a tab while an active terminal is still producing output.
	closed := make(chan error, 1)
	go func() { closed <- terminal.Kill() }()
	select {
	case err := <-closed:
		if err != nil {
			t.Fatal(err)
		}
	case <-ctx.Done():
		t.Fatal("active terminal did not stop and remove its host-owned profile")
	}
	if cmd.ProcessState == nil || !cmd.ProcessState.Exited() {
		t.Fatal("terminal relay was not reaped")
	}
	if err := os.WriteFile(filepath.Join(fixture, "host-cleanup.json"), []byte(`{"profileCleanupOwner":"host controller","activeClose":true,"profileDeleted":true,"relayReaped":true}`), 0600); err != nil {
		t.Fatal(err)
	}
}
