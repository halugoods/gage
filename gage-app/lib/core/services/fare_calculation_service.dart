import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'gage_pricing_service.dart';

/// Hasil perhitungan kalkulasi tarif, pembulatan transparan, komisi driver, dan bagi hasil platform
class FareCalculationResult {
  final double distanceKm;
  final int merchantCount;
  final bool isCashCod;
  final double realDeliveryFee; // Jarak * rate aktual
  final int roundedDeliveryFee; // Dibulatkan ke atas per Rp 500
  final int driverCommission;  // Komisi aktual driver eksak tanpa pembulatan
  final int platformShare;     // Sisa pembulatan + porsi gage
  final int adminFee;          // Biaya admin merchant
  final int totalFare;         // roundedDeliveryFee + adminFee

  const FareCalculationResult({
    required this.distanceKm,
    required this.merchantCount,
    required this.isCashCod,
    required this.realDeliveryFee,
    required this.roundedDeliveryFee,
    required this.driverCommission,
    required this.platformShare,
    required this.adminFee,
    required this.totalFare,
  });

  /// Sisa pembulatan ke atas kelipatan Rp 500 (Alokasi subsidi ongkir & voucher bersama)
  int get roundingSurplus {
    final diff = roundedDeliveryFee - realDeliveryFee.round();
    return diff > 0 ? diff : 0;
  }

  /// Porsi pokok platform sebelum ditambah sisa pembulatan
  int get platformBaseShare {
    final base = platformShare - roundingSurplus;
    return base > 0 ? base : 0;
  }

  /// Format Rupiah Helpers
  String get formattedRealDeliveryFee => FareCalculationService.formatRupiah(realDeliveryFee.round());
  String get formattedRoundedDeliveryFee => FareCalculationService.formatRupiah(roundedDeliveryFee);
  String get formattedDriverCommission => FareCalculationService.formatRupiah(driverCommission);
  String get formattedPlatformShare => FareCalculationService.formatRupiah(platformShare);
  String get formattedAdminFee => FareCalculationService.formatRupiah(adminFee);
  String get formattedTotalFare => FareCalculationService.formatRupiah(totalFare);
  String get formattedRoundingSurplus => FareCalculationService.formatRupiah(roundingSurplus);

  Map<String, dynamic> toMap() => {
    'distanceKm': distanceKm,
    'merchantCount': merchantCount,
    'isCashCod': isCashCod,
    'realDeliveryFee': realDeliveryFee,
    'roundedDeliveryFee': roundedDeliveryFee,
    'driverCommission': driverCommission,
    'platformShare': platformShare,
    'adminFee': adminFee,
    'totalFare': totalFare,
    'roundingSurplus': roundingSurplus,
  };

  @override
  String toString() {
    return 'FareCalculationResult(dist: ${distanceKm.toStringAsFixed(2)}km, '
        'real: Rp ${realDeliveryFee.round()}, rounded: Rp $roundedDeliveryFee, '
        'driver: Rp $driverCommission, platform: Rp $platformShare, '
        'admin: Rp $adminFee, total: Rp $totalFare)';
  }
}

/// Service perhitungan tarif & Pricing Engine untuk GAGE Pracimantoro
class FareCalculationService {
  /// Rate standar per kilometer untuk pengantaran belanja (Rp 3.000 / km)
  static const double defaultRatePerKm = 3000.0;

  /// Rasio default bagi hasil driver jika menggunakan skema bagi hasil proporsional (80% Driver, 20% GAGE)
  static const double defaultDriverCommissionRatio = 0.80;

  /// Pembulatan kelipatan (Rp 500)
  static const int roundingUnit = 500;

  /// Aturan pembulatan customer:
  /// `int roundedDeliveryFee = (realDeliveryFee / 500).ceil() * 500;`
  /// Misal:
  /// - Rp 12.100 -> Rp 12.500
  /// - Rp 12.700 -> Rp 13.000
  /// - Rp 12.000 -> Rp 12.000
  static int roundUpTo500(num amount) {
    if (amount <= 0) return 0;
    return (amount / roundingUnit.toDouble()).ceil() * roundingUnit;
  }

  // --- KONFIGURASI BIAYA ADMIN DINAMIS ---
  static const int defaultAdminFeeCashless = 1000;
  static const int defaultAdminFeeCodBase = 3000;
  static const int defaultAdminFeeCodExtra = 1000;

  /// Biaya Admin Cashless per merchant (default: Rp 1.000)
  static int adminFeeCashless = defaultAdminFeeCashless;

  /// Biaya Admin Cash COD untuk merchant pertama (default: Rp 3.000)
  static int adminFeeCodBase = defaultAdminFeeCodBase;

  /// Biaya Admin Cash COD per merchant tambahan berikutnya (default: Rp 1.000)
  static int adminFeeCodExtra = defaultAdminFeeCodExtra;

  /// Muat konfigurasi biaya admin yang tersimpan dari SharedPreferences
  static Future<void> loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      adminFeeCashless = prefs.getInt('price_admin_cashless') ??
          prefs.getInt('fare_admin_fee_cashless') ??
          defaultAdminFeeCashless;
      adminFeeCodBase = prefs.getInt('price_admin_cod_base') ??
          prefs.getInt('fare_admin_fee_cod_base') ??
          defaultAdminFeeCodBase;
      adminFeeCodExtra = prefs.getInt('price_admin_cod_extra') ??
          prefs.getInt('fare_admin_fee_cod_extra') ??
          defaultAdminFeeCodExtra;

      // Sinkronisasi dengan GagePricingService
      GagePricingService.adminFeeCashlessPerMerchant = adminFeeCashless;
      GagePricingService.adminFeeCashCodBase = adminFeeCodBase;
      GagePricingService.adminFeeCashCodExtraPerMerchant = adminFeeCodExtra;
    } catch (e) {
      debugPrint('FareCalculationService.loadConfig error: $e');
    }
  }

  /// Perbarui konfigurasi biaya admin dan persist ke SharedPreferences
  static Future<void> updateConfig({
    int? cashless,
    int? codBase,
    int? codExtra,
  }) async {
    if (cashless != null) adminFeeCashless = cashless;
    if (codBase != null) adminFeeCodBase = codBase;
    if (codExtra != null) adminFeeCodExtra = codExtra;

    // Sinkronisasi memori GagePricingService
    if (cashless != null) GagePricingService.adminFeeCashlessPerMerchant = cashless;
    if (codBase != null) GagePricingService.adminFeeCashCodBase = codBase;
    if (codExtra != null) GagePricingService.adminFeeCashCodExtraPerMerchant = codExtra;

    try {
      final prefs = await SharedPreferences.getInstance();
      if (cashless != null) {
        await prefs.setInt('price_admin_cashless', cashless);
        await prefs.setInt('fare_admin_fee_cashless', cashless);
      }
      if (codBase != null) {
        await prefs.setInt('price_admin_cod_base', codBase);
        await prefs.setInt('fare_admin_fee_cod_base', codBase);
      }
      if (codExtra != null) {
        await prefs.setInt('price_admin_cod_extra', codExtra);
        await prefs.setInt('fare_admin_fee_cod_extra', codExtra);
      }
    } catch (e) {
      debugPrint('FareCalculationService.updateConfig error: $e');
    }
  }

  /// Reset nilai ke default (berguna untuk testing unit test)
  static void resetToDefault() {
    adminFeeCashless = defaultAdminFeeCashless;
    adminFeeCodBase = defaultAdminFeeCodBase;
    adminFeeCodExtra = defaultAdminFeeCodExtra;
    GagePricingService.adminFeeCashlessPerMerchant = defaultAdminFeeCashless;
    GagePricingService.adminFeeCashCodBase = defaultAdminFeeCodBase;
    GagePricingService.adminFeeCashCodExtraPerMerchant = defaultAdminFeeCodExtra;
  }

  /// Aturan Biaya Admin Merchant Dinamis:
  /// - Cashless (GAGEPay / QRIS): [adminFeeCashless] per merchant (`merchantCount * adminFeeCashless`).
  /// - Cash COD: Base [adminFeeCodBase] untuk merchant pertama, +[adminFeeCodExtra] untuk setiap merchant berikutnya (`adminFeeCodBase + (merchantCount - 1) * adminFeeCodExtra`).
  static int calculateAdminFeeDynamic({
    required int merchantCount,
    required bool isCashCod,
  }) {
    final count = merchantCount < 1 ? 1 : merchantCount;
    if (isCashCod) {
      return adminFeeCodBase + ((count - 1) * adminFeeCodExtra);
    } else {
      return count * adminFeeCashless;
    }
  }

  /// Aturan Biaya Admin Merchant (mendelegasikan ke [calculateAdminFeeDynamic] untuk nilai dinamis):
  static int calculateAdminFee({
    required int merchantCount,
    required bool isCashCod,
  }) {
    return calculateAdminFeeDynamic(
      merchantCount: merchantCount,
      isCashCod: isCashCod,
    );
  }

  /// Helper penentu biaya admin berdasarkan string nama metode pembayaran
  static int calculateAdminFeeFromMethod({
    required String paymentMethod,
    required int merchantCount,
  }) {
    final cleanMethod = paymentMethod.trim().toUpperCase();
    final isCash = cleanMethod == 'CASH_COD' || cleanMethod == 'COD' || cleanMethod == 'CASH';
    return calculateAdminFeeDynamic(merchantCount: merchantCount, isCashCod: isCash);
  }

  /// Helper pemformatan mata uang Rupiah
  /// Contoh: 12500 -> "Rp 12.500"
  static String formatRupiah(int amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount).trim();
  }

  /// Fungsi utama perhitungan kalkulasi tarif lengkap:
  /// - [distanceKm]: Jarak tempuh pengantaran dalam kilometer
  /// - [merchantCount]: Jumlah merchant / toko yang dikunjungi (default 1)
  /// - [isCashCod]: True jika pembayaran tunai di tempat (COD)
  /// - [ratePerKm]: Tarif per km aktual (default Rp 2.500)
  /// - [baseDeliveryFee]: Tarif dasar minimum pengantaran jika berlaku (opsional)
  /// - [customRealDeliveryFee]: Override langsung nilai ongkir riil jika telah dihitung sebelumnya
  /// - [customDriverCommission]: Override komisi driver eksak jika telah ditentukan
  /// - [driverCommissionRatio]: Rasio porsi driver jika menggunakan sistem persentase bagi hasil (default 0.80)
  static FareCalculationResult calculate({
    required double distanceKm,
    int merchantCount = 1,
    bool isCashCod = false,
    double? ratePerKm,
    double? baseDeliveryFee,
    double? customRealDeliveryFee,
    int? customDriverCommission,
    double? driverCommissionRatio,
  }) {
    final count = merchantCount < 1 ? 1 : merchantCount;
    final rate = ratePerKm ?? defaultRatePerKm;

    // 1. Jarak * rate aktual (+ base delivery fee jika ditentukan)
    final double realDeliveryFee;
    if (customRealDeliveryFee != null) {
      realDeliveryFee = customRealDeliveryFee;
    } else if (baseDeliveryFee != null && baseDeliveryFee > 0) {
      realDeliveryFee = baseDeliveryFee + (distanceKm * rate);
    } else {
      realDeliveryFee = distanceKm * rate;
    }

    // 2. Pembulatan customer: kelipatan Rp 500 ke atas
    final int roundedDeliveryFee = roundUpTo500(realDeliveryFee);

    // 3. Komisi aktual driver: tetap eksak berdasarkan kilometer riil tanpa pembulatan (misal Rp 10.250)
    final int driverCommission;
    if (customDriverCommission != null) {
      driverCommission = customDriverCommission;
    } else if (driverCommissionRatio != null) {
      driverCommission = (realDeliveryFee * driverCommissionRatio).round();
    } else if (baseDeliveryFee != null && baseDeliveryFee > 0) {
      // Jika menggunakan base fee, driver mendapatkan porsi default 80% dari tarif aktual
      driverCommission = (realDeliveryFee * defaultDriverCommissionRatio).round();
    } else {
      // Eksak jarak * rate riil tanpa pembulatan
      driverCommission = (distanceKm * rate).round();
    }

    // 4. Platform share: Sisa pembulatan + porsi gage
    final int rawPlatformShare = roundedDeliveryFee - driverCommission;
    final int platformShare = rawPlatformShare < 0 ? 0 : rawPlatformShare;

    // 5. Biaya admin merchant (menggunakan nilai dinamis)
    final int adminFee = calculateAdminFeeDynamic(
      merchantCount: count,
      isCashCod: isCashCod,
    );

    // 6. Total tarif = roundedDeliveryFee + adminFee
    final int totalFare = roundedDeliveryFee + adminFee;

    return FareCalculationResult(
      distanceKm: distanceKm,
      merchantCount: count,
      isCashCod: isCashCod,
      realDeliveryFee: realDeliveryFee,
      roundedDeliveryFee: roundedDeliveryFee,
      driverCommission: driverCommission,
      platformShare: platformShare,
      adminFee: adminFee,
      totalFare: totalFare,
    );
  }
}
