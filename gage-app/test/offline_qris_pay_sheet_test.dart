import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/features/wallet/presentation/offline_qris_pay_sheet.dart';
import 'package:gage_app/providers/wallet_provider.dart';

void main() {
  testWidgets('OfflineQrisPaySheet renders 1:1 scanner and modern UI without errors',
      (WidgetTester tester) async {
    final walletProvider = WalletProvider();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<WalletProvider>.value(
          value: walletProvider,
          child: const Scaffold(
            body: OfflineQrisPaySheet(),
          ),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Title & Identity
    expect(find.text('GAGE QRIS Pay'), findsOneWidget);
    expect(find.text('Penyedia QRIS Resmi Mitra Pracimantoro'), findsOneWidget);

    // Verify 1:1 Viewfinder Corners exist
    expect(find.byType(QrViewfinderCorners), findsOneWidget);

    // Verify initial scanning text
    expect(find.text('Arahkan kamera ke QRIS Merchant...'), findsOneWidget);

    // Verify quick demo button exists
    expect(find.text('Pindai Contoh QRIS Merchant GAGE'), findsOneWidget);
  });
}
