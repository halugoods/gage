import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';

void main() {
  setUp(() {
    GagePricingService.resetToDefault();
  });

  group('GagePricingService Decoy Effect & Tiered Pricing Tests', () {
    test('Pembulatan ke atas kelipatan Rp 500 (roundUpTo500)', () {
      expect(GagePricingService.roundUpTo500(9000), equals(9000));
      expect(GagePricingService.roundUpTo500(9001), equals(9500));
      expect(GagePricingService.roundUpTo500(9250), equals(9500));
      expect(GagePricingService.roundUpTo500(9500), equals(9500));
      expect(GagePricingService.roundUpTo500(9501), equals(10000));
      expect(GagePricingService.roundUpTo500(12100), equals(12500));
      expect(GagePricingService.roundUpTo500(0), equals(0));
      expect(GagePricingService.roundUpTo500(-100), equals(0));
    });

    test('Opsi Hemat (Tarif Dasar) Tiered Calculations', () {
      // 0 - 3 km: Flat Rp 9.000
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 1.5, deliveryOption: 'hemat'),
        equals(9000),
      );
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 3.0, deliveryOption: 'hemat'),
        equals(9000),
      );

      // km ke-4 (+Rp 3.000 / km):
      // Jarak 3.5 km: 9.000 + 0.5 * 3.000 = 10.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 3.5, deliveryOption: 'hemat'),
        equals(10500),
      );
      // Jarak 4.0 km: 9.000 + 3.000 = 12.000
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 4.0, deliveryOption: 'hemat'),
        equals(12000),
      );

      // km ke-5 (+Rp 2.500 / km):
      // Jarak 5.0 km: 9.000 + 3.000 + 2.500 = 14.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 5.0, deliveryOption: 'hemat'),
        equals(14500),
      );

      // km ke-6+ (+Rp 2.000 / km):
      // Jarak 6.0 km: 14.500 + 1 * 2.000 = 16.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 6.0, deliveryOption: 'hemat'),
        equals(16500),
      );
      // Jarak 7.0 km: 16.500 + 2.000 = 18.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 7.0, deliveryOption: 'hemat'),
        equals(18500),
      );
    });

    test('Opsi Reguler (Decoy Prioritas) Tiered Calculations', () {
      // 0 - 3 km: Flat Rp 12.000
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 1.5, deliveryOption: 'reguler'),
        equals(12000),
      );
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 3.0, deliveryOption: 'reguler'),
        equals(12000),
      );

      // km ke-4 (+Rp 4.000 / km):
      // Jarak 3.5 km: 12.000 + 0.5 * 4.000 = 14.000
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 3.5, deliveryOption: 'reguler'),
        equals(14000),
      );
      // Jarak 4.0 km: 12.000 + 4.000 = 16.000
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 4.0, deliveryOption: 'reguler'),
        equals(16000),
      );

      // km ke-5 (+Rp 3.500 / km):
      // Jarak 5.0 km: 12.000 + 4.000 + 3.500 = 19.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 5.0, deliveryOption: 'reguler'),
        equals(19500),
      );

      // km ke-6+ (+Rp 3.000 / km):
      // Jarak 6.0 km: 19.500 + 1 * 3.000 = 22.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 6.0, deliveryOption: 'reguler'),
        equals(22500),
      );
      // Jarak 7.0 km: 22.500 + 3.000 = 25.500
      expect(
        GagePricingService.calculateCustomerShippingFee(distanceKm: 7.0, deliveryOption: 'reguler'),
        equals(25500),
      );
    });

    test('Biaya Layanan (Admin Fee) Cashless vs COD', () {
      expect(GagePricingService.calculateAdminFee(paymentMethod: 'GAGEPAY'), equals(1000));
      expect(GagePricingService.calculateAdminFee(paymentMethod: 'QRIS'), equals(1000));
      expect(GagePricingService.calculateAdminFee(paymentMethod: 'TRANSFER'), equals(1000));
      expect(GagePricingService.calculateAdminFee(paymentMethod: 'CASH'), equals(3000));
      expect(GagePricingService.calculateAdminFee(paymentMethod: 'COD'), equals(3000));
    });
  });
}
