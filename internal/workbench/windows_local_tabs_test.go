package workbench

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestWindowsLocalPTYQueuesRapidKeysInOrder(t *testing.T) {
	ctx := context.Background()
	hub := &windowsLocalHub{ctx: ctx, writes: make(chan windowsLocalEnvelope, 1)}
	p := &windowsLocalPTY{ctx: ctx, tab: &windowsLocalTab{id: "pty"}, hub: hub}
	session := newTerminalSession(p)
	// A stalled native writer must accept an ordinary line typed one key
	// per frame, including Ctrl+C, the next command, and its Enter.
	want := strings.Repeat("ab", 180) + "\x03" + "Write-Output '中文'\r"
	for _, key := range want {
		if err := session.enqueueInput(ctx, string(key)); err != nil {
			t.Fatal(err)
		}
	}
	stopped := make(chan struct{})
	go func() { defer close(stopped); session.writeInput() }()
	defer func() { close(session.stopping); <-stopped }()
	select {
	case msg := <-hub.writes:
		var input struct {
			Type string
			Text []byte
		}
		if err := json.Unmarshal(msg.Event, &input); err != nil || input.Type != "input" || string(input.Text) != want {
			t.Fatalf("native input lost or reordered keys: %q, %v", input.Text, err)
		}
	case <-time.After(2 * time.Second):
		t.Fatal("native writer did not flush queued keys")
	}
}

// Exercise two real workbench sockets against an offline helper transport.
func TestWindowsLocalTabsRouteIndependentShells(t *testing.T) {
	epoch, lock := context.WithCancel(context.Background())
	defer lock()
	life, stop := context.WithCancel(epoch)
	h := &windowsLocalHub{ctx: life, stop: stop, epoch: epoch, binding: windowsLocalBinding{InstanceID: "instance", WorkerSID: "sid"},
		writes: make(chan windowsLocalEnvelope, 8), ready: make(chan struct{}), done: make(chan struct{}), tabs: make(map[string]*windowsLocalTab)}
	p := &windowsLocalPrototype{tabs: h}
	s := &Server{windowsLocal: p}
	lines := make(chan string, 8)
	helperRead, helperWrite := io.Pipe()
	go func() {
		defer helperWrite.Close()
		for {
			select {
			case <-life.Done():
				return
			case line := <-lines:
				if _, err := fmt.Fprintln(helperWrite, line); err != nil {
					return
				}
			}
		}
	}()
	go func() {
		defer close(h.done)
		h.err = h.read(p, helperRead)
		helperRead.Close()
	}()
	lines <- `{"type":"ready","workerSid":"sid","instanceId":"instance"}`
	var upgrade websocket.Upgrader
	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		ws, err := upgrade.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		defer ws.Close()
		ctx := context.WithValue(r.Context(), windowsLocalEpochKey{}, epoch)
		_ = s.runWindowsLocalTab(ctx, ws, "terminal", "")
	}))
	defer server.Close()
	defer stop()
	next := func() windowsLocalEnvelope {
		t.Helper()
		select {
		case m := <-h.writes:
			return m
		case <-time.After(3 * time.Second):
			t.Fatal("helper request timed out")
		}
		return windowsLocalEnvelope{}
	}
	expect := func(ws *websocket.Conn, kind string) {
		t.Helper()
		ws.SetReadDeadline(time.Now().Add(3 * time.Second))
		var got struct{ Type, Text string }
		if err := ws.ReadJSON(&got); err != nil || got.Type != kind || (kind == "output" && got.Text != "second") {
			t.Fatalf("expected %s, received %+v: %v", kind, got, err)
		}
	}
	open := func() (*websocket.Conn, string) {
		t.Helper()
		ws, _, err := websocket.DefaultDialer.Dial("ws"+strings.TrimPrefix(server.URL, "http"), nil)
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { ws.Close() })
		m := next()
		if m.Type != "open" || m.App != "terminal" {
			t.Fatalf("unexpected open %+v", m)
		}
		lines <- fmt.Sprintf(`{"id":%q,"event":{"type":"ready","workerUsername":"worker","workerSid":"sid","instanceId":"instance","integrityLabel":"Low"}}`, m.ID)
		expect(ws, "ready")
		return ws, m.ID
	}
	first, firstID := open()
	second, secondID := open()
	if firstID == secondID {
		t.Fatal("terminal IDs collided")
	}
	first.WriteJSON(map[string]string{"type": "close"})
	if msg := next(); msg.ID != firstID || msg.Type != "close" {
		t.Fatalf("wrong close %+v", msg)
	}
	lines <- fmt.Sprintf(`{"id":%q,"event":{"type":"exit"}}`, firstID)
	if _, _, err := first.ReadMessage(); err == nil {
		t.Fatal("first terminal did not finish closing")
	}
	second.WriteJSON(map[string]string{"type": "input", "text": "second"})
	if msg := next(); msg.ID != secondID || msg.Type != "event" || !strings.Contains(string(msg.Event), "second") {
		t.Fatalf("wrong input %+v", msg)
	}
	lines <- fmt.Sprintf(`{"id":%q,"event":{"type":"output","text":"second"}}`, secondID)
	expect(second, "output")
	second.Close()
	select {
	case <-h.done:
	case <-time.After(3 * time.Second):
		t.Fatal("last socket did not release helper")
	}
}
