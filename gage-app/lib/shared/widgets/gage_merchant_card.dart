import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_favorite_button.dart';
import 'package:gage_app/shared/widgets/gage_merchant_tier_badge.dart';

/// Reusable Master Merchant Card GAGE SuperApp
/// Sesuai referensi visual BaksoManteb:
/// - Thumbnail 88x88 dengan Campaign Overlay Badge (misal: "11.11 RAME RAME")
/// - Nama Merchant + Level Badge (👑 Exclusive / ⭐ Star Merchant / Basic tanpa badge)
/// - Kategori toko / menu makanan
/// - Baris Metrik: ⭐ 4.8 (51) | 579m | 25min
/// - Baris Promo Pill: [Diskon 50%] [Diskon Ongkir]
class GageMerchantCard extends StatelessWidget {
  final String id;
  final String name;
  final String category;
  final double rating;
  final String ratingCount;
  final String distance;
  final String eta;
  final String image;
  final String? tier; // 'exclusive', 'star', or null/basic
  final bool isSponsored;
  final String? campaignBadge; // e.g. "11.11 RAME RAME", "DISKON SPESIAL"
  final List<String> promoBadges;
  final VoidCallback onTap;
  final double? width;
  final bool? isFavorite;
  final VoidCallback? onFavoriteTap;

  const GageMerchantCard({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.rating,
    required this.ratingCount,
    required this.distance,
    required this.eta,
    required this.image,
    required this.onTap,
    this.tier,
    this.isSponsored = false,
    this.campaignBadge,
    this.promoBadges = const [],
    this.width,
    this.isFavorite,
    this.onFavoriteTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget cardBody = Container(
      width: width,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Thumbnail Image 88x88 dengan Campaign Overlay
              ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                      child: Icon(
                        Icons.storefront_rounded,
                        color: isDark ? Colors.white38 : Colors.grey,
                        size: 36,
                      ),
                    ),
                  ),
                  if (isSponsored)
                    Positioned(
                      top: 5,
                      left: 5,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Iklan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  if (campaignBadge != null && campaignBadge!.isNotEmpty)
                    Positioned(
                      left: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE52320),
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8),
                          ),
                        ),
                        child: Text(
                          campaignBadge!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // 2. Info Kolom Kanan
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
              children: [
                // Baris 1: Format {badges level merchant} {nama merchant}
                Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            if (tier != null && tier!.isNotEmpty) ...[
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: GageMerchantTierBadge(tier: tier!),
                              ),
                              const WidgetSpan(child: SizedBox(width: 5)),
                            ],
                            TextSpan(
                              text: name,
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : GageTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 3),

                // Baris 2: Kategori Toko
                Text(
                  category,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 5),

                // Baris 3: ⭐ 4.8 (51)  |  579m  |  25min
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 16),
                      const SizedBox(width: 3),
                      Text(
                        rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : GageTheme.textPrimary,
                        ),
                      ),
                      Text(
                        ' ($ratingCount)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '|',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        distance,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '|',
                          style: TextStyle(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      Text(
                        eta,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),

                // Baris 4: Promo Pill Badges [Diskon 50%] [Diskon Ongkir]
                if (promoBadges.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: promoBadges.map((badge) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2C1315) : const Color(0xFFFFF1F2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECDD3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFFFCA5A5) : GageTheme.primary,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    ),
    Positioned(
      right: 0,
      bottom: 0,
      child: GageFavoriteMerchantButton(
        merchantId: id,
        merchantName: name,
        initialFavorite: isFavorite,
        onFavoriteChanged: onFavoriteTap,
        size: 20,
        withBackground: false,
      ),
    ),
  ],
),
);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(16),
      child: cardBody,
    );
  }
}
