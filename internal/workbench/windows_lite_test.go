package workbench

import (
	"context"
	"encoding/json"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/sylvinus/agent-vm/internal/cage"
	"github.com/sylvinus/agent-vm/internal/windowslite"
)

type liteFakeWorker struct {
	response []byte
	err      error
	closeErr error
	closed   bool
	requests []string
}

func (w *liteFakeWorker) Call(_ context.Context, request json.RawMessage) (json.RawMessage, error) {
	w.requests = append(w.requests, string(request))
	return w.response, w.err
}
func (w *liteFakeWorker) Close() error { w.closed = true; return w.closeErr }

func liteFixture(t *testing.T) *Server {
	t.Helper()
	profile := t.TempDir()
	s := &Server{profile: profile, configPath: filepath.Join(profile, "config.json")}
	s.windowsLite.Store(&windowsLiteRuntime{state: s.initialWindowsLiteState()})
	return s
}

func liteResponse(t *testing.T, ok bool, state windowsLiteSnapshot) []byte {
	t.Helper()
	data, err := json.Marshal(windowsLiteReply{OK: ok, State: state})
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func TestWindowsLiteSelectionSurvivesUnavailableWorker(t *testing.T) {
	profile := t.TempDir()
	file := filepath.Join(profile, "windows-lite.json")
	if err := os.WriteFile(file, []byte(`{"version":1,"kind":"windows-lite"}`), 0600); err != nil {
		t.Fatal(err)
	}
	s := &Server{profile: profile, configPath: filepath.Join(profile, "config.json")}
	if err := s.loadWindowsLiteMode(); err != nil {
		t.Fatal(err)
	}
	if !s.isWindowsLite() {
		t.Fatal("missing worker lost selected backend")
	}
	if s.environmentPrepared() || s.vmRunning() {
		t.Fatal("unverified backend reported ready or running")
	}
	if err := s.runCage("up"); err == nil {
		t.Fatal("Lite fell through to VM command")
	}
	if cmd := s.sshCommandOptions(context.Background(), false, "anything"); cmd.Err == nil {
		t.Fatal("Lite built an SSH command")
	}
}

func TestWindowsLiteBadMarkerNeverFallsBack(t *testing.T) {
	profile := t.TempDir()
	file := filepath.Join(profile, "windows-lite.json")
	for _, data := range []string{`{}`, `{"version":1,"kind":"linux"}`, `{"version":1,"kind":"windows-lite","verified":true}`, `{"version":1,"kind":"windows-lite"}{}`} {
		if err := os.WriteFile(file, []byte(data), 0600); err != nil {
			t.Fatal(err)
		}
		if _, err := windowsLiteSelected(profile); err == nil {
			t.Fatalf("accepted malformed marker: %s", data)
		}
		got, _ := os.ReadFile(file)
		if string(got) != data {
			t.Fatal("changed marker")
		}
	}
}

func TestWindowsLiteRejectsIncompleteOrContradictoryState(t *testing.T) {
	for _, data := range []string{
		`{"ok":true,"state":{"phase":"stopped","network":"closed","acceptance":"not-verified","profile":"x"}}`,
		`{"ok":true,"state":{"phase":"stopped","network":"closed","processCount":2,"acceptance":"not-verified","profile":"x"}}`,
		`{"ok":true,"state":{"phase":"running","network":"open","processCount":1,"acceptance":"not-verified","profile":"x"}}`,
		`{"ok":true,"state":{"phase":"stopped","network":"open","processCount":0,"acceptance":"verified","profile":"x"}}`,
		`{"ok":true,"state":{"phase":"running","network":"open","processCount":-1,"acceptance":"verified","profile":"x"}}`,
		`{"ok":true,"state":{"phase":"invalid","network":"closed","processCount":0,"acceptance":"verified","profile":"x"}}`,
	} {
		if _, err := decodeWindowsLiteReply([]byte(data)); err == nil {
			t.Fatalf("accepted unsafe state: %s", data)
		}
	}
}

func TestWindowsLiteCommunicationFailureBecomesUnknown(t *testing.T) {
	previous := windowsLiteHostAvailable
	previousStart := startWindowsLiteWorker
	windowsLiteHostAvailable = func() bool { return true }
	t.Cleanup(func() { windowsLiteHostAvailable = previous; startWindowsLiteWorker = previousStart })
	s := liteFixture(t)
	backend := s.windowsLite.Load()
	backend.state.ProcessCount = 0
	backend.state.Network = "closed"
	broken := &liteFakeWorker{err: errors.New("connection lost")}
	backend.worker = broken
	starts := 0
	recovered := s.initialWindowsLiteState()
	recovered.Phase, recovered.Network, recovered.ProcessCount = "stopped", "closed", 0
	replacement := &liteFakeWorker{response: liteResponse(t, true, recovered)}
	startWindowsLiteWorker = func(profile string) (windowslite.Worker, error) {
		if profile != s.windowsLiteProfile() {
			t.Fatal("recovery changed the persistent space")
		}
		starts++
		return replacement, nil
	}
	state, err := s.windowsLiteCall(context.Background(), "status", nil)
	if err == nil || state.ProcessCount != -1 || state.Network != "unknown" {
		t.Fatalf("failure was not unknown: %+v %v", state, err)
	}
	if !broken.closed || backend.worker != nil || starts != 0 {
		t.Fatal("failed call kept its worker or retried implicitly")
	}
	state, err = s.windowsLiteCall(context.Background(), "status", nil)
	if err != nil || state.Network != "closed" || starts != 1 || len(replacement.requests) != 1 || replacement.requests[0] != `{"action":"status"}` {
		t.Fatalf("next explicit operation did not recover status: %+v %v", state, err)
	}
}

func TestWindowsLiteCloseRequiresVerifiedStopReply(t *testing.T) {
	for _, confirmed := range []bool{false, true} {
		s := liteFixture(t)
		backend := s.windowsLite.Load()
		state := s.initialWindowsLiteState()
		if confirmed {
			state.Phase = "stopped"
			state.Network = "closed"
			state.ProcessCount = 0
		}
		worker := &liteFakeWorker{response: liteResponse(t, confirmed, state)}
		backend.worker = worker
		err := s.closeWindowsLite()
		if !worker.closed || len(worker.requests) != 1 || worker.requests[0] != `{"action":"stop"}` {
			t.Fatal("close did not request stop before releasing worker")
		}
		if confirmed && err != nil {
			t.Fatal(err)
		}
		if !confirmed && (err == nil || backend.state.Network != "unknown" || backend.state.ProcessCount != -1) {
			t.Fatal("unconfirmed stop reported success")
		}
	}
}

func TestWindowsLiteCloseFailureRevokesPriorVerification(t *testing.T) {
	s := liteFixture(t)
	backend := s.windowsLite.Load()
	state := s.initialWindowsLiteState()
	state.Phase, state.Network, state.ProcessCount, state.Acceptance = "stopped", "closed", 0, "verified"
	backend.state = state
	backend.worker = &liteFakeWorker{response: liteResponse(t, true, state), closeErr: errors.New("worker did not exit")}
	if s.closeWindowsLite() == nil || backend.state.Acceptance != "not-verified" || s.environmentPrepared() || windowsLiteCapabilities(backend.state)["sandbox_verified"] {
		t.Fatal("unconfirmed worker exit retained verification")
	}
}

func TestWindowsLitePreferencesDoNotRequireUnavailableRuntime(t *testing.T) {
	s := liteFixture(t)
	configuration := cage.DefaultConfig()
	configuration.ExitPolicy = configuration.ExitPolicy.Normalized()
	if err := writePrivate(s.configPath, configuration); err != nil {
		t.Fatal(err)
	}
	preferences := Preferences{BrowserHomeURL: "https://example.com/", BalancedDisplay: true}
	if err := s.applyWindowsLiteSettings(savedProfile{Config: configuration, Preferences: preferences}); err != nil {
		t.Fatal(err)
	}
	if s.windowsLite.Load().worker != nil || s.preferences != preferences {
		t.Fatal("preferences required or changed the application runtime")
	}
	var saved Preferences
	data, err := os.ReadFile(filepath.Join(s.profile, "workbench.json"))
	if err != nil || json.Unmarshal(data, &saved) != nil || saved != preferences {
		t.Fatal("preferences were not persisted")
	}
}

func TestWindowsLiteSettingsChangesRequireConfirmedStop(t *testing.T) {
	previous := windowsLiteHostAvailable
	windowsLiteHostAvailable = func() bool { return true }
	t.Cleanup(func() { windowsLiteHostAvailable = previous })
	for _, field := range []string{"dns", "workspace"} {
		t.Run(field, func(t *testing.T) {
			s := liteFixture(t)
			configuration := cage.DefaultConfig()
			configuration.ExitPolicy = configuration.ExitPolicy.Normalized()
			if err := writePrivate(s.configPath, configuration); err != nil {
				t.Fatal(err)
			}
			before, err := os.ReadFile(s.configPath)
			if err != nil {
				t.Fatal(err)
			}
			update := savedProfile{Config: configuration}
			if field == "dns" {
				update.Config.DNSURL = "https://1.0.0.1/dns-query"
			} else {
				update.Preferences.Workspace = t.TempDir()
			}
			backend := s.windowsLite.Load()
			backend.worker = &liteFakeWorker{response: liteResponse(t, true, s.initialWindowsLiteState())}
			if err := s.applyWindowsLiteSettings(update); err == nil {
				t.Fatal("changed settings with unknown process state")
			}
			after, err := os.ReadFile(s.configPath)
			if err != nil || string(after) != string(before) || s.preferences.Workspace != "" {
				t.Fatal("failed save changed settings")
			}
			stopped := s.initialWindowsLiteState()
			stopped.Phase, stopped.Network, stopped.ProcessCount = "stopped", "closed", 0
			backend.worker = &liteFakeWorker{response: liteResponse(t, true, stopped)}
			if err := s.applyWindowsLiteSettings(update); err != nil {
				t.Fatal(err)
			}
			saved, err := cage.Load(s.configPath)
			if err != nil || saved != update.Config || s.preferences != update.Preferences {
				t.Fatal("confirmed stopped save did not persist")
			}
		})
	}
}

func TestWindowsLiteKeepsControlPlaneAndRejectsGuestTransports(t *testing.T) {
	for _, path := range []string{"/api/settings", "/api/proxy/import", "/api/projects/open", "/api/account/unlock", "/api/favorites", "/api/diagnostics/export", "/api/windows-lite/launch", "/api/browser/new", "/api/terminals", "/api/vnc"} {
		if !windowsLiteWorkbenchRoute("POST", path) {
			t.Errorf("control route blocked: %s", path)
		}
	}
	for _, path := range []string{"/api/claude-desktop/start", "/api/environment/guest-systems/activate", "/api/environment/update"} {
		if windowsLiteWorkbenchRoute("POST", path) {
			t.Errorf("unadapted guest route allowed: %s", path)
		}
	}
}

func TestWindowsLiteMonitorLeaseRequiredForBrowserOperations(t *testing.T) {
	s := liteFixture(t)
	s.ready = true // A cached UI ready value must not grant runtime permission.
	state := s.initialWindowsLiteState()
	state.Phase, state.Network, state.ProcessCount, state.Acceptance = "running", "open", 1, "verified"
	state.Capabilities = map[string]bool{"embedded_browser": true, "terminal_stream": true}
	for _, monitor := range []windowsLiteMonitor{
		{},
		{Phase: "healthy", SessionID: "old", ConfigHash: strings.Repeat("a", 64), LastCheckedAt: time.Now().Add(-time.Minute), ValidUntil: time.Now().Add(-time.Second)},
		{Phase: "healthy", SessionID: "unbounded", ConfigHash: strings.Repeat("a", 64), LastCheckedAt: time.Now(), ValidUntil: time.Now().Add(time.Hour)},
	} {
		state.Monitor = monitor
		s.windowsLite.Load().state = state
		if windowsLiteAdmitted(state) || windowsLiteCapabilities(state)["embedded_browser"] {
			t.Fatal("invalid application monitor lease admitted browser")
		}
		if _, err := decodeWindowsLiteReply(liteResponse(t, true, state)); err == nil {
			t.Fatal("worker open state accepted without live monitor")
		}
		if _, err := s.browserAction(context.Background(), "new", &browserInput{URL: "https://example.com/"}); !errors.Is(err, errBrowserNotReady) {
			t.Fatal("cached ready flag bypassed monitor")
		}
	}
	state.Monitor = windowsLiteMonitor{Phase: "healthy", SessionID: "runtime-session", ConfigHash: strings.Repeat("b", 64), LastCheckedAt: time.Now(), ValidUntil: time.Now().Add(45 * time.Second)}
	if !windowsLiteAdmitted(state) || !windowsLiteCapabilities(state)["embedded_browser"] {
		t.Fatal("valid bounded runtime lease rejected")
	}
	if _, err := decodeWindowsLiteReply(liteResponse(t, true, state)); err != nil {
		t.Fatal(err)
	}
}

func TestWindowsLiteInitializationRequiresSetupWithoutClaimingAdmission(t *testing.T) {
	s := liteFixture(t)
	state, err := s.initializationState()
	if err != nil || !state.Required || state.Prepared {
		t.Fatalf("incorrect initialization view: %+v %v", state, err)
	}
	if s.finishInitialization() == nil {
		t.Fatal("unverified space completed initialization")
	}
	if _, err := os.Stat(filepath.Join(s.profile, "initialization.json")); !errors.Is(err, os.ErrNotExist) {
		t.Fatal("wrote false completed installation")
	}
}
