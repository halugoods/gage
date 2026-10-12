import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';

void main() {
  group('FareCalculationService Tests', () {
    test('Pembulatan ke atas per Rp 500 (Akad Thoyib)', () {
      // Rule: (realDeliveryFee / 500).ceil() * 500
      expect(FareCalculationService.roundUpTo500(12100), 12500);
      expect(FareCalculationService.roundUpTo500(12700), 13000);
      expect(FareCalculationService.roundUpTo500(12000), 12000);
      expect(FareCalculationService.roundUpTo500(12500), 12500);
      expect(FareCalculationService.roundUpTo500(10250), 10500);
      expect(FareCalculationService.roundUpTo500(100), 500);
      expect(FareCalculationService.roundUpTo500(0), 0);
      expect(FareCalculationService.roundUpTo500(-500), 0);
    });

    test('Perhitungan Komisi Driver Eksak Jarak Riil Tanpa Pembulatan', () {
      // Contoh: Jarak 4.1 km * Rp 2.500/km = Rp 10.250
      final result = FareCalculationService.calculate(
        distanceKm: 4.1,
        merchantCount: 1,
        isCashCod: false,
      );

      expect(result.distanceKm, 4.1);
      expect(result.realDeliveryFee, 10250.0);
      expect(result.roundedDeliveryFee, 10500);
      expect(result.driverCommission, 10250); // Eksak tanpa pembulatan
      expect(result.platformShare, 250);     // 10.500 - 10.250 = 250 (sisa pembulatan ke atas)
      expect(result.roundingSurplus, 250);
      expect(result.adminFee, 1000);          // Cashless 1 merchant = Rp 1.000
      expect(result.totalFare, 11500);        // 10.500 + 1.000 = 11.500
    });

    test('Aturan Biaya Admin Merchant Cashless (GAGEPay/QRIS)', () {
      // 1000 per merchant
      expect(FareCalculationService.calculateAdminFee(merchantCount: 1, isCashCod: false), 1000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 2, isCashCod: false), 2000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 3, isCashCod: false), 3000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 0, isCashCod: false), 1000);
    });

    test('Aturan Biaya Admin Merchant Cash COD', () {
      // 3.000 untuk merchant pertama, +1.000 tiap merchant berikutnya
      expect(FareCalculationService.calculateAdminFee(merchantCount: 1, isCashCod: true), 3000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 2, isCashCod: true), 4000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 3, isCashCod: true), 5000);
      expect(FareCalculationService.calculateAdminFee(merchantCount: 4, isCashCod: true), 6000);
    });

    test('Custom Real Delivery Fee dengan Kasus Rp 12.100 dan Rp 12.700', () {
      final res1 = FareCalculationService.calculate(
        distanceKm: 4.84,
        customRealDeliveryFee: 12100.0,
        customDriverCommission: 10250,
        merchantCount: 1,
        isCashCod: false,
      );

      expect(res1.realDeliveryFee, 12100.0);
      expect(res1.roundedDeliveryFee, 12500); // 12.100 -> 12.500
      expect(res1.driverCommission, 10250);
      expect(res1.platformShare, 2250);      // 12.500 - 10.250 = 2.250 (400 surplus + 1850 base gage)
      expect(res1.roundingSurplus, 400);     // 12.500 - 12.100 = 400
      expect(res1.platformBaseShare, 1850);
      expect(res1.adminFee, 1000);
      expect(res1.totalFare, 13500);

      final res2 = FareCalculationService.calculate(
        distanceKm: 5.08,
        customRealDeliveryFee: 12700.0,
        merchantCount: 2,
        isCashCod: true,
      );

      expect(res2.realDeliveryFee, 12700.0);
      expect(res2.roundedDeliveryFee, 13000); // 12.700 -> 13.000
      expect(res2.adminFee, 4000);           // COD 2 merchant = 3.000 + 1.000 = 4.000
      expect(res2.totalFare, 17000);         // 13.000 + 4.000 = 17.000
    });

    test('Helper Format Rupiah formatRupiah', () {
      expect(FareCalculationService.formatRupiah(12500), contains('12.500'));
      expect(FareCalculationService.formatRupiah(1000), contains('1.000'));
      expect(FareCalculationService.formatRupiah(0), contains('0'));
    });

    test('Dinamis: updateConfig dan calculateAdminFeeDynamic', () async {
      SharedPreferences.setMockInitialValues({});
      FareCalculationService.resetToDefault();

      // Default
      expect(FareCalculationService.adminFeeCashless, 1000);
      expect(FareCalculationService.adminFeeCodBase, 3000);
      expect(FareCalculationService.adminFeeCodExtra, 1000);

      // Ubah dinamis: Cashless Rp 1.500, COD Base Rp 4.000, COD Extra Rp 2.000
      await FareCalculationService.updateConfig(
        cashless: 1500,
        codBase: 4000,
        codExtra: 2000,
      );

      expect(FareCalculationService.adminFeeCashless, 1500);
      expect(FareCalculationService.adminFeeCodBase, 4000);
      expect(FareCalculationService.adminFeeCodExtra, 2000);

      // Hitung dinamis Cashless
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 1, isCashCod: false), 1500);
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 2, isCashCod: false), 3000);

      // Hitung dinamis COD
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 1, isCashCod: true), 4000);
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 2, isCashCod: true), 6000);
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 3, isCashCod: true), 8000);

      // Verifikasi calculate(...) menggunakan nilai dinamis tersebut
      final resultDynamic = FareCalculationService.calculate(
        distanceKm: 2.0, // 2.0 * 2500 = 5000
        merchantCount: 2,
        isCashCod: true,
      );
      expect(resultDynamic.roundedDeliveryFee, 5000);
      expect(resultDynamic.adminFee, 6000); // 4000 + 2000
      expect(resultDynamic.totalFare, 11000); // 5000 + 6000

      // Reset
      FareCalculationService.resetToDefault();
    });

    test('Dinamis: loadConfig dari SharedPreferences tersimpan', () async {
      SharedPreferences.setMockInitialValues({
        'price_admin_cashless': 2000,
        'price_admin_cod_base': 5000,
        'price_admin_cod_extra': 1500,
      });

      await FareCalculationService.loadConfig();

      expect(FareCalculationService.adminFeeCashless, 2000);
      expect(FareCalculationService.adminFeeCodBase, 5000);
      expect(FareCalculationService.adminFeeCodExtra, 1500);

      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 2, isCashCod: false), 4000);
      expect(FareCalculationService.calculateAdminFeeDynamic(merchantCount: 2, isCashCod: true), 6500);

      // Reset
      FareCalculationService.resetToDefault();
    });
  });
}
