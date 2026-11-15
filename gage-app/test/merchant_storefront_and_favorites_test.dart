import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/food/presentation/favorite_resto_screen.dart';
import 'package:gage_app/features/food/presentation/item_variant_sheet.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/resto_info_screen.dart';
import 'package:gage_app/features/food/presentation/resto_reviews_screen.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';
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
    GageApiClient.clearMerchantMenuCache();
  });

  tearDown(() {
    GageApiClient.testHttpClient = null;
    GageApiClient.allowDevSeedFallback = true;
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
        ChangeNotifierProvider<BannerManagerService>(create: (_) => BannerManagerService()),
        ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
      ],
      child: MaterialApp(home: home),
    );
  }

  group('Iterasi 1.5 - ItemVariantSheet Multi-Domain & Detail Edit Parity', () {
    testWidgets('ItemVariantSheet supports dynamic variant_groups and extra prices on Shop domain', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late CartProvider cart;

      await tester.pumpWidget(
        wrapWithProviders(
          Builder(
            builder: (ctx) {
              cart = Provider.of<CartProvider>(ctx, listen: false);
              return const Scaffold(
                body: SingleChildScrollView(
                  child: ItemVariantSheet(
                    merchant: {
                      'id': 'shop-berkah-fajar',
                      'name': 'Toko Sembako Berkah Fajar',
                      'domain': 'shop',
                      'serviceType': 'shop',
                    },
                    menuItem: {
                      'id': 'shop-beras-v1',
                      'name': 'Beras Ramos Spesial',
                      'price': 65000,
                      'category': 'Sembako',
                      'variant_groups': [
                        {
                          'title': 'Ukuran Kemasan',
                          'multi_select': false,
                          'required': true,
                          'options': [
                            {'name': '5 Kg', 'extra_price': 0},
                            {'name': '10 Kg', 'extra_price': 60000},
                          ],
                        },
                        {
                          'title': 'Proteksi Pengemasan',
                          'multi_select': true,
                          'required': false,
                          'options': [
                            {'name': 'Karung Lapis Ganda', 'extra_price': 2000},
                          ],
                        },
                      ],
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ukuran Kemasan'), findsOneWidget);
      expect(find.text('Proteksi Pengemasan'), findsOneWidget);
      expect(find.text('Tingkat Pedas / Varian Rasa'), findsNothing);

      await tester.tap(find.text('10 Kg'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Karung Lapis Ganda'));
      await tester.pumpAndSettle();

      await tester.tap(find.textContaining('Tambah'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(cart.items, hasLength(1));
      final added = cart.items.first;
      expect(added.serviceType, equals('shop'));
      expect(added.selectedVariants, equals(['10 Kg', 'Karung Lapis Ganda']));
      expect(added.variantPrice, equals(62000));
      expect(added.subtotal, equals(127000));
    });

    testWidgets('MerchantDetailScreen "Ubah Varian" passes cartItem & detail modal Tambah launches variant sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      GageApiClient.testHttpClient = MockClient((request) async {
        if (request.url.path.contains('/menu')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'menu-combo-99',
                  'merchant_id': 'm-combo-test',
                  'name': 'Combo Dimsum Hemat',
                  'description': 'Paket hemat lengkap',
                  'category': 'Paket Combo',
                  'gage_price': 25000,
                  'offline_price': 30000,
                  'has_variants': true,
                  'variants': ['Original', 'Extra Mentai'],
                  'variant_title': 'Pilihan Saus',
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      late CartProvider cart;

      await tester.pumpWidget(
        wrapWithProviders(
          Builder(
            builder: (ctx) {
              cart = Provider.of<CartProvider>(ctx, listen: false);
              return const MerchantDetailScreen(
                merchant: {
                  'id': 'm-combo-test',
                  'name': 'Resto Combo Uji',
                  'category': 'Kuliner',
                  'domain': 'food',
                  'serviceType': 'food',
                },
              );
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();

      // 1. Tap item row to open Product Detail Modal and verify Tambah launches ItemVariantSheet
      await tester.tap(find.text('Combo Dimsum Hemat').first);
      await tester.pumpAndSettle();
      expect(find.text('Pilihan Saus'), findsNothing);

      final modalTambah = find.text('Tambah').last;
      await tester.tap(modalTambah);
      await tester.pumpAndSettle();
      expect(find.text('Pilihan Saus'), findsOneWidget);

      await tester.tap(find.textContaining('Tambah •'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(cart.items, hasLength(1));
      expect(cart.items.first.selectedVariants, equals(['Original']));

      // 2. Tap "Ubah Varian" -> must open in EDIT mode ('Simpan Perubahan Varian') and update in place
      await tester.ensureVisible(find.text('Ubah Varian'));
      await tester.tap(find.text('Ubah Varian'));
      await tester.pumpAndSettle();

      expect(find.text('Simpan Perubahan Varian'), findsOneWidget);
      await tester.tap(find.text('Extra Mentai'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simpan Perubahan Varian'));
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();

      expect(cart.items, hasLength(1));
      expect(cart.items.first.selectedVariants, equals(['Extra Mentai']));
    });
  });

  group('Iterasi 1.6 - RestoInfoScreen, RestoReviewsScreen & Favorites Parity', () {
    testWidgets('RestoInfoScreen and RestoReviewsScreen adapt UI per domain without food leaks', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        wrapWithProviders(
          const RestoInfoScreen(
            restoName: 'TB Sumber Bangunan Pracimantoro',
            category: 'Semen, Cat & Material',
            domain: 'build',
            merchantId: 'build-sumber-bangunan',
            eta: '20-30 min',
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Info toko bangunan'), findsOneWidget);
      expect(find.text('Info resto'), findsNothing);
      expect(find.textContaining('20-30 min'), findsOneWidget);
      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
      expect(find.byIcon(Icons.restaurant_rounded), findsNothing);

      await tester.tap(find.text('Lihat semua'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(RestoReviewsScreen), findsOneWidget);
      expect(find.textContaining('Semen Gresik PCC 40 Kg'), findsOneWidget);
      expect(find.textContaining('🍽️'), findsNothing);
      expect(find.textContaining('Ayam Geprek'), findsNothing);
    });

    testWidgets('RestoReviewsScreen hides dummy reviews when useDevSeedData is false', (tester) async {
      GageApiClient.allowDevSeedFallback = false;

      await tester.pumpWidget(
        wrapWithProviders(
          const RestoReviewsScreen(
            restoName: 'Toko Prod Nyata',
            domain: 'shop',
            rating: 5.0,
            ratingCount: '0',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Semua (0)'), findsOneWidget);
      expect(find.text('Belum ada ulasan pembeli untuk toko ini.'), findsOneWidget);
      expect(find.text('Dimas Prasetyo'), findsNothing);
    });

    testWidgets('FavoriteRestoScreen respects useDevSeedData=false and displays persisted user favorites', (tester) async {
      GageApiClient.allowDevSeedFallback = false;
      GageApiClient.testHttpClient = MockClient((request) async {
        if (request.url.path == '/api/merchants') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': [
                {
                  'id': 'prod-resto-1',
                  'name': 'Warung Asli Production',
                  'category': 'Masakan Jawa',
                  'domain': 'food',
                  'serviceType': 'food',
                  'rating': 4.9,
                  'distance': '0.7 km',
                  'is_active': true,
                  'is_open': true,
                },
              ],
            }),
            200,
          );
        }
        return http.Response(jsonEncode({'success': true, 'data': []}), 200);
      });

      // Case A: Empty state in production when user has no saved favorites
      await tester.pumpWidget(wrapWithProviders(const FavoriteRestoScreen(key: ValueKey('prod-empty'))));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Resto & Menu Favorit'), findsOneWidget);
      expect(find.text('Belum Ada Resto Favorit'), findsOneWidget);
      expect(find.textContaining('Dimsum Sewu'), findsNothing);

      // Case B: Persisted user favorites appear for both Resto and Menu tabs
      SharedPreferences.setMockInitialValues({
        'fav_resto_prod-resto-1': true,
        'fav_item_prod-menu-1': true,
        'fav_item_meta_prod-menu-1': jsonEncode({
          'id': 'prod-menu-1',
          'name': 'Nasi Pecel Mbak Siti',
          'store': 'Warung Asli Production',
          'storeId': 'prod-resto-1',
          'price': 'Rp 12.000',
          'image': '',
          'domain': 'food',
        }),
      });

      await tester.pumpWidget(wrapWithProviders(const FavoriteRestoScreen(key: ValueKey('prod-populated'))));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Merchant Favorit'), findsOneWidget);
      expect(find.text('Produk Favorit'), findsOneWidget);
      expect(find.text('Warung Asli Production'), findsOneWidget);
      await tester.tap(find.text('Produk Favorit'));
      await tester.pumpAndSettle();
      expect(find.text('Nasi Pecel Mbak Siti'), findsOneWidget);
    });

    testWidgets('Universal Favorites use full-rounded pill segmented switch and omit switch & banner when scoped to open merchant', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Case A: General favorites (unscoped) shows full-rounded capsule red switch
      await tester.pumpWidget(
        wrapWithProviders(
          const ShopFavoriteScreen(
            key: ValueKey('unscoped-shop'),
            domain: 'shop',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Merchant Favorit'), findsOneWidget);
      expect(find.text('Produk Favorit'), findsOneWidget);
      final selectedThumb = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.color == GageTheme.primary &&
            dec.borderRadius == BorderRadius.circular(999);
      });
      expect(selectedThumb, isNotEmpty);

      final pillTrack = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.borderRadius == BorderRadius.circular(999) &&
            dec.color != GageTheme.primary;
      });
      expect(pillTrack, isNotEmpty);

      // Case B: Opened from inside a specific merchant hides segmented switch & status banner, showing only that merchant's items
      await tester.pumpWidget(
        wrapWithProviders(
          const ShopFavoriteScreen(
            key: ValueKey('scoped-shop'),
            domain: 'shop',
            initialTabIndex: 1,
            filterMerchantId: 'shop-berkah-fajar',
            filterMerchantName: 'Toko Sembako Berkah Fajar',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.text('Merchant Favorit'), findsNothing);
      expect(find.text('Produk Favorit'), findsOneWidget);
      expect(find.textContaining('Produk favorit khusus di'), findsNothing);

      expect(find.text('Beras C4 Super Raja Polos 5 Kg'), findsOneWidget);
      expect(find.text('Minyak Goreng Bimoli Klasik 2 Liter'), findsOneWidget);
      expect(find.text('Paket Sayur Sop Komplit + Bumbu Racik'), findsNothing);
    });

    testWidgets('RestoInfoScreen renders live pin map, Foto Lapak, Mon-Sun schedule, and actual buyer reviews', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      GageApiClient.allowDevSeedFallback = false;

      final customSchedule = MerchantOperatingSchedule.defaults(open: '08:00', close: '20:00').copyWith(
        everydaySame: false,
        days: {
          for (final day in MerchantOperatingSchedule.orderedWeekdays)
            day: DayOperatingHours(
              isOpen: day != DateTime.sunday,
              openTime: '08:00',
              closeTime: '20:00',
            ),
        },
      );

      await MerchantStorefrontService.saveStorefront(
        MerchantStorefrontData(
          merchantId: 'prod-resto-info',
          name: 'Kedai Nyata Pracimantoro',
          address: 'Jl. Raya Pracimantoro No. 88',
          logoPhoto: 'assets/images/resto_dimsum_sewu.png',
          locationPhoto: 'assets/images/shop_hero_banner.png',
          latitude: -8.0915,
          longitude: 110.8402,
          schedule: customSchedule,
        ),
      );

      await MerchantStorefrontService.submitBuyerReview(
        merchantId: 'prod-resto-info',
        merchantName: 'Kedai Nyata Pracimantoro',
        domain: 'food',
        userName: 'Rina Kusuma',
        stars: 4,
        comment: 'Porsi pas, cepat sampai.',
        orderedItems: const ['Dimsum Original'],
      );

      await tester.pumpWidget(
        wrapWithProviders(
          const RestoInfoScreen(
            restoName: 'Kedai Nyata Pracimantoro',
            restoImage: 'assets/images/resto_dimsum_sewu.png',
            category: 'Jajanan',
            domain: 'food',
            merchantId: 'prod-resto-info',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      // 1. Live MiniLocationPreviewMap uses merchant profile pin & custom coordinates
      final miniMap = tester.widget<MiniLocationPreviewMap>(find.byType(MiniLocationPreviewMap));
      expect(miniMap.useMerchantPin, isTrue);
      expect(miniMap.markerImagePath, equals('assets/images/resto_dimsum_sewu.png'));
      expect(miniMap.location.latitude, closeTo(-8.0915, 0.0001));
      expect(miniMap.location.longitude, closeTo(110.8402, 0.0001));
      expect(find.byType(MerchantLocationPin), findsWidgets);

      // 2. Redundant Perbesar peta removed; Foto lokasi merchant text button opens photo dialog
      expect(find.text('Perbesar peta'), findsNothing);
      expect(find.text('Foto lokasi merchant ↗'), findsOneWidget);
      expect(find.byType(StorefrontImage), findsWidgets);

      await tester.tap(find.text('Foto lokasi merchant ↗'));
      await tester.pumpAndSettle();
      expect(find.text('Foto Lapak Kedai Nyata Pracimantoro'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // 3. Tapping MiniMap expands full interactive map + Foto Lapak inside modal
      await tester.tap(find.byType(MiniLocationPreviewMap));
      await tester.pumpAndSettle();
      expect(find.text('Buka Rute di Google Maps'), findsOneWidget);
      expect(find.text('Peta Lokasi Kedai Nyata Pracimantoro'), findsOneWidget);
      expect(find.text('Foto Lokasi / Lapak Merchant'), findsOneWidget);
      expect(find.byType(FlutterMap), findsWidgets);
      await tester.tap(find.byIcon(Icons.close_rounded).last);
      await tester.pumpAndSettle();

      // 4. Tapping schedule row opens dynamic Senin-Minggu sheet with Merchant Portal route button
      await tester.tap(find.text('Lihat jadwal Senin - Minggu & kelola di Portal Merchant'));
      await tester.pumpAndSettle();
      expect(find.text('Jam Operasional (Senin - Minggu)'), findsOneWidget);
      expect(find.text('Tutup'), findsOneWidget); // Sunday closed
      expect(find.text('Atur di Portal Merchant'), findsOneWidget);
      Navigator.of(tester.element(find.text('Jam Operasional (Senin - Minggu)'))).pop();
      await tester.pumpAndSettle();

      // 5. Actual buyer rating card is clickable -> opens RestoReviewsScreen
      expect(find.text('1 rating'), findsOneWidget);
      await tester.ensureVisible(find.text('1 rating'));
      await tester.tap(find.text('1 rating'));
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();

      expect(find.byType(RestoReviewsScreen), findsOneWidget);
      expect(find.text('Rina Kusuma'), findsOneWidget);
      expect(find.text('4.0'), findsWidgets);
    });

    testWidgets('CheckoutScreen places Voucher above Metode Pembayaran and Driver Tip at bottom', (tester) async {
      tester.view.physicalSize = const Size(1080, 3200);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.setIsPickup(false);
      cart.addItem(
        CartItemModel(
          menuId: 'm-chk-1',
          merchantId: 'mch-dimsum-01',
          merchantName: 'Dimsum Sewu Pracimantoro',
          name: 'Dimsum Ayam Original',
          price: 20000,
          quantity: 1,
          category: 'Dimsum',
          serviceType: 'food',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider<BannerManagerService>.value(value: BannerManagerService.instance),
            ChangeNotifierProvider<LanguageProvider>(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final voucherFinder = find.text('Voucher').first;
      final metodeFinder = find.text('Metode Pembayaran').first;
      final summaryFinder = find.text('Ringkasan pembayaran').first;
      final tipFinder = find.text('Beri Tip untuk Driver?').first;

      await tester.scrollUntilVisible(tipFinder, 250.0, scrollable: find.byType(Scrollable).first);
      await tester.pump();

      // Re-verify vertical order in ListView by ensuring each target or measuring offsets after scrolling back up/down
      await tester.scrollUntilVisible(summaryFinder, -250.0, scrollable: find.byType(Scrollable).first);
      await tester.pump();

      final summaryY = tester.getTopLeft(summaryFinder).dy;
      final voucherY = tester.getTopLeft(voucherFinder).dy;
      final metodeY = tester.getTopLeft(metodeFinder).dy;
      expect(summaryY, lessThan(voucherY));
      expect(voucherY, lessThan(metodeY));

      await tester.scrollUntilVisible(tipFinder, 250.0, scrollable: find.byType(Scrollable).first);
      await tester.pump();
      final tipY = tester.getTopLeft(tipFinder).dy;
      // Tip card must be below Metode Pembayaran when scrolled to the bottom
      expect(tipY, greaterThan(0));
      if (metodeFinder.evaluate().isNotEmpty) {
        expect(tipY, greaterThan(tester.getTopLeft(metodeFinder).dy));
      }
    });
  });
}
