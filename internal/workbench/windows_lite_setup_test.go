package workbench

import (
	"crypto/sha256"
	"encoding/hex"
	"os"
	"path/filepath"
	"runtime"
	"testing"
)

func TestWindowsLiteInstalledComponentsDoNotAuthorizeApplications(t *testing.T) {
	s := liteFixture(t)
	if err := writePrivate(filepath.Join(s.windowsLiteProfile(), "setup.json"), windowsLiteSetupRecord{Version: 1, Completed: true, Directory: t.TempDir()}); err != nil {
		t.Fatal(err)
	}
	view, err := s.initializationState()
	if err != nil || view.Required || !view.Prepared {
		t.Fatalf("installed components did not complete onboarding: %+v %v", view, err)
	}
	if s.environmentPrepared() || s.vmRunning() || s.finishInitialization() == nil || windowsLiteCapabilities(s.windowsLiteState())["sandbox_verified"] {
		t.Fatal("component installation authorized unverified applications")
	}
}

func TestWindowsLiteBrokenSetupRecordRetainsData(t *testing.T) {
	s := liteFixture(t)
	path := filepath.Join(s.windowsLiteProfile(), "setup.json")
	if err := os.MkdirAll(filepath.Dir(path), 0700); err != nil {
		t.Fatal(err)
	}
	for _, data := range []string{`{`, `{"version":2,"completed":true}`, `{"version":1,"completed":true,"sandboxie_directory":"relative"}`} {
		if err := os.WriteFile(path, []byte(data), 0600); err != nil {
			t.Fatal(err)
		}
		if ok, err := s.windowsLiteComponentsPrepared(); err == nil || ok {
			t.Fatal("invalid installation claimed completion")
		}
		actual, err := os.ReadFile(path)
		if err != nil || string(actual) != data {
			t.Fatal("invalid record was overwritten")
		}
	}
}

func TestWindowsLitePackageDigestRejectsChangedFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "installer.exe")
	original := []byte("synthetic installer")
	digest := sha256.Sum256(original)
	expected := hex.EncodeToString(digest[:])
	if err := os.WriteFile(path, original, 0600); err != nil {
		t.Fatal(err)
	}
	if valid, err := liteArtifactMatches(path, expected); err != nil || !valid {
		t.Fatalf("valid digest rejected: %v", err)
	}
	changed := []byte("changed installer")
	if err := os.WriteFile(path, changed, 0600); err != nil {
		t.Fatal(err)
	}
	if valid, err := liteArtifactMatches(path, expected); err != nil || valid {
		t.Fatal("changed package was accepted")
	}
	actual, err := os.ReadFile(path)
	if err != nil || string(actual) != string(changed) {
		t.Fatal("failed verification altered the package")
	}
	if valid, err := liteArtifactMatches(filepath.Dir(path), expected); err == nil || valid {
		t.Fatal("directory was accepted as installer")
	}
}

func TestWindowsLiteFailedSetupCannotCompleteOnboarding(t *testing.T) {
	if runtime.GOOS != "windows" {
		t.Skip("Windows installation flow")
	}
	s := liteFixture(t)
	s.exe = filepath.Join(t.TempDir(), "cage.exe") // Deliberately incomplete package.
	state := s.initialWindowsLiteState()
	state.Phase, state.Network, state.ProcessCount = "stopped", "closed", 0
	s.windowsLite.Load().worker = &liteFakeWorker{response: liteResponse(t, true, state)}
	persist := filepath.Join(s.profile, "personal-data")
	if err := os.WriteFile(persist, []byte("keep this"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := s.setupWindowsLite(); err == nil {
		t.Fatal("incomplete package completed installation")
	}
	view, err := s.initializationState()
	if err != nil || !view.Required || view.Prepared {
		t.Fatalf("failed setup lost retry state: %+v %v", view, err)
	}
	actual, err := os.ReadFile(persist)
	if err != nil || string(actual) != "keep this" {
		t.Fatal("failed installation changed personal data")
	}
}
