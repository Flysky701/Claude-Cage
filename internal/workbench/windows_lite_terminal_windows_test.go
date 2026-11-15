package workbench

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"
	"unsafe"

	"golang.org/x/sys/windows"
)

func TestWindowsLiteConsoleProbeChild(t *testing.T) {
	if os.Getenv("CAGE_LITE_TERMINAL_CONSOLE_CHILD") != "1" {
		return
	}
	var box [128]uint16
	var session uint32
	query := windows.NewLazyDLL("SbieDll.dll").NewProc("SbieApi_QueryProcess")
	status, _, _ := query.Call(uintptr(os.Getpid()), uintptr(unsafe.Pointer(&box[0])), 0, 0, uintptr(unsafe.Pointer(&session)))
	if status != 0 || !strings.HasPrefix(windows.UTF16ToString(box[:]), "CageProbe_") {
		os.Exit(7)
	}
	var info windows.ConsoleScreenBufferInfo
	consoleErr := windows.GetConsoleScreenBufferInfo(windows.Handle(os.Stdout.Fd()), &info)
	report, _ := json.Marshal(map[string]any{"box": windows.UTF16ToString(box[:]), "queryStatus": status, "consoleError": fmt.Sprint(consoleErr), "pid": os.Getpid(), "stdout": uintptr(os.Stdout.Fd()), "consoleInfo": info})
	_ = os.WriteFile(os.Getenv("CAGE_LITE_TERMINAL_CHILD_REPORT"), report, 0600)
	written, writeErr := fmt.Println("actual-box:" + windows.UTF16ToString(box[:]))
	writeReport, _ := json.Marshal(map[string]any{"written": written, "error": fmt.Sprint(writeErr)})
	_ = os.WriteFile(os.Getenv("CAGE_LITE_TERMINAL_CHILD_REPORT")+".write", writeReport, 0600)
	text, err := bufio.NewReader(os.Stdin).ReadString('\n')
	if err != nil {
		os.Exit(4)
	}
	fmt.Println("received:" + strings.TrimSpace(text))
	if windows.GetConsoleScreenBufferInfo(windows.Handle(os.Stdout.Fd()), &info) != nil {
		os.Exit(5)
	}
	fmt.Printf("size:%dx%d\n", info.Window.Right-info.Window.Left+1, info.Window.Bottom-info.Window.Top+1)
	os.Exit(0)
}

func TestWindowsLiteForcedConPTYProbe(t *testing.T) {
	root := os.Getenv("CAGE_LITE_TERMINAL_ARTIFACTS")
	if root == "" {
		t.Skip("set CAGE_LITE_TERMINAL_ARTIFACTS for the installed forced ConPTY probe")
	}
	run, err := os.MkdirTemp(root, "terminal-forced-")
	if err != nil {
		t.Fatal(err)
	}
	t.Log("probe artifacts:", run)
	forced := filepath.Join(run, "forced")
	if err = os.Mkdir(forced, 0700); err != nil {
		t.Fatal(err)
	}
	copyPath := filepath.Join(forced, "CageConsoleProbe.exe")
	data, err := os.ReadFile(os.Args[0])
	if err != nil {
		t.Fatal(err)
	}
	if err = os.WriteFile(copyPath, data, 0700); err != nil {
		t.Fatal(err)
	}
	box := "CageProbe_" + randomToken()[:16]
	directory := os.Getenv("CAGE_LITE_SANDBOXIE_DIR")
	if directory == "" {
		directory = `C:\Program Files\Sandboxie-Plus`
	}
	setting := func(args ...string) {
		t.Helper()
		if output, err := exec.Command(filepath.Join(directory, "SbieIni.exe"), args...).CombinedOutput(); err != nil {
			t.Fatalf("configure: %v %q", err, output)
		}
	}
	t.Cleanup(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = exec.CommandContext(ctx, filepath.Join(directory, "Start.exe"), "/box:"+box, "/terminate").Run()
		_ = exec.CommandContext(ctx, filepath.Join(directory, "SbieIni.exe"), "set", box, "Enabled", "n").Run()
	})
	for key, value := range map[string]string{"Enabled": "n", "FileRootPath": filepath.Join(run, "boxdata"), "ConfigLevel": "10", "AutoDelete": "n", "NeverDelete": "y", "AutoRecover": "n", "DropAdminRights": "y", "NoSandboxieConsole": "y", "ForceFolder": forced, "OpenFilePath": run, "NetworkAccess": "*,Block"} {
		setting("set", box, key, value)
	}
	setting("set", box, "Enabled", "y")
	cmd := exec.Command(copyPath, "-test.run=^TestWindowsLiteConsoleProbeChild$")
	cmd.Env = append(os.Environ(), "CAGE_LITE_TERMINAL_CONSOLE_CHILD=1", "CAGE_LITE_TERMINAL_CHILD_REPORT="+filepath.Join(run, "child.json"))
	var manager terminalManager
	t.Cleanup(manager.close)
	session, err := manager.start(cmd, "", "shell")
	if err != nil {
		t.Fatal(err)
	}
	sub := session.subscribe()
	defer sub.Close()
	output := readTerminalUntil(t, sub, "actual-box:"+box)
	if err = session.file.Resize(120, 40); err != nil {
		t.Fatal(err)
	}
	if err = session.enqueueInput(context.Background(), "cage-boxed-input\r"); err != nil {
		t.Fatal(err)
	}
	last := readTerminalUntil(t, sub, "size:120x40")
	output += last
	if !strings.Contains(last, "received:cage-boxed-input") {
		t.Fatalf("input not delivered: %q", last)
	}
	awaitTerminalSignal(t, session.done)
	if err = os.WriteFile(filepath.Join(run, "output.txt"), []byte(output), 0600); err != nil {
		t.Fatal(err)
	}
	report, _ := json.MarshalIndent(map[string]any{"box": box, "sameBox": true, "inputOutput": true, "resize": "120x40", "completed": true, "scope": "forced synthetic process transport probe only; not runtime admission"}, "", "  ")
	if err = os.WriteFile(filepath.Join(run, "report.json"), report, 0600); err != nil {
		t.Fatal(err)
	}
}

// Opt-in transport diagnostic only: it creates and stops its own synthetic
// box. It never produces admission evidence for the application runtime.
func TestWindowsLiteSandboxieConPTYProbe(t *testing.T) {
	helper := os.Getenv("CAGE_LITE_TERMINAL_HELPER")
	if helper == "" {
		t.Skip("set CAGE_LITE_TERMINAL_HELPER to the compiled CageTerminal.exe")
	}
	root := os.Getenv("CAGE_LITE_TERMINAL_ARTIFACTS")
	if root == "" {
		t.Fatal("CAGE_LITE_TERMINAL_ARTIFACTS is required to retain this probe's files")
	}
	run, err := os.MkdirTemp(root, "terminal-native-")
	if err != nil {
		t.Fatal(err)
	}
	t.Log("probe artifacts:", run)
	box := "CageProbe_" + randomToken()[:16]
	directory := os.Getenv("CAGE_LITE_SANDBOXIE_DIR")
	if directory == "" {
		directory = `C:\Program Files\Sandboxie-Plus`
	}
	launcher := filepath.Join(directory, "Start.exe")
	setting := func(args ...string) {
		t.Helper()
		cmd := exec.Command(filepath.Join(directory, "SbieIni.exe"), args...)
		if data, err := cmd.CombinedOutput(); err != nil {
			t.Fatalf("configure probe: %v %q", err, data)
		}
	}
	listener, err := net.ListenTCP("tcp4", &net.TCPAddr{IP: net.IPv4(127, 0, 0, 1)})
	if err != nil {
		t.Fatal(err)
	}
	defer listener.Close()
	t.Cleanup(func() {
		ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		_ = exec.CommandContext(ctx, launcher, "/box:"+box, "/terminate").Run()
		_ = exec.CommandContext(ctx, filepath.Join(directory, "SbieIni.exe"), "set", box, "NetworkAccess", "*,Block").Run()
		_ = exec.CommandContext(ctx, filepath.Join(directory, "SbieIni.exe"), "set", box, "Enabled", "n").Run()
	})
	for key, value := range map[string]string{"Enabled": "n", "FileRootPath": filepath.Join(run, "boxdata"), "ConfigLevel": "10", "AutoDelete": "n", "NeverDelete": "y", "AutoRecover": "n", "DropAdminRights": "y", "UsePrivacyMode": "n", "UseSecurityMode": "n", "UseRuleSpecificity": "n", "NoSandboxieConsole": "y", "OpenFilePath": run, "NetworkAccess": "*,Block"} {
		setting("set", box, key, value)
	}
	setting("append", box, "NetworkAccess", fmt.Sprintf("*,Allow;Address=127.0.0.1;Port=%d;Protocol=TCP", listener.Addr().(*net.TCPAddr).Port))
	setting("set", box, "Enabled", "y")
	token := randomToken()
	if len(token) != 64 {
		t.Fatal("unexpected token length")
	}
	lease := randomToken()[:16]
	cmd := exec.Command(launcher, "/box:"+box, "/silent", "/hide_window", "/wait", helper, "--box", box, "--lease", lease, "--token", token, "--port", fmt.Sprint(listener.Addr().(*net.TCPAddr).Port), "--report", filepath.Join(run, "identity.json"), "--", os.Args[0], "-test.run=^TestWindowsLiteConsoleProbeChild$")
	cmd.Env = append(os.Environ(), "CAGE_LITE_TERMINAL_CONSOLE_CHILD=1", "CAGE_LITE_TERMINAL_CHILD_REPORT="+filepath.Join(run, "child.json"))
	if err = launchWindowsLiteTerminal(cmd); err != nil {
		t.Fatal(err)
	}
	defer func() { _ = cmd.Process.Kill(); _ = cmd.Wait() }()
	_ = listener.SetDeadline(time.Now().Add(15 * time.Second))
	conn, err := listener.AcceptTCP()
	if err != nil {
		t.Fatal(err)
	}
	defer conn.Close()
	_ = conn.SetDeadline(time.Now().Add(15 * time.Second))
	kind, payload, err := readWindowsLiteTerminalFrame(conn)
	var hello struct {
		LeaseID string `json:"leaseId"`
		Token   string `json:"token"`
		PID     uint32 `json:"pid"`
		BoxName string `json:"boxName"`
	}
	if err != nil || kind != 'H' || json.Unmarshal(payload, &hello) != nil || hello.LeaseID != lease || hello.Token != token || hello.BoxName != box {
		t.Fatalf("invalid helper identity: %v", err)
	}
	job, err := windows.CreateJobObject(nil, nil)
	if err != nil {
		t.Fatal(err)
	}
	defer windows.CloseHandle(job)
	limits := windows.JOBOBJECT_EXTENDED_LIMIT_INFORMATION{}
	limits.BasicLimitInformation.LimitFlags = windows.JOB_OBJECT_LIMIT_KILL_ON_JOB_CLOSE
	if _, err = windows.SetInformationJobObject(job, windows.JobObjectExtendedLimitInformation, uintptr(unsafe.Pointer(&limits)), uint32(unsafe.Sizeof(limits))); err != nil {
		t.Fatal(err)
	}
	process, err := windows.OpenProcess(windows.PROCESS_SET_QUOTA|windows.PROCESS_TERMINATE|windows.PROCESS_QUERY_LIMITED_INFORMATION, false, hello.PID)
	if err != nil {
		t.Fatal(err)
	}
	err = windows.AssignProcessToJobObject(job, process)
	windows.CloseHandle(process)
	if err != nil {
		t.Fatal(err)
	}
	if err = writeWindowsLiteTerminalFrame(conn, 'G', nil); err != nil {
		t.Fatal(err)
	}
	var pending bytes.Buffer
	for {
		kind, payload, err = readWindowsLiteTerminalFrame(conn)
		if err != nil {
			t.Fatal(err)
		}
		if kind == 'B' {
			break
		}
		if kind != 'O' {
			t.Fatalf("helper start failed: %c %q", kind, payload)
		}
		pending.Write(payload)
	}
	_ = conn.SetDeadline(time.Time{})
	var manager terminalManager
	t.Cleanup(manager.close)
	session, err := manager.startSessionWithPTY(cmd, "", "shell", claudeSelection{}, nil, func() (terminalPTY, error) { return newWindowsLiteTerminal(conn, pending.Bytes(), nil, nil), nil })
	if err != nil {
		t.Fatal(err)
	}
	sub := session.subscribe()
	defer sub.Close()
	if err = session.file.Resize(120, 40); err != nil {
		t.Fatal(err)
	}
	if err = session.enqueueInput(context.Background(), "cage-boxed-input\r"); err != nil {
		t.Fatal(err)
	}
	last := readTerminalUntil(t, sub, "size:120x40")
	output := last
	if !strings.Contains(last, "actual-box:"+box) {
		t.Fatalf("wrong child box: %q", last)
	}
	if !strings.Contains(last, "received:cage-boxed-input") {
		t.Fatalf("input lost: %q", last)
	}
	awaitTerminalSignal(t, session.done)
	if err = os.WriteFile(filepath.Join(run, "output.txt"), []byte(output), 0600); err != nil {
		t.Fatal(err)
	}
	report, _ := json.MarshalIndent(map[string]any{"box": box, "helperPID": hello.PID, "sameBox": true, "inputOutput": true, "resize": "120x40", "completed": true, "scope": "synthetic transport probe only; not runtime admission"}, "", "  ")
	if err = os.WriteFile(filepath.Join(run, "report.json"), report, 0600); err != nil {
		t.Fatal(err)
	}
}
