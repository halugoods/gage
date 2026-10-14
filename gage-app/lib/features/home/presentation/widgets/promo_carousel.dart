import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/features/membership/presentation/membership_screen.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

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

  void _onBannerTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const SendBookingScreen()),
      );
    } else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'ride')),
      );
    } else if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const ShopScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final bannerHeight = (screenWidth - 32) * 9 / 16; // Rasio baku 16:9

    return Column(
      children: [
        // Promo Swipe Carousel (3 Banner 16:9)
        SizedBox(
          height: bannerHeight.clamp(145.0, 180.0),
          child: PageView.builder(
            controller: _controller,
            itemCount: _promoBanners.length,
            onPageChanged: (idx) => setState(() => _currentIndex = idx),
            itemBuilder: (ctx, idx) {
              final banner = _promoBanners[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: InkWell(
                  onTap: () => _onBannerTap(idx),
                  borderRadius: BorderRadius.circular(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      banner['image'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (c, _, error) => Container(
                        color: GageTheme.primaryLight,
                        child: Center(
                          child: Text(
                            banner['title'],
                            style: const TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
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

        const SizedBox(height: 12),

        // Banner Tipis Membership GAGE Plus (Gaya Gojek: "Pasti dapet diskon tiap hari - Lihat keuntungan PLUS ->")
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const MembershipScreen()),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              constraints: const BoxConstraints(minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFEBEE), Color(0xFFFFCDD2)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEF9A9A), width: 1),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: const BoxDecoration(
                      color: GageTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Pasti dapet diskon tiap hari',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: GageTheme.primary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat keuntungan PLUS',
                          style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 3),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 12),
                      ],
                    ),
                  ),
                ],
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

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_rounded, color: Colors.amber, size: 56),
          const SizedBox(height: 12),
          const Text(
            'Hore! +100 Koin GAGE',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            'Kamu berhasil check-in hari ke-$_currentStreak. Koin sudah ditambahkan ke saldo dompet GAGE Cuan!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: const Text('Mantap!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade200, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.amber.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Judul & Badge Streak
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade300, width: 1),
                  ),
                  child: const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 20),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hadiah Login Harian',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: GageTheme.textPrimary),
                      ),
                      Text(
                        'Check-in tiap hari, kumpulkan Koin GAGE Cuan!',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade300, width: 0.8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 14),
                      const SizedBox(width: 2),
                      Text(
                        'Streak: $_currentStreak Hari',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Row 7 Hari Streak
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _days.map((d) {
                final isClaimed = d['claimed'] == true;
                final isToday = d['today'] == true && !_claimedToday;
                final isSpecial = d['special'] == true;

                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: isClaimed
                          ? Colors.grey.shade100
                          : (isToday ? Colors.amber.shade50 : (isSpecial ? Colors.orange.shade50 : Colors.grey.shade50)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isClaimed
                            ? Colors.grey.shade300
                            : (isToday
                                ? Colors.amber.shade700
                                : (isSpecial ? Colors.orange.shade300 : Colors.grey.shade200)),
                        width: isToday ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          d['day'] as String,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isToday ? Colors.amber.shade900 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (isClaimed)
                          const Icon(Icons.check_circle_rounded, color: Colors.green, size: 16)
                        else if (isSpecial)
                          const Icon(Icons.redeem_rounded, color: Colors.deepOrange, size: 16)
                        else
                          const Icon(Icons.monetization_on_rounded, color: Colors.amber, size: 16),
                        const SizedBox(height: 4),
                        Text(
                          '+${d['points']}',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            color: isClaimed ? Colors.grey : GageTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 12),

            // Tombol Klaim Hadiah Hari Ini
            SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: _claimedToday ? null : () => _claimReward(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _claimedToday ? Colors.grey.shade200 : const Color(0xFFF59E0B),
                  foregroundColor: _claimedToday ? Colors.grey.shade600 : Colors.white,
                  elevation: _claimedToday ? 0 : 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.zero,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _claimedToday ? Icons.check_rounded : Icons.touch_app_rounded,
                      size: 16,
                      color: _claimedToday ? Colors.grey.shade600 : Colors.white,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _claimedToday
                            ? 'Sudah Klaim Hari Ini'
                            : 'Klaim Hadiah Hari Ini (+100 Koin)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: _claimedToday ? Colors.grey.shade600 : Colors.white,
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
