import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service perhitungan tarif & komisi GAGE (Dinamis, siap diatur via Portal Admin)
class GagePricingService {
  // Config Default (Dapat diperbarui dinamis dari Admin Portal via SharedPreferences / API)
  static int rideHematBase = 6000; // Flat 1-2 km pertama Rp 6.000
  static int rideHematPerKm = 3000; // Km berikutnya (>2 km)

  static int rideRegulerBase = 6000; // Flat 1-2 km pertama Rp 6.000
  static int rideRegulerPerKm = 4000; // Km berikutnya (>2 km)

  static int carBase = 8000; // Flat 1 km pertama Rp 8.000
  static int carPerKm = 5000; // Km ke-2 dan seterusnya (>1 km)

  static int deliveryBase = 6000; // Flat 1-2 km pertama Rp 6.000 (Food, Shop, Tani, Send)
  static int deliveryPerKm = 3000; // Km berikutnya (>2 km)
  static int multiMerchantStopBonus = 2500; // Komisi tambahan driver per merchant ekstra

  // Biaya Admin Toko (Dapat disesuaikan dinamis via Portal Admin)
  static int adminFeeCashlessPerMerchant = 1000;
  static int adminFeeCashCodBase = 3000;
  static int adminFeeCashCodExtraPerMerchant = 1000;

  static double driverCommissionRatio = 0.80; // 80% hak driver, 20% hak GAGE

  /// Pembulatan tarif customer ke kelipatan Rp 500 perak ke atas
  /// Contoh: 12.100 -> 12.500 | 12.700 -> 13.000 | 12.000 -> 12.000
  static int roundUpTo500(int amount) {
    if (amount <= 0) return 0;
    final remainder = amount % 500;
    if (remainder == 0) return amount;
    return amount + (500 - remainder);
  }

  /// Hitung tarif GAGE Ride / Car untuk CUSTOMER (Dibulatkan per 500 perak)
  /// Non-Car: <= 2 km = Rp 6.000 flat. > 2 km = Rp 6.000 + ((km - 2) * perKm)
  /// Car: <= 1 km = Rp 8.000 flat. > 1 km = Rp 8.000 + ((km - 1) * perKm)
  static int calculateCustomerRideFare({
    required String serviceType, // 'hemat', 'reguler', 'car'
    required double distanceKm,
  }) {
    if (distanceKm <= 0) return 0;
    int rawFare;
    if (serviceType == 'car') {
      if (distanceKm <= 1.0) {
        rawFare = carBase;
      } else {
        rawFare = (carBase + ((distanceKm - 1.0) * carPerKm)).round();
      }
    } else if (serviceType == 'hemat') {
      if (distanceKm <= 2.0) {
        rawFare = rideHematBase;
      } else {
        rawFare = (rideHematBase + ((distanceKm - 2.0) * rideHematPerKm)).round();
      }
    } else {
      if (distanceKm <= 2.0) {
        rawFare = rideRegulerBase;
      } else {
        rawFare = (rideRegulerBase + ((distanceKm - 2.0) * rideRegulerPerKm)).round();
      }
    }
    return roundUpTo500(rawFare);
  }

  /// Hitung komisi riil DRIVER (Exact aktual berdasarkan jarak riil, tanpa mark up pembulatan)
  static int calculateDriverRideCommission({
    required String serviceType,
    required double distanceKm,
  }) {
    if (distanceKm <= 0) return 0;
    int rawFare;
    if (serviceType == 'car') {
      if (distanceKm <= 1.0) {
        rawFare = carBase;
      } else {
        rawFare = (carBase + ((distanceKm - 1.0) * carPerKm)).round();
      }
    } else if (serviceType == 'hemat') {
      if (distanceKm <= 2.0) {
        rawFare = rideHematBase;
      } else {
        rawFare = (rideHematBase + ((distanceKm - 2.0) * rideHematPerKm)).round();
      }
    } else {
      if (distanceKm <= 2.0) {
        rawFare = rideRegulerBase;
      } else {
        rawFare = (rideRegulerBase + ((distanceKm - 2.0) * rideRegulerPerKm)).round();
      }
    }
    return (rawFare * driverCommissionRatio).round();
  }

  /// Hitung ongkir pengantaran belanja (Food, Shop, Tani, Send) untuk CUSTOMER
  /// Skema adil: Berbasis akumulasi jarak riil kurir (antar toko + ke customer),
  /// TANPA membebani pembeli dengan biaya mampir flat Rp 2.500.
  /// Jarak <= 2 km flat Rp 6.000. Jarak > 2 km = Rp 6.000 + ((km - 2) * Rp 3.000)
  /// Dibulatkan per Rp 500
  static int calculateCustomerShippingFee({
    required double distanceKm,
    int merchantCount = 1,
  }) {
    // Akumulasi jarak tempuh riil antar-toko jika multi-merchant (+0.8 km per extra stop toko)
    final effectiveDistance = distanceKm + (merchantCount > 1 ? (merchantCount - 1) * 0.8 : 0.0);
    int rawShipping;
    if (effectiveDistance <= 2.0) {
      rawShipping = deliveryBase;
    } else {
      rawShipping = (deliveryBase + ((effectiveDistance - 2.0) * deliveryPerKm)).round();
    }
    return roundUpTo500(rawShipping);
  }

  /// Hitung komisi driver untuk pengantaran belanja berbasis jarak rute riil (80% bagi hasil)
  static int calculateDriverShippingCommission({
    required double distanceKm,
    int merchantCount = 1,
  }) {
    final effectiveDistance = distanceKm + (merchantCount > 1 ? (merchantCount - 1) * 0.8 : 0.0);
    int rawShipping;
    if (effectiveDistance <= 2.0) {
      rawShipping = deliveryBase;
    } else {
      rawShipping = (deliveryBase + ((effectiveDistance - 2.0) * deliveryPerKm)).round();
    }
    return (rawShipping * driverCommissionRatio).round();
  }

  /// Biaya Admin per Merchant yang adil:
  /// - Cashless (GAGEPay / QRIS): Rp 1.000 per merchant (1 toko = 1rb, 2 toko = 2rb, 3 toko = 3rb)
  /// - Cash (COD): Base Rp 3.000, tiap merchant tambahan + Rp 1.000 (1 toko = 3rb, 2 toko = 4rb, 3 toko = 5rb)
  static int calculateAdminFee({
    required String paymentMethod,
    required int merchantCount,
  }) {
    final count = merchantCount < 1 ? 1 : merchantCount;
    final isCash = paymentMethod.toUpperCase() == 'CASH_COD' || paymentMethod.toLowerCase() == 'cash';
    if (isCash) {
      return adminFeeCashCodBase + ((count - 1) * adminFeeCashCodExtraPerMerchant);
    } else {
      return count * adminFeeCashlessPerMerchant;
    }
  }

  /// Muat konfigurasi dinamis yang tersimpan dari Admin Portal
  static Future<void> loadAdminPricingConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      rideHematBase = prefs.getInt('price_ride_hemat_base') ?? rideHematBase;
      rideHematPerKm = prefs.getInt('price_ride_hemat_per_km') ?? rideHematPerKm;
      rideRegulerBase = prefs.getInt('price_ride_reg_base') ?? rideRegulerBase;
      rideRegulerPerKm = prefs.getInt('price_ride_reg_per_km') ?? rideRegulerPerKm;
      carBase = prefs.getInt('price_car_base') ?? carBase;
      carPerKm = prefs.getInt('price_car_per_km') ?? carPerKm;
      deliveryBase = prefs.getInt('price_delivery_base') ?? deliveryBase;
      deliveryPerKm = prefs.getInt('price_delivery_per_km') ?? deliveryPerKm;
      adminFeeCashlessPerMerchant = prefs.getInt('price_admin_cashless') ?? adminFeeCashlessPerMerchant;
      adminFeeCashCodBase = prefs.getInt('price_admin_cod_base') ?? adminFeeCashCodBase;
      adminFeeCashCodExtraPerMerchant = prefs.getInt('price_admin_cod_extra') ?? adminFeeCashCodExtraPerMerchant;
    } catch (e) {
      debugPrint('GagePricingService load error: $e');
    }
  }

  /// Simpan konfigurasi tarif baru dari Portal Admin
  static Future<void> saveAdminPricingConfig({
    int? newRideHematBase,
    int? newRideHematPerKm,
    int? newRideRegulerBase,
    int? newRideRegulerPerKm,
    int? newCarBase,
    int? newCarPerKm,
    int? newDeliveryBase,
    int? newDeliveryPerKm,
    int? newAdminFeeCashless,
    int? newAdminFeeCodBase,
    int? newAdminFeeCodExtra,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newRideHematBase != null) {
        rideHematBase = newRideHematBase;
        await prefs.setInt('price_ride_hemat_base', newRideHematBase);
      }
      if (newRideHematPerKm != null) {
        rideHematPerKm = newRideHematPerKm;
        await prefs.setInt('price_ride_hemat_per_km', newRideHematPerKm);
      }
      if (newRideRegulerBase != null) {
        rideRegulerBase = newRideRegulerBase;
        await prefs.setInt('price_ride_reg_base', newRideRegulerBase);
      }
      if (newRideRegulerPerKm != null) {
        rideRegulerPerKm = newRideRegulerPerKm;
        await prefs.setInt('price_ride_reg_per_km', newRideRegulerPerKm);
      }
      if (newCarBase != null) {
        carBase = newCarBase;
        await prefs.setInt('price_car_base', newCarBase);
      }
      if (newCarPerKm != null) {
        carPerKm = newCarPerKm;
        await prefs.setInt('price_car_per_km', newCarPerKm);
      }
      if (newDeliveryBase != null) {
        deliveryBase = newDeliveryBase;
        await prefs.setInt('price_delivery_base', newDeliveryBase);
      }
      if (newDeliveryPerKm != null) {
        deliveryPerKm = newDeliveryPerKm;
        await prefs.setInt('price_delivery_per_km', newDeliveryPerKm);
      }
      if (newAdminFeeCashless != null) {
        adminFeeCashlessPerMerchant = newAdminFeeCashless;
        await prefs.setInt('price_admin_cashless', newAdminFeeCashless);
      }
      if (newAdminFeeCodBase != null) {
        adminFeeCashCodBase = newAdminFeeCodBase;
        await prefs.setInt('price_admin_cod_base', newAdminFeeCodBase);
      }
      if (newAdminFeeCodExtra != null) {
        adminFeeCashCodExtraPerMerchant = newAdminFeeCodExtra;
        await prefs.setInt('price_admin_cod_extra', newAdminFeeCodExtra);
      }
    } catch (_) {}
  }
}
