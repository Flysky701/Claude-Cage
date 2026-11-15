package windowslite

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

type fakeWorker struct{ inputs []json.RawMessage }

func (f *fakeWorker) Call(_ context.Context, input json.RawMessage) (json.RawMessage, error) {
	f.inputs = append(f.inputs, append(json.RawMessage{}, input...))
	return json.RawMessage(`{"ok":true,"state":{"phase":"blocked","network":"closed","acceptance":"not-verified"}}`), nil
}
func (f *fakeWorker) Close() error { return nil }

func testServer() (*server, *fakeWorker) {
	f := &fakeWorker{}
	return &server{origin: "http://localhost:12345", token: strings.Repeat("a", 64), id: strings.Repeat("b", 64), worker: f, cancel: func() {}}, f
}

func call(s *server, method, path, body, origin, token string, header bool) *httptest.ResponseRecorder {
	r := httptest.NewRequest(method, s.origin+path, strings.NewReader(body))
	if token != "" {
		r.Header.Set("Authorization", "Bearer "+token)
	}
	if origin != "" {
		r.Header.Set("Origin", origin)
	}
	if header {
		r.Header.Set("X-Cage-Lite", "1")
	}
	w := httptest.NewRecorder()
	s.ServeHTTP(w, r)
	return w
}

func TestMutationsRequireSameOriginAndAuthentication(t *testing.T) {
	for _, tc := range []struct {
		name, origin, token string
		header              bool
	}{
		{"no origin", "", strings.Repeat("a", 64), true},
		{"foreign origin", "https://example.com", strings.Repeat("a", 64), true},
		{"no explicit header", "http://localhost:12345", strings.Repeat("a", 64), false},
		{"no authentication", "http://localhost:12345", "", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s, w := testServer()
			r := call(s, "POST", "/api/lite/launch", `{"entry":"shell"}`, tc.origin, tc.token, tc.header)
			if r.Code < 400 || len(w.inputs) != 0 {
				t.Fatal("unauthorized operation reached worker")
			}
		})
	}
}

func TestHostValidationPrecedesSessionAndStaticFiles(t *testing.T) {
	s, worker := testServer()
	for _, path := range []string{"/", "/api/session", "/api/lite/status"} {
		r := httptest.NewRequest("GET", "http://attacker.test:12345"+path, nil)
		r.Header.Set("Authorization", "Bearer "+s.token)
		w := httptest.NewRecorder()
		s.ServeHTTP(w, r)
		if w.Code != http.StatusForbidden {
			t.Fatalf("unexpected host accepted: %s", path)
		}
	}
	if len(worker.inputs) != 0 {
		t.Fatal("worker called")
	}
}

func TestSessionCookieAndBlockedStateArePreserved(t *testing.T) {
	s, worker := testServer()
	w := call(s, "POST", "/api/session", `{"token":"`+s.token+`"}`, s.origin, "", true)
	if w.Code != 200 {
		t.Fatal(w.Body.String())
	}
	cookies := w.Result().Cookies()
	if len(cookies) != 1 || !cookies[0].HttpOnly || cookies[0].SameSite != http.SameSiteStrictMode {
		t.Fatal("session cookie is not restricted")
	}
	r := httptest.NewRequest("GET", s.origin+"/api/lite/status", nil)
	r.AddCookie(cookies[0])
	w = httptest.NewRecorder()
	s.ServeHTTP(w, r)
	if w.Code != 200 || !strings.Contains(w.Body.String(), `"acceptance":"not-verified"`) || len(worker.inputs) != 1 {
		t.Fatal(w.Body.String())
	}
}

func TestActionComesFromRouteAndMalformedInputNeverExecutes(t *testing.T) {
	s, worker := testServer()
	for _, body := range []string{"null", "[]", `{} {}`, `{"entry":`} {
		w := call(s, "POST", "/api/lite/launch", body, s.origin, s.token, true)
		if w.Code != 400 || len(worker.inputs) != 0 {
			t.Fatalf("malformed body reached worker: %s", body)
		}
	}
	w := call(s, "POST", "/api/lite/launch", `{"entry":"shell","action":"configure"}`, s.origin, s.token, true)
	var input map[string]any
	if w.Code != 200 || len(worker.inputs) != 1 || json.Unmarshal(worker.inputs[0], &input) != nil || input["action"] != "launch" {
		t.Fatal("body changed routed action")
	}
}
