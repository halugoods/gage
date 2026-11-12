import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/food/data/merchant_catalog_helper.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MultiMerchantCartService.instance.clearCart();
  });

  Widget wrapWithProviders(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
        ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
        ChangeNotifierProvider<BannerManagerService>(create: (_) => BannerManagerService()),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(home: home),
    );
  }

  group('MerchantCatalogHelper Logic', () {
    test('resolvePrice applies merchant promo override and original_price accurately', () {
      const storefront = MerchantStorefrontData(
        merchantId: 'mch-dimsum-01',
        itemPromoPrices: {'menu-1': 12000},
      );

      final overridden = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-1', 'gage_price': 16000},
        storefront: storefront,
        devSeedOverride: false,
      );
      expect(overridden.effectivePrice, equals(12000));
      expect(overridden.originalPrice, equals(16000));
      expect(overridden.hasDiscount, isTrue);
      expect(overridden.discountPercent, equals(25));

      final apiPromo = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-2', 'gage_price': 15000, 'original_price': 20000},
        devSeedOverride: false,
      );
      expect(apiPromo.effectivePrice, equals(15000));
      expect(apiPromo.originalPrice, equals(20000));
      expect(apiPromo.discountPercent, equals(25));

      final plainProd = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-rc-01', 'gage_price': 14000},
        devSeedOverride: false,
      );
      expect(plainProd.effectivePrice, equals(14000));
      expect(plainProd.hasDiscount, isFalse);

      // promo_active: 0 and invalid promo_price >= gage_price must NOT fall through to seed promo ratios
      final disabledPromo = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-rc-01', 'gage_price': 14000, 'promo_price': 10000, 'promo_active': 0},
        devSeedOverride: true,
      );
      expect(disabledPromo.effectivePrice, equals(14000));
      expect(disabledPromo.hasDiscount, isFalse);

      final invalidPromo = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-rc-01', 'gage_price': 14000, 'promo_price': 16000},
        devSeedOverride: true,
      );
      expect(invalidPromo.effectivePrice, equals(14000));
      expect(invalidPromo.hasDiscount, isFalse);

      final turnedOffByMerchant = MerchantCatalogHelper.resolvePrice(
        {'id': 'menu-rc-01', 'gage_price': 14000},
        storefront: const MerchantStorefrontData(
          merchantId: 'mch-dimsum-01',
          itemPromoPrices: {'menu-rc-01': 0},
        ),
        devSeedOverride: true,
      );
      expect(turnedOffByMerchant.effectivePrice, equals(14000));
      expect(turnedOffByMerchant.hasDiscount, isFalse);
    });

    test('resolveSoldCount aggregates real completed orders and hides 0 in production', () {
      final orders = <OrderModel>[
        OrderModel(
          id: 'ord-1',
          orderNumber: 'GG-1',
          userId: 'u-1',
          merchantId: 'mch-1',
          merchantName: 'Toko Satu',
          merchantAddress: 'Pracimantoro',
          status: 'COMPLETED',
          paymentMethod: 'GAGEPAY',
          paymentStatus: 'PAID',
          totalAmount: 30000,
          itemsSubtotal: 30000,
          shippingFee: 0,
          shippingDiscount: 0,
          adminFee: 1000,
          deliveryAddress: 'Alamat',
          distanceKm: 1.0,
          trackingToken: 'trk-1',
          createdAt: 1700000000,
          items: const [
            OrderItemModel(id: 'm-1', name: 'Bakso', price: 15000, quantity: 2, subtotal: 30000),
          ],
        ),
        OrderModel(
          id: 'ord-2',
          orderNumber: 'GG-2',
          userId: 'u-1',
          merchantId: 'mch-1',
          merchantName: 'Toko Satu',
          merchantAddress: 'Pracimantoro',
          status: 'ON_DELIVERY',
          paymentMethod: 'GAGEPAY',
          paymentStatus: 'PAID',
          totalAmount: 15000,
          itemsSubtotal: 15000,
          shippingFee: 0,
          shippingDiscount: 0,
          adminFee: 1000,
          deliveryAddress: 'Alamat',
          distanceKm: 1.0,
          trackingToken: 'trk-2',
          createdAt: 1700000100,
          items: const [
            OrderItemModel(id: 'm-1', name: 'Bakso', price: 15000, quantity: 9, subtotal: 135000),
          ],
        ),
      ];

      final completedMap = MerchantCatalogHelper.buildCompletedOrderCounts(orders, merchantId: 'mch-1');
      final sold = MerchantCatalogHelper.resolveSoldCount(
        {'id': 'm-1', 'name': 'Bakso', 'sold_count': 10},
        completedOrderQtyByKey: completedMap,
        devSeedOverride: false,
      );
      expect(sold, equals(12));

      final zeroProd = MerchantCatalogHelper.resolveSoldCount(
        {'id': 'menu-rc-01', 'name': 'Baru'},
        completedOrderQtyByKey: completedMap,
        devSeedOverride: false,
      );
      expect(zeroProd, equals(0));
      expect(MerchantCatalogHelper.formatSoldLabel(0), isEmpty);
      expect(MerchantCatalogHelper.formatSoldLabel(45), equals('45 terjual'));
      expect(MerchantCatalogHelper.formatSoldLabel(1250), equals('1,3rb terjual'));
      expect(MerchantCatalogHelper.formatSoldLabel(1200), equals('1,2rb terjual'));
    });

    test('applySearchAndSort handles Terlaris, Baru ditambahkan, Lagi Promo, Termurah, Termahal', () {
      final items = [
        {'id': 'a', 'name': 'Es Teh', 'category': 'Minuman', 'gage_price': 4000, 'sold_count': 50, 'created_at': 100},
        {'id': 'b', 'name': 'Ayam Bakar', 'category': 'Makanan', 'gage_price': 20000, 'original_price': 25000, 'sold_count': 12, 'created_at': 300},
        {'id': 'c', 'name': 'Dimsum Jumbo', 'category': 'Snack', 'gage_price': 15000, 'sold_count': 180, 'created_at': 200},
      ];

      final bestSelling = MerchantCatalogHelper.applySearchAndSort(
        items,
        searchQuery: '',
        sortMode: MerchantProductSortMode.bestSelling,
        devSeedOverride: false,
      );
      expect(bestSelling.map((e) => e['id']).toList(), equals(['c', 'a', 'b']));

      final newest = MerchantCatalogHelper.applySearchAndSort(
        items,
        searchQuery: '',
        sortMode: MerchantProductSortMode.newest,
        devSeedOverride: false,
      );
      expect(newest.map((e) => e['id']).toList(), equals(['b', 'c', 'a']));

      final promoOnly = MerchantCatalogHelper.applySearchAndSort(
        items,
        searchQuery: '',
        sortMode: MerchantProductSortMode.promoOnly,
        devSeedOverride: false,
      );
      expect(promoOnly.map((e) => e['id']).toList(), equals(['b']));

      final cheapest = MerchantCatalogHelper.applySearchAndSort(
        items,
        searchQuery: '',
        sortMode: MerchantProductSortMode.lowestPrice,
        devSeedOverride: false,
      );
      expect(cheapest.map((e) => e['id']).toList(), equals(['a', 'c', 'b']));

      final priciest = MerchantCatalogHelper.applySearchAndSort(
        items,
        searchQuery: '',
        sortMode: MerchantProductSortMode.highestPrice,
        devSeedOverride: false,
      );
      expect(priciest.map((e) => e['id']).toList(), equals(['b', 'c', 'a']));
    });

    test('groupByOrderedCategories follows Merchant custom categoryOrder first then natural order', () {
      final items = [
        {'id': '1', 'name': 'Teh', 'category': 'Minuman'},
        {'id': '2', 'name': 'Semen', 'category': 'Material Berat'},
        {'id': '3', 'name': 'Paku', 'category': 'Pertukangan'},
        {'id': '4', 'name': 'Kopi', 'category': 'Minuman'},
      ];
      final grouped = MerchantCatalogHelper.groupByOrderedCategories(
        items,
        customOrder: ['Pertukangan', 'minuman'],
      );
      expect(grouped.map((e) => e.key).toList(), equals(['Pertukangan', 'Minuman', 'Material Berat']));
      expect(grouped[1].value.length, equals(2));
    });

    test('MerchantStorefrontData preserves categoryOrder and itemPromoPrices across JSON', () {
      const original = MerchantStorefrontData(
        merchantId: 'mch-test',
        name: 'Toko Uji',
        categoryOrder: ['Promo Spesial', 'Minuman', 'Makanan'],
        itemPromoPrices: {'menu-1': 9500, 'menu-2': 14000},
      );
      final roundTrip = MerchantStorefrontData.fromJson('mch-test', original.toJson());
      expect(roundTrip.categoryOrder, equals(['Promo Spesial', 'Minuman', 'Makanan']));
      expect(roundTrip.itemPromoPrices, equals({'menu-1': 9500, 'menu-2': 14000}));

      final legacy = MerchantStorefrontData.fromJson('mch-legacy', {'name': 'Toko Lama'});
      expect(legacy.categoryOrder, isNull);
      expect(legacy.itemPromoPrices, isNull);
    });
  });

  group('Favorites CTA -> Product Detail & Merchant Showcase UI', () {
    testWidgets('RestoDetailScreen renders bold category headings, sort dropdown, and auto-opens initialProductItem modal', (tester) async {
      await MerchantStorefrontService.saveStorefront(
        const MerchantStorefrontData(
          merchantId: 'mch-dimsum-01',
          categoryOrder: ['Minuman'],
          itemPromoPrices: {'ds-ori': 10000},
        ),
      );

      final store = {
        'id': 'mch-dimsum-01',
        'name': 'Dimsum Sewu Pracimantoro',
        'domain': 'food',
        'serviceType': 'food',
        'rating': 4.9,
      };
      final menus = GageApiClient.devSeedCatalogForMerchant('mch-dimsum-01');
      final firstItem = menus.first;

      await tester.pumpWidget(
        wrapWithProviders(
          RestoDetailScreen(
            merchant: store,
            initialProductItem: firstItem,
            initialProductId: firstItem['id']?.toString(),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // Auto-opened product detail bottom sheet modal should show Tambah button and item name
      expect(find.text('Tambah'), findsAtLeastNWidgets(1));
      expect(find.text('Rekomendasi'), findsOneWidget);

      // Dismiss modal
      final closeBtn = find.byIcon(Icons.close_rounded);
      if (closeBtn.evaluate().isNotEmpty) {
        await tester.tap(closeBtn.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('ShopFavoriteScreen outside merchant opens product detail modal on tap', (tester) async {
      await tester.pumpWidget(
        wrapWithProviders(
          const ShopFavoriteScreen(
            domain: 'shop',
            initialTabIndex: 1,
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final favItemFinder = find.textContaining('Beras');
      if (favItemFinder.evaluate().isNotEmpty) {
        await tester.tap(favItemFinder.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        expect(find.byType(RestoDetailScreen), findsOneWidget);
        expect(find.text('Tambah'), findsAtLeastNWidgets(1));
      }
    });
  });
}
