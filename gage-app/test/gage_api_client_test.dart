import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

void main() {
  group('GageApiClient Tiered Shipping & Offline Calculation Tests', () {
    test('Calculates shipping discount >= 80.000 (Rp 5.000 off)', () async {
      final res = await GageApiClient.calculateOrder(
        subtotal: 85000,
        distanceKm: 2.0,
        paymentMethod: 'GAGEPAY',
      );

      expect(res, isNotNull);
      expect(res!['items_subtotal'], 85000);
      expect(res['shipping_discount'], 5000);
      expect(res['admin_fee'], 1000);
      // Raw shipping for 2 km = 7000
      expect(res['raw_shipping_fee'], 7000);
      expect(res['final_shipping_fee'], 2000);
      expect(res['total_amount'], 85000 + 2000 + 1000);
    });

    test('Calculates shipping discount >= 50.000 (Rp 3.000 off)', () async {
      final res = await GageApiClient.calculateOrder(
        subtotal: 55000,
        distanceKm: 2.0,
        paymentMethod: 'GAGEPAY',
      );

      expect(res, isNotNull);
      expect(res!['shipping_discount'], 3000);
      expect(res['final_shipping_fee'], 4000);
    });

    test('Calculates shipping discount >= 25.000 (Rp 1.000 off)', () async {
      final res = await GageApiClient.calculateOrder(
        subtotal: 30000,
        distanceKm: 2.0,
        paymentMethod: 'GAGEPAY',
      );

      expect(res, isNotNull);
      expect(res!['shipping_discount'], 1000);
      expect(res['final_shipping_fee'], 6000);
    });

    test('Calculates COD payment method admin fee of Rp 3.000', () async {
      final res = await GageApiClient.calculateOrder(
        subtotal: 20000,
        distanceKm: 1.0,
        paymentMethod: 'CASH_COD',
      );

      expect(res, isNotNull);
      expect(res!['admin_fee'], 3000);
      expect(res['shipping_discount'], 0);
    });
  });
}
