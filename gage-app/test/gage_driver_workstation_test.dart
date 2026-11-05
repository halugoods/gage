import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/features/driver/presentation/driver_root_screen.dart';
import 'package:gage_app/features/driver/presentation/widgets/incoming_offer_sheet.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GAGE Agent - Driver Workstation Specification Tests', () {
    test('1. Online / Offline Toggle and Radar Polling State', () {
      final orderProv = DriverOrderProvider();
      expect(orderProv.isOnline, isTrue);

      // Turn Offline
      orderProv.toggleOnline(false);
      expect(orderProv.isOnline, isFalse);
      expect(orderProv.incomingOffer, isNull);

      // Turn Online
      orderProv.toggleOnline(true);
      expect(orderProv.isOnline, isTrue);
    });

    test('2. Incoming Offer Sheet - 30s Countdown & Exact 80% Driver Net Cut', () {
      final orderProv = DriverOrderProvider();

      // Trigger mock order
      orderProv.triggerMockIncomingOrder(serviceType: 'food', isCash: true);
      expect(orderProv.incomingOffer, isNotNull);

      final offer = orderProv.incomingOffer!;
      // Timer countdown starts at 30 seconds
      expect(orderProv.offerCountdown, 30);

      // Store & route details
      expect(offer.storeName, isNotEmpty);
      expect(offer.pickupAddress, isNotEmpty);
      expect(offer.dropoffAddress, isNotEmpty);
      expect(offer.distanceKm, 2.5);

      // Tarif murni OSRM & Upah bersih driver (Eksak 80%)
      expect(offer.totalFare, 10000);
      expect(offer.driverEarnings, 8000); // 80% of 10.000
      expect(offer.platformFee, 2000);    // 20% of 10.000
      expect(offer.isCashCod, isTrue);
    });

    test('3. Active Trip Screen - 3 Ergonomic Stages and Action Button Labels', () async {
      final orderProv = DriverOrderProvider();
      orderProv.triggerMockIncomingOrder(serviceType: 'food', isCash: true);
      final accepted = await orderProv.acceptIncomingOffer();
      expect(accepted, isTrue);

      // Tahap 1: Menuju Toko
      expect(orderProv.tripStep, 0);

      // Advance to Tahap 2: Menunggu Makanan / Verifikasi Barang
      final step1Done = await orderProv.advanceTripStep();
      expect(step1Done, isFalse);
      expect(orderProv.tripStep, 1);

      // Advance to Tahap 3: Menuju Pembeli
      final step2Done = await orderProv.advanceTripStep();
      expect(step2Done, isFalse);
      expect(orderProv.tripStep, 2);

      // Advance to Selesai
      final step3Done = await orderProv.advanceTripStep();
      expect(step3Done, isTrue);
      expect(orderProv.activeTrip, isNull);
    });

    test('4. Sistem Plafon COD Fleksibel (Batas Minus Rp 100.000 & Bebas Deposit Awal)', () {
      final walletProv = DriverWalletProvider();

      // Default balance
      expect(walletProv.canAcceptCashOrder, isTrue);
      expect(DriverWalletProvider.codCeilingLimit, -100000);
      expect(DriverWalletProvider.maxCodOverdraft, 100000);

      // Saldo nol (tanpa deposit awal sama sekali)
      walletProv.withdraw(walletProv.balance, 'BRI');
      expect(walletProv.balance, 0);
      // Kurir tetap bisa menerima order tunai COD karena ada plafon fleksibel
      expect(walletProv.canAcceptCashOrder, isTrue);
      expect(walletProv.availableCodCredit, 100000);

      // Selesaikan order tunai COD: Total Rp 10.000 (Upah Bersih Driver Rp 8.000, Platform 20% = Rp 2.000)
      walletProv.recordTripCompletion(
        tripId: 'TRIP-COD-01',
        serviceName: 'GAGE Food',
        serviceType: 'food',
        storeName: 'Mie Ayam Bakso Pak Man',
        pickupAddress: 'Jl. Raya Pracimantoro',
        dropoffAddress: 'Sambiroto',
        distanceKm: 2.5,
        driverEarnings: 8000,
        totalDeliveryFare: 10000,
        paymentMethod: 'CASH',
      );

      // Saldo menjadi minus Rp 2.000 (komisi platform terpotong, kurir bawa pulang cash Rp 10.000 di kantong)
      expect(walletProv.balance, -2000);
      expect(walletProv.todayEarnings, greaterThanOrEqualTo(8000));
      expect(walletProv.todayCashInHand, greaterThanOrEqualTo(10000));
      expect(walletProv.canAcceptCashOrder, isTrue);
      expect(walletProv.availableCodCredit, 98000); // 100.000 - 2.000

      // Jika saldo mencapai batas minus Rp 100.000
      walletProv.recordTripCompletion(
        tripId: 'TRIP-COD-OVER',
        serviceName: 'GAGE Food',
        serviceType: 'food',
        storeName: 'Toko Pracimantoro',
        pickupAddress: 'Pasar',
        dropoffAddress: 'Gedong',
        distanceKm: 3.0,
        driverEarnings: 392000,
        totalDeliveryFare: 490000,
        paymentMethod: 'CASH',
      );
      // Platform fee = 98.000 -> balance becomes -100.000
      expect(walletProv.balance, -100000);
      expect(walletProv.canAcceptCashOrder, isTrue); // tepat di batas limit
      expect(walletProv.availableCodCredit, 0);

      // Pelunasan komisi COD via QRIS/Transfer
      walletProv.topUp(50000, 'QRIS Instant');
      expect(walletProv.balance, -50000);
      expect(walletProv.availableCodCredit, 50000);
      expect(walletProv.canAcceptCashOrder, isTrue);
    });

    testWidgets('5. IncomingOfferSheet Widget renders Store, OSRM Distance, 80% Earnings, and 30s Countdown', (tester) async {
      const offer = DriverOrderOffer(
        id: 'OFFER-TEST-99',
        serviceType: 'food',
        serviceName: 'GAGE Food',
        storeName: 'Warung Makan Barokah',
        customerName: 'Budi Santoso',
        customerPhone: '081234567890',
        pickupAddress: 'Jl. Raya Pracimantoro No. 14',
        pickupLocation: LatLng(-8.0975, 110.8415),
        dropoffAddress: 'Dusun Sedayu RT 03/RW 02',
        dropoffLocation: LatLng(-8.1020, 110.8490),
        driverEarnings: 8000,
        totalFare: 10000,
        distanceKm: 2.5,
        paymentMethod: 'CASH',
        orderItems: ['1x Nasi Goreng Spesial'],
        notes: 'Rumah dekat gapura',
      );

      bool accepted = false;
      bool declined = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IncomingOfferSheet(
              offer: offer,
              countdown: 30,
              onAccept: () => accepted = true,
              onDecline: () => declined = true,
            ),
          ),
        ),
      );

      // Verify Store Name
      expect(find.text('Warung Makan Barokah'), findsOneWidget);

      // Verify OSRM Distance
      expect(find.text('2.5 KM via OSRM'), findsOneWidget);

      // Verify 80% Driver Clean Earning & Badge
      expect(find.text('EKSAK 80%'), findsOneWidget);
      expect(find.text('Rp 8.000'), findsOneWidget);

      // Verify 30 seconds countdown
      expect(find.text('30 detik'), findsOneWidget);

      // Verify Big Tactile Buttons
      final acceptButton = find.text('TERIMA ORDER');
      final declineButton = find.text('Tolak');
      expect(acceptButton, findsOneWidget);
      expect(declineButton, findsOneWidget);

      await tester.tap(acceptButton);
      expect(accepted, isTrue);

      await tester.tap(declineButton);
      expect(declined, isTrue);
    });

    testWidgets('6. DriverRootScreen renders bottom nav and primary workstation', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
            ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
            ChangeNotifierProvider(create: (_) => InAppChatProvider()),
            ChangeNotifierProvider.value(value: BannerManagerService.instance),
          ],
          child: const MaterialApp(
            home: DriverRootScreen(),
          ),
        ),
      );

      // Allow initial layout frames to render (DriverScreen has continuous animation)
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify bottom nav items exist
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Aktivitas'), findsOneWidget);
      expect(find.text('Pendapatan'), findsOneWidget);
      expect(find.text('Pesan'), findsOneWidget);
      expect(find.text('Akun'), findsOneWidget);
    });
  });
}
