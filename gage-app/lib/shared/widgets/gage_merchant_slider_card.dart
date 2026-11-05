import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_favorite_button.dart';

/// Reusable Horizontal Square Slider Card GAGE SuperApp
/// Sesuai instruksi visual:
/// - Kartu persegi untuk slider horizontal (geser kanan-kiri)
/// - Thumbnail 16:9 di bagian atas dengan Campaign Overlay Badge sudut merah
/// - Nama Merchant + 3D Badge Tag resmi Flow Nano Banana 2.1 INLINE di belakang nama
/// - Subtitle kategori
/// - Baris metrik: ⭐ 4.8 | 579m | 25min (FittedBox anti-overflow)
/// - Dua promo badge baku: [Diskon {persen}] dan [Diskon Ongkir]
class GageMerchantSliderCard extends StatelessWidget {
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
  final String? campaignBadge;
  final List<String> promoBadges;
  final VoidCallback onTap;
  final double width;

  const GageMerchantSliderCard({
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
    this.width = 168.0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: width,
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Thumbnail Atas (16:9) dengan Campaign Badge Sudut Merah
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: SizedBox(
                width: width,
                height: 98,
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
                    if (isSponsored)
                      Positioned(
                        top: 6,
                        left: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Iklan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    // Tombol Favorit Instan
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GageFavoriteMerchantButton(
                        merchantId: id,
                        merchantName: name,
                        withBackground: true,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Info Detail Merchant
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Baris 1: Format {badges level merchant} {nama merchant}
                  Text.rich(
                    TextSpan(
                      children: [
                        if (tier == 'exclusive') ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Image.asset(
                              'assets/icons/badge_exclusive_merchant.png',
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 5)),
                        ] else if (tier == 'star') ...[
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Image.asset(
                              'assets/icons/badge_star_merchant.png',
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const WidgetSpan(child: SizedBox(width: 5)),
                        ],
                        TextSpan(
                          text: name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : GageTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 3),

                  // Baris 2: Kategori Toko / Menu
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 6),

                  // Baris 3: ⭐ 4.8 | 579m | 25min (FittedBox anti-overflow)
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 14),
                        const SizedBox(width: 2),
                        Text(
                          rating.toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : GageTheme.textPrimary,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          distance,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            '|',
                            style: TextStyle(
                              color: isDark ? Colors.white24 : Colors.grey.shade300,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        Text(
                          eta,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Baris 4: Standar 2 Badge Diskon: [Diskon {persen}] & [Diskon Ongkir]
                  if (promoBadges.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: promoBadges.take(2).map((badge) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF2C1315) : const Color(0xFFFFF1F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECDD3),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }
}
