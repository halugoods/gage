package config

import (
	"os"
	"testing"
	"time"
)

func TestLoadDefaults(t *testing.T) {
	os.Clearenv()
	cfg := Load()

	if cfg.Port != 8085 {
		t.Errorf("expected default port 8085, got %d", cfg.Port)
	}
	if cfg.GatewaySecret != "gage-secret-local-dev-2026" {
		t.Errorf("unexpected default secret %s", cfg.GatewaySecret)
	}
	if cfg.GageCloudURL != "http://localhost:8787" {
		t.Errorf("unexpected default cloud url %s", cfg.GageCloudURL)
	}
	if cfg.PollInterval != 5*time.Second {
		t.Errorf("unexpected default poll interval %v", cfg.PollInterval)
	}
}

func TestEnvOverrides(t *testing.T) {
	os.Setenv("PORT", "9090")
	os.Setenv("GATEWAY_SECRET", "custom-secret-123")
	os.Setenv("GAGE_CLOUD_URL", "https://cloud.gage.id/")
	os.Setenv("POLL_INTERVAL_SEC", "10")
	defer os.Clearenv()

	cfg := Load()
	if cfg.Port != 9090 {
		t.Errorf("expected port 9090, got %d", cfg.Port)
	}
	if cfg.GatewaySecret != "custom-secret-123" {
		t.Errorf("expected secret custom-secret-123, got %s", cfg.GatewaySecret)
	}
	if cfg.GageCloudURL != "https://cloud.gage.id" {
		t.Errorf("expected cloud URL https://cloud.gage.id, got %s", cfg.GageCloudURL)
	}
	if cfg.PollInterval != 10*time.Second {
		t.Errorf("expected poll interval 10s, got %v", cfg.PollInterval)
	}
}
