package workbench

import (
	"context"
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

// Opt-in against a provisioned native account. Only freshly created folders
// beneath the caller's scratch root are granted. No worker or proxy is opened.
func TestWindowsLocalProjectGroupRoundTrip(t *testing.T) {
	helper, profile, root := os.Getenv("CAGE_TEST_PROJECT_HELPER"), os.Getenv("CAGE_TEST_PROJECT_PROFILE"), os.Getenv("CAGE_TEST_PROJECT_ROOT")
	if helper == "" || profile == "" || root == "" {
		t.Skip("requires a provisioned account and an independent scratch directory")
	}
	dir, err := os.MkdirTemp(root, "group-roundtrip-")
	if err != nil {
		t.Fatal(err)
	}
	defer os.RemoveAll(dir)
	main, extra := filepath.Join(dir, "main"), filepath.Join(dir, "extra")
	for _, path := range []string{main, extra} {
		if err = os.Mkdir(path, 0700); err != nil {
			t.Fatal(err)
		}
	}
	s := testServer(t)
	p := &windowsLocalPrototype{helper: helper, profile: profile, bindingPath: filepath.Join(s.profile, "windows-local-workbench.json")}
	if err := p.activate(context.Background(), true); err != nil {
		t.Fatal(err)
	}
	s.windowsLocal = p
	requestJSON := func(method, endpoint string, body any, code int) map[string]any {
		t.Helper()
		data, _ := json.Marshal(body)
		result := request(s, method, endpoint, s.origin, string(data), true)
		if result.Code != code {
			t.Fatalf("%s %s -> %d: %s", method, endpoint, result.Code, result.Body.String())
		}
		var out map[string]any
		if code == 200 {
			if err := json.Unmarshal(result.Body.Bytes(), &out); err != nil {
				t.Fatal(err)
			}
		}
		return out
	}
	// Make cleanup independent of the rest of the test, including a partially
	// failed assertion. Revoke while the original directory objects exist.
	defer func() {
		for _, path := range []string{main, extra} {
			_, err := p.projectRequest(context.Background(), windowsLocalProjectRequest{Path: path, Access: "revoke"})
			if err != nil {
				t.Errorf("cleanup %s: %v", path, err)
			}
		}
	}()
	// An invalid member must never grant the first one.
	requestJSON("POST", "/api/projects/save", map[string]any{"name": "broken", "folders": []string{main, filepath.Join(dir, "missing")}}, 400)
	view, err := s.readLocalProjectView(context.Background(), true)
	if err != nil || view.grant(main) != "" {
		t.Fatalf("partial grant: %v %v", view, err)
	}
	requestJSON("POST", "/api/projects/save", map[string]any{"name": "native group", "folders": []string{main, extra}, "folder_access": map[string]string{main: "rw"}}, 200)
	requestJSON("POST", "/api/projects/open", map[string]any{"workspace": extra, "activate": true}, 200)
	// Discard cached state exactly as on a new controller; grants and metadata
	// must both be sufficient to reassemble the group.
	p.projectView = nil
	status := requestJSON("GET", "/api/status", nil, 200)
	if status["workspace"] != main {
		t.Fatalf("selected workspace = %v", status["workspace"])
	}
	grants, ok := status["project_access"].(map[string]any)
	if !ok || grants[main] != "rw" || grants[extra] != "ro" {
		t.Fatalf("project grants = %v", grants)
	}
	folders, err := s.windowsLocalProjectFolders(context.Background(), extra)
	if err != nil || len(folders) != 2 || folders[0] != main || folders[1] != extra {
		t.Fatalf("group = %v %v", folders, err)
	}
	requestJSON("POST", "/api/projects/remove", map[string]string{"workspace": main}, 200)
	if _, err := s.windowsLocalProjectFolders(context.Background(), extra); err == nil {
		t.Fatal("revoked member still opens")
	}
}
