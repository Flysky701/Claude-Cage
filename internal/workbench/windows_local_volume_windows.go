package workbench

import (
	"bytes"
	"context"
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
	"time"

	"github.com/lima-vm/sshocker/pkg/reversesshfs"
	"github.com/sylvinus/agent-vm/internal/host"
	"golang.org/x/sys/windows"
)

type windowsVolumeReceipt struct {
	Identity                                                                            []uint32
	ReadOnlyTrees                                                                       []string
	Path, Mount, Stamp, SharedLock, Epoch, Access, WorkerSID, InstanceID, ControllerSID string
}

type windowsLocalVolume struct {
	receipt windowsVolumeReceipt
	stop    context.CancelFunc
	done    chan struct{}
	users   int // protected by windowsLocalPrototype.volumeMu
}

func (s *Server) windowsVolumeReceipt(ctx context.Context, project string) (windowsVolumeReceipt, error) {
	var out windowsVolumeReceipt
	p := s.windowsLocal
	binding := p.active.Load()
	if binding == nil {
		return out, errors.New("隔离账户尚未绑定。")
	}
	if err := p.checkPaths(); err != nil {
		return out, err
	}
	raw, _ := json.Marshal(map[string]string{"path": project, "instanceId": binding.InstanceID, "workerSid": binding.WorkerSID})
	cmd := exec.CommandContext(ctx, p.helper, "workbench-volume", "--profile", p.profile)
	cmd.Stdin = bytes.NewReader(raw)
	host.HideCommandWindow(cmd)
	data, err := cmd.Output()
	if err != nil {
		var failure *exec.ExitError
		if errors.As(err, &failure) {
			return out, fmt.Errorf("无法打开项目：%s", strings.TrimSpace(string(failure.Stderr)))
		}
		return out, err
	}
	if json.Unmarshal(data, &out) != nil || !strings.EqualFold(out.Path, filepath.Clean(project)) || out.WorkerSID != binding.WorkerSID || out.InstanceID != binding.InstanceID ||
		(out.Access != "ro" && out.Access != "rw") || len(out.Epoch) != 32 || len(out.Identity) != 3 || !filepath.IsAbs(out.Mount) {
		return out, errors.New("项目挂载授权未通过核验。")
	}
	return out, nil
}

func (s *Server) openWindowsLocalVolume(ctx context.Context, project string) (string, func(), error) {
	if project == "" {
		return "", func() {}, nil
	}
	p := s.windowsLocal
	p.volumeMu.Lock()
	defer p.volumeMu.Unlock()
	r, err := s.windowsVolumeReceipt(ctx, project)
	if err != nil {
		return "", nil, err
	}
	key := strings.ToLower(r.Path)
	if p.volumes == nil {
		p.volumes = map[string]*windowsLocalVolume{}
	}
	v := p.volumes[key]
	if v != nil {
		select {
		case <-v.done:
			v = nil
		default:
		}
	}
	if v != nil && v.receipt.Epoch != r.Epoch {
		v.stop()
		<-v.done
		v = nil
	}
	if v == nil {
		v, err = s.startWindowsLocalVolume(ctx, r)
		if err != nil {
			return "", nil, err
		}
		p.volumes[key] = v
	}
	v.users++
	return r.Mount, func() {
		p.volumeMu.Lock()
		defer p.volumeMu.Unlock()
		v.users--
		if v.users == 0 {
			v.stop()
			<-v.done
			if p.volumes[key] == v {
				delete(p.volumes, key)
			}
		}
	}, nil
}

type projectVolumePipes struct {
	io.Reader
	io.WriteCloser
}

func (s *Server) startWindowsLocalVolume(openCtx context.Context, r windowsVolumeReceipt) (*windowsLocalVolume, error) {
	helperDir := filepath.Join(filepath.Dir(s.windowsLocal.helper), "project-volume")
	name, err := os.ReadFile(filepath.Join(helperDir, "current"))
	version, de := hex.DecodeString(string(name))
	if err != nil || de != nil || len(version) != 32 {
		return nil, errors.New("本机项目读写需要安装 WinFsp 和 SSHFS-Win，再重新打开工作台。")
	}
	adapter := filepath.Join(helperDir, string(name), "CageProjectFileSystem.exe")
	programFiles, err := windows.KnownFolderPath(windows.FOLDERID_ProgramFilesX64, 0)
	if err != nil {
		return nil, err
	}
	sshfs := filepath.Join(programFiles, "SSHFS-Win", "bin", "sshfs.exe")
	if _, err = os.Stat(sshfs); err != nil {
		return nil, errors.New("本机项目读写需要安装 SSHFS-Win。")
	}
	// The private backing mount has no worker access, even by guessing its path.
	dir, err := os.MkdirTemp(s.profile, "local-project-")
	if err != nil {
		return nil, err
	}
	private := filepath.Join(dir, "source")
	if len(private) < 4 || private[1] != ':' {
		os.Remove(dir)
		return nil, errors.New("项目文件通道需要本地磁盘。")
	}
	cyg := "/cygdrive/" + strings.ToLower(private[:1]) + filepath.ToSlash(private[2:])
	lifetime, stop := context.WithCancel(s.lifetimeContext())
	volume := &windowsLocalVolume{receipt: r, stop: stop, done: make(chan struct{})}
	ready := make(chan error, 1)
	go func() {
		defer close(volume.done)
		defer stop()
		defer os.Remove(dir)
		sendError := func(err error) {
			select {
			case ready <- err:
			default:
			}
		}
		share, err := reversesshfs.OpenNativeProjectShare(r.Path, r.Access == "ro", r.ReadOnlyTrees)
		if err != nil {
			sendError(err)
			return
		}
		defer share.Close()
		if !share.MatchesWindowsDirectory(r.Identity[0], r.Identity[1], r.Identity[2]) {
			sendError(errors.New("授权后主机项目目录已被替换，请重新选择。"))
			return
		}
		privateFS := exec.CommandContext(lifetime, sshfs, ":/", cyg, "-f", "-o", "slave,uid=-1,gid=-1,cache=no,nodev,nosuid,FileSecurity=D:P(A;;FA;;;"+r.ControllerSID+")")
		host.HideCommandWindow(privateFS)
		input, err := privateFS.StdinPipe()
		if err != nil {
			sendError(err)
			return
		}
		output, err := privateFS.StdoutPipe()
		if err != nil {
			input.Close()
			sendError(err)
			return
		}
		if err = privateFS.Start(); err != nil {
			sendError(err)
			return
		}
		sftpDone := make(chan struct{})
		go func() { _ = share.Serve(projectVolumePipes{output, input}); close(sftpDone); stop() }()
		defer func() { stop(); input.Close(); output.Close(); privateFS.Wait(); <-sftpDone }()
		for {
			if fi, e := os.Stat(private); e == nil && fi.IsDir() {
				break
			}
			select {
			case <-lifetime.Done():
				sendError(errors.New("受限项目文件通道已关闭。"))
				return
			case <-time.After(25 * time.Millisecond):
			}
		}
		publicFS := exec.CommandContext(lifetime, adapter, private, r.Mount, r.WorkerSID, r.Stamp, r.Epoch, r.SharedLock, r.ControllerSID, r.Access)
		host.HideCommandWindow(publicFS)
		var diagnostic bytes.Buffer
		publicFS.Stderr = &boundedWindowsStatusWriter{buffer: &diagnostic, remaining: 4096}
		// Put the controller's private backing mount behind the Low-labelled view.
		// The child's stdin closing also unmounts it after an unexpected controller exit.
		ctl, err := publicFS.StdinPipe()
		if err != nil {
			sendError(err)
			return
		}
		lines, err := publicFS.StdoutPipe()
		if err != nil {
			ctl.Close()
			sendError(err)
			return
		}
		if err = publicFS.Start(); err != nil {
			sendError(err)
			return
		}
		hello := make([]byte, len("ready"))
		if _, err = io.ReadFull(lines, hello); err != nil || string(hello) != "ready" {
			ctl.Close()
			exitErr := publicFS.Wait()
			why := volumeFailureCode.FindString(diagnostic.String())
			if why == "" && exitErr != nil {
				why = exitErr.Error()
			}
			if why == "" {
				why = "无就绪响应"
			}
			sendError(fmt.Errorf("Windows 项目卷启动失败（%s）。", why))
			return
		}
		defer func() { stop(); ctl.Close(); publicFS.Wait() }()
		ready <- nil
		tick := time.NewTicker(200 * time.Millisecond)
		defer tick.Stop()
		for {
			select {
			case <-lifetime.Done():
				return
			case <-tick.C:
				data, err := os.ReadFile(r.Stamp)
				if err != nil || string(data) != r.Epoch {
					return
				}
			}
		}
	}()
	timer := time.NewTimer(15 * time.Second)
	defer timer.Stop()
	select {
	case err = <-ready:
	case <-openCtx.Done():
		err = openCtx.Err()
	case <-timer.C:
		err = errors.New("项目文件通道未能及时挂载。")
	}
	if err != nil {
		stop()
		<-volume.done
		return nil, err
	}
	return volume, nil
}

var volumeFailureCode = regexp.MustCompile(`mount:[A-Za-z]+:0x[[:xdigit:]]{8}`)
