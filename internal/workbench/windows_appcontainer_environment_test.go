//go:build windows

package workbench

import (
	"context"
	"encoding/json"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestWindowsAppContainerEnvironmentPersistence(t *testing.T) {
	launcher := os.Getenv("CAGE_TEST_APPCONTAINER_LAUNCHER")
	if launcher == "" {
		t.Skip("requires a locally built AppContainer candidate launcher")
	}
	base, err := os.MkdirTemp(filepath.Dir(launcher), "environment-persistence-")
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()
	env, err := createWindowsAppContainerEnvironment(ctx, launcher, filepath.Join(base, "environment"))
	if err != nil {
		t.Fatal(err)
	}
	defer env.Close()
	profile, sid := env.manifest.ProfileName, env.manifest.ProfileSID
	defer func() {
		if err := deleteTerminalAppContainer(profile); err != nil {
			t.Error(err)
		}
	}()
	if _, err := openWindowsAppContainerEnvironment(launcher, env.root); err == nil {
		t.Fatal("duplicate controller accepted")
	}
	source := filepath.Join(env.root, "private", "import-source")
	toolSource := filepath.Join(env.root, "private", "tools-source")
	for _, dir := range []string{source, toolSource} {
		if err := os.Mkdir(dir, 0700); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(source, "data.txt"), []byte("original\r\n"), 0600); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(toolSource, "check.cmd"), []byte("@set /a result=3037*19\r\n@echo %result%\r\n"), 0600); err != nil {
		t.Fatal(err)
	}
	ro, err := env.ImportProject(source, "readable copy", "read-only")
	if err != nil {
		t.Fatal(err)
	}
	rw, err := env.ImportProject(source, "editable copy", "read-write")
	if err != nil {
		t.Fatal(err)
	}
	tools, err := env.ImportTools(toolSource, "fixture")
	if err != nil {
		t.Fatal(err)
	}
	shell := filepath.Join(os.Getenv("SystemRoot"), "System32", "cmd.exe")
	one, err := env.StartTerminal(ctx, shell, "cmd", ro.ID, "/d", "/q")
	if err != nil {
		t.Fatal(err)
	}
	defer one.Close()
	oneOutput := make(chan []byte, 1)
	go func() { data, _ := io.ReadAll(one); oneOutput <- data }()
	two, err := env.StartTerminal(ctx, shell, "cmd", rw.ID, "/d", "/q")
	if err != nil {
		t.Fatal(err)
	}
	defer two.Close()
	twoOutput := make(chan []byte, 1)
	go func() { data, _ := io.ReadAll(two); twoOutput <- data }()
	if _, err := env.ImportProject(source, "while running", "read-only"); err == nil {
		t.Fatal("import accepted while terminals active")
	}
	// The completion marker is in the writable HOME, outside the read-only cwd.
	if _, err := one.Write([]byte("@echo off\recho denied>data.txt\recho ready>\"%USERPROFILE%\\ro-done.txt\"\r")); err != nil {
		t.Fatal(err)
	}
	marker := filepath.Join(env.root, "work", "ro-done.txt")
	for {
		if _, err := os.Stat(marker); err == nil {
			break
		}
		select {
		case <-ctx.Done():
			t.Fatal("read-only terminal did not reach marker")
		case <-time.After(30 * time.Millisecond):
		}
	}
	if err := one.Close(); err != nil {
		t.Fatal(err)
	}
	select {
	case <-oneOutput:
	case <-ctx.Done():
		t.Fatal("first terminal did not close")
	}
	// The second job must remain alive after the first relay has been closed.
	script := "@echo off\recho edited>data.txt\recho durable>\"%USERPROFILE%\\saved.txt\"\r" +
		"type \"" + filepath.Join(source, "data.txt") + "\" >\"%USERPROFILE%\\private-leak.txt\"\r" +
		"echo denied>\"" + filepath.Join(source, "data.txt") + "\"\r" +
		"call \"" + filepath.Join(tools, "check.cmd") + "\"\rset /a 91003*7 & echo.\rexit /b 0\r"
	if _, err := two.Write([]byte(script)); err != nil {
		t.Fatal(err)
	}
	var transcript []byte
	select {
	case transcript = <-twoOutput:
	case <-ctx.Done():
		t.Fatal("second terminal was not independent")
	}
	if err := two.Wait(); err != nil {
		t.Fatal(err)
	}
	if !strings.Contains(string(transcript), "637021") || !strings.Contains(string(transcript), "57703") {
		t.Fatalf("missing executed command/tool answers: %q", transcript)
	}
	checkFile := func(path, expected string) {
		t.Helper()
		data, err := os.ReadFile(path)
		if err != nil || strings.TrimSpace(string(data)) != expected {
			t.Fatalf("%s: wanted %q, got %q (%v)", path, expected, data, err)
		}
	}
	checkFile(filepath.Join(env.root, "projects", ro.ID, "data.txt"), "original")
	checkFile(filepath.Join(env.root, "projects", rw.ID, "data.txt"), "edited")
	checkFile(filepath.Join(source, "data.txt"), "original")
	checkFile(filepath.Join(env.root, "work", "private-leak.txt"), "")
	checkFile(filepath.Join(env.root, "work", "saved.txt"), "durable")
	if err := env.Close(); err != nil {
		t.Fatal(err)
	}
	reopened, err := openWindowsAppContainerEnvironment(launcher, env.root)
	if err != nil {
		t.Fatal(err)
	}
	defer reopened.Close()
	if reopened.manifest.ProfileName != profile || reopened.manifest.ProfileSID != sid || len(reopened.Projects()) != 2 {
		t.Fatal("environment identity or projects did not persist")
	}
	three, err := reopened.StartTerminal(ctx, shell, "cmd", "", "/d", "/q")
	if err != nil {
		t.Fatal(err)
	}
	defer three.Close()
	threeOutput := make(chan []byte, 1)
	go func() { data, _ := io.ReadAll(three); threeOutput <- data }()
	if _, err := three.Write([]byte("@echo off\rtype saved.txt\rcall \"" + filepath.Join(tools, "check.cmd") + "\"\rexit /b 0\r")); err != nil {
		t.Fatal(err)
	}
	select {
	case data := <-threeOutput:
		if !strings.Contains(string(data), "durable") || !strings.Contains(string(data), "57703") {
			t.Fatalf("state/tool missing after reopen: %q", data)
		}
	case <-ctx.Done():
		t.Fatal("reopened terminal timed out")
	}
	if err := three.Wait(); err != nil {
		t.Fatal(err)
	}
	export := filepath.Join(base, "export")
	if err := reopened.ExportProject(rw.ID, export); err != nil {
		t.Fatal(err)
	}
	checkFile(filepath.Join(export, "data.txt"), "edited")
	if err := reopened.ExportProject(rw.ID, export); err == nil {
		t.Fatal("export overwrote an existing directory")
	}
	// A hard-linked source is rejected; import never follows it to host data.
	hardlinks := filepath.Join(env.root, "private", "hardlinks")
	if err := os.Mkdir(hardlinks, 0700); err != nil {
		t.Fatal(err)
	}
	if err := os.Link(filepath.Join(source, "data.txt"), filepath.Join(hardlinks, "link.txt")); err != nil {
		t.Fatal(err)
	}
	if _, err := reopened.ImportProject(hardlinks, "hardlink", "read-only"); err == nil {
		t.Fatal("hard-linked source was imported")
	}
	junctions := filepath.Join(env.root, "private", "junctions")
	if err := os.Mkdir(junctions, 0700); err != nil {
		t.Fatal(err)
	}
	if output, err := exec.Command(shell, "/d", "/c", "mklink", "/j", filepath.Join(junctions, "escape"), source).CombinedOutput(); err != nil {
		t.Fatalf("create test junction: %v: %s", err, output)
	}
	if _, err := reopened.ImportProject(junctions, "junction", "read-only"); err == nil {
		t.Fatal("junction source was imported")
	}
	if output, err := exec.Command(shell, "/d", "/c", "mklink", "/j", filepath.Join(env.root, "projects", rw.ID, "escape"), source).CombinedOutput(); err != nil {
		t.Fatalf("create test export junction: %v: %s", err, output)
	}
	if err := reopened.ExportProject(rw.ID, filepath.Join(base, "unsafe-export")); err == nil {
		t.Fatal("junction project was exported")
	}
	if err := reopened.Close(); err != nil {
		t.Fatal(err)
	}
	result := map[string]any{"passed": true, "mode": "ordinary AppContainer", "persistentIdentity": true, "persistentWorkAndTools": true, "reopenedProjects": true, "simultaneousTerminals": 2, "closingOnePreservesOther": true, "readOnlyProjectUnchanged": true, "readWriteProjectEdited": true, "hostSourceReadDenied": true, "hostSourceUnchanged": true, "exportFreshOnly": true, "hardlinkImportRejected": true, "junctionImportRejected": true, "junctionExportRejected": true, "scope": "managed project copies; no host project ACL grants; candidate backend only"}
	data, _ := json.MarshalIndent(result, "", "  ")
	if err := os.WriteFile(filepath.Join(base, "environment-verification.json"), append(data, '\n'), 0600); err != nil {
		t.Fatal(err)
	}
	t.Logf("retained candidate evidence: %s", base)
}
