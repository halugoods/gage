# GAGE by Halu Goods Indonesia (Unit: GAGE Pracimantoro)

Aplikasi super on-demand hyperlocal (Ride, Car, Food, Shop, Send, Farm, Build, Cuan) terintegrasi untuk subdistrict Pracimantoro dengan arsitektur 4-Portal mandiri: **Customer**, **Merchant**, **Driver**, dan **Admin**.

---

## 🏛️ Arsitektur 4 Portal & Boundary File Ownership

Setiap portal memiliki wilayah kerja (folder) dan entrypoint tersendiri agar pengembangan terisolasi rapi, minim bentrok kode (*merge conflict*), dan dapat dikembangkan secara simultan oleh agent spesialis:

```
gage/gage-app/lib/
├── main.dart / main_customer.dart   --> [ PORTAL 1: CUSTOMER ]
├── main_merchant.dart               --> [ PORTAL 2: MERCHANT ]
├── main_driver.dart                 --> [ PORTAL 3: DRIVER ]
├── main_admin.dart                  --> [ PORTAL 4: ADMIN ]
├── core/ & data/                    --> [ SHARED KERNEL & KONTRAK DATA ]
└── shared/                          --> [ SHARED UI WIDGETS ]
```

---

### 1. 🛒 Portal Customer (`com.gagepracimantoro.customer`)
- **Entrypoint**: `lib/main.dart` & `lib/main_customer.dart`
- **Tanggung Jawab**: Pengalaman belanja pembeli, jelajah 8 katalog, keranjang single-merchant, hitung tarif OSRM (Decoy Effect: Hemat Rp 9rb vs Reguler Rp 12rb), checkout, dan pelacakan pesanan real-time.
- **File & Folder Milik Portal Customer**:
  - `lib/features/home/` (Beranda, `gage_home_header.dart`, `gage_service_grid.dart`, promo carousel).
  - `lib/features/food/` (`food_explore_screen.dart`, `resto_detail_screen.dart`, `shop_screen.dart`, `farm_screen.dart`, `build_screen.dart`, `item_variant_sheet.dart`).
  - `lib/features/checkout/` (`checkout_screen.dart`).
  - `lib/features/orders/` (`orders_screen.dart`, `order_detail_screen.dart`, `order_tracking_screen.dart`, `active_order_tracker_screen.dart`).
  - `lib/features/ride/` (`ride_booking_screen.dart`, `ride_checkout_screen.dart`, `send_booking_screen.dart`).
  - `lib/features/wallet/` (`gagepay_screen.dart`, `qris_pay_screen.dart`, `topup_qris_dialog.dart`).
  - `lib/features/affiliate/` (`affiliate_hub_screen.dart` - GAGE Cuan).
  - `lib/features/profile/` (`profile_screen.dart`, `edit_profile_screen.dart`).
  - `lib/providers/cart_provider.dart`, `wallet_provider.dart`, `auth_provider.dart`.

---

### 2. 🏪 Portal Merchant (`com.gagepracimantoro.merchant`)
- **Entrypoint**: `lib/main_merchant.dart`
- **Tanggung Jawab**: Workstation pengelola toko/warung, penerimaan pesanan masuk, alur penanganan menu habis (refund GagePay / selisih COD), chat pembeli, manajemen stok, dan kalkulator harga markup 10%.
- **File & Folder Milik Portal Merchant**:
  - `lib/features/merchant/presentation/` (`merchant_screen.dart`, `merchant_menu_screen.dart`, `merchant_finance_screen.dart`, `merchant_profile_screen.dart`, `merchant_chat_list_screen.dart`).
  - `lib/features/merchant/presentation/widgets/` (`merchant_bottom_nav_bar.dart`).
  - `lib/providers/merchant_order_provider.dart`.
- **SOP Siklus Pesanan**:
  - `Pesanan Baru`: Aksi `Terima Pesanan` (Hijau) & `Tolak Pesanan` (Merah, dengan modal alasan penalti performa).
  - `Sedang Disiapkan`: Aksi `Hubungi Pembeli` (Chat native), `Ubah Pesanan (Stok Habis)` (Ganti item/refund GagePay), dan `Pesanan Siap`.

---

### 3. 🛵 Portal Driver (`com.gagepracimantoro.driver`)
- **Entrypoint**: `lib/main_driver.dart`
- **Tanggung Jawab**: Workstation kurir motor/mobil, saklar siap narik (online/offline), radar tawaran pesanan masuk (80% ongkir murni OSRM), navigasi rute ambil di toko & antar ke pembeli, serta pencatatan plafon COD Rp 100.000.
- **File & Folder Milik Portal Driver**:
  - `lib/features/driver/presentation/` (`driver_screen.dart`, `active_trip_screen.dart`, `driver_earnings_screen.dart`, `driver_activity_screen.dart`, `driver_account_screen.dart`, `driver_chat_list_screen.dart`).
  - `lib/features/driver/presentation/widgets/` (`driver_bottom_nav_bar.dart`, `incoming_offer_sheet.dart`).
  - `lib/providers/driver_order_provider.dart`, `driver_wallet_provider.dart`.

---

### 4. ⚙️ Portal Admin (`com.gagepracimantoro.admin`)
- **Entrypoint**: `lib/main_admin.dart`
- **Tanggung Jawab**: Workstation kontrol operasional pemilik usaha (Halu Goods), live monitoring seluruh pesanan se-Pracimantoro, pengaturan tarif dinamis, rekap metrik harian (GMV & Take Rate), serta kurasi merchant.
- **File & Folder Milik Portal Admin**:
  - `lib/features/admin/presentation/` (`admin_screen.dart`, `admin_order_dispatch_screen.dart`, `admin_settings_screen.dart`, `admin_banner_screen.dart`, `admin_curation_screen.dart`).
  - `lib/features/admin/presentation/widgets/` (`admin_bottom_nav_bar.dart`, `tariff_edit_bottom_sheet.dart`, `in_place_banner_editor_sheet.dart`).

---

### 🔒 Shared Kernel & Kontrak Data (Shared Across All 4 Portals)
File-file berikut adalah jembatan penghubung antar-portal. Perubahan pada file ini wajib dikoordinasikan dengan Master Architect:
- `lib/data/models/order_model.dart` (Kontrak status, item, pembayaran, dan bagi hasil pesanan).
- `lib/data/models/cart_item_model.dart` & `user_model.dart`.
- `lib/core/services/gage_pricing_service.dart` (Mesin hitung tarif Decoy Effect, pembulatan Rp 500, dan bagi hasil 80% driver).
- `lib/core/services/multi_merchant_cart_service.dart` (Aturan 1 pesanan = 1 toko).
- `lib/features/chat/` (`in_app_chat_provider.dart`, `in_app_chat_screen.dart`).
- `lib/core/theme/gage_theme.dart` & `shared/widgets/`.

---

## 🚀 Perintah Build & Run per Portal

```bash
# Jalankan Portal Customer
flutter run -t lib/main_customer.dart

# Jalankan Portal Merchant
flutter run -t lib/main_merchant.dart

# Jalankan Portal Driver
flutter run -t lib/main_driver.dart

# Jalankan Portal Admin
flutter run -t lib/main_admin.dart
```

---

## 📈 Unit Economics & Model Finansial
Dokumentasi lengkap simulasi bisnis 3 bulan, rumus markup merchant $\text{CEIL}(\frac{\text{Harga Asli}}{0.90} \div 500) \times 500$, dan skema Flip withdrawal fee Rp 500 tersimpan di [gage_business_master_sheet_and_playbook.md](file:///C:/Users/ertyui/.gemini/antigravity/brain/99c7cebc-5112-4ea1-9e4d-3d58beb03511/gage_business_master_sheet_and_playbook.md).
