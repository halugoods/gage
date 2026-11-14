# Handoff Kontrak & Backlog Portal Merchant

* **Target Agent Session ID**: `1c4b07ce-55ca-434a-821e-f12ef99bac9c`
* **Panduan Visual Wajib**: [`GAGE_FRONTEND_UI_STYLE_GUIDE.md`](../../GAGE_FRONTEND_UI_STYLE_GUIDE.md) & [`AGENTS.md`](../../AGENTS.md)
* **Referensi Batas Portal**: [`PORTAL_BOUNDARIES.md`](../../PORTAL_BOUNDARIES.md)
* **Tanggal Handoff**: `2026-11-12`

> Dokumen ini merangkum kontrak data eksplisit, endpoint API, batas validasi harga promo, aturan penggabungan kategori, serta temuan drift UI di Portal Merchant.

---

## 1. Inventaris File Portal Merchant Saat Ini

* Root & Navigasi: [`merchant_root_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_root_screen.dart) (`_LiveMerchantScheduleInfoRow`, manajemen order & menu)
* Pesanan Masuk / Riwayat: [`merchant_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_screen.dart)
* Manajemen Katalog & Stok: [`merchant_menu_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_menu_screen.dart)
* Profil & Pengaturan Toko: [`merchant_profile_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_profile_screen.dart)
* Jadwal Operasional Sheet: [`operating_schedule_editor_sheet.dart`](../../gage-app/lib/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart)
* Keuangan & Penarikan: [`merchant_finance_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_finance_screen.dart)
* Chat Mitra: [`merchant_chat_list_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_chat_list_screen.dart)
* Provider & Service Bersama: [`merchant_order_provider.dart`](../../gage-app/lib/providers/merchant_order_provider.dart), [`merchant_storefront_service.dart`](../../gage-app/lib/core/services/merchant_storefront_service.dart)

---

## 2. Kontrak Data & Validasi Baru yang Harus Diimplementasikan Merchant

Portal Customer ([`resto_detail_screen.dart`](../../gage-app/lib/features/food/presentation/resto_detail_screen.dart), [`item_variant_sheet.dart`](../../gage-app/lib/features/food/presentation/item_variant_sheet.dart), [`merchant_catalog_helper.dart`](../../gage-app/lib/features/food/data/merchant_catalog_helper.dart)) membaca pengaturan dari `MerchantStorefrontData` serta field JSON item menu berikut:

### A. Menu Promosi Produk (Harga Coret + Status `promo_active`)
* **Kontrak State Lokal (`MerchantStorefrontData`)**:
  - Field: `Map<String, int>? itemPromoPrices` (`key = menuId`).
  - Nilai **`> 0`** (dan `< gage_price`): promo Harga Coret **AKTIF**.
  - Nilai **`0`** (atau key dihapus di produksi): promo Harga Coret **NONAKTIF** eksplisit (mencegah harga coret seed dev muncul kembali).
* **Kontrak Item / Backend D1 (`merchant_menus`)**:
  - `original_price` (`int?`): harga jual GAGE sebelum diskon (set ke `gage_price` saat promo diaktifkan).
  - `promo_price` (`int?`): harga jual promo baru (`> 0` dan `< gage_price`).
  - `promo_active` (`int`, `1` aktif / `0` nonaktif).
* **Aturan Validasi Margin/MDR yang Wajib Diterapkan di Form Promo**:
  - Formula MDR GAGE saat ini (lihat `merchant_root_screen.dart#L2237`): komisi/MDR platform 10%, sehingga bersih yang diterima merchant = `promoPrice * 0.90`.
  - **Hard Block (Wajib Tolak Simpan)**: `promoPrice <= 0` atau `promoPrice >= gage_price`.
  - **Soft Warning + Konfirmasi Merchant**: jika `promoPrice * 0.90 < offline_price` (penerimaan bersih di bawah harga warung), tampilkan peringatan kuning *"Harga bersih setelah biaya layanan lebih rendah dari harga offline"* namun tetap izinkan bila merchant menyetujui strategi bakar margin/umpan traffic.
* **Kontrak API Endpoint (Gunakan `PUT` sesuai CORS `index.ts#L22`)**:
  - `PUT /api/merchants/:id/menu/:menuId/promo`
  - Request JSON: `{ "promo_price": 12000, "original_price": 16000, "promo_active": 1 }`
  - Untuk mematikan promo: `{ "promo_price": null, "promo_active": 0 }` + simpan `itemPromoPrices[menuId] = 0` pada `MerchantStorefrontService.saveStorefront`.

### B. Pengaturan Urutan Tampil Kategori Katalog (`categoryOrder`)
* **Kontrak State (`MerchantStorefrontData`)**: `List<String>? categoryOrder`.
* **Aturan Merge & Hapus Kategori (Sinkron dengan `MerchantCatalogHelper.groupByOrderedCategories`)**:
  1. Ambil kategori unik dari katalog aktif milik merchant (jangan hanya hardcoded list `Dimsum Kukus`, `Minuman`, dll. seperti `merchant_menu_screen.dart#L26-L32`).
  2. Jika merchant sudah punya `categoryOrder`, pertahankan urutan kategori yang masih ada, buang kategori yang sudah tidak punya produk, dan tambahkan kategori baru di bagian bawah (kecuali kategori `'Lainnya'` / kosong dipin paling akhir).
  3. Simpan hasil `ReorderableListView` ke `MerchantStorefrontService.saveStorefront(current.copyWith(categoryOrder: ordered))` dan kirim `PUT /api/merchants/:id/category-order` dengan body `{ "category_order": ["Minuman", "Dimsum Kukus"] }`.

### C. Sinkronisasi `merchantId`, `created_at`, & `sold_count`
1. **Unifikasi Merchant ID Default**: `merchant_menu_screen.dart#L42` saat ini meng-hardcode `'m-dimsum-sewu'`, sedangkan `MerchantStorefrontService.defaultPortalMerchantId` adalah `'mch-dimsum-01'`. Gunakan `MerchantStorefrontService.defaultPortalMerchantId` secara konsisten saat load maupun `saveStorefront` agar perubahan merchant terbaca lintas portal.
2. **Timestamp `created_at`**: Saat menambah menu baru (`merchant_menu_screen.dart` / `merchant_root_screen.dart`), sertakan `created_at` dalam **Unix epoch seconds** (integer, konsisten dengan `0001_initial_schema.sql`) agar sort `"Baru ditambahkan"` di Customer akurat.
3. **Celah Endpoint Menu (`gage_api_client.dart#L2700-L2743`)**: Catat dalam integrasi backend bersama Admin bahwa `POST /api/merchant/menu` dan `POST /api/merchant/menu/:id/toggle-stock` yang dipanggil `GageApiClient` belum ada implementasinya di `gage-cloud/src/index.ts`.
4. **Konfirmasi Pickup Mode**: Jika order bertipe `PICKUP` (`order_type == 'PICKUP'`), alur dapur merchant harus menuntaskan order hingga `COMPLETED` langsung di tempat (tanpa menunggu kurir) dan memicu increment `sold_count` + payout merchant.

---

## 3. Verifikasi & Backlog Lintas-Portal (Storefront, Jadwal, Foto Lokasi)

* **Jadwal Operasional (`Senin - Minggu`)**: Sudah ada [`operating_schedule_editor_sheet.dart`](../../gage-app/lib/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart). Sinkronkan juga ke endpoint `PUT /api/merchants/:id/storefront`.
* **Foto Lokasi / Tampak Depan Merchant (`locationPhoto`) & Pin Koordinat**: Customer (`RestoInfoScreen`) & Driver (`ActiveTripScreen`) membaca `locationPhoto`, `latitude`, dan `longitude`. Pastikan [`merchant_profile_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_profile_screen.dart) menyinkronkan ketiganya ke `MerchantStorefrontService` & API storefront.

---

## 4. Audit Drift UI & Production Guard di Portal Merchant

1. **`merchant_screen.dart` (`L315-L348`, `_buildCustomTabBar`)**: Masih memakai underline `TabBar` (`indicatorColor: GageTheme.primary, indicatorWeight: 3`). **Wajib migrasi** ke segmented pill `BorderRadius.circular(999)` dengan active thumb `#E52320` + teks putih + `HapticFeedback.selectionClick()`.
2. **`merchant_menu_screen.dart` (`L379-L410`, Category Chips Bar)**: Ubah `BorderRadius.circular(20)` ke `999` + `HapticFeedback.selectionClick()` sesuai [`GAGE_FRONTEND_UI_STYLE_GUIDE.md`](../../GAGE_FRONTEND_UI_STYLE_GUIDE.md).
3. **`merchant_order_provider.dart` (`L64-L65`)**: `_initDefaultOrders()` wajib diguard dengan `if (!GageApiClient.useDevSeedData) return;` agar mock order tidak pernah bocor ke mode produksi.

---

## 5. Kontrak Wave 1 & Wave 2 Terbaru (Sinkronisasi Customer + Cloud D1)

1. **Alur Status Order Berurutan (`OrderModel` & `OrderDetailScreen` Customer)**:
   - Status pesanan sekarang diparse apa adanya (tidak dipaksa default ke tahap menyiapkan/lacak).
   - Urutan status layanan niaga (`food` / `shop` / `farm` / `build`): `PAID` (menunggu konfirmasi merchant) -> `COOKING` / `PREPARING` (sedang disiapkan) -> `READY_FOR_PICKUP` -> `ON_THE_WAY` -> `COMPLETED` (atau `CANCELLED` / `PAYMENT_PENDING`).
   - Merchant wajib memproses `accept` (`COOKING`) secara eksplisit sebelum status `READY_FOR_PICKUP`, dan untuk `order_type == 'PICKUP'`, merchant langsung menuntaskan status ke `COMPLETED` saat pelanggan mengambil pesanan di toko.
2. **Handoff Auth & Endpoint Keamanan Wave 2 (`gage-cloud/src/index.ts`)**:
   - Token HMAC `Authorization: Bearer <token>` kini dikirim otomatis oleh `GageApiClient` dari session login (`authToken`). Pastikan portal Merchant menyimpan `authToken` setelah login dan menghindari akses tulis tanpa header Bearer.
   - Endpoint toko/menu baru belum diimplementasikan penuh di Worker bila belum ada di Wave 2; koordinasikan dengan sesi Admin saat menambah endpoint tulis Merchant agar melewati guard kepemilikan `merchant_id`.
3. **Integrasi Chat & Penghapusan WhatsApp Customer**:
   - Customer telah menghapus tombol WhatsApp pada alur transaksi dan melompat langsung ke `InAppChatScreen` (`recipientRole: 'merchant'`). Pastikan Merchant merespons thread pesan per `orderId` melalui in-app chat (bukan redirect `wa.me`).
4. **Tier Pengiriman `Hemat` & Kartu Rincian Produk Customer**:
   - Syarat opsi ongkir `Hemat` diubah dari jarak menjadi minimal belanja subtotal (default **Rp 50.000**, dapat disinkronkan via `GagePricingService`), tanpa mengubah hak bersih harga produk merchant.
   - `CheckoutScreen` Customer kini menampilkan slider rekomendasi produk lain milik merchant; pastikan katalog produk aktif (`isAvailable`, `imageUrl`, `sold_count`, dan `promo_price`) tetap terawat rapi.

---

## 6. Kontrak Pembatalan Pesanan oleh Pelanggan (`canBeCancelledByCustomer`) & Struk Digital

1. **Aturan Pembatalan Pelanggan pada Layanan Niaga (`food` / `shop` / `farm` / `build`)**:
   - Pelanggan diizinkan membatalkan pesanan secara mandiri sebelum merchant mengonfirmasi pesanan (hanya ketika status masih `NEW`, `PAID`, atau `PENDING` / `WAITING_MERCHANT`).
   - Begitu merchant menerima pesanan dan status berubah menjadi `COOKING` / `PREPARING` atau `READY_FOR_PICKUP`, tombol pembatalan mandiri pelanggan otomatis hilang untuk mencegah kerugian bahan baku dapur merchant.
   - Endpoint: `PUT /api/orders/:id/status` dengan payload `{ "status": "CANCELLED", "cancellation_reason": "Dibatalkan oleh pelanggan" }`.
   - Dasbor Merchant: Saat pesanan dibatalkan pelanggan sebelum dimasak, daftar pesanan masuk wajib segera menghapus kartu pesanan tersebut atau menandainya sebagai Dibatalkan.
2. **Struk Digital Interaktif & Tiket Belanja**:
   - Customer kini dapat membagikan struk transaksi digital lengkap dengan nomor pesanan, daftar menu, rincian pembayaran, dan QR verifikasi (`GageReceiptShareDialog`).
   - Kasir/Merchant dapat mencocokkan struk digital ini saat pelanggan memilih opsi Ambil Sendiri (Pickup).
