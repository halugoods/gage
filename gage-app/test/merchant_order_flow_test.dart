import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GAGE Merchant Workstation Provider & Flow Tests', () {
    late MerchantOrderProvider provider;
    late InAppChatProvider chatProvider;

    setUp(() {
      provider = MerchantOrderProvider();
      chatProvider = InAppChatProvider();
    });

    tearDown(() {
      provider.dispose();
    });

    test('Initial state contains active orders and default workstation settings', () {
      expect(provider.isOpen, isTrue);
      expect(provider.autoAccept, isTrue);
      expect(provider.printerConnected, isTrue);
      expect(provider.activeOrders.isNotEmpty, isTrue);
      expect(provider.activeOrderCount, greaterThan(0));
      expect(provider.acceptanceScore, greaterThanOrEqualTo(90.0));
    });

    test('acceptOrder transitions order from NEW to COOKING and tracks acceptance score', () async {
      final newOrders = provider.activeOrders.where((o) => o.status == 'NEW').toList();
      expect(newOrders.isNotEmpty, isTrue);
      final target = newOrders.first;
      final prevAccepted = provider.dailyAcceptedCount;

      await provider.acceptOrder(target.id);

      final updated = provider.activeOrders.firstWhere((o) => o.id == target.id);
      expect(updated.status, 'COOKING');
      expect(provider.dailyAcceptedCount, prevAccepted + 1);
    });

    test('rejectOrder penalizes acceptance score and refunds 100% to GagePay', () async {
      final newOrders = provider.activeOrders.where((o) => o.status == 'NEW').toList();
      expect(newOrders.isNotEmpty, isTrue);
      final target = newOrders.first;
      final prevRejected = provider.dailyRejectedCount;

      await provider.rejectOrder(target.id, 'Bahan baku habis');

      expect(provider.dailyRejectedCount, prevRejected + 1);
      final cancelled = provider.cancelledOrders.firstWhere((o) => o.id == target.id);
      expect(cancelled.status, 'CANCELLED');
      expect(cancelled.cancellationReason, 'Bahan baku habis');
      expect(cancelled.refundAmount, target.totalAmount);
    });

    test('markReadyForPickup transitions order to READY_FOR_PICKUP', () async {
      final cookingOrders = provider.activeOrders.where((o) => o.status == 'COOKING').toList();
      expect(cookingOrders.isNotEmpty, isTrue);
      final target = cookingOrders.first;

      await provider.markReadyForPickup(target.id);

      final updated = provider.activeOrders.firstWhere((o) => o.id == target.id);
      expect(updated.status, 'READY_FOR_PICKUP');
    });

    test('completeOrder moves order to completedOrders list', () async {
      final target = provider.activeOrders.first;
      final initialCompletedCount = provider.completedOrders.length;

      await provider.completeOrder(target.id);

      expect(provider.completedOrders.length, initialCompletedCount + 1);
      expect(provider.activeOrders.any((o) => o.id == target.id), isFalse);
    });

    // ───────────────────────────────────────────────────────────────────────
    // 3 ALUR CERDAS UBAH PESANAN (STOK HABIS)
    // ───────────────────────────────────────────────────────────────────────

    test('Alur 1: Ganti Item lebih murah -> Refund instan ke GagePay & chat notice', () async {
      final cookingOrder = provider.activeOrders.firstWhere((o) => o.status == 'COOKING');
      final originalItem = cookingOrder.items.first;

      // Ganti dengan item yang lebih murah: Rp 8.000 (orig: Rp 14.000)
      const cheaperPrice = 8000;
      final expectedRefund = (originalItem.price - cheaperPrice) * originalItem.quantity;

      await provider.substituteOrderItem(
        orderId: cookingOrder.id,
        itemIndex: 0,
        newItemName: 'Dimsum Jamur Hemat',
        newItemPrice: cheaperPrice,
        chatProvider: chatProvider,
      );

      final updated = provider.activeOrders.firstWhere((o) => o.id == cookingOrder.id);
      expect(updated.items.first.name, 'Dimsum Jamur Hemat');
      expect(updated.items.first.price, cheaperPrice);
      expect(updated.refundAmount, expectedRefund);
      expect(updated.itemsSubtotal, cookingOrder.itemsSubtotal - expectedRefund);

      // Verify chat notification sent
      final messages = chatProvider.getMessages(cookingOrder.id);
      expect(messages.any((m) => m.text.contains('refund instan')), isTrue);
    });

    test('Alur 1: Ganti Item lebih mahal -> Tagihan COD tambahan ke kurir & chat notice', () async {
      final cookingOrder = provider.activeOrders.firstWhere((o) => o.status == 'COOKING');
      final originalItem = cookingOrder.items.first;

      // Ganti dengan item yang lebih mahal: Rp 20.000 (orig: Rp 14.000)
      const expensivePrice = 20000;
      final expectedDiff = (expensivePrice - originalItem.price) * originalItem.quantity;

      await provider.substituteOrderItem(
        orderId: cookingOrder.id,
        itemIndex: 0,
        newItemName: 'Dimsum Mozzarella Jumbo',
        newItemPrice: expensivePrice,
        chatProvider: chatProvider,
      );

      final updated = provider.activeOrders.firstWhere((o) => o.id == cookingOrder.id);
      expect(updated.items.first.name, 'Dimsum Mozzarella Jumbo');
      expect(updated.codAdjustment, expectedDiff);
      expect(updated.totalAmount, cookingOrder.totalAmount + expectedDiff);

      // Verify chat notification sent
      final messages = chatProvider.getMessages(cookingOrder.id);
      expect(messages.any((m) => m.text.contains('tagihan COD tambahan')), isTrue);
    });

    test('Alur 2: Kirim yang Ready Saja -> Nilai barang kosong di-refund, nota terkoreksi', () async {
      final cookingOrder = provider.activeOrders.firstWhere((o) => o.status == 'COOKING');
      expect(cookingOrder.items.length, greaterThanOrEqualTo(2));

      final oosItem = cookingOrder.items.last;
      final oosSubtotal = oosItem.subtotal;

      await provider.fulfillPartialOrder(
        orderId: cookingOrder.id,
        outOfStockItemIndices: [cookingOrder.items.length - 1],
        chatProvider: chatProvider,
      );

      final updated = provider.activeOrders.firstWhere((o) => o.id == cookingOrder.id);
      expect(updated.items.length, cookingOrder.items.length - 1);
      expect(updated.refundAmount, oosSubtotal);
      expect(updated.itemsSubtotal, cookingOrder.itemsSubtotal - oosSubtotal);

      // Verify chat notification sent
      final messages = chatProvider.getMessages(cookingOrder.id);
      expect(messages.any((m) => m.text.contains('di-refund ke GagePay')), isTrue);
    });

    test('Alur 3: Batalkan Seluruh Pesanan -> Refund 100% ke GagePay', () async {
      final cookingOrder = provider.activeOrders.firstWhere((o) => o.status == 'COOKING');
      final fullAmount = cookingOrder.totalAmount;

      await provider.cancelOrderWithFullRefund(
        orderId: cookingOrder.id,
        reason: 'Stok Habis Total',
        chatProvider: chatProvider,
      );

      final cancelled = provider.cancelledOrders.firstWhere((o) => o.id == cookingOrder.id);
      expect(cancelled.status, 'CANCELLED');
      expect(cancelled.refundAmount, fullAmount);

      final messages = chatProvider.getMessages(cookingOrder.id);
      expect(messages.any((m) => m.text.contains('100%')), isTrue);
    });

    // ───────────────────────────────────────────────────────────────────────
    // KALKULATOR MARKUP OTOMATIS: CEIL((Harga Asli / 0.90) / 500) * 500
    // ───────────────────────────────────────────────────────────────────────

    test('calculateMarkupPrice applies CEIL((Harga Asli / 0.90) / 500) * 500 accurately', () {
      // Misal Rp 10.000:
      // 10.000 / 0.90 = 11.111,11 -> CEIL(11.111,11 / 500) * 500 = 23 * 500 = 11.500
      expect(MerchantOrderProvider.calculateMarkupPrice(10000), 11500);

      // Misal Rp 12.000:
      // 12.000 / 0.90 = 13.333,33 -> CEIL(13.333,33 / 500) * 500 = 27 * 500 = 13.500
      expect(MerchantOrderProvider.calculateMarkupPrice(12000), 13500);

      // Misal Rp 15.000:
      // 15.000 / 0.90 = 16.666,67 -> CEIL(16.666,67 / 500) * 500 = 34 * 500 = 17.000
      expect(MerchantOrderProvider.calculateMarkupPrice(15000), 17000);

      // Misal Rp 18.000:
      // 18.000 / 0.90 = 20.000 -> CEIL(20.000 / 500) * 500 = 40 * 500 = 20.000
      expect(MerchantOrderProvider.calculateMarkupPrice(18000), 20000);

      // Misal Rp 25.000:
      // 25.000 / 0.90 = 27.777,78 -> CEIL(27.777,78 / 500) * 500 = 56 * 500 = 28.000
      expect(MerchantOrderProvider.calculateMarkupPrice(25000), 28000);

      // Net margin check: Warung never gets less than original price
      for (final price in [5000, 7500, 10000, 12000, 15000, 20000, 35000, 50000]) {
        final gagePrice = MerchantOrderProvider.calculateMarkupPrice(price);
        final netAfter10Percent = gagePrice - (gagePrice * 0.10).round();
        expect(netAfter10Percent, greaterThanOrEqualTo(price));
      }
    });

    test('toggleStoreOpen switches store status instantly', () {
      expect(provider.isOpen, isTrue);
      provider.toggleStoreOpen(false);
      expect(provider.isOpen, isFalse);
      provider.toggleStoreOpen(true);
      expect(provider.isOpen, isTrue);
    });
  });
}
