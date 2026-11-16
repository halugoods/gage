import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_video_upload_screen.dart';

/// Layar Detail Merchant Khusus Program Afiliasi GAGE Cuan
/// Menampilkan katalog seluruh produk toko, persentase komisi asli toko (maks 20%),
/// kalkulasi nominal Rupiah komisi per item, tombol share link produk, dan tombol sematkan ke video feed.
class AffiliateMerchantDetailScreen extends StatelessWidget {
  final Map<String, dynamic> merchant;
  final String referralCode;

  const AffiliateMerchantDetailScreen({
    super.key,
    required this.merchant,
    required this.referralCode,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    // Ambil persentase komisi asli yang dipasang merchant (dibatasi maks 20%)
    final rawRate = merchant['commissionRate'] ?? merchant['affiliate_commission_rate'] ?? 10;
    final int commissionRate = (rawRate is num ? rawRate.toInt() : int.tryParse('$rawRate') ?? 10).clamp(0, 20);

    final menus = (merchant['menus'] as List<dynamic>?) ?? [];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              merchant['name'] as String? ?? 'Detail Toko Mitra',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${merchant['category'] ?? 'Mitra Usaha'} • Pracimantoro',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          // 1. Profil Merchant & Banner Komisi Toko
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            merchant['image'] as String? ?? 'assets/images/resto_rocket_chicken.png',
                            width: 68,
                            height: 68,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              width: 68,
                              height: 68,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.storefront, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                merchant['name'] as String? ?? 'Mitra GAGE',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${merchant['rating'] ?? 4.9} (${merchant['ratingCount'] ?? '100+'})',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white70 : const Color(0xFF334155),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '${merchant['distance'] ?? '1.0 km'} (${merchant['eta'] ?? '15-20 min'})',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                merchant['address'] as String? ?? 'Pracimantoro, Kabupaten Wonogiri',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    // Banner Komisi Asli Toko
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: GageTheme.primary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.verified_rounded,
                            color: GageTheme.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Komisi Affiliator: $commissionRate%',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: GageTheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Ditetapkan langsung oleh merchant (maksimal 20% demi unit economics sehat)',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Tombol Share Toko
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 11),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          final shareText = AffiliateCommissionService.generateMerchantShareText(
                            merchantName: merchant['name'] as String? ?? 'Mitra GAGE',
                            category: merchant['category'] as String? ?? 'Kuliner',
                            affiliateLink: 'https://gage.co.id/resto/${merchant['id']}?ref=$referralCode',
                          );
                          SharePlus.instance.share(ShareParams(
                            text: shareText,
                            subject: 'Rekomendasi Toko Mitra GAGE',
                          ));
                        },
                        icon: const Icon(Icons.share_rounded, size: 16),
                        label: const Text(
                          'Bagikan Tautan Toko Mitra',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 2. Section Title
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Text(
                    'Daftar Menu & Komisi Produk (${menus.length})',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Product Cards List
          if (menus.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Text(
                    'Belum ada menu produk aktif yang didaftarkan toko ini.',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = menus[index] as Map<String, dynamic>;
                    final price = (item['price'] is num ? item['price'] as int : int.tryParse('${item['price']}') ?? 0);
                    final commissionRupiah = (price * (commissionRate / 100.0)).round();

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  item['image'] as String? ?? 'assets/images/dish_dimsum_mentai.png',
                                  width: 72,
                                  height: 72,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 72,
                                    height: 72,
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.restaurant, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String? ?? 'Produk Menu',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      currencyFormatter.format(price),
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                        color: GageTheme.primary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    // Badge Komisi Transparan Rupiah
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDCFCE7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        'Komisi $commissionRate%: +${currencyFormatter.format(commissionRupiah)}',
                                        style: const TextStyle(
                                          color: Color(0xFF166534),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // 2 Tombol Aksi Kapsul: Bagikan Link & Tag di Video
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                                    side: BorderSide(
                                      color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                                    ),
                                    shape: const StadiumBorder(),
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    final shareText = AffiliateCommissionService.generateProductShareText(
                                      productName: item['name'] as String? ?? 'Menu',
                                      merchantName: merchant['name'] as String? ?? 'Mitra GAGE',
                                      price: price,
                                      affiliateLink: 'https://gage.co.id/item/${item['id']}?ref=$referralCode',
                                    );
                                    SharePlus.instance.share(ShareParams(
                                      text: shareText,
                                      subject: 'Rekomendasi Kuliner GAGE',
                                    ));
                                  },
                                  icon: const Icon(Icons.share_rounded, size: 14),
                                  label: const Text(
                                    'Bagikan Link',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GageTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: const StadiumBorder(),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                  ),
                                  onPressed: () async {
                                    HapticFeedback.selectionClick();
                                    // Tambahkan produk otomatis ke etalase profil kreator
                                    await SocialProfileService.instance.addProductToShowcase({
                                      'productId': item['id'],
                                      'productTitle': item['name'],
                                      'productPrice': price,
                                      'merchantId': merchant['id'],
                                      'merchantName': merchant['name'],
                                      'merchantRating': merchant['rating'],
                                      'thumbnailUrl': item['image'],
                                    });

                                    try {
                                      final picker = ImagePicker();
                                      final XFile? picked = await picker.pickVideo(
                                        source: ImageSource.gallery,
                                        maxDuration: const Duration(minutes: 3),
                                      );
                                      if (!context.mounted) return;
                                      if (picked != null) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AffiliateVideoUploadScreen(
                                              initialMerchant: merchant,
                                              initialProduct: item,
                                              initialVideoPath: picked.path,
                                              initialVideoName: picked.name,
                                            ),
                                          ),
                                        );
                                        return;
                                      }
                                    } catch (_) {}

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AffiliateVideoUploadScreen(
                                            initialMerchant: merchant,
                                            initialProduct: item,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.videocam_rounded, size: 15),
                                  label: const Text(
                                    'Buat Video',
                                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: menus.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
