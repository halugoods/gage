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
    testWidgets('AdminSettingsScreen renders dynamic tariff, fee settings, and saves config', (tester) async {
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
      expect(find.text('Pengaturan Finansial & Tarif'), findsOneWidget);
      expect(find.text('TARIF GAGERIDE MOTOR (REGULER & HEMAT)'), findsOneWidget);
      expect(find.text('BIAYA LAYANAN & MDR TRANSAKSI'), findsOneWidget);

      // Verify Dynamic Base KM & Fee Labels
      expect(find.text('Jarak Dasar Reguler (KM Awal)'), findsOneWidget);
      expect(find.text('Biaya GagePay & QRIS Cashless'), findsOneWidget);
      expect(find.text('Biaya Dasar COD Tunai'), findsOneWidget);
      expect(find.text('Biaya Tambahan COD Toko Ekstra'), findsOneWidget);

      // Verify Universal Business Principles (without Islamic / Syar'i slop)
      expect(find.text('PRINSIP EKONOMI & SISTEM PEMBULATAN'), findsOneWidget);
      expect(find.text('Bagi Hasil Mitra Driver'), findsOneWidget);
      expect(find.text('Sistem Pembulatan Transparan'), findsOneWidget);

      // Verify Save Button
      final saveButton = find.text('Simpan Konfigurasi Tarif');
      expect(saveButton, findsOneWidget);

      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      // Verify SnackBar confirmation
      expect(find.textContaining('Konfigurasi tarif & jarak berhasil disimpan'), findsOneWidget);
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
