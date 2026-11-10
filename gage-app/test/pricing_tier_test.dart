import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GagePricingService.resetToDefault();
  });

  group('3-Tier Delivery Pricing Algorithm & Mutation Bug Immunity', () {
    test('Independent getters calculate correct 3-tier prices for short distance (1.0 km)', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Dekat', 1.0);

      // Prioritas is Reguler + 4000
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.prioritasShippingFee, equals(16000));
      expect(cart.hematShippingFee, equals(9000));
      // Distance < 2.5 km -> Hemat is NOT available
      expect(cart.isHematAvailable, isFalse);
    });

    test('Independent getters calculate correct 3-tier prices for long distance (3.0 km)', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Jauh', 3.0);

      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.prioritasShippingFee, equals(16000));
      expect(cart.hematShippingFee, equals(9000));
      // Distance >= 2.5 km -> Hemat is available
      expect(cart.isHematAvailable, isTrue);
    });

    test('Selecting HEMAT or PRIORITAS NEVER mutates the getters (Absolute Anomaly Prevention)', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Jauh', 3.0);

      // Initially selected delivery option is REGULER
      expect(cart.deliveryOption, equals('REGULER'));
      expect(cart.rawShippingFee, equals(12000));
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.prioritasShippingFee, equals(16000));

      // User selects HEMAT
      cart.setDeliveryOption('HEMAT');
      expect(cart.deliveryOption, equals('HEMAT'));
      expect(cart.rawShippingFee, equals(9000));

      // CRITICAL CHECK: Reguler and Prioritas getters MUST NOT mutate or drop!
      expect(cart.regulerShippingFee, equals(12000)); // NOT 9000!
      expect(cart.hematShippingFee, equals(9000));   // NOT 6000!
      expect(cart.prioritasShippingFee, equals(16000));

      // User selects PRIORITAS
      cart.setDeliveryOption('PRIORITAS');
      expect(cart.deliveryOption, equals('PRIORITAS'));
      expect(cart.rawShippingFee, equals(16000));

      // CRITICAL CHECK: Reguler and Hemat getters MUST NOT mutate!
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.prioritasShippingFee, equals(16000));
    });
  });
}
