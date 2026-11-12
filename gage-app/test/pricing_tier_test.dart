import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';

CartItemModel _makeItem(String id, int price, {int qty = 1}) => CartItemModel(
      menuId: id,
      merchantId: 'm-01',
      merchantName: 'Warung Uji',
      name: 'Item $id',
      price: price,
      quantity: qty,
      category: 'Makanan',
      serviceType: 'food',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    GagePricingService.resetToDefault();
  });

  group('3-Tier Delivery Pricing Algorithm & Mutation Bug Immunity', () {
    test('Opsi Hemat terkunci di bawah minimal belanja Rp 50.000 pada jarak mana pun', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Dekat', 1.0);
      cart.addItem(_makeItem('m-1', 25000, qty: 1));

      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.prioritasShippingFee, equals(16000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.isHematAvailable, isFalse);

      // Mencoba memilih HEMAT saat subtotal < Rp 50.000 otomatis jatuh ke REGULER
      cart.setDeliveryOption('HEMAT');
      expect(cart.deliveryOption, equals('REGULER'));
      expect(cart.rawShippingFee, equals(12000));
    });

    test('Opsi Hemat aktif saat subtotal >= Rp 50.000 dan otomatis kembali ke REGULER jika subtotal turun', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Jauh', 3.0);
      cart.addItem(_makeItem('m-1', 25000, qty: 2));

      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.prioritasShippingFee, equals(16000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.isHematAvailable, isTrue);

      cart.setDeliveryOption('HEMAT');
      expect(cart.deliveryOption, equals('HEMAT'));
      expect(cart.rawShippingFee, equals(9000));

      // Kurangi qty -> subtotal jadi Rp 25.000 (< Rp 50.000), HEMAT harus otomatis kembali ke REGULER
      cart.updateQuantity('m-1', -1);
      expect(cart.isHematAvailable, isFalse);
      expect(cart.deliveryOption, equals('REGULER'));
      expect(cart.rawShippingFee, equals(12000));
    });

    test('Selecting HEMAT or PRIORITAS NEVER mutates the getters (Absolute Anomaly Prevention)', () {
      final cart = CartProvider();
      cart.setDeliveryAddress('Pracimantoro Jauh', 3.0);
      cart.addItem(_makeItem('m-1', 50000, qty: 1));

      expect(cart.deliveryOption, equals('REGULER'));
      expect(cart.rawShippingFee, equals(12000));
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.prioritasShippingFee, equals(16000));

      cart.setDeliveryOption('HEMAT');
      expect(cart.deliveryOption, equals('HEMAT'));
      expect(cart.rawShippingFee, equals(9000));
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.prioritasShippingFee, equals(16000));

      cart.setDeliveryOption('PRIORITAS');
      expect(cart.deliveryOption, equals('PRIORITAS'));
      expect(cart.rawShippingFee, equals(16000));
      expect(cart.regulerShippingFee, equals(12000));
      expect(cart.hematShippingFee, equals(9000));
      expect(cart.prioritasShippingFee, equals(16000));
    });
  });
}
