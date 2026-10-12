# Panduan Deployment GAGE Cloud ke Akun Cloudflare Baru

Panduan resmi untuk mendeploy backend **GAGE Hyperlocal Delivery Cloud** (`gage-cloud`) ke akun Cloudflare baru yang terisolasi 100% dari akun Nusa Kasir.

---

## 1. Persiapan Akun Baru

Pastikan akun Cloudflare baru kamu sudah aktif dan login di browser.

Jalankan perintah ini di terminal (folder `gage/gage-cloud`):

```powershell
cd c:\Users\ertyui\ZCodeProject\gage\gage-cloud
npx.cmd wrangler login
```

Browser akan terbuka otomatis. Login dengan email/password akun Cloudflare barumu, lalu klik **Allow / Authorize**.

---

## 2. Pembuatan Database D1 SQLite Baru

Jalankan perintah untuk membuat database D1 bernama `gage-db`:

```powershell
npx.cmd wrangler d1 create gage-db
```

Output terminal akan menampilkan `database_id` baru, contoh:
```text
[[d1_databases]]
binding = "DB"
database_name = "gage-db"
database_id = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
```

Buka file `wrangler.toml`, lalu ganti baris `database_id` dengan id baru tersebut:

```toml
[[d1_databases]]
binding = "DB"
database_name = "gage-db"
database_id = "PASTE_ID_BARUMU_DI_SINI"
```

---

## 3. Eksekusi Migrasi Database (12 Tabel Otomatis)

Jalankan migrasi skema tabel D1:

```powershell
npx.cmd wrangler d1 execute gage-db --file=migrations/0001_initial_schema.sql --remote
npx.cmd wrangler d1 execute gage-db --file=migrations/0002_real_seed.sql --remote
```

Seluruh 12 tabel dan data awal UMKM (Dimsum Sewu by Halu Goods) akan terpasang otomatis.

---

## 4. Deploy Worker + Durable Object (Live GPS Tracker)

Deploy seluruh backend API ke edge Cloudflare:

```powershell
npx.cmd wrangler deploy
```

Worker akan terbit dengan URL publik, misalnya:
`https://gage-cloud.<subdomain-kamu>.workers.dev`

---

## 5. Verifikasi Endpoint

Cek URL Worker kamu di browser atau terminal:

1. **Healthcheck:**
   `GET https://gage-cloud.<subdomain>.workers.dev/`
2. **Kalkulator Subsidi Ongkir:**
   `POST /api/orders/calculate`
3. **Radar Driver:**
   `GET /api/driver/orders/available`
4. **Order Dapur Merchant:**
   `GET /api/merchant/orders`
5. **Web Tracking Publik (0 D1 write):**
   `https://gage-cloud.<subdomain>.workers.dev/track/ORD-9021`
6. **Web Landing Affiliator:**
   `https://gage-cloud.<subdomain>.workers.dev/c/c-GAGE01`
