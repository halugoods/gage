import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/voucher/presentation/voucher_selection_screen.dart';
import 'package:gage_app/providers/cart_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Master Mock Voucher Data Inventory', () {
    test('GAGE Shop vouchers exist with exact specifications', () {
      final shopVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Shop')
          .toList();

      expect(shopVouchers.length, greaterThanOrEqualTo(3));

      final belanjaHemat = shopVouchers.firstWhere((v) => v['code'] == 'BELANJAHEMAT');
      expect(belanjaHemat['title'], equals('Diskon 8RB'));
      expect(belanjaHemat['type'], equals('order'));
      expect(belanjaHemat['minOrder'], equals(25000));
      expect(belanjaHemat['discountAmount'], equals(8000));

      final sembakoMurah = shopVouchers.firstWhere((v) => v['code'] == 'SEMBAKOMURAH');
      expect(sembakoMurah['title'], equals('Diskon 10RB'));
      expect(sembakoMurah['type'], equals('order'));
      expect(sembakoMurah['minOrder'], equals(40000));
      expect(sembakoMurah['discountAmount'], equals(10000));

      final ongkirShop = shopVouchers.firstWhere((v) => v['code'] == 'ONGKIRFREE-SHOP');
      expect(ongkirShop['title'], equals('Gratis Ongkir s.d 7RB'));
      expect(ongkirShop['type'], equals('delivery'));
      expect(ongkirShop['minOrder'], equals(20000));
      expect(ongkirShop['discountAmount'], equals(7000));
    });

    test('GAGE Farm vouchers exist with exact specifications', () {
      final farmVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Farm')
          .toList();

      expect(farmVouchers.length, greaterThanOrEqualTo(3));

      final subsidiTani = farmVouchers.firstWhere((v) => v['code'] == 'SUBSIDITANI');
      expect(subsidiTani['title'], equals('Diskon 10RB'));
      expect(subsidiTani['type'], equals('order'));
      expect(subsidiTani['minOrder'], equals(30000));
      expect(subsidiTani['discountAmount'], equals(10000));

      final petaniSukses = farmVouchers.firstWhere((v) => v['code'] == 'PETANISUKSES');
      expect(petaniSukses['title'], equals('Diskon 15RB'));
      expect(petaniSukses['type'], equals('order'));
      expect(petaniSukses['minOrder'], equals(50000));
      expect(petaniSukses['discountAmount'], equals(15000));

      final ongkirFarm = farmVouchers.firstWhere((v) => v['code'] == 'ONGKIRFREE-FARM');
      expect(ongkirFarm['title'], equals('Gratis Ongkir s.d 7RB'));
      expect(ongkirFarm['type'], equals('delivery'));
      expect(ongkirFarm['minOrder'], equals(25000));
      expect(ongkirFarm['discountAmount'], equals(7000));
    });

    test('GAGE Build vouchers exist with exact specifications', () {
      final buildVouchers = GageVoucherData.allVouchers
          .where((v) => v['service'] == 'GAGE Build')
          .toList();

      expect(buildVouchers.length, greaterThanOrEqualTo(3));

      final proyekHemat = buildVouchers.firstWhere((v) => v['code'] == 'PROYEKHEMAT');
      expect(proyekHemat['title'], equals('Diskon 15RB'));
      expect(proyekHemat['type'], equals('order'));
      expect(proyekHemat['minOrder'], equals(50000));
      expect(proyekHemat['discountAmount'], equals(15000));

      final bangunRumah = buildVouchers.firstWhere((v) => v['code'] == 'BANGUNRUMAH');
      expect(bangunRumah['title'], equals('Diskon 25RB'));
      expect(bangunRumah['type'], equals('order'));
      expect(bangunRumah['minOrder'], equals(100000));
      expect(bangunRumah['discountAmount'], equals(25000));

      final ongkirBuild = buildVouchers.firstWhere((v) => v['code'] == 'ONGKIRFREE-BUILD');
      expect(ongkirBuild['title'], equals('Gratis Ongkir s.d 10RB'));
      expect(ongkirBuild['type'], equals('delivery'));
      expect(ongkirBuild['minOrder'], equals(50000));
      expect(ongkirBuild['discountAmount'], equals(10000));
    });
  });

  Widget createTestWidget({
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

  group('2. VoucherSelectionScreen Filtering by Active Service', () {
    testWidgets('Food Checkout: only Food vouchers appear, others are excluded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'food'));
      await tester.pumpAndSettle();

      // Dynamic Title
      expect(find.text('Pilih Voucher GAGE Food'), findsOneWidget);

      // Food vouchers must appear
      expect(find.text('DISKON50'), findsOneWidget);
      expect(find.text('ONGKIRGRATIS'), findsOneWidget);

      // Vouchers for other services must NOT appear
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
      expect(find.text('GAGECAR15'), findsNothing);
      expect(find.text('KIRIMKILAT'), findsNothing);
    });

    testWidgets('Farm Checkout: only Farm vouchers appear, others are excluded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'farm'));
      await tester.pumpAndSettle();

      // Dynamic Title
      expect(find.text('Pilih Voucher GAGE Farm'), findsOneWidget);

      // Farm vouchers must appear
      expect(find.text('SUBSIDITANI'), findsOneWidget);
      expect(find.text('PETANISUKSES'), findsOneWidget);
      expect(find.text('ONGKIRFREE-FARM'), findsOneWidget);

      // Irrelevant vouchers must NOT appear
      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('KULINER20'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
    });

    testWidgets('Shop Checkout: only Shop vouchers appear, others are excluded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'shop'));
      await tester.pumpAndSettle();

      // Dynamic Title
      expect(find.text('Pilih Voucher GAGE Shop'), findsOneWidget);

      // Shop vouchers must appear
      expect(find.text('BELANJAHEMAT'), findsOneWidget);
      expect(find.text('SEMBAKOMURAH'), findsOneWidget);
      expect(find.text('ONGKIRFREE-SHOP'), findsOneWidget);
      expect(find.text('BELANJAMART'), findsNothing);

      // Irrelevant vouchers must NOT appear
      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('PROYEKHEMAT'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
    });

    testWidgets('Build Checkout: only Build vouchers appear, others are excluded', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'build'));
      await tester.pumpAndSettle();

      // Dynamic Title
      expect(find.text('Pilih Voucher GAGE Build'), findsOneWidget);

      // Build vouchers must appear
      expect(find.text('PROYEKHEMAT'), findsOneWidget);
      expect(find.text('BANGUNRUMAH'), findsOneWidget);
      expect(find.text('ONGKIRFREE-BUILD'), findsOneWidget);

      // Irrelevant vouchers must NOT appear
      expect(find.text('DISKON50'), findsNothing);
      expect(find.text('SUBSIDITANI'), findsNothing);
      expect(find.text('BELANJAHEMAT'), findsNothing);
      expect(find.text('RIDEHEMAT'), findsNothing);
    });

    testWidgets('Fallback: resolves primaryServiceType from CartProvider when serviceType is null', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'farm-01',
          merchantId: 'm-farm-01',
          merchantName: 'Toko Tani Subur',
          name: 'Pupuk Organik 5kg',
          price: 35000,
          quantity: 1,
          category: 'Pupuk',
          serviceType: 'farm',
        ),
      );

      // serviceType not passed explicitly to VoucherSelectionScreen
      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: null));
      await tester.pumpAndSettle();

      // App bar title resolves to Farm
      expect(find.text('Pilih Voucher GAGE Farm'), findsOneWidget);

      // Farm vouchers present
      expect(find.text('SUBSIDITANI'), findsOneWidget);

      // Food vouchers excluded
      expect(find.text('DISKON50'), findsNothing);
    });
  });

  group('3. Voucher Application and Grand Total Calculation', () {
    testWidgets('Applying order voucher deducts discount correctly from grandTotal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'f-01',
          merchantId: 'm-01',
          merchantName: 'Warung Makan Berkah',
          name: 'Paket Ayam Bakar Madu',
          price: 50000,
          quantity: 1,
          category: 'Makanan',
          serviceType: 'food',
        ),
      );

      final initialSubtotal = cart.subtotal;
      expect(initialSubtotal, equals(50000));
      final initialGrandTotal = cart.grandTotal;

      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'food'));
      await tester.pumpAndSettle();

      // Find 'Pakai' button for DISKON50
      final pakaiButtons = find.widgetWithText(ElevatedButton, 'Pakai');
      expect(pakaiButtons, findsWidgets);

      // Tap the first 'Pakai' button
      await tester.tap(pakaiButtons.first);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // DISKON50 discount is 15000
      expect(cart.foodPromoCode, equals('DISKON50'));
      expect(cart.totalFoodDiscount, equals(15000));
      expect(cart.grandTotal, equals(initialGrandTotal - 15000));
    });

    testWidgets('Applying delivery voucher deducts shipping discount correctly from grandTotal', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'farm-01',
          merchantId: 'm-farm-01',
          merchantName: 'Kios Bibit Unggul',
          name: 'Benih Padi Ciherang 5kg',
          price: 60000,
          quantity: 1,
          category: 'Benih',
          serviceType: 'farm',
        ),
      );

      final initialShippingFee = cart.finalShippingFee;
      final initialGrandTotal = cart.grandTotal;

      await tester.pumpWidget(createTestWidget(cart: cart, serviceType: 'farm'));
      await tester.pumpAndSettle();

      // Switch to Gratis Ongkir tab (tab index 2)
      await tester.tap(find.text('Gratis Ongkir'));
      await tester.pumpAndSettle();

      expect(find.text('ONGKIRFREE-FARM'), findsOneWidget);

      final pakaiOngkir = find.widgetWithText(ElevatedButton, 'Pakai');
      expect(pakaiOngkir, findsOneWidget);

      await tester.tap(pakaiOngkir);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 3));

      // ONGKIRFREE-FARM discount is 7000
      expect(cart.deliveryPromoCode, equals('ONGKIRFREE-FARM'));
      expect(cart.totalShippingDiscount, equals(7000));
      expect(cart.finalShippingFee, equals(initialShippingFee - 7000));
      expect(cart.grandTotal, equals(initialGrandTotal - 7000));
    });

    test('Direct CartProvider financial model verification for Build voucher', () {
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'build-01',
          merchantId: 'm-build-01',
          merchantName: 'TB Makmur Sentosa',
          name: 'Semen Holcim 40kg',
          price: 65000,
          quantity: 2,
          category: 'Material',
          serviceType: 'build',
        ),
      );

      expect(cart.subtotal, equals(130000));
      expect(cart.primaryServiceType, equals('build'));

      final baseGrandTotal = cart.grandTotal;

      // Apply BANGUNRUMAH order voucher (25000 discount)
      cart.setFoodPromo('BANGUNRUMAH', 25000);
      expect(cart.totalFoodDiscount, equals(25000));
      expect(cart.grandTotal, equals(baseGrandTotal - 25000));

      // Apply ONGKIRFREE-BUILD delivery voucher (10000 discount)
      final rawShip = cart.rawShippingFee;
      cart.setDeliveryPromo('ONGKIRFREE-BUILD', 10000);
      final expectedShip = (rawShip - 10000).clamp(0, 99999999);
      expect(cart.finalShippingFee, equals(expectedShip));
      expect(cart.grandTotal, equals((130000 - 25000) + expectedShip + cart.adminFee));
    });
  });
}
