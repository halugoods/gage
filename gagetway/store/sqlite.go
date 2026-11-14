package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"github.com/hirotomasato/paygateme/core"
	_ "modernc.org/sqlite"
)

// WebhookAuditRecord logs every dispatch attempt to gage-cloud.
type WebhookAuditRecord struct {
	ID           int64     `json:"id"`
	PaymentID    string    `json:"payment_id"`
	Reference    string    `json:"reference"`
	ShopeeTxID   string    `json:"shopee_tx_id"`
	Amount       int64     `json:"amount"`
	TargetURL    string    `json:"target_url"`
	StatusCode   int       `json:"status_code"`
	Success      bool      `json:"success"`
	ErrorMessage string    `json:"error_message,omitempty"`
	Attempt      int       `json:"attempt"`
	CreatedAt    time.Time `json:"created_at"`
}

// SQLStore implements core.PaymentStore backed by SQLite.
type SQLStore struct {
	db *sql.DB
}

// OpenSQLStore opens or creates a SQLite-backed payment store.
func OpenSQLStore(dbPath string) (*SQLStore, error) {
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0o755); err != nil {
		return nil, fmt.Errorf("create db directory %s: %w", dir, err)
	}

	dsn := fmt.Sprintf("file:%s?_pragma=foreign_keys(1)&_pragma=busy_timeout(10000)&_pragma=journal_mode(WAL)&_pragma=synchronous(NORMAL)", dbPath)
	db, err := sql.Open("sqlite", dsn)
	if err != nil {
		return nil, fmt.Errorf("open sqlite: %w", err)
	}
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("ping sqlite: %w", err)
	}

	s := &SQLStore{db: db}
	if err := s.migrate(); err != nil {
		_ = db.Close()
		return nil, fmt.Errorf("migrate sqlite schema: %w", err)
	}
	return s, nil
}

func (s *SQLStore) migrate() error {
	stmts := []string{
		`CREATE TABLE IF NOT EXISTS payment_sessions (
			provider   TEXT NOT NULL,
			id         TEXT NOT NULL,
			session    TEXT NOT NULL,
			created_at INTEGER NOT NULL,
			PRIMARY KEY (provider, id)
		)`,
		`CREATE TABLE IF NOT EXISTS payments (
			id             TEXT NOT NULL PRIMARY KEY,
			provider       TEXT NOT NULL,
			account_id     TEXT NOT NULL,
			merchant_id    TEXT NOT NULL,
			base_amount    INTEGER NOT NULL,
			unique_offset  INTEGER NOT NULL,
			unique_amount  INTEGER NOT NULL,
			status         TEXT NOT NULL,
			created_at     INTEGER NOT NULL,
			expires_at     INTEGER NOT NULL,
			reference      TEXT NOT NULL,
			qr_string      TEXT NOT NULL,
			txn            TEXT NOT NULL,
			metadata       TEXT NOT NULL
		)`,
		`CREATE INDEX IF NOT EXISTS idx_payments_scope ON payments(provider, account_id, merchant_id)`,
		`CREATE INDEX IF NOT EXISTS idx_payments_status ON payments(status)`,
		`CREATE TABLE IF NOT EXISTS webhook_deliveries (
			id             INTEGER PRIMARY KEY AUTOINCREMENT,
			payment_id     TEXT NOT NULL,
			reference      TEXT NOT NULL,
			shopee_tx_id   TEXT NOT NULL,
			amount         INTEGER NOT NULL,
			target_url     TEXT NOT NULL,
			status_code    INTEGER NOT NULL,
			success        INTEGER NOT NULL,
			error_message  TEXT NOT NULL,
			attempt        INTEGER NOT NULL,
			created_at     INTEGER NOT NULL
		)`,
		`CREATE INDEX IF NOT EXISTS idx_webhook_payment_id ON webhook_deliveries(payment_id)`,
	}
	for _, stmt := range stmts {
		if _, err := s.db.Exec(stmt); err != nil {
			return fmt.Errorf("execute migration stmt: %w", err)
		}
	}
	return nil
}

// --- Core PaymentStore Implementation ---

func (s *SQLStore) Create(ctx context.Context, p core.Payment) error {
	txJSON, _ := json.Marshal(p.Transaction)
	metaJSON, _ := json.Marshal(p.Metadata)
	scope := p.Scope
	if scope == nil {
		scope = &core.PaymentScope{}
	}
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO payments (id, provider, account_id, merchant_id, base_amount, unique_offset, unique_amount, status, created_at, expires_at, reference, qr_string, txn, metadata)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		p.ID,
		scope.Provider, scope.AccountID, scope.MerchantID,
		p.BaseAmount, p.UniqueOffset, p.UniqueAmount,
		string(p.Status),
		p.CreatedAt.UnixMilli(), p.ExpiresAt.UnixMilli(),
		p.Reference, p.QRString,
		string(txJSON), string(metaJSON),
	)
	return err
}

func (s *SQLStore) Update(ctx context.Context, p core.Payment) error {
	txJSON, _ := json.Marshal(p.Transaction)
	metaJSON, _ := json.Marshal(p.Metadata)
	_, err := s.db.ExecContext(ctx,
		`UPDATE payments SET
			status=?, expires_at=?, txn=?, metadata=?
		 WHERE id=?`,
		string(p.Status),
		p.ExpiresAt.UnixMilli(),
		string(txJSON), string(metaJSON),
		p.ID,
	)
	return err
}

func (s *SQLStore) Get(ctx context.Context, id string) (*core.Payment, error) {
	row := s.db.QueryRowContext(ctx,
		`SELECT id, provider, account_id, merchant_id, base_amount, unique_offset, unique_amount, status, created_at, expires_at, reference, qr_string, txn, metadata
		 FROM payments WHERE id=?`, id)
	return s.scanPayment(row)
}

func (s *SQLStore) ListActive(ctx context.Context, scope *core.PaymentScope) ([]core.Payment, error) {
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, provider, account_id, merchant_id, base_amount, unique_offset, unique_amount, status, created_at, expires_at, reference, qr_string, txn, metadata
		 FROM payments WHERE status='pending' ORDER BY created_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []core.Payment
	for rows.Next() {
		p, err := s.scanPaymentRow(rows)
		if err != nil {
			return nil, err
		}
		if scope != nil {
			if p.Scope == nil || !core.SameScope(*p.Scope, *scope) {
				continue
			}
		}
		out = append(out, *p)
	}
	return out, rows.Err()
}

func (s *SQLStore) scanPayment(row *sql.Row) (*core.Payment, error) {
	var (
		id, provider, accountID, merchantID    string
		baseAmount, uniqueOffset, uniqueAmount int64
		status                                 string
		createdAtMs, expiresAtMs               int64
		reference, qrString, txJSON, metaJSON  string
	)
	err := row.Scan(&id, &provider, &accountID, &merchantID,
		&baseAmount, &uniqueOffset, &uniqueAmount, &status,
		&createdAtMs, &expiresAtMs,
		&reference, &qrString, &txJSON, &metaJSON)
	if err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	p := &core.Payment{
		ID:           id,
		Scope:        &core.PaymentScope{Provider: provider, AccountID: accountID, MerchantID: merchantID},
		BaseAmount:   baseAmount,
		UniqueOffset: uniqueOffset,
		UniqueAmount: uniqueAmount,
		Status:       core.PaymentStatus(status),
		CreatedAt:    time.UnixMilli(createdAtMs),
		ExpiresAt:    time.UnixMilli(expiresAtMs),
		Reference:    reference,
		QRString:     qrString,
	}
	if txJSON != "" && txJSON != "null" {
		var tx core.MerchantTransaction
		if json.Unmarshal([]byte(txJSON), &tx) == nil {
			p.Transaction = &tx
		}
	}
	if metaJSON != "" && metaJSON != "null" {
		_ = json.Unmarshal([]byte(metaJSON), &p.Metadata)
	}
	return p, nil
}

func (s *SQLStore) scanPaymentRow(rows *sql.Rows) (*core.Payment, error) {
	var (
		id, provider, accountID, merchantID    string
		baseAmount, uniqueOffset, uniqueAmount int64
		status                                 string
		createdAtMs, expiresAtMs               int64
		reference, qrString, txJSON, metaJSON  string
	)
	err := rows.Scan(&id, &provider, &accountID, &merchantID,
		&baseAmount, &uniqueOffset, &uniqueAmount, &status,
		&createdAtMs, &expiresAtMs,
		&reference, &qrString, &txJSON, &metaJSON)
	if err != nil {
		return nil, err
	}
	p := &core.Payment{
		ID:           id,
		Scope:        &core.PaymentScope{Provider: provider, AccountID: accountID, MerchantID: merchantID},
		BaseAmount:   baseAmount,
		UniqueOffset: uniqueOffset,
		UniqueAmount: uniqueAmount,
		Status:       core.PaymentStatus(status),
		CreatedAt:    time.UnixMilli(createdAtMs),
		ExpiresAt:    time.UnixMilli(expiresAtMs),
		Reference:    reference,
		QRString:     qrString,
	}
	if txJSON != "" && txJSON != "null" {
		var tx core.MerchantTransaction
		if json.Unmarshal([]byte(txJSON), &tx) == nil {
			p.Transaction = &tx
		}
	}
	if metaJSON != "" && metaJSON != "null" {
		_ = json.Unmarshal([]byte(metaJSON), &p.Metadata)
	}
	return p, nil
}

// ListAll returns all payments, newest first.
func (s *SQLStore) ListAll(ctx context.Context, limit int) ([]core.Payment, error) {
	if limit <= 0 || limit > 500 {
		limit = 100
	}
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, provider, account_id, merchant_id, base_amount, unique_offset, unique_amount, status, created_at, expires_at, reference, qr_string, txn, metadata
		 FROM payments ORDER BY created_at DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []core.Payment
	for rows.Next() {
		p, err := s.scanPaymentRow(rows)
		if err != nil {
			return nil, err
		}
		out = append(out, *p)
	}
	return out, rows.Err()
}

// --- Session Persistence ---

func (s *SQLStore) SaveSession(ctx context.Context, provider, id string, sessionJSON []byte) error {
	_, err := s.db.ExecContext(ctx,
		`INSERT OR REPLACE INTO payment_sessions (provider, id, session, created_at)
		 VALUES (?, ?, ?, ?)`,
		provider, id, string(sessionJSON), time.Now().UnixMilli())
	return err
}

func (s *SQLStore) LoadSession(ctx context.Context, provider, id string) ([]byte, error) {
	row := s.db.QueryRowContext(ctx,
		`SELECT session FROM payment_sessions WHERE provider=? AND id=?`, provider, id)
	var raw string
	if err := row.Scan(&raw); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return []byte(raw), nil
}

func (s *SQLStore) LoadLatestSession(ctx context.Context, provider string) ([]byte, error) {
	row := s.db.QueryRowContext(ctx,
		`SELECT session FROM payment_sessions WHERE provider=? ORDER BY created_at DESC LIMIT 1`, provider)
	var raw string
	if err := row.Scan(&raw); err != nil {
		if err == sql.ErrNoRows {
			return nil, nil
		}
		return nil, err
	}
	return []byte(raw), nil
}

func (s *SQLStore) DeleteSession(ctx context.Context, provider, id string) error {
	_, err := s.db.ExecContext(ctx,
		`DELETE FROM payment_sessions WHERE provider=? AND id=?`, provider, id)
	return err
}

// --- Webhook Audit Logging ---

func (s *SQLStore) RecordWebhookLog(ctx context.Context, rec WebhookAuditRecord) error {
	successInt := 0
	if rec.Success {
		successInt = 1
	}
	_, err := s.db.ExecContext(ctx,
		`INSERT INTO webhook_deliveries (payment_id, reference, shopee_tx_id, amount, target_url, status_code, success, error_message, attempt, created_at)
		 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
		rec.PaymentID, rec.Reference, rec.ShopeeTxID, rec.Amount, rec.TargetURL, rec.StatusCode, successInt, rec.ErrorMessage, rec.Attempt, time.Now().UnixMilli())
	return err
}

func (s *SQLStore) ListWebhookLogs(ctx context.Context, limit int) ([]WebhookAuditRecord, error) {
	if limit <= 0 || limit > 100 {
		limit = 50
	}
	rows, err := s.db.QueryContext(ctx,
		`SELECT id, payment_id, reference, shopee_tx_id, amount, target_url, status_code, success, error_message, attempt, created_at
		 FROM webhook_deliveries ORDER BY id DESC LIMIT ?`, limit)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var out []WebhookAuditRecord
	for rows.Next() {
		var r WebhookAuditRecord
		var successInt int
		var createdAtMs int64
		if err := rows.Scan(&r.ID, &r.PaymentID, &r.Reference, &r.ShopeeTxID, &r.Amount, &r.TargetURL, &r.StatusCode, &successInt, &r.ErrorMessage, &r.Attempt, &createdAtMs); err != nil {
			return nil, err
		}
		r.Success = (successInt == 1)
		r.CreatedAt = time.UnixMilli(createdAtMs)
		out = append(out, r)
	}
	return out, rows.Err()
}

func (s *SQLStore) Close() error {
	return s.db.Close()
}
