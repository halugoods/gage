import 'package:intl/intl.dart';

/// Konfigurasi Tier Diskon Bertahap Merchant Universal (Food, Shop, Farm, Build)
class MerchantDiscountTier {
  final int minSpend;
  final int discountAmount;
  final String? voucherCode;
  final String label;

  const MerchantDiscountTier({
    required this.minSpend,
    required this.discountAmount,
    this.voucherCode,
    required this.label,
  });

  String get compactBadge {
    final rb = discountAmount ~/ 1000;
    return '-${rb}RB';
  }

  String get hematBadge {
    final rb = discountAmount ~/ 1000;
    return 'Hemat ${rb}RB';
  }
}

/// Status Progres Multi-Tier Diskon yang Sedang Berjalan
class MerchantDiscountProgress {
  final MerchantDiscountTier? currentTier;
  final MerchantDiscountTier? nextTier;
  final double progress; // 0.0 - 1.0
  final int discountAmount;
  final int originalSubtotal;
  final int discountedSubtotal;
  final bool hasDiscount;
  final bool isMaxTier;
  final String hintText;
  final String compactSummaryText;
  final int neededForNext;
  final String? savedBadgeText;
  final String nextTierDetailText;

  const MerchantDiscountProgress({
    this.currentTier,
    this.nextTier,
    required this.progress,
    required this.discountAmount,
    required this.originalSubtotal,
    required this.discountedSubtotal,
    required this.hasDiscount,
    required this.isMaxTier,
    required this.hintText,
    required this.compactSummaryText,
    required this.neededForNext,
    this.savedBadgeText,
    this.nextTierDetailText = '',
  });
}

/// Service Sentral Pengelolaan Multi-Tier Diskon Bertahap GAGE
class MerchantDiscountTierService {
  MerchantDiscountTierService._();

  static final NumberFormat _currencyFormatter = NumberFormat('#,###', 'id_ID');

  static String formatRb(int amount) {
    if (amount >= 1000) {
      final thousands = amount / 1000.0;
      return thousands % 1 == 0 ? '${thousands.toInt()}RB' : '${thousands.toStringAsFixed(1)}RB';
    }
    return '$amount';
  }

  /// Fallback tier bawaan jika merchant belum mengatur custom tier
  static const List<MerchantDiscountTier> defaultTiers = [
    MerchantDiscountTier(
      minSpend: 15000,
      discountAmount: 5000,
      voucherCode: 'GAGEHEMAT',
      label: 'Diskon Rp 5.000',
    ),
    MerchantDiscountTier(
      minSpend: 35000,
      discountAmount: 10000,
      voucherCode: 'GAGEPROMO10',
      label: 'Diskon Rp 10.000',
    ),
    MerchantDiscountTier(
      minSpend: 60000,
      discountAmount: 20000,
      voucherCode: 'SUPERHEMAT',
      label: 'Diskon Rp 20.000',
    ),
  ];

  /// Menghitung progres tier diskon dinamis berbasis subtotal, merchantId, dan vertical serviceType
  static MerchantDiscountProgress calculateProgress({
    required int subtotal,
    String? merchantId,
    String? serviceType, // 'food' | 'shop' | 'farm' | 'build'
    List<MerchantDiscountTier>? customTiers,
  }) {
    final tiers = (customTiers != null && customTiers.isNotEmpty)
        ? List<MerchantDiscountTier>.from(customTiers)
        : List<MerchantDiscountTier>.from(defaultTiers);

    // Pastikan tiers terurut berdasarkan minSpend terkecil ke terbesar
    tiers.sort((a, b) => a.minSpend.compareTo(b.minSpend));

    final isFood = serviceType == null || serviceType == 'food';
    final discountDomainLabel = isFood ? 'Diskon Kuliner' : 'Diskon Belanja';

    if (tiers.isEmpty || subtotal <= 0) {
      return MerchantDiscountProgress(
        progress: 0.0,
        discountAmount: 0,
        originalSubtotal: subtotal,
        discountedSubtotal: subtotal,
        hasDiscount: false,
        isMaxTier: false,
        hintText: 'Belanja sekarang untuk dapat promo $discountDomainLabel',
        compactSummaryText: 'Dapatkan $discountDomainLabel',
        neededForNext: 0,
      );
    }

    MerchantDiscountTier? currentTier;
    MerchantDiscountTier? nextTier;

    for (int i = 0; i < tiers.length; i++) {
      if (subtotal >= tiers[i].minSpend) {
        currentTier = tiers[i];
      } else {
        nextTier = tiers[i];
        break;
      }
    }

    final int discountAmount = currentTier?.discountAmount ?? 0;
    final int discountedSubtotal = (subtotal - discountAmount).clamp(0, 99999999);
    final bool hasDiscount = discountAmount > 0;
    final bool isMaxTier = currentTier != null && nextTier == null;

    double progress = 0.0;
    int neededForNext = 0;
    String hintText = '';
    String compactSummaryText = '';

    String? savedBadgeText;
    String nextTierDetailText = '';

    if (currentTier == null && nextTier != null) {
      // Kasus 1: Belum mencapai tier pertama sama sekali
      neededForNext = (nextTier.minSpend - subtotal).clamp(0, 99999999);
      progress = (subtotal / nextTier.minSpend).clamp(0.0, 1.0);
      hintText = '+Rp ${_currencyFormatter.format(neededForNext)} lagi untuk ${nextTier.label}';
      nextTierDetailText = '+${formatRb(neededForNext)} lagi disc ${formatRb(nextTier.discountAmount)}';
      compactSummaryText = nextTierDetailText;
    } else if (currentTier != null && nextTier != null) {
      // Kasus 2: Tier pertama/kedua sudah tercapai, lanjutkan progres menuju tier berikutnya
      neededForNext = (nextTier.minSpend - subtotal).clamp(0, 99999999);
      final prevMin = currentTier.minSpend;
      final nextMin = nextTier.minSpend;
      final span = (nextMin - prevMin).clamp(1, 99999999);
      progress = ((subtotal - prevMin) / span).clamp(0.0, 1.0);
      hintText = '🎉 Hemat Rp ${_currencyFormatter.format(discountAmount)}! +Rp ${_currencyFormatter.format(neededForNext)} lagi ${nextTier.label}';
      savedBadgeText = 'Hemat ${formatRb(discountAmount)}';
      nextTierDetailText = '+${formatRb(neededForNext)} lagi disc ${formatRb(nextTier.discountAmount)}';
      compactSummaryText = '$savedBadgeText • $nextTierDetailText';
    } else if (isMaxTier) {
      // Kasus 3: Sudah mencapai diskon tertinggi/maksimal
      neededForNext = 0;
      progress = 1.0;
      hintText = '🎉 Mantap! ${currentTier.label} maksimal sudah aktif';
      savedBadgeText = 'Hemat ${formatRb(discountAmount)}';
      nextTierDetailText = 'Diskon Maksimal 🎉';
      compactSummaryText = '$savedBadgeText • $nextTierDetailText';
    }

    return MerchantDiscountProgress(
      currentTier: currentTier,
      nextTier: nextTier,
      progress: progress,
      discountAmount: discountAmount,
      originalSubtotal: subtotal,
      discountedSubtotal: discountedSubtotal,
      hasDiscount: hasDiscount,
      isMaxTier: isMaxTier,
      hintText: hintText,
      compactSummaryText: compactSummaryText,
      neededForNext: neededForNext,
      savedBadgeText: savedBadgeText,
      nextTierDetailText: nextTierDetailText,
    );
  }
}
