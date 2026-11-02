# GAGE 4-Portal Boundary Map & Agent Directory

Dokumen ini adalah peta kepemilikan file resmi untuk 4 Sesi Chat Agen Spesialis.

| Portal | Sesi Chat Conversation ID | Entrypoint Flutter | Cakupan Direktori Kode |
| :--- | :--- | :--- | :--- |
| **Customer** | `ab7f6a31-982e-4360-a939-167a27a79a39` | `lib/main_customer.dart` / `main.dart` | `lib/features/home/`, `food/`, `checkout/`, `orders/`, `ride/`, `wallet/`, `affiliate/`, `profile/` |
| **Merchant** | `1c4b07ce-55ca-434a-821e-f12ef99bac9c` | `lib/main_merchant.dart` | `lib/features/merchant/`, `lib/providers/merchant_order_provider.dart` |
| **Driver** | `d98ee887-52c5-46f7-b28e-7288f9eb5385` | `lib/main_driver.dart` | `lib/features/driver/`, `lib/providers/driver_order_provider.dart`, `driver_wallet_provider.dart` |
| **Admin** | `09b47b70-e6b6-4961-8c34-8f1b47e6f7d6` | `lib/main_admin.dart` | `lib/features/admin/`, `lib/core/services/banner_manager_service.dart` |

---

## Aturan Kolaborasi Lintas Portal:
1. **Dilarang Mengedit File Milik Portal Lain**:
   - Agen Merchant dilarang menyentuh file di `lib/features/driver/` atau `lib/features/customer/`.
   - Agen Driver dilarang menyentuh file di `lib/features/merchant/`.
2. **Kontrak Data Bersama (Shared Contract)**:
   - Jika butuh menambahkan status baru pada `OrderModel` (misal `OUT_OF_STOCK_PARTIAL`), ajukan ke Main Session (Master Architect).
   - Seluruh portal membaca objek `OrderModel` yang sama (`lib/data/models/order_model.dart`).
3. **In-App Chat Bersama**:
   - Seluruh portal menggunakan `InAppChatProvider` (`lib/features/chat/providers/in_app_chat_provider.dart`) untuk komunikasi real-time antara Pembeli, Penjual, dan Kurir.
