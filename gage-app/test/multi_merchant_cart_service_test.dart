import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';

void main() {
  group('CartItem Model Tests', () {
    test('CartItem default menuOrigin is shop', () {
      final item = CartItem(
        id: 'p1',
        name: 'Semen Tiga Roda',
        price: 55000,
        storeId: 'store_1',
        storeName: 'Toko Bangunan Berkah',
      );

      expect(item.menuOrigin, equals('shop'));
      expect(item.quantity, equals(1));
      expect(item.totalPrice, equals(55000));
    });

    test('CartItem supports custom menuOrigin and copyWith', () {
      final foodItem = CartItem(
        id: 'f1',
        name: 'Ayam Geprek Sambal Bawang',
        price: 15000,
        quantity: 2,
        storeId: 'resto_1',
        storeName: 'Warung Bu Sri',
        menuOrigin: 'food',
        note: 'Pedas sedang',
      );

      expect(foodItem.menuOrigin, equals('food'));
      expect(foodItem.totalPrice, equals(30000));

      final updated = foodItem.copyWith(quantity: 3, menuOrigin: 'farm');
      expect(updated.quantity, equals(3));
      expect(updated.menuOrigin, equals('farm'));
      expect(updated.note, equals('Pedas sedang'));
    });

    test('CartItem toJson and fromJson serialization preserves menuOrigin', () {
      final original = CartItem(
        id: 't1',
        name: 'Pupuk Urea 5kg',
        price: 45000,
        quantity: 2,
        storeId: 'farm_1',
        storeName: 'Kios Tani Makmur',
        category: 'Pupuk',
        image: 'pupuk.png',
        note: 'Titip di teras',
        menuOrigin: 'farm',
      );

      final json = original.toJson();
      expect(json['menuOrigin'], equals('farm'));

      final restored = CartItem.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.price, equals(original.price));
      expect(restored.quantity, equals(original.quantity));
      expect(restored.storeId, equals(original.storeId));
      expect(restored.storeName, equals(original.storeName));
      expect(restored.menuOrigin, equals('farm'));
      expect(restored.note, equals('Titip di teras'));
    });
  });

  group('Single-Merchant Cart Service Tests', () {
    late MultiMerchantCartService cart;

    setUp(() {
      cart = MultiMerchantCartService();
      cart.clear();
    });

    test('Initial cart state is empty', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.totalItemsPrice, equals(0));
      expect(cart.merchantCount, equals(0));
      expect(cart.uniqueStoreIds, isEmpty);
      expect(cart.uniqueStoreNames, isEmpty);
      expect(cart.currentStoreName, isNull);
    });

    test('Add item from single store correctly calculates totals', () {
      final item = CartItem(
        id: 'p1',
        name: 'Beras 5kg',
        price: 70000,
        quantity: 2,
        storeId: 'store_1',
        storeName: 'Toko Berkah',
        category: 'Sembako',
        image: 'img1.png',
        menuOrigin: 'shop',
      );

      final added = cart.addItem(item);
      expect(added, isTrue);
      expect(cart.totalItemCount, equals(2));
      expect(cart.totalItemsPrice, equals(140000));
      expect(cart.merchantCount, equals(1));
      expect(cart.uniqueStoreIds, equals(['store_1']));
      expect(cart.uniqueStoreNames, equals(['Toko Berkah']));
      expect(cart.currentStoreName, equals('Toko Berkah'));
    });

    test('Adding multiple items from the same store aggregates quantities', () {
      cart.addItem(CartItem(
        id: 'p1',
        name: 'Minyak 2L',
        price: 35000,
        quantity: 1,
        storeId: 'store_1',
        storeName: 'Toko Berkah',
        category: 'Sembako',
        image: 'img.png',
        menuOrigin: 'shop',
      ));

      cart.addItem(CartItem(
        id: 'p1',
        name: 'Minyak 2L',
        price: 35000,
        quantity: 2,
        storeId: 'store_1',
        storeName: 'Toko Berkah',
        category: 'Sembako',
        image: 'img.png',
        menuOrigin: 'shop',
      ));

      expect(cart.totalItemCount, equals(3));
      expect(cart.totalItemsPrice, equals(105000));
      expect(cart.getItemQuantity('store_1', 'p1'), equals(3));
    });

    test('Enforces Single-Merchant locking (rejects 2nd store item)', () {
      // Add from Toko 1
      final added1 = cart.addItem(CartItem(
        id: 'f1',
        name: 'Bakso Urat Jumbo',
        price: 25000,
        quantity: 2,
        storeId: 'resto_1',
        storeName: 'Bakso Pak Kumis',
        category: 'Food',
        menuOrigin: 'food',
      ));
      expect(added1, isTrue);
      expect(cart.merchantCount, equals(1));
      expect(cart.currentStoreName, equals('Bakso Pak Kumis'));

      // Check hasDifferentMerchant
      expect(cart.hasDifferentMerchant('resto_1'), isFalse);
      expect(cart.hasDifferentMerchant('store_2'), isTrue);

      // Attempt to add from Toko 2 should be rejected
      final added2 = cart.addItem(CartItem(
        id: 's1',
        name: 'Indomie Dus',
        price: 110000,
        quantity: 1,
        storeId: 'store_2',
        storeName: 'Minimarket Sumber',
        category: 'Minimarket',
        menuOrigin: 'shop',
      ));
      expect(added2, isFalse);
      expect(cart.lastErrorMessage, contains('1 pesanan hanya untuk 1 toko'));
      expect(cart.merchantCount, equals(1));
      expect(cart.uniqueStoreIds, equals(['resto_1']));

      // addItemOrThrow should throw exception
      expect(
        () => cart.addItemOrThrow(CartItem(
          id: 's1',
          name: 'Indomie Dus',
          price: 110000,
          storeId: 'store_2',
          storeName: 'Minimarket Sumber',
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('clearAndAdd replaces previous store with new store', () {
      cart.addItem(CartItem(
        id: 'f1',
        name: 'Bakso Urat Jumbo',
        price: 25000,
        storeId: 'resto_1',
        storeName: 'Bakso Pak Kumis',
      ));
      expect(cart.currentStoreName, equals('Bakso Pak Kumis'));

      // Clear and switch to new store
      cart.clearAndAdd(CartItem(
        id: 's1',
        name: 'Indomie Dus',
        price: 110000,
        storeId: 'store_2',
        storeName: 'Minimarket Sumber',
      ));

      expect(cart.merchantCount, equals(1));
      expect(cart.currentStoreName, equals('Minimarket Sumber'));
      expect(cart.uniqueStoreIds, equals(['store_2']));
      expect(cart.totalItemCount, equals(1));
      expect(cart.totalItemsPrice, equals(110000));
    });

    test('removeItem and updateQuantity behave correctly', () {
      final item = CartItem(
        id: 'p1',
        name: 'Kopi Kapal Api',
        price: 12000,
        quantity: 3,
        storeId: 'shop_1',
        storeName: 'Toko Kopi',
      );
      cart.addItem(item);

      cart.updateQuantity('shop_1', 'p1', 5);
      expect(cart.getItemQuantity('shop_1', 'p1'), equals(5));

      cart.updateQuantity('shop_1', 'p1', 0);
      expect(cart.isEmpty, isTrue);
    });
  });
}
