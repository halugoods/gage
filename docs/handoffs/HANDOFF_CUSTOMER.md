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


