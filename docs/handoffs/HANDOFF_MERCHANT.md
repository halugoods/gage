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

---

## 4. Handoff Wave 3 Iteration 4: Compact Auto-Detect Invoice Number Format
- Nomor invoice pesanan pelanggan kini beralih ke format kompak advance: `INV-{BASE36_TIMESTAMP}-{NODE_SEQ}{CHECKSUM}` (contoh: `INV-K9X2B7Q1-P018`).
- Kasir Merchant dapat memvalidasi keaslian nomor invoice secara instan menggunakan algoritma check digit Modulo 36 (Luhn variant) serta mengekstrak waktu transaksi tanpa lookup ke backend.

---

## 7. Handoff Ekosistem GAGE Cuan & Video: Formula Rekomendasi Markup Harga Merchant & Komisi Dinamis (Maks. 20%)

1. **Latar Belakang & Prinsip Utama**:
   - Merchant yang mengaktifkan fitur promosi afiliasi (GAGE Cuan & Keranjang Kuning Video) memberikan hak komisi kepada kreator/affiliator untuk mendongkrak omzet penjualan.
   - **Tingkat Komisi Dinamis Ditentukan Merchant (Batas Maksimal 20%)**:
     - Merchant memiliki wewenang penuh mengatur besaran komisi afiliasi per toko atau per produk (`affiliate_rate`), mulai dari 0% hingga batas atas **20%** agar ekosistem keuangan merchant tetap sehat dan margin tidak tergerus.
     - Platform fee GAGE tetap standar **10%** (`platform_rate = 0.10`).
     - Total potongan komisi saat ada transaksi affiliator: $\text{TotalDeductionRate} = \text{PlatformRate} (10\%) + \text{AffiliateRate} (\le 20\%)$.
   - **Prinsip Bebas Rugi bagi Merchant**: Pencairan bersih (*net payout*) ke saldo kasir merchant **wajib 100% utuh sama persis dengan harga offline outlet ($P_{\text{offline}}$)**.

2. **Formula Rekomendasi Markup Harga Online (*Net Payout Divisor*)**:
   - Formula yang dipakai:
     $$P_{\text{online}} = \frac{P_{\text{offline}}}{1 - (\text{PlatformRate} + \text{AffiliateRate})} = \frac{P_{\text{offline}}}{1 - (0.10 + \text{AffiliateRate})}$$
   - Contoh Perhitungan (dengan Komisi Affiliator 10% dan Platform 10% = Total 20%):
     - Harga offline outlet: **Rp 10.000**
     - Harga online aplikasi rekomendasi: $10.000 / 0.80 =$ **Rp 12.500**
     - Potongan komisi total 20%: $20\% \times 12.500 =$ **Rp 2.500**
     - **Pencairan bersih ke Merchant**: $12.500 - 2.500 =$ **Rp 10.000 (100% Utuh!)**
   - Contoh Perhitungan (dengan Komisi Affiliator 5% dan Platform 10% = Total 15%):
     - Harga offline outlet: **Rp 10.000**
     - Harga online aplikasi rekomendasi: $10.000 / 0.85 =$ **Rp 11.800** (dibulatkan ke atas)
     - **Pencairan bersih ke Merchant**: **Rp 10.000 (100% Utuh!)**

3. **Alokasi Pembagian Hasil Transaksi**:
   - **Transaksi dengan Affiliator (via Link / Keranjang Kuning Video)**:
     - Merchant: Menerima 100% dari harga offline ($P_{\text{offline}}$)
     - Affiliator: Menerima komisi sesuai rate toko/produk ($\text{AffiliateRate} \times P_{\text{online}}$)
     - Kas Platform GAGE: Menerima 10% platform fee
   - **Transaksi Organik (Customer Belanja Langsung Tanpa Affiliator)**:
     - Merchant: Tetap menerima 100% dari harga offline ($P_{\text{offline}}$, bebas rugi!)
     - Affiliator: Rp 0
     - Kas Platform GAGE: Menerima platform fee + bagian komisi afiliasi yang dialihkan ke kas platform

4. **Service Helper di Codebase**:
   - Telah tersedia di `AffiliateCommissionService` (`gage-app/lib/core/services/affiliate_commission_service.dart`).
   - Portal Merchant dapat mengimpor service ini pada layar manajemen menu (`merchant_menu_screen.dart`) untuk menampilkan fitur slider/input komisi dinamis (0% - 20%) dan kalkulator rekomendasi harga otomatis saat merchant menginput harga offline.

---

## 4. Ekosistem Semi-Sosmed & Profil Publik Toko Merchant di Aplikasi Customer

### A. Auto-Deteksi Akun Merchant & Integrasi Profil Publik
1. **Auto-Deteksi Akun**:
   - Ketika pengguna login sebagai merchant di aplikasi Customer, `ProfileScreen` secara otomatis mendeteksi status merchant (`SocialProfileService.isMerchantAccount(user)`) atau `initialMerchantId`.
   - Header profil beralih secara dinamis ke **`MerchantProfileHeader`** ([`merchant_profile_header.dart`](../../gage-app/lib/features/profile/presentation/widgets/merchant_profile_header.dart)).
2. **Komponen Header Profil Toko Mitra**:
   - Banner Joglo/cover toko resmi, avatar logo mitra dengan bingkai emas-merah `MITRA RESMI GAGE`.
   - Indikator real-time Buka/Tutup & jam operasional, rating bintang dan total ulasan.
   - Tombol aksi:
     - Bagi Customer umum: `+ Ikuti Toko`, `Chat Kasir`, dan `Buka Menu`.
     - Bagi Pemilik Toko (Merchant Sendiri): `Buka Portal Merchant ↗` (navigasi langsung ke `MerchantRootScreen`).
3. **Tab Konten Toko**:
   - `[ 🏪 Katalog Menu ]`: Menampilkan daftar menu aktif beserta harga online, harga coret promo, dan tombol tambah ke keranjang.
   - `[ 🎬 Video Toko ]`: Menampilkan reels/video dapur, proses masak, dan promosi yang diposting toko dengan badge keranjang kuning langsung.

---

## 8. Handoff Wave 4: Keranjang Merah Video Feed, Ekosistem Sound TikTok & Etalase Cuan

1. **Keranjang Merah Video Feed (`_ShoppableProductBanner`)**:
   - Card produk afiliasi diletakkan di bawah deskripsi/caption 2 baris (dengan accordion ekspansi jika lebih dari 2 baris).
   - Tombol "Beli" membuka quick order bottom sheet yang menampilkan nama toko dengan tombol "Buka Toko" (navigasi langsung ke `RestoDetailScreen`), selector jumlah (kuantitas), dan penambahan langsung ke keranjang belanja.
2. **Katalog Produk Afiliasi Merchant (`AffiliateMerchantDetailScreen`)**:
   - Setiap kartu menu toko kini memiliki tombol toggle aksi `+ Etalase` / `Di Etalase` yang terhubung langsung ke `SocialProfileService.instance.addProductToShowcase` dan `removeProductFromShowcase`.
   - Tombol "Buat Video" pada produk langsung mengikat produk afiliasi tersebut dan membawanya ke tahap pemilihan video dari galeri, masuk ke `VideoEditorScreen`, lalu otomatis terisi di `AffiliateVideoUploadScreen`.
3. **Sound Ecosystem & Video Editor**:
   - Terintegrasi dengan `GageSoundService` dan `SoundDetailScreen` untuk memutar preview sound, menyimpan ke favorit, dan membuat video menggunakan sound tersebut.
   - `VideoEditorScreen` menyediakan dual-slider volume mixer untuk memisahkan audio asli rekaman video dengan background musik pilihan kreator.

---

## 10. Handoff Wave 6: Pembersihan Barcode Kartu Visual, 3 Layanan G-Cuan, & Standardisasi QRIS

1. **Pembersihan Kartu Visual Toko Mitra (`GagePromoCardShareDialog`)**:
   - Barcode / QR Code resmi dihilangkan dari kartu promosi visual toko mitra. Poster grafis fokus menampilkan foto profil mitra, nama toko, mini map lokasi Pracimantoro, dan voucher resmi tanpa elemen barcode yang mengganggu.
   - Teks share caption dipangkas: membagikan toko mitra kini hanya mengirimkan tautan link bersih tanpa teks narasi panjang.
2. **Kategori Layanan Komersial G-Cuan**:
   - Segmented switch G-Cuan disederhanakan menjadi 3 kategori komersial murni: `G-Food` (Kuliner & Resto), `G-Shop` (Sembako & Belanja), dan `G-Farm` (Pertanian & Ternak).
3. **Void Kata 'QRIS Instan'**:
   - Seluruh sistem pembayaran merchant, topup, dan customer wajib menggunakan sebutan baku **'QRIS'** (bukan 'QRIS Instan' atau 'QRIS Instant').
4. **User Ownership & Bridging Cloudflare D1**:
   - Akun merchant dipetakan ke tabel Cloudflare D1 `merchants` berdasarkan `user_id` dari Google OAuth login.

---

## 11. Status Penyelesaian Backlog & Sinkronisasi FigCraft Canvas

* **Tanggal Penyelesaian**: `2026-11-21`
* **Lembar Visual Canvas FigCraft**:
  - Binary terkompilasi: `gage_merchant.figcraft` (621 nodes, 8 tokens variabel, 4 image assets).
  - Multi-Page:
    - Page 1: `01 Design System & Component Library` (129 nodes, tokens, master components, 6 floating sheets, 4 system dialogs).
    - Page 2: `02 18 Factual Merchant Mobile Screens` (490 nodes, 18 layar smartphone faktual 412x915).
  - Generator Engine: `scratch/generate_merchant_figcraft.py` via `figcraft-cli.exe`.
* **Sinkronisasi Kode Flutter (`gage-app`)**:
  - **Production Guard**: `_initDefaultOrders()` di `MerchantOrderProvider` diproteksi dengan `if (!GageApiClient.useDevSeedData) return;`.
  - **Unifikasi ID Toko**: ID default disatukan ke `MerchantStorefrontService.defaultPortalMerchantId` (`'mch-dimsum-01'`) lintas model, provider, dan view.
  - **Kepatuhan UI Style Guide**:
    - Segmented TabBar di `merchant_screen.dart` dimigrasi ke full-rounded capsule pill switch (`BorderRadius.circular(999)`).
    - Seluruh filter chips kategori dan stage filter dimigrasi ke `BorderRadius.circular(999)` dengan `HapticFeedback.selectionClick()`.
  - **Menu Promosi Harga Coret**:
    - Terintegrasi dengan `MerchantStorefrontData.itemPromoPrices`.
    - Dilengkapi validasi hard block (`promoPrice <= 0 || promoPrice >= gagePrice`) dan soft warning jika penerimaan bersih MDR 10% di bawah harga warung fisik.
  - **Pengaturan Urutan Kategori (`categoryOrder`)**:
    - Modal `ReorderableListView` dinamis terhubung langsung ke `MerchantStorefrontService.saveStorefront`.
  - **Kalkulator Markup Afiliasi Dinamis (0% - 20%)**:
    - Menggunakan `AffiliateCommissionService.calculateRecommendedOnlinePrice` dengan jaminan bebas rugi (net payout warung 100% utuh).
  - **Alur Langsung Selesai untuk Ambil Sendiri (Pickup)**:
    - Transisi langsung dari `READY_FOR_PICKUP` ke `COMPLETED` saat pelanggan mengambil pesanan di warung.
* **Hasil Verifikasi**:
  - `flutter analyze`: `No issues found!` (0 issues).
  - `flutter test`: 19/19 tests passed (100% pass rate).

---

## 12. Validasi Hardware Fisik & Uji Operasional Live via ADB Debug

* **Tanggal Validasi**: `2026-11-21`
* **Target Perangkat Fisik**: Samsung Galaxy Z Flip3 / SM-F711B (`R5CR81GTJDD`), Android 14 (API 34), Resolusi Layar 1080x2640.
* **Target Build & Flavor**: `applicationId = "com.gagepracimantoro.merchant"`, entrypoint `lib/main_merchant.dart`, flavor `merchant` (`app-merchant-debug.apk`).
* **Temuan Visual & Perbaikan Responsif pada Layar Fisik**:
  1. **Overflow Header Order Card**: Nomor invoice panjang (29 karakter e.g. `INV/GG/20261103/FD/GALIH-8822`) sebelumnya menyebabkan horizontal overflow 14px-24px. Diperbaiki dengan membungkus judul dan nomor invoice di dalam `Expanded` dengan `TextOverflow.ellipsis`.
  2. **Vertical Bottom Overflow pada Stage & Category Chips**: `ChoiceChip` bawaan Material 3 memicu micro-overflow vertikal (+2.6px) pada density tinggi. Dimigrasi penuh ke custom interactive pill capsule (`InkWell` + `AnimatedContainer` dengan `BorderRadius.circular(999)` dan haptic feedback).
  3. **Standardisasi Status Pill**: Seluruh badge status (`Pesanan Baru`, `Sedang Disiapkan`, `Siap Dijemput`, `Selesai`) distandarisasi ke full-capsule (`BorderRadius.circular(999)`).
* **Hasil Pengujian Interaksi Live pada Perangkat**:
  - **Tab 1: Pesanan Masuk (Order Card Interaktif)**:
    - Tombol "Terima Pesanan" berhasil memindahkan status order dari `NEW` ke `COOKING` secara instan, mengupdate badge counter real-time (Pesanan Baru: 1 -> 0, Sedang Disiapkan: 1 -> 2), dan mengubah tombol aksi menjadi `[Hubungi] [Ubah Stok] [Siap]`.
    - Tombol "Hubungi" membuka `InAppChatScreen` native dengan pelanggan terkait (`CUSTOMER #ord-8822`).
    - Tombol "Ubah Stok" membuka bottom sheet 3 alur cerdas operasional (Substitusi Menu, Kirim yang Ready Saja, Batalkan Seluruh Pesanan).
  - **Tab 2: Manajemen Menu & Stok**:
    - Tombol "Kalkulator Markup Komisi" membuka modal dengan formula presisi `CEIL((Harga Asli / 0.90) / 500) * 500`, lengkap dengan simulasi margin surplus mitra.
    - Toggle ketersediaan menu ("Tersedia" / "Stok Habis") berfungsi mulus dan responsif.
  - **Tab 3: Pengaturan Toko**:
    - Switch buka/tutup lapak instan berfungsi secara reaktif mengubah status badge toko ("TOKO BUKA" / "TOKO TUTUP").
    - Seluruh preferensi printer Bluetooth SPP 58mm, auto-accept 180s, dan estimasi waktu masak tampil sempurna.

---

## 13. Elevasi Total Menuju Visual Parity 11/12 dengan Portal Customer (Zero AI Slop)

* **Tanggal Elevasi**: `2026-11-21`
* **Audit Paritas Dart & Vision Lintas Portal**: Dilakukan perbandingan mendalam dengan kode produksi Customer Portal (`ab7f6a31-982e-4360-a939-167a27a79a39`), specifically `lib/core/theme/gage_theme.dart` (`TikTok Sans`), `lib/shared/widgets/gage_bottom_nav_bar.dart`, `lib/features/orders/presentation/orders_screen.dart`, dan `lib/shared/widgets/gage_floating_sheet.dart`.
* **Pemberantasan Elemen AI Slop**:
  1. **Tipografi & Font**: Mengeliminasi seluruh ketergantungan `GoogleFonts.plusJakartaSans` di layar merchant yang memicu inkonsistensi font. Seluruh komponen kini mewarisi font global resmi `TikTok Sans` via `GageTheme`.
  2. **Header Kios**: Mengganti kotak avatar merah generic dengan circular storefront avatar asli (`assets/images/resto_dimsum_sewu.png`), menyematkan `GageMerchantTierBadge(tier: 'star')` resmi, dan tombol status toko `TOKO BUKA` full capsule (`BorderRadius.circular(999)`).
  3. **Floating Island Navigation Bar**: Menghapus pinned bottom bar legacy dan mengimplementasikan `MerchantFloatingNavBar` (`lib/features/merchant/presentation/widgets/merchant_floating_nav_bar.dart`) dengan geometri floating frosted-glass island (`margin: 16`, `height: 60`, `BorderRadius.circular(32)`, `BackdropFilter: 24`, border transparan elegan, haptic feedback, dan notification badge counter).
  4. **Order Card Interaktif**:
     - Mengintegrasikan `_buildInvoiceChip` dengan icon copy merah dan notifikasi salin instan.
     - Standarisasi badge status order menggunakan token kanonik (`0xFFFEF3C7`/`0xFFB45309` untuk Pesanan Baru & Sedang Disiapkan, `0xFFDCFCE7`/`0xFF15803D` untuk Siap Dijemput & Selesai).
     - Menghapus container pink `[2x]` kaku dan menggantinya dengan foto makanan asli (`_buildItemImage`) berukuran 44x44 dengan sudut rounded 8px.
     - Seluruh tombol aksi order (`Tolak Pesanan`, `Terima Pesanan`, `Hubungi`, `Ubah Stok`, `Siap`, `Selesaikan Pesanan`) menggunakan `shape: const StadiumBorder()`.
  5. **Migrasi Seluruh Modal ke `GageFloatingSheet`**:
     - `_showRejectOrderModal`: Modal tolak pesanan dengan peringatan penalti poin penerimaan dan tombol `StadiumBorder()`.
     - `_showModifyOrderStockOutModal`: Modal 3 alur cerdas operasional stok habis dengan kartu opsi rounded 16px.
     - `_showSubstituteItemDialog` & `_showPartialFulfillDialog`: Input textfield dan dropdown berbentuk kapsul (`BorderRadius.circular(24)`).
     - `_showMarkupCalculatorDialog`: Menampilkan kalkulator markup otomatis formula resmi GAGE (`CEIL((Harga Asli / 0.90) / 500) * 500`) dengan breakdown transparansi margin dan input kapsul (`BorderRadius.circular(24)`).
     - `_showAddMenuDialog`: Form tambah menu baru dengan input kapsul dan formula kalkulasi real-time.
  6. **Tab 2 (Menu & Stok)**:
     - Mengganti icon generic hamburger 52x52 dengan foto hidangan nyata (`assets/images/dish_*.png`) berukuran 68x68 rounded 12px.
     - Format harga menampilkan harga efektif GAGE tebal merah, harga coret warung offline, dan pill status ketersediaan `TERSEDIA`/`HABIS` (`BorderRadius.circular(999)`).
     - Tombol `Kalkulator Markup Komisi` dan `Tambah Menu` menggunakan `StadiumBorder()`.
     - Padding scrollable list diberi jarak bawah `96px` sehingga tidak pernah terpotong oleh floating island navbar.
  7. **Tab 3 (Pengaturan Toko)**:
     - Padding list bawah `96px`, seluruh tombol eksternal (Kelola Toko & WhatsApp Support) menggunakan `shape: const StadiumBorder()`.
* **Hasil Verifikasi Akhir**:
  - `flutter analyze lib/features/merchant/ lib/providers/merchant_order_provider.dart lib/main_merchant.dart`: **No issues found!** (0 error, 0 warning).
  - `flutter test test/merchant_handoff_contracts_test.dart test/merchant_order_flow_test.dart test/merchant_workstation_widget_test.dart`: **19/19 tests passed (100%)**.
  - **Uji Coba Langsung di Samsung Galaxy Z Flip3 (SM-F711B / R5CR81GTJDD)**: Sukses diinstal (`app-merchant-debug.apk`) dan diverifikasi melalui tangkapan layar live pada Tab 1 (Orders), Tab 2 (Menu & Stok), Tab 3 (Pengaturan Toko), Modal Kalkulator Markup, Modal Ubah Stok 3 Alur Cerdas, Modal Tolak Pesanan, dan Layar In-App Chat.

---

## 14. Master Rekayasa Ulang Logika Bisnis & Eliminasi 12 Anomali Nirlogika

* **Tanggal Pembaruan**: `2026-11-21`
* **Agent Swarm Audit**: Divalidasi oleh swarm 12 agen mandiri (model `3.8 flash`) yang membedah seluruh alur bisnis, keuangan, dan siklus hidup transaksi merchant terhadap Customer Portal sesi `ab7f6a31-982e-4360-a939-167a27a79a39`.
* **12 Anomali Logika Bisnis yang Telah Diperbaiki Secara Total**:
  1. **Omset Toko Bersih vs Omset Semu**:
     - *Masalah*: Kartu pesanan dan laporan harian merchant sebelumnya menampilkan `order.totalAmount` yang tercampur ongkir driver dan biaya admin aplikasi.
     - *Solusi*: Ditambahkan getter kanonik di `OrderModel`: `merchantGrossOmset = itemsSubtotal`, `platformCommissionAmount = round(itemsSubtotal * 0.10)`, dan `merchantNetPayout = itemsSubtotal - platformCommissionAmount`. Layar kasir kini menampilkan Penerimaan Bersih Toko (bold hijau) dan rincian omset kotor dipotong komisi platform 10%.
  2. **Pencegahan Exploit Finansial Gratis pada Pesanan COD**:
     - *Masalah*: Saat pesanan tunai (`CASH_COD`) dibatalkan atau itemnya kosong, sistem sebelumnya salah memberikan pengembalian dana berupa saldo GagePay gratis (`refundAmount = outOfStockSum`), padahal pelanggan belum membayar sepeser pun uang tunai kepada kurir/merchant.
     - *Solusi*: Pada pesanan Tunai/COD, `refundAmount` ditetapkan mutlak `0`, dan sistem mencatat pemotongan tagihan tunai kurir melalui `codAdjustment = -outOfStockSum`. Pelanggan hanya membayar sisa barang yang ready tanpa exploit saldo gratis.
  3. **Penyelamatan Data Varian & Add-On di Payload Checkout**:
     - *Masalah*: `CheckoutScreen.dart` hanya mengirim nama menu dan harga flat, membuang data `selectedVariants` dan `variantPrice` sehingga level pedas, topping, dan selisih harga varian hilang saat order masuk ke database dan layar workstation dapur.
     - *Solusi*: Payload `itemsPayload` di `checkout_screen.dart` kini menyertakan `base_price`, `variant_price`, dan `selected_variants`. Workstation merchant menampilkan pill varian terpisah dari catatan khusus pelanggan.
  4. **Koreksi Inversi Lifecycle Handover vs Selesai**:
     - *Masalah*: Tombol "Serahkan ke Kurir" sebelumnya langsung memanggil `completeOrder()` yang mengubah status pesanan menjadi `COMPLETED`, mematikan GPS tracking customer saat kurir baru berangkat mengantar makanan.
     - *Solusi*: Ditambahkan alur `handoverToCourier()` dengan modal verifikasi PIN kurir (`_showHandoverPinModal`). Status berpindah ke `PICKED_UP`, lalu driver mengantar (`ON_DELIVERY`) hingga customer/driver menuntaskan ke `COMPLETED`.
  5. **Eliminasi Black Hole Status Kurir pada Layar Kasir**:
     - *Masalah*: Saat kurir mengubah status pesanan ke `AT_MERCHANT`, `PICKED_UP`, atau `ON_DELIVERY`, pesanan lenyap dari tab pesanan kasir karena filter hanya membaca `COOKING` atau `READY_FOR_PICKUP`.
     - *Solusi*: `activeOrders` di `MerchantOrderProvider` diperluas mencakup seluruh siklus hidup berjalan (`NEW`, `PAID`, `COOKING`, `READY_FOR_PICKUP`, `DRIVER_ASSIGNED`, `AT_MERCHANT`, `PICKED_UP`, `ON_DELIVERY`). Order card menampilkan banner highlight kurir tiba (`AT_MERCHANT`) dan pill kurir sedang di jalan (`PICKED_UP`).
  6. **Pseudo-PIN Kurir Statis Diperbaiki Menjadi PIN Unik**:
     - *Masalah*: Mengambil 4 digit pertama invoice diawali `2026...` menyebabkan seluruh pesanan memiliki PIN kurir yang sama persis (`2026`).
     - *Solusi*: Getter `courierVerificationPin` kini mengambil 4 digit numerik terakhir dari invoice unik (misal invoice unik `GALIH-8822` menghasilkan PIN `8822`, invoice `SITI-8821` menghasilkan `8821`).
  7. **Deteksi Pesanan Ambil Sendiri (Pickup) Tanpa String Matching Rapuh**:
     - *Masalah*: Merchant memeriksa pickup menggunakan string `address.contains('ambil')` yang rentan gagal jika nama jalan mengandung kata "ambil" atau alamat diformat lain.
     - *Solusi*: Menggunakan typed boolean resmi `order.isPickupOrder` (`isPickup || deliveryOption == 'PICKUP'`). Pesanan pickup menampilkan badge khusus `AMBIL SENDIRI (PICKUP)` berwarna oranye, menyembunyikan kotak kurir, dan memberikan tombol aksi kasir langsung: *"Selesaikan Pesanan (Diambil Pelanggan Langsung)"* yang mentransisikan order langsung ke `COMPLETED`.
  8. **Jadwal Operasional Aktif (Buka/Tutup Otomatis)**:
     - *Masalah*: Jadwal toko bersifat pasif, toko tetap buka jam 02:00 pagi dan auto-accept order saat pemilik lapak tidur.
     - *Solusi*: Ditambahkan helper `MerchantOperatingSchedule.isCurrentlyWithinSchedule({DateTime? now})` untuk evaluasi jam buka riil setiap hari. Header toko dan Tab 3 kini dilengkapi quick toggle 3-status terpadu: `TOKO BUKA`, `DAPUR SIBUK` (jeda 15/30/60 menit), dan `TOKO TUTUP`.
  9. **Foreground Polling Real-Time & Audio Alert**:
     - *Masalah*: Hitung mundur auto-accept di memori RAM dibekukan OS saat layar mati atau app di background, dan tidak ada polling update pesanan masuk.
     - *Solusi*: Ditambahkan periodic polling 4 detik (`startPolling()`, `stopPolling()`) pada `MerchantOrderProvider`, audio alert `GageAudioService.instance.playRecordStartChime()` saat pesanan baru terdeteksi, dan timer Mode Sibuk yang otomatis meresume toko saat waktu jeda dapur selesai.
  10. **Isolasi Dompet Finansial & Saldo Terpadu Toko**:
     - *Masalah*: Tab 3 sebelumnya tidak menampilkan saldo dompet toko secara real-time dan terisolasi dari transaksi berjalan.
     - *Solusi*: Dibuat Hero Card Dompet Mitra GAGE di Tab 3 yang menampilkan:
       * **Saldo Siap Ditarik** (`merchant.availableBalance`): Akumulasi saldo bersih omset toko.
       * **Saldo Tertahan (Escrow)** (`merchant.escrowBalance`): Akumulasi omset bersih pesanan aktif yang sedang dimasak/diantar kurir.
       * **Net Selesai Hari Ini** (`merchant.todayNetRevenue`): Omset bersih setelah komisi 10% untuk pesanan tuntas hari ini.
       * **Modal Pencairan Dana** (`_showWithdrawModal`): Fitur tarik dana instan ke Bank BRI (bebas biaya) atau saldo GagePay Mitra.
  11. **Perbaikan Persistensi Data Lapak & Radius Pengiriman**:
     - *Masalah*: Menyimpan profil toko sebelumnya menimpa objek `MerchantStorefrontData` baru sehingga menghapus `categoryOrder`, `itemPromoPrices`, `landmark`, dan `deliveryRadius`. Slider radius pengiriman selalu reset ke 7 KM.
     - *Solusi*: Menggunakan `(existing ?? ...).copyWith(...)` saat menyimpan profil toko (`_persistStorefront()`). Slider radius pengiriman menyimpan nilai secara persisten dengan `onChangeEnd`.
  12. **Integrasi Titik Lokasi Peta & Deteksi GPS Akurat**:
     - *Masalah*: Koordinat toko diketik angka desimal manual tanpa peta visual atau deteksi GPS perangkat.
     - *Solusi*: Terintegrasi langsung dengan `FullScreenMapPicker.open()` (peta interaktif standar GAGE) dan `LocationService.getCurrentLocation(forceFresh: true)` untuk deteksi titik GPS otomatis kios. Ditambahkan input `landmark` (patokan lapak, misal *"Sebelah gapura desa, tenda merah"*) untuk memudahkan kurir driver menemukan kios.
* **Hasil Automated Test Suite**:
  - `flutter test test/merchant_handoff_contracts_test.dart test/merchant_order_flow_test.dart test/merchant_workstation_widget_test.dart`: **22/22 tests passed (100%)** bebas regresi.

---

## 15. Master Arsitektur 5 Tab Baku Merchant & Paritas Kelas Dunia (Shopee Partner Parity)

* **Tanggal Implementasi**: `2026-11-21`
* **Target Hardware**: Samsung Galaxy Z Flip3 (`SM-F711B`, serial `R5CR81GTJDD`, display `4630947232161729154`).
* **Prinsip Higienitas Merek**: 100% terminologi murni GAGE (`GageMerchant`, `GagePay`, `GageFood`, `GageMarketing`, `GageOutlet`), **nol penggunaan kata merek pihak ketiga** di seluruh kode dan komentar produksi.

### A. Struktur 5 Tab Baku pada Floating Bottom Navigation Bar
Floating bottom navigation bar didesain ulang dengan arsitektur `Stack(children: [ Positioned.fill(...), Positioned(bottom: 0, child: MerchantFloatingNavBar(...)) ])` sehingga **melayang 100% bebas** di atas konten (tanpa kontainer penampung di belakang kapsul):
1. **Tab 0: `Pesanan` ([`gage_merchant_orders_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart))**:
   - 4 Segmented Tab Kapsul GAGE: `Disiapkan`, `Siap`, `Diantar`, `Selesai` (`BorderRadius.circular(999)` + active thumb merah + `HapticFeedback.selectionClick()`).
   - Format invoice adaptif pendek: `#${order.orderNumber.split('/').last}` (e.g. `#GALIH-8822`) dibungkus `Flexible` untuk mencegah RenderFlex overflow pada layar ponsel sempit (360-380dp).
   - **Pembalikan Logika PIN Penyerahan**: Merchant yang men-generate dan menampilkan PIN 4 digit unik (`courierVerificationPin`, misal `3304`) di kartu pesanan status `READY_FOR_PICKUP` dalam kotak kuning-amber (`#FEF3C7`), dan Driver yang bertugas menginput PIN di aplikasi Driver saat mengambil makanan di kios.
2. **Tab 1: `Chat` ([`gage_merchant_chat_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_chat_tab.dart))**:
   - In-App Chat Hub 1:1 identik dengan Customer Portal.
   - Filter capsule atas: `Semua`, `Driver`, `Pelanggan`, `Bantuan CS GAGE`.
   - Thread terintegrasi dengan badge status real-time (`Bantuan CS`, `Driver GAGE`, `Pelanggan`) dan unread counter merah.
3. **Tab 2: `Outlet` ([`gage_merchant_outlet_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_outlet_tab.dart))**:
   - Hero Card Omset & Skor Toko (`GAGE Food` badge, `Total Penjualan (Rp)`, `Total Transaksi`, `Skor Outlet 😊 98/100`).
   - Quick Status & Jadwal: `Toko Buka Menerima Pesanan` dengan tombol `Atur Jadwal` (`showOperatingScheduleEditorSheet`).
   - 8 Grid Aksi Operasional: `Menu`, `Keuangan`, `Pasang Iklan`, `Wawasan`, `Penilaian`, `Penalti`, `Pusat Edukasi`, `Pusat Bantuan`.
   - Banner `JADI STAR RESTO GAGE` (prioritas kurir & komisi spesial) dan Card Edukasi `INFORMASI NOMOR INDUK BERUSAHA (NIB)`.
4. **Tab 3: `Marketing` ([`gage_merchant_marketing_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_marketing_tab.dart))**:
   - `Aktivitas Saya`: Ringkasan kuantitatif Promo & Iklan (`Mendatang` vs `Berjalan`).
   - Fitur Promo: `Diskon Menu` (Harga Coret `promo_price`), `Diskon Langsung` (Voucher Toko baru).
   - Campaign Promo: `Flash Sale GAGE Food` dengan tanggal pendaftaran dan tombol `Mulai`.
   - Fitur Iklan: `Iklan Pencarian`, `Iklan Rekomendasi`, `Pencarian & Rekomendasi`, `Iklan Banner`.
   - Campaign Iklan: `Paket Iklan GAGE Food & Komisi Affiliate` dengan tombol `Mulai`.
5. **Tab 4: `GagePay` ([`gage_merchant_gagepay_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_gagepay_tab.dart))**:
   - Hero Dark Card `GagePay Toko`: Saldo Siap Ditarik (`merchantNetPayout`), badge `Akun Terverifikasi`.
   - Tombol Aksi Cepat: `Tarik Dana` (`GageWithdrawSheet` via Flip ke Bank BRI/BCA/Mandiri/E-Wallet biaya flat Rp 1.000), `QRIS Kasir` (`GagePayReceiveScreen` QRIS dinamis toko), dan Transfer saldo.
   - Payout Bank Info Card: `Rekening Utama Bank BRI • 0012-9941-2914 a.n Dimsum Sewu`.
   - Riwayat Transaksi Toko: Filter segmented `Semua`, `Hasil Penjualan`, `Penarikan Bank` dengan badge nominal hijau (+)/merah (-).

### B. Header Toko Bersih & Ergonomis
- Header atas kanan hanya menampilkan 1 ikon Lonceng Notifikasi (`NotificationService.instance.unreadCount`) dan ikon Roda Gigi Pengaturan Toko (`MerchantProfileScreen`).
- Ikon chat di header dihilangkan sepenuhnya karena telah memiliki Tab Baku independen di bottom navbar (Tab 1).

### C. Hasil Uji Hardware Langsung (Samsung Galaxy Z Flip3 SM-F711B)
- `app-merchant-debug.apk` di-build dan di-install via ADB.
- Seluruh 5 Tab diverifikasi visual live di layar lipat utama:
  - Tab 0: `merchant_live_tab0_fixed.png` (Invoice pendek rapi tanpa overflow, Segmented Tab Kapsul).
  - Tab 0 (Subtab Siap): `merchant_live_orders_siap.png` (Box PIN Penyerahan Driver `3304`).
  - Tab 1 (Chat): `merchant_live_tab1_chat.png` (In-App Chat Hub & Filter Capsule).
  - Tab 2 (Outlet): `merchant_live_tab2_outlet.png` (Hero Omset, 8 Grid Aksi, Star Resto, Info NIB).
  - Tab 3 (Marketing): `merchant_live_tab3_marketing.png` (Aktivitas Saya, Promo, Iklan, Campaign).
  - Tab 4 (GagePay): `merchant_live_tab4_gagepay.png` (Hero Saldo Toko, Rekening BRI, Riwayat).
  - QRIS Kasir Toko: `merchant_live_qris_detail.png` (QRIS Dinamis a.n DIMSUM SEWU KASIR).
  - Tarik Saldo GagePay: `merchant_live_withdraw_ok.png` (Pencairan instan via Flip, form nominal, rekening bank).
- Automated Tests: `flutter test test/merchant_workstation_widget_test.dart test/merchant_handoff_contracts_test.dart test/merchant_order_flow_test.dart`: **22/22 tests passed (100%)**.

---

## 9. Penyempurnaan UX Merchant & Paritas 1:1 GagePay Customer (Wave 3 Iterasi 2)

* **Target Rilis**: `2026-11-21`
* **Commitment**: Eliminasi total redundansi navigasi, unifikasi dompet GagePay 1:1 dengan Customer Portal, dan penyusunan ulang aksi operasional kios.

### A. Eliminasi Total Bottom Navbar Ganda pada Child Subpages
Sebelumnya, ketika merchant menekan menu seperti "Menu & Stok" (`MerchantMenuScreen`) atau "Lokasi & Peta" (`MerchantProfileScreen`), layar anak merender ulang `bottomNavigationBar: const MerchantBottomNavBar(...)`, menciptakan pengalaman pengguna membingungkan ("seperti membuka aplikasi lain").
- **Tindakan**: Menghapus seluruh properti `bottomNavigationBar` dari subpage child:
  - `merchant_menu_screen.dart`
  - `merchant_profile_screen.dart`
  - `merchant_chat_list_screen.dart`
  - `merchant_finance_screen.dart`
  - `merchant_screen.dart`
- **Hasil**: Setiap subpage kini bertindak sebagai child screen murni dengan AppBar back button otomatis yang bersih dan kembali ke Workstation Root secara mulus.

### B. Paritas 1:1 GagePay Customer di Tab 4
Tab 4 Merchant kini mengadopsi widget asli `GagePayScreen` (`isEmbeddedInTab: true`) yang terhubung langsung ke `WalletProvider` dan `AuthProvider` di `main_merchant.dart`:
- **Interactive 3D Leather Pocket Wallet (`GagePocketWallet`)**: Tampilan saku dompet kulit mewah dengan saldo utama, poin loyalitas, serta fan-out tumpukan kartu bank (BCA, Mandiri, GoPay) yang responsif terhadap ketukan (membuka *3D Flip Card Dialog*).
- **Dual Action Capsule Buttons**: Tombol gradien elegan `Kirim` (ungu) dan `Terima` (hijau) bergeometri full-capsule (`BorderRadius.circular(999)`).
- **Quick Actions Bar**: `Top Up`, `QRIS`, `Tarik Tunai`, `Poin Reward`.
- **Promo Banner & Transaction History**: Filter chips kapsul (`Semua`, `Transfer`, `Pemasukan`, `Penarikan`, `Pengeluaran`).

### C. Pembersihan Tab Outlet & Eliminasi Redundansi
1. **Pembersihan Settings Gear Kedua**: Menghapus tombol gear redundan di Tab Outlet dan Tab Marketing, menyisakan tepat 1 gear resmi di header utama workstation.
2. **Rekonfigurasi 6-Aksi Operasional Murni (2 baris x 3 item)**: Menghapus tombol shortcut `Keuangan` (redundant dengan Tab GagePay) dan `Pasang Iklan` (redundant dengan Tab Marketing) dari grid. Menyusun 6 aksi operasional kios:
   - `Menu & Stok` (`Icons.restaurant_menu_rounded`) -> `MerchantMenuScreen` (tanpa navbar ganda).
   - `Jadwal Toko` (`Icons.schedule_rounded`) -> `showOperatingScheduleEditorSheet`.
   - `Lokasi & Peta` (`Icons.storefront_rounded`) -> `MerchantProfileScreen`.
   - `Penilaian` (`Icons.star_rounded`) -> Modal ulasan & rating toko 4.9/5.0.
   - `Wawasan Dapur` (`Icons.insights_rounded`) -> Metrik waktu masak & jam sibuk dapur.
   - `Pusat Bantuan` (`Icons.support_agent_rounded`) -> Kontak CS Mitra 24 jam & WhatsApp hotline.
3. **Penghapusan Kartu NIB**: Menghilangkan kartu legalitas NIB sepenuhnya dari Tab Outlet (tidak relevan bagi operasional harian UMKM Pracimantoro).
4. **Banner Carousel Slider Star Resto Interaktif (`MerchantPromoBannerSlider`)**:
   - `PageView` dengan titik indikator kapsul (`BorderRadius.circular(999)`).
   - 3 Slide fungsional: Star Resto (dengan tombol *Syarat & Gabung* yang membuka kualifikasi: Rating >= 4.8, Pesanan >= 50, Pembatalan < 1%, Waktu Masak < 15 mnt), Festival Kuliner, dan Standar Higienis Dapur.

### D. Hasil Uji & Verifikasi Hardware Live (Samsung Galaxy Z Flip3 SM-F711B)
- **Static Analysis**: `dart analyze lib/features/merchant lib/main_merchant.dart lib/features/wallet/presentation/gagepay_screen.dart` -> **No issues found!**
- **Automated Tests**: `flutter test test/merchant_workstation_widget_test.dart test/merchant_handoff_contracts_test.dart test/merchant_order_flow_test.dart` -> **22/22 tests passed (100%)**.
- **Live Hardware Screenshots**:
  - `merchant_parity_tab0.png`: Tab Pesanan Masuk (Header bersih, Segmented Tab Kapsul).
  - `merchant_parity_tab2_outlet.png`: Tab Outlet (6-grid operasional bersih, Banner Carousel Slider dengan dots, TANPA kartu NIB, TANPA gear ganda).
  - `merchant_parity_star_resto_modal.png`: Dialog Syarat Kualifikasi Star Resto yang terbuka fungsional.
  - `merchant_parity_menu_no_navbar.png`: Layar Katalog Menu dibuka dari Outlet -> Bersih dengan tombol back AppBar dan **TIDAK ADA bottom navbar ganda**.
  - `merchant_parity_tab4_gagepay.png`: Tab GagePay 1:1 identik dengan Customer (3D Pocket Wallet, fan-out kartu ATM, dual action Kirim/Terima, riwayat transaksi).
  - `merchant_parity_flip_card.png`: Modal 3D Flip Card details rekening.

---

## 10. Iterasi Komprehensif: PIN Acak Serah Terima Driver, Struk Thermal, Floating Sheet & Paritas Navbar 1:1 (Wave 3 Iterasi 3)

* **Target Rilis**: `2026-11-22`
* **Target Hardware**: Samsung Galaxy Z Flip3 (`SM-F711B`, serial `R5CR81GTJDD`, display ID `4630947232161729154`).

### A. PIN 4-Digit Acak Serah Terima Pesanan (`handoverPin` / `courierVerificationPin`)
1. **Logika Pembuatan & Verifikasi**:
   - Merchant bertindak sebagai pihak yang men-generate PIN 4-digit acak (`1000 - 9999`) saat pesanan diterima dan disiapkan.
   - Driver bertindak sebagai pihak yang meng-input PIN ini di aplikasi kurir saat mengambil pesanan fisik di dapur/toko merchant.
   - Tidak lagi mengambil 4 digit terakhir nomor invoice (untuk menghindari tebakan).
   - Ditambahkan kemampuan **Acak Ulang PIN** (`MerchantOrderProvider.regenerateHandoverPin(orderId)`) langsung dari detail pesanan merchant.
2. **Kontrak Model & D1**:
   - Properti model: `OrderModel.handoverPin` (nullable `String?`).
   - Getter fallback: `OrderModel.courierVerificationPin` memprioritaskan `handoverPin`, dengan fallback deterministic hash bila null.
   - Kolom backend D1: `ALTER TABLE orders ADD COLUMN handover_pin TEXT;`.

### B. Paritas Penuh 1:1 Floating Bottom Navbar ala Customer Portal
1. **Geometri & Styling**:
   - Dimensi & Outer Margin: `EdgeInsets.fromLTRB(16, 0, 16, 12)`, tinggi `60px`, outer radius `BorderRadius.circular(32)`, `BackdropFilter` sigma blur `24x24`.
   - Selected Tab Pill: tinggi `50px`, margin snug-fit `EdgeInsets.symmetric(horizontal: 6, vertical: 3)`, sudut kapsul penuh `BorderRadius.circular(999)`.
   - Warna teks & ikon pill aktif: `isDark ? Colors.white : const Color(0xFF0F172A)` (bukan warna merah aksen yang menusuk).
   - Ikon tab resmi:
     - Tab 0: Pesanan (`Icons.receipt`)
     - Tab 1: Chat (`Icons.chat_bubble_rounded`)
     - Tab 2: Outlet (`Icons.storefront_rounded`)
     - Tab 3: Marketing (`Icons.campaign_rounded`)
     - Tab 4: GagePay (`Icons.account_balance_wallet_rounded`)

### C. Detail Pesanan Lengkap via Floating Sheet (`MerchantOrderDetailSheet`)
- Mengetuk kartu pesanan membuka sheet detail lengkap berbingkai rounded floating `GageFloatingSheet.show`:
  - Header status badge & ID pesanan.
  - Box PIN Serah Terima Kurir 4-digit acak berukuran besar (dengan tombol interaktif *Acak Ulang PIN*).
  - Profil & kontak Pelanggan (dengan tombol Chat in-app).
  - Profil & kontak Driver/Kurir penjemput (dengan tombol Chat in-app & plat kendaraan).
  - Daftar menu, rincian varian, catatan dapur, dan jumlah porsi.
  - Transparansi Margin & Komisi Platform: Subtotal pesanan, komisi GAGE 10%, dan Payout Bersih Toko.
  - Tombol aksi: Cetak Struk Thermal & Perbarui Status Pesanan.

### D. Fitur Cetak Struk Thermal 58mm / 80mm (`MerchantThermalReceiptSheet`)
- Tampilan realistis roll kertas kasir monospace putih dengan garis potong putus-putus (`_buildReceiptDashedLine`).
- Switcher segmented kapsul `58mm` vs `80mm`.
- Banner status koneksi printer Bluetooth SPP.
- Aksi Salin Teks Struk Monospace & Cetak Struk Sekarang (terhubung ke `MerchantOrderProvider.printOrderReceipt`).

### E. Eliminasi Garis Solid & Kompresi Padding Kontainer
- Menghapus garis divider tebal solid di seluruh kartu dan kontainer. Digantikan dengan pembatas tipis `Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200)`.
- Memadatkan padding vertikal kartu pesanan dan section menjadi `12-14px` agar hemat ruang vertikal dan pas di layar lipat Galaxy Z Flip3.

### F. Suite Marketing Anti-Gimmick Berfungsi Penuh
- **Diskon Menu**: Link langsung ke katalog menu untuk pengaturan promo harga coret per item.
- **Diskon Langsung Toko**: Floating sheet pengaturan nominal voucher potongan toko (Rp) & minimal belanja.
- **Flash Sale GAGE Food**: Floating sheet pendaftaran sesi kilat, slider diskon %, dan alokasi kuota porsi.
- **Iklan Toko (Pencarian, Rekomendasi, Banner)**: Floating sheet durasi tayang (3/7/14 hari), slider budget harian (Rp 10.000 - 50.000/hari), dan estimasi total investasi.
- **Bagi Hasil Affiliate**: Slider komisi bagi kreator video & kurir.

### G. Migrasi Menyeluruh ke `GageFloatingSheet` (Frosted Glass Blur)
- Menggantikan seluruh `AlertDialog`, `showDialog`, dan `showModalBottomSheet` standar dengan `GageFloatingSheet.show`:
  - `MerchantOrderDetailSheet`
  - `MerchantThermalReceiptSheet`
  - `OperatingScheduleEditorSheet`
  - Star Resto Qualification Sheet
  - Skor Outlet Breakdown Sheet
  - Branch Switcher Sheet
  - Reject Order Confirmation Sheet
  - Marketing Campaign Activation Sheets

### H. Bukti Verifikasi Hardware Live (Samsung Galaxy Z Flip3)
- `merchant_screen_orders_tab.png`: Tab Pesanan Masuk (Navbar floating 1:1, kartu padat, PIN acak `2706`, tombol print cepat).
- `merchant_screen_thermal_receipt.png`: `MerchantOrderDetailSheet` di dalam `GageFloatingSheet`.
- `merchant_screen_thermal_receipt_open.png`: `MerchantThermalReceiptSheet` dengan preview roll kasir 58mm/80mm monospace.
- `merchant_screen_marketing_tab.png`: Tab Marketing interaktif 1:1.
- `merchant_screen_ad_sheet.png`: Floating sheet Iklan Toko dengan slider budget & durasi.
- `merchant_screen_outlet_tab.png`: Tab Outlet bersih tanpa redundansi.
- `merchant_screen_star_resto_sheet.png`: Kualifikasi Star Resto di dalam `GageFloatingSheet`.
- `merchant_screen_gagepay_tab.png`: GagePay 1:1 Customer.
- `merchant_screen_chat_tab.png`: Tab Chat terpadu.




