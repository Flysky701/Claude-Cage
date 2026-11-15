package windowslite

import (
	"bufio"
	"context"
	"encoding/json"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sync"
	"time"
)

type pythonWorker struct {
	mu     sync.Mutex
	cmd    *exec.Cmd
	stdin  io.WriteCloser
	out    *bufio.Scanner
	closed bool
	broken bool
	done   chan error
}

// Worker is the serial, process-owned JSON-line space controller. It can be
// embedded in the regular Cage workbench without starting another HTTP server.
type Worker interface {
	Call(context.Context, json.RawMessage) (json.RawMessage, error)
	Close() error
}

func StartWorker(profile string) (Worker, error) { return newWorker(profile) }

func newWorker(profile string) (*pythonWorker, error) {
	exe, err := os.Executable()
	if err != nil {
		return nil, err
	}
	resources := filepath.Dir(exe)
	script := filepath.Join(resources, "windows-lite", "space.py")
	if _, err := os.Stat(script); err != nil {
		return nil, errors.New("测试包缺少空间管理组件")
	}
	python := filepath.Join(resources, "python", "python.exe")
	if _, err := os.Stat(python); err != nil {
		var runtime struct {
			Python string `json:"python"`
		}
		b, e := os.ReadFile(filepath.Join(resources, "windows-lite-runtime.json"))
		if e == nil && json.Unmarshal(b, &runtime) == nil && filepath.IsAbs(runtime.Python) {
			python = runtime.Python
		} else {
			python, err = exec.LookPath("python.exe")
			if err != nil {
				return nil, errors.New("未找到 64 位 Python，请重新生成包含运行组件的测试包")
			}
		}
	}
	cmd := exec.Command(python, "-B", "-u", script, "--profile", profile)
	cmd.Dir = filepath.Dir(script)
	cmd.Env = append(os.Environ(), "PYTHONUTF8=1", "PYTHONIOENCODING=utf-8")
	hideProcess(cmd, false)
	input, err := cmd.StdinPipe()
	if err != nil {
		return nil, err
	}
	output, err := cmd.StdoutPipe()
	if err != nil {
		input.Close()
		return nil, err
	}
	cmd.Stderr = io.Discard
	if err := cmd.Start(); err != nil {
		input.Close()
		return nil, err
	}
	w := &pythonWorker{cmd: cmd, stdin: input, out: bufio.NewScanner(output), done: make(chan error, 1)}
	w.out.Buffer(make([]byte, 4096), 1<<20)
	go func() { w.done <- cmd.Wait() }()
	ctx, cancel := context.WithTimeout(context.Background(), 12*time.Second)
	defer cancel()
	if _, err := w.Call(ctx, json.RawMessage(`{"action":"status"}`)); err != nil {
		w.Close()
		return nil, errors.New("空间管理组件未能启动，请检查 Python 运行环境")
	}
	return w, nil
}

func (w *pythonWorker) Call(ctx context.Context, input json.RawMessage) (json.RawMessage, error) {
	w.mu.Lock()
	defer w.mu.Unlock()
	if w.closed || w.broken {
		return nil, errors.New("worker unavailable")
	}
	if err := ctx.Err(); err != nil {
		return nil, err
	}
	if !json.Valid(input) {
		return nil, errors.New("invalid request")
	}
	if _, err := w.stdin.Write(append(append([]byte{}, input...), '\n')); err != nil {
		w.broken = true
		return nil, err
	}
	type received struct {
		data json.RawMessage
		err  error
	}
	ch := make(chan received, 1)
	go func() {
		if !w.out.Scan() {
			ch <- received{err: errors.New("worker stopped")}
			return
		}
		b := append(json.RawMessage{}, w.out.Bytes()...)
		if !json.Valid(b) {
			ch <- received{err: errors.New("invalid worker response")}
			return
		}
		ch <- received{data: b}
	}()
	select {
	case response := <-ch:
		if response.err != nil {
			w.broken = true
		}
		return response.data, response.err
	case <-ctx.Done():
		w.broken = true
		_ = w.stdin.Close()
		_ = w.cmd.Process.Kill()
		<-ch
		return nil, ctx.Err()
	}
}

func (w *pythonWorker) Close() error {
	w.mu.Lock()
	if w.closed {
		w.mu.Unlock()
		return nil
	}
	w.closed = true
	_ = w.stdin.Close()
	w.mu.Unlock()
	select {
	case err := <-w.done:
		return err
	case <-time.After(8 * time.Second):
		_ = w.cmd.Process.Kill()
		<-w.done
		return errors.New("space worker did not stop in time")
	}
}
