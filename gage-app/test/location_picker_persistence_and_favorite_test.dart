import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

Widget _wrapWithProviders(Widget child, {CartProvider? cartProvider}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WalletProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      if (cartProvider != null)
        ChangeNotifierProvider.value(value: cartProvider)
      else
        ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      theme: GageTheme.lightTheme,
      home: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('UserAddressService & CartProvider favorite metadata', () {
    test('matchFavoriteInList matches by id first, then 35m proximity', () {
      const favPersonal = UserSavedAddress(
        id: 'fav_home',
        name: 'Rumahku',
        address: 'Jl. Melati No. 1',
        category: 'personal',
        latitude: -8.05517,
        longitude: 110.80889,
      );
      const favBusiness = UserSavedAddress(
        id: 'fav_toko',
        name: 'Toko Berkah',
        address: 'Pasar Pracimantoro',
        category: 'business',
        latitude: -8.06000,
        longitude: 110.81500,
      );

      final byId = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        preferredId: 'fav_toko',
      );
      expect(byId?.id, equals('fav_toko'));

      final byCoord = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.05518, 110.80890),
      );
      expect(byCoord?.id, equals('fav_home'));

      final farCoord = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.09000, 110.85000),
      );
      expect(farCoord, isNull);
    });

    test('CartProvider persists deliveryLocationLabel and deliveryFavoriteId', () async {
      final cart = CartProvider();
      await Future.delayed(const Duration(milliseconds: 30));

      cart.setDeliveryAddress(
        'Pasar Pracimantoro',
        1.8,
        location: const LatLng(-8.06000, 110.81500),
        locationLabel: 'Toko Berkah',
        favoriteId: 'fav_toko',
      );
      expect(cart.deliveryLocationLabel, equals('Toko Berkah'));
      expect(cart.deliveryFavoriteId, equals('fav_toko'));

      await Future.delayed(const Duration(milliseconds: 50));

      final reloaded = CartProvider();
      await Future.delayed(const Duration(milliseconds: 50));
      expect(reloaded.deliveryLocationLabel, equals('Toko Berkah'));
      expect(reloaded.deliveryFavoriteId, equals('fav_toko'));
      expect(reloaded.deliveryLocation?.latitude, closeTo(-8.06000, 0.0001));
    });
  });

  group('LocationPickerSheet pin persistence & Add-Favorite locking', () {
    testWidgets('dragging main minimap and tapping Pakai Lokasi Ini emits dragged LatLng', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const startLoc = LatLng(-8.05517, 110.80889);
      LatLng? selectedLatLng;
      bool pickerClosed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  LocationPickerSheet.show(
                    ctx,
                    title: 'Pilih Titik Antar',
                    initialLocation: startLoc,
                    onSelected: (title, fullAddress, latLng) {
                      selectedLatLng = latLng;
                      pickerClosed = true;
                    },
                  );
                },
                child: const Text('Buka Picker'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Picker'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      final mapFinder = find.byKey(const ValueKey('main_preview_minimap'));
      expect(mapFinder, findsOneWidget);

      await tester.drag(mapFinder, const Offset(80, 60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pakai Lokasi Ini'), findsOneWidget);
      await tester.tap(find.text('Pakai Lokasi Ini'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(pickerClosed, isTrue);
      expect(selectedLatLng, isNotNull);
      expect(
        const Distance().as(LengthUnit.Meter, startLoc, selectedLatLng!),
        greaterThan(20),
      );

      // Reopen sheet with selectedLatLng and ensure map starts centered at dragged coordinate
      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Scaffold(
            body: LocationPickerSheet(
              title: 'Pilih Titik Antar',
              initialLocation: selectedLatLng,
              onSelected: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final reopenedMap = tester.widget<FlutterMap>(find.byKey(const ValueKey('main_preview_minimap')));
      expect(reopenedMap.mapController!.camera.center.latitude, closeTo(selectedLatLng!.latitude, 0.0001));
      expect(reopenedMap.mapController!.camera.center.longitude, closeTo(selectedLatLng!.longitude, 0.0001));
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('Add-Favorite minimap Pakai Lokasi Ini locks pin inside form without closing sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const startLoc = LatLng(-8.05517, 110.80889);
      bool onSelectedFired = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Scaffold(
            body: LocationPickerSheet(
              title: 'Pilih Titik Antar',
              initialLocation: startLoc,
              onSelected: (_, _, _) {
                onSelectedFired = true;
              },
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Open Tambah Alamat form from empty state
      await tester.tap(find.text('Simpan Alamat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Tambah Alamat Personal Baru'), findsOneWidget);
      final draftMapFinder = find.byKey(const ValueKey('add_favorite_draft_minimap'));
      expect(draftMapFinder, findsOneWidget);

      await tester.ensureVisible(draftMapFinder);
      await tester.pump();
      await tester.drag(draftMapFinder, const Offset(90, 70));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pakai Lokasi Ini'), findsOneWidget);
      await tester.tap(find.text('Pakai Lokasi Ini'));
      await tester.pump(const Duration(milliseconds: 250));

      // Sheet MUST remain open and form still visible with Terkunci badge
      expect(onSelectedFired, isFalse);
      expect(find.text('Terkunci'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Alamat'),
        'Rumah Baru',
      );
      await tester.pump(const Duration(milliseconds: 100));

      await tester.ensureVisible(find.text('Simpan'));
      await tester.tap(find.text('Simpan'));
      await tester.pump(const Duration(milliseconds: 350));

      final savedFavs = await UserAddressService.getFavorites();
      expect(savedFavs.any((f) => f.name == 'Rumah Baru'), isTrue);
      final saved = savedFavs.firstWhere((f) => f.name == 'Rumah Baru');
      expect(
        const Distance().as(LengthUnit.Meter, startLoc, saved.location),
        greaterThan(20),
      );
      await tester.pump(const Duration(seconds: 3));
    });
  });

  group('Favorite selection persistence & interaction banners', () {
    const savedBusinessFav = UserSavedAddress(
      id: 'fav_toko_maju',
      name: 'Toko Maju',
      address: 'Jl. Raya Pracimantoro No. 9',
      category: 'business',
      latitude: -8.06120,
      longitude: 110.81650,
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({
        'gage_saved_favorites_v1': jsonEncode([savedBusinessFav.toJson()]),
      });
    });

    testWidgets('LocationPickerSheet places in-card Ganti action with Terpilih badge and omits top banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Scaffold(
            body: LocationPickerSheet(
              title: 'Pilih Titik Antar',
              initialLocation: savedBusinessFav.location,
              initialLocationTitle: savedBusinessFav.name,
              selectedFavoriteId: savedBusinessFav.id,
              onSelected: (_, _, _) {},
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.textContaining('Dipilih dari Alamat Favorit'), findsNothing);
      expect(find.text('Terpilih'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
      expect(find.text('Ganti'), findsOneWidget);
      expect(find.text('Toko Maju'), findsAtLeastNWidgets(1));

      // Verify Personal/Bisnis switcher uses capsule 999 geometry
      final capsuleThumbs = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.borderRadius == BorderRadius.circular(999) &&
            dec.color == GageTheme.primary;
      }).toList();
      expect(capsuleThumbs.length, equals(1));

      // Tapping in-card Ganti clears selection highlight to let user pick another address
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pump();
      expect(find.text('Terpilih'), findsNothing);
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('CheckoutScreen shows Favorit badge when active location matches favorite', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final cart = CartProvider();
      cart.addItem(CartItemModel(
        menuId: 'item1',
        name: 'Ayam Geprek',
        price: 18000,
        imageUrl: 'assets/images/food_ayam_geprek.jpg',
        merchantId: 'mch_1',
        merchantName: 'Warung Geprek',
        quantity: 1,
      ));
      cart.setDeliveryAddress(
        savedBusinessFav.address,
        1.5,
        location: savedBusinessFav.location,
        locationLabel: savedBusinessFav.name,
        favoriteId: savedBusinessFav.id,
      );

      await tester.pumpWidget(
        _wrapWithProviders(const CheckoutScreen(serviceType: 'food'), cartProvider: cart),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Favorit • Toko Maju'), findsOneWidget);

      await tester.tap(find.text('Ganti').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.textContaining('Dipilih dari Alamat Favorit'), findsNothing);
      expect(find.text('Terpilih'), findsOneWidget);
      expect(find.byIcon(Icons.swap_horiz_rounded), findsOneWidget);
    });

    testWidgets('RideCheckoutScreen shows dual minimaps and Favorit badge on dropoff & pickup cards', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(
          RideCheckoutScreen(
            serviceType: 'ride',
            rideOption: 'REGULER',
            pickupLocation: const LatLng(-8.05517, 110.80889),
            dropoffLocation: savedBusinessFav.location,
            pickupAddress: 'Alun-Alun Pracimantoro',
            dropoffAddress: savedBusinessFav.address,
            distanceKm: 2.1,
            baseFare: 12000,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Titik Jemput'), findsOneWidget);
      expect(find.text('Titik Tujuan'), findsOneWidget);
      expect(find.text('Favorit • Toko Maju'), findsOneWidget);

      final combinedCard = find.byKey(const ValueKey('checkout_combined_route_card'));
      expect(combinedCard, findsOneWidget);

      final minimapFinders = find.descendant(
        of: combinedCard,
        matching: find.byType(MiniLocationPreviewMap),
      );
      expect(minimapFinders, findsNWidgets(2));
      final topMapRect = tester.getRect(minimapFinders.at(0));
      final bottomMapRect = tester.getRect(minimapFinders.at(1));
      expect(topMapRect.top < bottomMapRect.top, isTrue);

      final dotsFinder = find.descendant(
        of: combinedCard,
        matching: find.byKey(const ValueKey('checkout_route_dots_connector')),
      );
      expect(dotsFinder, findsOneWidget);
      final dotsRect = tester.getRect(dotsFinder);
      expect(dotsRect.top >= topMapRect.bottom - 4, isTrue);
      expect(dotsRect.bottom <= bottomMapRect.top + 4, isTrue);
    });

    testWidgets('RideCheckoutScreen Send shows dual minimaps and bordered voucher badge without parentheses', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(
          RideCheckoutScreen(
            serviceType: 'send',
            rideOption: 'sameday',
            pickupLocation: const LatLng(-8.05517, 110.80889),
            dropoffLocation: savedBusinessFav.location,
            pickupAddress: 'Alun-Alun Pracimantoro',
            dropoffAddress: savedBusinessFav.address,
            distanceKm: 3.0,
            baseFare: 15000,
            recipientName: 'Budi',
            recipientPhone: '081234567890',
            packageType: 'Elektronik',
            weightTier: '<5kg',
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Alamat Pengirim'), findsOneWidget);
      expect(find.text('Alamat Pengantaran'), findsOneWidget);
      expect(find.text('Pengirim'), findsOneWidget);
      expect(find.text('Favorit • Toko Maju'), findsOneWidget);
      expect(find.byType(MiniLocationPreviewMap), findsNWidgets(2));

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ringkasan pembayaran'), findsOneWidget);
      expect(find.text('Diskon Voucher'), findsOneWidget);
      expect(find.textContaining('Diskon Voucher ('), findsNothing);
    });
  });
}
