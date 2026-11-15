import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AffiliateCommissionService Tests', () {
    test('generateRandomReferralCode creates 6 character alphanumeric without ambiguous characters', () {
      final code1 = AffiliateCommissionService.generateRandomReferralCode();
      final code2 = AffiliateCommissionService.generateRandomReferralCode();

      expect(code1.length, 6);
      expect(code2.length, 6);
      expect(RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$').hasMatch(code1), isTrue);
      expect(RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$').hasMatch(code2), isTrue);
      // No ambiguous chars: 0, O, 1, I
      expect(code1.contains(RegExp(r'[0O1I]')), isFalse);
    });

    test('getOrCreateReferralCode persists code across calls', () async {
      SharedPreferences.setMockInitialValues({});
      final codeFirst = await AffiliateCommissionService.getOrCreateReferralCode();
      expect(codeFirst.length, 6);

      final codeSecond = await AffiliateCommissionService.getOrCreateReferralCode();
      expect(codeSecond, codeFirst);
    });

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
        referralCode: 'G8K2M9',
        userName: 'Ratih',
      );
      expect(referralText, contains('G8K2M9'));
      expect(referralText, contains('Rp 10.000'));
      expect(referralText, contains('https://gage.co.id/ref/G8K2M9'));

      final productText = AffiliateCommissionService.generateProductShareText(
        productName: 'Paket Geprek 1',
        merchantName: 'Rocket Chicken',
        price: 16000,
        affiliateLink: 'https://gage.co.id/item/rc-01?ref=G8K2M9',
      );
      expect(productText, contains('Paket Geprek 1'));
      expect(productText, contains('Rocket Chicken'));
      expect(productText, contains('Rp 16.000'));

      final merchantText = AffiliateCommissionService.generateMerchantShareText(
        merchantName: 'RM Bakso Mas No',
        category: 'Bakso & Soto',
        affiliateLink: 'https://gage.co.id/resto/mas-no?ref=G8K2M9',
      );
      expect(merchantText, contains('RM Bakso Mas No'));
      expect(merchantText, contains('Bakso & Soto'));
    });
  });
}
