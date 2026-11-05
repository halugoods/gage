import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/admin/presentation/admin_root_screen.dart';

void main() {
  testWidgets('AdminRootScreen initializes and displays 4 operational tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: BannerManagerService.instance),
        ],
        child: MaterialApp(
          theme: GageTheme.lightTheme,
          home: const AdminRootScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Tab 0: Radar Order
    expect(find.text('Radar Order'), findsOneWidget);
    expect(find.text('Finansial'), findsOneWidget);
    expect(find.text('Tarif'), findsOneWidget);
    expect(find.text('Kurasi/Banner'), findsOneWidget);

    // Verify Title & Subtitle for default tab
    expect(find.text('Radar Order & Armada'), findsOneWidget);

    // Switch to Tab 1: Finansial
    await tester.tap(find.text('Finansial'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard Finansial & GMV'), findsOneWidget);
    expect(find.textContaining('GROSS MERCHANDISE VALUE'), findsOneWidget);

    // Switch to Tab 2: Tarif
    await tester.tap(find.text('Tarif'));
    await tester.pumpAndSettle();
    expect(find.text('Pengaturan Tarif Dinamis'), findsOneWidget);
    expect(find.text('Kontrol Tarif Dinamis Pracimantoro'), findsOneWidget);

    // Switch to Tab 3: Kurasi/Banner
    await tester.tap(find.text('Kurasi/Banner'));
    await tester.pumpAndSettle();
    expect(find.text('Kurasi Merchant & Banner'), findsOneWidget);
    expect(find.text('Kurasi Merchant & BaBe'), findsOneWidget);
    expect(find.text('In-Place Banner Editor'), findsOneWidget);
  });
}
