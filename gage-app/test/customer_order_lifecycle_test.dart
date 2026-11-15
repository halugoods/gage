import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/orders/presentation/order_detail_screen.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';

OrderModel _makeOrder({
  String id = 'ord-wave1-01',
  String status = 'PREPARING',
  String serviceType = 'food',
  bool isPickup = false,
  String? driverName,
  String? driverPlate,
  String? driverPhone,
  Map<String, dynamic>? packageDetails,
}) {
  return OrderModel(
    id: id,
    orderNumber: 'INV-W1-001',
    userId: 'cust-live-01',
    merchantId: serviceType == 'food' ? 'm-warung-01' : 'gage-transport',
    merchantName: serviceType == 'food' ? 'Warung Soto Mbak Sari' : 'GAGE Send',
    merchantAddress: 'Jl. Raya Pracimantoro No. 12',
    driverName: driverName,
    driverPlate: driverPlate,
    driverPhone: driverPhone,
    status: status,
    paymentMethod: 'GAGEPAY',
    paymentStatus: 'PAID',
    totalAmount: 35000,
    itemsSubtotal: 25000,
    shippingFee: 9000,
    shippingDiscount: 0,
    adminFee: 1000,
    deliveryAddress: 'Dusun Tubokarto, Pracimantoro',
    pickupLat: -8.0558,
    pickupLng: 110.8095,
    deliveryLat: -8.0512,
    deliveryLng: 110.8062,
    distanceKm: 1.8,
    trackingToken: 'tok-01',
    createdAt: 1730000000,
    serviceType: serviceType,
    isPickup: isPickup,
    packageDetails: packageDetails,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GagePricingService.resetToDefault();
  });

  group('Wave 1 OrderModel Lifecycle & Assignment Contracts', () {
    test('hasAssignedDriver, isTransportService, and sequential statusLabel', () {
      final waiting = _makeOrder(status: 'ORDER_RECEIVED');
      expect(waiting.hasAssignedDriver, isFalse);
      expect(waiting.driver, isNull);
      expect(waiting.isTransportService, isFalse);
      expect(waiting.isActive, isTrue);

      final foodReady = _makeOrder(
        status: 'READY_FOR_PICKUP',
        driverName: 'Budi Santoso',
        driverPlate: 'AD 4321 XY',
        driverPhone: '081200009999',
      );
      expect(foodReady.hasAssignedDriver, isTrue);
      expect(foodReady.driver?.name, equals('Budi Santoso'));

      final sendOrder = _makeOrder(
        serviceType: 'send',
        status: 'SEARCHING_DRIVER',
      );
      expect(sendOrder.isTransportService, isTrue);
      expect(sendOrder.hasAssignedDriver, isFalse);
    });
  });

  group('Wave 1 OrderDetailScreen & OrderTrackingScreen Audit', () {
    testWidgets('OrderDetailScreen hides unassigned driver card, omits WA links, and renders optional tracking CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final order = _makeOrder(status: 'PREPARING');

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: OrderDetailScreen(order: order),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pantau Pengantaran'), findsOneWidget);
      expect(find.text('Bantuan'), findsOneWidget);
      expect(find.textContaining('WhatsApp'), findsNothing);
      expect(find.textContaining('wa.me'), findsNothing);
      // Belum ada driver ditugaskan -> bagian driver tersembunyi
      expect(find.text('Mitra Driver GAGE'), findsNothing);
      // Pesanan masih PREPARING -> bagian rating tidak muncul sebelum COMPLETED
      expect(find.text('Beri Ulasan'), findsNothing);
    });

    testWidgets('OrderDetailScreen shows assigned driver section and hides tracking CTA on COMPLETED', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final order = _makeOrder(
        status: 'COMPLETED',
        driverName: 'Bagus Saputra',
        driverPlate: 'AD 9876 AB',
        driverPhone: '081234567890',
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: OrderDetailScreen(order: order),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Bagus Saputra'), findsOneWidget);
      expect(find.text('Pantau Pengantaran'), findsNothing);
      expect(find.text('Bantuan'), findsOneWidget);
    });

    testWidgets('OrderTrackingScreen shows clean empty state when no order exists and useDevSeedData is false', (tester) async {
      final prevFallback = GageApiClient.allowDevSeedFallback;
      GageApiClient.allowDevSeedFallback = false;
      addTearDown(() => GageApiClient.allowDevSeedFallback = prevFallback);
      expect(GageApiClient.useDevSeedData, isFalse);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: const OrderTrackingScreen(orderId: 'missing-order-id'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Data pelacakan pesanan belum tersedia.'), findsOneWidget);
      expect(find.text('Kembali'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });
  });

  group('Wave 1 FullScreenMapPicker, SendBookingScreen & RideCheckoutScreen', () {
    testWidgets('FullScreenMapPicker renders top search bar, draggable center pin hint, and GPS button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: const FullScreenMapPicker(
            title: 'Titik Antar',
            initialLocation: LatLng(-8.0558, 110.8095),
            initialTitle: 'Pasar Pracimantoro',
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Geser peta untuk menentukan titik'), findsOneWidget);
      expect(find.textContaining('Cari jalan, tempat, atau patokan'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.text('Pakai Lokasi Ini'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('SendBookingScreen renders pickup/dropoff rows, Send tiers, GPS button, and primary CTA', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: const SendBookingScreen(autoStartLocationFlow: false),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Titik Jemput'), findsOneWidget);
      expect(find.text('Titik Antar'), findsOneWidget);
      expect(find.text('Send Instant'), findsOneWidget);
      expect(find.text('Send Hemat'), findsOneWidget);
      expect(find.byIcon(Icons.my_location_rounded), findsOneWidget);
      expect(find.byIcon(Icons.zoom_out_map_rounded), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });

    testWidgets('RideCheckoutScreen (Send) auto-applies eligible promo and renders editable package summary', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<CartProvider>(create: (_) => CartProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: const RideCheckoutScreen(
              serviceType: 'send',
              rideOption: 'INSTANT',
              pickupLocation: LatLng(-8.0558, 110.8095),
              dropoffLocation: LatLng(-8.0658, 110.8195),
              pickupAddress: 'Pasar Pracimantoro',
              dropoffAddress: 'Terminal Pracimantoro',
              distanceKm: 3.5,
              baseFare: 15000,
              recipientName: 'Siti Aminah',
              recipientPhone: '081299988877',
              packageType: 'Makanan',
              weightTier: '< 5 kg',
              itemDescription: 'Paket sembako keluarga',
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.textContaining('Siti Aminah'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Makanan'), findsWidgets);
      expect(find.text('Proteksi Pengiriman Barang'), findsOneWidget);
      expect(find.text('Voucher'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 4));
    });
  });
}
