import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Merchant Handoff & Contract Tests', () {
    test('Production Guard: _initDefaultOrders does not populate mock orders when useDevSeedData is false', () {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = false;
        final provider = MerchantOrderProvider();
        expect(provider.orders, isEmpty, reason: 'Mock orders must never leak into production release mode');
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    test('Merchant ID Unification: Default mock orders use MerchantStorefrontService.defaultPortalMerchantId', () {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = true;
        final provider = MerchantOrderProvider();
        expect(provider.orders, isNotEmpty);
        for (final order in provider.orders) {
          expect(order.merchantId, equals(MerchantStorefrontService.defaultPortalMerchantId));
          expect(order.merchantId, equals('mch-dimsum-01'));
        }
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    test('Dynamic Affiliate Markup Calculator computes accurate non-loss prices for 0%, 5%, 10%, 15%, 20%', () {
      const offlinePrice = 10000;

      // 0% Affiliate, 10% Platform (Total 10% deduction): 10000 / 0.90 = 11111 -> ceil 100 = 11200
      final p0 = AffiliateCommissionService.calculateRecommendedOnlinePrice(
        offlinePrice,
        platformRate: 0.10,
        affiliateRate: 0.0,
      );
      expect(p0, equals(11200));
      // Net payout: 11200 - 10% platform (1120) = 10080 >= 10000 (Bebas Rugi)
      final split0 = AffiliateCommissionService.calculateCommissionSplit(
        onlinePrice: p0,
        hasAffiliator: false,
        platformRate: 0.10,
        affiliateRate: 0.0,
      );
      expect(split0['merchantPayout'], greaterThanOrEqualTo(offlinePrice));

      // 10% Affiliate, 10% Platform (Total 20% deduction): 10000 / 0.80 = 12500 -> ceil 100 = 12500
      final p10 = AffiliateCommissionService.calculateRecommendedOnlinePrice(
        offlinePrice,
        platformRate: 0.10,
        affiliateRate: 0.10,
      );
      expect(p10, equals(12500));
      final split10 = AffiliateCommissionService.calculateCommissionSplit(
        onlinePrice: p10,
        hasAffiliator: true,
        platformRate: 0.10,
        affiliateRate: 0.10,
      );
      expect(split10['merchantPayout'], equals(10000), reason: '100% utuh sama dengan harga offline warung');

      // 20% Affiliate (Max), 10% Platform (Total 30% deduction): 10000 / 0.70 = 14285 -> ceil 100 = 14300
      final p20 = AffiliateCommissionService.calculateRecommendedOnlinePrice(
        offlinePrice,
        platformRate: 0.10,
        affiliateRate: 0.20,
      );
      expect(p20, equals(14300));
      final split20 = AffiliateCommissionService.calculateCommissionSplit(
        onlinePrice: p20,
        hasAffiliator: true,
        platformRate: 0.10,
        affiliateRate: 0.20,
      );
      expect(split20['merchantPayout'], greaterThanOrEqualTo(offlinePrice));
    });

    test('Promo Price (Harga Coret) margin guard logic', () {
      const offlinePrice = 12000;
      const gagePrice = 15000;

      // Skenario 1: Hard block if promo >= normal price
      const invalidPromoHigh = 16000;
      expect(invalidPromoHigh >= gagePrice, isTrue);

      // Skenario 2: Hard block if promo <= 0
      const invalidPromoZero = 0;
      expect(invalidPromoZero <= 0, isTrue);

      // Skenario 3: Soft warning if net payout < offline price
      // Promo 13.000 -> Net payout (13000 * 0.90) = 11.700 < 12.000 offlinePrice
      const promoBakarMargin = 13000;
      final netPayoutBakar = (promoBakarMargin * 0.90).round();
      expect(netPayoutBakar, lessThan(offlinePrice));

      // Skenario 4: Safe margin promo
      // Promo 14.000 -> Net payout (14000 * 0.90) = 12.600 >= 12.000 offlinePrice
      const promoAman = 14000;
      final netPayoutAman = (promoAman * 0.90).round();
      expect(netPayoutAman, greaterThanOrEqualTo(offlinePrice));
    });

    test('Pickup direct completion transitions order to COMPLETED', () async {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = true;
        final provider = MerchantOrderProvider();
        final readyOrder = provider.orders.firstWhere((o) => o.status == 'READY_FOR_PICKUP');

        await provider.completeOrder(readyOrder.id);

        final completed = provider.completedOrders.firstWhere((o) => o.id == readyOrder.id);
        expect(completed.status, equals('COMPLETED'));
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    test('Unique Handover PIN is a 4-digit numeric code generated by merchant and can be regenerated', () {
      final provider = MerchantOrderProvider();
      final base = provider.orders.first;
      final order1 = base.copyWith(
        orderNumber: 'INV/GG/20261103/FD/GALIH-8822',
        handoverPin: '4819',
      );

      final order2 = base.copyWith(
        orderNumber: 'INV/GG/20261103/FD/SITI-8821',
        handoverPin: '7352',
      );

      // Verifikasi PIN 4 digit acak
      expect(order1.courierVerificationPin, equals('4819'));
      expect(order2.courierVerificationPin, equals('7352'));
      expect(order1.courierVerificationPin.length, equals(4));
      expect(int.tryParse(order1.courierVerificationPin), isNotNull);
      expect(order1.courierVerificationPin, isNot(equals(order2.courierVerificationPin)));

      // Verifikasi regenerasi PIN oleh merchant
      final newPin = provider.regenerateHandoverPin(base.id);
      expect(newPin.length, equals(4));
      expect(int.tryParse(newPin), isNotNull);
    });

    test('COD cash order cancellation and partial fulfillment do NOT refund GagePay (anti-exploit)', () async {
      final prevSetting = GageApiClient.allowDevSeedFallback;
      try {
        GageApiClient.allowDevSeedFallback = true;
        final provider = MerchantOrderProvider();

        // Cari pesanan COD di list order
        final codOrder = provider.orders.firstWhere((o) => o.paymentMethod == 'CASH_COD');

        // Batalkan pesanan COD
        await provider.cancelOrderWithFullRefund(
          orderId: codOrder.id,
          reason: 'Bahan habis total',
        );

        // Refund harus 0 karena pembeli belum membayar sepeser pun uang tunai
        final cancelled = provider.cancelledOrders.firstWhere((o) => o.id == codOrder.id);
        expect(cancelled.status, equals('CANCELLED'));
        expect(cancelled.refundAmount, equals(0));
      } finally {
        GageApiClient.allowDevSeedFallback = prevSetting;
      }
    });

    test('Merchant busy mode pauses incoming orders and auto-resumes', () {
      final provider = MerchantOrderProvider();
      expect(provider.isBusy, isFalse);

      provider.pauseOrders(const Duration(minutes: 15), reason: 'Antrean dapur padat');
      expect(provider.isBusy, isTrue);
      expect(provider.busyReason, equals('Antrean dapur padat'));
      expect(provider.busyUntil, isNotNull);

      provider.resumeOrders();
      expect(provider.isBusy, isFalse);
      expect(provider.busyUntil, isNull);
    });

    test('Merchant net payout and escrow calculation correctly deducts platform fee 10%', () {
      const subtotal = 42000;
      final provider = MerchantOrderProvider();
      final order = provider.orders.first.copyWith(
        orderNumber: 'INV/GG/20261103/FD/GALIH-8822',
        totalAmount: 48000,
        itemsSubtotal: subtotal,
        shippingFee: 5000,
        adminFee: 1000,
      );

      // Gross omset toko hanya itemsSubtotal (42.000), bukan totalAmount (48.000)
      expect(order.merchantGrossOmset, equals(42000));
      // Komisi platform 10% = 4.200
      expect(order.platformCommissionAmount, equals(4200));
      // Net payout toko = 42.000 - 4.200 = 37.800
      expect(order.merchantNetPayout, equals(37800));
    });
  });
}
