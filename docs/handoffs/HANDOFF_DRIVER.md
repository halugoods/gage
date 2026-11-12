# Handoff Kontrak & Backlog Portal Driver

* **Target Agent Session ID**: `d98ee887-52c5-46f7-b28e-7288f9eb5385`
* **Panduan Visual Wajib**: [`GAGE_FRONTEND_UI_STYLE_GUIDE.md`](../../GAGE_FRONTEND_UI_STYLE_GUIDE.md) & [`AGENTS.md`](../../AGENTS.md)
* **Referensi Batas Portal**: [`PORTAL_BOUNDARIES.md`](../../PORTAL_BOUNDARIES.md)
* **Tanggal Handoff**: `2026-11-12`

> Dokumen ini merangkum seluruh kontrak data antara Portal Customer, Admin, dan Driver (`order_type`, `driver_tip`, metadata merchant lintas 4 layanan, serta sinkronisasi tarif dinamis), sekaligus temuan drift UI aktual di Portal Driver.

---

## 1. Inventaris File Portal Driver Saat Ini

* Root & Navigasi: [`driver_root_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_root_screen.dart), [`driver_bottom_nav_bar.dart`](../../gage-app/lib/features/driver/presentation/widgets/driver_bottom_nav_bar.dart)
* Beranda & Bid Order Radar: [`driver_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_screen.dart), [`incoming_offer_sheet.dart`](../../gage-app/lib/features/driver/presentation/widgets/incoming_offer_sheet.dart)
* Perjalanan & Pickup Aktif: [`active_trip_screen.dart`](../../gage-app/lib/features/driver/presentation/active_trip_screen.dart)
* Aktivitas & Riwayat: [`driver_activity_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_activity_screen.dart)
* Pendapatan & Dompet Mitra: [`driver_earnings_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_earnings_screen.dart)
* Akun & Chat: [`driver_account_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_account_screen.dart), [`driver_chat_list_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_chat_list_screen.dart)
* Provider & Service Bersama: [`driver_order_provider.dart`](../../gage-app/lib/providers/driver_order_provider.dart), `DriverWalletProvider`, [`gage_pricing_service.dart`](../../gage-app/lib/core/services/gage_pricing_service.dart), [`merchant_storefront_service.dart`](../../gage-app/lib/core/services/merchant_storefront_service.dart)

---

## 2. Audit Drift UI Kritis di Portal Driver

1. **Kotak Rounded pada Segmented Switch di [`driver_activity_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_activity_screen.dart#L118-L172)**:
   * **Temuan Aktual**: Segmented bar `Sedang Berjalan` vs `Riwayat Selesai` masih memakai `BorderRadius.circular(12)` untuk track luar dan `BorderRadius.circular(9)` untuk tombol aktif dengan active color putih/slate.
   * **Aksi Wajib**: Ubah outer track dan active thumb menjadi kapsul penuh **`BorderRadius.circular(999)`** (atau `StadiumBorder`), active thumb warna **`GageTheme.primary` (`#E52320`)** dengan teks putih tebal (`Colors.white`), outer track `#F1F5F9` / `#0F172A` (`EdgeInsets.all(4)`), dan tetap picu `HapticFeedback.selectionClick()`.
2. **Standar Kartu & Peta**: Pastikan seluruh UI Driver patuh Dark/Light Mode tanpa `Colors.black87` statis dan memakai OpenStreetMap `flutter_map` tanpa peta dummy statis.

---

## 3. Kontrak Sinkronisasi Data Driver yang Wajib Ditambahkan / Diperbaiki

Hasil audit menunjukkan beberapa field penting dari Customer belum tersedia di `DriverOrderOffer` (`driver_order_provider.dart#L7-L42`) dan respon `/api/driver/orders/available`:

### A. Isolasi Order `DELIVERY` vs `PICKUP`
* **Celah Saat Ini**: `GET /api/driver/orders/available` (`gage-cloud/src/index.ts#L1409`) hanya memfilter `o.driver_id IS NULL AND o.status IN ('PAID', 'COOKING', 'READY_FOR_PICKUP')` dan `DriverOrderOffer` belum memiliki `orderType`.
* **Kontrak Baru**: Tambahkan field `final String orderType;` (`'DELIVERY'` atau `'PICKUP'`, default `'DELIVERY'`) pada `DriverOrderOffer`. Backend wajib menyaring `AND o.order_type = 'DELIVERY'`, dan `DriverOrderProvider` di client juga mengabaikan item dengan `orderType == 'PICKUP'` sebagai pertahanan lapis kedua.

### B. Metadata Toko Lintas 4 Layanan (`merchantId`, `serviceType`, Koordinat, `locationPhoto`)
* **Celah Saat Ini**: `fetchAvailableOrdersFromCloud` (`driver_order_provider.dart#L147-L148`) masih mengisi hardcoded `serviceType: 'food'` dan `serviceName: 'GAGE Food'`, serta `DriverOrderOffer` belum menyimpan `merchantId`, `pickupLat`, `pickupLng`, maupun `merchantLocationPhoto`.
* **Tugas Portal Driver**:
  - Tambahkan field `merchantId`, `serviceType` (`'food' | 'shop' | 'farm' | 'build' | 'ride' | 'car' | 'send'`), `pickupLat`, `pickupLng`, dan `merchantLocationPhoto` ke `DriverOrderOffer` dengan parsing dari `/api/driver/orders/available`.
  - Di [`active_trip_screen.dart`](../../gage-app/lib/features/driver/presentation/active_trip_screen.dart), teruskan `merchantId` aktual saat memanggil `MerchantStorefrontService.loadStorefront(merchantId, merchantName: ...)` agar foto lokasi lapak (`locationPhoto`) dan pin `MerchantStorefrontService.resolveCoordinate(...)` muncul akurat pada seluruh 4 layanan niaga.
  - **Indikator Jam Tutup Merchant**: Jika `storefront?.schedule` tersedia dan toko tutup atau sisa waktu `< 30 menit` menuju `closeTime` hari ini, tampilkan badge peringatan halus di kartu detail pickup (`"Toko tutup dalam X menit"`). Jika `schedule == null`, jangan tampilkan peringatan spekulatif.

### C. Transparansi `driverTip` & Tarif Dinamis (`GagePricingService`)
* **Celah Saat Ini**: `DriverOrderOffer` belum memiliki field `int driverTip` (`default 0`) dan `DriverOrderProvider.calculateDriverCleanEarning` (`driver_order_provider.dart#L118`) masih meng-hardcode pengali `0.80` alih-alih membaca `GagePricingService.driverCommissionRatio`.
* **Tugas Portal Driver**:
  - Tambah `final int driverTip;` pada `DriverOrderOffer` (baca dari `driver_tip` / `driverTip`).
  - Ganti hardcoded `0.80` dengan `GagePricingService.driverCommissionRatio`, dan tampilkan komponen bersih: **`(ongkir * GagePricingService.driverCommissionRatio) + driverTip`** (tip 100% hak driver).
  - Tampilkan rincian `driverTip` secara eksplisit pada `incoming_offer_sheet.dart`, `active_trip_screen.dart`, dan `driver_earnings_screen.dart`.
  - Pastikan tarif jarak & komisi juga menyegarkan config terbaru dari backend saat tersedia (koordinasi dengan `HANDOFF_ADMIN.md`).
  - Diskon produk item (`Harga Coret` Customer) hanya memotong subtotal barang Merchant dan tidak memotong hak ongkir Driver.

### D. Kepatuhan Seed Data Produksi (`GageApiClient.useDevSeedData`)
* Audit `DriverOrderProvider`, `DriverWalletProvider`, dan `driver_screen.dart` untuk memastikan bid order contoh dan saldo/riwayat simulasi **hanya** dimuat jika `GageApiClient.useDevSeedData == true`.

---

## 4. Kontrak Wave 1 & Wave 2 Terbaru (Sinkronisasi Customer + Transport + Cloud D1)

1. **Ketersediaan Data Driver Real-Time ke Portal Customer**:
   - `OrderDetailScreen`, `OrdersScreen`, dan `OrderTrackingScreen` di Portal Customer kini menyembunyikan kartu driver dan tidak lagi menampilkan nama/plat/nomor HP fallback (`useDevSeedData == false`) selama `order.hasAssignedDriver` bernilai `false` (`driverId`/`driverName` kosong).
   - Saat Driver menerima order (`POST /api/driver/orders/:id/accept`), backend/D1 wajib mengisi `driver_id`, `driver_name`, `driver_vehicle`/`driver_plate`, dan `driver_phone` agar kartu pengemudi langsung muncul real-time di Customer.
2. **Transisi Status Berurutan & Akses In-App Chat**:
   - Customer tidak lagi membuka peta tracking secara otomatis segera setelah checkout (`OrderDetailScreen` menjadi layar utama, tombol lacak bersifat opsional selama status aktif bukan `PAYMENT_PENDING` atau `PICKUP`).
   - Pastikan Driver memperbarui status berurutan: `PAID` (tunggu merchant) -> `COOKING` -> `READY_FOR_PICKUP` -> `DRIVER_ASSIGNED` -> `ON_THE_WAY` -> `COMPLETED`.
   - Seluruh tombol WhatsApp Customer ke Driver telah diganti ke `InAppChatScreen` (`recipientRole: 'driver'`) dan `tel:` (hanya aktif bila `driverPhone` valid). Pastikan Driver mengandalkan chat in-app dan pembaruan foto/status valid.
3. **Kontrak Layanan Transport (`Ride`, `Car`, `Send`) & Paket Berat (`weightKg`)**:
   - Customer `SendBookingScreen` dan `RideCheckoutScreen` kini mendukung pengisian rincian paket yang dapat diedit (`package_details_json`: jenis, estimasi berat `weight_kg`, catatan kurir, dan penyesuaian tarif berat).
   - Driver `DriverOrderOffer` / trip screen wajib menampilkan `packageDetails` / `weight_kg`, koordinat lengkap `pickupLat`/`pickupLng` & `deliveryLat`/`deliveryLng`, serta `driverTip` agar kurir siap membawa kapasitas barang yang sesuai.
4. **Pembersihan Referensi Lama**:
   - Hapus referensi lama non-aktif di `driver_screen.dart` (`Lapak BaBe & Kios Sedayu` di L63) pada gelombang kerja Portal Driver agar selaras dengan penghapusan GAGE BaBe di Customer.
   - `driver_order_provider.dart` saat ini belum mengimpor/memeriksa `GageApiClient.useDevSeedData`; wajib ditambahkan guard sebelum rilis produksi Driver.
