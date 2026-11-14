# Handoff Operasional & Arsitektur Gagetway (`gagetway/`)

* **Target Agent**: Agent Pengembang Gateway & Web Admin Gagetway
* **Lokasi Service**: `c:\Users\ertyui\ZCodeProject\gage\gagetway`
* **Port Standar**: `8080` (HTTP REST API)
* **Backend Cloudflare Target**: `http://localhost:8787` (atau domain produksi `gage-cloud`)
* **Secret Shared**: `gage-secret-local-dev-2026` (`GATEWAY_SECRET`)

---

## 1. Latar Belakang & Analisis Modul `ezpzpay` / `paygateme`

Modul `gagetway` dibangun secara mandiri di dalam repositori GAGE, mengadopsi core engine dari `github.com/hirotomasato/paygateme@v0.1.0` (yang sebelumnya digunakan di `ezpzpay`) tanpa membawa ketergantungan rumit `ezpzai`:

1. **Shopee Merchant OTP Authentication**:
   - Berbeda dengan script scrapping web biasa yang memerlukan token statis (`B:xxx`) dari DevTools browser dan sering kadaluarsa, `paygateme` memiliki alur login programmatic Shopee Merchant API:
     - `RequestOtp(phone, channel)`: Mengirim kode OTP via WhatsApp atau SMS.
     - `VerifyOtp(phone, otp, token)`: Menukarkan kode OTP 6 digit menjadi session token Shopee.
     - `RefreshSession()`: Melakukan refresh token otomatis di background tanpa perlu input OTP ulang.
     - `SaveSession()` & `RestoreSession()`: Menyimpan session token ke SQLite (`gagetway.db`) sehingga service dapat di-restart kapan saja tanpa kehilangan sesi login.
2. **Injeksi EMVCo Dynamic QRIS (Tag 54) + Kode Unik**:
   - `paygateme` membedah string QRIS statis merchant, menyuntikkan nominal bayar dinamis (Tag 54) yang telah ditambahkan kode unik 3 digit (misal: nominal `Rp 50.000` menjadi `Rp 50.124`), lalu menghitung ulang CRC16 checksum (Tag 63).
3. **Settlement Polling & Webhook Idempoten**:
   - Daemon feed berjalan setiap 5 detik memanggil Shopee Merchant transaction feed.
   - Begitu mutasi dengan nominal `Rp 50.124` terdeteksi, hook `svc.OnPaid` terpicu dan memanggil `webhook.Dispatcher` untuk menembak `POST /api/gateway/settle` ke `gage-cloud` dengan header `X-Gateway-Secret`.

---

## 2. Cara Menjalankan & Mengakses Gagetway

### A. Prasyarat
- Go 1.22+ terinstal di sistem.
- Tidak memerlukan CGO (menggunakan pure Go SQLite `modernc.org/sqlite`).

### B. Konfigurasi Lingkungan (`.env`)
Di dalam folder `gagetway/.env`:
```env
PORT=8080
GATEWAY_SECRET=gage-secret-local-dev-2026
GAGE_CLOUD_URL=http://127.0.0.1:8787
POLL_INTERVAL=5s
DATA_DIR=.
STATIC_QRIS=00020101021126510013ID.GAGE.WWW01189360091800216174620208151234565204549953033605802ID5922Toko Rejeki Makmur6012Pracimantoro6105551226304D1A2
```

### C. Menjalankan Service
```powershell
Set-Location c:\Users\ertyui\ZCodeProject\gage\gagetway
go run .
```
Atau build binary:
```powershell
go build -o gagetway.exe .
.\gagetway.exe -port 8080
```

### D. Verifikasi Health Endpoint
```bash
curl http://localhost:8080/health
```
Respons:
```json
{
  "status": "ok",
  "service": "gagetway",
  "version": "1.0.0",
  "shopee_session": {
    "logged_in": false,
    "phone": "",
    "store_name": ""
  }
}
```

---

## 3. Daftar Endpoint API Gagetway

| Endpoint | Method | Fungsi |
| :--- | :---: | :--- |
| `/health` | `GET` | Cek status server dan sesi login ShopeePay |
| `/api/gateway/otp/request` | `POST` | Kirim OTP Shopee Merchant (`{"phone_number": "08xxx", "channel": 1}`) |
| `/api/gateway/otp/verify` | `POST` | Verifikasi OTP (`{"phone_number": "08xxx", "otp": "123456"}`) |
| `/api/gateway/session` | `GET` | Ambil detail sesi aktif & daftar toko merchant |
| `/api/gateway/session/refresh`| `POST` | Paksa pembaruan token sesi Shopee |
| `/api/gateway/session/logout` | `POST` | Hapus sesi aktif dari SQLite |
| `/api/gateway/payments/create` | `POST` | Alokasikan kode unik dan generate QRIS dinamis |
| `/api/gateway/qris/bind` | `POST` | Daftarkan/update string QRIS statis merchant |
| `/api/gateway/webhooks` | `GET` | Riwayat 50 pengiriman webhook ke `gage-cloud` |

---

## 4. Backlog Desain Web Admin Ramping (Kloning Ramping `ezpzai` Khusus GAGE)

Agent berikutnya yang menangani portal admin web/gateway dapat membangun antarmuka web minimalis (Single-Page UI berbasis HTML/Tailwind atau Vue/React ringan yang disajikan langsung oleh Go via `http.FileServer` atau port terpisah):

1. **Tab 1: Status Koneksi & Login ShopeePay**:
   - Kartu status: Hijau (Terhubung & Siap) / Abu-abu (Belum Login).
   - Form input Nomor WhatsApp/SMS pemilik merchant ShopeePay.
   - Input 6-digit OTP dengan auto-focus dan tombol verifikasi instan.
2. **Tab 2: Live Feed Transaksi Masuk**:
   - Tabel realtime menampilkan mutasi pembayaran ShopeePay yang masuk dalam 24 jam terakhir.
   - Kolom: Waktu, ID Transaksi Shopee, Nominal Asli, Kode Unik, Referensi GAGE, Status Webhook ke Cloudflare (`DELIVERED` / `RETRYING`).
3. **Tab 3: Simulator & Test Webhook**:
   - Tombol manual test trigger settlement ke `http://localhost:8787/api/gateway/settle` untuk menguji respon aplikasi customer secara lokal tanpa harus transfer uang nyata.
