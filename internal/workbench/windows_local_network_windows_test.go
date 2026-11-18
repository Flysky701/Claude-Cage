package workbench

import (
	"bufio"
	"context"
	"encoding/base64"
	"errors"
	"io"
	"net"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/Microsoft/go-winio"
	"github.com/sylvinus/agent-vm/internal/cage"
)

// The fixture acts as the selected upstream. No target is contacted, and the
// test never loads a real profile or selects a node in the workbench.
func TestWindowsLocalNetworkRequiresHelperAndRoute(t *testing.T) {
	name := "Cage.LocalEgress." + randomToken()
	listener, err := listenLocalNetworkPipe(name)
	if err != nil {
		t.Fatal(err)
	}
	token := strings.Repeat("a", 64)
	route := &localAppRoute{ctx: context.Background()}
	proxy, err := cage.GateProxy(route, token)
	if err != nil {
		t.Fatal(err)
	}
	server := &http.Server{Handler: http.HandlerFunc(func(w http.ResponseWriter, req *http.Request) {
		req.Header.Set("Proxy-Authorization", "Basic "+base64.StdEncoding.EncodeToString([]byte("proxy:"+token)))
		proxy.ServeHTTP(w, req)
	})}
	go server.Serve(&localNetworkListener{listener, token})
	defer server.Close()
	open := func(key string) (net.Conn, *bufio.Reader) {
		t.Helper()
		ctx, cancel := context.WithTimeout(context.Background(), 3*time.Second)
		defer cancel()
		conn, err := winio.DialPipeContext(ctx, listener.Addr().String())
		if err != nil {
			t.Fatal(err)
		}
		t.Cleanup(func() { conn.Close() })
		_ = conn.SetDeadline(time.Now().Add(4 * time.Second))
		_, err = io.WriteString(conn, key+"CONNECT 8.8.8.8:443 HTTP/1.1\r\nHost: 8.8.8.8:443\r\n\r\n")
		if err != nil {
			t.Fatal(err)
		}
		return conn, bufio.NewReader(conn)
	}
	expectStatus := func(reader *bufio.Reader, want int) {
		t.Helper()
		res, err := http.ReadResponse(reader, &http.Request{Method: http.MethodConnect})
		if err != nil || res.StatusCode != want {
			t.Fatalf("CONNECT = %v, error = %v, want %d", res, err, want)
		}
	}
	_, denied := open(strings.Repeat("b", 64))
	if _, err := denied.ReadByte(); !errors.Is(err, io.EOF) {
		t.Fatalf("invalid helper key: expected disconnect, got %v", err)
	}
	_, offline := open(token)
	expectStatus(offline, http.StatusForbidden)

	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodConnect || r.Host != "8.8.8.8:443" {
			http.Error(w, "unexpected target", 400)
			return
		}
		conn, buf, err := w.(http.Hijacker).Hijack()
		if err != nil {
			return
		}
		defer conn.Close()
		_ = conn.SetDeadline(time.Now().Add(8 * time.Second))
		_, _ = io.WriteString(conn, "HTTP/1.1 200 Connection Established\r\n\r\n")
		if line, err := buf.ReadString('\n'); err == nil && line == "request\n" {
			_, _ = io.WriteString(conn, "reply\n")
			_, _ = io.Copy(io.Discard, buf)
		}
	}))
	defer upstream.Close()
	cfg := cage.DefaultConfig()
	cfg.ProxyURL = upstream.URL
	raw, err := cage.NewEgress(cfg)
	if err != nil {
		t.Fatal(err)
	}
	life, cancel := context.WithCancel(context.Background())
	defer cancel()
	route.mu.Lock()
	route.grant = &localNetworkGrant{cfg, raw, life, cancel}
	route.mu.Unlock()
	conn, online := open(token)
	expectStatus(online, http.StatusOK)
	if _, err = io.WriteString(conn, "request\n"); err != nil {
		t.Fatal(err)
	}
	if reply, err := online.ReadString('\n'); err != nil || reply != "reply\n" {
		t.Fatalf("through selected fixture: %q, error = %v", reply, err)
	}
	route.mu.Lock()
	route.revokeLocked("stopped")
	route.mu.Unlock()
	if _, err := online.ReadByte(); !errors.Is(err, io.EOF) {
		t.Fatalf("existing tunnel after revocation: expected disconnect, got %v", err)
	}
	_, revoked := open(token)
	expectStatus(revoked, http.StatusForbidden)
}
