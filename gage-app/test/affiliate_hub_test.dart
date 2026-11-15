import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

void main() {
  testWidgets('AffiliateHubScreen builds cleanly with white clean theme, commission card and 3 capsule tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AffiliateHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AffiliateHubScreen), findsOneWidget);
    expect(find.text('GAGE Cuan'), findsOneWidget);
    expect(find.text('Pusat Afiliasi & Kreator'), findsOneWidget);
    expect(find.text('Saldo Komisi Siap Tarik'), findsOneWidget);
    expect(find.text('Tarik ke GAGEPay'), findsOneWidget);
    expect(find.text('GAGE-CUAN-RATIH'), findsOneWidget);
    expect(find.text('Ajak Teman Cuan'), findsOneWidget);

    // Verify 3 capsule tabs
    expect(find.text('Video Saya'), findsOneWidget);
    expect(find.text('Katalog Cuan'), findsOneWidget);
    expect(find.text('Riwayat Komisi'), findsOneWidget);

    // Switch to Katalog Cuan tab
    await tester.tap(find.text('Katalog Cuan'));
    await tester.pumpAndSettle();

    // Verify high commission products are listed
    expect(find.text('Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)'), findsOneWidget);
    expect(find.textContaining('Pencairan merchant utuh:'), findsAtLeastNWidgets(1));
  });
}
