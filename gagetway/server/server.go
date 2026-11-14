package server

import (
	"context"
	"fmt"
	"log"
	"net"
	"net/http"
	"time"

	"gagetway/gateway"
	"gagetway/store"
)

type Server struct {
	httpServer *http.Server
	port       int
	listener   net.Listener
}

func NewServer(port int, mgr *gateway.Manager, sqlStore *store.SQLStore) *Server {
	handlers := NewHandlers(mgr, sqlStore)

	mux := http.NewServeMux()

	// CORS wrapper
	withCORS := func(next http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization, X-Gateway-Secret")

			if r.Method == http.MethodOptions {
				w.WriteHeader(http.StatusOK)
				return
			}
			next(w, r)
		}
	}

	// Register routes
	mux.HandleFunc("/health", withCORS(handlers.HandleHealth))
	mux.HandleFunc("/api/health", withCORS(handlers.HandleHealth))

	// Shopee Auth / OTP Endpoints
	mux.HandleFunc("/api/gateway/otp/request", withCORS(handlers.HandleRequestOtp))
	mux.HandleFunc("/api/gateway/otp/verify", withCORS(handlers.HandleVerifyOtp))
	mux.HandleFunc("/api/gateway/login/complete", withCORS(handlers.HandleCompleteLogin))
	mux.HandleFunc("/api/gateway/session/refresh", withCORS(handlers.HandleRefreshSession))
	mux.HandleFunc("/api/gateway/session", withCORS(handlers.HandleGetSession))
	mux.HandleFunc("/api/gateway/logout", withCORS(handlers.HandleLogout))

	// QRIS & Payment Endpoints
	mux.HandleFunc("/api/gateway/qris/bind", withCORS(handlers.HandleBindQRIS))
	mux.HandleFunc("/api/gateway/payments/create", withCORS(handlers.HandleCreatePayment))
	mux.HandleFunc("/api/gateway/payments", withCORS(handlers.HandlePayments))
	mux.HandleFunc("/api/gateway/payments/", withCORS(handlers.HandlePayments))

	// Audit Logs
	mux.HandleFunc("/api/gateway/webhooks", withCORS(handlers.HandleWebhookLogs))

	return &Server{
		port: port,
		httpServer: &http.Server{
			Handler:      mux,
			ReadTimeout:  15 * time.Second,
			WriteTimeout: 20 * time.Second,
		},
	}
}

func (s *Server) Start() error {
	addr := fmt.Sprintf(":%d", s.port)
	ln, err := net.Listen("tcp", addr)
	if err != nil {
		return fmt.Errorf("listen on port %d: %w", s.port, err)
	}
	s.listener = ln

	log.Printf("[Server] GAGE Gateway HTTP server listening on http://127.0.0.1:%d", s.port)
	go func() {
		if err := s.httpServer.Serve(ln); err != nil && err != http.ErrServerClosed {
			log.Fatalf("[Server] HTTP server error: %v", err)
		}
	}()
	return nil
}

func (s *Server) Stop(ctx context.Context) error {
	if s.httpServer != nil {
		return s.httpServer.Shutdown(ctx)
	}
	return nil
}
