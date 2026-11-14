# GAGE Gateway (ShopeePay & Dynamic QRIS Settlement Daemon)

A standalone Go service for GAGE that integrates with ShopeePay Merchant QRIS via `github.com/hirotomasato/paygateme`. It monitors live incoming ShopeePay settlements, allocates unique payment amounts, and dispatches authenticated settlement webhooks directly to `gage-cloud`.

---

## Features

1. **Shopee Merchant OTP Authentication**:
   - `POST /api/gateway/otp/request`: Request OTP challenge for phone login.
   - `POST /api/gateway/otp/verify`: Verify OTP challenge and authenticate.
   - `POST /api/gateway/login/complete`: Select store/merchant if multiple exist.
   - `POST /api/gateway/session/refresh`: Silent token refresh without new OTP.
   - `GET /api/gateway/session`: Check live session and merchant status.
   - `POST /api/gateway/logout`: Terminate session and stop polling.

2. **Live Transaction Feed Polling Daemon**:
   - Continuously monitors Shopee merchant settlement feed in the background.
   - Automatic silent token renewal on expiration without interrupting the daemon.
   - Serialized state transitions to avoid race conditions.

3. **Settlement Webhook Dispatch to GAGE Cloud**:
   - When an incoming payment matches an allocated unique amount, the daemon dispatches:
     `POST /api/gateway/settle` to `GAGE_CLOUD_URL`
   - Payload:
     ```json
     {
       "amount": 25042,
       "reference": "ORD-2026-001",
       "shopee_tx_id": "SP_TX_12345678",
       "secret": "<GATEWAY_SECRET>"
     }
     ```
   - Includes retry policy (3 attempts with exponential backoff) and persistent audit logging in SQLite (`webhook_deliveries` table).

4. **Dynamic QRIS Generation**:
   - `POST /api/gateway/qris/bind`: Bind master static QRIS string.
   - `POST /api/gateway/payments/create`: Allocate unique amount & generate dynamic QRIS string + base64 PNG data URL.
   - `GET /api/gateway/payments`: List recent payment intents.
   - `GET /api/gateway/payments/:id`: Get payment status.
   - `POST /api/gateway/payments/:id/cancel`: Cancel pending payment intent.

5. **Storage & Audit**:
   - SQLite-backed store via pure Go `modernc.org/sqlite` (no CGO required).
   - Stored in `<DATA_DIR>/gateway.db`.
   - `GET /api/gateway/webhooks`: Query webhook audit logs.

---

## Configuration

Environment variables (or `.env` file in the gateway root):

| Variable | Default | Description |
|---|---|---|
| `PORT` | `8085` | HTTP listening port |
| `GATEWAY_SECRET` | `gage-secret-local-dev-2026` | Webhook verification secret shared with `gage-cloud` |
| `GAGE_CLOUD_URL` | `http://localhost:8787` | Base URL of `gage-cloud` backend |
| `DATA_DIR` | `./data` | Directory for SQLite database (`gateway.db`) |
| `POLL_INTERVAL_SEC` | `5` | Settlement polling interval in seconds |
| `STATIC_QRIS` | `""` | Master static QRIS string (optional on startup) |

---

## Build & Test

```bash
# Run tests
go test -v ./...

# Build executable
go build -o gage-gateway.exe .

# Run gateway
./gage-gateway.exe -port 8085
```
