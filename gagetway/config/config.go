package config

import (
	"bufio"
	"os"
	"strconv"
	"strings"
	"time"
)

// Config represents runtime configuration for the GAGE Payment Gateway.
type Config struct {
	Port          int
	GatewaySecret string
	GageCloudURL  string
	DataDir       string
	PollInterval  time.Duration
	StaticQRIS    string
	LogLevel      string
}

// Load reads configuration from environment variables with fallback defaults,
// and optionally merges variables from an existing .env file.
func Load() *Config {
	loadDotEnv(".env")

	cfg := &Config{
		Port:          getEnvInt("PORT", 8085),
		GatewaySecret: getEnvString("GATEWAY_SECRET", "gage-secret-local-dev-2026"),
		GageCloudURL:  strings.TrimRight(getEnvString("GAGE_CLOUD_URL", "http://localhost:8787"), "/"),
		DataDir:       getEnvString("DATA_DIR", "./data"),
		PollInterval:  getEnvDuration("POLL_INTERVAL_SEC", 5) * time.Second,
		StaticQRIS:    getEnvString("STATIC_QRIS", ""),
		LogLevel:      getEnvString("LOG_LEVEL", "info"),
	}

	return cfg
}

func getEnvString(key, fallback string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return fallback
}

func getEnvDuration(key string, fallbackSeconds int) time.Duration {
	if val := os.Getenv(key); val != "" {
		if sec, err := strconv.Atoi(val); err == nil && sec > 0 {
			return time.Duration(sec)
		}
	}
	return time.Duration(fallbackSeconds)
}

func loadDotEnv(filepath string) {
	file, err := os.Open(filepath)
	if err != nil {
		return
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		parts := strings.SplitN(line, "=", 2)
		if len(parts) == 2 {
			k := strings.TrimSpace(parts[0])
			v := strings.Trim(strings.TrimSpace(parts[1]), `"'`)
			if os.Getenv(k) == "" {
				_ = os.Setenv(k, v)
			}
		}
	}
}
