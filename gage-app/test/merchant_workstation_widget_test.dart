import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/merchant/presentation/merchant_root_screen.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildTestableApp({int initialTabIndex = 0}) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MerchantOrderProvider()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        home: MerchantRootScreen(initialTabIndex: initialTabIndex),
      ),
    );
  }

  testWidgets('MerchantRootScreen renders header and bottom navigation correctly', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Verify header elements
    expect(find.text('Dimsum Sewu Pracimantoro'), findsOneWidget);
    expect(find.text('TOKO BUKA'), findsOneWidget);

    // Verify 3 bottom navigation items
    expect(find.text('Pesanan Masuk'), findsOneWidget);
    expect(find.text('Menu & Stok'), findsOneWidget);
    expect(find.text('Pengaturan Toko'), findsOneWidget);
  });

  testWidgets('MerchantRootScreen switches tabs smoothly', (tester) async {
    await tester.pumpWidget(buildTestableApp());
    await tester.pumpAndSettle();

    // Switch to Menu & Stok (Tab 2)
    await tester.tap(find.text('Menu & Stok'));
    await tester.pumpAndSettle();

    expect(find.text('Kalkulator Markup Komisi'), findsOneWidget);
    expect(find.text('Tambah Menu'), findsOneWidget);

    // Switch to Pengaturan Toko (Tab 3)
    await tester.tap(find.text('Pengaturan Toko'));
    await tester.pumpAndSettle();

    expect(find.text('LAPAK SEDANG BUKA'), findsOneWidget);
    expect(find.text('Performa & Penerimaan Pesanan'), findsOneWidget);
  });

  testWidgets('Markup Calculator modal opens and computes correctly', (tester) async {
    await tester.pumpWidget(buildTestableApp(initialTabIndex: 1));
    await tester.pumpAndSettle();

    // Tap on Kalkulator Markup Komisi
    await tester.tap(find.text('Kalkulator Markup Komisi'));
    await tester.pumpAndSettle();

    // Check modal contents
    expect(find.text('Kalkulator Markup Otomatis GAGE'), findsOneWidget);
    expect(find.text('Formula: CEIL((Harga Asli / 0.90) / 500) * 500'), findsOneWidget);
    expect(find.text('Terapkan Harga Ini ke Menu Baru'), findsOneWidget);
  });
}
