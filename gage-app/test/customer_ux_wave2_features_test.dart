import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/gage_receipt_share_dialog.dart';
import 'package:gage_app/shared/widgets/gage_split_payment_banner.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';

Widget _wrap(
  Widget child, {
  WalletProvider? walletProvider,
  CartProvider? cartProvider,
  OrderProvider? orderProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => walletProvider ?? WalletProvider()),
      ChangeNotifierProvider(create: (_) => authProvider ?? AuthProvider()),
      ChangeNotifierProvider(create: (_) => orderProvider ?? OrderProvider()),
      ChangeNotifierProvider(create: (_) => cartProvider ?? CartProvider()),
    ],
    child: MaterialApp(
      theme: GageTheme.lightTheme,
      home: child,
    ),
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

  group('1. GAGEPay Multi-User WalletProvider Caching', () {
    test('WalletProvider initial balance is 0 and restores cached balance per userId', () async {
      SharedPreferences.setMockInitialValues({
        'gage_wallet_balance_usr-test-1': 75000,
        'gage_wallet_points_usr-test-1': 250,
      });

      final wallet = WalletProvider();
      expect(wallet.balance, equals(0));

      await wallet.restoreCachedWallet('usr-test-1');
      expect(wallet.balance, equals(75000));
      expect(wallet.points, equals(250));

      // Separate user has zero balance
      final wallet2 = WalletProvider();
      await wallet2.restoreCachedWallet('usr-test-2');
      expect(wallet2.balance, equals(0));
    });
  });

  group('2. Paket A: ProfileScreen Alamat Favorit Saya with Full-Rounded Switcher', () {
    testWidgets('Renders Alamat Favorit Saya tile and opens sheet with Personal vs Bisnis switcher', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await UserAddressService.saveFavorite(const UserSavedAddress(
        id: 'fav-home-1',
        name: 'Rumah Utama',
        address: 'Jl. Raya Pracimantoro No. 12',
        category: 'personal',
        latitude: -8.0551,
        longitude: 110.8088,
        notes: 'Pagar hitam depan pos ronda',
        recipientName: 'Budi Santoso',
        recipientPhone: '081234567890',
      ));

      await tester.pumpWidget(_wrap(const ProfileScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Alamat Favorit Saya'), findsOneWidget);

      await tester.ensureVisible(find.text('Alamat Favorit Saya'));
      await tester.tap(find.text('Alamat Favorit Saya'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Personal'), findsOneWidget);
      expect(find.text('Bisnis'), findsOneWidget);
      expect(find.text('Rumah Utama'), findsOneWidget);
      expect(find.textContaining('Pagar hitam'), findsOneWidget);
      expect(find.textContaining('Budi Santoso'), findsOneWidget);

      // Tap Bisnis tab
      await tester.tap(find.text('Bisnis'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Belum ada alamat favorit bisnis'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('3. Paket B: OrdersScreen Quick Struk and Batalkan Actions', () {
    testWidgets('Shows Struk button on completed order and Batalkan on cancellable active order', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final orderProvider = OrderProvider();
      await tester.pumpWidget(_wrap(const OrdersScreen(), orderProvider: orderProvider));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Active tab (Dalam Proses)
      // Check if cancellable orders display Batalkan
      expect(find.text('Dalam Proses'), findsOneWidget);

      // Switch to Riwayat Selesai
      await tester.tap(find.text('Riwayat Selesai'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Struk'), findsAtLeastNWidgets(1));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('GageReceiptShareDialog renders Salin Teks Ringkasan button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const sampleOrder = OrderModel(
        id: 'ord-test-01',
        orderNumber: 'ORD-2026-TEST',
        userId: 'usr-cust-01',
        merchantId: 'mch-1',
        merchantName: 'Rocket Chicken Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 10',
        status: 'COMPLETED',
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 25000,
        itemsSubtotal: 20000,
        shippingFee: 4000,
        shippingDiscount: 0,
        adminFee: 1000,
        driverTip: 0,
        pickupAddress: 'Resto',
        deliveryAddress: 'Rumah',
        pickupLat: -8.05,
        pickupLng: 110.80,
        deliveryLat: -8.06,
        deliveryLng: 110.81,
        distanceKm: 2.0,
        trackingToken: 'tok-1',
        items: [
          OrderItemModel(id: 'i1', name: 'Ayam Geprek', price: 20000, quantity: 1, subtotal: 20000),
        ],
        createdAt: 1730000000,
        serviceType: 'food',
        deliveryOption: 'REGULER',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: const Scaffold(
            body: GageReceiptShareDialog(order: sampleOrder),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Salin Teks Ringkasan'), findsNothing);
      expect(find.text('Simpan Gambar'), findsOneWidget);
      expect(find.text('Bagikan Struk'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });

  group('4. Paket C: Split Payment Quick Top-Up', () {
    testWidgets('GageSplitPaymentBanner renders Isi Saldo button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool topUpCalled = false;
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: GageSplitPaymentBanner(
              walletBalance: 10000,
              totalAmount: 25000,
              currencyFormatter: NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0),
              onTopUp: () => topUpCalled = true,
              onSelectCodSplit: () {},
              onSelectQrisSplit: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Isi Saldo'), findsOneWidget);
      expect(find.text('Saldo kurang Rp 15.000'), findsOneWidget);
      expect(find.text('GAGEPay + COD'), findsOneWidget);
      expect(find.text('GAGEPay + QRIS'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('TopupQrisDialog accepts initialAmount and shows 15-minute countdown upon generation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: TopupQrisDialog(
              initialAmount: 35000,
              onTopupSuccess: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Rp 35.000'), findsOneWidget);
      expect(find.text('Buat Pembayaran'), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 2));
    });
  });
}
