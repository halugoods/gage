package webhook

import (
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"path/filepath"
	"testing"
	"time"

	"gagetway/store"
)

func TestDispatcherSettlement(t *testing.T) {
	var receivedPayload SettlementPayload
	var receivedHeaderSecret string
	var receivedMethod string
	var receivedPath string

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		receivedMethod = r.Method
		receivedPath = r.URL.Path
		receivedHeaderSecret = r.Header.Get("X-Gateway-Secret")

		if err := json.NewDecoder(r.Body).Decode(&receivedPayload); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		_, _ = w.Write([]byte(`{"success":true}`))
	}))
	defer ts.Close()

	tempDir := t.TempDir()
	sqlStore, err := store.OpenSQLStore(filepath.Join(tempDir, "test.db"))
	if err != nil {
		t.Fatalf("failed to open sql store: %v", err)
	}
	defer sqlStore.Close()

	testSecret := "test-secret-key-xyz"
	dispatcher := NewDispatcher(ts.URL, testSecret, sqlStore)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	err = dispatcher.DispatchSettlement(ctx, "pay_123", 25042, "ORD-2026-999", "SP_TX_8888")
	if err != nil {
		t.Fatalf("unexpected dispatch error: %v", err)
	}

	if receivedMethod != http.MethodPost {
		t.Errorf("expected POST, got %s", receivedMethod)
	}
	if receivedPath != "/api/gateway/settle" {
		t.Errorf("expected /api/gateway/settle, got %s", receivedPath)
	}
	if receivedHeaderSecret != testSecret {
		t.Errorf("expected header secret %s, got %s", testSecret, receivedHeaderSecret)
	}
	if receivedPayload.Amount != 25042 {
		t.Errorf("expected amount 25042, got %d", receivedPayload.Amount)
	}
	if receivedPayload.Reference != "ORD-2026-999" {
		t.Errorf("expected reference ORD-2026-999, got %s", receivedPayload.Reference)
	}
	if receivedPayload.ShopeeTxID != "SP_TX_8888" {
		t.Errorf("expected shopee_tx_id SP_TX_8888, got %s", receivedPayload.ShopeeTxID)
	}
	if receivedPayload.Secret != testSecret {
		t.Errorf("expected payload secret %s, got %s", testSecret, receivedPayload.Secret)
	}

	// Verify webhook audit log in SQLite
	logs, err := sqlStore.ListWebhookLogs(ctx, 10)
	if err != nil {
		t.Fatalf("failed to query webhook logs: %v", err)
	}
	if len(logs) != 1 {
		t.Fatalf("expected 1 audit log, got %d", len(logs))
	}
	if !logs[0].Success || logs[0].StatusCode != 200 {
		t.Errorf("expected log success=true status=200, got success=%v status=%d", logs[0].Success, logs[0].StatusCode)
	}
}
