package workbench

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"slices"
	"sort"
	"strings"
	"time"
	"unicode/utf8"
)

// This file associates existing grants for one workbench. Only the helper's
// verified SID-specific ACL receipt can make a folder accessible.
type windowsLocalProjectRecord struct {
	Workspace string         `json:"workspace"`
	Groups    []projectGroup `json:"project_groups"`
}

type windowsLocalProjectView struct {
	record windowsLocalProjectRecord
	paths  []string
	groups []projectGroup
	active string
	access map[string]string
}

func (s *Server) localProjectRecordPath() string {
	return filepath.Join(s.profile, "windows-local-project-groups.json")
}

func (s *Server) readLocalProjectView(ctx context.Context, fresh bool) (*windowsLocalProjectView, error) {
	p := s.windowsLocal // caller holds projectMu
	if !fresh && p.projectView != nil && time.Now().Before(p.projectViewUntil) {
		return p.projectView, nil
	}
	var record windowsLocalProjectRecord
	data, err := os.ReadFile(s.localProjectRecordPath())
	if err == nil {
		err = json.Unmarshal(data, &record)
	}
	if err != nil && !errors.Is(err, os.ErrNotExist) {
		return nil, fmt.Errorf("无法读取本工作台的项目分组：%w", err)
	}
	result, err := p.projectRequest(ctx, windowsLocalProjectRequest{})
	if err != nil {
		return nil, err
	}
	view := localProjectView(record, result.Projects)
	p.projectView, p.projectViewUntil = view, time.Now().Add(5*time.Second)
	return view, nil
}

// Keep stable display paths from the Windows grant receipt even if the user
// reopens the folder using another letter case. Removed ACLs never reappear
// from the saved group file or the previous selection.
func localProjectView(record windowsLocalProjectRecord, grants []windowsLocalProjectGrant) *windowsLocalProjectView {
	view := &windowsLocalProjectView{record: record, paths: []string{}, access: map[string]string{}}
	canonical := map[string]string{}
	for _, grant := range grants {
		view.access[grant.Path] = grant.Access
		if grant.Access != "ro" && grant.Access != "rw" {
			continue
		}
		key := strings.ToLower(grant.Path)
		if _, ok := canonical[key]; !ok {
			view.paths = append(view.paths, grant.Path)
		}
		canonical[key] = grant.Path
	}
	sort.Slice(view.paths, func(i, j int) bool { return strings.ToLower(view.paths[i]) < strings.ToLower(view.paths[j]) })
	groups := make([]projectGroup, 0, len(record.Groups))
	for _, item := range record.Groups {
		group := projectGroup{Workspace: canonical[strings.ToLower(item.Workspace)], Name: item.Name}
		if group.Workspace == "" {
			continue
		}
		for _, folder := range item.Folders {
			if path := canonical[strings.ToLower(folder)]; path != "" {
				group.Folders = append(group.Folders, path)
			}
		}
		groups = append(groups, group)
	}
	view.groups = groupsFromPaths(view.paths, groups)
	if group := view.group(record.Workspace); group != nil {
		view.active = group.Workspace
	} else if len(view.groups) > 0 {
		view.active = view.groups[0].Workspace
	}
	return view
}

func (v *windowsLocalProjectView) group(path string) *projectGroup {
	for i := range v.groups {
		if slices.ContainsFunc(v.groups[i].Folders, func(p string) bool { return strings.EqualFold(path, p) }) {
			return &v.groups[i]
		}
	}
	return nil
}

func (s *Server) windowsLocalProjectStatus(ctx context.Context, status map[string]any) {
	p := s.windowsLocal
	if p.active.Load() == nil {
		return
	}
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	view, err := s.readLocalProjectView(ctx, false)
	if err != nil {
		status["project_list_error"] = err.Error()
		return
	}
	status["workspace"], status["projects"], status["project_groups"], status["project_access"] = view.active, view.paths, view.groups, view.access
}

func (s *Server) windowsLocalCurrentProject(ctx context.Context) string {
	p := s.windowsLocal
	if p.active.Load() == nil {
		return ""
	}
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	if view, err := s.readLocalProjectView(ctx, false); err == nil {
		return view.active
	}
	return ""
}

func (s *Server) windowsLocalProjectFolders(ctx context.Context, workspace string) ([]string, error) {
	p := s.windowsLocal
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	view, err := s.readLocalProjectView(ctx, true)
	if err != nil {
		return nil, err
	}
	if group := view.group(filepath.Clean(workspace)); group != nil {
		return slices.Clone(group.Folders), nil
	}
	return nil, errors.New("请先在项目选择器中授权该目录。")
}

func (s *Server) windowsLocalFoldersBusy(folders []string) bool {
	p := s.windowsLocal
	p.tabsMu.Lock()
	defer p.tabsMu.Unlock()
	if p.tabs != nil {
		for _, tab := range p.tabs.tabs {
			for _, open := range tab.folders {
				if slices.ContainsFunc(folders, func(path string) bool { return windowsLocalPathsOverlap(path, open) }) {
					return true
				}
			}
		}
	}
	return false
}

func (s *Server) windowsLocalOpenProject(w http.ResponseWriter, r *http.Request) {
	var in struct {
		Workspace     string
		Add, Activate bool
	}
	if !readJSON(w, r, &in) {
		return
	}
	path, err := s.localProjectPath(in.Workspace)
	if err != nil {
		requestError(w, err)
		return
	}
	p := s.windowsLocal
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	view, err := s.readLocalProjectView(r.Context(), true)
	if err != nil {
		requestError(w, err)
		return
	}
	group := view.group(path)
	if group == nil && !in.Add {
		requestError(w, errors.New("请先通过项目选择器添加这个文件夹。"))
		return
	}
	var changes []windowsLocalGrantChange
	if group != nil {
		path = group.Workspace
	} else {
		changes = []windowsLocalGrantChange{{Path: path, Before: view.grant(path), After: "ro"}}
	}
	record := view.record
	if in.Activate {
		record.Workspace = path
	}
	if in.Activate || len(changes) > 0 {
		if err := s.commitLocalProjectRecord(r.Context(), record, changes); err != nil {
			requestError(w, err)
			return
		}
	}
	jsonReply(w, map[string]string{"workspace": path})
}

func (v *windowsLocalProjectView) grant(path string) string {
	for folder, access := range v.access {
		if strings.EqualFold(path, folder) {
			return access
		}
	}
	return ""
}

func (s *Server) windowsLocalSaveProject(w http.ResponseWriter, r *http.Request) {
	var in struct {
		projectGroup
		Access map[string]string `json:"folder_access"`
	}
	if !readJSON(w, r, &in) {
		return
	}
	in.Name = strings.TrimSpace(in.Name)
	if in.Name == "" || utf8.RuneCountInString(in.Name) > 100 || strings.ContainsAny(in.Name, "\x00\r\n") || len(in.Folders) == 0 || len(in.Folders) > 32 {
		requestError(w, errors.New("请填写项目名称，并添加 1–32 个文件夹。"))
		return
	}
	p := s.windowsLocal
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	view, err := s.readLocalProjectView(r.Context(), true)
	if err != nil {
		requestError(w, err)
		return
	}
	group := projectGroup{Name: in.Name}
	members := map[string]bool{}
	for _, folder := range in.Folders {
		path, err := s.localProjectPath(folder)
		if err != nil {
			requestError(w, err)
			return
		}
		for existing := range view.access {
			if strings.EqualFold(path, existing) {
				path = existing
				break
			}
		}
		key := strings.ToLower(path)
		if !members[key] {
			members[key] = true
			group.Folders = append(group.Folders, path)
		}
	}
	rights := map[string]string{}
	for folder, access := range in.Access {
		key := strings.ToLower(filepath.Clean(folder))
		if !members[key] || rights[key] != "" || (access != "ro" && access != "rw") {
			requestError(w, errors.New("请逐个选择项目文件夹的只读或读写权限。"))
			return
		}
		rights[key] = access
	}
	group.Workspace = group.Folders[0]
	if in.Workspace != "" {
		existing := view.group(filepath.Clean(in.Workspace))
		if existing == nil || !strings.EqualFold(existing.Workspace, filepath.Clean(in.Workspace)) || !members[strings.ToLower(existing.Workspace)] {
			requestError(w, errors.New("请保留原来的主目录，以继续使用项目会话。"))
			return
		}
		group.Workspace = existing.Workspace
		group.Folders = append([]string{group.Workspace}, slices.DeleteFunc(group.Folders, func(f string) bool { return strings.EqualFold(f, group.Workspace) })...)
	}
	record := view.record
	record.Groups = slices.Clone(record.Groups)
	for _, other := range record.Groups {
		if strings.EqualFold(other.Workspace, group.Workspace) && in.Workspace != "" {
			continue
		}
		for _, folder := range other.Folders {
			if members[strings.ToLower(folder)] {
				requestError(w, fmt.Errorf("文件夹已属于项目“%s”，请先编辑该项目。", other.Name))
				return
			}
		}
	}
	changes := []windowsLocalGrantChange{}
	var changedExisting []string
	for _, folder := range group.Folders {
		before, after := view.grant(folder), rights[strings.ToLower(folder)]
		if after == "" {
			after = before
			if after == "" {
				after = "ro"
			}
		}
		if before == "unconfirmed" {
			requestError(w, fmt.Errorf("目录 %s 的现有授权无法核验，请先在项目权限中修复。", folder))
			return
		}
		if before != after {
			changes = append(changes, windowsLocalGrantChange{folder, before, after})
			if before != "" {
				changedExisting = append(changedExisting, folder)
			}
		}
	}
	if previous := view.group(group.Workspace); previous != nil {
		for _, folder := range previous.Folders {
			if !members[strings.ToLower(folder)] {
				changes = append(changes, windowsLocalGrantChange{folder, view.grant(folder), ""})
				changedExisting = append(changedExisting, folder)
			}
		}
		// A live Claude session can use any additional directory in its group.
		if len(changedExisting) > 0 {
			changedExisting = append(changedExisting, previous.Folders...)
		}
	}
	if s.windowsLocalFoldersBusy(changedExisting) {
		http.Error(w, "请先保存并关闭使用这些文件夹的终端和编辑器，再修改授权。", http.StatusConflict)
		return
	}
	index := slices.IndexFunc(record.Groups, func(item projectGroup) bool { return strings.EqualFold(item.Workspace, group.Workspace) })
	if index < 0 {
		record.Groups = append(record.Groups, group)
	} else {
		record.Groups[index] = group
	}
	if record.Workspace != "" && members[strings.ToLower(record.Workspace)] {
		record.Workspace = group.Workspace
	}
	if err := s.commitLocalProjectRecord(r.Context(), record, changes); err != nil {
		requestError(w, err)
		return
	}
	jsonReply(w, group)
}

func (s *Server) windowsLocalRemoveProject(w http.ResponseWriter, r *http.Request) {
	var in struct{ Workspace string }
	if !readJSON(w, r, &in) {
		return
	}
	p := s.windowsLocal
	p.projectMu.Lock()
	defer p.projectMu.Unlock()
	view, err := s.readLocalProjectView(r.Context(), true)
	if err != nil {
		requestError(w, err)
		return
	}
	group := view.group(filepath.Clean(in.Workspace))
	if group == nil {
		jsonReply(w, map[string]string{"workspace": view.active})
		return
	}
	if !strings.EqualFold(group.Workspace, filepath.Clean(in.Workspace)) {
		requestError(w, errors.New("移除项目时请选择主目录。"))
		return
	}
	if s.windowsLocalFoldersBusy(group.Folders) {
		http.Error(w, "请先关闭这个项目的终端和编辑器。", http.StatusConflict)
		return
	}
	record := view.record
	record.Groups = slices.DeleteFunc(slices.Clone(record.Groups), func(g projectGroup) bool { return strings.EqualFold(g.Workspace, group.Workspace) })
	if strings.EqualFold(view.active, group.Workspace) {
		record.Workspace = ""
		for _, other := range view.groups {
			if other.Workspace != group.Workspace {
				record.Workspace = other.Workspace
				break
			}
		}
	} else {
		record.Workspace = view.active
	}
	var changes []windowsLocalGrantChange
	for _, folder := range group.Folders {
		changes = append(changes, windowsLocalGrantChange{folder, view.grant(folder), ""})
	}
	if err := s.commitLocalProjectRecord(r.Context(), record, changes); err != nil {
		requestError(w, err)
		return
	}
	jsonReply(w, map[string]string{"workspace": record.Workspace})
}

func (s *Server) commitLocalProjectRecord(ctx context.Context, record windowsLocalProjectRecord, changes []windowsLocalGrantChange) error {
	p := s.windowsLocal
	p.projectView = nil
	if len(changes) > 0 {
		if _, err := p.projectRequest(ctx, windowsLocalProjectRequest{Changes: changes}); err != nil {
			return err
		}
	}
	err := writePrivate(s.localProjectRecordPath(), record)
	if err != nil && len(changes) > 0 {
		revert := slices.Clone(changes)
		for i := range revert {
			revert[i].Before, revert[i].After = revert[i].After, revert[i].Before
		}
		if _, restore := p.projectRequest(context.WithoutCancel(ctx), windowsLocalProjectRequest{Changes: revert}); restore != nil {
			return errors.Join(err, fmt.Errorf("恢复项目授权失败，请检查项目权限：%w", restore))
		}
	}
	return err
}
