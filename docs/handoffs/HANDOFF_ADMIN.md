# Handoff Kontrak & Backlog Portal Admin (+ Skema Backend D1)

* **Target Agent Session ID**: `09b47b70-e6b6-4961-8c34-8f1b47e6f7d6`
* **Panduan Visual Wajib**: [`GAGE_FRONTEND_UI_STYLE_GUIDE.md`](../../GAGE_FRONTEND_UI_STYLE_GUIDE.md) & [`AGENTS.md`](../../AGENTS.md)
* **Referensi Batas Portal**: [`PORTAL_BOUNDARIES.md`](../../PORTAL_BOUNDARIES.md)
* **Tanggal Handoff**: `2026-11-12`

> Dokumen ini berisi temuan drift UI di Portal Admin, spesifikasi modul Admin Dynamic Voucher & Sync Tarif, serta skema lengkap migrasi Cloudflare D1 + endpoint Hono (`gage-cloud`) untuk menutup seluruh celah integrasi lintas 4 portal.

---

## 1. Inventaris File Portal Admin Saat Ini

* Root & Navigasi: [`admin_root_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_root_screen.dart), [`admin_bottom_nav_bar.dart`](../../gage-app/lib/features/admin/presentation/widgets/admin_bottom_nav_bar.dart)
* Dashboard & Radar: [`admin_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_screen.dart), [`admin_financial_dashboard_tab.dart`](../../gage-app/lib/features/admin/presentation/tabs/admin_financial_dashboard_tab.dart), [`admin_order_radar_tab.dart`](../../gage-app/lib/features/admin/presentation/tabs/admin_order_radar_tab.dart)
* Kurasi & Banner: [`admin_curation_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_curation_screen.dart), [`admin_banner_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_banner_screen.dart), [`admin_curation_banner_tab.dart`](../../gage-app/lib/features/admin/presentation/tabs/admin_curation_banner_tab.dart)
* Tarif & Dispatch: [`admin_tariff_tab.dart`](../../gage-app/lib/features/admin/presentation/tabs/admin_tariff_tab.dart), [`admin_settings_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_settings_screen.dart), [`admin_order_dispatch_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_order_dispatch_screen.dart), [`tariff_edit_bottom_sheet.dart`](../../gage-app/lib/features/admin/presentation/widgets/tariff_edit_bottom_sheet.dart)
* WhatsApp Center & Preview: [`admin_whatsapp_center_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_whatsapp_center_screen.dart), [`portal_interactive_preview_screen.dart`](../../gage-app/lib/features/admin/presentation/portal_interactive_preview_screen.dart)

---

## 2. Audit Drift UI Kritis di Portal Admin

1. **Kotak Rounded pada Segmented Switch di [`admin_curation_screen.dart`](../../gage-app/lib/features/admin/presentation/admin_curation_screen.dart#L167-L230)**:
   * **Temuan Aktual**: `// Segmented Top Switcher (BaBe vs Mitra Toko)` masih menggunakan `BorderRadius.circular(12)` di outer container dan `BorderRadius.circular(10)` pada opsi aktif.
   * **Aksi Wajib**: Ubah outer track dan active thumb menjadi kapsul penuh **`BorderRadius.circular(999)`**, active thumb warna **`GageTheme.primary` (`#E52320`)** dengan teks putih tebal (`Colors.white`), outer track `#F1F5F9` / `#0F172A` (`EdgeInsets.all(4)`), dan picu `HapticFeedback.selectionClick()`.
2. **Audit Kebersihan Data Produksi & UI**:
   - Pastikan seluruh grafik/stat contoh dan radar simulasi dikunci di belakang `GageApiClient.useDevSeedData`.
   - Dilarang menambah banner promosi internal di Portal Admin.

---

## 3. Backlog Fitur Baru: Voucher Dinamis Terpusat & Sinkronisasi Tarif

### A. Manajemen Voucher Terpusat (`PromoScreen` & `VoucherSelectionScreen`)
* Pembuatan voucher terpusat berada di **Portal Admin** agar setiap voucher langsung berlaku lintas layanan tanpa kode terpisah per portal.
* Referensi client Customer:
  - [`gage_voucher_data.dart`](../../gage-app/lib/data/mock/gage_voucher_data.dart)
  - [`promo_screen.dart`](../../gage-app/lib/features/home/presentation/promo_screen.dart)
  - [`checkout_screen.dart`](../../gage-app/lib/features/checkout/presentation/checkout_screen.dart) & [`voucher_selection_screen.dart`](../../gage-app/lib/features/voucher/presentation/voucher_selection_screen.dart)
* **Arsitektur Sync yang Wajib Dibangun**:
  - Tambahkan service terpusat baru (mis. `gage-app/lib/core/services/voucher_manager_service.dart`) yang mengambil `GET /api/vouchers` + menyimpan override/cache lokal `SharedPreferences`, dengan fallback ke `GageVoucherData.allVouchers` **hanya** bila `GageApiClient.useDevSeedData == true`.
  - Buat UI **Kelola Voucher** di Portal Admin (`admin_curation_banner_tab.dart` atau `admin_settings_screen.dart`) untuk CRUD voucher via `POST/PUT /api/admin/vouchers` tanpa mengimpor `features/home/` atau `shared/` secara terlarang.
* **Aturan Stacking dengan Harga Coret Merchant**:
  - Produk dengan Harga Coret masuk ke keranjang memakai `promo_price`. Customer mengizinkan stacking Harga Coret dengan Voucher Ongkir (`type == 'delivery'`) maupun Voucher Belanja (`type == 'order'`) selama subtotal harga promo memenuhi `min_order`.

### B. Publikasi Tarif Dinamis Admin (`GagePricingService`)
* Saat ini `GagePricingService.saveAdminPricingConfig` hanya menyimpan ke `SharedPreferences` perangkat lokal.
* Tambahkan endpoint `GET /api/pricing-config` & `PUT /api/admin/pricing-config` agar ubahan tarif oleh Admin di `AdminTariffTab` otomatis tersinkron ke perangkat Customer dan Driver, sekaligus selaras dengan rumus `/api/orders/calculate` & `POST /api/orders` di `gage-cloud/src/index.ts`.

---

## 4. Spesifikasi Skema Migrasi Backend `gage-cloud` (`D1` & API Hono)

Berdasarkan inspeksi langsung terhadap [`0001_initial_schema.sql`](../../gage-cloud/migrations/0001_initial_schema.sql) dan [`index.ts`](../../gage-cloud/src/index.ts), berikut daftar perubahan SQL & API yang perlu disiapkan dalam migrasi baru (mis. `0002_ecosystem_parity.sql`):

### A. Migrasi SQL D1 (`0002_ecosystem_parity.sql`)
1. **Tabel `merchant_menus`**:
   ```sql
   ALTER TABLE merchant_menus ADD COLUMN sold_count INTEGER NOT NULL DEFAULT 0;
   ALTER TABLE merchant_menus ADD COLUMN original_price INTEGER;
   ALTER TABLE merchant_menus ADD COLUMN promo_price INTEGER;
   ALTER TABLE merchant_menus ADD COLUMN promo_active INTEGER NOT NULL DEFAULT 0;
   ```
2. **Tabel `merchants`**:
   ```sql
   ALTER TABLE merchants ADD COLUMN service_type TEXT NOT NULL DEFAULT 'food';
   ALTER TABLE merchants ADD COLUMN location_photo TEXT;
   ALTER TABLE merchants ADD COLUMN operating_schedule_json TEXT;
   ALTER TABLE merchants ADD COLUMN category_order_json TEXT;
   ```
3. **Tabel `orders`** (menutup blocker Pickup isolation, Driver Tip, Dual Voucher, dan Handover PIN Driver):
   ```sql
   ALTER TABLE orders ADD COLUMN order_type TEXT NOT NULL DEFAULT 'DELIVERY';
   ALTER TABLE orders ADD COLUMN service_type TEXT NOT NULL DEFAULT 'food';
   ALTER TABLE orders ADD COLUMN driver_tip INTEGER NOT NULL DEFAULT 0;
   ALTER TABLE orders ADD COLUMN order_promo_code TEXT;
   ALTER TABLE orders ADD COLUMN delivery_promo_code TEXT;
   ALTER TABLE orders ADD COLUMN handover_pin TEXT;
   ```
4. **Tabel `vouchers`** (ganti/lengkapi struktur `promos` statis agar mendukung filter per layanan):
   ```sql
   CREATE TABLE IF NOT EXISTS vouchers (
     id TEXT PRIMARY KEY,
     code TEXT NOT NULL UNIQUE,
     service_domain TEXT NOT NULL, -- 'food' | 'shop' | 'farm' | 'build' | 'ride' | 'car' | 'send' | 'all'
     service_label TEXT NOT NULL,  -- 'GAGE Food', 'GAGE Shop', dll.
     voucher_type TEXT NOT NULL,   -- 'order' | 'delivery'
     title TEXT NOT NULL,
     discount_text TEXT NOT NULL,
     min_order INTEGER NOT NULL DEFAULT 0,
     discount_amount INTEGER NOT NULL DEFAULT 0,
     discount_percentage REAL,
     quantity INTEGER NOT NULL DEFAULT 1,
     tag TEXT,
     expiry_at INTEGER NOT NULL,   -- Unix epoch seconds
     expiry_label TEXT NOT NULL,   -- mis. '31 Des 2026'
     terms_json TEXT NOT NULL DEFAULT '[]',
     is_active INTEGER NOT NULL DEFAULT 1,
     created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
     updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
   );
   ```
5. **Tabel `pricing_configs`** (key-value JSON untuk `GagePricingService`):
   ```sql
   CREATE TABLE IF NOT EXISTS pricing_configs (
     id TEXT PRIMARY KEY,
     config_json TEXT NOT NULL,
     updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
   );
   ```

### B. Endpoint & Perbaikan Logika Server (`gage-cloud/src/index.ts`)
> **Catatan CORS**: Saat ini `index.ts#L22` hanya mengizinkan `['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS']`. Gunakan method **`PUT`** (atau tambahkan `'PATCH'` ke array CORS `allowMethods`).
> **Keamanan Auth**: Semua endpoint tulis Admin (`/api/admin/*`) dan Merchant (`/api/merchants/:id/*`, `/api/merchant/menu*`) wajib memeriksa token session / role guard (`admin` atau pemilik `merchant_id`).

1. **Perbaikan Bug Falsy Pickup di `POST /api/orders` (`index.ts#L1153`)**:
   - Saat Checkout memilih `Pickup`, client mengirim `distanceKm: 0.0`. Ekspresi lama `Number(body.distance_km || 1.5)` di JavaScript menganggap `0` bernilai falsy sehingga memaksa ongkir `1.5 km`.
   - Ubah menjadi `const orderType = body.order_type === 'PICKUP' ? 'PICKUP' : 'DELIVERY';` dan `const distanceKm = orderType === 'PICKUP' ? 0 : Math.max(1, Number(body.distance_km ?? 1.5));`. Saat `orderType === 'PICKUP'`, wajib paksa `rawShipping = 0` dan `driverCut = 0`.
2. **Dukungan Dual Voucher & Harga Promo + Tip di `POST /api/orders` & `/api/orders/calculate`**:
   - Ambil unit price dari `promo_active = 1 && promo_price > 0 && promo_price < gage_price ? promo_price : gage_price`.
   - Validasi `order_promo_code` dan `delivery_promo_code` terhadap `vouchers` & subtotal promo (`>= min_order`).
   - Simpan `driver_tip` (`Math.max(0, Number(body.driver_tip ?? 0))`), tambahkan ke `total_amount`, dan kreditkan `driver_cut + driver_tip` saat order selesai (`index.ts#L1452`).
   - Increment `merchant_menus.sold_count` setiap kali order mencapai status `'COMPLETED'`.
3. **Filter Pickup & Metadata Toko di `GET /api/driver/orders/available` (`index.ts#L1405-L1409`)**:
   - Ubah query SQL menjadi `WHERE o.driver_id IS NULL AND o.order_type = 'DELIVERY' AND o.status IN ('PAID', 'COOKING', 'READY_FOR_PICKUP')` serta sertakan `o.driver_tip`, `o.order_type`, `o.service_type`, `m.id AS merchant_id`, `m.latitude AS merchant_lat`, `m.longitude AS merchant_lng`, `m.location_photo`.
4. **Endpoint Katalog, Promosi & Menu Merchant yang Dibutuhkan**:
   - `POST /api/merchant/menu` & `POST /api/merchant/menu/:id/toggle-stock` (agar method yang sudah ada di `GageApiClient` tidak 404).
   - `PUT /api/merchants/:id/storefront` (`name`, `address`, `bio`, `location_photo`, `operating_schedule_json`, `latitude`, `longitude`).
   - `PUT /api/merchants/:id/category-order` (`category_order`).
   - `PUT /api/merchants/:id/menu/:menuId/promo` (`promo_price`, `original_price`, `promo_active`).
   - `GET /api/vouchers`, `POST /api/admin/vouchers`, `PUT /api/admin/vouchers/:id`.
   - `GET /api/pricing-config`, `PUT /api/admin/pricing-config`.

---

## 5. Update Wave 1 & Wave 2 (Customer Portal & Backend Sync)

### A. Migrasi D1, Auth JWT & Deployment Worker (`gage-cloud/`)
1. **Migrasi D1 `0006_security_and_order_sync.sql`**:
   - Menambahkan kolom `package_details_json` pada tabel `orders` untuk sinkronisasi paket GAGE Send.
   - Menambahkan kolom `password_hash`, `role`, dan `is_verified` pada tabel `users`, serta tabel `user_sessions` / `otp_codes` sesuai kontrak auth baru.
   - Jalankan migrasi pada D1 remote/local sebelum deploy Worker baru.
2. **Environment & Secrets (`wrangler.toml` / Worker Secrets)**:
   - Pastikan secret `AUTH_JWT_SECRET` dan `ADMIN_API_KEY` diset di environment produksi Cloudflare Worker.
   - Endpoint admin/voucher/pricing wajib memverifikasi header `X-Admin-Key` / bearer JWT admin sesuai `src/security.ts` dan `src/index.ts`.
3. **Sinkronisasi Pengaturan Pricing (`GagePricingService` / `/api/pricing-config`)**:
   - Customer Portal kini memicu tier **Hemat** (Food, Shop, Farm, Build) berbasis minimal belanja **`hematMinSubtotal`** dengan default **`Rp 50.000`** (menggantikan syarat jarak >= 2.5 km) demi menjaga margin komisi.
   - Pada layanan GAGE Send (`serviceType == 'send'`), tier pengiriman disinkronkan menjadi **`INSTAN`** (pengganti `REGULER`) dan **`HEMAT`**. Nilai ini dikirim di `delivery_option` dan `tier` pada payload pesanan.
   - Portal Admin perlu menyediakan form konfigurasi `hematMinSubtotal` (dan tarif dasar/ongkir per service) agar dapat diubah sewaktu-waktu via `PUT /api/admin/pricing-config` tanpa rebuild aplikasi.

### B. Cleanup Wave 3 untuk Portal Admin (`lib/features/admin/` & `main_admin.dart`)
- Sesuai isolasi portal, file di `lib/features/admin/` belum disentuh pada Wave 1. Saat eksekusi Wave 3 Portal Admin:
  - Hapus seluruh tab, menu, KPI, moderasi, atau filter yang masih merujuk ke modul **GAGE BaBe** dan **GAGE Clean** yang sudah dihentikan.
  - Pastikan admin dashboard / WA center tidak lagi memakai tautan eksternal WhatsApp (`wa.me` / `whatsapp://`) untuk alur chat pelanggan dan mengarahkannya ke sistem chat in-app (`InAppChatProvider`).
  - Terapkan kapsul penuh (`BorderRadius.circular(999)` / `StadiumBorder()`) pada seluruh segmented switch dan tab di Portal Admin.

---

## 6. Update Multi-User Wallet Top-Up & ShopeePay Gateway Settlement (Nov 2026)

### A. Endpoint Settlement Gateway (`POST /api/gateway/settle`)
- **Autentikasi**: Header `X-Gateway-Secret` atau payload `secret` dicocokkan terhadap `c.env.GATEWAY_SECRET || 'gage-secret-local-dev-2026'`.
- **Payload Request**:
  ```json
  {
    "amount": 50123,
    "reference": "TOP-XYZ",
    "shopee_tx_id": "SPP123456",
    "secret": "gage-secret-local-dev-2026"
  }
  ```
- **Logika Eksekusi**:
  1. Cari transaksi pending: `SELECT * FROM qris_transactions WHERE amount = ? AND status = 'PENDING' ORDER BY created_at DESC LIMIT 1` (atau via `id = reference`).
  2. Idempotensi: Jika transaksi sudah berstatus `SUCCESS`, kembalikan respons sukses langsung.
  3. Update `qris_transactions` menjadi `status = 'SUCCESS'`, `paid_at = now`.
  4. Ambil wallet user: `SELECT * FROM wallets WHERE user_id = ?` (auto-create jika belum ada).
  5. Update saldo: `UPDATE wallets SET balance = balance + ?, updated_at = ? WHERE user_id = ?`.
  6. Catat mutasi: `INSERT INTO wallet_transactions (id, wallet_id, type, amount, balance_after, reference_id, description, created_at) VALUES (?, ?, 'TOPUP', ?, ?, ?, 'Top Up QRIS ShopeePay', ?)`.
  7. Jika `reference_type == 'ORDER'`, otomatis update `orders.payment_status = 'PAID'` dan transisikan status order ke persiapan pesanan.

### B. Polling Status Top-Up QRIS (`GET /api/wallet/topup/status/:reference`)
- Mengembalikan status transaksi (`PENDING`, `SUCCESS`, `EXPIRED`) bagi aplikasi mobile / dialog top-up QRIS:
  ```json
  {
    "success": true,
    "status": "SUCCESS",
    "data": {
      "reference": "TOP-123",
      "user_id": "usr-cust-01",
      "amount": 50123,
      "status": "SUCCESS",
      "reference_type": "TOPUP",
      "created_at": 1773000000,
      "paid_at": 1773000010
    }
  }
  ```
- Dilengkapi mekanisme auto-expire bila transaksi masih `PENDING` setelah 15 menit.

### C. Multi-User Wallet Fetch (`GET /api/wallet/:userId`)
- Mengembalikan saldo terkini (`balance`, `points`, object `wallet`) dan 20 transaksi mutasi terakhir dari `wallet_transactions` diurutkan dari yang terbaru.

---

## 7. Modul Kustomisasi Struk Pembayaran Digital (Admin Receipt Configurator)

### A. Kebutuhan Bisnis & Visual
Customer Portal (`gage_receipt_share_dialog.dart`) telah memiliki fitur Struk Pembayaran Digital Resmi bergaya thermal receipt autentik (layar penuh, anti AI-slop, perforated edge, anti-fraud QR code, dan penyimpanan native ke album Galeri `"Gage by Halu Goods Indonesia"`).
Admin harus memiliki kontrol penuh untuk mengubah logo, nama header, catatan kaki, dan format struk tanpa perlu merilis ulang APK mobile.

### B. Skema Konfigurasi D1 (`receipt_settings`)
```sql
CREATE TABLE IF NOT EXISTS receipt_settings (
  id TEXT PRIMARY KEY DEFAULT 'default',
  logo_url TEXT DEFAULT '',
  header_title TEXT DEFAULT 'GAGE PRACIMANTORO',
  subtitle TEXT DEFAULT 'BUKTI TRANSAKSI PEMBAYARAN RESMI',
  footer_note TEXT DEFAULT 'GAGE - Layanan Lokal Pracimantoro',
  contact_hotline TEXT DEFAULT '0812-3456-7890',
  qr_verification_enabled INTEGER DEFAULT 1,
  updated_at INTEGER NOT NULL
);
```

### C. Kontrak API Hono Cloudflare (`gage-cloud`)
1. **Ambil Konfigurasi Struk Publik (`GET /api/receipt/config`)**:
   - Digunakan oleh Customer Portal saat merender struk pembayaran digital.
   ```json
   {
     "success": true,
     "data": {
       "logo_url": "https://pub-r2.gage.id/branding/logo_gage_receipt.png",
       "header_title": "GAGE PRACIMANTORO",
       "subtitle": "BUKTI TRANSAKSI PEMBAYARAN RESMI",
       "footer_note": "GAGE - Layanan Lokal Pracimantoro",
       "contact_hotline": "0812-3456-7890",
       "qr_verification_enabled": true
     }
   }
   ```
2. **Pembaruan Konfigurasi oleh Admin (`PUT /api/admin/receipt/config`)**:
   - Membutuhkan role admin token. Mengupdate field konfigurasi struk di tabel D1.

---

## 9. Handoff Wave 3 Iteration 4: Compact Auto-Detect Invoice Number & GAGEPay Enhancements

### 9.1. Format Baru Nomor Invoice (`InvoiceNumberGenerator`)
- **Format**: `INV-{BASE36_TIMESTAMP}-{NODE_SEQ}{CHECKSUM}` (contoh: `INV-K9X2B7Q1-P018`, ~16-17 karakter).
- **Spesifikasi Teknis**:
  - `BASE36_TIMESTAMP`: 8 karakter encoding milidetik sejak epoch dalam Radix 36.
  - `NODE_SEQ`: 1 digit ID node cluster + 2 digit counter sequence heksadesimal (`00`-`FF`).
  - `CHECKSUM`: 1 digit check digit Luhn variant Modulo 36 untuk deteksi typo dan integritas tanpa query D1.
- **Auto-Detection DateTime**:
  - Backend/Admin tidak perlu menyimpan redundansi kolom tanggal terpisah untuk audit cepat. Cukup parse segmen Base36 untuk mengekstrak timestamp milidetik persis transaksi dibuat.
- **Anti-Collision**:
  - Aman dari tabrakan ID saat migrasi server, database multi-region D1, atau burst checkout bersamaan.

### 9.2. GAGEPay Poin Loyalty & QRIS Official Billing Receipt
- Penambahan loyalty tier, konversi poin ke saldo, voucher UMKM, dan donasi sosial.
- Lembar tagihan QRIS resmi standar ASPI/BI (`GageQrisReceiptWidget`) menggantikan mockup visual kartu pada fitur Terima Saldo. Detail kartu 2.5D kini berada di menu Pengaturan GAGEPay.

---

## 10. Handoff Wave 4: GAGE Video Sound Catalog & Affiliate Showcase Schema

### 10.1. Tabel Cloudflare D1 `video_sounds` & `creator_showcase`
```sql
CREATE TABLE IF NOT EXISTS video_sounds (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  artist TEXT NOT NULL,
  duration TEXT NOT NULL,
  audio_url TEXT NOT NULL,
  album_art_url TEXT NOT NULL,
  videos_count INTEGER NOT NULL DEFAULT 0,
  is_original INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS creator_showcase_items (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  merchant_id TEXT NOT NULL,
  product_title TEXT NOT NULL,
  product_price INTEGER NOT NULL,
  thumbnail_url TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  UNIQUE(user_id, product_id)
);
```

### 10.2. Endpoint Hono Terkait
- `GET /api/sounds/trending`: Mengambil daftar musik pengiring video viral lokal Pracimantoro.
- `GET /api/sounds/:id`: Detail lagu, statistik penggunaan, dan video yang menggunakan audio tersebut.
- `GET /api/creators/:userId/showcase`: Daftar produk etalase aktif affiliator.
- `POST /api/creators/:userId/showcase`: Menyematkan produk menu merchant ke etalase profil.
- `DELETE /api/creators/:userId/showcase/:productId`: Menghapus produk dari etalase profil.

---

## 11. Spesifikasi WebSocket Hibernation & Analisis Skalabilitas Cloudflare D1 (50 s.d. 10.000 DAU)

### 11.1. Arsitektur WebSocket Hibernation & Penyatuan Chat (Sosmed & Transaksional)
Untuk mencegah ledakan query database saat interaksi chat meningkat (baik chat order antar customer-driver-merchant maupun direct message sosmed):
1. **Zero Database Polling**:
   - Seluruh koneksi real-time menggunakan **Cloudflare Workers WebSocket Hibernation API**. Saat koneksi idle / menunggu pesan, Worker masuk ke status hibernasi dan mengonsumsi 0 CPU duration serta 0 D1 reads.
2. **In-Memory Routing via Durable Objects**:
   - Pengiriman pesan antar pengguna yang sedang online ditangani langsung di memori Durable Object / room session tanpa melakukan query `SELECT` ke D1.
3. **Write Buffer & Batching ke D1**:
   - Pesan baru tidak langsung memicu `INSERT` tunggal per detik. Durable Object mengumpulkan pesan dalam queue memori dan melakukan flushing batch (`db.batch([...])`) setiap 2-5 detik atau saat buffer mencapai 20 pesan.
4. **Offloading Aset & Konten Statis**:
   - Video, thumbnail, dan file audio suara viral disimpan di **Cloudflare R2** dengan cache CDN edge. D1 hanya menyimpan metadata teks pendek.
   - Profil pengguna, katalog merchant, dan daftar voucher dicache di client (`SharedPreferences` / SQLite lokal) dengan TTL 15-60 menit + HTTP `ETag` / `If-None-Match`.

### 11.2. Tabel Analisis Kapasitas D1: Skenario 50 s.d. 10.000 DAU

| Skala Pengguna (DAU) | Estimasi Reads / Hari | Estimasi Writes / Hari | Beban D1 Free Tier (Reads: 5M/hr) | Beban D1 Free Tier (Writes: 100k/hr) | Status Keamanan & Biaya |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **50 DAU** | ~3.000 | ~500 | 0.06% | 0.50% | **100% Aman (Free Tier)** |
| **100 DAU** | ~6.500 | ~1.000 | 0.13% | 1.00% | **100% Aman (Free Tier)** |
| **200 DAU** | ~13.000 | ~2.000 | 0.26% | 2.00% | **100% Aman (Free Tier)** |
| **300 DAU** | ~19.500 | ~3.000 | 0.39% | 3.00% | **100% Aman (Free Tier)** |
| **500 DAU** | ~32.500 | ~5.000 | 0.65% | 5.00% | **100% Aman (Free Tier)** |
| **1.000 DAU** | ~65.000 | ~10.000 | 1.30% | 10.00% | **100% Aman (Free Tier)** |
| **5.000 DAU** | ~325.000 | ~50.000 | 6.50% | 50.00% | **100% Aman (Free Tier)** |
| **10.000 DAU** | ~650.000 | ~100.000 | 13.00% | 100.00% (Batas Free Tier) | **Aman & Rekomendasi Upgrade Paid Tier ($5/bln)** |

### 11.3. Rasionalitas & Keandalan Skalabilitas:
- **Di tingkat 50 s.d. 5.000 DAU**: Seluruh beban operasional GAGE (Customer, Merchant, Driver, Admin) berada jauh di bawah limit gratis Cloudflare D1 (hanya memakan < 50% kuota harian). Biaya infrastruktur database = **$0 (Rp 0)**.
- **Di tingkat 10.000 DAU**: Operasi pembacaan D1 hanya terpakai 13%, dan penulisan menyentuh batas 100k/hari. Mengaktifkan **Workers Paid ($5 / ~Rp 80.000 per bulan)** langsung melipatgandakan limit menjadi **25 juta reads/hari dan 50 juta writes/bulan (~1.66 juta writes/hari)**, yang sanggup menampung hingga **150.000 DAU** tanpa kendala sama sekali.

---

## 12. Handoff Wave 5: Skema Voucher Afiliasi Publik `GAGEHALU`

1. **Voucher Afiliasi Riil Non-Gimmick**:
   - Kode Voucher: `GAGEHALU` (ID: `v-affiliate-cuan`).
   - Ketentuan Diskon: Diskon belanja Rp 10.000 dengan **Minimal Belanja Rp 30.000**.
   - Ketentuan Subsidi Ongkir: Gratis ongkir hingga Rp 5.000 dengan **Minimal Belanja Rp 25.000**.
   - Tipe Layanan yang Didukung: `['food', 'shop', 'farm', 'build']`.
   - Kuota Penggunaan: 1x per pengguna baru atau pengguna referral.
2. **Backend D1 Sync**:
   - Pastikan tabel `vouchers` di D1 Cloudflare memuat record untuk `GAGEHALU` dengan batas kuota dan tanggal kadaluarsa yang dapat dikelola secara dinamis lewat Admin Voucher Management Tab.

---

## 13. Handoff Wave 6: Sinkronisasi Foto Profil Pengguna via Cloudflare R2 & Skema D1

Untuk mengakhiri ambiguitas atau tampilan foto profil yang berbeda antara halaman Profil, Video Feed, dan formulir Ubah Profil:

### 13.1. Skema Database Cloudflare D1 (`users`)
```sql
ALTER TABLE users ADD COLUMN avatar_url TEXT;
ALTER TABLE users ADD COLUMN bio TEXT;
ALTER TABLE users ADD COLUMN handle TEXT;
```

### 13.2. Endpoint Upload Avatar (`POST /api/v1/user/avatar`)
* **Metode**: `POST`
* **Format**: `multipart/form-data` (file gambar: `.jpg`, `.png`, `.webp`, maks. 5 MB)
* **Penyimpanan**: Disimpan di **Cloudflare R2 Bucket** (`gage-media/avatars/{user_id}_{timestamp}.webp`) dengan konversi otomatis ke WebP di Cloudflare Workers.
* **CDN Caching**: Di-distribusikan melalui edge CDN domain publik `https://media.gage.id/avatars/...` dengan header `Cache-Control: public, max-age=86400`.
* **Database Sync**: Worker mengeksekusi:
  ```sql
  UPDATE users SET avatar_url = ?1, updated_at = unixepoch() WHERE id = ?2;
  ```
* **Response JSON**:
  ```json
  {
    "success": true,
    "avatar_url": "https://media.gage.id/avatars/usr_123_1732000000.webp"
  }
  ```

## 14. Handoff Wave 7: Audit Menyeluruh UI Design System & Bridging Cloudflare D1

### 14.1. Audit UI Design System & Pantangan Keras User
1. **Mandatory Full-Rounded Capsule (`R999` / `StadiumBorder`)**:
   - Seluruh tab switcher, segmented bar, mode toggle, dan filter chips di 4 portal WAJIB berbentuk kapsul penuh `BorderRadius.circular(999)` pada track luar dan tombol aktif (`GageTheme.primary` dengan teks putih tebal).
   - Dilarang keras memakai boxy rounded-rectangles (`R8` s.d. `R16`).
2. **Desain Poster Grafis Bersih (Anti-Struk Kasir)**:
   - Kartu promosi visual untuk dibagikan (`GagePromoCardShareDialog`) adalah poster promosi digital modern berbingkai bulat halus `R20`.
   - Dilarang menambahkan elemen sobekan kertas kasir (gigi gergaji, perforasi lubang-lubang, notches tiket).
   - Barcode / QR Code ditiadakan dari kartu produk dan kartu toko mitra (hanya ada pada referral).
   - Teks pesan bagikan di sosial media dipangkas: cukup link URL saja.
3. **Pemberantasan Terminologi 'QRIS Instan'**:
   - Kata 'QRIS Instan' atau 'QRIS Instant' dilarang di seluruh sistem GAGE (portal Admin, Merchant, Driver, Customer, dan skema database). Cukup gunakan terminologi resmi **'QRIS'**.
4. **Standardisasi Banner Beranda Superapp**:
   - Kartu 'Pasti dapet diskon tiap hari / Lihat keuntungan PLUS' diletakkan di atas slider banner promo dengan kilatan cahaya diagonal interval 3.5 detik dan aset 3D tiket voucher hijau transparan.
   - Ukuran slider banner promo diseragamkan ke proporsi standar superapp (tinggi ~145-160px).

### 14.2. Arsitektur Bridging Cloudflare D1 & User Ownership Akun Google Login
1. **Ownership Berdasarkan Google OAuth**:
   - Setiap pengguna (Customer, Mitra Merchant, Mitra Driver, Admin) memiliki record di tabel `users` dengan `google_id` dan `email` unik.
   - Hak akses portal diverifikasi melalui foreign key `merchants.user_id`, `drivers.user_id`, dan `admins.user_id`.
2. **Sinkronisasi Transaksi Lintas 4 Portal**:
   - Checkout Customer -> D1 `orders` -> Dapur Merchant -> Radar Driver (`order_type == 'DELIVERY'`) -> Monitoring Admin Dispatcher.
   - Penarikan komisi afiliasi G-Cuan langsung cair ke saldo GAGEPay pengguna via D1 `wallet_transactions`.

## 15. Handoff Wave 11: Siaran Notifikasi Interaktif Media Gambar (`imageUrl`) & Integrasi D1

### 15.1. Skema Tabel Cloudflare D1 `notifications`
```sql
ALTER TABLE notifications ADD COLUMN image_url TEXT;
ALTER TABLE notifications ADD COLUMN action_url TEXT;
```

### 15.2. Endpoint Broadcast Notifikasi Admin (`POST /api/admin/notifications/broadcast`)
* **Metode**: `POST`
* **Header**: `Authorization: Bearer <admin_token>`
* **Payload JSON**:
  ```json
  {
    "title": "Promo Festival Kuliner Pracimantoro!",
    "body": "Nikmati diskon s.d. 30% di seluruh mitra GAGE Food terpilih hari ini.",
    "type": "promo",
    "image_url": "https://pub-r2.gage.id/promos/festival_kuliner.png",
    "action_url": "gage://promo/festival-kuliner",
    "target_role": "all"
  }
  ```
* **Perilaku Client Mobile**:
  - `NotificationService` otomatis mengurai `imageUrl` dan `actionUrl`.
  - Item notifikasi pada tab Notifikasi Customer, Merchant, dan Driver menjadi interaktif dan dapat dibuka ke layar penuh `NotificationDetailScreen` dengan banner gambar resolusi tinggi.

---

## 16. Handoff Wave 13: Verifikasi & Persetujuan Pengajuan Pindah Lokasi Kios Merchant

### 16.1. Kebijakan Lokasi Kios Terverifikasi
- Alamat kios fisik dan titik GPS adalah data resmi yang diverifikasi saat onboarding awal merchant di Kecamatan Pracimantoro.
- Merchant tidak diperbolehkan mengubah alamat dan titik peta secara mandiri. Perubahan dilakukan melalui formulir resmi *Pengajuan Pindah Lokasi Kios* yang membutuhkan verifikasi dan persetujuan Admin GAGE.

### 16.2. Skema Tabel Cloudflare D1 `merchant_location_requests`
```sql
CREATE TABLE IF NOT EXISTS merchant_location_requests (
  id TEXT PRIMARY KEY,
  merchant_id TEXT NOT NULL REFERENCES merchants(id),
  current_address TEXT NOT NULL,
  new_address TEXT NOT NULL,
  new_landmark TEXT,
  new_latitude REAL NOT NULL,
  new_longitude REAL NOT NULL,
  reason TEXT NOT NULL,
  status TEXT NOT NULL DEFAULT 'PENDING', -- 'PENDING' | 'APPROVED' | 'REJECTED'
  admin_notes TEXT,
  submitted_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  reviewed_at INTEGER,
  reviewed_by TEXT REFERENCES users(id)
);
```

### 16.3. API Endpoint Admin Review
1. `GET /api/admin/merchant-location-requests?status=PENDING`:
   - Mengambil daftar antrean pengajuan pindah kios dari mitra merchant yang menunggu ditinjau.
2. `PUT /api/admin/merchant-location-requests/:id/review`:
   - Payload: `{"action": "APPROVE" | "REJECT", "admin_notes": "..."}`
   - Jika `APPROVE`: Otomatis memperbarui kolom `address`, `landmark`, `latitude`, `longitude` pada tabel `merchants`, dan status permohonan menjadi `APPROVED`.
   - Jika `REJECT`: Status menjadi `REJECTED` beserta alasan penolakan agar tampil di lembar *Pengajuan Saya* merchant.

---

## 17. Handoff Wave 14: Standardisasi Store ID Cloudflare D1, Dokumen Kemitraan Resmi & Hotline Dispatcher

### 17.1. Format Store ID Terstruktur Cloudflare D1
- Format ID Toko di seluruh ekosistem GAGE kini distandarisasi menggunakan kode terstruktur:
  `GAGE-[DISTRICT]-[CATEGORY][SEQ]`
  Contoh: `GAGE-PRC-FD01` (GAGE Pracimantoro Food #01), `GAGE-PRC-SH02` (Shop #02), `GAGE-PRC-FM01` (Farm #01).
- Admin backend D1 generator wajib menghasilkan ID toko dengan skema ini pada tabel `merchants.id`.

### 17.2. Perjanjian Kemitraan Resmi & Skema MDR 10%
- Dokumen kebijakan di Portal Merchant (`MerchantTermsAndPrivacyScreen`) telah mengikat aturan:
  1. Biaya layanan platform (MDR) adalah **10% (sepuluh persen)** dari subtotal produk.
  2. Pencairan saldo penjualan (settlement) otomatis ditransfer ke rekening bank / e-wallet mitra terdaftar **H+1 hari kerja** tanpa potongan tersembunyi.
  3. Kerahasiaan data pembeli dilindungi hukum; merchant dilarang memanfaatkan data pembeli di luar pemenuhan pesanan aktif.
  4. Penanganan pesanan dibatalkan akibat kelalaian outlet / menu habis menjadi kewajiban ganti rugi merchant.

### 17.3. Hotline Telepon Dispatcher & Kanal CS Mitra
- Admin Dispatcher Hub Pracimantoro terhubung dengan tombol direct-call di lembar bantuan merchant:
  - Nomor Hotline Darurat Dispatcher: `+62 811-1222-333`
  - WhatsApp CS Mitra Usaha: `+62 811-1222-333`
  - Kantor Operasional: *Jl. Raya Pracimantoro No. 12, Wonogiri, Jawa Tengah*.










---

## 18. Handoff Wave 15: Integrasi Backend & D1 Opsional untuk G-Fit & Profil Avatar Chat

1. **Verifikasi Avatar Lintas Portal (`driver_avatar`, `merchant_avatar`, `customer_avatar`)**:
   - `gage-cloud/src/index.ts` sudah mengembalikan `du.avatar_url as driver_avatar`, `m.image_url as merchant_avatar`, dan `u.avatar_url as customer_avatar` pada endpoint order utama. Pastikan endpoint `POST /api/user/profile` tetap mengizinkan driver, merchant, maupun customer menyimpan `avatar_url` berbasis HTTPS maupun path R2 relatif (`/api/chat/media/...`), yang kini dinormalisasi oleh `GageAvatar.resolveSourceUrl` di aplikasi.
2. **Skema D1 & Endpoint Opsional untuk Sinkronisasi Cloud G-Fit**:
   - Fitur G-Fit di aplikasi Customer kini menyimpan sesi olahraga (koordinat rute, kalori MET, split pace per km), target mingguan, serta klaim misi & voucher reward (`GFITSEHAT`, `GFITONGKIR`, `GFITJUARA`) secara lokal per `userId` di `SharedPreferences` dan langsung mengkreditkan `WalletProvider.points`.
   - Untuk sinkronisasi lintas-perangkat dan validasi kupon server-side penuh, Admin & Backend D1 perlu menyediakan migrasi tabel opsional berikut:
```sql
CREATE TABLE IF NOT EXISTS gfit_workouts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  activity_type TEXT NOT NULL, -- 'run' | 'walk' | 'bike'
  started_at INTEGER NOT NULL,
  duration_seconds INTEGER NOT NULL,
  distance_km REAL NOT NULL,
  calories INTEGER NOT NULL,
  elevation_gain_m REAL DEFAULT 0,
  points_earned INTEGER DEFAULT 0,
  is_simulation INTEGER DEFAULT 0,
  route_name TEXT,
  route_points_json TEXT,
  split_laps_json TEXT,
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

CREATE TABLE IF NOT EXISTS gfit_mission_claims (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES users(id),
  week_key TEXT NOT NULL, -- YYYY-MM-DD (Senin minggu berjalan)
  mission_id TEXT NOT NULL,
  bonus_points INTEGER NOT NULL,
  voucher_code TEXT NOT NULL,
  claimed_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
  UNIQUE(user_id, week_key, mission_id)
);
```
   - Disarankan menambahkan baris voucher aktif `GFITSEHAT`, `GFITONGKIR`, dan `GFITJUARA` pada katalog tabel `vouchers` D1 bila validasi promo checkout sisi server sudah diaktifkan penuh, serta endpoint `GET/POST /api/gfit/workouts` & `POST /api/gfit/missions/claim` dengan batas kredit harian `300 poin/hari`.

---

## 19. Handoff Wave 16: Kontrak Backend Cloudflare D1 & R2 untuk Seluruh Modul Chat (`lib/features/chat/`)

Dokumen ini merangkum temuan audit pada `gage-cloud/src/index.ts` agar seluruh portal (Customer, Merchant, Driver) memiliki foto profil dan sinkronisasi pesan chat yang berjalan penuh di produksi.

### A. Celah Field Avatar pada Query Order (`gage-cloud/src/index.ts`)
1. **`GET /api/merchant/orders` (`index.ts#L2057`)**:
   - Saat ini query `SELECT` sudah mengambil `du.avatar_url as driver_avatar`, namun **belum mengambil `u.avatar_url as customer_avatar`**.
   - **Tindakan Admin/Backend**: Tambahkan `u.avatar_url as customer_avatar` pada query `SELECT` agar Portal Merchant (`GageMerchantChatTab` & `MerchantChatListScreen`) dapat menampilkan foto profil pelanggan asli.
2. **`GET /api/driver/orders` (`index.ts#L2096`)**:
   - Saat ini query `SELECT` baru mengambil `m.name as merchant_name`, `u.name as customer_name`, namun **belum mengambil `m.image_url as merchant_avatar`, `u.phone as customer_phone`, dan `u.avatar_url as customer_avatar`**.
   - **Tindakan Admin/Backend**: Tambahkan ketiga kolom tersebut agar Portal Driver (`DriverChatListScreen`) dan `InAppChatScreen` Driver mendapat avatar toko, avatar pelanggan, dan nomor telepon yang akurat.

### B. Sinkronisasi Persistent Pesan Chat D1 (Transisi dari Lokal `InAppChatProvider`)
Saat ini `gage-cloud/src/index.ts` baru menyediakan endpoint upload & CDN media R2 (`POST /api/chat/media/upload-url`, `POST /api/chat/media/upload`, `GET /api/chat/media/*` pada `L2533-L2611`), sedangkan pesan teks/gambar/produk/suara masih disimpan di memori lokal `InAppChatProvider` (`lib/features/chat/providers/in_app_chat_provider.dart`).

Untuk sinkronisasi real-time antar-perangkat Customer <-> Driver <-> Merchant <-> Pusat Bantuan, sediakan tabel dan endpoint D1 sesuai struktur `ChatMessage` (`lib/features/chat/domain/chat_message.dart`):

```sql
CREATE TABLE IF NOT EXISTS chat_messages (
  id TEXT PRIMARY KEY,
  order_id TEXT NOT NULL,
  sender_id TEXT NOT NULL,
  sender_role TEXT NOT NULL, -- 'customer' | 'driver' | 'merchant' | 'admin' | 'support'
  sender_name TEXT NOT NULL,
  text TEXT NOT NULL DEFAULT '',
  media_url TEXT,
  message_type TEXT NOT NULL DEFAULT 'text', -- 'text' | 'image' | 'product' | 'voice'
  product_name TEXT,
  product_price INTEGER,
  product_image TEXT,
  voice_duration_seconds INTEGER,
  status TEXT NOT NULL DEFAULT 'sent', -- 'sending' | 'sent' | 'delivered' | 'read'
  created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);
CREATE INDEX IF NOT EXISTS idx_chat_messages_order_time ON chat_messages(order_id, created_at ASC);
```

- **Endpoint yang Disarankan**:
  1. `GET /api/chat/messages?order_id=...` -> mengembalikan array JSON dengan field sesuai `ChatMessage.fromJson` (`id`, `orderId`, `senderId`, `senderRole`, `senderName`, `text`, `mediaUrl`, `messageType`, `productName`, `productPrice`, `productImage`, `voiceDurationSeconds`, `timestamp` dalam epoch ms, `status`).
  2. `POST /api/chat/messages` -> menyimpan pesan baru dan memicu push notification / polling ke pihak penerima terkait.
  3. `PATCH /api/chat/messages/read` -> menandai pesan terbaca per `order_id` & `reader_role`.
