import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/features/food/data/service_directory_helper.dart';
import 'package:gage_app/features/food/presentation/build_screen.dart';
import 'package:gage_app/features/food/presentation/farm_screen.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    MultiMerchantCartService.instance.clearCart();
    GageApiClient.allowDevSeedFallback = true;
    GageApiClient.testHttpClient = MockClient(
      (_) async => http.Response(jsonEncode({'success': true, 'data': []}), 200),
    );
    GageApiClient.clearMerchantMenuCache();
  });

  tearDown(() {
    GageApiClient.allowDevSeedFallback = true;
    GageApiClient.testHttpClient = null;
    GageApiClient.clearMerchantMenuCache();
  });

  Widget wrapWithProviders(Widget home) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
        ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
        ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
        ChangeNotifierProvider<BannerManagerService>.value(value: BannerManagerService.instance),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(home: home),
    );
  }

  group('1. Production Active-Merchant Separation & Live Menu Fetch', () {
    test('Production mode excludes dev seeds and inactive accounts, and loads live HTTP menus', () async {
      GageApiClient.allowDevSeedFallback = false;
      GageApiClient.testHttpClient = MockClient((request) async {
        if (request.url.path == '/api/merchants') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'reg-farm-aktif',
                  'name': 'Kios Mitra Resmi Pracimantoro',
                  'service_type': 'farm',
                  'category': 'Pupuk & Nutrisi',
                  'status': 'active',
                  'is_open': 1,
                  'is_active': 1,
                },
                {
                  'id': 'reg-farm-pending',
                  'name': 'Calon Mitra Belum Verifikasi',
                  'service_type': 'farm',
                  'category': 'Pupuk',
                  'status': 'pending',
                  'is_open': 1,
                },
                {
                  'id': 'reg-build-closed',
                  'name': 'Toko Tutup Sementara',
                  'service_type': 'build',
                  'category': 'Semen',
                  'status': 'active',
                  'is_open': 0,
                },
                {
                  'id': 'reg-build-aktif',
                  'name': 'TB Mitra Terdaftar Jaya',
                  'service_type': 'build',
                  'category': 'Semen & Pasir',
                  'status': 'active',
                  'is_open': 1,
                },
              ],
            }),
            200,
          );
        }
        if (request.url.path == '/api/merchants/reg-build-aktif/menu') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'live-menu-1',
                  'name': 'Semen Putih Super Praci 40 Kg',
                  'category': 'Semen & Pasir',
                  'description': 'Produk riil terdaftar dari akun merchant aktif',
                  'offline_price': 60000,
                  'gage_price': 63000,
                  'is_available': 1,
                },
                {
                  'id': 'live-menu-hidden',
                  'name': 'Produk Habis Disembunyikan',
                  'category': 'Semen',
                  'offline_price': 10000,
                  'gage_price': 10000,
                  'is_available': 0,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      final farmStores = await GageApiClient.getFarmMerchants();
      expect(farmStores.map((s) => s['id']).toList(), equals(['reg-farm-aktif']));

      final buildStores = await GageApiClient.getBuildMerchants();
      expect(buildStores.map((s) => s['id']).toList(), equals(['reg-build-aktif']));

      final shopStores = await GageApiClient.getShopMerchants();
      expect(shopStores, isEmpty);

      final foodStores = await GageApiClient.getFoodMerchants();
      expect(foodStores, isEmpty);

      final buildMenus = await GageApiClient.getMerchantMenu('reg-build-aktif');
      expect(buildMenus.length, equals(1));
      expect(buildMenus.first['name'], equals('Semen Putih Super Praci 40 Kg'));
      expect(buildMenus.first['isDevSeed'], isFalse);

      // Search matches live product catalog cached from API (even if absent on store name)
      expect(
        ServiceDirectoryHelper.matchesMerchantSearch(buildStores.first, 'Semen Putih Super'),
        isTrue,
      );
      expect(
        ServiceDirectoryHelper.matchedProductsLabel(buildStores.first, 'Semen Putih'),
        equals('Cocok: Semen Putih Super Praci 40 Kg'),
      );

      // Empty catalog endpoint returns [] in production mode (no hardcoded dimsum/semen)
      final emptyMenus = await GageApiClient.getMerchantMenu('reg-farm-aktif');
      expect(emptyMenus, isEmpty);
    });
  });

  group('2. Banner Sanitization & Farm/Build Catalog Search Across Screens', () {
    test('BannerManagerService sanitizes legacy send_hero_banner.png on customer_shop', () async {
      SharedPreferences.setMockInitialValues({
        'gage_banner_manager_configs': jsonEncode({
          'customer_shop': {
            'menuKey': 'customer_shop',
            'menuName': 'GAGE Shop',
            'title': 'Sembako',
            'subtitle': 'Belanja',
            'badge': '',
            'imagePath': 'assets/images/send_hero_banner.png',
            'ctaText': 'Mulai Belanja',
            'isActive': true,
          },
        }),
      });

      final service = BannerManagerService.instance;
      await service.loadFromPrefs();
      expect(service.getBanner('customer_shop').imagePath, equals('assets/images/shop_hero_banner.png'));
      expect(service.getBanner('build').imagePath, equals('assets/images/prod_semen.png'));
    });

    Future<void> pumpFrames(WidgetTester tester, {int steps = 8, int stepMs = 80}) async {
      for (int i = 0; i < steps; i++) {
        await tester.pump(Duration(milliseconds: stepMs));
      }
    }

    testWidgets('Real catalog search works across Food, Shop, Farm, Build screens', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Food: search "cimol" matches Seblak Nyentrik catalog
      await tester.pumpWidget(wrapWithProviders(const FoodExploreScreen()));
      await pumpFrames(tester);
      await tester.enterText(find.byType(TextField).first, 'cimol');
      await pumpFrames(tester, steps: 4);
      expect(find.textContaining('Seblak Prasmanan', findRichText: true), findsWidgets);
      expect(find.textContaining('Cocok: Cimol Bojot'), findsWidgets);

      // Shop: search "teh pucuk" matches Minimarket Warga Losari catalog
      await tester.pumpWidget(wrapWithProviders(const ShopScreen()));
      await pumpFrames(tester);
      await tester.enterText(find.byType(TextField).first, 'teh pucuk');
      await pumpFrames(tester, steps: 4);
      expect(find.textContaining('Minimarket Warga Losari', findRichText: true), findsWidgets);
      expect(find.textContaining('Cocok: Teh Pucuk'), findsWidgets);

      // Farm: search "rodalon" matches Kios Pakan Sedayu catalog on Peternakan tab
      await tester.pumpWidget(wrapWithProviders(const FarmScreen(initialTab: 'peternakan')));
      await pumpFrames(tester);
      await tester.enterText(find.byType(TextField).first, 'rodalon');
      await pumpFrames(tester, steps: 4);
      expect(find.textContaining('Sedayu', findRichText: true), findsWidgets);
      expect(find.textContaining('Cocok: Desinfektan Kandang'), findsWidgets);

      // Build: search "eterna nym" (multi-token) matches TB Sinar Mandiri catalog
      await tester.pumpWidget(wrapWithProviders(const BuildScreen()));
      await pumpFrames(tester);
      await tester.enterText(find.byType(TextField).first, 'eterna nym');
      await pumpFrames(tester, steps: 4);
      expect(find.textContaining('Sinar Mandiri', findRichText: true), findsWidgets);
      expect(find.textContaining('Cocok: Kabel Listrik Eterna'), findsWidgets);
    });
  });

  group('3. Iterasi 1.3 Farm Parity & Iterasi 1.4 Build Parity', () {
    Future<void> pumpFrames(WidgetTester tester, {int steps = 8, int stepMs = 80}) async {
      for (int i = 0; i < steps; i++) {
        await tester.pump(Duration(milliseconds: stepMs));
      }
    }

    testWidgets('All 14 Farm categories (Pertanian + Peternakan) return stores and open MerchantDetailScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(const FarmScreen()));
      await pumpFrames(tester);

      const pertanianCats = [
        'Pupuk & Nutrisi',
        'Benih & Bibit',
        'Obat & Pestisida',
        'Alat Pertanian',
        'Padi & Palawija',
        'Cabai & Sayuran',
        'Pipa Irigasi',
      ];
      for (final cat in pertanianCats) {
        final finder = find.text(cat);
        if (finder.evaluate().isEmpty) {
          await tester.drag(find.byType(GridView).first, const Offset(-320, 0));
          await pumpFrames(tester, steps: 4);
        }
        await tester.tap(find.text(cat).first);
        await pumpFrames(tester, steps: 3);
        expect(find.textContaining('Tidak ada toko yang cocok'), findsNothing, reason: 'Farm Pertanian "$cat" must match >= 1 store');
      }

      // Switch to Peternakan tab and test all 7 livestock categories
      await tester.tap(find.text('Peternakan'));
      await pumpFrames(tester, steps: 4);
      const peternakanCats = [
        'Pakan Unggas',
        'Pakan Sapi',
        'Konsentrat Pakan',
        'Vitamin & Obat Hewan',
        'Telur & DOC',
        'Peralatan Kandang',
        'Desinfektan',
      ];
      for (final cat in peternakanCats) {
        final finder = find.text(cat);
        if (finder.evaluate().isEmpty) {
          await tester.drag(find.byType(GridView).first, const Offset(-320, 0));
          await pumpFrames(tester, steps: 4);
        }
        await tester.tap(find.text(cat).first);
        await pumpFrames(tester, steps: 3);
        expect(find.textContaining('Tidak ada toko yang cocok'), findsNothing, reason: 'Farm Peternakan "$cat" must match >= 1 store');
      }

      // Reset category & open Farm favorite screen via header favorite button
      await tester.tap(find.text('Pertanian'));
      await pumpFrames(tester, steps: 4);
      final resetFarm = find.text('Reset');
      if (resetFarm.evaluate().isNotEmpty) {
        await tester.tap(resetFarm.first);
        await pumpFrames(tester, steps: 3);
      }
      await tester.tap(
        find.descendant(
          of: find.byType(GageServiceStickyHeader),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
      );
      await pumpFrames(tester, steps: 8);
      expect(find.byType(ShopFavoriteScreen), findsOneWidget);
      expect(find.text('Kios Tani & Ternak Favorit'), findsOneWidget);
      await tester.pageBack();
      await pumpFrames(tester, steps: 8);

      // Verify voucher badge alignment & MerchantDetailScreen domain 'farm'
      expect(find.text('Diskon 10RB'), findsWidgets);
      final kiosFinder = find.textContaining('Kios Tani Subur Makmur', findRichText: true).first;
      await tester.ensureVisible(kiosFinder);
      await tester.tap(kiosFinder);
      await pumpFrames(tester, steps: 8);
      expect(find.byType(MerchantDetailScreen), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 7RB'), findsOneWidget);

      await tester.ensureVisible(find.text('Tambah').first);
      await tester.tap(find.text('Tambah').first);
      await tester.pump(const Duration(seconds: 3));
      await pumpFrames(tester, steps: 4);
      final cart = Provider.of<CartProvider>(tester.element(find.byType(SeamlessFloatingCartBar)), listen: false);
      expect(cart.primaryServiceType, equals('farm'));
      // NPK 1kg Rp 19.500 < minOrder Rp 25.000, so ONGKIRFREE-FARM is not yet eligible
      expect(cart.deliveryPromoCode, isNull);

      // Increment to 2x (Rp 39.000 >= 30.000): SUBSIDITANI + ONGKIRFREE-FARM auto-apply
      await tester.tap(find.byIcon(Icons.add).first);
      await pumpFrames(tester, steps: 4);
      expect(cart.foodPromoCode, equals('SUBSIDITANI'));
      expect(cart.deliveryPromoCode, equals('ONGKIRFREE-FARM'));
    });

    testWidgets('All 9 Build categories return stores and open MerchantDetailScreen with ONGKIRFREE-BUILD', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(wrapWithProviders(const BuildScreen()));
      await pumpFrames(tester);

      const buildCats = [
        'Semen & Pasir',
        'Cat & Thinner',
        'Besi & Baja',
        'Pipa & Keran',
        'Alat Tukang',
        'Keramik Lantai',
        'Kayu & Triplek',
        'Kelistrikan',
        'Atap & Genteng',
      ];
      for (final cat in buildCats) {
        final finder = find.text(cat);
        if (finder.evaluate().isEmpty) {
          await tester.drag(find.byType(GridView).first, const Offset(-320, 0));
          await pumpFrames(tester, steps: 4);
        }
        await tester.tap(find.text(cat).first);
        await pumpFrames(tester, steps: 3);
        expect(find.textContaining('Tidak ada toko yang cocok'), findsNothing, reason: 'Build category "$cat" must match >= 1 store');
      }

      final resetFinder = find.text('Reset');
      if (resetFinder.evaluate().isNotEmpty) {
        await tester.tap(resetFinder.first);
        await pumpFrames(tester, steps: 3);
      }

      // Open Build favorite screen via header favorite button
      await tester.tap(
        find.descendant(
          of: find.byType(GageServiceStickyHeader),
          matching: find.byIcon(Icons.favorite_rounded),
        ),
      );
      await pumpFrames(tester, steps: 8);
      expect(find.byType(ShopFavoriteScreen), findsOneWidget);
      expect(find.text('Toko Bangunan Favorit'), findsOneWidget);
      await tester.pageBack();
      await pumpFrames(tester, steps: 8);

      // Open TB Sumber Bangunan -> MerchantDetailScreen & add item -> Build vouchers auto-applied
      expect(find.text('Diskon 15RB'), findsWidgets);
      final buildFinder = find.textContaining('TB Sumber Bangunan Pracimantoro', findRichText: true).first;
      await tester.ensureVisible(buildFinder);
      await tester.tap(buildFinder);
      await pumpFrames(tester, steps: 8);
      expect(find.byType(MerchantDetailScreen), findsOneWidget);
      expect(find.text('Gratis Ongkir s.d 10RB'), findsOneWidget);

      await tester.ensureVisible(find.text('Tambah').first);
      await tester.tap(find.text('Tambah').first);
      await tester.pump(const Duration(seconds: 3));
      await pumpFrames(tester, steps: 4);
      final cart = Provider.of<CartProvider>(tester.element(find.byType(SeamlessFloatingCartBar)), listen: false);
      expect(cart.primaryServiceType, equals('build'));
      expect(cart.deliveryPromoCode, equals('ONGKIRFREE-BUILD'));
    });
  });
}
