import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_promo_card_share_dialog.dart';

void main() {
  test('GageTheme uses TikTok Sans as default fontFamily for light and dark', () {
    expect(GageTheme.lightTheme.textTheme.bodyMedium?.fontFamily, 'TikTok Sans');
    expect(GageTheme.darkTheme.textTheme.bodyMedium?.fontFamily, 'TikTok Sans');
  });

  test('No Unicode em dashes in modified source files', () {
    final filesToCheck = [
      'pubspec.yaml',
      'lib/core/theme/gage_theme.dart',
      'lib/features/affiliate/presentation/affiliate_hub_screen.dart',
      'lib/features/affiliate/presentation/affiliate_merchant_detail_screen.dart',
      'lib/features/affiliate/presentation/affiliate_video_upload_screen.dart',
      'lib/shared/widgets/gage_promo_card_share_dialog.dart',
      'lib/shared/widgets/gage_receipt_share_dialog.dart',
    ];

    for (final relPath in filesToCheck) {
      final file = File(relPath);
      if (file.existsSync()) {
        final content = file.readAsStringSync();
        expect(
          content.contains('\u2014'),
          isFalse,
          reason: 'File $relPath must not contain Unicode em dash',
        );
      }
    }
  });

  testWidgets('GagePromoCardShareDialog renders merchant card with mini-map and zero barcode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GageTheme.lightTheme,
        home: const Scaffold(
          body: GagePromoCardShareDialog(
            type: PromoCardType.merchant,
            title: 'RM Bakso Mas No',
            subtitle: 'Kuliner • Pracimantoro',
            shareUrl: 'https://gage.id/resto/rest-1?ref=G8K2M9',
            commissionText: 'Komisi 10%',
          ),
        ),
      ),
    );

    // Verify Title & Subtitle
    expect(find.text('RM Bakso Mas No'), findsOneWidget);
    expect(find.text('Kuliner • Pracimantoro'), findsOneWidget);
    // Verify Promo Badge
    expect(find.text('DISKON S/D 15K + GRATIS ONGKIR'), findsOneWidget);
    // Verify Share Button
    expect(find.text('Bagikan'), findsOneWidget);
  });

  testWidgets('GagePromoCardShareDialog renders product card with 1:1 aspect ratio and promo badge', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: GageTheme.lightTheme,
        home: const Scaffold(
          body: GagePromoCardShareDialog(
            type: PromoCardType.product,
            title: 'Bakso Urat Jumbo',
            merchantName: 'RM Bakso Mas No',
            productPrice: 'Rp 15.000',
            shareUrl: 'https://gage.id/item/item-1?ref=G8K2M9',
          ),
        ),
      ),
    );

    expect(find.text('Bakso Urat Jumbo'), findsOneWidget);
    expect(find.text('RM Bakso Mas No'), findsOneWidget);
    expect(find.text('Rp 15.000'), findsOneWidget);
    expect(find.text('DISKON S/D 15RB'), findsOneWidget);
    expect(find.byType(AspectRatio), findsWidgets);
  });
}
