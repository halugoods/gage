import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/shared/widgets/service_transparency_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('ServiceTransparencyDialog Widget & Logic Tests', () {
    test('isAccepted returns false initially and true after saved', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await ServiceTransparencyDialog.isAccepted(), false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(ServiceTransparencyDialog.prefKey, true);
      expect(await ServiceTransparencyDialog.isAccepted(), true);

      await ServiceTransparencyDialog.resetAcceptance();
      expect(await ServiceTransparencyDialog.isAccepted(), false);
    });

    testWidgets('Renders all 3 transparent principles and handles acceptance', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ServiceTransparencyDialog(isDialogMode: false),
          ),
        ),
      );

      // Verify Header & 3 Prinsip Layanan
      expect(find.text('STANDAR LAYANAN RESMI'), findsOneWidget);
      expect(find.text('Syarat & Ketentuan Layanan'), findsOneWidget);
      expect(find.text('Perjanjian Layanan Pengantaran Mitra Pengemudi'), findsOneWidget);
      expect(find.text('Kuasa Pembelian Toko Resmi'), findsOneWidget);
      expect(find.text('Ketentuan Pembulatan Tarif Pengantaran Rp 500'), findsOneWidget);
      expect(find.text('Saya Memahami & Menyetujui Ketentuan'), findsOneWidget);

      // Tap accept button
      await tester.tap(find.text('Saya Memahami & Menyetujui Ketentuan'));
      await tester.pumpAndSettle();

      // Verify saved in SharedPreferences with exact key
      expect(await ServiceTransparencyDialog.isAccepted(), true);
    });
  });
}
