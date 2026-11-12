import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/chat/presentation/chat_hub_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_chat_list_screen.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_home_header.dart';
import 'package:gage_app/features/home/presentation/widgets/home_merchant_showcase_section.dart';
import 'package:gage_app/features/merchant/presentation/merchant_chat_list_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/features/notification/presentation/notification_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/gage_merchant_slider_card.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await NotificationService.instance.resetForTest();
  });

  group('1. GAGE Food Merchant Isolation Filter', () {
    test('filterFoodMerchants retains food merchants and removes Shop, Farm, Build, and Babe', () {
      final mixedApiRows = <Map<String, dynamic>>[
        {
          'id': 'm-dimsum-sewu',
          'name': 'Dimsum Sewu by Halu Goods',
          'category': 'Kuliner Dimsum',
        },
        {
          'id': 'mch-rc-01',
          'name': 'Rocket Chicken Sambiroto, Pracimantoro',
          'category': 'Ayam Goreng Krispi & Aneka Burger',
        },
        {
          'id': 'mch-martabak-custom',
          'name': 'Martabak Telur Special Mas Anton',
          'category': 'Martabak, Terang Bulan & Jajanan Malam',
        },
        {
          'id': 'shop-berkah-fajar',
          'name': 'Toko Sembako Berkah Fajar',
          'category': 'Sembako, Beras & Minyak Goreng',
        },
        {
          'id': 'farm-kios-subur',
          'name': 'Kios Tani Subur Makmur',
          'category': 'Pupuk NPK & Urea, Benih Padi & Sayur',
        },
        {
          'id': 'build-sumber-abadi',
          'name': 'Toko Besi & Bangunan Sumber Abadi',
          'category': 'Semen, Besi Beton, Cat & Pipa PVC',
        },
        {
          'id': 'custom-unknown-id',
          'name': 'TB Sinar Mulia Pracimantoro',
          'category': 'Baja Ringan, Genteng Metal & Pasir',
        },
        {
          'id': 'custom-explicit-shop',
          'name': 'Depot Air & Galon Sejahtera',
          'category': 'Air Minum',
          'serviceType': 'shop',
        },
      ];

      final foodOnly = GageApiClient.filterFoodMerchants(mixedApiRows);
      final ids = foodOnly.map((m) => m['id']).toList();

      expect(ids, equals(['m-dimsum-sewu', 'mch-rc-01', 'mch-martabak-custom']));
      expect(ids, isNot(contains('shop-berkah-fajar')));
      expect(ids, isNot(contains('farm-kios-subur')));
      expect(ids, isNot(contains('build-sumber-abadi')));
      expect(ids, isNot(contains('custom-unknown-id')));
      expect(ids, isNot(contains('custom-explicit-shop')));
    });

    testWidgets('HomeMerchantShowcaseSection Food section hides leaked non-food stores', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: HomeMerchantShowcaseSection(
                isLoading: false,
                foodMerchants: [
                  {
                    'id': 'build-sumber-abadi',
                    'name': 'Toko Besi & Bangunan Sumber Abadi',
                    'category': 'Semen, Besi Beton, Cat & Pipa PVC',
                  },
                  {
                    'id': 'farm-kios-subur',
                    'name': 'Kios Tani Subur Makmur',
                    'category': 'Pupuk NPK & Urea, Benih Padi & Sayur',
                  },
                  {
                    'id': 'shop-telur-jaya',
                    'name': 'Agen Telur & Sembako Jaya',
                    'category': 'Telur Ayam Ras, Gula Pasir & Tepung',
                  },
                  {
                    'id': 'mch-rc-01',
                    'name': 'Rocket Chicken Sambiroto, Pracimantoro',
                    'category': 'Ayam Goreng Krispi',
                  },
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure the Food section (top section) renders Rocket Chicken, while leaked rows
      // passed via foodMerchants (note: shop-telur-jaya only exists in static Shop if listed separately)
      // Specifically Kios Tani Subur Makmur & Sumber Abadi only appear in Farm/Build sections cleanly
      // Assert the first horizontal ListView (Resto Kuliner Pilihan) contains ONLY Rocket Chicken
      final foodListFinder = find.byType(ListView).first;
      final cardFinders = find.descendant(
        of: foodListFinder,
        matching: find.byType(GageMerchantSliderCard),
      );
      final cards = tester.widgetList<GageMerchantSliderCard>(cardFinders).toList();
      expect(cards.length, equals(1));
      expect(cards.single.id, equals('mch-rc-01'));
      expect(cards.single.name, equals('Rocket Chicken Sambiroto, Pracimantoro'));
    });
  });

  group('2. Auto-Apply Gratis Ongkir When Conditions Are Met', () {
    test('GageVoucherData.bestEligibleDeliveryVoucher picks best eligible delivery voucher per service', () {
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'food', subtotal: 15000), isNull);
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'food', subtotal: 20000)?['code'], equals('ONGKIR5RB'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'food', subtotal: 25000)?['code'], equals('ONGKIRGRATIS'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'shop', subtotal: 20000)?['code'], equals('ONGKIRFREE-SHOP'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'farm', subtotal: 25000)?['code'], equals('ONGKIRFREE-FARM'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'build', subtotal: 50000)?['code'], equals('ONGKIRFREE-BUILD'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'send', subtotal: 10000)?['code'], equals('GAGERATIH'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'send', subtotal: 12000)?['code'], equals('KIRIMKILAT'));
      expect(GageVoucherData.bestEligibleDeliveryVoucher(serviceType: 'ride', subtotal: 20000), isNull);
    });

    testWidgets('CheckoutScreen auto-applies free shipping on open, upgrades on qty increase, clears below minOrder or pickup, and respects manual close', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'm1',
          merchantId: 'mch-rc-01',
          merchantName: 'Rocket Chicken',
          name: 'Ayam Crispy',
          price: 15000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Subtotal 15.000 < 20.000 -> no delivery voucher auto-applied yet
      expect(cart.deliveryPromoCode, isNull);

      // Add quantity -> 30.000 >= 25.000 -> ONGKIRGRATIS (7000) auto-applied!
      cart.updateQuantity('m1', 1);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));
      expect(cart.deliveryPromoDiscount, equals(7000));
      expect(cart.totalShippingDiscount, greaterThan(0));

      // Switch to Pickup -> delivery promo cleared; switch back -> restored!
      cart.setIsPickup(true);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, isNull);
      expect(cart.finalShippingFee, equals(0));

      cart.setIsPickup(false);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));

      // Drop below minimum order -> automatically un-applies
      cart.updateQuantity('m1', -1);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, isNull);

      // Re-meet condition, then manually dismiss -> stays dismissed on quantity updates
      cart.updateQuantity('m1', 1);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));

      cart.removeDeliveryPromo();
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, isNull);

      cart.updateQuantity('m1', 1);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, isNull);
    });

    testWidgets('RideCheckoutScreen (GAGE Send) auto-applies best eligible delivery voucher and adapts across tiers', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: RideCheckoutScreen(
              serviceType: 'send',
              rideOption: 'INSTANT',
              pickupLocation: LatLng(-8.089, 110.837),
              dropoffLocation: LatLng(-8.095, 110.845),
              pickupAddress: 'Titik Jemput',
              dropoffAddress: 'Titik Antar',
              distanceKm: 2.5,
              baseFare: 12500,
              recipientName: 'Budi',
              recipientPhone: '081234567890',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Send Instant at 2.5 km = Rp 12.500 >= 12.000 -> auto-applied KIRIMKILAT with simplified '-5RB' badge
      expect(find.textContaining('KIRIMKILAT'), findsWidgets);
      expect(find.text('-5RB'), findsOneWidget);
      expect(find.textContaining('KIRIMKILAT (-Rp'), findsNothing);

      // Switch tier to Hemat (at 2.5 km = 8000 + 2000 = Rp 10.000 -> < 12000, >= 5000)
      // Automatically switches to GAGERATIH with simplified '-2RB' badge
      final hematTier = find.text('Hemat').first;
      await tester.ensureVisible(hematTier);
      await tester.tap(hematTier);
      await tester.pumpAndSettle();

      expect(find.textContaining('GAGERATIH'), findsWidgets);
      expect(find.text('-2RB'), findsOneWidget);

      // Tap inline 'x' close icon directly inside the installed GAGERATIH badge
      final rideCloseBadge = find.byIcon(Icons.close_rounded).first;
      await tester.ensureVisible(rideCloseBadge);
      await tester.tap(rideCloseBadge);
      await tester.pumpAndSettle();
      expect(find.textContaining('GAGERATIH'), findsNothing);

      // Open VoucherSelectionScreen at Hemat Rp 10.000:
      // - KIRIMKILAT (min 12.000) must be disabled and NOT selectable
      // - GAGERATIH (min 5.000) must be enabled and selectable while staying on screen
      await tester.tap(find.text('Gunakan / masukkan kode'));
      await tester.pumpAndSettle();
      expect(find.byType(VoucherSelectionScreen), findsOneWidget);

      final pakaiButtons = find.widgetWithText(ElevatedButton, 'Pakai');
      expect(pakaiButtons, findsNWidgets(2));
      final firstBtn = tester.widget<ElevatedButton>(pakaiButtons.first);
      expect(firstBtn.onPressed, isNull); // KIRIMKILAT disabled below minOrder 12.000

      await tester.tap(pakaiButtons.last); // GAGERATIH enabled (>= 5.000)
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(VoucherSelectionScreen), findsOneWidget);
      expect(find.text('Terpasang'), findsOneWidget);

      // Navigate back and confirm RideCheckoutScreen shows simplified '-2RB' badge
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(VoucherSelectionScreen), findsNothing);
      expect(find.textContaining('GAGERATIH'), findsWidgets);
      expect(find.text('-2RB'), findsOneWidget);
    });

    testWidgets('CheckoutScreen inline badge close removes only that badge and VoucherSelectionScreen stays open on select', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'f1',
          merchantId: 'mch-rc-01',
          merchantName: 'Rocket Chicken',
          name: 'Paket Keluarga',
          price: 30000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );
      cart.setFoodPromo('DISKON50', 15000);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider(create: (_) => WalletProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Both Diskon Ongkir (auto) and -15RB (food) badges have their own inline 'x' icon
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));
      expect(cart.foodPromoCode, equals('DISKON50'));
      final closeIcons = find.byIcon(Icons.close_rounded);
      expect(closeIcons, findsNWidgets(2));

      // Remove only the Diskon Ongkir badge via its inline 'x'; DISKON50 remains untouched
      await tester.ensureVisible(closeIcons.first);
      await tester.tap(closeIcons.first);
      await tester.pumpAndSettle();
      expect(cart.deliveryPromoCode, isNull);
      expect(cart.foodPromoCode, equals('DISKON50'));
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);

      // Open VoucherSelectionScreen -> tap 'Pakai' on ONGKIRGRATIS -> stays on VoucherSelectionScreen
      await tester.tap(find.text('Voucher').last);
      await tester.pumpAndSettle();
      expect(find.byType(VoucherSelectionScreen), findsOneWidget);

      await tester.tap(find.text('Gratis Ongkir'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ElevatedButton, 'Pakai').first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      expect(find.byType(VoucherSelectionScreen), findsOneWidget);
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));
    });
  });

  group('3. Promo, Notification, and Chat Badges Lifecycle', () {
    testWidgets('PromoScreen clears bottom nav Promo badge and new voucher re-triggers it', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      expect(NotificationService.instance.unreadPromoCount, equals(1));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: GageBottomNavBar(currentIndex: 0),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before opening Promo, both Pesanan ('1') and Promo ('1') badges appear
      expect(find.text('1'), findsNWidgets(2));

      // Open PromoScreen
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: PromoScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Opening PromoScreen must clear unreadPromoCount to 0 -> Promo badge disappears immediately!
      expect(NotificationService.instance.unreadPromoCount, equals(0));
      // Only Pesanan active order ('1') remains on GageBottomNavBar
      expect(
        find.descendant(of: find.byType(GageBottomNavBar), matching: find.text('1')),
        findsOneWidget,
      );

      // Simulate new voucher arriving
      await NotificationService.instance.notifyNewVoucher(
        code: 'VOUCHERBARU',
        title: 'Diskon 30% s.d 10RB',
      );
      await tester.pumpAndSettle();

      expect(NotificationService.instance.unreadPromoCount, equals(1));
      expect(
        find.descendant(of: find.byType(GageBottomNavBar), matching: find.text('1')),
        findsNWidgets(2),
      );
    });

    testWidgets('GageHomeHeader bell and chat badges clear when viewing NotificationScreen and reading ChatHubScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      expect(NotificationService.instance.unreadChatCount, equals(2));
      expect(NotificationService.instance.unreadCount, equals(3));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => BannerManagerService()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(body: GageHomeHeader()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Open NotificationScreen -> bell unread count clears to 0 immediately
      await tester.tap(find.byIcon(Icons.notifications_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(NotificationScreen), findsOneWidget);
      expect(NotificationService.instance.unreadCount, equals(0));

      // Pop back to Home Header -> bell badge '3' is gone while chat badge '2' remains
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('3'), findsNothing);
      expect(find.text('2'), findsOneWidget);

      // Open ChatHubScreen and mark chats read
      await tester.tap(find.byIcon(Icons.chat_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(ChatHubScreen), findsOneWidget);

      await tester.tap(find.text('Tandai Dibaca'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(NotificationService.instance.unreadChatCount, equals(0));

      // Pop back to Home Header -> chat badge '2' is gone too
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pumpAndSettle();
      expect(find.text('2'), findsNothing);
    });

    testWidgets('Driver and Merchant bottom nav Pesan badges reactively clear after opening chats', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DriverChatListScreen(showBottomNav: true),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(NotificationService.instance.unreadDriverChatCount, equals(1));
      expect(find.byType(DriverBottomNavBar), findsOneWidget);

      await NotificationService.instance.markDriverChatAsRead('drv-ORD-88219-customer');
      await tester.pumpAndSettle();
      expect(NotificationService.instance.unreadDriverChatCount, equals(0));

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MerchantChatListScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(NotificationService.instance.unreadMerchantChatCount, equals(1));
      expect(find.byType(MerchantBottomNavBar), findsOneWidget);

      await NotificationService.instance.markMerchantChatAsRead('mch-ORD-9021-driver');
      await tester.pumpAndSettle();
      expect(NotificationService.instance.unreadMerchantChatCount, equals(0));
    });
  });

  group('4. Dual Auto-Apply Consistency, Strict Eligibility & Transport Badge Format', () {
    testWidgets('SeamlessFloatingCartBar syncs real GageVoucherData promos matching Checkout and VoucherSelectionScreen 1:1', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'm-sync-1',
          merchantId: 'food-warung-1',
          merchantName: 'Warung Bakso Praci',
          name: 'Bakso Jumbo Spesial',
          price: 15000,
          quantity: 2,
          serviceType: 'food',
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  SizedBox.expand(),
                  Positioned(left: 0, right: 0, bottom: 0, child: SeamlessFloatingCartBar()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Must auto-apply real Food catalog vouchers, never fake GAGEHEMAT / GAGEPROMO10
      expect(cart.foodPromoCode, equals('DISKON50'));
      expect(cart.foodPromoDiscount, equals(15000));
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));
      expect(cart.deliveryPromoDiscount, equals(7000));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('-15RB'));
      expect(find.text('Diskon Ongkir'), findsWidgets);
      expect(find.text('-15RB'), findsOneWidget);

      final voucherRowFinder = find.text('Voucher').last;
      await tester.ensureVisible(voucherRowFinder);
      await tester.tap(voucherRowFinder);
      await tester.pumpAndSettle();
      expect(find.byType(VoucherSelectionScreen), findsOneWidget);

      // Both auto-applied vouchers show Terpasang inside VoucherSelectionScreen
      expect(find.text('Terpasang'), findsNWidgets(2));

      // Pop back, dismiss -15RB via inline 'x', then verify SeamlessFloatingCartBar respects dismissal
      await tester.pageBack();
      await tester.pumpAndSettle();

      final minus15Pill = find.ancestor(of: find.text('-15RB'), matching: find.byType(Container)).first;
      final close15Icon = find.descendant(of: minus15Pill, matching: find.byIcon(Icons.close_rounded)).first;
      await tester.ensureVisible(close15Icon);
      await tester.tap(close15Icon);
      await tester.pumpAndSettle();

      expect(cart.foodPromoCode, isNull);
      expect(cart.deliveryPromoCode, equals('ONGKIRGRATIS'));

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>.value(value: cart),
          ],
          child: const MaterialApp(
            home: Scaffold(body: SeamlessFloatingCartBar()),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(cart.foodPromoCode, isNull);
    });

    testWidgets('VoucherSelectionScreen blocks ineligible higher minOrder vouchers via tap and claim sheet across Food & Car', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // 1. Food cart subtotal Rp 25.000: DISKON50 (min 20k) eligible; KULINER20 (min 50k) blocked
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'm-elig-1',
          merchantId: 'food-01',
          merchantName: 'Warung Praci',
          name: 'Mie Ayam',
          price: 25000,
          quantity: 1,
          serviceType: 'food',
        ),
      );
      cart.syncAutoPromos(serviceType: 'food', notify: false);
      expect(cart.foodPromoCode, equals('DISKON50'));
      expect(cart.foodPromoDiscount, equals(12500));

      await tester.pumpWidget(
        MultiProvider(
          providers: [ChangeNotifierProvider<CartProvider>.value(value: cart)],
          child: const MaterialApp(
            home: VoucherSelectionScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // KULINER20 should show shortage reason and disabled 'Pakai'
      expect(find.textContaining('Min. Rp50.000 (kurang Rp25.000)'), findsOneWidget);
      final kulinerCard = find.byWidgetPredicate(
        (w) => w.runtimeType.toString() == 'GageTicketVoucherCard',
      );
      expect(kulinerCard, findsWidgets);

      // Tapping KULINER20 disabled 'Pakai' does not change foodPromoCode
      final pakaiBtn = find.widgetWithText(ElevatedButton, 'Pakai').first;
      expect(tester.widget<ElevatedButton>(pakaiBtn).onPressed, isNull);
      await tester.tap(pakaiBtn);
      await tester.pumpAndSettle();
      expect(cart.foodPromoCode, equals('DISKON50'));

      // Claiming KULINER20 manually by code also rejects and shows error toast
      await tester.tap(find.text('Masukkan kode promo'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'KULINER20');
      await tester.tap(find.text('Terapkan Voucher'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      expect(cart.foodPromoCode, equals('DISKON50'));

      // 2. GAGE Car checkout at Rp 22.000: GAGECAR15 (min 30k) disabled; PRACICAR (min 20k) -> '-3RB' badge
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
            ChangeNotifierProvider<CartProvider>.value(value: cart),
          ],
          child: const MaterialApp(
            home: RideCheckoutScreen(
              serviceType: 'car',
              rideOption: 'HEMAT',
              pickupLocation: LatLng(-8.089, 110.837),
              dropoffLocation: LatLng(-8.095, 110.845),
              pickupAddress: 'Pasar Pracimantoro',
              dropoffAddress: 'Terminal Pracimantoro',
              distanceKm: 4.0,
              baseFare: 22000,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Gunakan / masukkan kode'));
      await tester.pumpAndSettle();

      final carPakaiButtons = find.widgetWithText(ElevatedButton, 'Pakai');
      expect(carPakaiButtons, findsNWidgets(2));
      expect(tester.widget<ElevatedButton>(carPakaiButtons.first).onPressed, isNull); // GAGECAR15 disabled
      expect(tester.widget<ElevatedButton>(carPakaiButtons.last).onPressed, isNotNull); // PRACICAR enabled

      await tester.tap(carPakaiButtons.last);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Terpasang'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('-3RB'), findsOneWidget);
      expect(find.textContaining('PRACICAR (-Rp'), findsNothing);
    });
  });
}
