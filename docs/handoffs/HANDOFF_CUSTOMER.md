# Handoff Desain & Fitur Portal Customer

* **Sumber Handoff**: Merchant Portal (`1c4b07ce-55ca-434a-821e-f12ef99bac9c`)
* **Panduan Visual Wajib**: `GAGE_FRONTEND_UI_STYLE_GUIDE.md` & `AGENTS.md`
* **Tanggal Handoff**: `2026-11-22`

---

## 1. Item Card Mini Preview Produk (Ukuran 2 Baris Teks)

* **Lokasi Target**:
  - `lib/features/orders/presentation/order_detail_screen.dart`
  - `lib/features/orders/presentation/order_history_screen.dart`
  - Dialog / Sheet Struk Transaksi Digital Customer (`GageReceiptShareDialog`)
* **Spesifikasi UI Paritas**:
  - Setiap baris produk pesanan kini dilengkapi dengan preview gambar mini produk:
    - Ukuran: `width: 38`, `height: 38` (seukuran proporsional 2-baris teks nama item dan catatan varian).
    - Sudut: `BorderRadius.circular(8)`.
    - Warna background fallback: `Colors.grey.shade200` (Light) / `Colors.white10` (Dark).
    - Ikon fallback jika `imageUrl == null`: `Icons.inventory_2_outlined` dengan ukuran 18.
    - Struktur row: `[Mini Image Preview (38x38)] -> SizedBox(width: 8) -> [Badge Kuantitas Qty x] -> SizedBox(width: 8) -> [Nama Item & Catatan Varian] -> Spacer -> [Subtotal Harga Item]`.

---

## 2. Floating Bottom Navigation Bar: Transisi Outline Stroke ke Filled

* **Lokasi Target**:
  - `lib/features/home/presentation/widgets/gage_bottom_nav_bar.dart` (Customer Floating Frosted Bar)
* **Spesifikasi Navigasi**:
  - Sebelum dipilih (unselected): Ikon menggunakan gaya outline stroke (`*_outlined`).
  - Setelah dipilih (selected): Ikon bertransformasi menjadi gaya filled (`*_rounded` / solid).
  - Skema Ikon Customer:
    - Beranda: `Icons.home_outlined` -> `Icons.home_rounded`
    - Pesanan: `Icons.receipt_long_outlined` -> `Icons.receipt_long_rounded`
    - GagePay: `Icons.account_balance_wallet_outlined` -> `Icons.account_balance_wallet_rounded`
    - Akun: `Icons.person_outline_rounded` -> `Icons.person_rounded`
  - Haptic feedback tetap dipicu saat tab berubah: `HapticFeedback.selectionClick()`.

---

## 3. Notifikasi Interaktif Full-Screen & Media Gambar Admin (`imageUrl` & `actionUrl`)

* **Lokasi Target**:
  - `lib/core/services/notification_service.dart`
  - `lib/features/notification/presentation/notification_screen.dart`
  - `lib/features/notification/presentation/notification_detail_screen.dart`
* **Spesifikasi Model & UI**:
  - Model `GageNotification` memiliki field: `imageUrl` (`String?`) dan `actionUrl` (`String?`).
  - Item notifikasi pada daftar kini dapat ditekan (*tappable*) dan membuka layar penuh `NotificationDetailScreen`.
  - Jika notifikasi menyertakan `imageUrl` (broadcast promo/informasi dari Admin), render gambar dengan `ClipRRect(borderRadius: BorderRadius.circular(16))` di layar detail, dan thumbnail kompak di kartu list.

---

## 4. Search Bar Floating & Geometri Kapsul Penuh (999) 1:1 Paritas

* **Lokasi Target**:
  - `lib/features/home/presentation/widgets/home_search_bar.dart`
  - `lib/features/food/presentation/food_home_screen.dart`
  - `lib/features/shop/presentation/shop_home_screen.dart`
* **Spesifikasi UI Paritas**:
  - Search bar harus mengambang jernih (*floating*) di atas list produk tanpa adanya kontainer penampung putih kaku di belakangnya.
  - Border geometry: Selalu menggunakan kapsul penuh `BorderRadius.circular(999)` atau `StadiumBorder()`.
  - Dimensi: Tinggi seragam `height: 42` s/d `44`.
  - Styling Text Field: Hint text halus (`#94A3B8`), ikon pencarian di kiri, dan tombol aksi (filter/QR) yang proporsional di kanan.

---

## 5. Paritas Tipografi Header Menu, Font Size & Standardisasi Komponen

* **Lokasi Target**:
  - Seluruh sub-screen menu Customer (`lib/features/food/`, `lib/features/shop/`, `lib/features/orders/`)
* **Spesifikasi Tipografi & Spacing**:
  - Judul AppBar: Maksimal 16-17px dengan `FontWeight.w800` (Gage font), hindari judul multi-baris yang verbose.
  - Subtitle deskripsi: 11-12px dengan warna sekunder (`#64748B` di mode terang / `#94A3B8` di mode gelap).
  - Badge Status & Chips: Wajib menggunakan kapsul penuh (`BorderRadius.circular(999)`), bukan persegi panjang bersudut 8-16px.
  - Hapus tombol atau badge redundant yang menduplikasi preview interaktif (misal: tombol 'Perbesar peta' di sebelah mini map yang sudah bisa di-tap).

---

## 6. Prosedur Penjemputan Tugas oleh Agen Sesi Chat Customer

* **Mekanisme Kerja**:
  1. Pengguna membuka sesi chat agent Customer.
  2. Agen Customer secara otomatis diinstruksikan oleh `c:\Users\ertyui\ZCodeProject\gage\AGENTS.md` Bagian 4 (*Mandatory Cross-Portal Handoff Documentation*) untuk membaca file handoff ini (`docs/handoffs/HANDOFF_CUSTOMER.md`).
  3. Agen Customer langsung mengimplementasikan penyesuaian di direktori `lib/features/orders/`, `lib/features/home/`, dan `lib/features/food/` sesuai instruksi butir 1 sampai 5 di atas tanpa perlu didekte ulang.

---

## 7. Status Implementasi & Verifikasi (Selesai - 2026-11-24)

1. **Item Card Mini Preview Produk & Penyelarasan Layout Pesanan Customer**:
   - `lib/features/orders/presentation/order_detail_screen.dart`: Section "Item Pesanan" diselaraskan 1:1 dengan layout Merchant (Gambar 3):
     - Outer container padding: 14, radius 16.
     - Header: `Item Pesanan` (13.5px bold) & `${order.items.length} Macam` (11.5px grey).
     - Kontainer per item: `#F8FAFC` (Light) / `#0F172A` (Dark), radius 10, padding 8.
     - Thumbnail: 38x38 (radius 8) menggunakan `item.effectiveImageUrl` (otomatis resolve aset lokal makanan seperti dimsum, chicken, dll).
     - Badge kuantitas: Soft rounded rectangle `BorderRadius.circular(6)`, background `#E2E8F0` / `white12`, font 12px `FontWeight.w800` (`${item.quantity}x`).
     - Teks: Nama item (12.5px bold) dan catatan varian/notes (11px grey `#64748B`), bersih tanpa nama toko redundan di dalam baris item.
     - Subtotal harga item: 12.5px bold di sisi kanan.
   - `lib/features/orders/presentation/orders_screen.dart`: Kartu daftar pesanan customer (`_buildOrderCard`):
     - Header baris 1 (Style Lama Customer): Chip invoice bersih berupa teks nomor invoice dengan ikon salin merah di kiri, dan badge status kapsul (`BorderRadius.circular(999)`) di kanan. Tanpa kontainer merah muda (#INV...), tanpa tag 'Pesan Antar', dan tanpa teks waktu elapsed di header.
     - Baris 2: Profil Toko (15px bold) + alamat merchant (11.5px grey) dengan tag 'Multi Toko' bila berlaku.
     - Baris 3: Kontainer item abu-abu (`#F8FAFC` / `#0F172A`, radius 12, padding 10) dengan mini preview gambar produk (34x34 menggunakan `item.effectiveImageUrl`), kuantitas (`${item.quantity}x`), nama produk, varian, dan harga.
     - Baris 4: `Total Pembayaran` (11px grey) & nominal bold merah 15.5px (`GageTheme.primary`).
     - Tombol aksi ergonomis StadiumBorder: `[Rincian]`, `[Batalkan]` (jika aktif & dapat dibatalkan), `[Struk]` (jika selesai), `[Lacak]` (jika aktif pengantaran), dan `[Pesan Lagi]` (jika riwayat).
     - Aturan Privasi & Interaksi: Tombol `Chat Toko` dihapus dari kartu pesanan customer karena customer tidak boleh chat langsung ke merchant kecuali merchant yang memulai chat terlebih dahulu.

2. **Floating Bottom Nav Bar: Transisi Outline Stroke ke Filled**:
   - Selesai di `lib/shared/widgets/gage_bottom_nav_bar.dart`.
   - Ikon unselected menggunakan outline stroke (`*_outlined`), selected menggunakan filled (`*_rounded` / solid).

3. **Verifikasi & Build**:
   - Analisis statis `flutter analyze`: 0 issues found.
   - Unit tests `flutter test`: 13 passed, 0 failed.
   - Build debug APK customer flavor & instalasi berhasil via ADB pada perangkat fisik Samsung `R5CR81GTJDD`. Visual terverifikasi via tangkapan layar langsung.
   - Skema ikon lengkap: Beranda (`home_outlined` -> `home_rounded`), Pesanan (`receipt_outlined` -> `receipt_rounded` solid filled, menggantikan `receipt_long` yang tidak memiliki varian filled di Flutter Material Icons), Promo (`local_offer_outlined` -> `local_offer_rounded`), Video (`play_circle_outline_rounded` -> `play_circle_fill_rounded`), Profil (`person_outline_rounded` -> `person_rounded`).
   - Haptic feedback `HapticFeedback.selectionClick()` aktif di setiap perubahan tab.

3. **Notifikasi Interaktif Full-Screen & Media Gambar Admin**:
   - Model `GageNotification` di `lib/core/services/notification_service.dart` mendukung `imageUrl` dan `actionUrl`.
   - `lib/features/notification/presentation/notification_screen.dart` menampilkan thumbnail kompak dan navigasi interaktif ke detail screen, badge 'BARU' menggunakan kapsul penuh `BorderRadius.circular(999)`.
   - `lib/features/notification/presentation/notification_detail_screen.dart` merender gambar promosi/pengumuman dengan `ClipRRect(borderRadius: BorderRadius.circular(16))` dan `AspectRatio(16/9)`.

4. **Search Bar Floating & Geometri Kapsul Penuh (999)**:
   - Selesai di `lib/features/home/presentation/widgets/gage_home_header.dart` (tinggi 42, kapsul penuh 999, hint text `#94A3B8`).
   - Alamat pengiriman di atas search bar beranda (`📍 Rumah 1 ⌵`) telah dihapus agar search bar melayang rapi di bawah status bar tanpa menggeser konten beranda ke bawah.
   - Selesai di `lib/shared/widgets/gage_service_header.dart` (tinggi 42, kapsul 999 untuk G-Food, G-Shop, G-Farm, chip lokasi kapsul 999).
   - Logika penampil alamat di sub-screen (Food, Shop, Farm) telah distandarisasi untuk memprioritaskan label ringkas (misal "Rumah 1") tanpa konkatenasi berulang.

5. **Paritas Tipografi Header Menu, Font Size & Standardisasi Komponen**:
   - Section "Item Pesanan" di `order_detail_screen.dart` diselaraskan 1:1 dengan layout Merchant: Header `Item Pesanan` dan `X Macam`, item row terdiri dari thumbnail 38x38, badge kuantitas kapsul R999, nama item bold, subtitle varian/catatan bersih tanpa prefix "Catatan:" atau format miring, serta subtotal harga di kanan tanpa baris `@ Rp...` redundan.
   - Seluruh referensi menu G-Build yang telah diputuskan dihapus dibersihkan secara menyeluruh dari beranda (showcase section, smart search sheet, promo carousel, promo screen, checkout).
   - Seluruh badge kuantitas, status chips, unread count badges, dan rating banner di `orders_screen.dart`, `order_detail_screen.dart`, `order_tracking_screen.dart`, `gage_home_header.dart`, `resto_detail_screen.dart`, `category_merchant_list_screen.dart`, dan `resto_reviews_screen.dart` telah distandarisasi ke kapsul penuh `BorderRadius.circular(999)`.
   - Tidak ada duplikasi aksi redundan di dekat peta mini interaktif.
   - Seluruh static analysis (`flutter analyze`) dan unit/widget tests (`flutter test`) lulus 100%.


