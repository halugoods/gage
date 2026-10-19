import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_settings_screen.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GAGE Admin Settings & Fee Configuration Tests', () {
    testWidgets('AdminSettingsScreen renders dynamic tariff cards and opens bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      SharedPreferences.setMockInitialValues({});
      FareCalculationService.resetToDefault();
      GagePricingService.resetToDefault();

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminSettingsScreen(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header & Sections
      expect(find.text('Pengaturan Tarif & Layanan'), findsOneWidget);
      expect(find.text('KONFIGURASI TARIF & PENGANTARAN'), findsOneWidget);

      // Verify Dynamic Tariff Options
      expect(find.text('Tarif Motor (GageRide)'), findsOneWidget);
      expect(find.text('Tarif Mobil (GageCar)'), findsOneWidget);
      expect(find.text('Ongkir Pengantaran (Food, Shop, Send)'), findsOneWidget);
      expect(find.text('Biaya Layanan & MDR Transaksi'), findsOneWidget);

      // Verify Live App Editor shortcut
      expect(find.text('LIVE APP WYSIWYG EDITOR'), findsOneWidget);

      // Tap on Motor Tariff Option to open iOS Bottom Sheet
      await tester.tap(find.text('Tarif Motor (GageRide)'));
      await tester.pumpAndSettle();

      // Verify Bottom Sheet Subtitle & Save Button
      expect(find.text('Atur jarak dasar dan tarif per kilometer motor reguler & hemat'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);

      // Tap Simpan Perubahan in Bottom Sheet
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.textContaining('Konfigurasi tarif berhasil diperbarui'), findsOneWidget);
    });

    testWidgets('AdminBottomNavBar renders all 5 simplified operational tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdminBottomNavBar(currentIndex: 0),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Kurasi'), findsOneWidget);
      expect(find.text('Pengaturan'), findsOneWidget);
    });
  });
}
