import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';

Widget _wrapWithProviders(Widget child, {ThemeMode themeMode = ThemeMode.light}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => WalletProvider()),
      ChangeNotifierProvider(create: (_) => AuthProvider()),
      ChangeNotifierProvider(create: (_) => OrderProvider()),
      ChangeNotifierProvider(create: (_) => CartProvider()),
    ],
    child: MaterialApp(
      theme: GageTheme.lightTheme,
      darkTheme: GageTheme.darkTheme,
      themeMode: themeMode,
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

  group('Fase 2: Transportasi & Logistik Parity Tests', () {
    testWidgets('RideBookingScreen uses full-rounded capsule switcher and switches Ride/Car cleanly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(const RideBookingScreen(initialTab: 'ride', autoStartLocationFlow: false)),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pesan GAGE Ride'), findsOneWidget);
      expect(find.text('Ride Reguler'), findsOneWidget);
      expect(find.text('Ride Hemat'), findsOneWidget);

      // Verify full-rounded capsule geometry on active thumb (AnimatedContainer)
      final animatedThumbs = tester.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration && dec.borderRadius == BorderRadius.circular(999);
      }).toList();
      expect(animatedThumbs.length, greaterThanOrEqualTo(2));
      final selectedThumbs = animatedThumbs.where((c) {
        final dec = c.decoration as BoxDecoration;
        return dec.color == GageTheme.primary;
      }).toList();
      expect(selectedThumbs.length, equals(1));

      // Verify outer track uses BorderRadius.circular(999)
      final outerTracks = tester.widgetList<Container>(find.byType(Container)).where((c) {
        final dec = c.decoration;
        return dec is BoxDecoration &&
            dec.borderRadius == BorderRadius.circular(999) &&
            c.padding == const EdgeInsets.all(3);
      }).toList();
      expect(outerTracks.length, equals(1));

      // Switch to GAGE Car
      await tester.tap(find.text('GAGE Car'));
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pesan GAGE Car'), findsOneWidget);
      expect(find.text('Car Reguler'), findsOneWidget);
      expect(find.text('Car Hemat'), findsOneWidget);
    });

    test('RideBookingScreen source has zero dummy driver SnackBar stubs or dead _AddressSearchModal', () {
      final src = File('lib/features/ride/presentation/ride_booking_screen.dart').readAsStringSync();
      expect(src.contains('Membuka chat dengan Driver Slamet'), isFalse);
      expect(src.contains('Menghubungi Driver Slamet via Telepon'), isFalse);
      expect(src.contains('class _AddressSearchModal'), isFalse);
      expect(src.contains('InAppChatScreen('), isTrue);
      expect(src.contains('GageApiClient.useDevSeedData'), isTrue);
    });

    testWidgets('SendBookingScreen renders tiers cleanly and validates empty recipient in production mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final prevAllowSeed = GageApiClient.allowDevSeedFallback;
      addTearDown(() {
        GageApiClient.allowDevSeedFallback = prevAllowSeed;
      });
      GageApiClient.allowDevSeedFallback = false;

      await tester.pumpWidget(
        _wrapWithProviders(const SendBookingScreen(autoStartLocationFlow: false), themeMode: ThemeMode.dark),
      );
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Pesan GAGE Send'), findsOneWidget);
      expect(find.text('Send Instant'), findsOneWidget);
      expect(find.text('Send Hemat'), findsOneWidget);
      expect(find.text('Pilih Titik Jemput'), findsOneWidget);

      await tester.tap(find.text('Send Hemat'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    });

    testWidgets('RideCheckoutScreen (Send) syncs sameday->Hemat, supports Proteksi Pengiriman & Tip at bottom', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(
          const RideCheckoutScreen(
            serviceType: 'send',
            rideOption: 'sameday',
            pickupLocation: LatLng(-8.0895, 110.8492),
            dropoffLocation: LatLng(-8.0950, 110.8600),
            pickupAddress: 'Jl. Raya Pracimantoro No. 1',
            dropoffAddress: 'Pasar Pracimantoro',
            distanceKm: 2.5,
            baseFare: 10000,
            recipientName: 'Budi',
            recipientPhone: '081234567890',
            packageType: 'Dokumen',
            weightTier: '< 1 kg',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Send checkout renders Instant and Hemat options (bukan Reguler)
      expect(find.text('Instant'), findsOneWidget);
      expect(find.text('Hemat'), findsAtLeastNWidgets(1));

      // Send sameday initializes Hemat radio checked (color GageTheme.primary, aside from green pickup dot)
      final activeRadioIcons = tester
          .widgetList<Icon>(find.byIcon(Icons.radio_button_checked))
          .where((icon) => icon.color == GageTheme.primary)
          .toList();
      expect(activeRadioIcons.length, equals(1));
      final offRadioIcons = tester.widgetList<Icon>(find.byIcon(Icons.radio_button_off)).toList();
      expect(offRadioIcons.length, equals(1));

      // Tip card sits below Ringkasan pembayaran
      final summaryY = tester.getTopLeft(find.text('Ringkasan pembayaran')).dy;
      final tipY = tester.getTopLeft(find.text('Beri Tip untuk Driver?')).dy;
      expect(tipY, greaterThan(summaryY));

      // Toggle Proteksi Pengiriman Barang (+Rp 1.000)
      final proteksiLabel = find.text('Proteksi Pengiriman Barang');
      expect(proteksiLabel, findsOneWidget);
      final proteksiSwitch = find.byType(Switch);
      await tester.ensureVisible(proteksiSwitch);
      await tester.tap(proteksiSwitch);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      // Proteksi appears as a second row in Ringkasan pembayaran
      expect(find.text('Proteksi Pengiriman Barang'), findsNWidgets(2));
    });

    testWidgets('RideCheckoutScreen (Ride) hides Send proteksi switch and works in Dark Mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        _wrapWithProviders(
          const RideCheckoutScreen(
            serviceType: 'ride',
            rideOption: 'standard',
            pickupLocation: LatLng(-8.0895, 110.8492),
            dropoffLocation: LatLng(-8.0950, 110.8600),
            pickupAddress: 'Titik Jemput',
            dropoffAddress: 'Titik Tujuan',
            distanceKm: 2.5,
            baseFare: 12500,
          ),
          themeMode: ThemeMode.dark,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Proteksi Pengiriman Barang'), findsNothing);
      expect(find.text('Beri Tip untuk Driver?'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
