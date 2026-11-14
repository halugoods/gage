package store

import (
	"context"
	"path/filepath"
	"testing"
	"time"

	"github.com/hirotomasato/paygateme/core"
)

func TestSQLStoreOperations(t *testing.T) {
	tempDir := t.TempDir()
	dbPath := filepath.Join(tempDir, "test_store.db")

	store, err := OpenSQLStore(dbPath)
	if err != nil {
		t.Fatalf("OpenSQLStore: %v", err)
	}
	defer store.Close()

	ctx := context.Background()

	// 1. Session persistence
	sessionData := []byte(`{"account_id":"acc_1","merchant":{"id":"mch_1","name":"Warung GAGE"}}`)
	if err := store.SaveSession(ctx, "shopee", "acc_1", sessionData); err != nil {
		t.Fatalf("SaveSession: %v", err)
	}

	loaded, err := store.LoadSession(ctx, "shopee", "acc_1")
	if err != nil || string(loaded) != string(sessionData) {
		t.Fatalf("LoadSession mismatch: err=%v, data=%s", err, string(loaded))
	}

	latest, err := store.LoadLatestSession(ctx, "shopee")
	if err != nil || string(latest) != string(sessionData) {
		t.Fatalf("LoadLatestSession mismatch: err=%v, data=%s", err, string(latest))
	}

	// 2. Payments CRUD
	p := core.Payment{
		ID:           "test_pay_1",
		Scope:        &core.PaymentScope{Provider: "shopee", AccountID: "acc_1", MerchantID: "mch_1"},
		BaseAmount:   10000,
		UniqueOffset: 34,
		UniqueAmount: 10034,
		Status:       core.PaymentPending,
		CreatedAt:    time.Now().Truncate(time.Millisecond),
		ExpiresAt:    time.Now().Add(10 * time.Minute).Truncate(time.Millisecond),
		Reference:    "REF-10034",
		QRString:     "000201...",
		Metadata:     map[string]any{"note": "GAGE Test"},
	}

	if err := store.Create(ctx, p); err != nil {
		t.Fatalf("Create payment: %v", err)
	}

	retrieved, err := store.Get(ctx, p.ID)
	if err != nil || retrieved == nil {
		t.Fatalf("Get payment: err=%v, p=%v", err, retrieved)
	}
	if retrieved.UniqueAmount != 10034 || retrieved.Reference != "REF-10034" {
		t.Errorf("payment data mismatch: amount=%d, ref=%s", retrieved.UniqueAmount, retrieved.Reference)
	}

	active, err := store.ListActive(ctx, p.Scope)
	if err != nil || len(active) != 1 {
		t.Fatalf("ListActive expected 1, got %d (err=%v)", len(active), err)
	}

	// 3. Update status
	p.Status = core.PaymentPaid
	p.Transaction = &core.MerchantTransaction{
		ID:          "SP_TX_123",
		OrderID:     "SP_ORD_456",
		Status:      "SUCCESS",
		Amount:      10034,
		PaymentType: "SHOPEEPAY",
		Time:        time.Now(),
	}
	if err := store.Update(ctx, p); err != nil {
		t.Fatalf("Update payment: %v", err)
	}

	updated, err := store.Get(ctx, p.ID)
	if err != nil || updated.Status != core.PaymentPaid || updated.Transaction == nil || updated.Transaction.ID != "SP_TX_123" {
		t.Errorf("updated payment mismatch: status=%s, txn=%v", updated.Status, updated.Transaction)
	}

	// List active should now be empty
	activeAfter, _ := store.ListActive(ctx, p.Scope)
	if len(activeAfter) != 0 {
		t.Errorf("expected 0 active payments, got %d", len(activeAfter))
	}
}
