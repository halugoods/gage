import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_transfer_screen.dart';
import 'package:gage_app/shared/widgets/gage_receipt_share_dialog.dart';

Widget _wrap(
  Widget child, {
  WalletProvider? walletProvider,
  AuthProvider? authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => walletProvider ?? WalletProvider()),
      ChangeNotifierProvider(create: (_) => authProvider ?? AuthProvider()),
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

  group('GAGEPay P2P & Universal Scanner Tests', () {
    test('WalletProvider exposes formatted accountNumber and supports P2P transfer', () async {
      final wallet = WalletProvider();
      wallet.topUp(50000);

      expect(wallet.accountNumber, startsWith('8908'));
      expect(wallet.accountNumber.length, equals(12));
      expect(LuhnAlgorithm.validate(wallet.accountNumber), isTrue);

      final prevBalance = wallet.balance;
      final ok = await wallet.transferBalance(
        recipientAccount: '890812345678',
        recipientName: 'Siti Rahmawati',
        amount: 15000,
        note: 'Uang makan',
      );

      expect(ok, isTrue);
      expect(wallet.balance, equals(prevBalance - 15000));
      expect(wallet.transactions.first['type'], equals('TRANSFER_OUT'));
    });

    test('GageApiClient verifyOrderReceipt returns structured verification data', () async {
      final res = await GageApiClient.verifyOrderReceipt('ORD-20261113-001');
      expect(res, isNotNull);
      expect(res!['order_number'] ?? res['orderNumber'], equals('ORD-20261113-001'));
      expect(res['status'], isNotNull);
    });

    testWidgets('GageReceiptShareDialog renders full-screen receipt and QR code', (tester) async {
      final testOrder = OrderModel(
        id: 'ord-test-01',
        orderNumber: 'ORD-20261113-999',
        userId: 'usr-cust-01',
        merchantId: 'merch-01',
        merchantName: 'Ayam Geprek Mas Bro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 12',
        serviceType: 'food',
        status: 'completed',
        paymentStatus: 'paid',
        paymentMethod: 'GAGEPay',
        totalAmount: 45000,
        itemsSubtotal: 35000,
        shippingFee: 10000,
        shippingDiscount: 0,
        adminFee: 0,
        deliveryAddress: 'Tubokarto, Pracimantoro',
        distanceKm: 1.5,
        trackingToken: 'TRK-999',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => GageReceiptShareDialog.show(ctx, testOrder),
                child: const Text('Buka Struk'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Struk'));
      await tester.pumpAndSettle();

      expect(find.text('BUKTI TRANSAKSI PEMBAYARAN RESMI'), findsOneWidget);
      expect(find.text('Ayam Geprek Mas Bro'), findsOneWidget);
      expect(find.text('ORD-20261113-999'), findsOneWidget);
      expect(find.text('Simpan Gambar'), findsOneWidget);
    });

    testWidgets('GagePayTransferScreen renders recipient lookup and nominal pills', (tester) async {
      final wallet = WalletProvider();
      wallet.topUp(50000);

      await tester.pumpWidget(_wrap(
        const GagePayTransferScreen(),
        walletProvider: wallet,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Saldo'), findsOneWidget);
      expect(find.text('Terakhir'), findsOneWidget);
      expect(find.text('Favorit'), findsOneWidget);
      expect(find.text('Cari penerima di sini'), findsOneWidget);

      // Tap recipient to transition to step 2
      await tester.tap(find.text('Dnid Selvi Agus'));
      await tester.pumpAndSettle();

      expect(find.text('Nominal Transfer'), findsOneWidget);
      expect(find.text('Kirim Sekarang'), findsOneWidget);
      expect(find.text('Rp 10.000'), findsOneWidget);
    });
  });
}
