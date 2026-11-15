import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AffiliateHubScreen builds cleanly with ShopeeFood-inspired 2-tab architecture & 6-char random referral', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    SharedPreferences.setMockInitialValues({
      'gage_referral_code_v2': 'G8K2M9',
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: AffiliateHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AffiliateHubScreen), findsOneWidget);

    // Verify Tab 1: Penawaran
    expect(find.text('Penawaran'), findsOneWidget);
    expect(find.text('Performa'), findsOneWidget);
    expect(find.textContaining('Surya Tani, Jalan Raya Pracimantoro'), findsOneWidget);
    expect(find.text('Cari Resto atau Hidangan'), findsOneWidget);
    expect(find.text('Performa di GAGE Cuan'), findsOneWidget);
    expect(find.text('Klik'), findsOneWidget);
    expect(find.text('Pesanan'), findsOneWidget);
    expect(find.text('Komisi Kotor'), findsOneWidget);

    // Verify 6-char referral banner
    expect(find.text('AJAK TEMAN CUAN'), findsOneWidget);
    expect(find.text('G8K2M9'), findsOneWidget);
    expect(find.text('Share WhatsApp'), findsOneWidget);

    // Verify Menu Pilihan
    expect(find.text('Menu Pilihan'), findsOneWidget);
    expect(find.text('Tahu kupat'), findsOneWidget);
    expect(find.text('Mie ayam bakso jumbo'), findsOneWidget);

    // Verify Filter Tabs
    expect(find.text('Rekomendasi'), findsOneWidget);
    expect(find.text('Komisi Tertinggi'), findsOneWidget);
    expect(find.text('Terlaris'), findsOneWidget);

    // Verify Resto Mitra Pracimantoro
    expect(find.text('Geprekin Aja Raya Pracimantoro'), findsOneWidget);
    expect(find.text('RM Bakso Mas No'), findsOneWidget);

    // Switch to Tab 2: Performa
    await tester.tap(find.text('Performa'));
    await tester.pumpAndSettle();

    // Verify Performa Header & Saldo Komisi
    expect(find.text('Saldo Komisi Siap Tarik'), findsOneWidget);
    expect(find.text('Tarik ke GAGEPay'), findsOneWidget);

    // Verify Status Filter Tabs
    expect(find.text('Semua'), findsOneWidget);
    expect(find.text('Belum Dibayar'), findsOneWidget);
    expect(find.text('Diproses'), findsWidgets);
    expect(find.text('Selesai'), findsWidgets);

    // Tap "Belum Dibayar" to verify empty state
    await tester.tap(find.text('Belum Dibayar'));
    await tester.pumpAndSettle();

    expect(find.text('Belum Ada Pesanan Affiliate'), findsOneWidget);
    expect(find.text('Mulai Bagikan Menu'), findsOneWidget);

    // Tap "Selesai" tab to verify orders
    await tester.tap(find.text('Selesai').first);
    await tester.pumpAndSettle();

    expect(find.text('Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)'), findsOneWidget);
  });
}
