import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';

void main() {
  group('AffiliateCommissionService Tests', () {
    test('calculateRecommendedOnlinePrice yields 100% net payout to merchant', () {
      const offlinePrice = 10000;
      final onlinePrice = AffiliateCommissionService.calculateRecommendedOnlinePrice(offlinePrice);
      expect(onlinePrice, 12500); // 10000 / 0.80 = 12500

      // Split with affiliator
      final splitWithAffiliate = AffiliateCommissionService.calculateCommissionSplit(
        onlinePrice: onlinePrice,
        hasAffiliator: true,
      );
      expect(splitWithAffiliate['platformCut'], 1250); // 10%
      expect(splitWithAffiliate['affiliateCut'], 1250); // 10%
      expect(splitWithAffiliate['gageRevenue'], 1250);
      expect(splitWithAffiliate['merchantPayout'], 10000); // 100% offline price!
    });

    test('calculateCommissionSplit on organic sales channels full 20% margin to GAGE', () {
      const onlinePrice = 12500;
      final splitOrganic = AffiliateCommissionService.calculateCommissionSplit(
        onlinePrice: onlinePrice,
        hasAffiliator: false,
      );

      expect(splitOrganic['platformCut'], 1250);
      expect(splitOrganic['affiliateCut'], 0);
      expect(splitOrganic['gageRevenue'], 2500); // 20% to GAGE!
      expect(splitOrganic['merchantPayout'], 10000); // Merchant still gets full 10000
    });

    test('generateReferralShareText and generateProductShareText produce formatted messages', () {
      final referralText = AffiliateCommissionService.generateReferralShareText(
        referralCode: 'GAGE-TEST',
        userName: 'Ratih',
      );
      expect(referralText, contains('GAGE-TEST'));
      expect(referralText, contains('Rp 10.000'));

      final productText = AffiliateCommissionService.generateProductShareText(
        productName: 'Paket Geprek 1',
        merchantName: 'Rocket Chicken',
        price: 16000,
        affiliateLink: 'https://gage.co.id/item/rc-01?ref=GAGE-TEST',
      );
      expect(productText, contains('Paket Geprek 1'));
      expect(productText, contains('Rocket Chicken'));
      expect(productText, contains('Rp 16.000'));
    });
  });
}
