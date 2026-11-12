import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('MiniLocationPreviewMap Reactive Camera Sync', () {
    testWidgets('updates MapController camera when location prop changes', (tester) async {
      const initialCoord = LatLng(-8.05517, 110.80889);
      const updatedCoord = LatLng(-8.07727, 110.84537);
      LatLng activeCoord = initialCoord;
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) => Column(
                children: [
                  MiniLocationPreviewMap(
                    location: activeCoord,
                    size: 68,
                    onTap: () {
                      tapped = true;
                      setState(() => activeCoord = updatedCoord);
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final mapWidget1 = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(mapWidget1.mapController, isNotNull);
      expect(mapWidget1.mapController!.camera.center.latitude, closeTo(initialCoord.latitude, 0.0001));
      expect(mapWidget1.mapController!.camera.center.longitude, closeTo(initialCoord.longitude, 0.0001));
      expect(mapWidget1.mapController!.camera.zoom, closeTo(16.5, 0.01));

      await tester.tap(find.byType(MiniLocationPreviewMap));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tapped, isTrue);
      final mapWidget2 = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(mapWidget2.mapController!.camera.center.latitude, closeTo(updatedCoord.latitude, 0.0001));
      expect(mapWidget2.mapController!.camera.center.longitude, closeTo(updatedCoord.longitude, 0.0001));
    });
  });

  group('CartProvider Delivery Location Persistence', () {
    test('stores and reloads selected coordinates while stripping legacy Yogyakarta dummy placeholder', () async {
      SharedPreferences.setMockInitialValues({
        'gage_saved_cart': '{"merchant_id":"m1","delivery_address":"Jl. Wates Km 3, Kadipiro, Kasihan","items":[]}',
      });

      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(cart.deliveryAddress, isEmpty);
      expect(cart.deliveryLocation, isNull);
      expect(cart.hasCustomDeliveryLocation, isFalse);

      const chosenLoc = LatLng(-8.0612, 110.8154);
      cart.setDeliveryAddress('Pasar Pracimantoro, Wonogiri', 1.2, location: chosenLoc);

      expect(cart.deliveryAddress, equals('Pasar Pracimantoro, Wonogiri'));
      expect(cart.deliveryLocation, equals(chosenLoc));
      expect(cart.hasCustomDeliveryLocation, isTrue);
    });
  });

  group('CheckoutScreen Minimap Displays Selected Coordinate', () {
    testWidgets('CheckoutScreen initializes MiniLocationPreviewMap to CartProvider selected location', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const customTarget = LatLng(-8.05460, 110.80660);
      final cart = CartProvider();
      cart.addItem(
        CartItemModel(
          menuId: 'f1',
          merchantId: 'm1',
          merchantName: 'Dimsum Sewu Pracimantoro',
          name: 'Dimsum Ayam',
          price: 15000,
          quantity: 1,
          category: 'Dimsum',
          serviceType: 'food',
        ),
      );
      cart.setDeliveryAddress('SD Muhammadiyah PK Pracimantoro', 1.4, location: customTarget);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
            ChangeNotifierProvider<WalletProvider>(create: (_) => WalletProvider()),
            ChangeNotifierProvider<CartProvider>.value(value: cart),
            ChangeNotifierProvider<OrderProvider>(create: (_) => OrderProvider()),
            ChangeNotifierProvider.value(value: BannerManagerService.instance),
          ],
          child: const MaterialApp(
            home: CheckoutScreen(serviceType: 'food'),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('SD Muhammadiyah PK Pracimantoro'), findsOneWidget);
      final miniMap = tester.widget<MiniLocationPreviewMap>(find.byType(MiniLocationPreviewMap));
      expect(miniMap.location.latitude, closeTo(customTarget.latitude, 0.0001));
      expect(miniMap.location.longitude, closeTo(customTarget.longitude, 0.0001));

      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(flutterMap.mapController!.camera.center.latitude, closeTo(customTarget.latitude, 0.0001));
      expect(flutterMap.mapController!.camera.center.longitude, closeTo(customTarget.longitude, 0.0001));
    });
  });
}
