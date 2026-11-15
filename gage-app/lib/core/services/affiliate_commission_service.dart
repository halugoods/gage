import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AffiliateCommissionService
/// Mengelola kalkulasi margin platform, komisi affiliator, rekomendasi markup harga merchant,
/// dan pembuatan kode referral acak 6 karakter unik yang persisten.
class AffiliateCommissionService {
  static const String _referralCodePrefsKey = 'gage_referral_code_v2';
  static const String _referralChars = '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';

  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Menghasilkan kode referral 6 digit acak tanpa karakter ambigu (0, O, 1, I).
  static String generateRandomReferralCode() {
    final rnd = math.Random();
    return List.generate(
      6,
      (_) => _referralChars[rnd.nextInt(_referralChars.length)],
    ).join();
  }

  /// Mengambil kode referral persisten pengguna saat ini, atau membuat kode baru jika belum ada.
  static Future<String> getOrCreateReferralCode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString(_referralCodePrefsKey);
      if (existing != null && existing.trim().length == 6) {
        return existing.trim().toUpperCase();
      }
      final newCode = generateRandomReferralCode();
      await prefs.setString(_referralCodePrefsKey, newCode);
      return newCode;
    } catch (_) {
      return generateRandomReferralCode();
    }
  }

  /// Menghitung harga jual aplikasi (online price) yang direkomendasikan
  /// agar pencairan bersih ke merchant 100% utuh sama dengan harga offline (P_offline)
  /// dengan rumus Divisor Payout:
  /// P_online = P_offline / (1.0 - (platformRate + affiliateRate))
  static int calculateRecommendedOnlinePrice(
    int offlinePrice, {
    double platformRate = 0.10,
    double affiliateRate = 0.10,
  }) {
    if (offlinePrice <= 0) return 0;
    final totalDeductionRate = platformRate + affiliateRate;
    if (totalDeductionRate >= 1.0) return offlinePrice;

    // Divisor payout
    final rawOnline = offlinePrice / (1.0 - totalDeductionRate);
    // Bulatkan ke ratusan terdekat ke atas agar merchant tidak rugi pecahan
    final rounded = (rawOnline / 100).ceil() * 100;
    return rounded;
  }

  /// Menghitung alokasi pembagian hasil dari harga online:
  /// - platformCut: 10%
  /// - affiliateCut: 10% jika ada affiliator, atau jika organik (tanpa affiliator) komisi ini masuk ke kas GAGE (total 20% ke GAGE)
  /// - merchantPayout: sisanya (100% dari harga offline yang diharapkan)
  static Map<String, dynamic> calculateCommissionSplit({
    required int onlinePrice,
    required bool hasAffiliator,
    double platformRate = 0.10,
    double affiliateRate = 0.10,
  }) {
    final platformCut = (onlinePrice * platformRate).round();
    final affiliateShare = (onlinePrice * affiliateRate).round();

    final actualAffiliateFee = hasAffiliator ? affiliateShare : 0;
    final actualGageRevenue = platformCut + (hasAffiliator ? 0 : affiliateShare);
    final merchantPayout = onlinePrice - (platformCut + affiliateShare);

    return {
      'onlinePrice': onlinePrice,
      'hasAffiliator': hasAffiliator,
      'platformCut': platformCut,
      'affiliateCut': actualAffiliateFee,
      'gageRevenue': actualGageRevenue,
      'merchantPayout': merchantPayout,
      'isOrganik': !hasAffiliator,
    };
  }

  /// Generate pesan WhatsApp untuk Ajak Teman (Referral)
  static String generateReferralShareText({
    required String referralCode,
    required String userName,
  }) {
    return 'Halo! Yuk pesan kuliner lezat, belanja sembako, dan kirim paket di Pracimantoro lewat aplikasi GAGE!\n\n'
        'Daftar pakai kode referral saya: *$referralCode*\n'
        'Dapatkan bonus kupon diskon Rp 10.000 untuk pesanan pertamamu!\n\n'
        'Download sekarang: https://gage.co.id/ref/$referralCode';
  }

  /// Generate pesan WhatsApp untuk Share Link Produk Afiliasi
  static String generateProductShareText({
    required String productName,
    required String merchantName,
    required int price,
    required String affiliateLink,
  }) {
    final formattedPrice = _currencyFormatter.format(price);
    return 'Rekomendasi kuliner lezat Pracimantoro: *$productName* dari *$merchantName* cuma $formattedPrice!\n\n'
        'Pesan praktis diantar kurir GAGE sekarang juga:\n$affiliateLink';
  }

  /// Generate pesan WhatsApp untuk Share Restoran / Toko Mitra Afiliasi
  static String generateMerchantShareText({
    required String merchantName,
    required String category,
    required String affiliateLink,
  }) {
    return 'Rekomendasi resto & kuliner favorit di Pracimantoro: *$merchantName* ($category)!\n\n'
        'Cek menu lengkap & pesan langsung lewat aplikasi GAGE:\n$affiliateLink';
  }
}
