import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_root_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// MerchantProfileHeader
/// Header Toko Mitra Resmi (Verified Merchant Storefront)
/// Menampilkan Banner Lapak/Resto, Logo Resmi, Badge Mitra Resmi, Rating, Status Jam Buka, dan Tombol Aksi.
class MerchantProfileHeader extends StatefulWidget {
  final String merchantId;
  final String merchantName;
  final String category;
  final String bannerUrl;
  final String logoUrl;
  final String address;
  final double rating;
  final int reviewsCount;
  final int soldCount;
  final String openHours;
  final bool isOpen;
  final bool isOwner;

  const MerchantProfileHeader({
    super.key,
    required this.merchantId,
    required this.merchantName,
    this.category = 'Kuliner',
    this.bannerUrl = 'assets/images/resto_dimsum_sewu.png',
    this.logoUrl = 'assets/images/resto_dimsum_sewu.png',
    this.address = 'Pracimantoro, Wonogiri',
    this.rating = 4.9,
    this.reviewsCount = 320,
    this.soldCount = 1400,
    this.openHours = '09:00 - 21:00',
    this.isOpen = true,
    this.isOwner = false,
  });

  @override
  State<MerchantProfileHeader> createState() => _MerchantProfileHeaderState();
}

class _MerchantProfileHeaderState extends State<MerchantProfileHeader> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final socialService = SocialProfileService.instance;
    final isFollowing = socialService.isFollowing(widget.merchantId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Banner Lapak / Resto
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 140,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                image: widget.bannerUrl.startsWith('assets/')
                    ? DecorationImage(
                        image: AssetImage(widget.bannerUrl),
                        fit: BoxFit.cover,
                      )
                    : DecorationImage(
                        image: NetworkImage(widget.bannerUrl),
                        fit: BoxFit.cover,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.5),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Logo Avatar Toko (Floating di batas banner)
            Positioned(
              left: 16,
              bottom: -32,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border.all(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.logoUrl.startsWith('assets/')
                      ? Image.asset(widget.logoUrl, fit: BoxFit.cover)
                      : Image.network(
                          widget.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            child: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 36),
                          ),
                        ),
                ),
              ),
            ),

            // Badge MITRA RESMI GAGE
            Positioned(
              right: 14,
              bottom: -14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE52320), Color(0xFFB91C1C)],
                  ),
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: GageTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFFFDE047), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'MITRA RESMI GAGE ${widget.category.toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 38),

        // Info Nama & Alamat Toko
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.merchantName,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_rounded, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.address,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Barisan Metrik: Rating, Terjual, Status Buka
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.rating} (${widget.reviewsCount}+ Ulasan)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(height: 12, width: 1, color: Colors.grey.shade400),
                    const SizedBox(width: 12),
                    Text(
                      '${(widget.soldCount / 1000).toStringAsFixed(1)}K Terjual',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.isOpen ? const Color(0xFF10B981) : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      widget.isOpen ? 'Buka • ${widget.openHours}' : 'Tutup',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: widget.isOpen
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.red.shade400 : Colors.red),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Barisan Tombol Aksi Toko
              Row(
                children: [
                  if (widget.isOwner) ...[
                    // Pemilik Toko
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantRootScreen()),
                          );
                        },
                        icon: const Icon(Icons.store_mall_directory_rounded, size: 16),
                        label: const Text(
                          'Buka Portal Merchant ↗',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ] else ...[
                    // Pelanggan Publik
                    Expanded(
                      flex: 4,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isFollowing
                              ? (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))
                              : GageTheme.primary,
                          foregroundColor: isFollowing
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () async {
                          HapticFeedback.selectionClick();
                          final nowFollowed = await socialService.toggleFollow(widget.merchantId);
                          setState(() {});
                          if (mounted) {
                            GageToast.show(
                              context,
                              nowFollowed
                                  ? 'Mengikuti toko ${widget.merchantName}'
                                  : 'Berhenti mengikuti toko ${widget.merchantName}',
                              type: GageToastType.info,
                            );
                          }
                        },
                        icon: Icon(
                          isFollowing ? Icons.check_rounded : Icons.add_rounded,
                          size: 16,
                        ),
                        label: Text(
                          isFollowing ? 'Mengikuti' : 'Ikuti Toko',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 3,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                          foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          GageToast.show(
                            context,
                            'Menghubungi kasir ${widget.merchantName}...',
                            type: GageToastType.info,
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                        label: const Text(
                          'Chat',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    Expanded(
                      flex: 4,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          side: const BorderSide(color: GageTheme.primary),
                          foregroundColor: GageTheme.primary,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RestoDetailScreen(
                                merchant: {
                                  'id': widget.merchantId,
                                  'name': widget.merchantName,
                                  'category': widget.category,
                                  'address': widget.address,
                                  'rating': widget.rating,
                                  'image': widget.logoUrl,
                                },
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant_menu_rounded, size: 14),
                        label: const Text(
                          'Buka Menu',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
