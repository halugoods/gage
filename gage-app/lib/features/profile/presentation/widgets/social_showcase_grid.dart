import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_promo_card_share_dialog.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_video_upload_screen.dart';

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

    return ListenableBuilder(
      listenable: SocialProfileService.instance,
      builder: (context, _) {
        final rawList = (isOwnProfile && products.isEmpty)
            ? SocialProfileService.instance.getShowcaseProducts()
            : products;
        final currentProducts = rawList.where((p) {
          final pId = (p['productId'] ?? p['id'])?.toString();
          return pId == null || !SocialProfileService.instance.isShowcaseProductRemoved(pId);
        }).toList();

        if (currentProducts.isEmpty) {
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
                    Icons.storefront_rounded,
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

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: currentProducts.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            final item = currentProducts[index];
            final price = item['productPrice'] as int? ?? 15000;
            final originalPrice = item['originalPrice'] as int?;
            final hasRealDiscount = originalPrice != null && originalPrice > price;
            final title = item['productTitle'] as String? ?? 'Menu Pilihan';
            final merchant = item['merchantName'] as String? ?? 'Mitra GAGE';
            final rating = (item['merchantRating'] as num?)?.toDouble() ?? 4.8;
            final thumb = (item['thumbnailUrl'] as String?) ?? '';
            final pId = (item['productId'] ?? item['id'])?.toString() ?? '';

            return InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                // Navigasi langsung ke RestoDetailScreen dengan produk terpilih terfokus dan harga lengkap
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestoDetailScreen(
                      merchant: {
                        'id': item['merchantId'] ?? 'mrc-dimsum-sewu',
                        'name': merchant,
                        'category': item['category'] ?? 'Kuliner',
                        'address': item['address'] ?? 'Pracimantoro, Wonogiri',
                        'rating': rating,
                        'image': thumb,
                      },
                      initialProductId: pId,
                      initialProductItem: {
                        ...item,
                        'id': pId,
                        'name': title,
                        'price': price,
                        'gage_price': price,
                        'productPrice': price,
                        'product_price': price,
                        'original_price': originalPrice,
                        'originalPrice': originalPrice,
                        'image': thumb,
                        'imageUrl': thumb,
                        'thumbnailUrl': thumb,
                        'photo': thumb,
                        'description': item['productDescription'] ?? 'Menu spesial mitra pilihan GAGE Pracimantoro.',
                      },
                    ),
                  ),
                );
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
                    // 1:1 Foto Menu Persegi Presisi
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 74,
                        height: 74,
                        child: thumb.startsWith('assets/')
                            ? Image.asset(thumb, fit: BoxFit.cover)
                            : Image.network(
                                thumb,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: const Color(0xFF1E293B),
                                  child: const Icon(Icons.fastfood_rounded, color: Colors.white54),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Detail Produk (Judul, Merchant, Coret Harga Asli, Harga Promo)
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
                          Row(
                            children: [
                              Icon(
                                Icons.storefront_rounded,
                                size: 13,
                                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  merchant,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (hasRealDiscount) ...[
                                // Harga Coret Asli jika memang ada promo riil dari katalog
                                Text(
                                  currencyFormatter.format(originalPrice),
                                  style: TextStyle(
                                    fontSize: 11,
                                    decoration: TextDecoration.lineThrough,
                                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              // Harga Riil Produk
                              Text(
                                currencyFormatter.format(price),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w900,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          // Baris Sejajar: Badge Komisi Statis + 3 Ikon Aksi (Showcase Tas, Bagikan, Buat Video)
                          Row(
                            children: [
                              Container(
                                constraints: const BoxConstraints(maxWidth: 142),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'Komisi 10%: +${currencyFormatter.format((price * 0.1).round())}',
                                  style: const TextStyle(
                                    color: Color(0xFF166534),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Spacer(),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 1. Etalase / Showcase Toggle (Icon tas belanja dengan check badge ala TikTok)
                                  InkWell(
                                    onTap: () async {
                                      HapticFeedback.selectionClick();
                                      final pId = (item['productId'] ?? item['id'])?.toString() ?? '';
                                      await SocialProfileService.instance.removeProductFromShowcase(pId);
                                      if (context.mounted) {
                                        GageToast.showSuccess(context, 'Produk dihapus dari Etalase');
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            Icons.shopping_bag_rounded,
                                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                                            size: 19,
                                          ),
                                          Positioned(
                                            right: -2,
                                            bottom: -1,
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.check_circle_rounded,
                                                color: Color(0xFF16A34A),
                                                size: 10,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // 2. Bagikan Produk (Visual Card Generator)
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final pId = (item['productId'] ?? item['id'])?.toString() ?? '';
                                      GagePromoCardShareDialog.directShareProduct(
                                        context,
                                        productName: title,
                                        merchantName: merchant,
                                        price: currencyFormatter.format(price),
                                        shareUrl: 'https://gage.id/item/$pId?ref=${SocialProfileService.instance.userHandle}',
                                        imageUrl: thumb,
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Transform.flip(
                                        flipX: true,
                                        child: const Icon(
                                          Icons.reply_rounded,
                                          color: GageTheme.primary,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),

                                  // 3. Buat Video (Kamera)
                                  InkWell(
                                    onTap: () {
                                      HapticFeedback.selectionClick();
                                      final pId = (item['productId'] ?? item['id'])?.toString() ?? '';
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AffiliateVideoUploadScreen(
                                            initialMerchant: {
                                              'id': item['merchantId'] ?? 'mrc-dimsum-sewu',
                                              'name': merchant,
                                              'rating': rating,
                                            },
                                            initialProduct: {
                                              'id': pId,
                                              'name': title,
                                              'price': price,
                                              'image': thumb,
                                            },
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(999),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.video_call_rounded,
                                        color: GageTheme.primary,
                                        size: 21,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
