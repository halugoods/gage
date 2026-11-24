import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/farm_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_gleam_plus_banner.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/live_app_edit_scope.dart';

class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<Map<String, dynamic>> _promoBanners = [
    {
      'image': 'assets/images/food_hero_banner.png',
      'title': 'Pesta Kuliner Spesial',
      'desc': 'Diskon 50% & Gratis Ongkir Pesanan',
    },
    {
      'image': 'assets/images/send_hero_banner.png',
      'title': 'Kirim Kilat GAGE Send',
      'desc': 'Tarif Hemat Kirim Paket Instan',
    },
    {
      'image': 'assets/images/ride_hero_banner.png',
      'title': 'GAGE Ride & Car',
      'desc': 'Perjalanan Nyaman dengan Tarif Hemat',
    },
    {
      'image': 'assets/images/shop_hero_banner.png',
      'title': 'Belanja Sembako Lengkap',
      'desc': 'Grosir & Eceran Pasar Pracimantoro',
    },
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildCarouselImage(String imgPath, String fallbackTitle) {
    if (imgPath.startsWith('http://') || imgPath.startsWith('https://')) {
      return Image.network(
        imgPath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, _, error) => _buildCarouselFallback(fallbackTitle),
      );
    } else if (imgPath.startsWith('assets/')) {
      return Image.asset(
        imgPath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, _, error) => _buildCarouselFallback(fallbackTitle),
      );
    } else if (imgPath.isNotEmpty && File(imgPath).existsSync()) {
      return Image.file(
        File(imgPath),
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, _, error) => _buildCarouselFallback(fallbackTitle),
      );
    }
    return _buildCarouselFallback(fallbackTitle);
  }

  Widget _buildCarouselFallback(String title) {
    return Container(
      color: GageTheme.primaryLight,
      child: Center(
        child: Text(
          title,
          style: const TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _onBannerTap(int index, bool isEditMode) async {
    final bannerManager = BannerManagerService.instance;
    final targetKey = 'customer_promo_carousel_slide_${index + 1}';
    final liveBanner = bannerManager.getBanner(targetKey);

    if (isEditMode) {
      final initialImg = liveBanner.imagePath.isNotEmpty ? liveBanner.imagePath : _promoBanners[index]['image']!;
      final initialTitle = liveBanner.title.isNotEmpty ? liveBanner.title : _promoBanners[index]['title']!;
      final initialDesc = liveBanner.subtitle.isNotEmpty ? liveBanner.subtitle : _promoBanners[index]['desc']!;

      LiveAppEditScope.triggerEdit(
        context: context,
        screenTarget: targetKey,
        title: initialTitle,
        subtitle: initialDesc,
        badge: 'PROMO SLIDE ${index + 1}',
        imageUrl: initialImg,
        actionUrl: liveBanner.ctaText.isNotEmpty ? liveBanner.ctaText : (index == 1 ? 'send' : (index == 2 ? 'ride' : (index == 3 ? 'shop' : 'food'))),
        aspectRatio: 16 / 4.5, // Half 16:9
        onSaved: () {
          setState(() {});
        },
      );
      return;
    }

    final route = liveBanner.ctaText.trim();
    if (route.isEmpty || route.toLowerCase() == 'none') {
      // Tautan opsional kosong: banner murni grafis informasi
      return;
    }

    final lowerRoute = route.toLowerCase();
    if (lowerRoute.startsWith('http://') || lowerRoute.startsWith('https://')) {
      final uri = Uri.tryParse(route);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    if (lowerRoute.startsWith('service:') ||
        lowerRoute == 'send' ||
        lowerRoute == 'ride' ||
        lowerRoute == 'car' ||
        lowerRoute == 'food' ||
        lowerRoute == 'shop' ||
        lowerRoute == 'farm' ||
        lowerRoute == 'build' ||
        lowerRoute == 'cuan') {
      final serviceType = lowerRoute.replaceAll('service:', '').trim();
      if (serviceType == 'send') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SendBookingScreen()));
      } else if (serviceType == 'ride') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'ride')));
      } else if (serviceType == 'car') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'car')));
      } else if (serviceType == 'shop') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ShopScreen()));
      } else if (serviceType == 'farm') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FarmScreen()));
      } else if (serviceType == 'cuan') {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const AffiliateHubScreen()));
      } else {
        Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()));
      }
      return;
    }

    if (lowerRoute.startsWith('merchant:')) {
      // Navigasi ke resto / merchant spesifik
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
      );
      return;
    }

    if (lowerRoute.contains('promo') || lowerRoute.contains('voucher')) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const PromoScreen()));
      return;
    }

    if (lowerRoute.contains('wallet') || lowerRoute.contains('gagepay')) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const GagePayScreen()));
      return;
    }

    // Default Fallback
    if (index == 1) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const SendBookingScreen()));
    } else if (index == 2) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'ride')));
    } else if (index == 3) {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const ShopScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Rasio banner proporsional standar superapp (~2.3:1)
    final bannerHeight = (screenWidth - 32) * 9 / 20;
    final bannerManager = context.watch<BannerManagerService>();
    final isEditMode = LiveAppEditScope.isEditModeActive(context);

    return Column(
      children: [
        // 1. Banner GAGE Plus Berkilau (Diletakkan di Atas Slider)
        const GageGleamPlusBanner(),

        const SizedBox(height: 14),

        // 2. Promo Swipe Carousel (Ukuran Standar Proporsional Superapp)
        SizedBox(
          height: bannerHeight.clamp(140.0, 165.0),
          child: PageView.builder(
            controller: _controller,
            itemCount: _promoBanners.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (ctx, idx) {
              final banner = _promoBanners[idx];
              final targetKey = 'customer_promo_carousel_slide_${idx + 1}';
              final liveBanner = bannerManager.getBanner(targetKey);
              final activeImg = liveBanner.imagePath.isNotEmpty ? liveBanner.imagePath : banner['image']!;
              final activeTitle = liveBanner.title.isNotEmpty ? liveBanner.title : banner['title']!;

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => _onBannerTap(idx, isEditMode),
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        _buildCarouselImage(activeImg, activeTitle),
                        if (isEditMode)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: GageTheme.primary, width: 1.2),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Edit Slide ${idx + 1}',
                                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 8),

        // Indicator Dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _promoBanners.length,
            (idx) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _currentIndex == idx ? 16 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: _currentIndex == idx ? GageTheme.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Hadiah Login Harian (Check-in Streak Gamification)
        const DailyCheckInCard(),
      ],
    );
  }
}

class DailyCheckInCard extends StatefulWidget {
  const DailyCheckInCard({super.key});

  @override
  State<DailyCheckInCard> createState() => _DailyCheckInCardState();
}

class _DailyCheckInCardState extends State<DailyCheckInCard> {
  bool _claimedToday = false;
  final int _currentStreak = 2;

  final List<Map<String, dynamic>> _days = [
    {'day': 'H1', 'points': 50, 'claimed': true},
    {'day': 'H2', 'points': 100, 'claimed': false, 'today': true},
    {'day': 'H3', 'points': 150, 'claimed': false},
    {'day': 'H4', 'points': 200, 'claimed': false},
    {'day': 'H5', 'points': 250, 'claimed': false},
    {'day': 'H6', 'points': 300, 'claimed': false},
    {'day': 'H7', 'points': 1000, 'claimed': false, 'special': true},
  ];

  void _claimReward(BuildContext context) {
    if (_claimedToday) return;

    setState(() {
      _claimedToday = true;
      _days[1]['claimed'] = true;
    });

    context.read<WalletProvider>().addPoints(100);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars_rounded, color: GageTheme.primary, size: 40),
          ),
          const SizedBox(height: 14),
          const Text(
            'Hore! +100 Koin GAGE Cuan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu berhasil check-in hari ke-$_currentStreak. Poin cuan langsung masuk ke saldo dompet GAGE Anda!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GagePayScreen()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Lihat Saldo & Poin Cuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Tutup', style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: GAGE Red Icon, Title & Streak Capsule Badge
            InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GagePayScreen()),
                );
              },
              borderRadius: BorderRadius.circular(10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: GageTheme.primary, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hadiah Check-in Harian',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13.5,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          'Klaim koin cuan gratis tiap hari untuk potongan belanja',
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          color: GageTheme.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '$_currentStreak Hari',
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Row 7 Hari Streak: Bersih, Rapi & Berakar pada Brand GAGE
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _days.map((d) {
                final isClaimed = d['claimed'] == true;
                final isToday = d['today'] == true && !_claimedToday;
                final isSpecial = d['special'] == true;

                final boxBg = isClaimed
                    ? (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9))
                    : (isToday
                        ? GageTheme.primary.withValues(alpha: 0.10)
                        : (isSpecial
                            ? (isDark ? const Color(0xFF281118) : const Color(0xFFFFF1F2))
                            : (isDark ? const Color(0xFF0F172A).withValues(alpha: 0.4) : const Color(0xFFF8FAFC))));

                final boxBorder = isClaimed
                    ? (isDark ? Colors.white12 : const Color(0xFFE2E8F0))
                    : (isToday
                        ? GageTheme.primary
                        : (isSpecial
                            ? GageTheme.primary.withValues(alpha: 0.35)
                            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0))));

                final dayTextColor = isToday
                    ? GageTheme.primary
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

                final pointsTextColor = isClaimed
                    ? (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))
                    : (isToday
                        ? GageTheme.primary
                        : (isSpecial ? GageTheme.primary : textPrimary));

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: boxBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: boxBorder,
                        width: isToday ? 1.5 : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d['day'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
                            color: dayTextColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isClaimed)
                          const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 16)
                        else if (isSpecial)
                          const Icon(Icons.redeem_rounded, color: GageTheme.primary, size: 16)
                        else
                          Icon(
                            Icons.stars_rounded,
                            color: isToday ? GageTheme.primary : (isDark ? Colors.white30 : const Color(0xFFCBD5E1)),
                            size: 16,
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '+${d['points']}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isToday ? FontWeight.w900 : FontWeight.bold,
                            color: pointsTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Tombol Solid Kapsul Klaim Hadiah Hari Ini
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _claimedToday ? null : () => _claimReward(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _claimedToday
                      ? (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9))
                      : GageTheme.primary,
                  foregroundColor: _claimedToday
                      ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8))
                      : Colors.white,
                  elevation: _claimedToday ? 0 : 2,
                  shape: const StadiumBorder(),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _claimedToday ? Icons.check_circle_rounded : Icons.stars_rounded,
                      size: 16,
                      color: _claimedToday
                          ? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF94A3B8))
                          : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _claimedToday
                            ? 'Sudah Klaim Hari Ini'
                            : 'Klaim Hadiah Hari Ini (+100 Poin Cuan)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: _claimedToday ? const Color(0xFF94A3B8) : Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
