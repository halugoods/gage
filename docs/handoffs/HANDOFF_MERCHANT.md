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

---

## 7. Pembaruan Wave 4: Autonomous Overnight Audit, Luxury Standard, & Customer Parity

* **Baseline Git Checkpoint**: `merchant-v3-overnight-baseline` (Dikomit dan diberi tag permanen pada repositori untuk revertability instan).
* **Hasil Verifikasi Test Suite Komprehensif**: 21 / 21 Tests Passed (`test/merchant_handoff_contracts_test.dart` & `test/merchant_comprehensive_audit_scenarios_test.dart`).

### A. Pemisahan Tegas Layar Penuh (Full Screen Page) vs Lembar Mengambang (Floating Sheet)
- **Halaman Layar Penuh (Full Screen Page with Native AppBar Back Button)**:
  1. `MerchantReviewScreen`:
     - Menampilkan metrik ulasan mendalam: Rating Hero Card `4.9 / 5.0` (98 ulasan pembeli), 5 bintang emas, diagram batang distribusi rating 5 hingga 1 bintang.
     - Segmented Filter Chips Kapsul 999: *Semua*, *Dengan Foto*, *Rasa Enak*, *Porsi Pas*, *Kemasan Rapi*.
     - Daftar ulasan riil pembeli dengan menu yang dipesan, tanggal, dan tanggapan resmi toko.
     - Modal balas ulasan pelanggan dengan form field mewah anti-slop radius 14.
  2. `MerchantKitchenInsightsScreen`:
     - 4 Kartu KPI Utama: Waktu Masak rata-rata (8.5 mnt - Sangat Cepat), Tingkat Penyelesaian (100% - 0 Batal), Akurasi Bahan Dapur (98.5%), dan Kepuasan Pelanggan (4.9 / 5.0).
     - Diagram batang visual interaktif Jam Sibuk Dapur: Pagi (10%), Siang (45% Puncak), Sore (20%), Malam (25% Puncak).
     - Tip operasional dapur Pracimantoro.
     - Daftar 5 Menu Terlaris (Paling Laku) dengan omset kotor dan kuantitas porsi terjual.
- **Lembar Mengambang Cepat (GageFloatingSheet)**:
  1. `MerchantSupportSheet`: Pusat bantuan cepat mitra dengan hotline panggilan telepon & WhatsApp resmi CS GAGE Pracimantoro 24/7 + FAQ panduan operasional toko.
  2. `MerchantOrderDetailSheet`: Rincian instan pesanan & PIN serah terima.
  3. `MerchantThermalReceiptSheet`: Cetak cepat struk kasir thermal 58mm / 80mm.

### B. Standardisasi Form Field Mewah (Anti-Slop Luxury Input Fields)
- Seluruh form field di portal merchant telah ditingkatkan mengikuti estetika Customer Portal:
  - Container berlatar lembut: `filled: true`, `fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)`.
  - Sudut radius mewah: `BorderRadius.circular(14)`.
  - Border samping tipis dan elegan: `BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))`.
  - Focused border beraksen tegas: `BorderSide(color: GageTheme.primary, width: 1.5)`.
  - Header label eksternal tebal di atas input field + prefix icon tematik.
  - Diterapkan pada:
    - Form Atur Diskon Langsung Toko (`gage_merchant_marketing_tab.dart`)
    - Form Tambah Menu Baru Dapur (`merchant_menu_screen.dart`)
    - Form Atur Harga Promo Coret (`merchant_menu_screen.dart`)
    - Form Edit Profil Kios, Titik Map, Foto, & Radius Antar (`merchant_profile_screen.dart`)
    - Form Balas Ulasan Pembeli (`merchant_review_screen.dart`)

### C. Sinkronisasi Voucher Toko Lintas Portal (Merchant -> Customer)
- Properti baru pada `MerchantStorefrontData`:
  - `directDiscountAmount` (`int?`): Nominal potongan harga voucher toko (Rp).
  - `minSpendAmount` (`int?`): Minimal belanja subtotal keranjang (Rp).
  - `directDiscountActive` (`bool?`): Status aktif diskon toko.
- Terhubung langsung ke `resto_detail_screen.dart` di Portal Customer:
  - Ketika mitra merchant mengaktifkan atau mengubah diskon toko di Tab Marketing, voucher otomatis disuntikkan ke barisan kartu `Voucher Toko` di halaman resto pelanggan dengan stub perforasi oranye, diskon nominal, dan label *"Spesial Mitra Toko"*.

### D. Fitur Pencarian Cepat Tab Pesanan
- Search Bar mewah kapsul 999 di `gage_merchant_orders_tab.dart` untuk memfilter pesanan seketika berdasarkan nomor invoice / nama pembeli di semua tahapan pesanan (Pesanan Masuk, Disiapkan, Siap Dijemput).

### E. Quick Replies Khusus Dapur & Kasir
- Menambahkan 5 Quick Replies khusus dapur saat `currentRole == 'merchant'` di `in_app_chat_screen.dart` untuk komunikasi cepat dengan Driver dan Pelanggan tanpa mengetik manual saat jam sibuk.

---

## 8. Pembaruan Wave 5: Image Picker Kamera/Galeri & Kalkulator Harga In-Place Tambah Menu

* **Hasil Verifikasi Test Suite Komprehensif**: **24 / 24 Tests Passed (0 Failures)** (`test/merchant_handoff_contracts_test.dart` & `test/merchant_comprehensive_audit_scenarios_test.dart`).

### A. Image Picker Interaktif Foto Produk Menu Dapur
- **Masalah Teratasi**: Sebelumnya tambah menu hanya menyediakan chip statis preset tanpa opsi memilih foto riil dari perangkat.
- **Implementasi Baru di `merchant_menu_screen.dart`**:
  - Box upload foto interaktif dengan dua opsi tombol aksi cepat:
    1. **Kamera (`ImageSource.camera`)**: Memungkinkan staf dapur/kasir langsung memotret masakan segar dari wajan/meja saji.
    2. **Galeri HP (`ImageSource.gallery`)**: Memilih foto olahan grafis atau foto katalog yang sudah tersimpan di galeri perangkat.
  - Preview foto terpilih langsung ditampilkan dalam kontainer berukuran proporsional dengan tombol ganti foto dan hapus foto.
  - Opsi foto preset cepat (`Dimsum Ori`, `Dimsum Mentai`, `Resto Kios`) tetap disediakan sebagai fallback darurat.
  - Kompatibel dengan semua jenis URI/Path melalui helper `_buildMenuItemImage` (mendukung path lokal dari ImagePicker, URL http/https, maupun aset aplikasi).
  - Terintegrasi langsung ke parameter `image` pada `GageApiClient.createMerchantMenu`.

### B. Kalkulator Harga & Margin Bersih Terintegrasi In-Place (Anti-Rugi)
- **Masalah Teratasi**: Sebelumnya kalkulator harga terpisah dan tidak terintegrasi langsung di samping kolom harga pada form Tambah Menu, sehingga membingungkan mitra toko.
- **Implementasi Baru di `merchant_menu_screen.dart`**:
  - Kolom input **Harga Warung (Offline/Modal)** dan **Harga Jual di GAGE** kini ditempatkan berdampingan dalam satu card terpadu.
  - Saat Harga Warung diketik, sistem secara cerdas menghitung harga jual rekomendasi anti-rugi secara otomatis menggunakan `AffiliateCommissionService.calculateRecommendedOnlinePrice`.
  - Mitra juga dapat mengedit harga jual di GAGE secara fleksibel, dan disediakan tombol **Auto Anti-Rugi** untuk mengembalikan perhitungan ke formula resmi sewaktu-waktu.
  - **Tabel Rincian Kalkulator Transparan (Real-Time Live Breakdown)**:
    - Harga Jual ke Pelanggan: `Rp XX.XXX`
    - Potongan MDR Platform GAGE (10%): `- Rp X.XXX`
    - Potongan Komisi Kreator/Afiliasi (0% s/d 20%): `- Rp Y.YYY`
    - **Estimasi Pencairan Bersih Masuk Saldo**: `= Rp Z.ZZZ`
    - **Banner Analisis Margin Laba**:
      - Jika margin positif: Badge hijau *"✓ Margin Bersih Aman: +Rp ... di atas modal warung (Bebas Rugi!)"*.
      - Jika margin tipis/negatif: Badge peringatan *"⚠ Margin Tipis: Estimasi bersih Rp ... di bawah harga warung fisik!"*.

---

## 9. Pembaruan Wave 6: Audio Alarm Dapur Bising, Filter 6 Kategori Kapsul 999, Alur Tolak Beradab, Thermal Multi-Rangkap, Varian/Topping Builder, & Quick Status Operasional

* **Hasil Verifikasi Test Suite Komprehensif**: **32 / 32 Tests Passed (0 Failures)** (`test/merchant_workstation_widget_test.dart`, `test/merchant_handoff_contracts_test.dart`, & `test/merchant_comprehensive_audit_scenarios_test.dart`).
* **Verifikasi Hardware Fisik**: Berhasil diuji dan berjalan mulus pada Samsung Galaxy Z Flip3 (`R5CR81GTJDD`, Android 14) via build single flavor `app-merchant-debug.apk` (`applicationId = "com.gagepracimantoro.merchant"`).
* **Fix Responsif Struk Thermal pada Layar Fisik**: Layout pill selector rangkap cetak (1x, 2x, 3x) distrukturkan full-width horizontal kapsul 999 dengan `Expanded`, dan preview chips dibungkus `SingleChildScrollView` sehingga bebas dari segala overflow layout (0 overflow errors).

### A. Sistem Notifikasi Audio & Alarm Pesanan Masuk (Dapur Bising)
- **`GageAudioService`**:
  - `playOrderIncomingChime()`: Menghasilkan melodi arpeggio bertingkat 3 nada (D5 587Hz -> G5 784Hz -> C6 1046Hz) dengan harmonik overtone jernih berbasis sintesis waveform in-memory.
  - `startOrderAlertLoop()`: Mengulang alarm chime setiap 4 detik disertai getaran `HapticFeedback.heavyImpact()`, ideal untuk staf restoran dalam suasana dapur yang bising.
  - `stopOrderAlertLoop()`: Menghentikan loop alarm seketika saat kasir merespons pesanan.
  - Arsitektur lazy & safely guarded: Mencegah `MissingPluginException` pada eksekusi widget test headless tanpa mock platform channel.
- **`MerchantOrderProvider`**:
  - Properti `soundAlarmEnabled` (default `true`) dan toggle `toggleSoundAlarm`.
  - Otomatis membunyikan alarm loop saat pesanan berstatus `NEW`/`PAID` masuk, dan seketika berhenti saat pesanan diterima (`acceptOrder`) atau ditolak (`rejectOrder`).
  - Banner peringatan darurat di bagian atas tab pesanan dengan tombol instan *Heningkan Alarm* / *Alarm Nyala*.

### B. Filter Kategori Status Pesanan Lengkap: 6 Kategori Kapsul 999
- **`gage_merchant_orders_tab.dart`**:
  - 6 Kategori Kapsul Kebugaran UX:
    1. **Semua**: Seluruh riwayat pesanan aktif maupun selesai.
    2. **Perlu Konfirmasi**: Pesanan baru masuk (`NEW`, `PAID`) yang membutuhkan penerimaan kasir segera.
    3. **Sedang Dimasak**: Pesanan yang sedang diproses di dapur (`COOKING`).
    4. **Siap Diambil**: Pesanan matang yang menunggu penjemputan (`READY_FOR_PICKUP`, `DRIVER_ASSIGNED`, `AT_MERCHANT`).
    5. **Selesai**: Pesanan tuntas (`COMPLETED`).
    6. **Dibatalkan**: Pesanan batal (`CANCELLED`).
  - Desain horizontal scrollable dengan pill kapsul penuh `BorderRadius.circular(999)`, badge counter jumlah pesanan per kategori, active thumb `#E52320` dengan label putih tebal dan `HapticFeedback.selectionClick()`.

### C. Alur Penolakan / Pembatalan Pesanan Beradab
- Modal floating sheet tolak pesanan terstruktur di `gage_merchant_orders_tab.dart`:
  - 4 Alasan operasional resmi:
    - *Bahan baku habis (Menu tidak dapat disajikan)*
    - *Kios sedang sangat ramai / antre panjang*
    - *Toko tutup mendadak / kendala operasional*
    - *Kendala teknis / cuaca buruk / lainnya*
  - Input catatan tambahan kustom untuk pelanggan (Radius 14, styling mewah anti-slop).
  - Callout edukasi kepastian konsumen: Pelanggan menerima notifikasi resmi serta pengembalian dana 100% instan ke saldo GagePay, dan driver dibebastugaskan tanpa penalti.

### D. Cetak Struk Kasir Thermal Multi-Rangkap & Auto-Print
- **`merchant_thermal_receipt_sheet.dart`**:
  - Selector rangkap kapsul 999: `1x Tunggal`, `2x Rangkap (1 Dapur + 1 Kurir)`, `3x Rangkap (+ Kasir)`.
  - Toggle switch *Cetak Otomatis saat Pesanan Diterima* (`provider.autoPrintOnAccept`).
  - Pratinjau dinamis tiap lembar rangkap dengan header pembeda:
    - `>>> [ RANGKAP 1: SALINAN DAPUR ] <<<` (Merah Dapur)
    - `>>> [ RANGKAP 2: KURIR / PELANGGAN ] <<<` (Biru Kurir)
    - `>>> [ RANGKAP 3: ARSIP KASIR ] <<<` (Hijau Kasir)
  - Di `merchant_order_detail_sheet.dart` dan `gage_merchant_orders_tab.dart`: Saat tombol *Terima & Masak* ditekan, pesanan diterima sekaligus memicu pencetakan struk multi-rangkap secara otomatis ke printer thermal.

### E. Sistem Varian & Modifiers Menu (Add-ons / Topping Builder)
- **`merchant_menu_screen.dart`**:
  - Modul pembangun varian di dalam bottom sheet Tambah Menu Baru.
  - Pilihan preset cepat:
    - `+ Level Pedas` (Level 0 s/d Level 3)
    - `+ Pilihan Sambal` (Sambal Dimsum, Sambal Bangkok, Saus Mentai)
    - `+ Ekstra Topping` (Keju Mozzarella, Ekstra Siomay 1 pcs)
  - Tampilan tag visual per opsi dan tambahan biaya Rp.
  - Kartu daftar menu katalog menampilkan badge `✦ Varian` bila menu memiliki modifiers.
  - Tersimpan dan tersinkronisasi via `GageApiClient.createMerchantMenu(variantGroups: ...)`.

### F. Quick Status Operasional Toko (Buka / Istirahat / Tutup) & Audit Dark Mode
- **`merchant_root_screen.dart`**:
  - Bottom sheet cepat status toko dengan dukungan Dark Mode penuh (`0xFF1E293B`, `0xFF0F172A`).
  - Opsi: *Toko Buka Normal*, *Mode Sibuk (Jeda 15 Menit)*, *Mode Sibuk (Jeda 30 Menit)*, *Tutup Toko Sementara*.
  - Header utama toko kini menampilkan live countdown jeda: `ISTIRAHAT (30m)` dengan indikator bulat oranye.
  - Kontras tema gelap di seluruh form, badge, dan modal dialog tervalidasi memenuhi rasio kontras WCAG AA.

---

## 12. Dokumentasi Pembaruan Wave 7 (Luxury Refinement, Static Segmented Tabs, Full-Screen Order Detail, dan Android 14 Photo Picker ala NUSA Kasir)

* **Commit**: `8eaa9e0`
* **GitHub Release**: [`v1.0.4+39`](https://github.com/halugoods/gage/releases/tag/v1.0.4%2B39)
* **Status Pengujian**: **35 / 35 Tests PASSED (100%)**

### A. Segmented Tab Switch Statis (Non-Scrollable 4 Kategori Universal)
- **File**: `lib/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart`
- Menghapus pembungkus `SingleChildScrollView` horizontal.
- Menggunakan `Container` kapsul penuh 999 (`height: 44`, padding 3px) yang membungkus `Row` dengan 4 segmen `Expanded` proporsional.
- Dilengkapi `FittedBox(fit: BoxFit.scaleDown)` pada label (*Disiapkan*, *Siap Diambil*, *Sedang Diantar*, *Selesai*) dan badge counter untuk mencegah pemotongan teks maupun horizontal scrolling pada seluruh rasio layar ponsel.

### B. Eliminasi Total Garis Pembatas Horizontal Solid (`Divider`)
- Menghapus seluruh instansi `Divider(height: 1)` pada kontainer kartu pesanan, item breakdown, rincian pembayaran margin, kalkulator harga, dan menu profil.
- Menggantikannya dengan hierarki visual *breathing room* dan *tint grouping* lembut (`#F8FAFC` pada mode terang, `#0F172A` pada mode gelap).

### C. Detail Pesanan Layar Penuh (`MerchantOrderDetailScreen`)
- **File Baru**: `lib/features/merchant/presentation/merchant_order_detail_screen.dart`
- Menghadirkan halaman layar penuh mandiri:
  - Custom AppBar dengan badge nomor pesanan dan tag jenis layanan (*Pesan Antar* / *Ambil Sendiri*).
  - Kartu Status Operasional Universal dengan ikon dan deskripsi progresif.
  - Kartu PIN Verifikasi Kurir terpusat dengan teks tombol acak ulang PIN.
  - Kartu Informasi Pemesan & Kurir GAGE dengan integrasi tombol chat in-app.
  - Rincian produk dan transparansi margin kasir (MDR 10% dan pencairan bersih) tanpa garis solid.
  - *Sticky bottom action bar* berkapsul penuh (StadiumBorder) untuk tombol operasional (*Terima Pesanan*, *Pesanan Siap Diambil*, *Serahkan Pesanan*).
- **Kompatibilitas**: `merchant_order_detail_sheet.dart` bertindak sebagai *router forwarder* otomatis dengan injeksi `ChangeNotifierProvider.value`.

### D. Android 14 / One UI Photo Picker ala NUSA Kasir
- **File Baru**: `lib/features/merchant/presentation/widgets/merchant_photo_picker_sheet.dart`
- Mengadopsi arsitektur `mock_gallery_sheet.dart` dari NUSA Kasir:
  - Header native Android 14 dengan drag handle dan tombol tutup.
  - Segmented category switch kapsul 999: **Kuliner (Food)**, **Sembako (Shop)**, dan **Tani & Ternak (Farm)**.
  - GridView 3-kolom:
    - **Slot 0**: Tile Kamera fisik (`Icons.camera_alt_outlined`).
    - **Slot 1**: Tile Galeri perangkat (`Icons.photo_library_outlined`).
    - **Slot 2..N**: Katalog preset produk resmi beresolusi tinggi dengan *circular checkmark indicator* biru (`#1A73E8`).
  - Haptic feedback pada setiap ketukan.

### E. Standarisasi Luxury Form Fields & Penghapusan Sisa Bias Kuliner
- Form field seragam ber-background `#F8FAFC` / `#0F172A`, border `#E2E8F0`, rounded 14px, dan focus `#E52320`.
- Istilah *"Estimasi Waktu Masak Default"* diubah menjadi *"Estimasi Waktu Penyiapan Default"*, *"Auto-Print Tiket Dapur"* menjadi *"Auto-Print Tiket Pesanan"*, dan kalkulator dapur menjadi kalkulator produk universal.

---

## 13. Dokumentasi Pembaruan Wave 8 (Production 1:1 Image Cropper/Rotator, 5-Min Auto-Regenerating PIN, Sticky Clean Header Pesanan, Standarisasi Invoice Cloudflare, & GAGE Thermal Printer Suite)

* **GitHub Release**: [`v1.0.4+40`](https://github.com/halugoods/gage/releases/tag/v1.0.4%2B40)
* **Status Pengujian**: **26 / 26 Widget & Integration Scenarios PASSED (100%)**
* **Analisis Kode**: **0 Issues Found (`flutter analyze` clean)**

### A. Production-Grade 1:1 Image Cropper & Rotator (Zero Mock Sandbox)
- **File**: `lib/features/merchant/presentation/widgets/gage_image_crop_rotate_dialog.dart` & `merchant_photo_picker_sheet.dart`
- Menghapus seluruh preset foto mock/sandbox.
- Menghadirkan opsi riil: **Ambil Foto Kamera** fisik & **Pilih dari Galeri HP** via `image_picker` dengan `maxWidth: 1024`.
- Dialog interaktif murni Flutter:
  - Rasio aspek 1:1 (persegi) resmi katalog.
  - Fitur gesture pinch-to-zoom & pan (`InteractiveViewer`).
  - Fitur rotasi 90° berulang (`RotatedBox`).
  - Render hasil potongan dan orientasi langsung ke byte memory buffer PNG/JPG via `RepaintBoundary`.
- Di halaman edit/tambah menu (`merchant_menu_screen.dart`), preview foto produk 1:1 (160x160) dilengkapi tombol aksi potong ulang / putar (`Icons.crop_rotate_rounded`), ganti foto, dan hapus foto.

### B. Auto-Regenerating 5-Minute Handover PIN (Kurir & Dapur)
- **Model**: `lib/data/models/order_model.dart`
- PIN serah terima kurir tidak lagi diacak manual oleh merchant (mencegah desinkronisasi antara Merchant dan Driver).
- Menggunakan formula time-window modulo 5 menit berbasis waktu deterministik:
  `final window = DateTime.now().millisecondsSinceEpoch ~/ 300000;`
  `final pin = (orderNumber.hashCode ^ id.hashCode ^ window).abs() % 9000 + 1000;`
- Getter `pinSecondsRemaining` untuk menghitung sisa detik pada window aktif.
- Menghapus tombol manual "Acak Ulang PIN" pada `MerchantOrderDetailScreen`, digantikan dengan badge kapsul informatif *"Berganti otomatis setiap 5 menit"*.

### C. Sticky Clean Header & Tab Pesanan Tanpa Box Kontainer Belakang
- **File**: `lib/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart`
- Menghilangkan kontainer background kaku/tebal di belakang search bar dan segmented switch.
- Struktur sticky bar melayang jernih menyatu dengan background scaffold (`#F8FAFC` / `#0F172A`), tetap mengambang di puncak saat daftar pesanan digulir ke bawah (identik dengan pengalaman di beranda customer).
- Segmented switch 4 kapsul statis dengan penamaan ringkas yang pas dan tidak meluap (overflow): **Disiapkan**, **Siap**, **Diantar**, **Selesai**.
- Menghapus badge status internal mentah AI-slop seperti `READY_FOR_PICKUP`.

### D. Standarisasi Warna Tombol Aksi & Format Invoice Cloudflare D1
- Seluruh tombol aksi alur kerja pesanan distandarisasi menggunakan `GageTheme.primary` (`#E52320`), menghapus inkonsistensi warna tombol hijau (`#059669` / `#16A34A`).
- Kartu keterangan pesanan selesai memiliki tinggi dan padding konsisten dengan tombol aksi lainnya (`padding: vertical 11`, `StadiumBorder()`), dengan keterangan ringkas cukup: `"Selesai"`.
- Format invoice distandarisasi mengikuti pola Cloudflare D1 platform (`#INV-XXXX` / `INV-YYYYMMDD-XXXX`), menghapus penamaan invoice mock personal seperti `#RATNA-3304`. Chip invoice dapat diklik untuk menyalin nomor invoice ke clipboard disertai toast konfirmasi.

### E. GAGE Bluetooth Thermal Printer Suite (Adaptasi NUSA Kasir)
- **File**: `lib/features/merchant/presentation/widgets/merchant_printer_settings_sheet.dart`
- Pengaturan printer thermal Bluetooth terpadu dengan desain mewah khas GAGE (kapsul 999, tanpa garis solid).
- Fitur:
  - Pindai dan koneksi printer Bluetooth SPP.
  - Pemilihan ukuran kertas: **58mm** vs **80mm** (segmented capsule).
  - Sakelar cetak otomatis saat pesanan diterima (*Auto-print on accept*).
  - Pengaturan jumlah rangkap struk: **1x**, **2x (Dapur + Kurir)**, **3x (Dapur + Kasir + Kurir)**.
  - Tombol uji cetak sampel struk transaksi.

---

## 14. Dokumentasi Pembaruan Wave 9 (Penyempurnaan Kartu Pesanan, Countdown PIN & SLA Penyiapan, Unifikasi Profil, dan Paritas UI GAGE)

* **Status Pengujian**: Siap diverifikasi otomatis
* **Komponen Terdampak**: `OrderModel`, `MerchantOrderProvider`, `GageMerchantOrdersTab`, `MerchantOrderDetailScreen`, `MerchantFloatingNavBar`, `MerchantPrinterSettingsSheet`

### A. Perbaikan Logika Chat & Routing Eksplisit
- Tombol aksi chat pada kartu pesanan luar kini secara eksplisit membuka chat ke **Pelanggan** (`recipientRole: 'customer'`).
- Jika kurir telah ditetapkan (`hasAssignedDriver`), bagian driver menampilkan tombol chat khusus kurir (`recipientRole: 'driver'`), menghilangkan kebingungan merchant saat berkomunikasi.

### B. Countdown Timer PIN & SLA Penyiapan Toko (Auto-Ready + Penalti -1 Poin)
- **PIN Live Ticker**: Kartu PIN verifikasi kini menampilkan countdown detik per detik (`MM:SS`) hingga pergantian 5 menit berikutnya.
- **SLA Penyiapan Pesanan**: Saat pesanan berada pada status `COOKING`, sistem menghitung mundur waktu penyiapan (default 15 menit). Jika waktu habis tanpa merchant menekan *"Pesanan Siap Diambil"*, pesanan otomatis beralih menjadi `READY_FOR_PICKUP` dan toko dikenakan penalti performa -1 Poin.

### C. Unifikasi Kartu Profil Customer & Driver
- Menggabungkan data pelanggan dan kurir ke dalam 1 kontainer kartu tunggal yang bersih.
- Dipisahkan oleh garis horizontal halus (`Divider(height: 20, thickness: 0.8)`).
- Menggunakan `CircleAvatar` ber-border lingkaran untuk foto profil pelanggan dan kurir.
- Menyeragamkan warna ikon chat ke warna primer `GageTheme.primary` (menghapus campur aduk warna biru vs hijau).
- Mengeliminasi background container highlight ("efek stabilo") pada rincian Total Bayar Pelanggan.

### D. Mini Image Preview Produk pada Item Card
- Setiap produk pada rincian pesanan dilengkapi preview thumbnail gambar mini (~38x38, `BorderRadius.circular(8)`) yang proporsional setinggi 2 baris teks.

### E. Nominal Pesanan Warna Merah di Kartu Luar
- Mengganti teks nominal menjadi *"Total Pesanan:"* dengan font tebal berwarna merah **`GageTheme.primary` (`#E52320`)**, selaras dengan portal customer.

### F. Floating Bottom Nav Bar: Outline Stroke ke Filled
- Ikon bottom navigation bar menampilkan gaya outline (`*_outlined`) saat tidak aktif dan bertransformasi menjadi filled (`*_rounded`) saat aktif.

### G. Perapian Suite Printer Thermal Kasir
- Menghapus string dummy MAC address dan merampingkan antarmuka agar intuitif, elegan, dan bersih.

---

## 15. Dokumentasi Pembaruan Wave 10 (Eliminasi Badge Raw READY_FOR_PICKUP, Paritas Driver-First & Privasi Pelanggan, Live Countdown Tombol Luar, True Floating Action Bar, & Zero-D1 Image Loader)

* **GitHub Release**: [`v1.0.4+42`](https://github.com/halugoods/gage/releases/tag/v1.0.4%2B42)
* **Status Pengujian**: **29 / 29 Widget & Comprehensive Audit Scenarios PASSED (100%)**
* **Analisis Kode**: **0 Issues Found (`flutter analyze` clean)**

### A. Eliminasi Total Badge Status Raw `READY_FOR_PICKUP` & Enum Lainnya
- Menghapus badge pill raw status enum `order.status` (`READY_FOR_PICKUP`, `COOKING`, `NEW`, `PAID`, dll.) dari banner kartu status atas `MerchantOrderDetailScreen`.
- Judul banner `"Pesanan Siap Diambil"` kini tampil bersih, elegan, dan proporsional tanpa badge duplikat teknis yang membingungkan mitra merchant.
- Pengujian otomatis secara ketat memverifikasi bahwa `find.text('READY_FOR_PICKUP')` tidak muncul di seluruh tampilan UI detail order.

### B. Serah Terima Otomatis Kurir (Tanpa Tombol Manual "Serahkan ke Driver")
- Menghapus tombol manual *"Serahkan ke Driver"* / *"Serahkan Pesanan"* pada pesanan siap diambil (delivery).
- Secara arsitektural, status beralih tuntas otomatis saat mitra kurir menginput PIN verifikasi di aplikasi Driver.
- Untuk pesanan ambil di toko (*Self-Pickup*), tombol aksi berubah menjadi *"Selesaikan (Ambil di Toko)"*.

### C. Reposisi Driver ke Atas & Privasi Pelanggan
- Pada kartu pesanan dan layar detail order, informasi Driver ditempatkan di **atas** informasi Pelanggan saat driver telah ditetapkan (`hasAssignedDriver`).
- Menghilangkan kontainer tebal/kaku pada blok info driver dan beralih ke layout baris inline yang rapi.
- Demi menjaga privasi data pelanggan pada terminal usaha (merchant), foto avatar profil dan alamat pengantaran lengkap pelanggan dihilangkan dari kartu pesanan. Hanya nama pelanggan dan tombol aksi *"Chat Pembeli"* yang ditampilkan.

### D. Live Countdown SLA Masak pada Tombol Kartu Pesanan Luar
- Tombol aksi penyiapan di kartu pesanan luar kini menampilkan hitung mundur menit & detik secara langsung:
  `"Pesanan Siap Diambil (${order.formattedCookingTimeRemaining})"` (misal: `Pesanan Siap Diambil (14:32)`).

### E. PIN Serah Terima Sederhana & Stabil (Tanpa Auto-Regenerate 5 Menit)
- Menghapus mekanisme regenerasi otomatis PIN tiap 5 menit dan teks *"Berganti otomatis tiap 5 menit"*.
- PIN serah terima dibuat stabil, to-the-point, dan tidak berganti-ganti di tengah proses penyiapan, mencegah miss-komunikasi antara toko dan kurir.

### F. Smart Product Image Loader (Zero D1 Database Query Overhead)
- Menambahkan getter `effectiveImageUrl` pada `OrderItemModel` yang memetakan item pesanan secara cerdas:
  1. Aset lokal instan (`assets/images/dish_...png`, `prod_...png`) jika tersedia.
  2. URL remote Cloudflare / HTTP jika telah terisi.
  3. Inferensi fallback cerdas dari nama produk ke aset visual yang relevan.
- Seluruh thumbnail produk pada kartu pesanan luar (`34x34`, radius 8px) dan detail order (`38x38`, radius 8px) tampil instan dengan **0 kali pemanggilan query D1**, menjaga limit kuota Cloudflare tetap aman maksimal.

### G. Bottom Nav Bar: Ikon Pesanan Solid Filled saat Aktif
- Tab Pesanan (Index 0) kini menggunakan `Icons.receipt_rounded` (solid filled) saat aktif dan `Icons.receipt_outlined` saat tidak aktif, konsisten dengan standar ikonografi GAGE.

### H. True Floating Bottom Action Button & Search Bar Paritas Kapsul 42px
- Menghapus kontainer putih solid penutup di belakang tombol aksi bawah detail pesanan, menjadikannya tombol aksi yang benar-benar melayang (*true floating button*).
- Search bar pesanan diseragamkan tingginya menjadi 42px dengan kapsul penuh `BorderRadius.circular(999)`, melayang jernih tanpa box background.

## 16. Dokumentasi Pembaruan Wave 11 (Detail Pesanan Tanpa Banner Status, Modern PIN Digit Tiles, Placement Driver Bawah Total Pesanan, Engine Cetak Struk Nusa Kasir, Notifikasi Interaktif Media Gambar, Rombak Pengaturan Eliminasi Radius, & Portal Auth Mitra Usaha)

### A. Eliminasi Total Banner Status Operasional pada Layar Detail Pesanan
- Menghapus komponen banner status kartu atas (`_buildStatusCard`) dari `MerchantOrderDetailScreen`.
- Detail pesanan kini langsung berfokus pada informasi esensial: PIN Serah Terima, Driver/Kurir penjemput, Data Pembeli, Rincian Produk, dan Ringkasan Finansial Toko.

### B. Desain Baru PIN Serah Terima Kurir (Individual Modern Digit Tiles)
- Rombak total kotak PIN Serah Terima kurir dari sebelumnya ber-border merah muda kaku menjadi 4 kotak ubin digit individual (`44x48`, rounded 12) dengan jarak lega, font tebal 22px, dan tombol salin PIN satu sentuhan.

### C. Pemisahan Kontainer Pembeli dan Driver / Kurir GAGE Berjudul
- Memisahkan blok informasi Pembeli dan Driver menjadi 2 kontainer terpisah yang bersih:
  - Header kontainer: `"Driver / Kurir GAGE"` dan `"Pembeli"`.
  - Menggunakan avatar profil lingkaran (`CircleAvatar`).
  - Tombol aksi chat terstandardisasi menggunakan warna merah `GageTheme.primary`.

### D. Kartu Pesanan Luar: Placement Driver di Bawah Total Pesanan & Ukuran Tombol Seragam
- Pada `gage_merchant_orders_tab.dart`, section informasi Driver dipindahkan ke **bawah Total Pesanan** dalam kontainer warna tipis (`#F8FAFC` / `#0F172A`).
- Tombol aksi `"Menunggu Verifikasi PIN Driver"` diseragamkan ukurannya (`minHeight: 44px`, `StadiumBorder()`) agar identik 1:1 dengan tombol operasional lainnya.

### E. True Floating Bottom Action Button
- Menghilangkan dock kontainer putih di belakang tombol aksi bawah `MerchantOrderDetailScreen` menggunakan `extendBody: true` dan padding transparan dengan efek bayangan melayang (*drop shadow*).

### F. Engine Cetak Struk Nusa Kasir (`MerchantReceiptPrinterService`)
- Membangun `MerchantReceiptPrinterService` yang mengadopsi standar cetak thermal Nusa Kasir.
- Format monospace ketat 58mm (32 kolom) dan 80mm (48 kolom) untuk Struk Transaksi Toko dan Tiket Dapur.
- Menghapus konsep print driver yang tidak terpakai, dan menyederhanakan opsi rangkap struk (1x Struk Toko & 2x Toko + Dapur).
- Pengaturan printer Bluetooth thermal dipindahkan ke menu Pengaturan Toko / Outlet.

### G. Notifikasi Interaktif Layar Penuh & Dukungan Media Gambar Admin
- Menambahkan field `imageUrl` dan `actionUrl` pada model `GageNotification` di `NotificationService`.
- Mengetuk item notifikasi kini membuka layar penuh `NotificationDetailScreen` yang menampilkan banner gambar broadcast dari Admin, chip kategori, waktu lengkap, dan isi pesan detail.

### H. Rombak Pengaturan Outlet & Eliminasi Radius Layanan
- Menghapus slider radius layanan (`_deliveryRadius`) pada `merchant_profile_screen.dart` dan `gage_merchant_outlet_tab.dart` karena layanan GAGE mencakup seluruh desa di Kecamatan Pracimantoro tanpa pembatasan radius toko.
- Menambahkan Grid Operasional 8 fitur lengkap (Menu & Stok, Printer Thermal, Jadwal Toko, Lokasi & Kios, Ulasan, Wawasan, Komisi MDR 10%, Bantuan).
- Menambahkan card informasi cakupan wilayah Pracimantoro dan opsi Logout Akun Toko.

### I. Screen Auth Login & Registrasi Mitra Usaha Baru
- Membangun `MerchantLoginScreen` (`/merchant/login`): Login via WhatsApp Toko & PIN 6-Digit dengan Dev Quick Login.
- Membangun `MerchantRegisterScreen` (`/merchant/register`): Pendaftaran toko baru lengkap dengan pilihan kategori (Food, Shop, Farm, Build), pilihan desa Pracimantoro, dan persetujuan komisi MDR 10%.
- Mendaftarkan rute di `MerchantRoutes` dan `main_merchant.dart`.

## 17. Dokumentasi Pembaruan Wave 12 (Detail Pesanan Bersih, Red Driver Dock, Nusa Kasir Real Bluetooth & Struk Monospace, Rombak Pengaturan Bebas Slop, Google-First Wizard Setup Toko)

### A. Detail Pesanan Bersih & Eliminasi Seluruh Badges Berlebihan
- Membuang total badge "Kurir Terpasang" dan "Pesan Antar" pada kartu Driver dan Pembeli di `MerchantOrderDetailScreen`.
- Menghapus teks subtitle "Pengantaran kurir ke alamat pembeli" pada blok Pembeli.
- Mengubah judul blok menjadi bersih dan to the point: `"Driver"` dan `"Pembeli"` (void `"Driver / Kurir GAGE"`).
- Menghapus badge `"Wajib Validasi"` pada kartu PIN serah terima.
- Memastikan tombol aksi bawah benar-benar floating melayang bebas tanpa kontainer putih di belakangnya (`extendBody: true`, `FloatingActionButtonLocation.centerFloat`).

### B. Kartu Pesanan Luar: Red Driver Dock Layer & Smart Product Images
- Penugasan driver pada kartu pesanan (`gage_merchant_orders_tab.dart`) kini diposisikan di layer paling bawah kartu sebagai **kontainer footer merah lembut / soft red** terintegrasi dengan radius kartu (`BorderRadius.vertical(bottom: Radius.circular(20))`).
- Tombol aksi "Pesanan Siap Diambil" dilengkapi countdown timer dinamis penyiapan masakan (`11:51`).
- Pemuat gambar produk cerdas (`_buildProductImage`) menampilkan thumbnail produk mini (34x34 & 38x38) yang selaras dengan katalog menu dan asset lokal.
- Search bar dan segmented switch mengambang bersih di atas list tanpa kontainer putih pembungkus di belakangnya.

### C. Pengecekan Bluetooth Riil & Engine Printer Nusa Kasir (Paritas 1:1)
- Integrasi bridge native SPP Bluetooth di `BluetoothUtils` dan `MainActivity.kt`.
- Pengecekan fisik riil status Bluetooth adapter: jika Bluetooth non-aktif, sheet menampilkan banner oranye peringatan *"Bluetooth Belum Aktif"* dan tombol *"Aktifkan"*. Tidak ada lagi status palsu "ONLINE" saat Bluetooth mati.
- Toggle Cetak Otomatis setelah transaksi diterima dan Buka Laci Uang Otomatis (Cash Drawer).
- Segmented switch ukuran kertas [58mm | 80mm] kapsul penuh 999.
- Tombol aksi: Pindai Perangkat, Uji Coba Cetak (Test Print monospace presisi), dan Cetak Ulang Struk Terakhir.

### D. Pengaturan Struk Toko Monospace (`MerchantReceiptSettingsSheet`)
- Lembar pengaturan struk mandiri dengan live preview monospaced receipt dinamis.
- Slider ukuran font header toko (12 - 36 px) dengan counter interaktif.
- Input kustomisasi baris footer ucapan terima kasih toko dan nomor kontak layanan pelanggan.

### E. Rombak Menu Pengaturan (Bebas AI Slop)
- Judul halaman dan AppBar disederhanakan menjadi cukup **"Pengaturan"**.
- Menghapus 100% input teks teknis koordinat Latitude/Longitude angka mentah (`-8.089200, 110.837400`).
- Menggantikannya dengan Card Titik Lokasi Peta GPS interaktif + tombol kapsul *"Buka Peta"* (`FullScreenMapPicker`) dan *"GPS"*.
- Menghapus total chips placeholder slop: *"Lapak Utama"*, *"Toko Sembako"*, *"Etalase Resto"* dan input path teks manual `assets/images/resto_dimsum_sewu.png`.
- Memasang Image Picker riil (Kamera/Galeri) dengan dialog Crop & Rotate interaktif: rasio 1:1 untuk Foto Profil/Logo dan rasio 16:9 untuk Banner Sampul Toko.
- Seksi `PERANGKAT` mengadopsi 1:1 layout Nusa Kasir dengan opsi `Printer` dan `Pengaturan Struk`.

### F. Google-First Authentication & Multi-Step Wizard Setup Toko Mitra Usaha
- Masuk / Daftar akun Mitra Usaha berpusat pada Google Sign-In (`auth.signInWithGoogle()`).
- Deteksi otomatis status setup toko via `MerchantStorefrontService.hasCompletedStoreSetup(merchantId)`.
- Jika toko baru belum disetup, merchant langsung diarahkan ke **Wizard Setup Toko (`MerchantStoreSetupWizardScreen`)**:
  - Langkah 1: Identitas Toko, Nomor WhatsApp Operasional Toko (wajib), dan Kategori Usaha.
  - Langkah 2: Branding Visual (Logo 1:1 & Banner 16:9 via Image Picker interaktif) + Bio Singkat.
  - Langkah 3: Alamat Kios di Kecamatan Pracimantoro, Patokan/Landmark, dan Titik GPS Peta Interaktif.
  - Langkah 4: Jam Operasional Toko (Buka/Tutup via Time Picker) & Transparansi Biaya Platform (MDR 10%).
  - Tombol aksi utama: *"Buka Toko & Mulai Jualan"*.
- Jika toko sudah disetup, langsung masuk ke Dashboard Toko GAGE.

---

## 21. Wave 13: Full-Width Floating Action Bar, Eliminasi Chat Driver, Domain Murni (Food, Shop, Farm), & Arsitektur Pengaturan Paritas Shopee Partner

* **Tanggal Rilis**: `2026-11-24`
* **Target Build & Flavor**: `applicationId = "com.gagepracimantoro.merchant"`, entrypoint `lib/main_merchant.dart`, flavor `merchant` (`v1.0.4+45`).

### A. Full-Width Floating Action Bar di Detail Pesanan (`MerchantOrderDetailScreen`)
- Menggantikan floating action button kerdil canggung di tengah (`centerFloat`) menjadi **Full-Width Floating Action Dock**.
- Menggunakan `width: double.infinity, height: 50`, margin `EdgeInsets.fromLTRB(16, 0, 16, 14)`, `StadiumBorder()`, dan bayangan elegan halus (alpha 0.22, blur 10, offset (0, 3)).
- Tombol responsif terhadap status: *"Terima Pesanan"*, *"Pesanan Siap Diambil"*, *"Selesaikan (Ambil di Toko)"*, *"Kembali ke Pesanan"*.

### B. Eliminasi Total Fitur Chat Driver & Red Driver Dock Terintegrasi
- **Larangan Chat Driver**: Merchant dilarang berkomunikasi langsung via chat dengan driver untuk mencegah deviasi alur penjemputan. Tombol *"Chat Driver"* dihapus total dari `MerchantOrderDetailScreen` dan `GageMerchantOrdersTab`. Merchant hanya memiliki saluran komunikasi resmi *"Chat Pembeli"*.
- **Red Driver Dock Terintegrasi**: Posisikan kontainer driver merah lembut (`#FEF2F2` / `#450A0A`, `BorderRadius.circular(14)`) di DALAM padding kartu pesanan luar di bawah tombol aksi, mempertahankan sudut rounded halus `BorderRadius.circular(20)` pada kontainer putih kartu luar.

### C. Domain Bisnis Murni: Hanya Food, Shop, Farm (Void Build)
- Menegaskan domain merchant di GAGE Pracimantoro hanya terdiri dari 3 pilar: `Food` (Kuliner), `Shop` (Kelontong/Sembako), dan `Farm` (Pertanian/Peternakan).
- Domain `Build` (Material Bangunan) telah ditiadakan total dari wizard dan katalog.
- Menghapus input deskripsi singkat / slogan bio toko pada form pendaftaran dan pengaturan toko karena tidak ditampilkan di sisi aplikasi pelanggan.

### D. Rombak Pengaturan Mengadopsi Arsitektur Shopee Partner
- **Header Toko**: Avatar 1:1 bulat (`_storeLogo`), Nama Toko, Lokasi Singkat (`Kecamatan Pracimantoro, Kab. Wonogiri`), Badge Kapsul `TERVERIFIKASI`, ID Toko (`#M-22467742` + tombol salin cepat ke clipboard), dan tombol kapsul *"Menu"* ke Katalog Produk.
- **Shopee Partner Grid Menu (7 Tile)**:
  1. *Informasi Toko*: Foto Profil (1:1), Banner Toko (16:9), Nama Usaha, Kontak WhatsApp, dan Alamat Kios Terverifikasi.
  2. *Pengaturan Pesanan*: Estimasi waktu penyiapan makanan default (10, 15, 20, 25 menit segmented kapsul), toggle pesanan ambil di toko (self-pickup), dan auto-konfirmasi pesanan.
  3. *Pengaturan Notifikasi*: Dering alarm pesanan baru berulang (audio dapur bising) dan popup layar kunci.
  4. *Printer Thermal*: Terintegrasi dengan `MerchantPrinterSettingsSheet` (Nusa Kasir ESC/POS engine).
  5. *Pengaturan Struk*: Terintegrasi dengan `MerchantReceiptSettingsSheet` (Monospace 58mm/80mm preview, footer kustom, logo).
  6. *Pengajuan Saya*: Status peninjauan permohonan merchant oleh Admin GAGE (termasuk Pengajuan Pindah Lokasi Kios fisik).
  7. *Pusat Bantuan*: Direct WhatsApp Help Center ke CS GAGE Pracimantoro.
- **Alur Pengajuan Pindah Lokasi Kios (`MerchantLocationChangeRequestSheet`)**:
  - Alamat kios fisik dan titik GPS adalah data resmi terverifikasi saat pendaftaran awal dan tidak dapat diubah bebas oleh merchant.
  - Jika merchant pindah ruko/lapak, mereka mengisi formulir resmi *Ajukan Pindah Lokasi Kios* dengan alamat baru, patokan, titik peta via `FullScreenMapPicker`, dan alasan pemindahan.
  - Data pengajuan disimpan ke persistence (`MerchantStorefrontService.saveLocationChangeRequest`) dan berstatus `PENDING` (menunggu persetujuan Admin GAGE).
- **Kepatuhan UI**: Semua segmented tab, switch, dan action buttons wajib full-rounded kapsul (`StadiumBorder()`). Outline field halus `Color(0xFFE2E8F0)`, background soft `#F8FAFC`. Bebas em dash (`\u2014`).

---

## 22. Wave 14: Conditional Countdown SLA, Live Driver Animation, Kotak Rounded Profile, D1 Store ID, Floating Blur Sheets & Full-Screen Policy

* **Tanggal Rilis**: `2026-11-25`
* **Target Build & Flavor**: `applicationId = "com.gagepracimantoro.merchant"`, entrypoint `lib/main_merchant.dart`, flavor `merchant` (`v1.0.4+46`).

### A. Conditional Countdown SLA & Animasi Pencarian Armada
- **Kondisi Countdown Memasak**: Countdown SLA penyiapan pesanan (`formattedCookingTimeRemaining`) HANYA dimunculkan pada tombol aksi ketika armada kurir telah terpasang (`order.hasAssignedDriver || order.isPickup`).
- **Indikator Sedang Mencari Kurir**: Saat pesanan pengantaran dalam status `COOKING` namun belum mendapat kurir, countdown waktu di tombol aksi disembunyikan dan digantikan dengan indikator animasi pulsing radar `_LivePulsingRadarIcon` bertuliskan *"Sedang mencari kurir terdekat..."* sehingga dapur tidak terbebani timer palsu sebelum kurir ada.

### B. Driver Dock Kapsul Full-Rounded (Radius 999) & Animasi Live "Menuju Kios"
- **Geometri Kapsul Penuh**: Kontainer informasi driver di kartu pesanan luar (`GageMerchantOrdersTab`) dan detail pesanan (`MerchantOrderDetailScreen`) diubah menjadi full-rounded kapsul `BorderRadius.circular(999)` tanpa outline merah solid (`border: null`, soft background `#FEF2F2` / `#450A0A`).
- **Live Status Armada**: Ditambahkan badge live dengan pulsing dot merah (`_LivePulsingDot`) bertuliskan *"Menuju Kios"* di sisi kanan dock kurir.
- **Test Safety Invariant**: Animasi live diproteksi dengan guard `WidgetsBinding.instance.runtimeType.toString().contains('Test')` agar widget test Flutter tidak mengalami infinite loop timeout.

### C. Header Pengaturan Toko & Standardisasi Cloudflare D1 Store ID
- **Avatar Kotak Rounded**: Foto profil/logo merchant di header Pengaturan (`MerchantProfileScreen`) diubah dari lingkaran (`ClipOval`) menjadi kotak rounded 12px (`ClipRRect(borderRadius: BorderRadius.circular(12))`).
- **Eliminasi Tombol Menu**: Tombol "Menu" di header Pengaturan ditiadakan untuk menjaga tata letak header tetap bersih dan fokus pada identitas toko.
- **Standarisasi ID Toko Cloudflare D1**: Format ID toko disesuaikan dari placeholder `#M-22467742` menjadi skema terstruktur multi-portal D1: `GAGE-PRC-FD01` (dengan fitur salin ke clipboard).
- **Interaktivitas Rating Toko**: Kartu matriks Rating Toko kini dapat diklik (`InkWell`) untuk langsung membuka halaman ulasan pelanggan `MerchantReviewScreen`.

### D. Standardisasi Floating Sheet Blur & Perbaikan Scroll Jadwal Operasional
- **GageFloatingSheet Blur Standard**: Seluruh modal sheet di Pengaturan (Printer Thermal, Pengaturan Struk, Ajukan Pindah Lokasi, Pusat Bantuan, Jam Operasional) distandarisasi menggunakan `GageFloatingSheet.show` dengan frosted blur 24px, margin melayang 16px, border radius 24px, dan batas tinggi proporsional maksimal 2/3 layar (`maxHeightFactor: 0.67`).
- **Scroll Kustom Jadwal Operasional**: Memperbaiki bug scroll pada custom schedule di `OperatingScheduleEditorSheet` dengan mengganti `Flexible(ListView)` di dalam `SingleChildScrollView` menjadi `Column(children: days.map(...))` sehingga seluruh hari (Senin s/d Minggu) dan tombol simpan dapat di-scroll dengan mulus tanpa overflow.
- **Standardisasi Toggle Switch Merah GAGE**: Seluruh sakelar switch toggle ON/OFF di seluruh sheet dan layar pengaturan distandarisasi menggunakan warna merah primer GAGE (`GageTheme.primary` `#E52320`).

### E. Dokumen Kebijakan Kemitraan Full-Screen (`MerchantTermsAndPrivacyScreen`)
- Menyediakan layar penuh dokumen resmi kemitraan dan privasi data pelanggan, mencakup:
  1. Skema bagi hasil & komisi MDR 10% (transparansi settlement H+1).
  2. Kebijakan perlindungan & kerahasiaan data pembeli (larangan kontak di luar pemenuhan pesanan).
  3. Standar mutu, kebersihan dapur, dan SOP kemasan anti-tumpah.
  4. Prosedur pembatalan pesanan, stok habis, dan ganti rugi/refund.
  5. Saluran resmi kontak operasional dispatcher & legal GAGE.
  6. Tombol salin ringkasan ketentuan ke clipboard.

### F. Pusat Bantuan Non-Gimmick (`MerchantHelpCenterSheet`)
- Menyediakan lembar bantuan operasional riil dengan aksi langsung:
  - Tombol telepon cepat ke Hotline Darurat Dispatcher Pracimantoro (`tel:+628111222333`).
  - Tombol WhatsApp Customer Service Mitra Usaha (`https://wa.me/628111222333`).
  - Direktori FAQ interaktif (pencairan saldo, armada telat, pairing printer thermal, ubah pesanan, dan prosedur pindah lokasi).

---

## 23. Wave 15: Animasi Delivery Track Top-Down Rider, Paritas Card Order Tanpa Chat, Dual Action Detail Order, Pembersihan Double Header Sheets & Multi-Outlet Branch Switcher

* **Tanggal Rilis**: `2026-11-25`
* **Target Build & Flavor**: `applicationId = "com.gagepracimantoro.merchant"`, entrypoint `lib/main_merchant.dart`, flavor `merchant` (`v1.0.4+47`).

### A. Animasi Delivery Track Top-Down Rider (`GageDeliveryTrackProgress`)
- Menggantikan badge dot sederhana dengan progress track horizontal bergaya ShopeeFood/Shopee Partner (`lib/shared/widgets/gage_delivery_track_progress.dart`).
- Dilengkapi node cutlery restoran, pin lokasi tujuan, garis progres warna primer, dan ikon kurir motor matic tampak atas (`_TopDownCourierRiderPainter`) yang meluncur mulus saat *Mencari Kurir* maupun *Menuju Kios*.

### B. Paritas Kartu Pesanan Luar & Detail Order (Gambar 2 & 3)
- **Kartu Pesanan Luar (`GageMerchantOrdersTab`)**: Menghapus tombol *"Chat Pembeli"* dari kartu pesanan luar agar fokus murni pada ringkasan item, total pesanan, delivery track, dan tombol aksi utama.
- **Detail Pesanan (`MerchantOrderDetailScreen`)**:
  - Kartu Driver dilengkapi tombol ikon **Telepon In-App** bulat (`_showInAppCallSheet`).
  - Kartu Pembeli dilengkapi **dua tombol aksi berdampingan**: Ikon Chat (`InAppChatScreen`) dan Ikon Telepon In-App.

### C. Eliminasi Anomali Double Header pada Floating Sheets
- Membersihkan duplikasi handle bar internal, border radius kontainer luar, dan duplikasi judul di dalam `MerchantPrinterSettingsSheet`, `MerchantReceiptSettingsSheet`, `MerchantLocationChangeRequestSheet`, dan `MerchantPhotoPickerSheet`.

### D. Sinkronisasi Nama Toko & Sistem Kelola Cabang (`MerchantBranch`)
- Menyeragamkan nama default outlet menjadi `"Dimsum Sewu Pracimantoro (Pusat)"` secara reaktif melalui `MerchantOrderProvider.activeBranchName`.
- Menambahkan model `MerchantBranch`, persistence di `MerchantStorefrontService`, dan `MerchantBranchSwitcherSheet` yang dapat diakses dari Header Dashboard, Tab Outlet, dan Menu Pengaturan untuk beralih cabang atau menambah cabang baru.













---

## 23. Wave 15: Sinkronisasi Avatar Chat Asli, Penghapusan Label AI & Integrasi Voucher G-Fit

1. **Standar Foto Profil & Penamaan Chat Lintas Portal**:
   - Customer Portal telah menghapus seluruh label `AI Assistant`, `Bantuan AI`, badge `24/7`, serta akhiran `(Driver GAGE)` pada tampilan nama chat. Layanan bantuan kini bernama `Pusat Bantuan` (tab `Bantuan`, icon resmi `assets/images/gage_icon.png`), sedangkan chip peran `Driver` dan `Toko` dipertahankan.
   - `GageAvatar.resolveSourceUrl(...)` kini menormalkan URL relatif `/api/...` dan `/media/...` dengan `GageApiClient.baseUrl`.
2. **Aksi yang Diperlukan di Portal Merchant (`lib/features/merchant/`)**:
   - **`merchant_chat_list_screen.dart` & `gage_merchant_chat_tab.dart`**: Ganti fallback hardcoded `assets/images/gage_chat_icon.png` pada driver/CS dan teruskan `recipientAvatar` ke `InAppChatScreen` (`order.driverAvatar` atau `order.customerAvatar` untuk pelanggan, `assets/images/gage_icon.png` untuk Pusat Bantuan). Pastikan nama mitra driver tidak lagi menyertakan `(Driver GAGE)` dan entri CS tidak memakai embel-embel `AI` / `(24/7)`.
3. **Voucher Reward G-Fit (`GFITSEHAT`, `GFITONGKIR`, `GFITJUARA`)**:
   - Setelah pelanggan menyelesaikan misi mingguan G-Fit (5 KM / 10 KM / 21 KM), voucher `GFITSEHAT` (diskon Rp5.000), `GFITONGKIR` (subsidi ongkir s/d Rp10.000), dan `GFITJUARA` (diskon 25% s/d Rp15.000) kini dapat digunakan langsung pada checkout GAGE Food & GAGE Shop. Potongan voucher platform ini bersumber dari kupon promo platform (tidak memotong hak bersih omset item merchant).

---

## 24. Wave 16: Handoff Lengkap Seluruh File Chat (`lib/features/chat/`) untuk Eksekusi Portal Merchant

Dokumen ini merinci seluruh file Dart modul chat yang aktif di ekosistem Customer serta langkah eksekusi yang **wajib disinkronkan di Portal Merchant** (`lib/features/merchant/`). Sesuai isolasi portal pada [`PORTAL_BOUNDARIES.md`](../../PORTAL_BOUNDARIES.md), file Portal Merchant belum diubah langsung oleh sesi Customer.

### A. Inventaris Lengkap File Chat (`gage-app/lib/features/chat/` & Shared Avatar)
1. **Model Pesan (`domain/chat_message.dart`)**: [`chat_message.dart`](../../gage-app/lib/features/chat/domain/chat_message.dart)
   - Class `ChatMessage`: `id`, `orderId`, `senderId`, `senderRole` (`'customer' | 'driver' | 'merchant' | 'admin'`), `senderName`, `text`, `mediaUrl`, `messageType` (`'text' | 'image' | 'product' | 'voice'`), `productName`, `productPrice`, `productImage`, `voiceDurationSeconds`, `timestamp`, `status` (`'sending' | 'sent' | 'delivered' | 'read'`).
   - Helper getter: `isFromDriver`, `isFromCustomer`, `isFromMerchant`, `isFromAdmin`, `isImage`, `isProduct`, `isVoice`, `audioUrl`.
2. **State Provider Chat (`providers/in_app_chat_provider.dart`)**: [`in_app_chat_provider.dart`](../../gage-app/lib/features/chat/providers/in_app_chat_provider.dart)
   - Class `InAppChatProvider`: menyuplai `getMessages(orderId)`, `sendMessage(...)`, `sendVoiceMessage(...)`, `sendMediaMessage(...)`, `sendProductMessage(...)`.
   - Seed percakapan hanya aktif bila `GageApiClient.useDevSeedData == true` dan nama driver sudah bersih tanpa akhiran `(Driver GAGE)` (`'Syamsul Maarif'`).
   - Catatan penting: saat ini masih menyimpan thread per `orderId` di memori lokal (`_messagesByOrder`); tunggu endpoint D1 admin bila ingin sinkronisasi lintas device real-time.
3. **Layar Ruang Chat Lintas Peran (`presentation/in_app_chat_screen.dart`)**: [`in_app_chat_screen.dart`](../../gage-app/lib/features/chat/presentation/in_app_chat_screen.dart)
   - Parameter widget: `orderId`, `recipientName`, `recipientRole` (`'customer' | 'merchant' | 'driver' | 'support' | 'admin'`), `recipientPhone`, `recipientAvatar` (`String?`), `currentRole` (`'driver' | 'merchant' | 'customer'`).
   - Static helper wajib dipakai ulang di Merchant:
     - `InAppChatScreen.isSupportRole(role)` (`'ai'`, `'support'`, `'admin'`)
     - `InAppChatScreen.isSupportOrderId(orderId)` (`'AI-SUPPORT'`, `'cs-gage-support'`, `'GAGE-CARE'`)
     - `InAppChatScreen.cleanDisplayName(rawName, role: role)` untuk membuang `(Driver GAGE)`, `(Driver)`, plat dalam kurung, label `AI Assistant`/`Bantuan AI`, serta `(24/7)`.
   - Sudah memiliki quick replies khusus `currentRole == 'merchant'` (baik saat membalas ke `'driver'` maupun ke `'customer'`) dan tombol lampiran katalog produk (`_handleFileCatalog`).
4. **Input Bar Chat (`presentation/widgets/gage_chat_input_bar.dart`)**: [`gage_chat_input_bar.dart`](../../gage-app/lib/features/chat/presentation/widgets/gage_chat_input_bar.dart)
   - Komponen `GageChatInputBar`: mengelola input teks, tombol kamera (`onCameraTap`), galeri (`onGalleryTap`), berkas/katalog (`onFileTap`), serta rekaman voice note inline via `GageAudioService` (`onVoiceRecordedWithFile`). Sudah terpasang otomatis di `InAppChatScreen`.
5. **Sheet Katalog Produk di Chat (`presentation/widgets/gage_product_catalog_sheet.dart`)**: [`gage_product_catalog_sheet.dart`](../../gage-app/lib/features/chat/presentation/widgets/gage_product_catalog_sheet.dart)
   - Dipanggil oleh `InAppChatScreen._handleFileCatalog()` untuk mengirim kartu produk (`ChatMessage` bertipe `'product'`).
   - **Temuan Gap**: pada `in_app_chat_screen.dart#L301` masih mempassing `merchantId: 'm-dimsum-sewu'` secara statis dan membaca `GageMockRegistry.foodMerchants`. Saat dipakai di mode produksi multi-toko Merchant, sesuaikan agar membaca katalog aktif milik `MerchantStorefrontService` / merchant yang sedang login.
6. **Hub Daftar Chat Customer (`presentation/chat_hub_screen.dart`)**: [`chat_hub_screen.dart`](../../gage-app/lib/features/chat/presentation/chat_hub_screen.dart)
   - Referensi 1:1 UX terbaru untuk diadopsi Merchant: tab kapsul `BorderRadius.circular(999)`, avatar via `GageAvatar`, membaca order riil (`OrderProvider` -> `MerchantOrderProvider` di sisi Merchant) serta preview pesan terakhir dari `InAppChatProvider`, membersihkan nama driver, dan membuang label `AI` / `(24/7)`.
7. **Widget Avatar Lintas Portal (`shared/widgets/gage_avatar.dart`)**: [`gage_avatar.dart`](../../gage-app/lib/shared/widgets/gage_avatar.dart)
   - Gunakan `GageAvatar(imageUrl: ..., fallbackName: ..., radius: ...)` pada seluruh daftar chat agar path relatif R2 (`/api/chat/media/...` atau `/media/...`) otomatis dinormalkan lewat `GageAvatar.resolveSourceUrl(...)` ke `GageApiClient.baseUrl`, dan fallback ke inisial nama (bukan gambar `gage_chat_icon.png`).

### B. Checklist Eksekusi Wajib untuk Portal Merchant
1. **Refactor [`gage_merchant_chat_tab.dart`](../../gage-app/lib/features/merchant/presentation/tabs/gage_merchant_chat_tab.dart)**:
   - Hapus penggunaan `CircleAvatar` + `Image.asset(chat['avatar'] ?? 'assets/images/gage_chat_icon.png')` pada baris `L216-L231`; ganti dengan `GageAvatar(imageUrl: avatarUrl, fallbackName: displayName, radius: 24)`.
   - Ganti `_mockChats` statis agar menggabungkan thread dinamis dari `MerchantOrderProvider` (active & history orders) + `InAppChatProvider.getMessages(order.id)`, dan hanya menyertakan mock thread saat `GageApiClient.useDevSeedData == true`.
   - Teruskan `recipientAvatar` (`order.driverAvatar`, `order.customerAvatar` setelah D1 menyuplai field tersebut, atau `'assets/images/gage_icon.png'` untuk bantuan) saat memanggil `InAppChatScreen(...)` pada `L198-L204`.
   - Hapus teks `Pusat Bantuan Mitra GAGE (24/7)` -> ganti `Pusat Bantuan` (avatar `'assets/images/gage_icon.png'`, tanpa `(24/7)` dan tanpa badge `Bantuan CS` bernuansa AI); bersihkan nama `'Budi Santoso (Driver GAGE)'` / `'Agus Prabowo (Driver GAGE)'` menjadi nama murni + chip peran `'Driver'` (bukan `'Driver GAGE'`), dan `'Siti Rahmawati (Pelanggan)'` menjadi `'Siti Rahmawati'` + chip `'Pelanggan'`.
2. **Refactor [`merchant_chat_list_screen.dart`](../../gage-app/lib/features/merchant/presentation/merchant_chat_list_screen.dart)**:
   - Guard daftar `_chatRooms` agar tidak bocor di produksi (`GageApiClient.useDevSeedData`) dan hubungkan ke `MerchantOrderProvider` + `InAppChatProvider` (sekaligus ganti `CircleAvatar(Icon)` dengan `GageAvatar` + bersihkan nama `(Kurir GAGE)`/`(Driver Motor)` + teruskan `recipientAvatar` ke `InAppChatScreen`).
3. **Verifikasi Kepatuhan Aturan Pelanggan vs Merchant**:
   - Customer tidak diperbolehkan memulai chat langsung ke toko dari halaman etalase toko sebelum order/merchant memulai percakapan, sedangkan Merchant dapat merespons/memulai chat ke pelanggan atau driver pada pesanan aktif (`currentRole: 'merchant'`).

---

## 24. Wave 16: Sheet Width Audit, Red G-Rider Track, Detail Order Polish, TikTok Sans & Chat Hub Parity (Selesai)

* **Tanggal Rilis**: `2026-11-25`
* **Target Build & Flavor**: `v1.0.4+48` (`com.gagepracimantoro.merchant`).
* **Poin Eksekusi**:
  1. **Floating Sheet Width**: Margin luar `GageFloatingSheet` dipersempit (`16px -> 10px`) dan padding ganda di anak sheet dihapus sehingga konten bertambah lebar +60px.
  2. **Red G-Rider Track & Domain Icons**: `GageDeliveryTrackProgress` memakai motor merah `#E52320` dengan huruf **"G"** putih pada boks delivery dan ikon tengah adaptif (`Food`, `Shop`, `Farm`). Handoff diteruskan ke `HANDOFF_CUSTOMER.md`.
  3. **Detail Order Polish**: Ikon Chat & Telepon dibuat polos bold tanpa kontainer lingkaran, dan `order.notes` dibungkus kontainer merah lembut tipis.
  4. **TikTok Sans Typography**: Sisa `GoogleFonts.plusJakartaSans` di `merchant_screen.dart` dihapus dan ketebalan font distandarisasi proporsional.
---

## 25. Wave 21: Order Card, Tab Switch & Delivery Track Adjustments (Selesai)

* **Tanggal Rilis**: `2026-11-26`
* **Target Build & Flavor**: `v1.0.4+50` (`com.gagepracimantoro.merchant`).
* **Poin Eksekusi**:
  1. **Posisi Quick Search Bar**: Dipindahkan ke **bawah** Segmented Tab Switch (`Disiapkan`, `Siap`, `Diantar`, `Selesai`) agar filter navigasi utama tetap berada di posisi atas secara hierarkis.
  2. **Tab Selesai Bebas Badge Count**: Segmented Tab Switch pada tab `'Selesai'` (`index: 3`) tidak merender badge notif angka (`count: null`). Kapsul pill `'Selesai'` tetap bersih dan proporsional tanpa angka ratusan memenuhi pill.
  3. **Kartu Pesanan Selesai Bersih**: Pesanan berstatus `COMPLETED` atau `CANCELLED` tidak lagi memicu animasi motor bergerak `"Menuju Toko"`. Jika diantar kurir, kartu menampilkan blok profil driver netral (`#F8FAFC` / `#0F172A`, 2 baris: nama + tipe/plat) tanpa badge kapsul AI-slop redundan.
  4. **Spesialisasi Status "Pengemudi telah tiba di toko" (Konsisten GAGE Red `#E52320`)**:
     - Seluruh elemen pelacakan tetap konsisten menggunakan palet merah GAGE (`GageTheme.primary`, tanpa perubahan warna hijau).
     - Jalur track terisi penuh menuju node toko kanan; ikon ujung beralih dari pin lokasi ke ikon toko (`Icons.storefront_rounded`) dengan animasi gelombang radar merah konsentris lembut, dan motor G-Rider diparkir rapi di sebelah kiri ikon toko dengan jarak aman tanpa tumpang-tindih.
     - Pada tampilan 5 tahap (`MerchantOrderDetailScreen`), stage `'Siap'` menampilkan sonar pulse merah GAGE yang serasi dengan seluruh node tahap lainnya.
  5. **Hierarki Baris Driver & Pembatas Inset Tipis**:
     - Profil driver pada kartu luar disusun 2 baris bersih (nama bold + sublabel tipe kurir & plat) dan dipisahkan dari area tracking oleh garis pembatas horizontal tipis 1px tidak penuh (`horizontal: 10`, warna hairline rose lembut `GageTheme.primary @ 0.14` Light / `Colors.white @ 0.10` Dark).
  6. **Detail Order Parity**: `MerchantOrderDetailScreen` disinkronkan dengan pembatas horizontal tipis pada kartu driver dan label status ringkas konsisten (`Menuju Toko`, `Pengemudi telah tiba di toko`, `Menuju Pembeli • Est. X mnt`, `Pesanan Selesai`).

