import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/shared/widgets/akad_thoyib_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AkadThoyibDialog Widget & Logic Tests', () {
    test('isAccepted returns false initially and true after saved', () async {
      SharedPreferences.setMockInitialValues({});
      expect(await AkadThoyibDialog.isAccepted(), false);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AkadThoyibDialog.prefKey, true);
      expect(await AkadThoyibDialog.isAccepted(), true);

      await AkadThoyibDialog.resetAcceptance();
      expect(await AkadThoyibDialog.isAccepted(), false);
    });

    testWidgets('Renders all 3 Akad items and handles acceptance', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AkadThoyibDialog(isDialogMode: false),
          ),
        ),
      );

      // Verify Headers & 3 Akad texts
      expect(find.text("GAGE PRACIMANTORO SYAR'I"), findsOneWidget);
      expect(find.text('Transparansi Akad & Berkah'), findsOneWidget);
      expect(find.text('Akad Ijarah (Jasa Antar Driver)'), findsOneWidget);
      expect(find.text('Akad Wakalah bil Ujrah (Jasa Titip Beli)'), findsOneWidget);
      expect(find.text('Akad Thoyib Pembulatan Ongkir'), findsOneWidget);
      expect(find.text('Saya Setuju & Ridho (Bismillah)'), findsOneWidget);

      // Tap accept button
      await tester.tap(find.text('Saya Setuju & Ridho (Bismillah)'));
      await tester.pumpAndSettle();

      // Verify saved in SharedPreferences
      expect(await AkadThoyibDialog.isAccepted(), true);
    });
  });
}
