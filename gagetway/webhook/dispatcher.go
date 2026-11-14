package webhook

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	"gagetway/store"
)

// SettlementPayload matches the exact required JSON contract for gage-cloud:
// POST /api/gateway/settle
// { "amount": <amount>, "reference": <ref>, "shopee_tx_id": <id>, "secret": <GATEWAY_SECRET> }
type SettlementPayload struct {
	Amount     int64  `json:"amount"`
	Reference  string `json:"reference"`
	ShopeeTxID string `json:"shopee_tx_id"`
	Secret     string `json:"secret"`
}

// Dispatcher manages secure webhook dispatches to gage-cloud.
type Dispatcher struct {
	targetURL string
	secret    string
	store     *store.SQLStore
	client    *http.Client
}

// NewDispatcher constructs a webhook dispatcher for gage-cloud.
func NewDispatcher(cloudBaseURL, secret string, sqlStore *store.SQLStore) *Dispatcher {
	cleanURL := fmt.Sprintf("%s/api/gateway/settle", cloudBaseURL)
	return &Dispatcher{
		targetURL: cleanURL,
		secret:    secret,
		store:     sqlStore,
		client: &http.Client{
			Timeout: 12 * time.Second,
		},
	}
}

// DispatchSettlement sends the settlement event to gage-cloud with retries and audit logging.
func (d *Dispatcher) DispatchSettlement(ctx context.Context, paymentID string, amount int64, reference, shopeeTxID string) error {
	payload := SettlementPayload{
		Amount:     amount,
		Reference:  reference,
		ShopeeTxID: shopeeTxID,
		Secret:     d.secret,
	}

	bodyBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("marshal settlement payload: %w", err)
	}

	maxAttempts := 3
	var lastErr error

	for attempt := 1; attempt <= maxAttempts; attempt++ {
		req, err := http.NewRequestWithContext(ctx, http.MethodPost, d.targetURL, bytes.NewReader(bodyBytes))
		if err != nil {
			return fmt.Errorf("create webhook request: %w", err)
		}

		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("User-Agent", "GAGE-Gateway/1.0")
		req.Header.Set("X-Gateway-Secret", d.secret)

		log.Printf("[Webhook] Dispatching settlement to %s (attempt %d/%d) for ref=%s, amount=%d, shopee_tx=%s",
			d.targetURL, attempt, maxAttempts, reference, amount, shopeeTxID)

		resp, err := d.client.Do(req)
		statusCode := 0
		var respBody string

		if err == nil {
			statusCode = resp.StatusCode
			b, _ := io.ReadAll(resp.Body)
			_ = resp.Body.Close()
			respBody = string(b)
		}

		success := (err == nil && statusCode >= 200 && statusCode < 300)
		errMsg := ""
		if err != nil {
			errMsg = err.Error()
			lastErr = err
		} else if !success {
			errMsg = fmt.Sprintf("HTTP %d: %s", statusCode, respBody)
			lastErr = fmt.Errorf("webhook responded with status %d: %s", statusCode, respBody)
		}

		// Record audit log
		if d.store != nil {
			_ = d.store.RecordWebhookLog(context.Background(), store.WebhookAuditRecord{
				PaymentID:    paymentID,
				Reference:    reference,
				ShopeeTxID:   shopeeTxID,
				Amount:       amount,
				TargetURL:    d.targetURL,
				StatusCode:   statusCode,
				Success:      success,
				ErrorMessage: errMsg,
				Attempt:      attempt,
			})
		}

		if success {
			log.Printf("[Webhook] Successfully delivered settlement for ref=%s (status %d)", reference, statusCode)
			return nil
		}

		log.Printf("[Webhook] Attempt %d failed for ref=%s: %v", attempt, reference, errMsg)

		// Don't sleep after the last attempt or if context was cancelled
		if attempt < maxAttempts {
			select {
			case <-ctx.Done():
				return ctx.Err()
			case <-time.After(time.Duration(attempt) * 1500 * time.Millisecond):
			}
		}
	}

	return fmt.Errorf("all %d webhook delivery attempts failed: %w", maxAttempts, lastErr)
}
