package server

import (
	"encoding/base64"
	"encoding/json"
	"fmt"
	"net/http"
	"strconv"
	"strings"

	"github.com/skip2/go-qrcode"

	"gagetway/gateway"
	"gagetway/store"
)

type ServerHandlers struct {
	mgr   *gateway.Manager
	store *store.SQLStore
}

func NewHandlers(mgr *gateway.Manager, store *store.SQLStore) *ServerHandlers {
	return &ServerHandlers{
		mgr:   mgr,
		store: store,
	}
}

// JSON response helpers
func respondJSON(w http.ResponseWriter, status int, data any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(data)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]any{
		"success": false,
		"error":   message,
	})
}

func respondSuccess(w http.ResponseWriter, data any) {
	respondJSON(w, http.StatusOK, map[string]any{
		"success": true,
		"data":    data,
	})
}

// HandleHealth reports service readiness and session state.
func (h *ServerHandlers) HandleHealth(w http.ResponseWriter, r *http.Request) {
	session := h.mgr.GetSessionInfo()
	respondJSON(w, http.StatusOK, map[string]any{
		"status":         "ok",
		"service":        "gagetway",
		"version":        "1.0.0",
		"shopee_session": session,
	})
}

// HandleRequestOtp initiates OTP login.
// POST /api/gateway/otp/request {"phone": "08xxx", "password": "optional"}
func (h *ServerHandlers) HandleRequestOtp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req struct {
		Phone    string `json:"phone"`
		Password string `json:"password"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Phone) == "" {
		respondError(w, http.StatusBadRequest, "Invalid request: 'phone' is required")
		return
	}

	resp, err := h.mgr.RequestOtp(r.Context(), req.Phone, req.Password)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	respondSuccess(w, resp)
}

// HandleVerifyOtp completes OTP verification.
// POST /api/gateway/otp/verify {"otp": "123456"}
func (h *ServerHandlers) HandleVerifyOtp(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req struct {
		OTP string `json:"otp"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.OTP) == "" {
		respondError(w, http.StatusBadRequest, "Invalid request: 'otp' is required")
		return
	}

	outcome, err := h.mgr.VerifyOtp(r.Context(), strings.TrimSpace(req.OTP))
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	respondSuccess(w, outcome)
}

// HandleCompleteLogin completes multi-merchant store selection.
// POST /api/gateway/login/complete {"merchant_id": "...", "store_id": "..."}
func (h *ServerHandlers) HandleCompleteLogin(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req struct {
		MerchantID string `json:"merchant_id"`
		StoreID    string `json:"store_id"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.MerchantID == "" {
		respondError(w, http.StatusBadRequest, "Invalid request: 'merchant_id' is required")
		return
	}

	result, err := h.mgr.CompleteLogin(r.Context(), req.MerchantID, req.StoreID)
	if err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	respondSuccess(w, result)
}

// HandleRefreshSession forces silent session token renewal.
// POST /api/gateway/session/refresh
func (h *ServerHandlers) HandleRefreshSession(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	session, err := h.mgr.RefreshSession(r.Context())
	if err != nil {
		respondJSON(w, http.StatusUnauthorized, map[string]any{
			"success": false,
			"error":   err.Error(),
			"session": session,
		})
		return
	}

	respondSuccess(w, session)
}

// HandleGetSession returns current session info.
// GET /api/gateway/session
func (h *ServerHandlers) HandleGetSession(w http.ResponseWriter, r *http.Request) {
	respondSuccess(w, h.mgr.GetSessionInfo())
}

// HandleLogout discards active session and stops polling.
// POST /api/gateway/logout
func (h *ServerHandlers) HandleLogout(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	_ = h.mgr.Logout(r.Context())
	respondSuccess(w, map[string]string{"message": "Logged out successfully"})
}

// HandleBindQRIS sets the static QRIS payload.
// POST /api/gateway/qris/bind {"payload": "..."}
func (h *ServerHandlers) HandleBindQRIS(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req struct {
		Payload string `json:"payload"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || strings.TrimSpace(req.Payload) == "" {
		respondError(w, http.StatusBadRequest, "Invalid request: 'payload' is required")
		return
	}

	if err := h.mgr.SetStaticQris(strings.TrimSpace(req.Payload)); err != nil {
		respondError(w, http.StatusBadRequest, err.Error())
		return
	}

	respondSuccess(w, map[string]string{"message": "Static QRIS bound successfully"})
}

// HandleCreatePayment creates dynamic QRIS payment intent.
// POST /api/gateway/payments/create {"amount": 25000, "reference": "ORDER-123"}
func (h *ServerHandlers) HandleCreatePayment(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req struct {
		Amount    int64  `json:"amount"`
		Reference string `json:"reference"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Amount <= 0 {
		respondError(w, http.StatusBadRequest, "Invalid request: 'amount' must be greater than 0")
		return
	}

	summary, err := h.mgr.CreatePayment(r.Context(), req.Amount, req.Reference)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}

	// Generate QR Code PNG Base64 data URI
	var qrDataURI string
	if summary.QRString != "" {
		if pngBytes, err := qrcode.Encode(summary.QRString, qrcode.Medium, 256); err == nil {
			qrDataURI = fmt.Sprintf("data:image/png;base64,%s", base64.StdEncoding.EncodeToString(pngBytes))
		}
	}

	respondSuccess(w, map[string]any{
		"payment":     summary,
		"qr_data_uri": qrDataURI,
	})
}

// HandlePayments handles listing or getting payments.
// GET /api/gateway/payments
// GET /api/gateway/payments/{id}
func (h *ServerHandlers) HandlePayments(w http.ResponseWriter, r *http.Request) {
	path := strings.TrimPrefix(r.URL.Path, "/api/gateway/payments")
	path = strings.TrimPrefix(path, "/")

	if path == "" {
		// List recent payments
		limitStr := r.URL.Query().Get("limit")
		limit := 50
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
			limit = l
		}
		list, err := h.mgr.ListPayments(r.Context(), limit)
		if err != nil {
			respondError(w, http.StatusInternalServerError, err.Error())
			return
		}
		respondSuccess(w, list)
		return
	}

	// Sub-paths: {id} or {id}/cancel
	parts := strings.Split(path, "/")
	id := parts[0]

	if len(parts) > 1 && parts[1] == "cancel" {
		if r.Method != http.MethodPost {
			respondError(w, http.StatusMethodNotAllowed, "Method not allowed")
			return
		}
		if err := h.mgr.CancelPayment(r.Context(), id); err != nil {
			respondError(w, http.StatusInternalServerError, err.Error())
			return
		}
		respondSuccess(w, map[string]string{"message": "Payment cancelled successfully"})
		return
	}

	// Get single payment
	summary, err := h.mgr.GetPayment(r.Context(), id)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}
	if summary == nil {
		respondError(w, http.StatusNotFound, "Payment not found")
		return
	}
	respondSuccess(w, summary)
}

// HandleWebhookLogs returns audit records of webhook dispatches to gage-cloud.
// GET /api/gateway/webhooks?limit=50
func (h *ServerHandlers) HandleWebhookLogs(w http.ResponseWriter, r *http.Request) {
	limitStr := r.URL.Query().Get("limit")
	limit := 50
	if l, err := strconv.Atoi(limitStr); err == nil && l > 0 {
		limit = l
	}

	logs, err := h.store.ListWebhookLogs(r.Context(), limit)
	if err != nil {
		respondError(w, http.StatusInternalServerError, err.Error())
		return
	}
	respondSuccess(w, logs)
}
