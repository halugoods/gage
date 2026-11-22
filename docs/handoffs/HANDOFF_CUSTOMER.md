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
