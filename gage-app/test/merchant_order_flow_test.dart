import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MerchantOrderProvider Tests', () {
    late MerchantOrderProvider provider;

    setUp(() {
      provider = MerchantOrderProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state contains active orders and default settings', () {
      expect(provider.isOpen, isTrue);
      expect(provider.autoAccept, isTrue);
      expect(provider.printerConnected, isTrue);
      expect(provider.activeOrders.isNotEmpty, isTrue);
      expect(provider.activeOrderCount, greaterThan(0));
    });

    test('acceptOrder transitions order from NEW to COOKING', () async {
      final newOrders = provider.activeOrders.where((o) => o.stage == 'NEW').toList();
      expect(newOrders.isNotEmpty, isTrue);
      final target = newOrders.first;

      await provider.acceptOrder(target.id);

      final updated = provider.activeOrders.firstWhere((o) => o.id == target.id);
      expect(updated.stage, 'COOKING');
    });

    test('markReadyForPickup transitions order to READY_FOR_PICKUP', () async {
      final cookingOrders = provider.activeOrders.where((o) => o.stage == 'COOKING').toList();
      expect(cookingOrders.isNotEmpty, isTrue);
      final target = cookingOrders.first;

      await provider.markReadyForPickup(target.id);

      final updated = provider.activeOrders.firstWhere((o) => o.id == target.id);
      expect(updated.stage, 'READY_FOR_PICKUP');
    });

    test('completeOrder moves order to completedOrders list', () async {
      final target = provider.activeOrders.first;
      final initialCompletedCount = provider.completedOrders.length;

      await provider.completeOrder(target.id);

      expect(provider.completedOrders.length, initialCompletedCount + 1);
      expect(provider.activeOrders.any((o) => o.id == target.id), isFalse);
    });

    test('rejectOrder moves order to cancelledOrders list', () async {
      final newOrders = provider.activeOrders.where((o) => o.stage == 'NEW').toList();
      expect(newOrders.isNotEmpty, isTrue);
      final target = newOrders.first;

      await provider.rejectOrder(target.id, 'Bahan habis');

      expect(provider.cancelledOrders.any((o) => o.id == target.id), isTrue);
      expect(provider.activeOrders.any((o) => o.id == target.id), isFalse);
    });

    test('togglePickingItem toggles isPicked status for shop orders', () {
      final shopOrders = provider.activeOrders.where((o) => o.channel == 'shop').toList();
      expect(shopOrders.isNotEmpty, isTrue);
      final order = shopOrders.first;
      final initialPicked = order.items.first.isPicked;

      provider.togglePickingItem(order.id, 0);

      final updated = provider.activeOrders.firstWhere((o) => o.id == order.id);
      expect(updated.items.first.isPicked, !initialPicked);
    });

    test('setStageFilter filters activeOrders correctly', () {
      provider.setStageFilter('PERLU_DISIAPKAN');
      expect(provider.selectedStageFilter, 'PERLU_DISIAPKAN');
      expect(provider.activeOrders.every((o) => o.stage == 'NEW' || o.stage == 'COOKING'), isTrue);

      provider.setStageFilter('SIAP_DIAMBIL');
      expect(provider.selectedStageFilter, 'SIAP_DIAMBIL');
      expect(provider.activeOrders.every((o) => o.stage == 'READY_FOR_PICKUP'), isTrue);

      provider.setStageFilter('SEMUA');
      expect(provider.selectedStageFilter, 'SEMUA');
    });

    test('triggerMockIncomingOrder prepends a new order with auto accept timer', () {
      final initialCount = provider.activeOrderCount;

      provider.triggerMockIncomingOrder();

      expect(provider.activeOrderCount, initialCount + 1);
      expect(provider.activeOrders.first.stage, 'NEW');
      expect(provider.activeOrders.first.autoAcceptSecondsRemaining, 180);
    });
  });
}
