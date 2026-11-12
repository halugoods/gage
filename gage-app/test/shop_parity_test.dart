import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_home_header.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';

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

  group('1. GageApiClient Shop Isolation & Store-Specific Menus', () {
    test('isShopMerchant isolates shop stores and excludes food, farm, build, and babe', () {
      expect(GageApiClient.isShopMerchant({'id': 'shop-berkah-fajar', 'name': 'Berkah Fajar'}), isTrue);
      expect(GageApiClient.isShopMerchant({'id': 'ext-1', 'name': 'Toko Kelontong Sejahtera', 'category': 'Sembako'}), isTrue);
      expect(GageApiClient.isShopMerchant({'id': 'mch-dimsum-01', 'name': 'Dimsum Sewu', 'category': 'Kuliner'}), isFalse);
      expect(GageApiClient.isShopMerchant({'id': 'farm-kios-subur', 'name': 'Kios Tani', 'category': 'Pupuk & Benih'}), isFalse);
      expect(GageApiClient.isShopMerchant({'id': 'build-sumber-abadi', 'name': 'TB Sumber Abadi', 'category': 'Semen & Cat'}), isFalse);
      expect(GageApiClient.isShopMerchant({'id': 'babe-01', 'name': 'Barang Bekas Praci'}), isFalse);
    });

    test('getShopMerchants returns all Pracimantoro Shop stores with domain shop', () async {
      final stores = await GageApiClient.getShopMerchants();
      final ids = stores.map((s) => s['id']).toSet();
      expect(
        ids,
        containsAll([
          'shop-berkah-fajar',
          'shop-kelontong-bu-sri',
          'shop-minimarket-losari',
          'shop-grosir-sentosa',
          'shop-sayur-bu-marti',
          'shop-sumber-lancar',
          'shop-telur-jaya',
          'shop-lapak-siti',
        ]),
      );
      for (final s in stores) {
        expect(s['domain'], equals('shop'));
        expect(s['serviceType'], equals('shop'));
      }
    });

    test('getMerchantMenu differentiates specialized Shop catalogs', () async {
      final galonMenus = await GageApiClient.getMerchantMenu('shop-sumber-lancar');
      expect(galonMenus.any((m) => (m['name'] as String).contains('Galon')), isTrue);
      expect(galonMenus.any((m) => (m['name'] as String).contains('LPG')), isTrue);

      final minimarketMenus = await GageApiClient.getMerchantMenu('shop-minimarket-losari');
      expect(minimarketMenus.any((m) => (m['name'] as String).contains('Teh Pucuk')), isTrue);
      expect(minimarketMenus.any((m) => (m['name'] as String).contains('Rinso')), isTrue);

      final telurMenus = await GageApiClient.getMerchantMenu('shop-telur-jaya');
      expect(telurMenus.any((m) => (m['name'] as String).contains('Telur Ayam Ras')), isTrue);
      expect(telurMenus.any((m) => (m['name'] as String).contains('Terigu')), isTrue);

      final sayurMenus = await GageApiClient.getMerchantMenu('shop-sayur-bu-marti');
      expect(sayurMenus.any((m) => (m['name'] as String).contains('Sayur Sop')), isTrue);
      expect(sayurMenus.any((m) => (m['name'] as String).contains('Cabai Rawit')), isTrue);
    });
  });

  group('2. ShopScreen Category Filtering & Unified MerchantDetailScreen Parity', () {
    testWidgets('All 9 Shop categories return matching stores and tap opens MerchantDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(const ShopScreen()));
      await tester.pump(const Duration(milliseconds: 450));
      await tester.pumpAndSettle();

      const previouslyBrokenCategories = [
        'Telur Segar',
        'Gula & Terigu',
        'Mie & Makanan Instan',
        'Sayur & Cabai',
        'Minuman Dingin',
        'Sabun & Kebersihan',
        'Makanan Ringan',
      ];

      for (final cat in previouslyBrokenCategories) {
        final catFinder = find.text(cat);
        if (catFinder.evaluate().isEmpty) {
          final grid = find.byType(GridView).first;
          await tester.drag(grid, const Offset(-320, 0));
          await tester.pumpAndSettle();
        }
        expect(find.text(cat), findsAtLeastNWidgets(1), reason: 'Category $cat must exist');
        await tester.tap(find.text(cat).first);
        await tester.pumpAndSettle();

        expect(
          find.textContaining('Toko tidak ditemukan'),
          findsNothing,
          reason: 'Category $cat must match at least 1 store',
        );
      }

      // Reset to Semua
      final resetFinder = find.text('Reset');
      if (resetFinder.evaluate().isNotEmpty) {
        await tester.tap(resetFinder);
        await tester.pumpAndSettle();
      }

      // Verify store cards display updated GAGE Shop promo badges & open MerchantDetailScreen
      expect(find.text('Diskon 8RB'), findsWidgets);
      final storeFinder = find.textContaining('Toko Sembako Berkah Fajar', findRichText: true).first;
      await tester.ensureVisible(storeFinder);
      await tester.tap(storeFinder);
      await tester.pumpAndSettle();

      expect(find.byType(MerchantDetailScreen), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 7RB'), findsOneWidget);
      expect(find.text('Diskon 10RB'), findsOneWidget);
      expect(find.text('Beras C4 Super Raja 5 Kg'), findsOneWidget);

      // Scroll to verify collapsed header domain localization ('Cari produk di toko ini...')
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Cari produk di toko ini...'), findsOneWidget);

      // Add Shop item to Cart and verify serviceType = 'shop' + Produk label + auto promos
      final addButtons = find.text('Tambah');
      expect(addButtons, findsWidgets);
      await tester.ensureVisible(addButtons.first);
      await tester.tap(addButtons.first);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      final barCtx = tester.element(find.byType(SeamlessFloatingCartBar));
      final cart = Provider.of<CartProvider>(barCtx, listen: false);
      expect(cart.primaryServiceType, equals('shop'));
      expect(cart.itemQuantityLabel, equals('Produk'));
      // Beras C4 5 Kg Rp 72.000 (>= 40.000) selects best eligible Shop voucher SEMBAKOMURAH (10RB > 8RB)
      expect(cart.foodPromoCode, equals('SEMBAKOMURAH'));
      expect(cart.foodPromoDiscount, equals(10000));
      expect(cart.deliveryPromoCode, equals('ONGKIRFREE-SHOP'));
    });
  });

  group('3. Unified MerchantDetailScreen Routing Parity', () {
    testWidgets('ShopFavoriteScreen opens MerchantDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(const ShopFavoriteScreen()));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('Toko Sembako Berkah Fajar'), findsOneWidget);
      await tester.tap(find.text('Toko Sembako Berkah Fajar'));
      await tester.pumpAndSettle();

      expect(find.byType(MerchantDetailScreen), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 7RB'), findsOneWidget);
      expect(find.text('Beras C4 Super Raja 5 Kg'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(find.text('Cari produk di toko ini...'), findsOneWidget);
    });

    testWidgets('GageHomeHeader search routes Shop, Farm & Build merchants to MerchantDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithProviders(
          const Scaffold(
            body: GageHomeHeader(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cari layanan, toko, atau menu...'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'Berkah Fajar');
      await tester.pump(const Duration(milliseconds: 300));

      final shopResult = find.text('Toko Sembako Berkah Fajar');
      expect(shopResult, findsWidgets);
      await tester.tap(shopResult.first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MerchantDetailScreen), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 7RB'), findsOneWidget);
      expect(find.text('Beras C4 Super Raja 5 Kg'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(MerchantDetailScreen),
          matching: find.byIcon(Icons.arrow_back_rounded),
        ).first,
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Cari layanan, toko, atau menu...'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'Subur Makmur');
      await tester.pump(const Duration(milliseconds: 300));

      final farmResult = find.text('Kios Tani Subur Makmur');
      expect(farmResult, findsWidgets);
      await tester.tap(farmResult.first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MerchantDetailScreen), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byType(MerchantDetailScreen),
          matching: find.byIcon(Icons.arrow_back_rounded),
        ).first,
      );
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.text('Cari layanan, toko, atau menu...'));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(find.byType(TextField), 'Pracimantoro Bangkit');
      await tester.pump(const Duration(milliseconds: 300));

      final buildResult = find.text('TB Pracimantoro Bangkit');
      expect(buildResult, findsWidgets);
      await tester.tap(buildResult.first);
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MerchantDetailScreen), findsOneWidget);
    });

    testWidgets('MerchantDetailScreen resolves store vouchers by serviceType even with arbitrary IDs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithProviders(
          const MerchantDetailScreen(
            merchant: {
              'id': 'm-98213',
              'name': 'Toko Mitra Merdeka',
              'category': 'Kebutuhan Proyek Harian',
              'serviceType': 'build',
              'domain': 'build',
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      expect(find.text('Diskon 15RB'), findsOneWidget);
      expect(find.text('Diskon 25RB'), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 10RB'), findsOneWidget);
    });
  });
}
