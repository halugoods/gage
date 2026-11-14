import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/open_location_code_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/shared/widgets/full_screen_map_picker.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
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
    test('matchFavoriteInList matches by id first, then strict <= 5m coordinate precision', () {
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

      // Jarak ~1.5 meter (titik sama persis dengan deviasi floating point) -> Cocok
      final byCoord = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.05518, 110.80890),
      );
      expect(byCoord?.id, equals('fav_home'));

      // Jarak ~20 meter (tetangga / titik kustom sekitar) -> DILARANG membajak (harus null)
      final nearbyCoord = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.05535, 110.80889),
      );
      expect(nearbyCoord, isNull);

      final farCoord = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.09000, 110.85000),
      );
      expect(farCoord, isNull);

      // Titik jauh meski preferredId terisi TIDAK BOLEH mencaplok favorit (menghindari duplikasi Rumah 1)
      final farCoordWithPreferredId = UserAddressService.matchFavoriteInList(
        const [favPersonal, favBusiness],
        location: const LatLng(-8.09000, 110.85000),
        preferredId: 'fav_home',
      );
      expect(farCoordWithPreferredId, isNull);
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

  group('FullScreenMapPicker recents, favorites pill, & pin persistence', () {
    testWidgets('dragging map and tapping Pakai Lokasi Ini emits dragged LatLng and saves recent', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const startLoc = LatLng(-8.05517, 110.80889);
      FullScreenMapResult? result;

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await FullScreenMapPicker.open(
                    ctx,
                    title: 'Pilih Titik Antar',
                    initialLocation: startLoc,
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

      final mapFinder = find.byType(FlutterMap);
      expect(mapFinder, findsOneWidget);

      await tester.drag(mapFinder, const Offset(80, 60));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pakai Lokasi Ini'), findsOneWidget);
      await tester.tap(find.text('Pakai Lokasi Ini'));
      await tester.pump(const Duration(milliseconds: 400));

      expect(result, isNotNull);
      expect(
        const Distance().as(LengthUnit.Meter, startLoc, result!.location),
        greaterThan(20),
      );

      final recents = await UserAddressService.getRecents();
      expect(recents, isNotEmpty);

      // Reopen picker with result.location and ensure map starts centered at dragged coordinate
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          theme: GageTheme.lightTheme,
          home: FullScreenMapPicker(
            title: 'Pilih Titik Antar',
            initialLocation: result!.location,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 250));

      final reopenedMap = tester.widget<FlutterMap>(find.byType(FlutterMap).first);
      expect(reopenedMap.mapController!.camera.center.latitude, closeTo(result!.location.latitude, 0.0001));
      expect(reopenedMap.mapController!.camera.center.longitude, closeTo(result!.location.longitude, 0.0001));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('focusing search opens Alamat Terakhir dropdown and + Favorit saves with capsule switch', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      const recentAddr = UserSavedAddress(
        id: 'rec_1',
        name: 'Pasar Pracimantoro',
        address: 'Jl. Raya Pracimantoro, Wonogiri',
        category: 'personal',
        latitude: -8.06200,
        longitude: 110.81700,
      );
      await UserAddressService.addRecent(recentAddr);

      await tester.pumpWidget(
        MaterialApp(
          theme: GageTheme.lightTheme,
          home: const FullScreenMapPicker(
            title: 'Pilih Titik Antar',
            initialLocation: LatLng(-8.05517, 110.80889),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Focus search bar with empty query -> shows Alamat Terakhir
      await tester.tap(find.byType(TextField));
      await tester.pump(const Duration(milliseconds: 250));
      expect(find.text('Alamat Terakhir'), findsOneWidget);
      expect(find.text('Pasar Pracimantoro'), findsOneWidget);

      await tester.tap(find.text('Pasar Pracimantoro'));
      await tester.pump(const Duration(milliseconds: 250));
      final movedMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      expect(movedMap.mapController!.camera.center.latitude, closeTo(-8.06200, 0.0001));

      // Tap bookmark button -> expands bottom container showing "Alamat Favorit" & "Tambah" button
      await tester.tap(find.byIcon(Icons.bookmark_add_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Saat kosong, tombol di header disembunyikan sesuai permintaan user dan muncul tombol aksi utama
      expect(find.text('Tambah Alamat Sekarang'), findsOneWidget);
      await tester.tap(find.text('Tambah Alamat Sekarang'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Memastikan alur dua tahap: pilih titik di peta terlebih dahulu
      expect(find.text('Pilih Alamat'), findsOneWidget);
      await tester.tap(find.text('Pilih Alamat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tambah Alamat Favorit'), findsOneWidget);

      final capsuleThumbs = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.borderRadius == BorderRadius.circular(999) &&
            dec.color == GageTheme.primary;
      }).toList();
      expect(capsuleThumbs.length, greaterThanOrEqualTo(1));

      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Alamat'),
        'Kios Baru',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Patokan / Catatan Pengantaran (Opsional)'),
        'Sebelah selatan pasar',
      );

      // Verifikasi tombol Ubah Titik berfungsi kembali ke peta tanpa menghapus data form
      expect(find.text('Ubah Titik'), findsOneWidget);
      await tester.tap(find.text('Ubah Titik'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Pilih Alamat'), findsOneWidget);
      await tester.tap(find.text('Pilih Alamat'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Tambah Alamat Favorit'), findsOneWidget);
      expect(find.text('Kios Baru'), findsOneWidget);

      await tester.ensureVisible(find.text('Simpan Lokasi Ini'));
      await tester.tap(find.text('Simpan Lokasi Ini'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      final savedFavs = await UserAddressService.getFavorites();
      expect(savedFavs.any((f) => f.name == 'Kios Baru'), isTrue);
      expect(find.text('Kios Baru'), findsAtLeastNWidgets(1));
      expect(find.text('Favorit'), findsOneWidget);

      // Tap bookmark button (now active) -> open list, edit favorite, then delete
      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pumpAndSettle();

      // Uji fitur Edit Alamat Favorit
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Edit Alamat Favorit'), findsOneWidget);
      expect(find.text('Simpan Perubahan'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nama Alamat'),
        'Kios Baru Edit',
      );
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      final updatedFavs = await UserAddressService.getFavorites();
      expect(updatedFavs.any((f) => f.name == 'Kios Baru Edit'), isTrue);

      // Reopen favorites list to test delete
      await tester.tap(find.byIcon(Icons.bookmark_rounded));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Hapus Alamat Favorit?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Hapus'));
      await tester.pumpAndSettle();

      final reloadedFavs = await UserAddressService.getFavorites();
      expect(reloadedFavs.any((f) => f.name.contains('Kios Baru')), isFalse);

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    });

    test('OsmGeocodingService scopes instant search strictly to Kecamatan Pracimantoro and supports Plus Codes', () {
      final villageHits = OsmGeocodingService.searchLocalInstant('Tubokarto');
      expect(villageHits.any((p) => p.title.toLowerCase().contains('tubokarto')), isTrue);
      expect(villageHits.every((p) => OsmGeocodingService.isWithinPracimantoro(p.location)), isTrue);

      final neighborHits = OsmGeocodingService.searchLocalInstant('Giritontro');
      expect(neighborHits, isEmpty);

      const center = LatLng(-8.05517, 110.80889);
      final plusCode = OpenLocationCodeService.getShortPlusCode(center);
      final plusHits = OsmGeocodingService.searchLocalInstant(plusCode);
      expect(plusHits, isNotEmpty);
      expect(const Distance().as(LengthUnit.Meter, center, plusHits.first.location), lessThan(25));
    });
  });

  group('Favorite selection persistence & FullScreenMapPicker checkout integration', () {
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

    testWidgets('CheckoutScreen shows Favorit badge and tapping Ganti directly opens FullScreenMapPicker', (tester) async {
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

      expect(find.byType(FullScreenMapPicker), findsOneWidget);
      expect(find.text('Toko Maju'), findsAtLeastNWidgets(1));
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
      expect(find.text('Favorit • Toko Maju'), findsOneWidget);
      expect(find.byType(MiniLocationPreviewMap), findsNWidgets(2));

      await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -600));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Ringkasan pembayaran'), findsOneWidget);
      expect(find.text('Diskon Voucher'), findsOneWidget);
      expect(find.textContaining('Diskon Voucher ('), findsNothing);
    });
  });

  group('OrderModel cancellation & Customer UX', () {
    OrderModel makeTestOrder({
      required String id,
      required String orderNumber,
      required String serviceType,
      required String status,
      String? driverName,
    }) {
      return OrderModel(
        id: id,
        orderNumber: orderNumber,
        userId: 'cust_1',
        merchantId: 'merch_1',
        merchantName: 'Mitra',
        merchantAddress: 'Tubokarto',
        serviceType: serviceType,
        status: status,
        driverName: driverName,
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 12000,
        itemsSubtotal: 10000,
        shippingFee: 2000,
        shippingDiscount: 0,
        adminFee: 0,
        deliveryAddress: 'Jl. Tubokarto',
        distanceKm: 1.0,
        trackingToken: 'tok_1',
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );
    }

    test('canBeCancelledByCustomer enforces strict transport and merchant gates', () {
      final rideSearching = makeTestOrder(
        id: 'ord_ride_1',
        orderNumber: 'RIDE-001',
        serviceType: 'ride',
        status: 'SEARCHING_DRIVER',
      );
      expect(rideSearching.canBeCancelledByCustomer, isTrue);

      final rideAssigned = makeTestOrder(
        id: 'ord_ride_2',
        orderNumber: 'RIDE-002',
        serviceType: 'ride',
        status: 'DRIVER_ASSIGNED',
        driverName: 'Pak Joko',
      );
      expect(rideAssigned.canBeCancelledByCustomer, isFalse);

      final foodWaiting = makeTestOrder(
        id: 'ord_food_1',
        orderNumber: 'FOOD-001',
        serviceType: 'food',
        status: 'WAITING_MERCHANT',
      );
      expect(foodWaiting.canBeCancelledByCustomer, isTrue);

      final foodCooking = makeTestOrder(
        id: 'ord_food_2',
        orderNumber: 'FOOD-002',
        serviceType: 'food',
        status: 'COOKING',
      );
      expect(foodCooking.canBeCancelledByCustomer, isFalse);
    });
  });
}
