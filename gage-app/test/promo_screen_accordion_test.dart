import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';

void main() {
  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('PromoScreen Accordion Header Redesign & Voucher Categorization', () {
    testWidgets('displays Ongkir at top followed by distinct Food, Shop, Farm, Build, Transport, Send (20 total, zero Mart)', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithProviders(const PromoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Voucher Diskon Ongkir (5)'), findsOneWidget);
      expect(find.text('Voucher GAGE Food (2)'), findsOneWidget);
      expect(find.text('Voucher GAGE Shop (2)'), findsOneWidget);
      expect(find.text('Voucher GAGE Farm (2)'), findsOneWidget);
      expect(find.text('Voucher GAGE Build (2)'), findsOneWidget);
      expect(find.text('Voucher Transportasi (Ride & Car) (5)'), findsOneWidget);
      expect(find.text('Voucher GAGE Send (2)'), findsOneWidget);

      // GAGE Mart must not exist anywhere in PromoScreen
      expect(find.textContaining('GAGE Mart'), findsNothing);
      expect(find.text('BELANJAMART'), findsNothing);

      // Verify vertical ordering: Diskon Ongkir at the very top, then Food, Shop, Farm, Build
      final ongkirY = tester.getTopLeft(find.text('Voucher Diskon Ongkir (5)')).dy;
      final foodY = tester.getTopLeft(find.text('Voucher GAGE Food (2)')).dy;
      final shopY = tester.getTopLeft(find.text('Voucher GAGE Shop (2)')).dy;
      final farmY = tester.getTopLeft(find.text('Voucher GAGE Farm (2)')).dy;
      final buildY = tester.getTopLeft(find.text('Voucher GAGE Build (2)')).dy;
      expect(ongkirY, lessThan(foodY));
      expect(foodY, lessThan(shopY));
      expect(shopY, lessThan(farmY));
      expect(farmY, lessThan(buildY));

      // Verify Food cards show distinct GAGE Food stub label instead of generic Diskon
      expect(find.text('GAGE\nFood'), findsNWidgets(2));
      expect(find.text('BELANJAHEMAT'), findsOneWidget);
      expect(find.text('SUBSIDITANI'), findsOneWidget);
      expect(find.text('PROYEKHEMAT'), findsOneWidget);
    });

    testWidgets('accordion headers are unboxed without container card decoration', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithProviders(const PromoScreen()));
      await tester.pumpAndSettle();

      final headerFinder = find.text('Voucher Diskon Ongkir (5)');
      expect(headerFinder, findsOneWidget);

      final inkWellFinder = find.ancestor(of: headerFinder, matching: find.byType(InkWell)).first;
      final inkWellWidget = tester.widget<InkWell>(inkWellFinder);
      expect(inkWellWidget.child, isA<Padding>());

      final paddingWidget = inkWellWidget.child as Padding;
      expect(paddingWidget.child, isA<Row>());
    });

    testWidgets('accordion sections expand and collapse independently on tap', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithProviders(const PromoScreen()));
      await tester.pumpAndSettle();

      final accordionListView = find.byType(ListView).first;

      expect(
        find.descendant(of: accordionListView, matching: find.text('ONGKIRGRATIS')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: accordionListView, matching: find.text('DISKON50')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: accordionListView, matching: find.text('SUBSIDITANI')),
        findsOneWidget,
      );

      // Tap Voucher GAGE Food header to collapse it
      await tester.tap(find.text('Voucher GAGE Food (2)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: accordionListView, matching: find.text('DISKON50')),
        findsNothing,
      );
      expect(
        find.descendant(of: accordionListView, matching: find.text('ONGKIRGRATIS')),
        findsOneWidget,
      );

      // Tap Voucher GAGE Food header again to re-expand
      await tester.tap(find.text('Voucher GAGE Food (2)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: accordionListView, matching: find.text('DISKON50')),
        findsOneWidget,
      );

      // Tap Voucher Diskon Ongkir header to collapse it
      await tester.tap(find.text('Voucher Diskon Ongkir (5)'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: accordionListView, matching: find.text('ONGKIRGRATIS')),
        findsNothing,
      );
      expect(
        find.descendant(of: accordionListView, matching: find.text('SUBSIDITANI')),
        findsOneWidget,
      );
    });

    testWidgets('header chevron toggles between up and down when section collapsed', (tester) async {
      tester.view.physicalSize = const Size(600, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(wrapWithProviders(const PromoScreen()));
      await tester.pumpAndSettle();

      // Initially all 7 headers are expanded
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNWidgets(7));
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);

      // Collapse Voucher GAGE Build
      await tester.tap(find.text('Voucher GAGE Build (2)'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsNWidgets(6));
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);
    });
  });
}
