package workbench

import (
	"context"
	"encoding/json"
	"net/http/httptest"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestWindowsLiteBrowserRequiresCurrentSpaceLaunch(t *testing.T) {
	previous := windowsLiteHostAvailable
	windowsLiteHostAvailable = func() bool { return true }
	t.Cleanup(func() { windowsLiteHostAvailable = previous })
	for _, scenario := range []string{"current", "previous-session", "changed-configuration", "remote-control", "outside-profile"} {
		t.Run(scenario, func(t *testing.T) {
			s := liteFixture(t)
			resources := t.TempDir()
			s.exe = filepath.Join(resources, "cage.exe")
			if err := os.MkdirAll(filepath.Join(resources, "windows-lite"), 0700); err != nil {
				t.Fatal(err)
			}
			for _, name := range []string{"node.exe", "windows-lite/browser-controller.mjs"} {
				if err := os.WriteFile(filepath.Join(resources, name), nil, 0600); err != nil {
					t.Fatal(err)
				}
			}
			state := s.initialWindowsLiteState()
			state.Phase, state.Network, state.Acceptance, state.ProcessCount = "running", "open", "verified", 1
			state.Capabilities = map[string]bool{"embedded_browser": true}
			state.Monitor = windowsLiteMonitor{Phase: "healthy", SessionID: "current-session", ConfigHash: strings.Repeat("c", 64), LastCheckedAt: time.Now(), ValidUntil: time.Now().Add(45 * time.Second)}
			launch := windowsLiteBrowserLaunch{CDPURL: "http://127.0.0.1:12345", ProxyURL: "http://127.0.0.1:23456", DataDirectory: filepath.Join(s.windowsLiteProfile(), "browser-data"), PID: 123, SessionID: state.Monitor.SessionID, ConfigHash: state.Monitor.ConfigHash}
			switch scenario {
			case "previous-session":
				launch.SessionID = "previous-session"
			case "changed-configuration":
				launch.ConfigHash = strings.Repeat("d", 64)
			case "remote-control":
				launch.CDPURL = "https://example.com:443"
			case "outside-profile":
				launch.DataDirectory = t.TempDir()
			}
			data, _ := json.Marshal(launch)
			response, _ := json.Marshal(windowsLiteReply{OK: true, State: state, Browser: data})
			s.windowsLite.Load().state = state
			s.windowsLite.Load().worker = &liteFakeWorker{response: response}
			client := s.newWindowsLiteBrowserClient(context.Background())
			defer client.close()
			command, err := client.start(context.Background())
			if scenario != "current" {
				if err == nil || command != nil {
					t.Fatal("untrusted browser launch produced a host controller")
				}
				return
			}
			if err != nil || command == nil {
				t.Fatalf("current space-owned browser rejected: %v", err)
			}
			if command.Path != filepath.Join(resources, "node.exe") {
				t.Fatal("controller used an inherited executable")
			}
			state.Monitor.ValidUntil = time.Now().Add(-time.Second)
			s.windowsLite.Load().state = state
			if client.admit() == nil || s.environmentPrepared() {
				t.Fatal("expired monitor retained browser admission")
			}
		})
	}
}

func TestWindowsLiteUnavailableFileTransferDoesNotStartHostSave(t *testing.T) {
	s := liteFixture(t)
	s.ready = true
	item := browserDownloadInfo{ID: "01234567-89ab-cdef-0123-456789abcdef", Name: "test.txt", State: "saved", Path: "untrusted-guest-path"}
	if transfer, err := s.startNativeDownload(item); err == nil || transfer != nil {
		t.Fatal("unverified file capability started native transfer")
	}
	mapped := s.nativeDownloadForHost(item)
	if mapped.Path != "" || mapped.Retryable || mapped.State != "failed" || s.nativeDownloads != nil {
		t.Fatal("unavailable transfer exposed a path or queued a host save")
	}
	response := httptest.NewRecorder()
	s.browserUpload(response, httptest.NewRequest("POST", "/api/browser/files/uploads/"+item.ID, nil))
	if response.Code != 409 {
		t.Fatal("upload did not require live transfer capability")
	}
}
