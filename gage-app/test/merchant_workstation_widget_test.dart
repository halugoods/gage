import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/merchant/presentation/merchant_root_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_floating_nav_bar.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableApp({int initialTabIndex = 0}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => MerchantOrderProvider()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        home: MerchantRootScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  testWidgets('MerchantRootScreen renders header and 5-tab bottom navigation correctly', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // 1. Verifikasi elemen header
    expect(find.text('Dimsum Sewu Pracimantoro'), findsOneWidget);
    expect(find.text('TOKO BUKA'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    // 2. Verifikasi 5 tab navigasi bawah dalam MerchantFloatingNavBar
    final navFinder = find.byType(MerchantFloatingNavBar);
    expect(find.descendant(of: navFinder, matching: find.text('Pesanan')), findsOneWidget);
    expect(find.descendant(of: navFinder, matching: find.text('Chat')), findsOneWidget);
    expect(find.descendant(of: navFinder, matching: find.text('Outlet')), findsOneWidget);
    expect(find.descendant(of: navFinder, matching: find.text('Marketing')), findsOneWidget);
    expect(find.descendant(of: navFinder, matching: find.text('GagePay')), findsOneWidget);

    // 3. Verifikasi 4 Segmented Tab Kapsul Universal (Food, Shop, Farm) pada Tab 0 (Pesanan)
    expect(find.text('Disiapkan'), findsOneWidget);
    expect(find.text('Siap Diambil'), findsOneWidget);
    expect(find.text('Sedang Diantar'), findsOneWidget);
    expect(find.text('Selesai'), findsOneWidget);
  });

  testWidgets('MerchantRootScreen switches 5 tabs smoothly and renders designated screens', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    final navFinder = find.byType(MerchantFloatingNavBar);

    // Buka Tab 1: Chat
    await tester.tap(find.descendant(of: navFinder, matching: find.text('Chat')));
    await tester.pumpAndSettle();
    expect(find.text('Pusat Bantuan Mitra GAGE (24/7)'), findsOneWidget);
    expect(find.text('Bantuan CS GAGE'), findsOneWidget);

    // Buka Tab 2: Outlet
    await tester.tap(find.descendant(of: navFinder, matching: find.text('Outlet')));
    await tester.pumpAndSettle();
    expect(find.text('Total Penjualan (Rp)'), findsOneWidget);
    expect(find.text('Skor Outlet'), findsOneWidget);
    expect(find.text('Menu & Stok'), findsOneWidget);
    expect(find.text('Jadwal Toko'), findsOneWidget);
    expect(find.text('Lokasi & Peta'), findsOneWidget);
    expect(find.text('JADI STAR RESTO GAGE'), findsOneWidget);

    // Buka Tab 3: Marketing
    await tester.tap(find.descendant(of: navFinder, matching: find.text('Marketing')));
    await tester.pumpAndSettle();
    expect(find.text('Aktivitas Saya'), findsOneWidget);
    expect(find.text('Diskon Menu'), findsOneWidget);
    expect(find.text('Flash Sale GAGE Food'), findsOneWidget);

    // Buka Tab 4: GagePay (1:1 Customer Parity)
    await tester.tap(find.descendant(of: navFinder, matching: find.text('GagePay')));
    await tester.pumpAndSettle();
    expect(find.text('Kirim'), findsWidgets);
    expect(find.text('Terima'), findsWidgets);
    expect(find.text('Riwayat Transaksi'), findsOneWidget);
  });
}
