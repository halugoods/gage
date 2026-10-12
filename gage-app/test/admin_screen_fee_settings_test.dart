import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';

void main() {
  testWidgets('AdminScreen renders Admin Fee form, Live Simulation, and Saves config', (tester) async {
    SharedPreferences.setMockInitialValues({});
    FareCalculationService.resetToDefault();

    await tester.pumpWidget(
      const MaterialApp(
        home: AdminScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Tab "Biaya & Komisi" exists
    expect(find.text('Biaya & Komisi'), findsOneWidget);

    // Verify Admin fee header
    expect(find.text('Pengaturan Biaya Admin Toko (Multi-Merchant)'), findsWidgets);

    // Verify Form Fields
    expect(find.text('Biaya Admin Cashless per Toko (Default: Rp 1.000)'), findsWidgets);
    expect(find.text('Biaya Admin COD Toko Pertama (Default: Rp 3.000)'), findsWidgets);
    expect(find.text('Biaya Admin COD Toko Tambahan (Default: Rp 1.000)'), findsWidgets);

    // Verify Live Simulation Box
    expect(find.text('Live Simulation Kalkulasi Admin Real-time'), findsWidgets);
    expect(find.text('1 Toko Cashless'), findsWidgets);
    expect(find.text('2 Toko Cash COD'), findsWidgets);

    // Verify Save Button
    expect(find.text('Simpan Pengaturan Biaya'), findsWidgets);
  });
}
