import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget buildVoucherTestHarness({
    required CartProvider cart,
    String? serviceType,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: cart),
      ],
      child: MaterialApp(
        home: VoucherSelectionScreen(serviceType: serviceType),
      ),
    );
  }

  Widget buildCheckoutTestHarness({
    required CartProvider cart,
    String? serviceType,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<CartProvider>.value(value: cart),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
      ],
      child: MaterialApp(
        home: CheckoutScreen(serviceType: serviceType),
      ),
    );
  }

  group('Adversarial 1: Case Sensitivity and Whitespace in serviceType', () {
    testWidgets('Uppercase FOOD and padded whitespace "  food  " normalize to Food', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      // Uppercase test
      final cart1 = CartProvider();
      await tester.pumpWidget(buildVoucherTestHarness(cart: cart1, serviceType: 'FOOD'));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Food'), findsOneWidget);
      expect(find.text('DISKON50'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);

      // Padded whitespace test
      final cart2 = CartProvider();
      await tester.pumpWidget(buildVoucherTestHarness(cart: cart2, serviceType: '   food   '));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Food'), findsOneWidget);
      expect(find.text('DISKON50'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsNothing);
    });

    testWidgets('Uppercase FARM and mixed case "  FaRm  " normalize to Farm', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: '  FaRm  '));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Farm'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsOneWidget);
      expect(find.text('PETANISUKSES'), findsOneWidget);
      expect(find.text('ONGKIRFREE-FARM'), findsOneWidget);

      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
    });

    testWidgets('Mixed case "Shop" and whitespace padded "  sHoP  " normalize to Shop', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: '  sHoP  '));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Shop'), findsOneWidget);
      expect(find.text('BELANJAHEMAT'), findsOneWidget);
      expect(find.text('SEMBAKOMURAH'), findsOneWidget);
      expect(find.text('BELANJAMART'), findsNothing);
      expect(find.text('ONGKIRFREE-SHOP'), findsOneWidget);

      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
    });

    testWidgets('Uppercase BUILD and padded "  bUiLd  " normalize to Build', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: '  bUiLd  '));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Build'), findsOneWidget);
      expect(find.text('PROYEKHEMAT'), findsOneWidget);
      expect(find.text('BANGUNRUMAH'), findsOneWidget);
      expect(find.text('ONGKIRFREE-BUILD'), findsOneWidget);

      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
    });
  });

  group('Adversarial 2: Fallback Behavior for Null or Empty serviceType', () {
    testWidgets('Null serviceType and empty cart defaults safely to Food', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      expect(cart.items.isEmpty, isTrue);
      expect(cart.primaryServiceType, equals('food'));

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: null));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Food'), findsOneWidget);
      expect(find.text('DISKON50'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
    });

    testWidgets('Whitespace-only serviceType "   " falls back to CartProvider primaryServiceType', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'farm-02',
          merchantId: 'm-farm-02',
          merchantName: 'Tani Sejahtera',
          name: 'Bibit Jagung Manis 1kg',
          price: 45000,
          quantity: 1,
          category: 'Bibit',
          serviceType: 'farm',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: '   '));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Farm'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsOneWidget);
      expect(find.text('DISKON50'), findsNothing);
    });

    testWidgets('Null serviceType with Shop cart items falls back to Shop', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'shop-01',
          merchantId: 'm-shop-01',
          merchantName: 'Toko Sembako Berkah',
          name: 'Minyak Goreng 2L',
          price: 34000,
          quantity: 1,
          category: 'Sembako',
          serviceType: 'shop',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: null));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Shop'), findsOneWidget);
      expect(find.text('BELANJAHEMAT'), findsOneWidget);
      expect(find.text('DISKON50'), findsNothing);
    });

    testWidgets('Null serviceType with Build cart items falls back to Build', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'build-01',
          merchantId: 'm-build-01',
          merchantName: 'TB Aneka Bangunan',
          name: 'Cat Tembok 5kg',
          price: 85000,
          quantity: 1,
          category: 'Cat',
          serviceType: 'build',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: null));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Voucher GAGE Build'), findsOneWidget);
      expect(find.text('PROYEKHEMAT'), findsOneWidget);
      expect(find.text('DISKON50'), findsNothing);
    });
  });

  group('Adversarial 3: Boundaries on Discount Calculation', () {
    test('Subtotal is strictly less than order discount amount', () {
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'item-small',
          merchantId: 'm-01',
          merchantName: 'Warung Kecil',
          name: 'Krupuk Kaleng',
          price: 5000,
          quantity: 1,
          category: 'Snack',
          serviceType: 'food',
        ),
      );

      expect(cart.subtotal, equals(5000));
      final baseShipping = cart.finalShippingFee;
      final baseAdmin = cart.adminFee;

      // Apply massive discount (25000) on a 5000 subtotal
      cart.setFoodPromo('HUGEPROMO', 25000);

      // Total food discount must be clamped to subtotal (5000)
      expect(cart.totalFoodDiscount, equals(5000));
      // Net food subtotal must be 0, never negative
      expect(cart.subtotal - cart.totalFoodDiscount, equals(0));
      // Grand total must equal 0 + shipping + admin
      expect(cart.grandTotal, equals(0 + baseShipping + baseAdmin));
      expect(cart.grandTotal, greaterThan(0));
    });

    test('Shipping fee is strictly less than delivery discount amount', () {
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'item-01',
          merchantId: 'm-01',
          merchantName: 'Warung Makan',
          name: 'Nasi Rames',
          price: 25000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );

      final rawShipping = cart.rawShippingFee;
      expect(rawShipping, greaterThan(0));

      // Apply oversized delivery discount (50000)
      cart.setDeliveryPromo('OVERSIZED-ONGKIR', 50000);

      // Shipping discount must be clamped to rawShippingFee
      expect(cart.totalShippingDiscount, equals(rawShipping));
      // Final shipping fee must be 0, never negative
      expect(cart.finalShippingFee, equals(0));
      // Grand total must be subtotal + 0 + adminFee
      expect(cart.grandTotal, equals(cart.subtotal + 0 + cart.adminFee));
    });

    test('Simultaneous over-discounting on both subtotal and delivery fee', () {
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'item-01',
          merchantId: 'm-01',
          merchantName: 'Warung Mini',
          name: 'Es Teh Manis',
          price: 3000,
          quantity: 1,
          category: 'Minuman',
          serviceType: 'food',
        ),
      );

      // Subtotal: 3000
      cart.setFoodPromo('MEGAFOOD', 100000);
      // Raw shipping: ~9000 or 12000
      cart.setDeliveryPromo('MEGASHIP', 100000);

      expect(cart.totalFoodDiscount, equals(3000));
      expect(cart.totalShippingDiscount, equals(cart.rawShippingFee));
      expect(cart.finalShippingFee, equals(0));
      expect(cart.grandTotal, equals(cart.adminFee));
    });

    test('Pickup mode neutralizes delivery discount cleanly', () {
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'item-01',
          merchantId: 'm-01',
          merchantName: 'Warung',
          name: 'Sate Ayam',
          price: 20000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );

      cart.setIsPickup(true);
      expect(cart.finalShippingFee, equals(0));

      cart.setDeliveryPromo('ONGKIRGRATIS', 7000);
      expect(cart.finalShippingFee, equals(0));
      expect(cart.grandTotal, equals(20000 + cart.adminFee));
    });
  });

  group('Adversarial 4: Transport Vouchers Isolation from Merchant Checkouts', () {
    test('GageVoucherData transport vouchers inventory check', () {
      final rideVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Ride')
          .map((v) => v['code'])
          .toList();
      final carVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Car')
          .map((v) => v['code'])
          .toList();
      final sendVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Send')
          .map((v) => v['code'])
          .toList();

      expect(rideVouchers, containsAll(['RIDEHEMAT', 'GAGEHEMAT']));
      expect(carVouchers, containsAll(['GAGECAR15', 'PRACICAR']));
      expect(sendVouchers, containsAll(['KIRIMKILAT', 'GAGERATIH']));
    });

    testWidgets('Food Checkout: Transport codes cannot be claimed via promo sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'f-01',
          merchantId: 'm-01',
          merchantName: 'Resto',
          name: 'Nasi Goreng',
          price: 25000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: 'food'));
      await tester.pumpAndSettle();

      // Ensure no transport voucher text is in the list
      expect(find.text('RIDEHEMAT'), findsNothing);
      expect(find.text('GAGECAR15'), findsNothing);
      expect(find.text('KIRIMKILAT'), findsNothing);

      // Open Klaim Kode Promo sheet via input bar
      final claimInputBar = find.text('Masukkan kode promo');
      expect(claimInputBar, findsOneWidget);
      await tester.tap(claimInputBar);
      await tester.pumpAndSettle();

      // Enter RIDEHEMAT
      final inputField = find.byType(TextField);
      expect(inputField, findsOneWidget);
      await tester.enterText(inputField, 'RIDEHEMAT');

      // Tap Terapkan Voucher
      final terapkanButton = find.text('Terapkan Voucher');
      await tester.tap(terapkanButton);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // Cart promo should NOT be set
      expect(cart.foodPromoCode, isNull);
      expect(cart.deliveryPromoCode, isNull);
      expect(cart.totalFoodDiscount, equals(0));
    });

    testWidgets('Farm Checkout: GAGECAR15 and KIRIMKILAT cannot be claimed via promo sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'farm-01',
          merchantId: 'm-farm-01',
          merchantName: 'Toko Tani',
          name: 'Pupuk 10kg',
          price: 50000,
          quantity: 1,
          category: 'Pupuk',
          serviceType: 'farm',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: 'farm'));
      await tester.pumpAndSettle();

      // Open Klaim sheet
      await tester.tap(find.text('Masukkan kode promo'));
      await tester.pumpAndSettle();

      // Enter GAGECAR15
      await tester.enterText(find.byType(TextField), 'GAGECAR15');
      await tester.tap(find.text('Terapkan Voucher'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // Cart promo remains untouched
      expect(cart.foodPromoCode, isNull);
      expect(cart.deliveryPromoCode, isNull);
    });

    testWidgets('Build Checkout: Food vouchers (DISKON50) cannot be claimed via promo sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'build-01',
          merchantId: 'm-build-01',
          merchantName: 'TB Sejahtera',
          name: 'Semen 50kg',
          price: 70000,
          quantity: 1,
          category: 'Semen',
          serviceType: 'build',
        ),
      );

      await tester.pumpWidget(buildVoucherTestHarness(cart: cart, serviceType: 'build'));
      await tester.pumpAndSettle();

      // Open Klaim sheet
      await tester.tap(find.text('Masukkan kode promo'));
      await tester.pumpAndSettle();

      // Try entering Food voucher code DISKON50
      await tester.enterText(find.byType(TextField), 'DISKON50');
      await tester.tap(find.text('Terapkan Voucher'));
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // Cart promo remains untouched
      expect(cart.foodPromoCode, isNull);
      expect(cart.deliveryPromoCode, isNull);
    });
  });

  group('Adversarial 5: CheckoutScreen Navigation Propagation', () {
    testWidgets('CheckoutScreen with serviceType "farm" propagates "farm" to VoucherSelectionScreen', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.setPaymentMethod('CASH_COD');
      cart.addItem(
        CartItemModel(
          menuId: 'farm-01',
          merchantId: 'm-farm-01',
          merchantName: 'Kios Tani Sejati',
          name: 'Benih Jagung Hibrida 1kg',
          price: 45000,
          quantity: 1,
          category: 'Benih',
          serviceType: 'farm',
        ),
      );

      await tester.pumpWidget(buildCheckoutTestHarness(cart: cart, serviceType: 'farm'));
      await tester.pumpAndSettle();

      // Find the voucher selection tile on CheckoutScreen and scroll into view
      final voucherFinder = find.byIcon(Icons.confirmation_number_rounded);
      final scrollableFinder = find.byType(Scrollable).first;
      await tester.scrollUntilVisible(voucherFinder, 500, scrollable: scrollableFinder);
      await tester.pumpAndSettle();

      expect(voucherFinder, findsOneWidget);
      await tester.tap(voucherFinder);
      await tester.pumpAndSettle();

      // Pushed screen must be VoucherSelectionScreen with Farm title and vouchers
      expect(find.text('Pilih Voucher GAGE Farm'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsOneWidget);
      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
    });
  });
}
