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
   - Layanan GAGE Send menggunakan tier **`INSTAN`** dan **`HEMAT`** (bukan `REGULER`). Driver radar dan rincian penawaran wajib menampilkan tier ini (`deliveryOption`) secara konsisten.
   - Informasi penerima paket (`recipient_name` dan `recipient_phone`) diisi otomatis oleh Customer dari riwayat kontak terakhir atau favorit tersimpan, dan diteruskan dalam payload `package_details` agar Driver/Kurir dapat langsung melihat nama dan nomor telepon/WhatsApp penerima saat tiba di tujuan.
   - Driver `DriverOrderOffer` / trip screen wajib menampilkan `packageDetails` / `weight_kg`, koordinat lengkap `pickupLat`/`pickupLng` & `deliveryLat`/`deliveryLng`, serta `driverTip` agar kurir siap membawa kapasitas barang yang sesuai.
4. **Pembersihan Referensi Lama**:
   - Hapus referensi lama non-aktif di `driver_screen.dart` (`Lapak BaBe & Kios Sedayu` di L63) pada gelombang kerja Portal Driver agar selaras dengan penghapusan GAGE BaBe di Customer.
   - `driver_order_provider.dart` saat ini belum mengimpor/memeriksa `GageApiClient.useDevSeedData`; wajib ditambahkan guard sebelum rilis produksi Driver.

---

## 5. Kontrak Pembatalan Pesanan oleh Pelanggan (`canBeCancelledByCustomer`) & Struk Digital

1. **Aturan Pembatalan Pelanggan pada Transport (`Ride`, `Car`, `Send`)**:
   - Pelanggan diizinkan membatalkan pesanan secara mandiri selama driver belum ditetapkan (`!hasAssignedDriver` atau status `SEARCHING_DRIVER`, `PAID`, `PENDING`).
   - Begitu driver menerima pesanan (`DRIVER_ASSIGNED`, `ON_THE_WAY`), opsi pembatalan langsung pelanggan terkunci untuk melindungi hak perjalanan driver.
   - Endpoint: `PUT /api/orders/:id/status` dengan payload `{ "status": "CANCELLED", "cancellation_reason": "Dibatalkan oleh pelanggan" }`.
   - Radar Driver: Saat status order menjadi `CANCELLED`, radar driver wajib segera menarik kartu penawaran aktif agar driver tidak menerima order yang sudah dibatalkan.
2. **Struk Digital Interaktif & Verifikasi Lapangan**:
   - Customer kini dapat membagikan struk/bukti bayar digital berbentuk gambar tiket perforasi lengkap dengan QR Code (`GageReceiptShareDialog`).
   - Driver/Kurir dapat mencocokkan nomor pesanan atau memindai QR Code struk pelanggan untuk konfirmasi serah terima barang di tempat.

---

## 6. Handoff Wave 6: Standardisasi Terminologi QRIS & User Ownership Google Auth

1. **Void Kata 'QRIS Instant' di Dompet Driver (`driver_earnings_screen.dart`)**:
   - Seluruh alur setoran saldo / pelunasan komisi COD oleh driver telah diubah dari 'QRIS Instant' menjadi baku **'QRIS'**.
   - Nama metode pembayaran di dompet dan histori mutasi seragam 'QRIS' tanpa imbuhan 'Instan' atau 'Instant'.
2. **Standardisasi Nama Layanan Baru GAGE**:
   - Master entity layanan pengemudi kini selaras: `G-Ride`, `G-Car`, `G-Send`.
   - Huruf dan label layanan pada seluruh radar order menggunakan font tebal tegas `FontWeight.w800`.
3. **User Ownership via Google Auth & Cloudflare D1**:
   - Akun driver diikat pada `user_id` hasil autentikasi Google. Radar penawaran dan riwayat order divalidasi berdasarkan kepemilikan akun driver terverifikasi.

---

## 7. Handoff Wave 7 & 8: PIN 4-Digit Serah Terima Pesanan & Standarisasi Invoice Cloudflare

1. **Mekanisme Serah Terima Fisik Barang & PIN 5 Menit Otomatis (Wave 8)**:
   - Merchant menampilkan 4-digit PIN serah terima di dasbor toko (`OrderModel.currentPin`).
   - **Regenerasi Otomatis 5 Menit**: PIN tidak lagi diacak manual oleh merchant untuk mencegah desinkronisasi. PIN dihitung dengan formula deterministik berbasis window waktu 5 menit (`DateTime.now().millisecondsSinceEpoch ~/ 300000`).
   - Driver yang tiba di toko wajib menanyakan dan menginput PIN tersebut ke aplikasi Driver (`active_trip_screen.dart`) sebelum status pesanan berubah ke `ON_THE_WAY`.
2. **Standarisasi Nomor Invoice Platform Cloudflare D1**:
   - Seluruh invoice pesanan kini terstandarisasi dengan format resmi Cloudflare D1 (`#INV-XXXX` / `INV-YYYYMMDD-XXXX`), menggantikan penamaan acak personal (seperti `#RATNA-3304`). Driver dapat memverifikasi nomor invoice yang identik dengan struk pemesan dan merchant.

---

## 8. Handoff Wave 11: PIN Serah Terima Stabil & Notifikasi Interaktif Media Gambar

1. **PIN Serah Terima Stabil**:
   - Menghapus regenerasi otomatis per 5 menit pada PIN serah terima agar kurir tidak mengalami penolakan PIN saat terjadi latensi jaringan di kios merchant. PIN bersifat stabil per pesanan.
2. **Notifikasi Interaktif & Media Gambar Broadcast Admin**:
   - Driver Portal mengadopsi pembaruan `GageNotification` (`imageUrl` & `actionUrl`), di mana notifikasi promosi atau penugasan khusus dari admin dapat menampilkan media gambar resolusi tinggi dan membuka `NotificationDetailScreen`.






---

## 9. Handoff Wave 15: Sinkronisasi Foto Profil Driver di Chat & Pembersihan Nama

1. **Tampilan Foto Profil & Nama Driver di Customer Portal (`ChatHubScreen`, `InAppChatScreen`, `OrderDetailScreen`)**:
   - Customer Portal kini membersihkan akhiran `(Driver GAGE)`, `(Driver)`, maupun plat kendaraan di dalam judul nama via `InAppChatScreen.cleanDisplayName(..., role: 'driver')` (hanya menampilkan nama asli driver seperti `Budi Santoso`), sambil mempertahankan chip/pill peran `Driver`.
   - `ChatHubScreen` tidak lagi menampilkan icon statis `assets/images/gage_chat_icon.png` untuk driver; saat `order.driverAvatar` terisi dari Cloudflare D1, avatar otomatis me-render foto asli tersebut (`GageAvatar.resolveSourceUrl` mendukung URL penuh maupun path relatif `/api/chat/media/...` & `/media/...`), dan saat kosong menampilkan inisial nama.
   - Entri dukungan aplikasi kini bernama `Pusat Bantuan` (tab `Bantuan`) menggunakan icon `assets/images/gage_icon.png` tanpa label `AI` ataupun badge `24/7`.
2. **Aksi yang Diperlukan di Portal Driver (`lib/features/driver/`)**:
   - **Upload Foto Profil Driver**: Sediakan kontrol upload/ganti foto profil pada layar akun driver (`DriverAccountScreen`) menggunakan upload media R2 (`POST /api/chat/media/upload` atau endpoint upload R2 serupa) dan simpan URL hasilnya melalui `POST /api/user/profile` (`avatar_url`) sehingga kolom `du.avatar_url as driver_avatar` pada query order (`gage-cloud/src/index.ts`) otomatis menampilkan foto driver asli di Customer & Merchant.
   - **Bersihkan Nama & Teruskan `recipientAvatar` di `DriverChatListScreen`**: Hapus label `(Driver GAGE)`/`(24/7)` atau `AI Assistant` bila masih muncul pada daftar/room chat driver, dan teruskan `recipientAvatar: order.customerAvatar` / `order.merchantAvatar` ke `InAppChatScreen`.

---

## 10. Handoff Wave 16: Handoff Lengkap Seluruh File Chat (`lib/features/chat/`) untuk Eksekusi Portal Driver

Dokumen ini merinci seluruh file Dart modul chat yang dipakai bersama serta daftar eksekusi wajib di Portal Driver (`lib/features/driver/`).

### A. Kontrak File Chat Bersama (`gage-app/lib/features/chat/` & `shared/widgets/gage_avatar.dart`)
1. [`chat_message.dart`](../../gage-app/lib/features/chat/domain/chat_message.dart): Model `ChatMessage` (`text`, `image`, `product`, `voice`, `senderRole`, `mediaUrl`, `timestamp`, `status`).
2. [`in_app_chat_provider.dart`](../../gage-app/lib/features/chat/providers/in_app_chat_provider.dart): `InAppChatProvider` dengan seed ter-guard `GageApiClient.useDevSeedData`, method `getMessages(orderId)`, `sendMessage`, `sendVoiceMessage`, `sendMediaMessage`, `sendProductMessage`.
3. [`in_app_chat_screen.dart`](../../gage-app/lib/features/chat/presentation/in_app_chat_screen.dart): Layar chat terpadu. Driver masuk dengan `currentRole: 'driver'`, menerima parameter `recipientAvatar` (`String?`), `recipientName`, `recipientRole` (`'customer' | 'merchant' | 'support' | 'admin'`), `recipientPhone`, `orderId`. Sudah memiliki quick replies khusus `currentRole == 'driver'`.
4. [`gage_chat_input_bar.dart`](../../gage-app/lib/features/chat/presentation/widgets/gage_chat_input_bar.dart): Input bar dengan voice note (`GageAudioService`), kamera, galeri, dan katalog produk.
5. [`gage_product_catalog_sheet.dart`](../../gage-app/lib/features/chat/presentation/widgets/gage_product_catalog_sheet.dart): Bottom sheet katalog item (aktif dari tombol berkas di `InAppChatScreen`).
6. [`chat_hub_screen.dart`](../../gage-app/lib/features/chat/presentation/chat_hub_screen.dart): Implementasi referensi sisi Customer untuk filter kapsul `BorderRadius.circular(999)`, merge order riil, nama bersih, dan normalisasi avatar.
7. [`gage_avatar.dart`](../../gage-app/lib/shared/widgets/gage_avatar.dart): Widget `GageAvatar` + `GageAvatar.resolveSourceUrl(...)` untuk merender foto Cloudflare `/api/chat/media/...` atau URL penuh, serta fallback inisial nama tanpa ikon chat statis.

### B. Checklist Eksekusi Wajib untuk Portal Driver
1. **Refactor [`driver_chat_list_screen.dart`](../../gage-app/lib/features/driver/presentation/driver_chat_list_screen.dart)**:
   - Guard daftar `_chatRooms` statis dengan `GageApiClient.useDevSeedData` dan integrasikan thread nyata dari trip/order aktif di `DriverProvider` serta pesan terbaru di `InAppChatProvider`.
   - Ganti `CircleAvatar(child: Icon(roleIcon))` (`L118-L122`) dengan `GageAvatar(imageUrl: avatarUrl, fallbackName: name, radius: 24)` yang mengambil `order.customerAvatar` (untuk pelanggan), `order.resolveMerchantAvatarAsset()` (untuk merchant), dan `'assets/images/gage_icon.png'` untuk entri dukungan.
   - Teruskan `recipientAvatar` saat memanggil `InAppChatScreen(...)` (`L102-L109`).
   - Pastikan label dukungan admin/bantuan bersih bernama `Pusat Bantuan` (tanpa embel-embel `AI` atau `24/7`) dan pertahankan badge peran yang jelas (`Pelanggan`, `Toko`).
2. **Upload Foto Profil Driver ke Cloudflare D1 (`avatar_url`)**:
   - Tambahkan pemilih foto profil di layar akun Driver (`DriverAccountScreen`), unggah ke R2 (`POST /api/chat/media/upload` atau endpoint upload R2), dan simpan hasilnya lewat `POST /api/user/profile` (`avatar_url`) agar `order.driverAvatar` otomatis tampil riil di Chat Customer & Merchant.
3. **Sync OrderModel dari `GET /api/driver/orders`**:
   - Koordinasi dengan Admin (lihat `HANDOFF_ADMIN.md` Bagian 19) agar query order driver turut mengembalikan `m.image_url as merchant_avatar`, `u.phone as customer_phone`, dan `u.avatar_url as customer_avatar`.
