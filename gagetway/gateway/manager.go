package gateway

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"sync"
	"time"

	"github.com/hirotomasato/paygateme/core"
	"github.com/hirotomasato/paygateme/shopee"
	"github.com/hirotomasato/paygateme/utils"

	"gagetway/store"
	"gagetway/webhook"
)

// OtpResponse is the result of requesting a Shopee OTP.
type OtpResponse struct {
	PhoneNumber string `json:"phone_number"`
	Channel     int    `json:"channel"`
	HasPassword bool   `json:"has_password"`
}

// MerchantSummary represents an accessible merchant for the account.
type MerchantSummary struct {
	ID     string `json:"id"`
	Name   string `json:"name"`
	Status int    `json:"status"`
}

// StoreSummary represents an accessible store/branch.
type StoreSummary struct {
	ID   string `json:"id"`
	Name string `json:"name"`
}

// VerifyLoginOutcome is the result of verifying an OTP.
type VerifyLoginOutcome struct {
	Status       string            `json:"status"` // "complete" or "merchant-selection-required"
	MerchantID   string            `json:"merchant_id,omitempty"`
	MerchantName string            `json:"merchant_name,omitempty"`
	StoreID      string            `json:"store_id,omitempty"`
	Merchants    []MerchantSummary `json:"merchants,omitempty"`
}

// CompleteLoginResult is returned after explicitly picking merchant/store.
type CompleteLoginResult struct {
	Status       string `json:"status"`
	MerchantID   string `json:"merchant_id"`
	MerchantName string `json:"merchant_name"`
	StoreID      string `json:"store_id"`
}

// SessionInfo provides public session status.
type SessionInfo struct {
	LoggedIn     bool   `json:"logged_in"`
	MerchantID   string `json:"merchant_id,omitempty"`
	MerchantName string `json:"merchant_name,omitempty"`
	StoreID      string `json:"store_id,omitempty"`
	NeedsRelogin bool   `json:"needs_relogin"`
	StaticQRIS   bool   `json:"static_qris_bound"`
	Polling      bool   `json:"polling_active"`
}

// PaymentSummary is the API representation of a payment intent.
type PaymentSummary struct {
	ID           string `json:"id"`
	BaseAmount   int64  `json:"base_amount"`
	UniqueAmount int64  `json:"unique_amount"`
	Status       string `json:"status"`
	Reference    string `json:"reference"`
	QRString     string `json:"qr_string"`
	CreatedAt    int64  `json:"created_at"`
	ExpiresAt    int64  `json:"expires_at"`
	ShopeeTxID   string `json:"shopee_tx_id,omitempty"`
}

// Manager orchestrates Shopee authentication, payment service, and webhook dispatching.
type Manager struct {
	mu           sync.Mutex
	store        *store.SQLStore
	dispatcher   *webhook.Dispatcher
	provider     *shopee.Provider
	started      bool
	staticQRIS   string
	pollInterval time.Duration

	// Intermediate login challenges
	challenge    *shopee.OtpChallenge
	verification *shopee.OtpVerification
}

// NewManager initializes the gateway manager.
func NewManager(sqlStore *store.SQLStore, dispatcher *webhook.Dispatcher, defaultStaticQRIS string, pollInterval time.Duration) *Manager {
	if pollInterval <= 0 {
		pollInterval = 5 * time.Second
	}
	return &Manager{
		store:        sqlStore,
		dispatcher:   dispatcher,
		staticQRIS:   defaultStaticQRIS,
		pollInterval: pollInterval,
	}
}

// newProvider constructs a ShopeeProvider wired to the SQL store.
func (m *Manager) newProvider(session *shopee.Session) *shopee.Provider {
	return shopee.NewProvider(shopee.ProviderConfig{
		Session:      session,
		Store:        m.store,
		StaticQris:   m.staticQRIS,
		DeviceReport: shopee.DeviceRiskBlob,
		PollInterval: m.pollInterval.Milliseconds(),
		Logger:       utils.NewConsoleLogger(utils.LevelInfo),
		OnSessionUpdated: func(s shopee.Session) error {
			data, err := json.Marshal(s)
			if err != nil {
				return err
			}
			return m.store.SaveSession(context.Background(), "shopee", s.AccountID, data)
		},
	})
}

// RequestOtp sends an OTP challenge to the given phone number.
func (m *Manager) RequestOtp(ctx context.Context, phone, password string) (*OtpResponse, error) {
	p := m.newProvider(nil)

	challenge, err := p.RequestOtp(ctx, phone, shopee.OtpRequestOptions{
		Password: password,
	})
	if err != nil {
		return nil, fmt.Errorf("request OTP failed: %w", err)
	}

	m.mu.Lock()
	m.provider = p
	m.challenge = challenge
	m.verification = nil
	m.mu.Unlock()

	return &OtpResponse{
		PhoneNumber: challenge.PhoneNumber,
		Channel:     challenge.Channel,
		HasPassword: challenge.HasPassword,
	}, nil
}

// VerifyOtp completes the OTP verification step.
func (m *Manager) VerifyOtp(ctx context.Context, otp string) (*VerifyLoginOutcome, error) {
	m.mu.Lock()
	challenge := m.challenge
	provider := m.provider
	m.mu.Unlock()

	if challenge == nil || provider == nil {
		return nil, fmt.Errorf("no pending OTP challenge; call RequestOtp first")
	}

	outcome, err := provider.LoginWithOtp(ctx, shopee.LoginWithOtpInput{
		Challenge: *challenge,
		OTP:       otp,
	})
	if err != nil {
		return nil, fmt.Errorf("verify OTP failed: %w", err)
	}

	m.mu.Lock()
	m.challenge = nil
	m.mu.Unlock()

	result := &VerifyLoginOutcome{Status: string(outcome.Status)}

	switch outcome.Status {
	case shopee.LoginComplete:
		result.MerchantID = outcome.Session.Merchant.ID
		result.MerchantName = outcome.Session.Merchant.Name
		result.StoreID = outcome.Session.StoreID

		sessionJSON, _ := json.Marshal(outcome.Session)
		_ = m.store.SaveSession(ctx, "shopee", outcome.Session.AccountID, sessionJSON)

		// Auto-bind default QRIS if configured
		if m.staticQRIS != "" {
			_ = provider.SetStaticQris(m.staticQRIS)
		}

		m.startService()

	case shopee.LoginMerchantSelectionNeeded:
		m.mu.Lock()
		m.verification = outcome.Verification
		m.mu.Unlock()

		merchants := make([]MerchantSummary, len(outcome.Merchants))
		for i, mch := range outcome.Merchants {
			merchants[i] = MerchantSummary{
				ID:     mch.ID,
				Name:   mch.Name,
				Status: mch.Status,
			}
		}
		result.Merchants = merchants
	}

	return result, nil
}

// CompleteLogin resolves merchant and store selection if multiple were returned.
func (m *Manager) CompleteLogin(ctx context.Context, merchantID, storeID string) (*CompleteLoginResult, error) {
	m.mu.Lock()
	verification := m.verification
	provider := m.provider
	m.mu.Unlock()

	if verification == nil || provider == nil {
		return nil, fmt.Errorf("no pending merchant verification; call VerifyOtp first")
	}

	session, err := provider.CompleteLogin(ctx, shopee.CompleteLoginInput{
		Verification: *verification,
		MerchantID:   merchantID,
		StoreID:      storeID,
	})
	if err != nil {
		return nil, fmt.Errorf("complete login failed: %w", err)
	}

	m.mu.Lock()
	m.verification = nil
	m.mu.Unlock()

	sessionJSON, _ := json.Marshal(session)
	_ = m.store.SaveSession(ctx, "shopee", session.AccountID, sessionJSON)

	if m.staticQRIS != "" {
		_ = provider.SetStaticQris(m.staticQRIS)
	}

	m.startService()

	return &CompleteLoginResult{
		Status:       "complete",
		MerchantID:   session.Merchant.ID,
		MerchantName: session.Merchant.Name,
		StoreID:      session.StoreID,
	}, nil
}

// RefreshSession renews the merchant session token silently without an OTP.
func (m *Manager) RefreshSession(ctx context.Context) (*SessionInfo, error) {
	m.mu.Lock()
	provider := m.provider
	m.mu.Unlock()

	if provider == nil {
		// Attempt restore from DB
		restored, err := m.RestoreSession(ctx)
		if err != nil || !restored {
			return &SessionInfo{LoggedIn: false, NeedsRelogin: true}, fmt.Errorf("no session to refresh; login required")
		}
		m.mu.Lock()
		provider = m.provider
		m.mu.Unlock()
	}

	refreshed, err := provider.RefreshSession(ctx)
	if err != nil || refreshed == nil {
		m.mu.Lock()
		m.stopServiceLocked()
		m.provider = nil
		m.started = false
		m.mu.Unlock()
		return &SessionInfo{LoggedIn: false, NeedsRelogin: true}, fmt.Errorf("silent refresh failed: %w", err)
	}

	// Persist refreshed session
	sessionJSON, _ := json.Marshal(refreshed)
	_ = m.store.SaveSession(ctx, "shopee", refreshed.AccountID, sessionJSON)

	// Restart service with fresh credentials
	m.mu.Lock()
	m.stopServiceLocked()
	m.started = false
	m.mu.Unlock()
	m.startService()

	return m.GetSessionInfo(), nil
}

// RestoreSession loads the latest saved session from SQLite and resumes service if valid.
func (m *Manager) RestoreSession(ctx context.Context) (bool, error) {
	raw, err := m.store.LoadLatestSession(ctx, "shopee")
	if err != nil || raw == nil {
		return false, nil
	}

	var session shopee.Session
	if err := json.Unmarshal(raw, &session); err != nil {
		return false, fmt.Errorf("unmarshal stored session: %w", err)
	}

	p := m.newProvider(&session)
	m.mu.Lock()
	m.provider = p
	m.mu.Unlock()

	if !p.Authenticated() {
		// Attempt automatic silent refresh
		log.Printf("[Gateway] Session expired in storage, attempting silent token refresh...")
		refreshed, refErr := p.RefreshSession(ctx)
		if refErr != nil || refreshed == nil {
			log.Printf("[Gateway] Silent refresh failed: %v", refErr)
			return false, nil
		}
		data, _ := json.Marshal(refreshed)
		_ = m.store.SaveSession(ctx, "shopee", refreshed.AccountID, data)
	}

	if m.staticQRIS != "" {
		_ = p.SetStaticQris(m.staticQRIS)
	}

	m.startService()
	log.Printf("[Gateway] Restored Shopee session for merchant %s (ID: %s, Store: %s)",
		session.Merchant.Name, session.Merchant.ID, session.StoreID)
	return true, nil
}

// GetSessionInfo checks the live authentication status.
func (m *Manager) GetSessionInfo() *SessionInfo {
	m.mu.Lock()
	provider := m.provider
	started := m.started
	m.mu.Unlock()

	if provider == nil {
		return &SessionInfo{LoggedIn: false}
	}

	if !provider.Authenticated() {
		return &SessionInfo{LoggedIn: false, NeedsRelogin: true}
	}

	session := provider.ExportSession()
	if session == nil {
		return &SessionInfo{LoggedIn: false}
	}

	return &SessionInfo{
		LoggedIn:     true,
		MerchantID:   session.Merchant.ID,
		MerchantName: session.Merchant.Name,
		StoreID:      session.StoreID,
		NeedsRelogin: false,
		StaticQRIS:   provider.StaticQris() != "",
		Polling:      started,
	}
}

// HasSession reports if the provider is authenticated.
func (m *Manager) HasSession() bool {
	m.mu.Lock()
	defer m.mu.Unlock()
	return m.provider != nil && m.provider.Authenticated()
}

// Logout terminates session and stops background polling.
func (m *Manager) Logout(ctx context.Context) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.stopServiceLocked()

	if m.provider != nil {
		if scope := m.provider.GetPaymentScope(); scope != nil {
			_ = m.store.DeleteSession(ctx, scope.Provider, scope.AccountID)
		}
	}
	m.provider = nil
	m.challenge = nil
	m.verification = nil
	m.started = false
	return nil
}

// --- Live Settlement Polling Daemon & Webhook Dispatch ---

func (m *Manager) startService() {
	m.mu.Lock()
	provider := m.provider
	if m.started || provider == nil {
		m.mu.Unlock()
		return
	}
	m.started = true
	m.mu.Unlock()

	svc, err := provider.Payments()
	if err != nil {
		log.Printf("[Gateway] Failed to initialize payment service: %v", err)
		m.mu.Lock()
		m.started = false
		m.mu.Unlock()
		return
	}

	// Propagate static QRIS if configured
	if m.staticQRIS != "" {
		svc.SetStaticQris(m.staticQRIS)
	}

	// 1. Settlement event handler
	svc.OnPaid(func(p core.Payment) {
		shopeeTxID := p.ID
		if p.Transaction != nil && p.Transaction.ID != "" {
			shopeeTxID = p.Transaction.ID
		}

		settledAmount := p.UniqueAmount
		if settledAmount <= 0 {
			settledAmount = p.BaseAmount
		}

		log.Printf("[Settlement] Match detected! ID=%s, Ref=%s, Amount=%d, ShopeeTx=%s",
			p.ID, p.Reference, settledAmount, shopeeTxID)

		// Dispatch secure webhook to gage-cloud: POST /api/gateway/settle
		go func(payID string, amount int64, ref, txID string) {
			ctx, cancel := context.WithTimeout(context.Background(), 45*time.Second)
			defer cancel()

			if err := m.dispatcher.DispatchSettlement(ctx, payID, amount, ref, txID); err != nil {
				log.Printf("[Settlement] CRITICAL: Webhook delivery failed for ref=%s: %v", ref, err)
			}
		}(p.ID, settledAmount, p.Reference, shopeeTxID)
	})

	// 2. Expiry handler
	svc.OnExpired(func(p core.Payment) {
		log.Printf("[Settlement] Payment expired: ID=%s, Ref=%s, UniqueAmount=%d",
			p.ID, p.Reference, p.UniqueAmount)
	})

	// 3. Error handler
	svc.OnError(func(err error) {
		log.Printf("[Gateway] Payment polling engine error: %v", err)
	})

	// Start the background polling daemon
	log.Printf("[Gateway] Starting Shopee transaction feed polling daemon...")
	svc.Start()
}

func (m *Manager) stopServiceLocked() {
	if m.provider == nil {
		return
	}
	if svc, err := m.provider.Payments(); err == nil && svc != nil {
		svc.Stop()
		log.Printf("[Gateway] Stopped transaction polling daemon")
	}
}

// --- Dynamic QRIS Payments ---

// SetStaticQris binds a static QRIS string to the provider and active service.
func (m *Manager) SetStaticQris(payload string) error {
	m.mu.Lock()
	defer m.mu.Unlock()

	m.staticQRIS = payload
	if m.provider != nil {
		if err := m.provider.SetStaticQris(payload); err != nil {
			return err
		}
		if svc, err := m.provider.Payments(); err == nil && svc != nil {
			svc.SetStaticQris(payload)
		}
	}
	return nil
}

// CreatePayment creates a payment intent with an allocated unique amount and dynamic QRIS.
func (m *Manager) CreatePayment(ctx context.Context, amount int64, reference string) (*PaymentSummary, error) {
	m.mu.Lock()
	provider := m.provider
	m.mu.Unlock()

	if provider == nil || !provider.Authenticated() {
		return nil, fmt.Errorf("no authenticated Shopee session; login required")
	}

	p, err := provider.CreatePayment(ctx, amount, reference)
	if err != nil {
		return nil, fmt.Errorf("create payment: %w", err)
	}

	return toPaymentSummary(p), nil
}

// GetPayment retrieves a payment record by ID.
func (m *Manager) GetPayment(ctx context.Context, id string) (*PaymentSummary, error) {
	p, err := m.store.Get(ctx, id)
	if err != nil {
		return nil, err
	}
	if p == nil {
		return nil, nil
	}
	return toPaymentSummary(p), nil
}

// ListPayments returns recent payments.
func (m *Manager) ListPayments(ctx context.Context, limit int) ([]PaymentSummary, error) {
	list, err := m.store.ListAll(ctx, limit)
	if err != nil {
		return nil, err
	}
	out := make([]PaymentSummary, len(list))
	for i := range list {
		out[i] = *toPaymentSummary(&list[i])
	}
	return out, nil
}

// CancelPayment cancels a pending payment intent.
func (m *Manager) CancelPayment(ctx context.Context, id string) error {
	m.mu.Lock()
	provider := m.provider
	m.mu.Unlock()

	if provider == nil {
		return fmt.Errorf("no active Shopee session")
	}

	_, err := provider.CancelPayment(ctx, id)
	return err
}

// Close shuts down the manager cleanly.
func (m *Manager) Close() error {
	m.mu.Lock()
	m.stopServiceLocked()
	m.mu.Unlock()
	return m.store.Close()
}

func toPaymentSummary(p *core.Payment) *PaymentSummary {
	if p == nil {
		return nil
	}
	shopeeTxID := ""
	if p.Transaction != nil {
		shopeeTxID = p.Transaction.ID
	}
	return &PaymentSummary{
		ID:           p.ID,
		BaseAmount:   p.BaseAmount,
		UniqueAmount: p.UniqueAmount,
		Status:       string(p.Status),
		Reference:    p.Reference,
		QRString:     p.QRString,
		CreatedAt:    p.CreatedAt.UnixMilli(),
		ExpiresAt:    p.ExpiresAt.UnixMilli(),
		ShopeeTxID:   shopeeTxID,
	}
}
