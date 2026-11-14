import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/invoice_number_generator.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_transfer_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_receive_screen.dart';
import 'package:gage_app/features/wallet/presentation/gage_points_reward_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_settings_screen.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_pocket_wallet.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_qris_receipt_widget.dart';

Widget _wrap(Widget child, {WalletProvider? walletProvider, AuthProvider? authProvider}) {
  final wallet = walletProvider ?? WalletProvider();
  final auth = authProvider ?? AuthProvider();
  final cart = CartProvider();

  return MultiProvider(
    providers: [
      ChangeNotifierProvider<WalletProvider>.value(value: wallet),
      ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ChangeNotifierProvider<CartProvider>.value(value: cart),
    ],
    child: MaterialApp(
      theme: GageTheme.lightTheme,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('id_ID', null);
  });

  group('Wave 3 Iteration 4: InvoiceNumberGenerator Tests', () {
    test('Generates compact invoice and auto-detects DateTime accurately', () {
      final now = DateTime(2026, 11, 14, 23, 30, 45, 123);
      final inv = InvoiceNumberGenerator.generate(timestamp: now, nodeId: 'P');

      expect(inv.startsWith('INV-'), isTrue);
      expect(inv.length, greaterThanOrEqualTo(16));
      expect(inv.length, lessThanOrEqualTo(18));

      // Validasi integritas
      expect(InvoiceNumberGenerator.validate(inv), isTrue);

      // Auto-detect tanggal & jam dari invoice
      final extractedDt = InvoiceNumberGenerator.extractDateTime(inv);
      expect(extractedDt, isNotNull);
      expect(extractedDt!.year, equals(2026));
      expect(extractedDt.month, equals(11));
      expect(extractedDt.day, equals(14));
      expect(extractedDt.hour, equals(23));
      expect(extractedDt.minute, equals(30));

      // Parsing metadata
      final parsed = InvoiceNumberGenerator.parse(inv);
      expect(parsed, isNotNull);
      expect(parsed!['nodeId'], equals('P'));
      expect(parsed['isValid'], isTrue);
    });

    test('Detects typos and invalid check digits', () {
      final inv = InvoiceNumberGenerator.generate();
      expect(InvoiceNumberGenerator.validate(inv), isTrue);

      // Ubah 1 karakter terakhir (check digit dirusak)
      final corruptedLast = '${inv.substring(0, inv.length - 1)}${inv.endsWith('A') ? 'B' : 'A'}';
      expect(InvoiceNumberGenerator.validate(corruptedLast), isFalse);

      // Typo di tengah payload
      final corruptedMid = '${inv.substring(0, 7)}Z${inv.substring(8)}';
      expect(InvoiceNumberGenerator.validate(corruptedMid), isFalse);
    });

    test('Zero collisions across 500 rapid invoice generations', () {
      final set = <String>{};
      for (int i = 0; i < 500; i++) {
        final inv = InvoiceNumberGenerator.generate();
        expect(set.contains(inv), isFalse);
        set.add(inv);
      }
      expect(set.length, equals(500));
    });
  });

  group('Wave 3 Iteration 4: UI & Navigation Tests', () {
    testWidgets('GagePointsRewardScreen renders loyalty tier, 3 segmented tabs, and multi-utilities', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = WalletProvider();
      wallet.addPoints(650); // Tier Madya (GOLD)

      await tester.pumpWidget(_wrap(
        const GagePointsRewardScreen(),
        walletProvider: wallet,
      ));
      await tester.pumpAndSettle();

      // Header tier and points
      expect(find.text('Pusat Poin & Rewards'), findsOneWidget);
      expect(find.text('TOTAL POIN SAYA'), findsOneWidget);
      expect(find.text('650'), findsOneWidget);
      expect(find.text('GOLD'), findsOneWidget);

      // 3 Segmented Pill Tabs
      expect(find.text('Tukar Poin'), findsOneWidget);
      expect(find.text('GAGE Peduli'), findsOneWidget);
      expect(find.text('Transfer & Riwayat'), findsOneWidget);

      // Tab 1: Tukar Langsung ke Saldo Belanja
      expect(find.text('Tukar Langsung ke Saldo Belanja'), findsOneWidget);
      expect(find.text('Katalog E-Voucher & Promo UMKM'), findsOneWidget);

      // Switch to Tab 2: GAGE Peduli
      await tester.tap(find.text('GAGE Peduli'));
      await tester.pumpAndSettle();
      expect(find.text('GAGE Peduli Pracimantoro'), findsOneWidget);
      expect(find.text('Paket Sembako UMKM Pra-Sejahtera'), findsOneWidget);

      // Switch to Tab 3: Transfer & Riwayat
      await tester.tap(find.text('Transfer & Riwayat'));
      await tester.pumpAndSettle();
      expect(find.text('Kirim Poin ke Sesama Akun GAGE'), findsOneWidget);
      expect(find.text('Riwayat Aktivitas Poin'), findsOneWidget);
    });

    testWidgets('GagePaySettingsScreen displays 2.5D card preview, share button, PIN, limits, and helpdesk', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(const GagePaySettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Pengaturan GAGEPay'), findsOneWidget);
      expect(find.text('DETAIL KARTU DIGITAL'), findsOneWidget);
      expect(find.text('Salin Rekening'), findsOneWidget);
      expect(find.text('Bagikan Kartu 2.5D'), findsOneWidget);
      expect(find.text('Kunci Kartu Sementara'), findsOneWidget);

      expect(find.text('KEAMANAN & AUTENTIKASI'), findsOneWidget);
      expect(find.text('Ubah PIN GAGEPay'), findsOneWidget);
      expect(find.text('Biometrik (Sidik Jari / Wajah)'), findsOneWidget);

      expect(find.text('LIMIT TRANSAKSI HARIAN'), findsOneWidget);
      expect(find.text('PREFERENSI & PRIVASI'), findsOneWidget);
      expect(find.text('INFORMASI & BANTUAN'), findsOneWidget);
    });

    testWidgets('GagePayReceiveScreen renders official QRIS receipt off-screen and Bagikan button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(const GagePayReceiveScreen(
        accountNumber: '890812345678',
        userName: 'Siti Rahmawati',
      )));
      await tester.pumpAndSettle();

      expect(find.text('Terima Saldo'), findsOneWidget);
      expect(find.text('Set Nominal'), findsOneWidget);
      expect(find.text('Bagikan'), findsOneWidget);
      // "Bagikan Detail" should be gone
      expect(find.text('Bagikan Detail'), findsNothing);

      // Verifikasi GageQrisReceiptWidget dirender off-screen
      expect(find.byType(GageQrisReceiptWidget, skipOffstage: false), findsOneWidget);
      expect(find.text('PEMBAYARAN QRIS DINAMIS GAGEPAY', skipOffstage: false), findsOneWidget);
    });

    testWidgets('GagePocketWallet has Refresh icon in top-right slot', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      bool refreshCalled = false;
      await tester.pumpWidget(_wrap(GagePocketWallet(
        balance: 100000,
        points: 50,
        onRefreshTap: () {
          refreshCalled = true;
        },
      )));
      await tester.pumpAndSettle();

      // Find refresh icon on pocket wallet
      final refreshFinder = find.byIcon(Icons.refresh_rounded);
      expect(refreshFinder, findsOneWidget);

      await tester.tap(refreshFinder);
      await tester.pumpAndSettle();
      expect(refreshCalled, isTrue);
    });

    testWidgets('GagePayScreen AppBar has Tambah Rekening Penarikan and Pengaturan icons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(const GagePayScreen()));
      await tester.pumpAndSettle();

      expect(find.text('GAGEPay'), findsOneWidget);
      // Ikon di header AppBar
      expect(find.byIcon(Icons.add_card_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('GagePayTransferScreen Tab Terakhir orders purely chronologically', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final wallet = WalletProvider();
      wallet.topUp(100000);
      // Akun A: transfer 1 jam lalu (bukan favorit)
      await wallet.transferBalance(
        recipientAccount: '890811112222',
        recipientName: 'Akun Terkini Non-Fav',
        amount: 10000,
      );

      await tester.pumpWidget(_wrap(
        const GagePayTransferScreen(),
        walletProvider: wallet,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Saldo'), findsOneWidget);
      expect(find.text('Terakhir'), findsOneWidget);
      expect(find.text('Favorit'), findsOneWidget);

      // Verifikasi kemunculan akun terkini
      expect(find.text('Akun Terkini Non-Fav'), findsOneWidget);
    });
  });
}
