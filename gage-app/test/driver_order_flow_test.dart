import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';

void main() {
  group('GAGE Driver Order & Wallet Flow Tests', () {
    test('DriverOrderProvider initializes with online status and all 5 services', () {
      final provider = DriverOrderProvider();
      expect(provider.isOnline, isTrue);
      expect(provider.activeServices.length, 5);
      expect(provider.activeServices.contains('ride'), isTrue);
      expect(provider.activeServices.contains('car'), isTrue);
      expect(provider.activeServices.contains('food'), isTrue);
      expect(provider.activeServices.contains('send'), isTrue);
      expect(provider.activeServices.contains('shop'), isTrue);
      expect(provider.activeTrip, isNull);
      expect(provider.incomingOffer, isNull);
    });

    test('DriverOrderProvider service toggles work properly and prevent empty set', () {
      final provider = DriverOrderProvider();

      provider.toggleService('car');
      expect(provider.activeServices.contains('car'), isFalse);

      provider.toggleService('car');
      expect(provider.activeServices.contains('car'), isTrue);
    });

    test('DriverOrderProvider triggers incoming offer, accepts, and advances lifecycle', () async {
      final orderProv = DriverOrderProvider();
      final walletProv = DriverWalletProvider();
      final initialBalance = walletProv.balance;

      // 1. Pemicu tawaran order simulasi
      orderProv.triggerMockIncomingOrder();
      expect(orderProv.incomingOffer, isNotNull);
      final offer = orderProv.incomingOffer!;
      expect(offer.driverEarnings, greaterThan(0));

      // 2. Terima order
      final accepted = await orderProv.acceptIncomingOffer();
      expect(accepted, isTrue);
      expect(orderProv.incomingOffer, isNull);
      expect(orderProv.activeTrip, isNotNull);
      expect(orderProv.tripStep, 0);

      // 3. Maju ke Step 1 (Tiba di Lokasi Jemput)
      final step1Done = await orderProv.advanceTripStep();
      expect(step1Done, isFalse);
      expect(orderProv.tripStep, 1);

      // 4. Maju ke Step 2 (Bawa Pesanan)
      final step2Done = await orderProv.advanceTripStep();
      expect(step2Done, isFalse);
      expect(orderProv.tripStep, 2);

      // 5. Maju ke Step 3 (Selesai Trip)
      final step3Done = await orderProv.advanceTripStep();
      expect(step3Done, isTrue);
      expect(orderProv.activeTrip, isNull);
      expect(orderProv.completedTrips.length, 1);

      // 6. Masukkan saldo ke dompet
      walletProv.addEarnings(offer.driverEarnings);
      expect(walletProv.balance, initialBalance + offer.driverEarnings);
      expect(walletProv.todayTrips, 6);
    });

    test('triggerMockIncomingOrder selects specific service accurately', () {
      final orderProv = DriverOrderProvider();

      // Food
      orderProv.triggerMockIncomingOrder(serviceType: 'food');
      expect(orderProv.incomingOffer?.serviceType, 'food');
      orderProv.declineIncomingOffer();

      // Ride
      orderProv.triggerMockIncomingOrder(serviceType: 'ride');
      expect(orderProv.incomingOffer?.serviceType, 'ride');
      orderProv.declineIncomingOffer();

      // Send
      orderProv.triggerMockIncomingOrder(serviceType: 'send');
      expect(orderProv.incomingOffer?.serviceType, 'send');
      orderProv.declineIncomingOffer();

      // Car
      orderProv.triggerMockIncomingOrder(serviceType: 'car');
      expect(orderProv.incomingOffer?.serviceType, 'car');
      orderProv.declineIncomingOffer();
    });

    test('toggleAutoBid updates auto-bid flag and accepts incoming offer automatically', () async {
      final orderProv = DriverOrderProvider();
      expect(orderProv.isAutoBid, isFalse);

      orderProv.toggleAutoBid(true);
      expect(orderProv.isAutoBid, isTrue);

      orderProv.triggerMockIncomingOrder();
      expect(orderProv.incomingOffer, isNotNull);

      // Wait for autoBidTimer (1200ms)
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(orderProv.activeTrip, isNotNull);
      expect(orderProv.incomingOffer, isNull);
    });
  });
}
