import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_merchant_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('AffiliateHubScreen builds cleanly with 3 commerce services (G-Food, G-Shop, G-Farm), Keranjang Kuning CTA, and dynamic merchant navigation', (tester) async {
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

    // Verify Tab 1: Penawaran (G-Cuan Signature Header & Capsule Tab)
    expect(find.text('G-Cuan'), findsOneWidget);
    expect(find.text('Afiliasi Mitra'), findsNothing);
    expect(find.text('Penawaran'), findsOneWidget);
    expect(find.text('Performa'), findsOneWidget);

    // Verify 6-char referral banner
    expect(find.text('Ajak teman dapat cuan'), findsOneWidget);
    expect(find.text('G8K2M9'), findsOneWidget);
    expect(find.text('Bagikan'), findsOneWidget);

    // Verify Bikin Video Cuan CTA Banner is removed
    expect(find.text('Bikin Video Cuan'), findsNothing);
    expect(find.text('Unggah 📹'), findsNothing);

    // Verify 3 Commerce Services (G-Food, G-Shop, G-Farm)
    expect(find.text('G-Food'), findsOneWidget);
    expect(find.text('G-Shop'), findsOneWidget);
    expect(find.text('G-Farm'), findsOneWidget);
    expect(find.text('G-Send'), findsNothing);
    expect(find.text('Build'), findsNothing);

    // Verify Filter Tabs
    expect(find.text('Rekomendasi'), findsOneWidget);
    expect(find.text('Komisi Tertinggi'), findsOneWidget);
    expect(find.text('Terlaris'), findsOneWidget);

    // Verify default Food merchants from GageMockRegistry
    expect(find.text('Rocket Chicken Pracimantoro'), findsOneWidget);

    // Tap on Shop service
    await tester.tap(find.text('G-Shop'));
    await tester.pumpAndSettle();
    expect(find.text('Toko Sembako Berkah Fajar'), findsOneWidget);

    // Tap on Farm service
    await tester.tap(find.text('G-Farm'));
    await tester.pumpAndSettle();
    expect(find.text('Kios Tani Subur Makmur'), findsOneWidget);

    // Tap merchant card in Farm service to open AffiliateMerchantDetailScreen
    await tester.tap(find.text('Kios Tani Subur Makmur'));
    await tester.pumpAndSettle();
    expect(find.byType(AffiliateMerchantDetailScreen), findsOneWidget);

    // Pop back to AffiliateHubScreen
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

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
    expect(find.text('Mulai Bagikan Produk'), findsOneWidget);
  });
}
