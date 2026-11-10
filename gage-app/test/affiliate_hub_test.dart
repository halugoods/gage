import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

void main() {
  testWidgets('AffiliateHubScreen builds cleanly with obsidian commission card and 3 production tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AffiliateHubScreen(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(AffiliateHubScreen), findsOneWidget);
    expect(find.text('GAGE Cuan'), findsOneWidget);
    expect(find.text('Mitra Affiliator Resmi'), findsOneWidget);
    expect(find.text('Saldo Komisi Siap Tarik'), findsOneWidget);
    expect(find.text('Tarik Saldo'), findsOneWidget);
    expect(find.text('GAGE-CUAN-RATIH'), findsOneWidget);

    // Verify 3 production tabs
    expect(find.text('Katalog Cuan'), findsOneWidget);
    expect(find.text('Performa & CVR'), findsOneWidget);
    expect(find.text('Riwayat Penarikan'), findsOneWidget);

    // Verify high commission products are listed
    expect(find.text('Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)'), findsOneWidget);
  });
}
