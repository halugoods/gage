import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service perhitungan tarif & komisi GAGE (Dinamis, siap diatur via Portal Admin)
class GagePricingService {
  // Config Default Jarak Dasar (KM awal yang di-cover tarif dasar, dinamis via Admin)
  static double rideHematBaseKm = 2.0; // KM pertama opsi hemat (default 2.0 km)
  static double rideRegulerBaseKm = 2.0; // KM pertama motor standar (default 2.0 km)
  static double carBaseKm = 1.0; // KM pertama mobil (default 1.0 km)
  static double deliveryBaseKm = 2.0; // KM pertama belanja/paket (default 2.0 km)

  // Config Default Tarif (Dapat diperbarui dinamis dari Admin Portal via SharedPreferences / API)
  static int rideHematBase = 6000; // Flat KM pertama Rp 6.000
  static int rideHematPerKm = 3000; // Km berikutnya (> base KM)

  static int rideRegulerBase = 6000; // Flat KM pertama Rp 6.000
  static int rideRegulerPerKm = 4000; // Km berikutnya (> base KM)

  static int carBase = 8000; // Flat KM pertama Rp 8.000
  static int carPerKm = 5000; // Km berikutnya (> base KM)

  static int deliveryBase = 6000; // Flat KM pertama Rp 6.000 (Food, Shop, Tani, Send)
  static int deliveryPerKm = 3000; // Km berikutnya (> base KM)
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
  /// Non-Car: <= baseKm = flat base. > baseKm = base + ((km - baseKm) * perKm)
  /// Car: <= carBaseKm = flat base. > carBaseKm = base + ((km - carBaseKm) * perKm)
  static int calculateCustomerRideFare({
    required String serviceType, // 'hemat', 'reguler', 'car'
    required double distanceKm,
  }) {
    if (distanceKm <= 0) return 0;
    int rawFare;
    if (serviceType == 'car') {
      if (distanceKm <= carBaseKm) {
        rawFare = carBase;
      } else {
        rawFare = (carBase + ((distanceKm - carBaseKm) * carPerKm)).round();
      }
    } else if (serviceType == 'hemat') {
      if (distanceKm <= rideHematBaseKm) {
        rawFare = rideHematBase;
      } else {
        rawFare = (rideHematBase + ((distanceKm - rideHematBaseKm) * rideHematPerKm)).round();
      }
    } else {
      if (distanceKm <= rideRegulerBaseKm) {
        rawFare = rideRegulerBase;
      } else {
        rawFare = (rideRegulerBase + ((distanceKm - rideRegulerBaseKm) * rideRegulerPerKm)).round();
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
      if (distanceKm <= carBaseKm) {
        rawFare = carBase;
      } else {
        rawFare = (carBase + ((distanceKm - carBaseKm) * carPerKm)).round();
      }
    } else if (serviceType == 'hemat') {
      if (distanceKm <= rideHematBaseKm) {
        rawFare = rideHematBase;
      } else {
        rawFare = (rideHematBase + ((distanceKm - rideHematBaseKm) * rideHematPerKm)).round();
      }
    } else {
      if (distanceKm <= rideRegulerBaseKm) {
        rawFare = rideRegulerBase;
      } else {
        rawFare = (rideRegulerBase + ((distanceKm - rideRegulerBaseKm) * rideRegulerPerKm)).round();
      }
    }
    return (rawFare * driverCommissionRatio).round();
  }

  /// Hitung ongkir pengantaran belanja (Food, Shop, Tani, Send) untuk CUSTOMER
  /// Skema adil: Berbasis akumulasi jarak riil kurir (antar toko + ke customer),
  /// TANPA membebani pembeli dengan biaya mampir flat Rp 2.500.
  /// Jarak <= deliveryBaseKm flat deliveryBase. Jarak > deliveryBaseKm = deliveryBase + ((km - deliveryBaseKm) * perKm)
  /// Dibulatkan per Rp 500 ke atas
  static int calculateCustomerShippingFee({
    required double distanceKm,
    int merchantCount = 1,
  }) {
    // Akumulasi jarak tempuh riil antar-toko jika multi-merchant (+0.8 km per extra stop toko)
    final effectiveDistance = distanceKm + (merchantCount > 1 ? (merchantCount - 1) * 0.8 : 0.0);
    int rawShipping;
    if (effectiveDistance <= deliveryBaseKm) {
      rawShipping = deliveryBase;
    } else {
      rawShipping = (deliveryBase + ((effectiveDistance - deliveryBaseKm) * deliveryPerKm)).round();
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
    if (effectiveDistance <= deliveryBaseKm) {
      rawShipping = deliveryBase;
    } else {
      rawShipping = (deliveryBase + ((effectiveDistance - deliveryBaseKm) * deliveryPerKm)).round();
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
      rideHematBaseKm = prefs.getDouble('price_ride_hemat_base_km') ?? rideHematBaseKm;
      rideHematBase = prefs.getInt('price_ride_hemat_base') ?? rideHematBase;
      rideHematPerKm = prefs.getInt('price_ride_hemat_per_km') ?? rideHematPerKm;

      rideRegulerBaseKm = prefs.getDouble('price_ride_reg_base_km') ?? rideRegulerBaseKm;
      rideRegulerBase = prefs.getInt('price_ride_reg_base') ?? rideRegulerBase;
      rideRegulerPerKm = prefs.getInt('price_ride_reg_per_km') ?? rideRegulerPerKm;

      carBaseKm = prefs.getDouble('price_car_base_km') ?? carBaseKm;
      carBase = prefs.getInt('price_car_base') ?? carBase;
      carPerKm = prefs.getInt('price_car_per_km') ?? carPerKm;

      deliveryBaseKm = prefs.getDouble('price_delivery_base_km') ?? deliveryBaseKm;
      deliveryBase = prefs.getInt('price_delivery_base') ?? deliveryBase;
      deliveryPerKm = prefs.getInt('price_delivery_per_km') ?? deliveryPerKm;

      multiMerchantStopBonus = prefs.getInt('price_multi_merchant_bonus') ?? multiMerchantStopBonus;
      driverCommissionRatio = prefs.getDouble('price_driver_commission_ratio') ?? driverCommissionRatio;
      adminFeeCashlessPerMerchant = prefs.getInt('price_admin_cashless') ?? adminFeeCashlessPerMerchant;
      adminFeeCashCodBase = prefs.getInt('price_admin_cod_base') ?? adminFeeCashCodBase;
      adminFeeCashCodExtraPerMerchant = prefs.getInt('price_admin_cod_extra') ?? adminFeeCashCodExtraPerMerchant;
    } catch (e) {
      debugPrint('GagePricingService load error: $e');
    }
  }

  /// Simpan konfigurasi tarif baru dari Portal Admin
  static Future<void> saveAdminPricingConfig({
    double? newRideHematBaseKm,
    int? newRideHematBase,
    int? newRideHematPerKm,
    double? newRideRegulerBaseKm,
    int? newRideRegulerBase,
    int? newRideRegulerPerKm,
    double? newCarBaseKm,
    int? newCarBase,
    int? newCarPerKm,
    double? newDeliveryBaseKm,
    int? newDeliveryBase,
    int? newDeliveryPerKm,
    int? newMultiMerchantBonus,
    double? newDriverCommissionRatio,
    int? newAdminFeeCashless,
    int? newAdminFeeCodBase,
    int? newAdminFeeCodExtra,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (newRideHematBaseKm != null) {
        rideHematBaseKm = newRideHematBaseKm;
        await prefs.setDouble('price_ride_hemat_base_km', newRideHematBaseKm);
      }
      if (newRideHematBase != null) {
        rideHematBase = newRideHematBase;
        await prefs.setInt('price_ride_hemat_base', newRideHematBase);
      }
      if (newRideHematPerKm != null) {
        rideHematPerKm = newRideHematPerKm;
        await prefs.setInt('price_ride_hemat_per_km', newRideHematPerKm);
      }

      if (newRideRegulerBaseKm != null) {
        rideRegulerBaseKm = newRideRegulerBaseKm;
        await prefs.setDouble('price_ride_reg_base_km', newRideRegulerBaseKm);
      }
      if (newRideRegulerBase != null) {
        rideRegulerBase = newRideRegulerBase;
        await prefs.setInt('price_ride_reg_base', newRideRegulerBase);
      }
      if (newRideRegulerPerKm != null) {
        rideRegulerPerKm = newRideRegulerPerKm;
        await prefs.setInt('price_ride_reg_per_km', newRideRegulerPerKm);
      }

      if (newCarBaseKm != null) {
        carBaseKm = newCarBaseKm;
        await prefs.setDouble('price_car_base_km', newCarBaseKm);
      }
      if (newCarBase != null) {
        carBase = newCarBase;
        await prefs.setInt('price_car_base', newCarBase);
      }
      if (newCarPerKm != null) {
        carPerKm = newCarPerKm;
        await prefs.setInt('price_car_per_km', newCarPerKm);
      }

      if (newDeliveryBaseKm != null) {
        deliveryBaseKm = newDeliveryBaseKm;
        await prefs.setDouble('price_delivery_base_km', newDeliveryBaseKm);
      }
      if (newDeliveryBase != null) {
        deliveryBase = newDeliveryBase;
        await prefs.setInt('price_delivery_base', newDeliveryBase);
      }
      if (newDeliveryPerKm != null) {
        deliveryPerKm = newDeliveryPerKm;
        await prefs.setInt('price_delivery_per_km', newDeliveryPerKm);
      }

      if (newMultiMerchantBonus != null) {
        multiMerchantStopBonus = newMultiMerchantBonus;
        await prefs.setInt('price_multi_merchant_bonus', newMultiMerchantBonus);
      }
      if (newDriverCommissionRatio != null) {
        driverCommissionRatio = newDriverCommissionRatio;
        await prefs.setDouble('price_driver_commission_ratio', newDriverCommissionRatio);
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

  /// Reset semua konfigurasi tarif ke nilai default pabrik (untuk unit test)
  static void resetToDefault() {
    rideHematBaseKm = 2.0;
    rideRegulerBaseKm = 2.0;
    carBaseKm = 1.0;
    deliveryBaseKm = 2.0;
    rideHematBase = 6000;
    rideHematPerKm = 3000;
    rideRegulerBase = 6000;
    rideRegulerPerKm = 4000;
    carBase = 8000;
    carPerKm = 5000;
    deliveryBase = 6000;
    deliveryPerKm = 3000;
    multiMerchantStopBonus = 2500;
    adminFeeCashlessPerMerchant = 1000;
    adminFeeCashCodBase = 3000;
    adminFeeCashCodExtraPerMerchant = 1000;
    driverCommissionRatio = 0.80;
  }
}
