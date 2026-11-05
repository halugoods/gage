import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service perhitungan tarif & komisi GAGE (Dinamis, siap diatur via Portal Admin)
class GagePricingService {
  // Config Default Jarak Dasar (KM awal yang di-cover tarif dasar, dinamis via Admin)
  static double rideHematBaseKm = 3.0; // KM pertama opsi hemat (0-3 km: Rp 9.000)
  static double rideRegulerBaseKm = 3.0; // KM pertama motor standar (0-3 km: Rp 12.000)
  static double carBaseKm = 1.0; // KM pertama mobil (default 1.0 km)
  static double deliveryBaseKm = 3.0; // KM pertama belanja/paket (default 3.0 km)

  // Config Default Tarif (Dapat diperbarui dinamis dari Admin Portal via SharedPreferences / API)
  static int rideHematBase = 9000; // Flat 0-3 km Rp 9.000
  static int rideHematPerKm = 3000; // km ke-4

  static int rideRegulerBase = 12000; // Flat 0-3 km Rp 12.000 (Decoy Prioritas)
  static int rideRegulerPerKm = 4000; // km ke-4

  static int carBase = 8000; // Flat KM pertama Rp 8.000
  static int carPerKm = 5000; // Km berikutnya (> base KM)

  static int deliveryBase = 9000; // Flat 0-3 km Rp 9.000
  static int deliveryPerKm = 3000; // km ke-4
  static int multiMerchantStopBonus = 2500; // Komisi tambahan driver per merchant ekstra

  // Biaya Layanan: Cashless Rp 1.000 | COD Rp 3.000
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

  /// Perhitungan Tarif Decoy Effect Bertingkat Eksak Sebelum Pembulatan:
  /// - Opsi Hemat (Tarif Dasar):
  ///   0-3 km: Rp 9.000
  ///   km ke-4: +Rp 3.000 / km
  ///   km ke-5: +Rp 2.500 / km
  ///   km ke-6+: +Rp 2.000 / km
  /// - Opsi Reguler (Decoy Prioritas):
  ///   0-3 km: Rp 12.000
  ///   km ke-4: +Rp 4.000 / km
  ///   km ke-5: +Rp 3.500 / km
  ///   km ke-6+: +Rp 3.000 / km
  static double calculateRawTieredFare({
    required double distanceKm,
    required bool isReguler,
  }) {
    if (distanceKm <= 0) return 0.0;

    final double baseFare = isReguler ? rideRegulerBase.toDouble() : rideHematBase.toDouble();
    final double baseKm = isReguler ? rideRegulerBaseKm : rideHematBaseKm;

    if (distanceKm <= baseKm) {
      return baseFare;
    }

    // km ke-4 (3.0 < km <= 4.0)
    final double km4Rate = isReguler ? 4000.0 : 3000.0;
    if (distanceKm <= 4.0) {
      return baseFare + ((distanceKm - baseKm) * km4Rate);
    }

    // km ke-5 (4.0 < km <= 5.0)
    final double km4Total = (4.0 - baseKm) * km4Rate;
    final double km5Rate = isReguler ? 3500.0 : 2500.0;
    if (distanceKm <= 5.0) {
      return baseFare + km4Total + ((distanceKm - 4.0) * km5Rate);
    }

    // km ke-6+ (> 5.0 km)
    final double km5Total = 1.0 * km5Rate;
    final double km6Rate = isReguler ? 3000.0 : 2000.0;
    return baseFare + km4Total + km5Total + ((distanceKm - 5.0) * km6Rate);
  }

  /// Hitung tarif Decoy Effect dengan pembulatan ke atas kelipatan Rp 500
  static int calculateTieredFare({
    required double distanceKm,
    required bool isReguler,
  }) {
    final raw = calculateRawTieredFare(
      distanceKm: distanceKm,
      isReguler: isReguler,
    );
    return roundUpTo500(raw.round());
  }

  /// Hitung tarif GAGE Ride / Car untuk CUSTOMER (Dibulatkan per 500 perak)
  static int calculateCustomerRideFare({
    required String serviceType, // 'hemat', 'reguler', 'car'
    required double distanceKm,
  }) {
    if (distanceKm <= 0) return 0;
    if (serviceType.toLowerCase() == 'car') {
      if (distanceKm <= carBaseKm) {
        return roundUpTo500(carBase);
      } else {
        final raw = carBase + ((distanceKm - carBaseKm) * carPerKm);
        return roundUpTo500(raw.round());
      }
    }
    final isReguler = serviceType.toLowerCase() != 'hemat';
    return calculateTieredFare(distanceKm: distanceKm, isReguler: isReguler);
  }

  /// Hitung komisi riil DRIVER (Exact aktual berdasarkan jarak riil, 80% bagi hasil)
  static int calculateDriverRideCommission({
    required String serviceType,
    required double distanceKm,
  }) {
    if (distanceKm <= 0) return 0;
    double rawFare;
    if (serviceType.toLowerCase() == 'car') {
      if (distanceKm <= carBaseKm) {
        rawFare = carBase.toDouble();
      } else {
        rawFare = carBase + ((distanceKm - carBaseKm) * carPerKm);
      }
    } else {
      final isReguler = serviceType.toLowerCase() != 'hemat';
      rawFare = calculateRawTieredFare(distanceKm: distanceKm, isReguler: isReguler);
    }
    return (rawFare * driverCommissionRatio).round();
  }

  /// Hitung ongkir pengantaran belanja (Food, Shop, Farm, Build, Send) untuk CUSTOMER
  /// Mendukung Opsi Hemat vs Opsi Reguler (Decoy Effect) & pembulatan Rp 500 ke atas
  static int calculateCustomerShippingFee({
    required double distanceKm,
    String deliveryOption = 'REGULER',
    int merchantCount = 1,
  }) {
    if (distanceKm <= 0) return 0;
    final isReguler = deliveryOption.toUpperCase() != 'HEMAT';
    return calculateTieredFare(distanceKm: distanceKm, isReguler: isReguler);
  }

  /// Hitung komisi driver untuk pengantaran belanja berbasis jarak rute riil (80% bagi hasil)
  static int calculateDriverShippingCommission({
    required double distanceKm,
    String deliveryOption = 'REGULER',
    int merchantCount = 1,
  }) {
    if (distanceKm <= 0) return 0;
    final isReguler = deliveryOption.toUpperCase() != 'HEMAT';
    final rawFare = calculateRawTieredFare(distanceKm: distanceKm, isReguler: isReguler);
    return (rawFare * driverCommissionRatio).round();
  }

  /// Biaya Layanan: Cashless Rp 1.000 | COD Rp 3.000
  static int calculateAdminFee({
    required String paymentMethod,
    int merchantCount = 1,
  }) {
    final clean = paymentMethod.trim().toUpperCase();
    final isCash = clean.contains('CASH') || clean.contains('COD');
    if (isCash) {
      return adminFeeCashCodBase; // Rp 3.000
    } else {
      return adminFeeCashlessPerMerchant; // Rp 1.000
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
    rideHematBaseKm = 3.0;
    rideRegulerBaseKm = 3.0;
    carBaseKm = 1.0;
    deliveryBaseKm = 3.0;
    rideHematBase = 9000;
    rideHematPerKm = 3000;
    rideRegulerBase = 12000;
    rideRegulerPerKm = 4000;
    carBase = 8000;
    carPerKm = 5000;
    deliveryBase = 9000;
    deliveryPerKm = 3000;
    multiMerchantStopBonus = 2500;
    adminFeeCashlessPerMerchant = 1000;
    adminFeeCashCodBase = 3000;
    adminFeeCashCodExtraPerMerchant = 1000;
    driverCommissionRatio = 0.80;
  }
}
