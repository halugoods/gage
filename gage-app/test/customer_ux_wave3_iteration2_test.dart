import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_transfer_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_receive_screen.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_pocket_wallet.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_home_header.dart';

Widget _wrap(Widget child, {WalletProvider? walletProvider}) {
  final wallet = walletProvider ?? WalletProvider();
  final auth = AuthProvider();
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

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Wave 3 Iteration 3 UX Tests (Full Screen Transfer & Receive)', () {
    testWidgets('GagePayTransferScreen renders segmented tabs, search bar, and contact list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(
        const GagePayTransferScreen(),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Kirim Saldo'), findsOneWidget);
      expect(find.text('Terakhir'), findsOneWidget);
      expect(find.text('Favorit'), findsOneWidget);
      expect(find.text('Cari penerima di sini'), findsOneWidget);

      // Pastikan ada kontak tersimpan dari seed dev
      expect(find.text('Dnid Selvi Agus'), findsOneWidget);
      expect(find.textContaining('8908'), findsWidgets);

      // Pastikan ada icon bintang favorit (emas)
      expect(find.byIcon(Icons.star_rounded), findsWidgets);
      expect(find.byIcon(Icons.star_outline_rounded), findsWidgets);

      // Test tap bintang untuk toggle tanpa batas
      final starOutlines = find.byIcon(Icons.star_outline_rounded);
      if (starOutlines.evaluate().isNotEmpty) {
        await tester.tap(starOutlines.first);
        await tester.pumpAndSettle();
      }

      // Test tap kontak berpindah ke Step 2 (Nominal)
      await tester.tap(find.text('Dnid Selvi Agus'));
      await tester.pumpAndSettle();

      expect(find.text('Nominal Transfer'), findsOneWidget);
      expect(find.text('Kirim Sekarang'), findsOneWidget);
      expect(find.text('Ganti'), findsOneWidget);
    });

    testWidgets('GagePayReceiveScreen renders clean QR code and side-by-side action buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(
        const GagePayReceiveScreen(
          accountNumber: '890812345678',
          userName: 'Budi Santoso',
        ),
      ));
      await tester.pumpAndSettle();

      // Header nomor rekening & salin
      expect(find.text('Terima Saldo'), findsOneWidget);
      expect(find.text('NOMOR REKENING GAGEPAY'), findsOneWidget);
      expect(find.text('8908 1234 5678'), findsWidgets);
      expect(find.text('a.n. Budi Santoso'), findsOneWidget);
      expect(find.text('Salin'), findsOneWidget);

      // Tombol aksi berdampingan
      expect(find.text('Set Nominal'), findsOneWidget);
      expect(find.text('Bagikan Detail'), findsOneWidget);

      // Kartu 2.5D tidak boleh terlihat di area layar utama
      // Bebas istilah "p2p" dan badge ISO
      expect(find.textContaining(RegExp(r'p2p', caseSensitive: false)), findsNothing);
      expect(find.text('Terverifikasi ISO/IEC'), findsNothing);
    });

    testWidgets('GagePocketWallet renders Saldo, Poin, and Nomor Rekening without collision', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(
        GagePocketWallet(
          balance: 1500000,
          points: 250,
          accountNumber: '890812345678',
          onTopUpTap: () {},
          onPayQrisTap: () {},
          onWithdrawTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('TOTAL SALDO GAGEPAY'), findsOneWidget);
      expect(find.text('Rp 1.500.000'), findsOneWidget);
      expect(find.text('250 Poin'), findsOneWidget);
      expect(find.text('8908 1234 5678'), findsOneWidget);
    });

    testWidgets('GageHomeHeader search bar barcode scanner icon has red GageTheme.primary color', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(_wrap(
        const GageHomeHeader(scrollOffset: 0.0),
      ));
      await tester.pumpAndSettle();

      final scannerIconFinder = find.byIcon(Icons.qr_code_scanner_rounded);
      expect(scannerIconFinder, findsOneWidget);

      final iconWidget = tester.widget<Icon>(scannerIconFinder);
      expect(iconWidget.color, equals(GageTheme.primary));
    });
  });
}
