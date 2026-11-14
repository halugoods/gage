package server

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"gagetway/gateway"
	"gagetway/store"
	"gagetway/webhook"
)

func setupTestServer(t *testing.T) (*Server, *gateway.Manager, *store.SQLStore) {
	tempDir := t.TempDir()
	sqlStore, err := store.OpenSQLStore(filepath.Join(tempDir, "server_test.db"))
	if err != nil {
		t.Fatalf("OpenSQLStore: %v", err)
	}

	dispatcher := webhook.NewDispatcher("http://127.0.0.1:8787", "test-secret", sqlStore)
	mgr := gateway.NewManager(sqlStore, dispatcher, "", 5*time.Second)

	srv := NewServer(0, mgr, sqlStore)
	return srv, mgr, sqlStore
}

func TestHealthEndpoint(t *testing.T) {
	srv, mgr, sqlStore := setupTestServer(t)
	defer mgr.Close()
	defer sqlStore.Close()

	req := httptest.NewRequest(http.MethodGet, "/health", nil)
	rec := httptest.NewRecorder()

	srv.httpServer.Handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 OK, got %d", rec.Code)
	}

	var resp map[string]any
	if err := json.NewDecoder(rec.Body).Decode(&resp); err != nil {
		t.Fatalf("failed to decode json: %v", err)
	}
	if resp["status"] != "ok" || resp["service"] != "gagetway" {
		t.Errorf("unexpected health body: %v", resp)
	}
}

func TestCORSHeaders(t *testing.T) {
	srv, mgr, sqlStore := setupTestServer(t)
	defer mgr.Close()
	defer sqlStore.Close()

	req := httptest.NewRequest(http.MethodOptions, "/api/gateway/session", nil)
	rec := httptest.NewRecorder()

	srv.httpServer.Handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusOK {
		t.Errorf("expected 200 for OPTIONS, got %d", rec.Code)
	}
	if rec.Header().Get("Access-Control-Allow-Origin") != "*" {
		t.Errorf("expected Access-Control-Allow-Origin: *")
	}
}

func TestRequestOtpValidation(t *testing.T) {
	srv, mgr, sqlStore := setupTestServer(t)
	defer mgr.Close()
	defer sqlStore.Close()

	// Empty body should return 400
	req := httptest.NewRequest(http.MethodPost, "/api/gateway/otp/request", strings.NewReader(`{}`))
	rec := httptest.NewRecorder()

	srv.httpServer.Handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusBadRequest {
		t.Errorf("expected 400 Bad Request, got %d", rec.Code)
	}
}

func TestPaymentUnauthenticated(t *testing.T) {
	srv, mgr, sqlStore := setupTestServer(t)
	defer mgr.Close()
	defer sqlStore.Close()

	req := httptest.NewRequest(http.MethodPost, "/api/gateway/payments/create", strings.NewReader(`{"amount": 50000, "reference": "REF-1"}`))
	rec := httptest.NewRecorder()

	srv.httpServer.Handler.ServeHTTP(rec, req)

	if rec.Code != http.StatusInternalServerError && rec.Code != http.StatusUnauthorized {
		t.Errorf("expected error status for unauthenticated payment create, got %d", rec.Code)
	}
}
