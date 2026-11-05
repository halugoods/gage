# GAGE SuperApp - Master Frontend UI Style Guide & Design System

Dokumen ini adalah standar baku desain antarmuka (*UI/UX Frontend*) untuk seluruh ekosistem **GAGE** (Pracimantoro / Halu Goods Indonesia). Dokumen ini WAJIB dijadikan acuan oleh seluruh agent AI dan pengembang agar seluruh 4 portal (**Customer, Driver, Merchant, dan Admin**) memiliki bahasa visual, struktur komponen, dan mikro-interaksi yang seragam, elegan, dan anti-slop.

---

## 🏛️ 1. Filosofi Desain: Gojek Utility + iOS Human Interface

Ekosistem GAGE mengawinkan **kepraktisan utilitas superapp harian (Gojek/Grab)** dengan **kebersihan estetika dan taktil sistem iOS (Apple Human Interface Guidelines)**:

1. **Zero AI Slop & Clean Form**:
   - Dilarang membuat border kasar, gradient pelangi berlebihan, atau gaya generic AI dashboard.
   - Menggunakan estetika *Inset Grouped*, kontras warna yang tegas dan nyaman di mata, serta jarak spasi (*padding & margin*) yang bernapas lega.
2. **Zero Fake Gimmick**:
   - Dilarang membuat visualisasi peta palsu dengan koordinat statis di atas kontainer abu-abu (`_buildRadarPin`). Selalu gunakan `flutter_map` dengan tile riil OpenStreetMap.
   - Dilarang menambahkan banner promosi diri sendiri di portal internal (seperti Admin atau Driver).
3. **Zero Dummy Engineering**:
   - Dilarang membuat tombol atau kartu yang hanya memunculkan `SnackBar` janji fitur (*"Fitur segera hadir..."*).
   - Setiap elemen UI yang tampil wajib memiliki fungsi jelas, interaksi visual, atau terhubung ke state/API riil.
4. **Tactile Haptic Feedback**:
   - Setiap ketukan tombol utama, switch segmented control, dan pemilihan filter kategori wajib memicu getaran mikro taktil:
     ```dart
     HapticFeedback.lightImpact();
     ```

---

## 🎨 2. Palet Warna & Design Tokens

GAGE menggunakan palet warna khas yang dinamis antara mode Terang (*Light*) dan Gelap (*Dark*):

| Kategori Token | Nama Warna | Kode Hex (Light) | Kode Hex (Dark) | Kegunaan |
| :--- | :--- | :--- | :--- | :--- |
| **Brand Primary** | Merah Semangat GAGE | `#E52320` | `#EF4444` | CTA Utama, Aksen Aktif, Badge Status Penting |
| **Primary Deep** | Merah Crimson | `#B91C1C` | `#DC2626` | Hover/Pressed State, Header Accent |
| **Primary Soft** | Merah Pastel | `#FEE2E2` | `#450A0A` | Container Chip Aktif, Background Icon |
| **Background App** | Soft Cloud Slate | `#F8FAFC` | `#0F172A` | Background seluruh layar / Scaffold |
| **Surface Card** | Murni Putih / Dark Slate | `#FFFFFF` | `#1E293B` | Kontainer Kartu, Bottom Sheet, App Bar |
| **Border Line** | Hairline Border | `#E2E8F0` | `#334155` | Border kartu & pembatas (Opacity halus) |
| **Text Primary** | Deep Charcoal / Bright Slate| `#0F172A` | `#F8FAFC` | Judul, Angka Harga, Teks Utama |
| **Text Secondary**| Cool Slate | `#64748B` | `#94A3B8` | Label input, Deskripsi, Subjudul |
| **Text Muted** | Dim Slate | `#94A3B8` | `#64748B` | Placeholder, Timestamp, Keterangan Nonaktif |
| **Status Green** | Emerald Success | `#16A34A` | `#22C55E` | Driver Online, Pembayaran Lunas, Selesai |
| **Status Amber** | Golden Warning | `#F59E0B` | `#FBBF24` | Pesanan Disiapkan, Menunggu Kurir |
| **Status Blue** | Royal Info | `#2563EB` | `#3B82F6` | Tracking Kurir di Peta, Pesanan Online |

---

## 🔤 3. Hierarki Tipografi (`Poppins`)

Semua teks menggunakan font keluarga **`Poppins`** (via `GoogleFonts.poppinsTextTheme()`), memberikan karakter geometris modern, hangat, ramah, dan khas superapp premium:

```dart
// 1. Judul Halaman / Layar Utama (Screen Title)
TextStyle(fontSize: 20, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: textPrimary)

// 2. Judul Bagian / Kategori (Section Header)
TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2, color: textPrimary)

// 3. Nama Produk / Kartu Merchant / List Item
TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary)

// 4. Harga / Angka Transaksi (Nominal Rupiah)
TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textPrimary)

// 5. Teks Isi / Deskripsi (Body Text)
TextStyle(fontSize: 13, fontWeight: FontWeight.w400, height: 1.4, color: textSecondary)

// 6. Label Input / Subteks / Badge (Caption)
TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textSecondary)

// 7. Micro Badge / Tag Status
TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.3)
```

---

## 📐 4. Standar Spesifikasi Komponen UI Frontend

### A. Pola Input & Form Field (`GageFormField` / `GageInput`)
> **Aturan Wajib**: Label SELALU berada di luar/di atas kotak input, BUKAN floating label di dalam border.

* **Label Luar**: `fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary`, margin bottom `8px`.
* **Container Input**:
  - Border radius: `12px – 14px`
  - Padding jempol: `horizontal: 16px, vertical: 14px`
  - Fill Color: `#F1F5F9` (Light) / `#1E293B` (Dark)
  - Border Default: `Border.all(color: #E2E8F0, width: 1.0)`
  - Border Focused: `Border.all(color: #E52320, width: 1.5)`
  - Placeholder style: `color: textMuted, fontSize: 13`

```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Alamat Pengantaran', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textSecondary)),
    const SizedBox(height: 8),
    Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1E293B) : Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isFocused ? Color(0xFFE52320) : Color(0xFFE2E8F0)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: TextField(...),
    ),
  ],
)
```

---

### B. Pola Kartu & Kontainer (`GageCard`)
* **Corner Radius**: `16px` seragam.
* **Elevation**: `0` (Dilarang menggunakan drop shadow buram tebal ala template lama).
* **Border**: Hairline subtle border `BorderSide(color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06), width: 1)`.
* **Padding Internal**: `16px` (nyaman untuk jempol).

---

### C. Pola Tombol & Aksi (`GageButton`)
1. **Primary Button (Aksi Utama / Beli / Pesan)**:
   - Background: Merah GAGE (`#E52320`)
   - Text: Putih Murni (`#FFFFFF`), `fontWeight: FontWeight.w700, fontSize: 14`
   - Height: `48px – 52px` (Standar ergonomic mobile)
   - Corner Radius: `12px – 14px`
   - Loading State: `SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))`
2. **Secondary Button (Batal / Filter / Detail)**:
   - Background: Transparan / `#F1F5F9`
   - Border: `Border.all(color: #CBD5E1)`
   - Text: Deep Charcoal (`#0F172A`)
3. **Floating Cart Bar (Bilah Keranjang Melayang)**:
   - Kapsul melayang rounded `16px` di safe-area bawah (di atas bottom nav bar).
   - Menampilkan total item, subtotal rupiah, dan tombol hijau/merah *"Lanjut Bayar ➔"*.

---

### D. Pola Bottom Sheet & Modal (`GageBottomSheet` & `ItemVariantSheet`)
* **Corner Radius**: `Radius.vertical(top: Radius.circular(24))`
* **Drag Indicator Handle**: Baris abu-abu di bagian atas tengah (`width: 36px, height: 4px, borderRadius: 2px, color: textMuted`).
* **Safe Area Bottom**: Selalu bungkus dengan `SafeArea(top: false, child: ...)`.
* **Micro-interactions**: Selector kuantitas `[-] [Qty] [+]` dan tombol submit wajib memicu `HapticFeedback.lightImpact()`.

---

### E. Pola Grid Layanan Resmi (`GageServiceGrid`)
* **Struktur**: Grid 4 kolom x 2 baris (tepat 8 layanan resmi):
  1. `Ride` (Antar jemput motor)
  2. `Car` (Perjalanan mobil)
  3. `Food` (Pesan kuliner)
  4. `Shop` (Belanja sembako)
  5. `Send` (Kirim paket)
  6. `Farm` (Pertanian & peternakan)
  7. `Build` (Bahan bangunan & pertukangan)
  8. `Cuan` (Affiliate hub & komisi 10%)
* **Gaya Visual**: 100% transparan murni (*zero card container*, *zero border*, *zero drop-shadow*). Icon 3D clay `56x56` dengan label tebal `fontSize: 11.5`.
* **Taktil**: Setiap tap memicu `HapticFeedback.lightImpact()`.

---

### F. Pola Single-Merchant Locking & Dialog Ganti Toko (`SwitchMerchantDialog`)
* **Aturan Mutlak**: 1 Pesanan = 1 Toko (Single-Merchant). Mencegah kurir mondar-mandir dan menjaga kesegaran pesanan.
* **Respon Pergantian**: Dilarang memunculkan error toast kasar. Tampilkan dialog konfirmasi sopan:
  > *"Keranjang Anda saat ini berisi menu dari [Nama Toko Lama]. 1 pesanan hanya untuk 1 toko/resto. Kosongkan keranjang untuk beralih ke [Nama Toko Baru]?"*
* **Tombol Aksi**: `Batal` (TextButton abu-abu) dan `Ganti & Tambah` (ElevatedButton merah GAGE).

---

### G. Pola Bilah Keranjang Mengambang Kapsul (`SeamlessFloatingCartBar`) & Harmoni Navigasi
* **Pola Tumpukan Melayang Bertingkat (Vertical Coordinated Floating Stack)**:
  - Menyelesaikan dilema tumpang tindih elemen melayang di bagian bawah layar:
    1. **Di Layar Katalog / Detail Resto / Toko** (tidak ada navbar): `SeamlessFloatingCartBar` melayang di dasar layar (`bottom: 12px` + safe-area).
    2. **Di Layar Beranda (`HomeScreen`)**: `SeamlessFloatingCartBar` secara dinamis ter-docking melayang tepat di atas `GageBottomNavBar` dengan celah napas vertikal presisi `8px` dan margin horizontal sama persis `16px`.
* **Dimensi & Geometri**:
  - Bentuk kapsul melayang seragam: corner radius `32px` (identik dengan radius kapsul navbar Telegram).
  - Tombol aksi *"Lihat Pesanan"*: Pill capsule `borderRadius: BorderRadius.circular(24)` dengan padding `horizontal: 16, vertical: 9.5`.
  - Permukaan Frosted Glass semi-transparan dengan `ImageFilter.blur(sigmaX: 16, sigmaY: 16)` dan `BackdropFilter`.
  - Hairline border `#E2E8F0` / `Colors.white12` dengan bayangan ambient lembut `blurRadius: 18`.
* **Fitur**: Subtotal nominal rupiah, jumlah item, progress bar diskon dengan animasi glow berdenyut, dan tombol aksi *"Lihat Pesanan"* merah GAGE (`#E52320`).
* **Feed Spacer Otomatis & True Floating**:
  - `Scaffold(extendBody: true)` aktif di seluruh layar utama, sehingga feed konten mengalir bebas di bawah navbar tanpa blok putih kaku.
  - Bottom spacer pada feed beranda otomatis bergeser dari `100px` ke `170px` saat ada item di keranjang agar kartu konten paling bawah tidak tertutup.

---

### H. Pola Telegram-Style Floating Navigation Bar (`GageBottomNavBar` / `GageFloatingNavBar`)
* **File Lokasi**: `lib/shared/widgets/gage_bottom_nav_bar.dart` (alias: `GageFloatingNavBar`).
* **Estetika Floating Capsule Telegram**:
  - Bentuk kapsul melayang penuh dengan `borderRadius: BorderRadius.circular(32)` dan margin `EdgeInsets.fromLTRB(16, 4, 16, 12)`.
  - Permukaan Frosted Glass semi-transparan dengan efek blur `ImageFilter.blur(sigmaX: 16, sigmaY: 16)` dan `BackdropFilter`.
  - Dark Mode: `Color(0xFF1E293B)` (slate-800) opacity 94% dengan border `Colors.white12`.
  - Light Mode: `Colors.white` opacity 96% dengan border `Color(0xFFE2E8F0)`.
* **Micro-Interactions & Indikator Aktif**:
  - Tab yang dipilih memiliki background highlight kapsul lonjong `GageTheme.primary.withValues(alpha: 0.12)` di belakang ikon.
  - Ikon dan teks label aktif berwarna merah GAGE (`#E52320`) dengan font tebal (`FontWeight.w700`).
  - Ikon tidak aktif berwarna slate muted (`#64748B` / `Colors.white60`) dengan font medium (`FontWeight.w500`).
  - Getaran taktil `HapticFeedback.lightImpact()` pada setiap pergantian tab.
* **Badge Dinamis Real-Time**:
  - Tab `Pesanan`: Menampilkan badge counter angka merah dengan jumlah pesanan aktif (`orderProvider.activeOrders.length`).
  - Tab `Promo`: Menampilkan badge dot merah untuk notifikasi voucher promo baru.
* **Perpindahan Halaman Instan**:
  - Menggunakan `Navigator.pushReplacement` dengan `PageRouteBuilder(transitionDuration: Duration.zero)` untuk transisi tab secepat kilat tanpa glitch rendering.

---

### I. Pola Pilihan Pengantaran Decoy Effect (`DecoyDeliveryCard`)
* **Dua Opsi Bertingkat**:
  1. **Opsi HEMAT (Pilihan Utama)**:
     - Badge: `Terpopuler` (Hijau Pastel `#DCFCE7`, Teks `#16A34A`).
     - Tarif: 0-3 km Rp 9.000 (+Rp 3.000/km ke-4, +Rp 2.500/km ke-5, +Rp 2.000/km ke-6+).
  2. **Opsi REGULER (Prioritas / VIP)**:
     - Badge: `Prioritas` (Amber Pastel `#FEF3C7`, Teks `#D97706`).
     - Tarif: 0-3 km Rp 12.000 (+Rp 4.000/km ke-4, +Rp 3.500/km ke-5, +Rp 3.000/km ke-6+).
* **Pembulatan**: Pembulatan ke atas kelipatan Rp 500 (`roundUpTo500`).
* **Biaya Layanan**:
  - Non-tunai / Cashless (GagePay, QRIS, Transfer): Rp 1.000.
  - Tunai COD: Rp 3.000.
* **Proteksi COD**: Pesanan tunai dibatasi maksimal Rp 75.000. Jika subtotal melebihi Rp 75.000, opsi COD otomatis disabled dan mengarahkan ke non-tunai.

---

### J. Pola Stepper Pelacakan Pesanan 5-Tahap Standar Industri (`OrderTrackingStepper`)
* **5 Tahap Status Pesanan**:
  1. **`Pesanan Diterima`** (Biru `#2563EB` \| `Icons.receipt_long_rounded`) - Toko & sistem menerima pesanan.
  2. **`Sedang Disiapkan`** (Kuning `#D97706` \| `Icons.outdoor_grill_rounded`) - Toko sedang memasak/mengemas.
  3. **`Pesanan Siap`** (Oranye `#C2410C` \| `Icons.inventory_2_rounded`) - Selesai dikemas, siap dipickup kurir.
  4. **`Dalam Pengantaran`** (Merah `#E52320` \| `Icons.delivery_dining_rounded`) - Kurir meluncur ke rumah pemesan.
  5. **`Pesanan Selesai`** (Hijau `#16A34A` \| `Icons.check_circle_rounded`) - Paket diterima dengan bukti foto PoD.
* **Native In-App Chat Integration**:
  - Setiap kartu driver dan resto wajib menyediakan tombol Chat In-App langsung (`InAppChatScreen`), didampingi opsi telepon/WA sekunder.
  - Floating Action Button Chat In-App melayang di atas peta untuk akses cepat 1-sentuhan.

---

### K. Pola Filter Pill Kapsul Anti-Slop (`GageFilterPill`)
* **File Lokasi**: `lib/shared/widgets/gage_filter_pill.dart`.
* **Kiblat UI & Visual Tokens**:
  - Bentuk kapsul penuh (`BorderRadius.circular(50)`), tinggi kompak ~36px.
  - **State Inactive (Tidak Dipilih)**:
    - Light: Background pastel merah lembut Rose-50 (`#FFF1F2`), border halus Rose-200 (`#FECDD3`, lebar `1.2px`), teks merah GAGE `GageTheme.primary` (`#E52320`).
    - Dark: Background maroon gelap (`#2C1315`), border merah gelap (`#991B1B`), teks pastel (`#FCA5A5`).
  - **State Active (Terpilih)**:
    - Background: Solid merah GAGE `GageTheme.primary` (`#E52320`), border solid `#E52320`.
    - Teks: Putih bersih (`#FFFFFF`), `fontWeight: FontWeight.w700`.
    - Bayangan: Ambient glow halus `BoxShadow(color: GageTheme.primary.withValues(alpha: 0.28), blurRadius: 6, offset: Offset(0, 2))`.
  - **Zero Clutter**: Tanpa ikon silang (X) yang tidak perlu.
  - **Mikro-Interaksi**: Wajib memicu getaran taktil seleksi `HapticFeedback.selectionClick()` saat disentuh.
  - **Fungsionalitas**: Setiap filter pill wajib terhubung ke penyortiran atau penyaringan data riil (misal: *GAGE Plus*, *Di Bawah 10rb*, *Terlaris*, *Terdekat*, *Rating 4.5+*).

---

## 🔄 5. Aturan Replikasi Desain Antar-Portal

Portal **Customer** adalah induk dari bahasa visual ini. Portal lain mereplikasi pola yang sama dengan fungsi masing-masing:

| Komponen / Pola | Portal Customer (Induk) | Portal Driver | Portal Merchant | Portal Admin |
| :--- | :--- | :--- | :--- | :--- |
| **Aksen Utama** | Merah GAGE (`#E52320`) | Merah GAGE + Hijau Online | Merah GAGE + Kuning Toko Buka | Merah GAGE + Biru Sistem |
| **Peta Wilayah** | Tracking kurir & rute antar | Peta pickup resto & dropoff | Lokasi kurir tiba di resto | Live radar se-Pracimantoro |
| **Kartu Pesanan** | Rincian belanja & status resto | Kartu bid order masuk (Ongkir & Jarak) | Tiket pesanan dapur (Siapkan/Masak) | Card pesanan & reassign kurir |
| **Segmented Control** | Makanan, Mart, Ride, BaBe | Tab Order Masuk, Aktif, Selesai | Tab Menu Aktif, Habis, Kategori | Tab Radar, Keuangan, Tarif, Mitra |
| **Form Input** | Catatan pesanan & alamat | Konfirmasi plat motor & rekening | Input harga produk & foto menu | Input ubah tarif & komisi |

---

## ⚠️ Checklist Anti-Slop Pengembang Frontend

Sebelum commit kode UI pada portal manapun, pastikan lolos checklist ini:
- [ ] Apakah font menggunakan `Poppins`?
- [ ] Apakah label input berada **di luar / di atas kontainer field**?
- [ ] Apakah semua tombol aksi memicu `HapticFeedback.lightImpact()`?
- [ ] Apakah tidak ada visualisasi peta palsu (`_buildRadarPin` abu-abu)?
- [ ] Apakah tidak ada tombol dummy yang hanya memunculkan `SnackBar` kosong?
- [ ] Apakah ukuran target sentuh (*touch target*) minimal 44x44 pixel?
- [ ] Apakah tampilan mendukung Dark Mode dan Light Mode secara konsisten?
