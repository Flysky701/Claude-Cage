package managedproxy

import (
	"context"
	"encoding/base64"
	"encoding/json"
	"io"
	"net/http"
	"net/http/httptest"
	"os"
	"reflect"
	"strings"
	"testing"

	"go.yaml.in/yaml/v3"
)

func TestTrojanHTTPSSubscriptionStoreAndRuntime(t *testing.T) {
	links := "trojan://fixture@example.com:443?peer=tls.example.com&allowInsecure=0#TCP\n" +
		"trojan://fixture@example.com:443?type=ws&host=cdn.example.com&path=%2Ftunnel#WS\n" +
		"trojan://fixture@example.com:443?type=grpc&serviceName=proxy-service#GRPC\n" +
		"vmess://unsupported#unsupported"
	server := httptest.NewTLSServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.UserAgent() != "clash.meta/Cage" {
			t.Error("subscription client identity changed")
		}
		w.Header().Set("Content-Type", "text/plain")
		_, _ = io.WriteString(w, base64.StdEncoding.EncodeToString([]byte(links)))
	}))
	defer server.Close()
	data, _, err := Fetch(context.Background(), server.Client(), server.URL)
	if err != nil {
		t.Fatal(err)
	}
	profile := t.TempDir()
	s, _ := Load(profile)
	if err := s.Import("subscription", server.URL, data, "source", 24, ""); err != nil {
		t.Fatal(err)
	}
	if s.Count() != 3 || len(s.Sources[0].Skipped) != 1 || s.Selected != "" {
		t.Fatal("HTTPS subscription lost nodes, skipped-node report, or applied a route")
	}
	s.Selected = s.Sources[0].Nodes[0].ID
	s.Chain = []string{s.Selected}
	if err := s.Save(profile); err != nil {
		t.Fatal(err)
	}
	loaded, err := Load(profile)
	if err != nil {
		t.Fatal(err)
	}
	runtime, err := loaded.Runtime(profile)
	if err != nil {
		t.Fatal(err)
	}
	var config struct {
		Proxies []map[string]any
		Rules   []string
	}
	if err := yaml.Unmarshal(runtime, &config); err != nil || len(config.Proxies) != 3 || !reflect.DeepEqual(config.Rules, []string{"MATCH," + Group}) {
		t.Fatal("runtime lost imported nodes or changed the managed route", err)
	}
	for _, node := range config.Proxies {
		if node["udp"] != false || node["password"] != "fixture" || node["skip-cert-verify"] == true {
			t.Fatal("runtime changed credentials, TLS verification or UDP policy")
		}
	}
	if os.Getenv("CAGE_PROXY_INTEGRATION") == "1" {
		if err := Validate(context.Background(), profile, loaded); err != nil {
			t.Fatal(err)
		}
	}
}

func TestTrojanShareSubscription(t *testing.T) {
	link := "trojan://private%3Apass%40word%2B@example.com:443?peer=tls.example.com&allowInsecure=0#%E6%B5%8B%E8%AF%95%20node"
	for _, format := range []struct {
		name   string
		encode func(string) string
	}{
		{"plain", func(s string) string { return s }},
		{"base64", func(s string) string { return base64.StdEncoding.EncodeToString([]byte(s)) }},
		{"unpadded", func(s string) string { return base64.RawStdEncoding.EncodeToString([]byte(s)) }},
		{"url-base64", func(s string) string { return base64.URLEncoding.EncodeToString([]byte(s)) }},
		{"url-unpadded", func(s string) string { return base64.RawURLEncoding.EncodeToString([]byte(s)) }},
		{"wrapped", func(s string) string {
			b := base64.StdEncoding.EncodeToString([]byte(s))
			return "\ufeff \r\n" + b[:40] + "\r\n" + b[40:] + "\n"
		}},
	} {
		t.Run(format.name, func(t *testing.T) {
			s, _ := Load(t.TempDir())
			if err := s.Import("subscription", "https://example.com/sub", []byte(format.encode(link)), "source", 24, ""); err != nil {
				t.Fatal(err)
			}
			if s.Count() != 1 || s.Selected != "" || len(s.Chain) != 0 {
				t.Fatal("import must retain one node without applying it")
			}
			node := s.Sources[0].Nodes[0]
			want := map[string]any{"name": node.ID, "type": "trojan", "server": "example.com", "port": 443,
				"password": "private:pass@word+", "sni": "tls.example.com", "skip-cert-verify": false, "udp": false}
			if node.Name != "测试 node" || !reflect.DeepEqual(node.Config, want) {
				t.Fatal("share-link fields were not preserved")
			}
		})
	}
}

func TestTrojanShareTransports(t *testing.T) {
	for _, tc := range []struct {
		name, query string
		fields      map[string]any
	}{
		{"tcp", "type=tcp&security=tls&sni=tls.example.com&peer=tls.example.com&allowInsecure=1&alpn=h2,http%2F1.1&fp=chrome",
			map[string]any{"sni": "tls.example.com", "skip-cert-verify": true, "alpn": []string{"h2", "http/1.1"}, "client-fingerprint": "chrome"}},
		{"websocket", "type=ws&host=cdn.example.com&path=%2Ftunnel%3Fed%3D2048",
			map[string]any{"network": "ws", "ws-opts": map[string]any{"path": "/tunnel?ed=2048", "headers": map[string]any{"Host": "cdn.example.com"}}}},
		{"grpc", "type=grpc&serviceName=proxy-service",
			map[string]any{"network": "grpc", "grpc-opts": map[string]any{"grpc-service-name": "proxy-service"}}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			nodes, err := Parse([]byte("trojan://fixture@[2001:db8::1]:8443?"+tc.query+"#node"), "source")
			if err != nil {
				t.Fatal(err)
			}
			config := nodes[0].Config
			if config["server"] != "2001:db8::1" || config["port"] != 8443 || config["udp"] != false {
				t.Fatal("address or UDP policy changed")
			}
			for key, value := range tc.fields {
				if !reflect.DeepEqual(config[key], value) {
					t.Fatalf("transport field %s was not preserved", key)
				}
			}
		})
	}
}

func TestShareSubscriptionSkippedNodesDoNotExposeCredentials(t *testing.T) {
	valid := "trojan://fixture@example.com:443#good\n"
	for _, bad := range []string{
		"vmess://private-credential#unsupported",
		"trojan://private-credential@example.com:443?plugin=private-option#unsupported",
		"trojan://private-credential@example.com:443?sni=one&peer=private-other#conflict",
		"trojan://private-credential@example.com:443?allowInsecure=private-invalid#invalid",
		"trojan://private-credential@example.com:443?allowInsecure=0&allowInsecure=1#duplicate",
		"trojan://private-credential@example.com:443?security=none#not-tls",
		"trojan://private-credential@example.com:443?type=tcp&path=%2Fprivate-path#wrong-transport",
		"trojan://private-credential@example.com:443?type=grpc&host=private-host#wrong-host",
		"trojan://private-credential@example.com:443?type=ws&serviceName=private-service#wrong-service",
		"trojan://private-credential@example.com:65536#port",
		"trojan://private-credential@example.com:0#port",
		"trojan://private-credential@example.com:443/private-path#path",
		"trojan://private-%ZZ@example.com:443#malformed",
		"trojan://example.com:443#no-password",
	} {
		nodes, skipped, err := parseNodes([]byte(base64.StdEncoding.EncodeToString([]byte(valid+bad))), "source")
		if err != nil || len(nodes) != 1 || len(skipped) != 1 || skipped[0].Index != 2 || skipped[0].Reason == "" {
			t.Fatal("partial import did not report the unsupported node", err)
		}
		report, _ := json.Marshal(skipped)
		if strings.Contains(string(report), "private-") {
			t.Fatal("skipped-node report exposed credentials or parameter values")
		}
		_, _, err = parseNodes([]byte(bad), "source")
		if err == nil || strings.Contains(err.Error(), "private-") {
			t.Fatal("invalid-only import was accepted or exposed a secret")
		}
	}
}

func TestShareSubscriptionRefreshPreservesSelectedRoute(t *testing.T) {
	s, _ := Load(t.TempDir())
	original := "trojan://fixture@example.com:443#exit"
	if err := s.Import("source", "https://example.com/sub", []byte(original), "source", 24, ""); err != nil {
		t.Fatal(err)
	}
	s.Selected = s.Sources[0].Nodes[0].ID
	s.Chain = []string{s.Selected}
	before, _ := json.Marshal(s)
	broken := original + "\ntrojan://other@other.example.com:443#exit"
	if err := s.Import("source", "https://example.com/sub", []byte(broken), "source", 24, ""); err == nil {
		t.Fatal("duplicate names should fail")
	}
	broken = "trojan://fixture@example.com:443?type=unsupported#exit\ntrojan://other@other.example.com:443#spare"
	if err := s.Import("source", "https://example.com/sub", []byte(broken), "source", 24, ""); err == nil {
		t.Fatal("refresh removed the selected exit")
	}
	after, _ := json.Marshal(s)
	if string(before) != string(after) {
		t.Fatal("failed refresh changed the saved source or route")
	}
}

func TestShareSubscriptionLimitsAndInvalidFormats(t *testing.T) {
	for _, input := range []string{
		strings.Repeat("trojan://fixture@example.com:443#node\n", 3001),
		strings.Repeat("A", MaxImport+1),
		"%%%not-base64%%%",
		base64.StdEncoding.EncodeToString([]byte("<html>not a subscription</html>")),
		base64.StdEncoding.EncodeToString([]byte("proxies: [{name: hidden, type: http, server: example.com, port: 80}]")),
	} {
		if _, err := Parse([]byte(input), "source"); err == nil {
			t.Fatal("invalid or oversized import accepted")
		}
	}
}
