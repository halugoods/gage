package main

import (
	"context"
	"flag"
	"log"
	"os"
	"os/signal"
	"path/filepath"
	"syscall"
	"time"

	"gagetway/config"
	"gagetway/gateway"
	"gagetway/server"
	"gagetway/store"
	"gagetway/webhook"
)

func main() {
	cfg := config.Load()

	// Command-line flag overrides
	portFlag := flag.Int("port", cfg.Port, "HTTP server listening port")
	secretFlag := flag.String("secret", cfg.GatewaySecret, "Shared secret for webhook authentication")
	cloudURLFlag := flag.String("cloud", cfg.GageCloudURL, "GAGE Cloud backend base URL")
	dataDirFlag := flag.String("data", cfg.DataDir, "Directory for SQLite store and session state")
	qrisFlag := flag.String("qris", cfg.StaticQRIS, "Default static QRIS payload string")
	flag.Parse()

	cfg.Port = *portFlag
	cfg.GatewaySecret = *secretFlag
	cfg.GageCloudURL = *cloudURLFlag
	cfg.DataDir = *dataDirFlag
	cfg.StaticQRIS = *qrisFlag

	log.Printf("==================================================")
	log.Printf("🚀 Starting GAGE Gateway (ShopeePay & QRIS Daemon)")
	log.Printf("==================================================")
	log.Printf("Port:         %d", cfg.Port)
	log.Printf("Gage Cloud:   %s", cfg.GageCloudURL)
	log.Printf("Data Dir:     %s", cfg.DataDir)
	log.Printf("Poll Interval: %v", cfg.PollInterval)
	if cfg.StaticQRIS != "" {
		log.Printf("Static QRIS:  [Configured (%d bytes)]", len(cfg.StaticQRIS))
	} else {
		log.Printf("Static QRIS:  [Not set; bind via /api/gateway/qris/bind]")
	}

	// 1. Initialize SQLite store
	dbPath := filepath.Join(cfg.DataDir, "gateway.db")
	sqlStore, err := store.OpenSQLStore(dbPath)
	if err != nil {
		log.Fatalf("Failed to initialize SQLite store at %s: %v", dbPath, err)
	}
	defer sqlStore.Close()
	log.Printf("SQLite storage initialized at: %s", dbPath)

	// 2. Initialize Webhook Dispatcher
	dispatcher := webhook.NewDispatcher(cfg.GageCloudURL, cfg.GatewaySecret, sqlStore)

	// 3. Initialize Gateway Manager (Shopee Provider + Polling Engine)
	mgr := gateway.NewManager(sqlStore, dispatcher, cfg.StaticQRIS, cfg.PollInterval)
	defer mgr.Close()

	// 4. Attempt automatic session restoration
	ctxInit, cancelInit := context.WithTimeout(context.Background(), 15*time.Second)
	restored, err := mgr.RestoreSession(ctxInit)
	cancelInit()
	if err != nil {
		log.Printf("[Warning] Failed restoring session: %v", err)
	} else if restored {
		sess := mgr.GetSessionInfo()
		log.Printf("✅ Active session restored: Merchant '%s' (ID: %s, Store: %s)",
			sess.MerchantName, sess.MerchantID, sess.StoreID)
	} else {
		log.Printf("ℹ️ No active session found. Ready for OTP login via /api/gateway/otp/request")
	}

	// 5. Start HTTP REST Server
	srv := server.NewServer(cfg.Port, mgr, sqlStore)
	if err := srv.Start(); err != nil {
		log.Fatalf("Failed to start HTTP server: %v", err)
	}

	// 6. Graceful shutdown handler
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Printf("\nShutting down GAGE Gateway gracefully...")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()

	if err := srv.Stop(shutdownCtx); err != nil {
		log.Printf("Error stopping HTTP server: %v", err)
	}
	_ = mgr.Close()

	log.Printf("GAGE Gateway stopped. Goodbye.")
}
