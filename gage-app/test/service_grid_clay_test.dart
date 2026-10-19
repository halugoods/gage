import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/home/presentation/widgets/service_grid_clay.dart';
import 'package:gage_app/features/babe/presentation/babe_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

class TestNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushedRoutes.add(route);
    super.didPush(route, previousRoute);
  }
}

void main() {
  group('ServiceGridClay Tests', () {
    test('Services list has exactly 8 items in the specified order', () {
      final services = ServiceGridClay.services;
      expect(services.length, equals(8));

      // 1. Ride & Car
      expect(services[0]['id'], equals('ride_car'));
      expect(services[0]['name'], equals('Ride & Car'));
      expect(services[0]['icon'], equals('assets/icons/ic_ride.png'));

      // 2. GAGE Food
      expect(services[1]['id'], equals('food'));
      expect(services[1]['name'], equals('GAGE Food'));
      expect(services[1]['icon'], equals('assets/icons/ic_food.png'));

      // 3. GAGE Shop
      expect(services[2]['id'], equals('shop'));
      expect(services[2]['name'], equals('GAGE Shop'));
      expect(services[2]['icon'], equals('assets/icons/ic_mart.png'));

      // 4. GAGE Send
      expect(services[3]['id'], equals('send'));
      expect(services[3]['name'], equals('GAGE Send'));
      expect(services[3]['icon'], equals('assets/icons/ic_send.png'));

      // 5. GAGE Tani
      expect(services[4]['id'], equals('tani'));
      expect(services[4]['name'], equals('GAGE Tani'));
      expect(services[4]['icon'], equals('assets/icons/ic_tani.png'));

      // 6. GAGE Ternak
      expect(services[5]['id'], equals('ternak'));
      expect(services[5]['name'], equals('GAGE Ternak'));
      expect(services[5]['icon'], equals('assets/icons/ic_ternak.png'));

      // 7. GAGE BaBe (Posisi ke-7)
      expect(services[6]['id'], equals('babe'));
      expect(services[6]['name'], equals('GAGE BaBe'));
      expect(services[6]['icon'], equals('assets/icons/ic_babe.png'));

      // 8. GAGE Cuan (Posisi ke-8, paling akhir)
      expect(services[7]['id'], equals('cuan'));
      expect(services[7]['name'], equals('GAGE Cuan'));
      expect(services[7]['icon'], equals('assets/icons/ic_bonus.png'));
    });

    testWidgets('Renders all 8 items and tapping GAGE BaBe pushes BabeScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final observer = TestNavigatorObserver();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider.value(value: BannerManagerService.instance),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Scaffold(
              body: ServiceGridClay(
                onFoodTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify all 8 names are rendered
      expect(find.text('Ride & Car'), findsOneWidget);
      expect(find.text('GAGE Food'), findsOneWidget);
      expect(find.text('GAGE Shop'), findsOneWidget);
      expect(find.text('GAGE Send'), findsOneWidget);
      expect(find.text('GAGE Tani'), findsOneWidget);
      expect(find.text('GAGE Ternak'), findsOneWidget);
      expect(find.text('GAGE BaBe'), findsOneWidget);
      expect(find.text('GAGE Cuan'), findsOneWidget);

      // Tap GAGE BaBe
      await tester.tap(find.text('GAGE BaBe'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(2));
      final pushedRoute = observer.pushedRoutes.last as MaterialPageRoute;
      final builtWidget = pushedRoute.builder(tester.element(find.byType(ServiceGridClay)));
      expect(builtWidget, isA<BabeScreen>());
    });

    testWidgets('Tapping GAGE Cuan pushes AffiliateHubScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final observer = TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: ServiceGridClay(
              onFoodTap: () {},
            ),
          ),
        ),
      );

      // Tap GAGE Cuan
      await tester.tap(find.text('GAGE Cuan'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(2));
      final pushedRoute = observer.pushedRoutes.last as MaterialPageRoute;
      final builtWidget = pushedRoute.builder(tester.element(find.byType(ServiceGridClay)));
      expect(builtWidget, isA<AffiliateHubScreen>());
    });

    testWidgets('Tapping GAGE Food invokes onFoodTap callback', (WidgetTester tester) async {
      bool foodTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceGridClay(
              onFoodTap: () {
                foodTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('GAGE Food'));
      await tester.pump();

      expect(foodTapped, isTrue);
    });

    testWidgets('Grid 4x2 renders without overflow even on small 320x568 screen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ServiceGridClay(
              onFoodTap: () {},
            ),
          ),
        ),
      );

      // No assertion or overflow exceptions thrown
      expect(tester.takeException(), isNull);
    });
  });
}
