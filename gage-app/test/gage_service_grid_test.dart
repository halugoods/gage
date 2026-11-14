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

      // 1. GAGE Ride (Motor)
      expect(services[0]['id'], equals('ride'));
      expect(services[0]['name'], equals('GAGE Ride'));
      expect(services[0]['icon'], equals('assets/icons/ic_ride.png'));

      // 2. GAGE Car (Mobil)
      expect(services[1]['id'], equals('car'));
      expect(services[1]['name'], equals('GAGE Car'));
      expect(services[1]['icon'], equals('assets/icons/ic_car.png'));

      // 3. GAGE Food
      expect(services[2]['id'], equals('food'));
      expect(services[2]['name'], equals('GAGE Food'));
      expect(services[2]['icon'], equals('assets/icons/ic_food.png'));

      // 4. GAGE Shop
      expect(services[3]['id'], equals('shop'));
      expect(services[3]['name'], equals('GAGE Shop'));
      expect(services[3]['icon'], equals('assets/icons/ic_shop.png'));

      // 5. GAGE Send
      expect(services[4]['id'], equals('send'));
      expect(services[4]['name'], equals('GAGE Send'));
      expect(services[4]['icon'], equals('assets/icons/ic_send.png'));

      // 6. GAGE Farm
      expect(services[5]['id'], equals('farm'));
      expect(services[5]['name'], equals('GAGE Farm'));
      expect(services[5]['icon'], equals('assets/icons/ic_farm.png'));

      // 7. GAGE Build
      expect(services[6]['id'], equals('build'));
      expect(services[6]['name'], equals('GAGE Build'));
      expect(services[6]['icon'], equals('assets/icons/ic_build.png'));

      // 8. GAGE Cuan
      expect(services[7]['id'], equals('cuan'));
      expect(services[7]['name'], equals('GAGE Cuan'));
      expect(services[7]['icon'], equals('assets/icons/ic_bonus.png'));
    });

    testWidgets('Renders all 8 items and tapping GAGE Ride pushes RideBookingScreen with ride tab', (WidgetTester tester) async {
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
      expect(find.text('GAGE Ride'), findsOneWidget);
      expect(find.text('GAGE Car'), findsOneWidget);
      expect(find.text('GAGE Food'), findsOneWidget);
      expect(find.text('GAGE Shop'), findsOneWidget);
      expect(find.text('GAGE Send'), findsOneWidget);
      expect(find.text('GAGE Farm'), findsOneWidget);
      expect(find.text('GAGE Build'), findsOneWidget);
      expect(find.text('GAGE Cuan'), findsOneWidget);

      // Tap GAGE Ride
      await tester.tap(find.text('GAGE Ride'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(3));
      final bookingRoute = observer.pushedRoutes[1] as MaterialPageRoute;
      final builtWidget = bookingRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<RideBookingScreen>());
      final mapRoute = observer.pushedRoutes[2] as MaterialPageRoute;
      final builtMap = mapRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtMap.runtimeType.toString(), contains('FullScreenMapPicker'));
    });

    testWidgets('Tapping GAGE Car pushes RideBookingScreen with car tab', (WidgetTester tester) async {
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

      // Tap GAGE Car
      await tester.tap(find.text('GAGE Car'));
      await tester.pump();

      expect(observer.pushedRoutes.length, equals(3));
      final bookingRoute = observer.pushedRoutes[1] as MaterialPageRoute;
      final builtWidget = bookingRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<RideBookingScreen>());
      final mapRoute = observer.pushedRoutes[2] as MaterialPageRoute;
      final builtMap = mapRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtMap.runtimeType.toString(), contains('FullScreenMapPicker'));
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
            body: GageServiceGrid(
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
      final builtWidget = pushedRoute.builder(tester.element(find.byType(GageServiceGrid)));
      expect(builtWidget, isA<AffiliateHubScreen>());
    });

    testWidgets('Tapping GAGE Food invokes onFoodTap callback', (WidgetTester tester) async {
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
