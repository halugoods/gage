import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

/// SocialShowcaseGrid
/// Etalase Produk Rekomendasi & Keranjang Kuning Kreator
/// Menampilkan produk-produk UMKM lokal Pracimantoro yang pernah direview/ditag di video
class SocialShowcaseGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool isOwnProfile;
  final String emptyMessage;

  const SocialShowcaseGrid({
    super.key,
    required this.products,
    this.isOwnProfile = true,
    this.emptyMessage = 'Belum ada produk yang disematkan di etalase',
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    if (products.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_bag_outlined,
                size: 36,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (isOwnProfile)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.storefront_rounded, size: 18, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Kelola produk etalase di GAGE Cuan',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 13,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          itemCount: products.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = products[index];
            final price = item['productPrice'] as int? ?? 15000;
            final title = item['productTitle'] as String? ?? 'Menu Pilihan';
            final merchant = item['merchantName'] as String? ?? 'Mitra GAGE';
            final rating = (item['merchantRating'] as num?)?.toDouble() ?? 4.8;
            final thumb = (item['thumbnailUrl'] as String?) ?? '';

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (isOwnProfile) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AffiliateHubScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RestoDetailScreen(
                        merchant: {
                          'id': item['merchantId'] ?? 'mrc-dimsum-sewu',
                          'name': merchant,
                          'category': 'Kuliner',
                          'address': 'Pracimantoro, Wonogiri',
                          'rating': rating,
                          'image': thumb,
                        },
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Foto Menu
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 70,
                        height: 70,
                        child: thumb.startsWith('assets/')
                            ? Image.asset(thumb, fit: BoxFit.cover)
                            : Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.fastfood_rounded, color: Colors.white54),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Detail Produk
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            merchant,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                '$rating',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                currencyFormatter.format(price),
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Tombol Beli / Pesan (Hanya untuk pengunjung, bukan akun sendiri)
                    if (!isOwnProfile) ...[
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestoDetailScreen(
                                merchant: {
                                  'id': item['merchantId'] ?? 'mrc-dimsum-sewu',
                                  'name': merchant,
                                  'category': 'Kuliner',
                                  'address': 'Pracimantoro, Wonogiri',
                                  'rating': rating,
                                  'image': thumb,
                                },
                              ),
                            ),
                          );
                        },
                        child: const Text(
                          'Beli',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
