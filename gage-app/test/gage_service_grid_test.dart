import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_service_grid.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
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
  group('GageServiceGrid Tests (Updated 8 Services)', () {
    test('Services list has exactly 8 items in the specified order', () {
      final services = GageServiceGrid.services;
      expect(services.length, equals(8));

      // 1. G-Ride (Motor)
      expect(services[0]['id'], equals('ride'));
      expect(services[0]['name'], equals('G-Ride'));
      expect(services[0]['icon'], equals('assets/icons/ic_ride.png'));

      // 2. G-Car (Mobil)
      expect(services[1]['id'], equals('car'));
      expect(services[1]['name'], equals('G-Car'));
      expect(services[1]['icon'], equals('assets/icons/ic_car.png'));

      // 3. G-Food
      expect(services[2]['id'], equals('food'));
      expect(services[2]['name'], equals('G-Food'));
      expect(services[2]['icon'], equals('assets/icons/ic_food.png'));

      // 4. G-Shop
      expect(services[3]['id'], equals('shop'));
      expect(services[3]['name'], equals('G-Shop'));
      expect(services[3]['icon'], equals('assets/icons/ic_shop.png'));

      // 5. G-Send
      expect(services[4]['id'], equals('send'));
      expect(services[4]['name'], equals('G-Send'));
      expect(services[4]['icon'], equals('assets/icons/ic_send.png'));

      // 6. G-Farm
      expect(services[5]['id'], equals('farm'));
      expect(services[5]['name'], equals('G-Farm'));
      expect(services[5]['icon'], equals('assets/icons/ic_farm.png'));

      // 7. G-Cuan
      expect(services[6]['id'], equals('cuan'));
      expect(services[6]['name'], equals('G-Cuan'));
      expect(services[6]['icon'], equals('assets/icons/ic_bonus.png'));

      // 8. G-Fit (Sports)
      expect(services[7]['id'], equals('pacu'));
      expect(services[7]['name'], equals('G-Fit'));
      expect(services[7]['icon'], equals('assets/icons/ic_build.png'));
    });

    testWidgets('Renders all 8 items and tapping G-Ride pushes RideBookingScreen with ride tab', (WidgetTester tester) async {
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
            ChangeNotifierProvider(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Scaffold(
              body: GageServiceGrid(
                onFoodTap: () {},
              ),
            ),
          ),
        ),
      );

      // Verify all 8 names are rendered
      expect(find.text('G-Ride'), findsOneWidget);
      expect(find.text('G-Car'), findsOneWidget);
      expect(find.text('G-Food'), findsOneWidget);
      expect(find.text('G-Shop'), findsOneWidget);
      expect(find.text('G-Send'), findsOneWidget);
      expect(find.text('G-Farm'), findsOneWidget);
      expect(find.text('G-Cuan'), findsOneWidget);
      expect(find.text('G-Fit'), findsOneWidget);

      // Tap G-Ride
      await tester.tap(find.text('G-Ride'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(3));
      final bookingRoute = observer.pushedRoutes[1] as MaterialPageRoute;
      final builtWidget = bookingRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<RideBookingScreen>());
      final mapRoute = observer.pushedRoutes[2] as MaterialPageRoute;
      final builtMap = mapRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtMap.runtimeType.toString(), contains('FullScreenMapPicker'));
    });

    testWidgets('Tapping G-Car pushes RideBookingScreen with car tab', (WidgetTester tester) async {
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
            ChangeNotifierProvider(create: (_) => WalletProvider()),
          ],
          child: MaterialApp(
            navigatorObservers: [observer],
            home: Scaffold(
              body: GageServiceGrid(
                onFoodTap: () {},
              ),
            ),
          ),
        ),
      );

      // Tap G-Car
      await tester.tap(find.text('G-Car'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(3));
      final bookingRoute = observer.pushedRoutes[1] as MaterialPageRoute;
      final builtWidget = bookingRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<RideBookingScreen>());
      final mapRoute = observer.pushedRoutes[2] as MaterialPageRoute;
      final builtMap = mapRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtMap.runtimeType.toString(), contains('FullScreenMapPicker'));
    });

    testWidgets('Tapping G-Cuan pushes AffiliateHubScreen', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final observer = TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Scaffold(
            body: GageServiceGrid(
              onFoodTap: () {},
            ),
          ),
        ),
      );

      // Tap G-Cuan
      await tester.tap(find.text('G-Cuan'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(2));
      final pushedRoute = observer.pushedRoutes.last as MaterialPageRoute;
      final builtWidget = pushedRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<AffiliateHubScreen>());
    });

    testWidgets('Tapping G-Food invokes onFoodTap callback', (WidgetTester tester) async {
      bool foodTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GageServiceGrid(
              onFoodTap: () {
                foodTapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('G-Food'));
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
            body: GageServiceGrid(
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
