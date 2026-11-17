//go:build windows

package workbench

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"unsafe"

	"golang.org/x/sys/windows"
)

// This is an opt-in local candidate, not the production backend. Projects are
// explicit managed copies. Import/export never grants the package host ACLs.
type windowsAppContainerProject struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Access string `json:"access"`
}

type windowsAppContainerManifest struct {
	Version     int                          `json:"version"`
	ProfileName string                       `json:"profileName"`
	ProfileSID  string                       `json:"profileSID"`
	Projects    []windowsAppContainerProject `json:"projects"`
}

type windowsAppContainerEnvironment struct {
	mu        sync.Mutex
	root      string
	launcher  string
	manifest  windowsAppContainerManifest
	lock      *os.File
	closed    bool
	terminals map[string]*windowsAppContainerTerminal
}

var candidateID = regexp.MustCompile(`^[a-f0-9]{32}$`)
var candidateToolName = regexp.MustCompile(`^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$`)

func appContainerRandomID() (string, error) {
	var b [16]byte
	_, err := rand.Read(b[:])
	return hex.EncodeToString(b[:]), err
}

func appContainerInside(parent, child string) bool {
	rel, err := filepath.Rel(parent, child)
	return err == nil && rel != ".." && !strings.HasPrefix(rel, ".."+string(filepath.Separator)) && !filepath.IsAbs(rel)
}

// Resolve every existing ancestor without following reparse points. Candidate
// environment roots must stay beneath the launcher's dedicated build directory.
func appContainerPlainPath(path string) error {
	full, err := filepath.Abs(path)
	if err != nil {
		return err
	}
	for current := full; ; current = filepath.Dir(current) {
		wide, err := windows.UTF16PtrFromString(current)
		if err != nil {
			return err
		}
		attributes, err := windows.GetFileAttributes(wide)
		if err != nil {
			return err
		}
		if attributes&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 {
			return fmt.Errorf("reparse points are not allowed: %s", current)
		}
		if filepath.Dir(current) == current {
			break
		}
	}
	return nil
}

func appContainerEnvironmentPaths(launcher, root string, existing bool) (string, string, error) {
	launcher, err := filepath.Abs(launcher)
	if err != nil {
		return "", "", err
	}
	root, err = filepath.Abs(root)
	if err != nil {
		return "", "", err
	}
	if strings.EqualFold(root, filepath.Dir(launcher)) || !appContainerInside(filepath.Dir(launcher), root) {
		return "", "", errors.New("environment must be inside the candidate launcher's directory")
	}
	if err := appContainerPlainPath(launcher); err != nil {
		return "", "", err
	}
	check := filepath.Dir(root)
	if existing {
		check = root
	}
	if err := appContainerPlainPath(check); err != nil {
		return "", "", err
	}
	return launcher, root, nil
}

func appContainerProfileSID(name string, requireFolder bool) (string, error) {
	if !strings.HasPrefix(name, "Cage.TerminalCandidate.") || !candidateID.MatchString(strings.TrimPrefix(name, "Cage.TerminalCandidate.")) {
		return "", errors.New("invalid environment profile name")
	}
	wide, err := windows.UTF16PtrFromString(name)
	if err != nil {
		return "", err
	}
	var sid *windows.SID
	code, _, _ := windows.NewLazySystemDLL("userenv.dll").NewProc("DeriveAppContainerSidFromAppContainerName").Call(uintptr(unsafe.Pointer(wide)), uintptr(unsafe.Pointer(&sid)))
	if int32(code) < 0 || sid == nil {
		return "", fmt.Errorf("derive environment SID: HRESULT 0x%08x", uint32(code))
	}
	defer windows.FreeSid(sid)
	value := sid.String()
	if requireFolder {
		sidText, _ := windows.UTF16PtrFromString(value)
		var folder *uint16
		code, _, _ = windows.NewLazySystemDLL("userenv.dll").NewProc("GetAppContainerFolderPath").Call(uintptr(unsafe.Pointer(sidText)), uintptr(unsafe.Pointer(&folder)))
		if int32(code) < 0 || folder == nil {
			return "", fmt.Errorf("open environment profile: HRESULT 0x%08x", uint32(code))
		}
		folderPath := windows.UTF16PtrToString(folder)
		windows.NewLazySystemDLL("ole32.dll").NewProc("CoTaskMemFree").Call(uintptr(unsafe.Pointer(folder)))
		info, err := os.Stat(folderPath)
		if err != nil {
			return "", err
		}
		if !info.IsDir() {
			return "", errors.New("environment profile folder missing")
		}
	}
	return value, nil
}

func lockAppContainerEnvironment(root string) (*os.File, error) {
	path := filepath.Join(root, "private", "environment.lock")
	if err := appContainerPlainPath(filepath.Dir(path)); err != nil {
		return nil, err
	}
	if _, err := os.Lstat(path); err == nil {
		if err := appContainerPlainPath(path); err != nil {
			return nil, err
		}
	} else if !errors.Is(err, os.ErrNotExist) {
		return nil, err
	}
	wide, _ := windows.UTF16PtrFromString(path)
	h, err := windows.CreateFile(wide, windows.GENERIC_READ|windows.GENERIC_WRITE, 0, nil, windows.OPEN_ALWAYS, windows.FILE_ATTRIBUTE_NORMAL|windows.FILE_FLAG_OPEN_REPARSE_POINT, 0)
	if err != nil {
		return nil, fmt.Errorf("lock environment (another controller may be open): %w", err)
	}
	return os.NewFile(uintptr(h), path), nil
}

// Creation requires a fresh directory. Opening never reruns initialization or
// silently recreates a missing identity; both would conceal lost persistence.
func createWindowsAppContainerEnvironment(ctx context.Context, launcher, root string) (*windowsAppContainerEnvironment, error) {
	launcher, root, err := appContainerEnvironmentPaths(launcher, root, false)
	if err != nil {
		return nil, err
	}
	if err := os.Mkdir(root, 0700); err != nil {
		return nil, err
	}
	profile, err := createTerminalAppContainer()
	if err != nil {
		return nil, err
	}
	ok := false
	defer func() {
		if !ok {
			_ = deleteTerminalAppContainer(profile)
		}
	}()
	output, err := exec.CommandContext(ctx, launcher, "environment-init", root, profile).CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("initialize candidate environment: %w: %s", err, output)
	}
	sid, err := appContainerProfileSID(profile, true)
	if err != nil {
		return nil, err
	}
	lock, err := lockAppContainerEnvironment(root)
	if err != nil {
		return nil, err
	}
	e := &windowsAppContainerEnvironment{root: root, launcher: launcher, lock: lock, terminals: make(map[string]*windowsAppContainerTerminal), manifest: windowsAppContainerManifest{Version: 1, ProfileName: profile, ProfileSID: sid}}
	if err := os.Mkdir(filepath.Join(root, "projects"), 0700); err != nil && !errors.Is(err, os.ErrExist) {
		_ = lock.Close()
		return nil, err
	}
	if err := e.save(); err != nil {
		_ = lock.Close()
		return nil, err
	}
	ok = true
	return e, nil
}

func openWindowsAppContainerEnvironment(launcher, root string) (*windowsAppContainerEnvironment, error) {
	launcher, root, err := appContainerEnvironmentPaths(launcher, root, true)
	if err != nil {
		return nil, err
	}
	lock, err := lockAppContainerEnvironment(root)
	if err != nil {
		return nil, err
	}
	ok := false
	defer func() {
		if !ok {
			_ = lock.Close()
		}
	}()
	path := filepath.Join(root, "private", "environment.json")
	if err := appContainerPlainPath(path); err != nil {
		return nil, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return nil, err
	}
	e := &windowsAppContainerEnvironment{root: root, launcher: launcher, lock: lock, terminals: make(map[string]*windowsAppContainerTerminal)}
	if err := json.Unmarshal(data, &e.manifest); err != nil {
		return nil, err
	}
	if e.manifest.Version != 1 {
		return nil, errors.New("unsupported environment version")
	}
	sid, err := appContainerProfileSID(e.manifest.ProfileName, true)
	if err != nil {
		return nil, err
	}
	if e.manifest.ProfileSID != sid {
		return nil, errors.New("environment identity changed")
	}
	seen := make(map[string]bool)
	for _, p := range e.manifest.Projects {
		if !candidateID.MatchString(p.ID) || seen[p.ID] || (p.Access != "read-only" && p.Access != "read-write") {
			return nil, errors.New("invalid environment project manifest")
		}
		seen[p.ID] = true
		if err := appContainerPlainPath(filepath.Join(root, "projects", p.ID)); err != nil {
			return nil, err
		}
	}
	ok = true
	return e, nil
}

func (e *windowsAppContainerEnvironment) save() error {
	data, err := json.MarshalIndent(e.manifest, "", "  ")
	if err != nil {
		return err
	}
	path := filepath.Join(e.root, "private", "environment.json")
	temp := path + ".new"
	file, err := os.OpenFile(temp, os.O_WRONLY|os.O_CREATE|os.O_EXCL, 0600)
	if err != nil {
		return err
	}
	_, err = file.Write(append(data, '\n'))
	err = errors.Join(err, file.Close())
	if err != nil {
		return err
	}
	return os.Rename(temp, path)
}

func (e *windowsAppContainerEnvironment) idle() error {
	if e.closed {
		return errors.New("environment controller is closed")
	}
	for id, terminal := range e.terminals {
		select {
		case <-terminal.cleaned:
			delete(e.terminals, id)
		default:
			return errors.New("close environment terminals before importing or exporting")
		}
	}
	return nil
}

func (e *windowsAppContainerEnvironment) Projects() []windowsAppContainerProject {
	e.mu.Lock()
	defer e.mu.Unlock()
	return append([]windowsAppContainerProject(nil), e.manifest.Projects...)
}

func (e *windowsAppContainerEnvironment) StartTerminal(ctx context.Context, exe, shell, projectID string, args ...string) (*windowsAppContainerTerminal, error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.closed {
		return nil, errors.New("environment controller is closed")
	}
	cwd := filepath.Join(e.root, "work")
	if projectID != "" {
		found := false
		for _, p := range e.manifest.Projects {
			if p.ID == projectID {
				found = true
				cwd = filepath.Join(e.root, "projects", p.ID)
				break
			}
		}
		if !found {
			return nil, errors.New("unknown managed project")
		}
	}
	if err := appContainerPlainPath(cwd); err != nil {
		return nil, err
	}
	id, err := appContainerRandomID()
	if err != nil {
		return nil, err
	}
	command := []string{"terminal-rpc-persistent", "ac", e.root, exe, e.manifest.ProfileName, id, cwd}
	cmd := exec.CommandContext(ctx, e.launcher, append(command, args...)...)
	terminal, err := startOwnedWindowsAppContainerTerminal(cmd, map[string]any{"action": "open", "workspace": "home", "shell": shell, "cols": 80, "rows": 25}, e.manifest.ProfileName, false)
	if err != nil {
		return nil, err
	}
	e.terminals[id] = terminal
	return terminal, nil
}

func (e *windowsAppContainerEnvironment) Close() error {
	e.mu.Lock()
	if e.closed {
		e.mu.Unlock()
		return nil
	}
	e.closed = true
	terminals := e.terminals
	e.mu.Unlock()
	var result error
	for _, terminal := range terminals {
		result = errors.Join(result, terminal.Close())
	}
	return errors.Join(result, e.lock.Close())
}

// Projects receive only data access: unlike the private work directory, even
// writable projects do not grant ChangePermissions. Their host-only parent
// prevents a package from replacing or changing another project's access mode.
func appContainerProjectACL(path, sid string, writable bool) error {
	user, err := windows.GetCurrentProcessToken().GetTokenUser()
	if err != nil {
		return err
	}
	rights := "0x1200a9" // Read + Execute + Synchronize.
	if writable {
		rights = "0x1301bf"
	} // Modify + Synchronize, without WRITE_DAC.
	sd, err := windows.SecurityDescriptorFromString("D:P(A;OICI;FA;;;" + user.User.Sid.String() + ")(A;OICI;FA;;;SY)(A;OICI;" + rights + ";;;" + sid + ")")
	if err != nil {
		return err
	}
	acl, _, err := sd.DACL()
	if err != nil {
		return err
	}
	if err := windows.SetNamedSecurityInfo(path, windows.SE_FILE_OBJECT, windows.DACL_SECURITY_INFORMATION|windows.PROTECTED_DACL_SECURITY_INFORMATION, nil, nil, acl, nil); err != nil {
		return err
	}
	if writable {
		label, err := windows.SecurityDescriptorFromString("S:(ML;OICI;NW;;;LW)")
		if err != nil {
			return err
		}
		sacl, _, err := label.SACL()
		if err != nil {
			return err
		}
		return windows.SetNamedSecurityInfo(path, windows.SE_FILE_OBJECT, windows.LABEL_SECURITY_INFORMATION, nil, nil, nil, sacl)
	}
	return nil
}

func (e *windowsAppContainerEnvironment) ImportProject(source, name, access string) (windowsAppContainerProject, error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	var project windowsAppContainerProject
	if err := e.idle(); err != nil {
		return project, err
	}
	if access != "read-only" && access != "read-write" {
		return project, errors.New("project access must be read-only or read-write")
	}
	id, err := appContainerRandomID()
	if err != nil {
		return project, err
	}
	destination := filepath.Join(e.root, "projects", id)
	if err := appContainerCopyTree(source, destination, func(path string) error {
		return appContainerProjectACL(path, e.manifest.ProfileSID, access == "read-write")
	}); err != nil {
		return project, err
	}
	project = windowsAppContainerProject{ID: id, Name: name, Access: access}
	e.manifest.Projects = append(e.manifest.Projects, project)
	if err := e.save(); err != nil {
		e.manifest.Projects = e.manifest.Projects[:len(e.manifest.Projects)-1]
		return windowsAppContainerProject{}, err
	}
	return project, nil
}

// Tools are copied once into the persistent read-only tools tree, never granted
// access in place in the host installation. Returns the imported directory.
func (e *windowsAppContainerEnvironment) ImportTools(source, name string) (string, error) {
	e.mu.Lock()
	defer e.mu.Unlock()
	if err := e.idle(); err != nil {
		return "", err
	}
	if !candidateToolName.MatchString(name) {
		return "", errors.New("invalid tool directory name")
	}
	destination := filepath.Join(e.root, "tools", name)
	err := appContainerCopyTree(source, destination, func(path string) error { return appContainerProjectACL(path, e.manifest.ProfileSID, false) })
	return destination, err
}

func (e *windowsAppContainerEnvironment) ExportProject(id, destination string) error {
	e.mu.Lock()
	defer e.mu.Unlock()
	if err := e.idle(); err != nil {
		return err
	}
	full, err := filepath.Abs(destination)
	if err != nil {
		return err
	}
	if appContainerInside(e.root, full) {
		return errors.New("export destination must be outside the environment")
	}
	for _, p := range e.manifest.Projects {
		if p.ID == id {
			return appContainerCopyTree(filepath.Join(e.root, "projects", id), full, nil)
		}
	}
	return errors.New("unknown managed project")
}

// Pin each source directory/file without write/delete sharing while reading.
// Reject reparse points and hard links; copy regular unnamed file contents only.
// Destinations must be fresh. A failed partial copy is retained for inspection,
// never recursively removed by this candidate controller.
func appContainerCopyTree(source, destination string, initialize func(string) error) error {
	source, err := filepath.Abs(source)
	if err != nil {
		return err
	}
	destination, err = filepath.Abs(destination)
	if err != nil {
		return err
	}
	if appContainerInside(source, destination) || appContainerInside(destination, source) {
		return errors.New("copy source and destination overlap")
	}
	if err := appContainerPlainPath(source); err != nil {
		return err
	}
	if err := appContainerPlainPath(filepath.Dir(destination)); err != nil {
		return err
	}
	// Hold the existing destination parent during creation, so a junction or
	// rename cannot redirect this fresh copy between validation and writing.
	parent, err := appContainerOpenPinned(filepath.Dir(destination))
	if err != nil {
		return err
	}
	defer parent.Close()
	return appContainerCopyEntry(source, destination, true, initialize)
}

func appContainerOpenPinned(path string) (*os.File, error) {
	wide, err := windows.UTF16PtrFromString(path)
	if err != nil {
		return nil, err
	}
	h, err := windows.CreateFile(wide, windows.GENERIC_READ, windows.FILE_SHARE_READ, nil, windows.OPEN_EXISTING, windows.FILE_FLAG_BACKUP_SEMANTICS|windows.FILE_FLAG_OPEN_REPARSE_POINT, 0)
	if err != nil {
		return nil, err
	}
	file := os.NewFile(uintptr(h), path)
	var name [32768]uint16
	n, err := windows.GetFinalPathNameByHandle(h, &name[0], uint32(len(name)), 0)
	if err != nil || n >= uint32(len(name)) {
		_ = file.Close()
		return nil, fmt.Errorf("resolve copy handle: %w", err)
	}
	resolved := windows.UTF16ToString(name[:n])
	if strings.HasPrefix(resolved, `\\?\UNC\`) {
		resolved = `\\` + strings.TrimPrefix(resolved, `\\?\UNC\`)
	} else {
		resolved = strings.TrimPrefix(resolved, `\\?\`)
	}
	if !strings.EqualFold(filepath.Clean(resolved), filepath.Clean(path)) {
		_ = file.Close()
		return nil, errors.New("copy path resolved outside its validated location")
	}
	var info windows.ByHandleFileInformation
	if err := windows.GetFileInformationByHandle(h, &info); err != nil {
		_ = file.Close()
		return nil, err
	}
	if info.FileAttributes&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 {
		_ = file.Close()
		return nil, errors.New("copy rejects reparse points")
	}
	return file, nil
}

func appContainerCopyEntry(source, destination string, root bool, initialize func(string) error) error {
	file, err := appContainerOpenPinned(source)
	if err != nil {
		return err
	}
	defer file.Close()
	h := windows.Handle(file.Fd())
	var info windows.ByHandleFileInformation
	if err := windows.GetFileInformationByHandle(h, &info); err != nil {
		return err
	}
	if info.FileAttributes&windows.FILE_ATTRIBUTE_REPARSE_POINT != 0 {
		return errors.New("copy rejects reparse points")
	}
	directory := info.FileAttributes&windows.FILE_ATTRIBUTE_DIRECTORY != 0
	if root && !directory {
		return errors.New("copy source must be a directory")
	}
	if !directory {
		if info.NumberOfLinks != 1 {
			return errors.New("copy rejects hard-linked files")
		}
		out, err := os.OpenFile(destination, os.O_CREATE|os.O_EXCL|os.O_WRONLY, 0600)
		if err != nil {
			return err
		}
		_, err = io.Copy(out, file)
		return errors.Join(err, out.Close())
	}
	if err := os.Mkdir(destination, 0700); err != nil {
		return err
	}
	if root && initialize != nil {
		if err := initialize(destination); err != nil {
			return err
		}
	}
	entries, err := os.ReadDir(source)
	if err != nil {
		return err
	}
	for _, entry := range entries {
		if err := appContainerCopyEntry(filepath.Join(source, entry.Name()), filepath.Join(destination, entry.Name()), false, nil); err != nil {
			return err
		}
	}
	return nil
}
