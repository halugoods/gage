# GAGE SuperApp - Master Frontend UI Style Guide, Standar Desain & Audit Customer

Dokumen ini adalah standar baku antarmuka (*UI/UX Frontend*) untuk seluruh ekosistem **GAGE** (Pracimantoro / Halu Goods Indonesia) lintas 4 portal (**Customer, Merchant, Driver, dan Admin**). Seluruh agent AI dan pengembang wajib merujuk dokumen ini sebelum membuat atau memodifikasi komponen UI.

---

## 1. Filosofi Desain: Gojek Utility + iOS Human Interface

Ekosistem GAGE memadukan kepraktisan superapp transaksi harian (Gojek/Grab/ShopeeFood) dengan kebersihan estetika dan taktil iOS:

1. **Zero AI Slop & Clean Hierarchy**: Dilarang membuat border kasar berlebihan, gradient pelangi generik, atau banner dekoratif yang mengulang informasi yang sudah jelas dari konteks layar.
2. **Zero Fake Gimmick**: Dilarang membuat visualisasi peta palsu statis (`_buildRadarPin` abu-abu). Gunakan `flutter_map` tile OpenStreetMap nyata dengan [`MiniLocationPreviewMap`](gage-app/lib/shared/widgets/mini_location_preview_map.dart) untuk preview lokasi.
3. **Zero Dummy Engineering**: Dilarang membuat tombol yang hanya memunculkan `SnackBar` janji fitur. Seluruh data seed/demo wajib dikunci oleh `GageApiClient.useDevSeedData`.
4. **Clutter-Free Contextual UI**:
   - Jika widget preview sudah dapat diketuk langsung (contoh: `MiniLocationPreviewMap` di `RestoInfoScreen`), jangan tambah tombol aksi teks duplikat seperti `"Perbesar peta"`.
   - Untuk aksi media sekunder di dalam kartu informasi padat (seperti foto lokasi/lapak merchant), gunakan tombol teks+ikon ringkas (`"Foto lokasi merchant"` dengan ikon buka) alih-alih menyisipkan thumbnail besar dan deskripsi multi-baris.
   - Jika halaman daftar (contoh: `ShopFavoriteScreen`) dibuka dalam konteks satu entitas spesifik (`filterMerchantId != null`), jangan tampilkan segmented switch maupun banner status konteks tambahan; tampilkan langsung daftar item favorit merchant tersebut.
5. **Tactile Haptic Feedback**: Ketukan aksi utama memakai `HapticFeedback.lightImpact()`, sedangkan pergantian tab segmented switch, pill filter, atau sort dropdown memakai `HapticFeedback.selectionClick()`.

---

## 2. Palet Warna & Design Tokens

| Kategori Token | Nama Warna | Light Mode | Dark Mode | Kegunaan |
| :--- | :--- | :--- | :--- | :--- |
| **Brand Primary** | Merah Semangat GAGE | `#E52320` | `#EF4444` | CTA utama, active pill, badge diskon, Harga Coret |
| **Primary Deep** | Merah Crimson | `#B91C1C` | `#DC2626` | Hover/Pressed accent, highlight header |
| **Primary Soft** | Merah Pastel / Maroon | `#FEE2E2` | `#450A0A` | Pill chip inactive fill, ikon aksen lembut |
| **Background App** | Soft Cloud / Deep Slate | `#F8FAFC` | `#0F172A` | Background utama `Scaffold` |
| **Surface Card** | Putih Murni / Slate-800 | `#FFFFFF` | `#1E293B` | Kartu, Bottom Sheet, AppBar |
| **Border Line** | Hairline Slate | `#E2E8F0` | `#334155` | Pembatas daftar menu & border kartu |
| **Text Primary** | Deep Charcoal / White | `#0F172A` | `#F8FAFC` | Judul halaman, judul kategori, nama produk, harga |
| **Text Secondary** | Cool Slate | `#64748B` | `#94A3B8` | Label input, deskripsi, keterangan `terjual` |
| **Status Green** | Emerald Success | `#16A34A` | `#22C55E` | Driver online, status selesai, buka |
| **Status Amber** | Golden Warning | `#F59E0B` | `#FBBF24` | Rating bintang, pesanan disiapkan |
| **Status Blue** | Royal Info | `#2563EB` | `#3B82F6` | Link eksternal Google Maps, info tracking |

> **Aturan Keras Dark Mode**: Dilarang keras menaruh warna hardcoded `Colors.black87` atau `Colors.grey.shade200` pada teks produk, harga, atau garis pemisah daftar tanpa percabangan `isDark ? Colors.white : const Color(0xFF0F172A)`.

---

## 3. Hierarki Tipografi (`Poppins` + Fallback Sistem)

* **Screen Title**: `fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5`
* **Section / Category Header (Plain Unboxed Text)**: `fontSize: 15.5 - 16, fontWeight: FontWeight.w800`, tanpa container/card pembungkus.
* **Nama Produk / Item Katalog**: `fontSize: 14 - 15, fontWeight: FontWeight.w700`
* **Harga Produk / Transaksi**: `fontSize: 14.5 - 15, fontWeight: FontWeight.w700` (merah `#E52320` jika sedang promo Harga Coret)
* **Harga Asli Coret**: `fontSize: 12, decoration: TextDecoration.lineThrough, color: Colors.grey.shade500`
* **Teks `terjual` & Metadata**: `fontSize: 11.5, fontWeight: FontWeight.w500`, warna abu-abu polos (`Colors.grey.shade600` Light / `Colors.grey.shade400` Dark), **tanpa kotak/badge** dan **tersembunyi saat `0 terjual`**.

---

## 4. Spesifikasi Baku Komponen UI Portal Customer

### A. Wajib Full-Rounded Capsule Segmented Switch (`BorderRadius.circular(999)`)
Berlaku keras pada **seluruh 4 portal** untuk tab switch, mode toggle (`Delivery vs Pickup`, `Merchant Favorit vs Produk Favorit`, `Dalam Proses vs Selesai`, `Order Aktif vs Riwayat`, `BaBe vs Mitra Toko`):
* **Outer Track Container**: `padding: EdgeInsets.all(4)` (atau `3.5`), `borderRadius: BorderRadius.circular(999)` (atau `StadiumBorder`), fill `#F1F5F9` (Light) / `#0F172A` atau `#1E293B` (Dark), border tipis `#E2E8F0` / `Colors.white12`.
* **Inner Active Thumb**: `AnimatedContainer` (`200ms`, `Curves.easeOutCubic`), `borderRadius: BorderRadius.circular(999)`, fill `GageTheme.primary` (`#E52320`), teks putih `Colors.white` tebal (`FontWeight.w700` / `w800`).
* **Haptic**: wajib panggil `HapticFeedback.selectionClick()` pada `onTap`.
* **Referensi**: [`shop_favorite_screen.dart`](gage-app/lib/features/food/presentation/shop_favorite_screen.dart#L372-L432) (`999`), [`resto_detail_screen.dart`](gage-app/lib/features/food/presentation/resto_detail_screen.dart#L1540-L1615) (`999`). (Catatan: [`promo_screen.dart`](gage-app/lib/features/home/presentation/promo_screen.dart#L542-L574) sudah berbentuk pill visual namun token radius-nya masih `24`/`20`.)

### B. Kartu Produk Etalase Merchant (`RestoDetailScreen` / 4 Layanan: Food, Shop, Farm, Build)
Digunakan seragam oleh 4 vertikal niaga (`food`, `shop`, `farm`, `build`) via [`MerchantCatalogHelper`](gage-app/lib/features/food/data/merchant_catalog_helper.dart) & [`RestoDetailScreen`](gage-app/lib/features/food/presentation/resto_detail_screen.dart):
1. **Header Bagian Kategori Polos**: Ketika mode `Rekomendasi` aktif, daftar produk dikelompokkan di bawah **teks bold kategori tanpa kontainer/card pembungkus**, diurutkan sesuai pengaturan `categoryOrder` dari Portal Merchant (sisanya mengikuti urutan alami katalog).
2. **Dropdown Sort & Filter Kapsul**: Tombol kapsul `BorderRadius.circular(999)` di kanan judul katalog yang membuka [`GageFloatingSheet`](gage-app/lib/shared/widgets/gage_floating_sheet.dart) dengan 6 mode:
   - `Rekomendasi` (grouped bold categories)
   - `Terlaris` (daftar datar urut `soldCount` tertinggi)
   - `Baru ditambahkan` (daftar datar urut `created_at` terbaru)
   - `Lagi Promo` (filter khusus produk dengan Harga Coret aktif, urut diskon `%` tertinggi)
   - `Harga Termurah` (daftar datar urut harga efektif naik)
   - `Harga Termahal` (daftar datar urut harga efektif turun)
3. **Tata Letak Kiri Kartu Produk (Overflow-Safe untuk Layar 320px/360px)**:
   - Baris 1: Nama Produk (bold, adaptif Light/Dark).
   - Baris 2 (opsional): Deskripsi singkat max 2 baris.
   - Baris 3: `Wrap(spacing: 6)` berisi **Harga Promo / Jual** + **Harga Asli Dicoret** + teks **`-X%`** merah (jika Harga Coret aktif).
   - Baris 4: Teks polos abu-abu **`X terjual`** tepat **di bawah harga** (tanpa pill/badge; disembunyikan jika `<= 0`).
4. **Tata Letak Kanan Kartu**: Foto produk `86x86` rounded `12px` dengan tombol hati favorit kecil di pojok kanan atas, diikuti tombol kapsul `Tambah` atau stepper `[-] Qty [+]` + kapsul `Ubah Varian`.
5. **Harga Promo & Keranjang**: Saat item dengan Harga Coret masuk ke [`CartProvider`](gage-app/lib/providers/cart_provider.dart) atau [`ItemVariantSheet`](gage-app/lib/features/food/presentation/item_variant_sheet.dart), harga unit aktual yang ditagihkan adalah `effectivePrice`. Voucher Ongkir dan Voucher Toko tetap dapat dipakai selama subtotal promo memenuhi `minOrder`.

### C. Alur CTA Favorit -> Langsung Detail Produk
* Baik dibuka dari **dalam merchant detail** (ikon hati di [`RestoDetailScreen`](gage-app/lib/features/food/presentation/resto_detail_screen.dart)) maupun dari **luar merchant** ([`ShopFavoriteScreen`](gage-app/lib/features/food/presentation/shop_favorite_screen.dart) / `FavoriteRestoScreen`):
  - Mengetuk produk favorit wajib langsung memunculkan modal detail produk (`_showProductDetailModal`) tempat tombol `Tambah` / `Varian` berada, bukan sekadar mendarat di header toko.
  - Konteks di dalam merchant menyembunyikan segmented switch & banner konteks redundant.

### D. Info Toko (`RestoInfoScreen`), Minimap Preview & Ulasan (`RestoReviewsScreen`)
* **Minimap Preview**: Menggunakan [`MiniLocationPreviewMap`](gage-app/lib/shared/widgets/mini_location_preview_map.dart) dengan pin berfoto profil merchant di tengah pin lokasi, dapat diketuk langsung untuk membuka dialog peta penuh yang juga menampilkan **Foto Lokasi Merchant** (`StorefrontImage`). Tidak memakai tombol duplikat `"Perbesar peta"`.
* **Foto Lokasi Merchant**: Ditampilkan di kartu info sebagai tombol ikon+teks bersih (`"Foto lokasi merchant"`) di samping `"Buka di Google Maps"`.
* **Jam Operasional**: Sinkron dengan [`MerchantStorefrontService`](gage-app/lib/core/services/merchant_storefront_service.dart) (`Senin - Minggu` / toggle `"Buka setiap hari"`), terhubung ke Portal Merchant.
* **Kartu Ulasan & Rating**: Kartu bintang pada `RestoDetailScreen` dan header/tombol `"Lihat Semua"` pada `RestoInfoScreen` sama-sama membuka `RestoReviewsScreen`; rata-rata & jumlah ulasan dihitung riil oleh `MerchantStorefrontService.loadRatingSummary(...)`, dan respon penjual memakai avatar foto profil merchant.

### E. Checkout Order (`CheckoutScreen`) & Navigasi Mengambang (`HomeScreen`)
* **Urutan Kartu Checkout**: Ringkasan Pesanan -> Voucher -> Metode Pembayaran -> **Tip Driver (paling bawah)**.
* **Bilah Navigasi & Keranjang Kapsul**: `GageBottomNavBar` (`borderRadius: 32`, `Frosted Glass` `ImageFilter.blur(sigmaX: 24, sigmaY: 24)` di [`gage_bottom_nav_bar.dart`](gage-app/lib/shared/widgets/gage_bottom_nav_bar.dart#L105)) berharmoni dengan `SeamlessFloatingCartBar` berjarak vertikal `8px` (`Scaffold.extendBody = true`).
* **Grid Layanan**: 8 layanan resmi (`Ride, Car, Food, Shop, Send, Farm, Build, Cuan`) transparan murni tanpa kontainer kotak.
* **Filter Pill Horizontal (`GageFilterPill`)**: Kapsul penuh `50px`/`999`, inactive pastel Rose-50 `#FFF1F2` border Rose-200 `#FECDD3`, active solid `#E52320` teks putih.

---

## 5. Matriks Standar Lintas 4 Portal

| Komponen / Pola | Customer (Induk) | Merchant (`HANDOFF_MERCHANT.md`) | Driver (`HANDOFF_DRIVER.md`) | Admin (`HANDOFF_ADMIN.md`) |
| :--- | :--- | :--- | :--- | :--- |
| **Segmented Switch** | Pill `999` merah solid | Wajib migrasi ke Pill `999` | Wajib migrasi ke Pill `999` | Wajib migrasi ke Pill `999` |
| **Peta Lokasi** | OSM + `MiniLocationPreviewMap` | Pin koordinat + foto lokasi lapak | Rute jemput/antar + foto lapak | Live radar seluruh Kec. Pracimantoro |
| **Data Seed Guard** | Wajib `GageApiClient.useDevSeedData` | Wajib patuh `useDevSeedData` | Wajib patuh `useDevSeedData` | Wajib patuh `useDevSeedData` |
| **Katalog & Promo** | Tampil Harga Coret, `terjual`, kategori bold terurut | Kelola Harga Coret (Promosi) & urutan kategori | Lihat bukti `locationPhoto` pickup | Kelola voucher terpusat per layanan & D1 |

---

## 6. Laporan Audit UI & Drift Ekosistem (Tanggal Audit: 2026-11-12)

Ringkasan hasil pemindaian langsung kode `gage-app/lib` dan `gage-cloud/src/index.ts` (hanya fakta terverifikasi dari pembacaan file):

| Area / File | Status Audit | Temuan Aktual & Aksi |
| :--- | :--- | :--- |
| [`shop_favorite_screen.dart`](gage-app/lib/features/food/presentation/shop_favorite_screen.dart) | Diperbaiki | Tab switch sudah pill `999`; mode scoped merchant sudah tanpa banner & tanpa switcher; tap item kini meneruskan `initialProductItem` agar modal detail produk langsung terbuka. |
| [`resto_detail_screen.dart`](gage-app/lib/features/food/presentation/resto_detail_screen.dart) | Diperbaiki | Menambahkan `initialProductItem` CTA modal, sort/filter dropdown kapsul (`6` mode), section kategori teks bold polos terurut, Harga Coret + cart price propagation, teks abu-abu `terjual` di bawah harga, serta perbaikan kontras teks/border Dark Mode pada kartu produk (`L1695/L1711/L1729` lama). Catatan kecil tersisa: baris rating pada kartu overlay (`L1384` area lama) masih memakai `Colors.black87` statis, aman dirapikan bila menyentuh header overlay. |
| [`promo_screen.dart`](gage-app/lib/features/home/presentation/promo_screen.dart#L542-L574), [`orders_screen.dart`](gage-app/lib/features/orders/presentation/orders_screen.dart#L88-L105), & [`checkout_screen.dart`](gage-app/lib/features/checkout/presentation/checkout_screen.dart#L1264-L1338) | Compliant Visual (Minor Token) | Sudah berbentuk kapsul pill (`BorderRadius.circular(24)`/`20` pada tinggi `40-44px`). Standarkan token ke `BorderRadius.circular(999)` saat sentuhan berikutnya agar 100% seragam dengan `AGENTS.md`. |
| [`order_provider.dart`](gage-app/lib/providers/order_provider.dart#L18-L25) & [`merchant_order_provider.dart`](gage-app/lib/providers/merchant_order_provider.dart#L64-L65) | **Drift Terdeteksi (Production Guard)** | `_initDefaultOrders()` masih mengisi mock order tanpa memeriksa `if (!GageApiClient.useDevSeedData) return;`. Perlu diperbaiki pada iterasi kebersihan data produksi agar order contoh tidak masuk ke penghitungan `soldCount` produksi. |
| [`merchant_screen.dart`](gage-app/lib/features/merchant/presentation/merchant_screen.dart#L315-L348) | **Drift di Portal Merchant** | `_buildCustomTabBar` masih memakai underline `TabBar` (`indicatorWeight: 3`) alih-alih segmented pill `999`. Masuk ke [`docs/handoffs/HANDOFF_MERCHANT.md`](docs/handoffs/HANDOFF_MERCHANT.md). |
| [`driver_activity_screen.dart`](gage-app/lib/features/driver/presentation/driver_activity_screen.dart#L118-L172) | **Drift di Portal Driver** | Segmented bar masih kotak rounded (`BorderRadius.circular(12)` & `9`). Masuk ke [`docs/handoffs/HANDOFF_DRIVER.md`](docs/handoffs/HANDOFF_DRIVER.md). |
| [`admin_curation_screen.dart`](gage-app/lib/features/admin/presentation/admin_curation_screen.dart#L167-L230) | **Drift di Portal Admin** | Segmented switcher `BaBe vs Mitra Toko` masih kotak rounded (`BorderRadius.circular(12)` & `10`). Masuk ke [`docs/handoffs/HANDOFF_ADMIN.md`](docs/handoffs/HANDOFF_ADMIN.md). |
| [`gage-cloud/migrations/0001_initial_schema.sql`](gage-cloud/migrations/0001_initial_schema.sql#L57-L69) | **Celah Skema Backend** | Tabel `merchant_menus` belum punya kolom `sold_count`, `original_price`, `promo_price`, dan `merchants` belum menyimpan `category_order` serta `location_photo`/`operating_schedule`. Masuk ke `HANDOFF_ADMIN.md` & `HANDOFF_MERCHANT.md`. |

---

## Checklist Anti-Slop Sebelum Merge

- [ ] Seluruh Segmented Switch, Tab Switcher, dan Filter Chip memakai `BorderRadius.circular(999)` / `StadiumBorder` dengan active thumb `#E52320` + teks putih.
- [ ] Zero karakter Unicode em-dash (`\u2014`) di kode, komentar, test, maupun markdown.
- [ ] Seluruh mock/seed data hanya aktif saat `GageApiClient.useDevSeedData == true`.
- [ ] Tidak ada tombol/kartu aksi redundant atau banner status konteks yang mengulang informasi layar.
- [ ] Mendukung Light & Dark mode serta aman overflow pada lebar layar 320px/360px.
