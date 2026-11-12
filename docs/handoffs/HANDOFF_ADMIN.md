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
3. **Tabel `orders`** (menutup blocker Pickup isolation, Driver Tip, dan Dual Voucher):
   ```sql
   ALTER TABLE orders ADD COLUMN order_type TEXT NOT NULL DEFAULT 'DELIVERY';
   ALTER TABLE orders ADD COLUMN service_type TEXT NOT NULL DEFAULT 'food';
   ALTER TABLE orders ADD COLUMN driver_tip INTEGER NOT NULL DEFAULT 0;
   ALTER TABLE orders ADD COLUMN order_promo_code TEXT;
   ALTER TABLE orders ADD COLUMN delivery_promo_code TEXT;
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
   - Portal Admin perlu menyediakan form konfigurasi `hematMinSubtotal` (dan tarif dasar/ongkir per service) agar dapat diubah sewaktu-waktu via `PUT /api/admin/pricing-config` tanpa rebuild aplikasi.

### B. Cleanup Wave 3 untuk Portal Admin (`lib/features/admin/` & `main_admin.dart`)
- Sesuai isolasi portal, file di `lib/features/admin/` belum disentuh pada Wave 1. Saat eksekusi Wave 3 Portal Admin:
  - Hapus seluruh tab, menu, KPI, moderasi, atau filter yang masih merujuk ke modul **GAGE BaBe** dan **GAGE Clean** yang sudah dihentikan.
  - Pastikan admin dashboard / WA center tidak lagi memakai tautan eksternal WhatsApp (`wa.me` / `whatsapp://`) untuk alur chat pelanggan dan mengarahkannya ke sistem chat in-app (`InAppChatProvider`).
  - Terapkan kapsul penuh (`BorderRadius.circular(999)` / `StadiumBorder()`) pada seluruh segmented switch dan tab di Portal Admin.

