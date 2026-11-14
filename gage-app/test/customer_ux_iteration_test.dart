import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/orders/presentation/order_detail_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/shared/widgets/gage_split_payment_banner.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';

Widget _wrapWithProviders(
  Widget child, {
  WalletProvider? walletProvider,
  CartProvider? cartProvider,
  OrderProvider? orderProvider,
}) {
  return MultiProvider(
    key: UniqueKey(),
    providers: [
      ChangeNotifierProvider(create: (_) => walletProvider ?? WalletProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => orderProvider ?? OrderProvider()),
      if (cartProvider != null)
        ChangeNotifierProvider<CartProvider>.value(value: cartProvider)
      else
        ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      theme: GageTheme.lightTheme,
      home: child,
    ),
  );
}

OrderModel _sampleOrder({
  required String id,
  required String serviceType,
  String? merchantAvatar,
  List<OrderItemModel> items = const [],
  Map<String, dynamic>? packageDetails,
}) {
  return OrderModel(
    id: id,
    orderNumber: id,
    userId: 'usr-cust-01',
    merchantId: 'mch-1',
    merchantName: serviceType == 'food' ? 'Rocket Chicken Pracimantoro' : 'GAGE ${serviceType.toUpperCase()}',
    merchantAddress: 'Jl. Raya Pracimantoro No. 10',
    merchantAvatar: merchantAvatar,
    status: 'PREPARING',
    paymentMethod: 'QRIS',
    paymentStatus: 'PAID',
    totalAmount: 24000,
    itemsSubtotal: 20000,
    shippingFee: 3000,
    shippingDiscount: 0,
    adminFee: 1000,
    driverTip: 0,
    pickupAddress: 'Pasar Pracimantoro',
    deliveryAddress: 'Terminal Pracimantoro',
    pickupLat: -8.0558,
    pickupLng: 110.8095,
    deliveryLat: -8.0620,
    deliveryLng: 110.8150,
    distanceKm: 2.3,
    trackingToken: 'tok-$id',
    items: items,
    createdAt: 1730000000,
    serviceType: serviceType,
    packageDetails: packageDetails,
    deliveryOption: 'REGULER',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('CheckoutScreen zero-balance, split banner & recommendation header', () {
    testWidgets('Leaves payment unselected at Rp 0 balance, shows Top Up + COD/QRIS options, and plain Tambah lainnya', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = WalletProvider()..deductBalance(45000);
      expect(wallet.balance, 0);

      final cart = CartProvider();
      cart.addItem(CartItemModel(
        menuId: 'm1',
        name: 'Ayam Geprek Sambal Bawang',
        price: 18000,
        imageUrl: 'assets/images/dish_ayam_geprek.png',
        merchantId: 'mch-1',
        merchantName: 'Rocket Chicken',
        quantity: 1,
      ));

      await tester.pumpWidget(
        _wrapWithProviders(
          const CheckoutScreen(serviceType: 'food'),
          walletProvider: wallet,
          cartProvider: cart,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(cart.paymentMethod, isEmpty);
      expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);
      expect(find.text('Pakai COD'), findsNothing);
      expect(find.text('Pakai QRIS'), findsNothing);
      expect(find.text('Top Up'), findsNothing);
      expect(find.text('GAGEPay + COD'), findsNothing);
      expect(find.text('GAGEPay + QRIS'), findsNothing);

      // Verify plain text 'Tambah lainnya' and no 'Ada lagi yang mau dibeli?' block
      expect(find.text('Ada lagi yang mau dibeli?'), findsNothing);
      expect(find.text('Tambah lainnya'), findsOneWidget);

      // Open payment method sheet and confirm Top Up button sits beside GAGEPay and COD/QRIS are selectable
      await tester.ensureVisible(find.text('Pilih').first);
      await tester.tap(find.text('Pilih').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('SALDO RP 0'), findsOneWidget);
      expect(find.text('Top Up'), findsAtLeastNWidgets(1));
      expect(find.textContaining('QRIS'), findsAtLeastNWidgets(1));
      expect(find.textContaining('COD'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Tunai ke Driver'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Shows GageSplitPaymentBanner when wallet has partial positive balance < total', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = WalletProvider()..topUp(5000);
      expect(wallet.balance, 5000);

      final cart = CartProvider();
      cart.addItem(CartItemModel(
        menuId: 'm1',
        name: 'Bakso Urat',
        price: 22000,
        imageUrl: 'assets/images/dish_bakso_urat.png',
        merchantId: 'mch-2',
        merchantName: 'Bakso Titoti',
        quantity: 1,
      ));

      await tester.pumpWidget(
        _wrapWithProviders(
          const CheckoutScreen(serviceType: 'food'),
          walletProvider: wallet,
          cartProvider: cart,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(cart.paymentMethod, equals('GAGEPAY'));
      expect(find.byType(GageSplitPaymentBanner), findsOneWidget);
      expect(find.text('GAGEPay + COD'), findsOneWidget);
      expect(find.text('GAGEPay + QRIS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('RideBookingScreen & SendBookingScreen 2-step FullScreenMapPicker flow', () {
    testWidgets('RideBookingScreen starts immediately in 2-step FullScreenMapPicker (Jemput -> Antar -> Back)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(const RideBookingScreen(initialTab: 'ride')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.byType(FullScreenMapPicker), findsOneWidget);
      final jemputBtnFinder = find.descendant(
        of: find.byType(FullScreenMapPicker),
        matching: find.byKey(const ValueKey('map_picker_confirm_button')),
      );
      expect(jemputBtnFinder, findsOneWidget);
      expect(find.text('Geser peta untuk menentukan titik'), findsOneWidget);

      // Step 1 -> Step 2
      await tester.tap(jemputBtnFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.byType(FullScreenMapPicker), findsOneWidget);
      final antarBtnFinder = find.descendant(
        of: find.byType(FullScreenMapPicker),
        matching: find.byKey(const ValueKey('map_picker_confirm_button')),
      );
      expect(antarBtnFinder, findsOneWidget);
      expect(find.text('Geser peta untuk menentukan titik'), findsOneWidget);

      // Back in Step 2 returns to Step 1
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 600));

      expect(jemputBtnFinder, findsOneWidget);
      expect(find.text('Geser peta untuk menentukan titik'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('SendBookingScreen starts in FullScreenMapPicker by default and omits Detail pill in summary', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(const SendBookingScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(
        find.descendant(
          of: find.byType(FullScreenMapPicker),
          matching: find.byKey(const ValueKey('map_picker_confirm_button')),
        ),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _wrapWithProviders(const SendBookingScreen(autoStartLocationFlow: false)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Detail:'), findsNothing);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('RideCheckoutScreen Detail Barang, Pickup note, and zero-balance default', () {
    testWidgets('Renders Detail Barang, Pickup & Dropoff driver notes, and unselected Rp 0 payment with Top Up', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = WalletProvider()..deductBalance(45000);

      await tester.pumpWidget(
        _wrapWithProviders(
          const RideCheckoutScreen(
            serviceType: 'send',
            rideOption: 'INSTANT',
            pickupLocation: LatLng(-8.0558, 110.8095),
            dropoffLocation: LatLng(-8.0658, 110.8195),
            pickupAddress: 'Pasar Pracimantoro',
            dropoffAddress: 'Terminal Pracimantoro',
            distanceKm: 3.5,
            baseFare: 15000,
          ),
          walletProvider: wallet,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Detail Barang'), findsOneWidget);
      expect(find.text('Rincian Barang & Penerima'), findsNothing);
      // Both pickup and dropoff rows show driver note button
      expect(find.text('+ Tambah catatan / patokan driver'), findsNWidgets(2));
      // Zero balance payment state: unselected on front card, full controls inside modal
      expect(find.text('Pilih Metode Pembayaran'), findsOneWidget);
      expect(find.text('Pakai COD'), findsNothing);
      expect(find.text('Pakai QRIS'), findsNothing);
      expect(find.text('Top Up'), findsNothing);

      await tester.ensureVisible(find.text('Pilih').first);
      await tester.tap(find.text('Pilih').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('SALDO RP 0'), findsOneWidget);
      expect(find.text('Top Up'), findsAtLeastNWidgets(1));
      expect(find.textContaining('QRIS'), findsAtLeastNWidgets(1));
      expect(find.textContaining('COD'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('OrderDetailScreen & OrderTrackingScreen refinements', () {
    testWidgets('Hides Daftar Menu on ride & send, shows service-specific cards and merchant MiniLocationPreviewMap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final rideOrder = _sampleOrder(
        id: 'RIDE-01',
        serviceType: 'ride',
        items: const [
          OrderItemModel(
            id: 'item-transport-01',
            name: 'Layanan Antar Jemput Motor (REGULER)',
            price: 12000,
            quantity: 1,
            subtotal: 12000,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWithProviders(OrderDetailScreen(order: rideOrder)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Daftar Menu'), findsNothing);
      expect(find.text('Rincian Perjalanan'), findsOneWidget);
      expect(find.byType(MiniLocationPreviewMap), findsOneWidget);

      final sendOrder = _sampleOrder(
        id: 'SEND-01',
        serviceType: 'send',
        packageDetails: const {
          'package_type': 'Elektronik',
          'weight_tier': '1 - 5 kg',
          'description': 'Charger laptop',
          'recipient_name': 'Budi Santoso',
          'recipient_phone': '08123456789',
        },
        items: const [
          OrderItemModel(
            id: 'item-transport-01',
            name: 'Pengiriman Paket GAGE Send (REGULER)',
            price: 15000,
            quantity: 1,
            subtotal: 15000,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWithProviders(OrderDetailScreen(order: sendOrder)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Daftar Menu'), findsNothing);
      expect(find.text('Detail Pengiriman & Barang'), findsOneWidget);
      expect(find.text('Elektronik'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);

      final foodOrder = _sampleOrder(
        id: 'FOOD-01',
        serviceType: 'food',
        items: const [
          OrderItemModel(
            id: 'menu-1',
            name: 'Ayam Geprek Jumbo',
            price: 20000,
            quantity: 1,
            subtotal: 20000,
          ),
        ],
      );

      await tester.pumpWidget(
        _wrapWithProviders(OrderDetailScreen(order: foodOrder)),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('Daftar Menu / Produk'), findsOneWidget);
      expect(find.byType(MiniLocationPreviewMap), findsOneWidget);
      expect(find.byIcon(Icons.circle), findsNothing);
      expect(find.byIcon(Icons.receipt_long_rounded), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.storefront_rounded), findsAtLeastNWidgets(1));

      // Tapping merchant minimap opens 1:1 floating sheet
      await tester.ensureVisible(find.byType(MiniLocationPreviewMap));
      await tester.tap(find.byType(MiniLocationPreviewMap));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Lokasi Toko Mitra'), findsOneWidget);
      final sheetAspectRatios = tester.widgetList<AspectRatio>(find.byType(AspectRatio)).where((ar) => ar.aspectRatio == 1.0);
      expect(sheetAspectRatios, isNotEmpty);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    test('OrderModel resolves real merchant avatar assets and OrderTrackingScreen omits generic storefront fallback', () {
      final rocketOrder = _sampleOrder(id: 'FOOD-RC', serviceType: 'food', merchantAvatar: '');
      expect(rocketOrder.resolveMerchantAvatarAsset(), equals('assets/images/resto_rocket_chicken.png'));

      final baksoOrder = OrderModel(
        id: 'FOOD-BK',
        orderNumber: 'FOOD-BK',
        userId: 'u1',
        merchantId: 'm2',
        merchantName: 'Bakso Titoti Wonogiri',
        merchantAddress: 'Jl. Solo',
        status: 'PREPARING',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        totalAmount: 20000,
        itemsSubtotal: 17000,
        shippingFee: 2000,
        shippingDiscount: 0,
        adminFee: 1000,
        driverTip: 0,
        deliveryAddress: 'Pracimantoro',
        distanceKm: 1.5,
        trackingToken: 'tok',
        items: const [],
        createdAt: 1730000000,
        serviceType: 'food',
      );
      expect(baksoOrder.resolveMerchantAvatarAsset(), equals('assets/images/dish_bakso_urat.png'));
    });
  });

  group('SeamlessFloatingCartBar Delivery-vs-Pickup Buy Flow', () {
    testWidgets('Delivery opens FullScreenMapPicker before CheckoutScreen and updates CartProvider', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final deliveryCart = CartProvider();
      deliveryCart.addItem(CartItemModel(
        menuId: 'm1',
        name: 'Bakso Urat',
        price: 18000,
        imageUrl: 'assets/images/dish_bakso_urat.png',
        merchantId: 'mch_bakso',
        merchantName: 'Bakso Titoti Wonogiri',
        quantity: 1,
      ));
      expect(deliveryCart.isPickup, isFalse);

      await tester.pumpWidget(
        _wrapWithProviders(
          const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SeamlessFloatingCartBar(),
            ),
          ),
          cartProvider: deliveryCart,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Beli'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(FullScreenMapPicker), findsOneWidget);
      expect(find.text('Lanjut ke Checkout'), findsOneWidget);

      await tester.tap(find.text('Lanjut ke Checkout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(CheckoutScreen), findsOneWidget);
      expect(deliveryCart.hasCustomDeliveryLocation, isTrue);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Pickup skips FullScreenMapPicker and pushes CheckoutScreen directly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final pickupCart = CartProvider();
      pickupCart.addItem(CartItemModel(
        menuId: 'm2',
        name: 'Ayam Geprek',
        price: 20000,
        imageUrl: 'assets/images/food_ayam_geprek.jpg',
        merchantId: 'mch_geprek',
        merchantName: 'Warung Geprek',
        quantity: 1,
      ));
      pickupCart.setIsPickup(true);
      expect(pickupCart.isPickup, isTrue);

      await tester.pumpWidget(
        _wrapWithProviders(
          const Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: SeamlessFloatingCartBar(),
            ),
          ),
          cartProvider: pickupCart,
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      await tester.tap(find.text('Beli'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 450));

      expect(find.byType(FullScreenMapPicker), findsNothing);
      expect(find.byType(CheckoutScreen), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });
  });
}
