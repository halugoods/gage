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

      final updated = foodItem.copyWith(quantity: 3, menuOrigin: 'tani');
      expect(updated.quantity, equals(3));
      expect(updated.menuOrigin, equals('tani'));
      expect(updated.note, equals('Pedas sedang'));
    });

    test('CartItem toJson and fromJson serialization preserves menuOrigin', () {
      final original = CartItem(
        id: 't1',
        name: 'Pupuk Urea 5kg',
        price: 45000,
        quantity: 2,
        storeId: 'tani_1',
        storeName: 'Kios Tani Makmur',
        category: 'Pupuk',
        image: 'pupuk.png',
        note: 'Titip di teras',
        menuOrigin: 'tani',
      );

      final json = original.toJson();
      expect(json['menuOrigin'], equals('tani'));

      final restored = CartItem.fromJson(json);
      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.price, equals(original.price));
      expect(restored.quantity, equals(original.quantity));
      expect(restored.storeId, equals(original.storeId));
      expect(restored.storeName, equals(original.storeName));
      expect(restored.menuOrigin, equals('tani'));
      expect(restored.note, equals('Titip di teras'));
    });
  });

  group('MultiMerchantCartService Tests', () {
    late MultiMerchantCartService cart;

    setUp(() {
      cart = MultiMerchantCartService();
      cart.clearCart();
    });

    test('Initial cart state is empty', () {
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.totalItemsPrice, equals(0));
      expect(cart.merchantCount, equals(0));
      expect(cart.uniqueStoreIds, isEmpty);
      expect(cart.uniqueStoreNames, isEmpty);
      expect(cart.activeMenuOrigins, isEmpty);
      expect(cart.isCrossMenu, isFalse);
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
      expect(cart.activeMenuOrigins, equals(['shop']));
      expect(cart.isCrossMenu, isFalse);
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

    test('Supports cross-menu shopping (Food + Shop + Tani) up to 3 stores', () {
      // Toko 1: Menu Food
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

      // Toko 2: Menu Shop
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
      expect(added2, isTrue);

      // Toko 3: Menu Tani
      final added3 = cart.addItem(CartItem(
        id: 't1',
        name: 'Bibit Cabai Rawit Unggul',
        price: 15000,
        quantity: 3,
        storeId: 'tani_3',
        storeName: 'Kios Tani Makmur',
        category: 'Bibit',
        menuOrigin: 'tani',
      ));
      expect(added3, isTrue);

      expect(cart.merchantCount, equals(3));
      expect(cart.totalItemCount, equals(6)); // 2 + 1 + 3
      expect(cart.totalItemsPrice, equals(205000)); // 50000 + 110000 + 45000
      expect(cart.uniqueStoreIds.length, equals(3));
      expect(cart.uniqueStoreNames, containsAll(['Bakso Pak Kumis', 'Minimarket Sumber', 'Kios Tani Makmur']));

      // Cross-menu checks
      expect(cart.activeMenuOrigins.length, equals(3));
      expect(cart.activeMenuOrigins, containsAll(['food', 'shop', 'tani']));
      expect(cart.isCrossMenu, isTrue);
      expect(cart.hasMenuOrigin('food'), isTrue);
      expect(cart.hasMenuOrigin('shop'), isTrue);
      expect(cart.hasMenuOrigin('tani'), isTrue);

      // Store-specific getters
      expect(cart.getStoreSubtotal('resto_1'), equals(50000));
      expect(cart.getStoreSubtotal('store_2'), equals(110000));
      expect(cart.getStoreSubtotal('tani_3'), equals(45000));
      expect(cart.getItemsForStore('resto_1').length, equals(1));
      expect(cart.getItemsForStore('resto_1').first.name, equals('Bakso Urat Jumbo'));

      // Menu origin helpers
      expect(cart.getMenuSubtotal('food'), equals(50000));
      expect(cart.getMenuSubtotal('tani'), equals(45000));
      expect(cart.getItemsByMenuOrigin('tani').length, equals(1));

      // Attempt toko ke-4 harus ditolak (limit 3)
      final added4 = cart.addItem(CartItem(
        id: 'p4',
        name: 'Obat Sakit Kepala',
        price: 5000,
        quantity: 1,
        storeId: 'store_4',
        storeName: 'Apotek Pracimantoro',
        category: 'Farmasi',
        menuOrigin: 'shop',
      ));
      expect(added4, isFalse);
      expect(cart.lastErrorMessage, contains('Maksimal 3 toko'));
      expect(cart.merchantCount, equals(3));

      // addItemOrThrow should throw exception on 4th store
      expect(
        () => cart.addItemOrThrow(CartItem(
          id: 'p4',
          name: 'Obat Sakit Kepala',
          price: 5000,
          storeId: 'store_4',
          storeName: 'Apotek Pracimantoro',
        )),
        throwsA(isA<StateError>()),
      );
    });

    test('clearStore removes only specified store items', () {
      cart.addItem(CartItem(
        id: 'f1',
        name: 'Sate Ayam',
        price: 20000,
        storeId: 'resto_1',
        storeName: 'Warung Bu Sri',
        menuOrigin: 'food',
      ));
      cart.addItem(CartItem(
        id: 's1',
        name: 'Sapu Lidi',
        price: 10000,
        storeId: 'shop_1',
        storeName: 'Toko Alat Rumah',
        menuOrigin: 'shop',
      ));

      expect(cart.merchantCount, equals(2));
      cart.clearStore('resto_1');
      expect(cart.merchantCount, equals(1));
      expect(cart.uniqueStoreIds, equals(['shop_1']));
      expect(cart.activeMenuOrigins, equals(['shop']));
      expect(cart.isCrossMenu, isFalse);
    });

    test('Update quantity and removal works properly', () {
      cart.addItem(CartItem(
        id: 'p1',
        name: 'Gula 1kg',
        price: 17500,
        quantity: 2,
        storeId: 'store_1',
        storeName: 'Toko Berkah',
        category: 'Sembako',
        image: '',
      ));

      cart.updateQuantity('store_1', 'p1', 5);
      expect(cart.totalItemCount, equals(5));
      expect(cart.totalItemsPrice, equals(87500));

      // Update to 0 removes the item and store
      cart.updateQuantity('store_1', 'p1', 0);
      expect(cart.isEmpty, isTrue);
      expect(cart.merchantCount, equals(0));
    });

    test('Clear cart removes all items across all stores', () {
      cart.addItem(CartItem(
        id: 'p1',
        name: 'Item 1',
        price: 10000,
        storeId: 's1',
        storeName: 'Store 1',
        menuOrigin: 'food',
      ));
      cart.addItem(CartItem(
        id: 'p2',
        name: 'Item 2',
        price: 20000,
        storeId: 's2',
        storeName: 'Store 2',
        menuOrigin: 'shop',
      ));

      expect(cart.merchantCount, equals(2));
      cart.clearCart();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.totalItemsPrice, equals(0));
      expect(cart.activeMenuOrigins, isEmpty);
    });
  });
}
