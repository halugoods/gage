import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';

/// Standalone universal Bottom Navigation Bar untuk GAGE SuperApp
/// Pendekatan independent route seperti NUSA Kasir:
/// - Setiap screen memiliki Scaffold top-level mandiri
/// - Tanpa nested Scaffold di dalam IndexedStack (menghilangkan konflik constraint viewport di semua device Android)
/// - Transisi tab instan & mulus (PageRouteBuilder zero duration)
class GageBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const GageBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget target;
    switch (index) {
      case 0:
        target = const HomeScreen();
        break;
      case 1:
        target = const OrdersScreen();
        break;
      case 2:
        target = const PromoScreen();
        break;
      case 3:
        target = const VideoFeedScreen();
        break;
      case 4:
        target = const ProfileScreen();
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => target,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? GageTheme.darkSurface : Colors.white,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black54 : Colors.black12,
            blurRadius: 4,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(context, 0, 'assets/images/nav_home_active.png', 'assets/images/nav_home_inactive.png', 'Beranda', isDark: isDark),
            _buildNavItem(context, 1, 'assets/images/nav_orders_active.png', 'assets/images/nav_orders_inactive.png', 'Pesanan', isDark: isDark),
            _buildNavItem(context, 2, 'assets/images/nav_promo_active.png', 'assets/images/nav_promo_inactive.png', 'Promo', hasBadge: true, isDark: isDark),
            _buildNavItem(context, 3, 'assets/images/nav_video_active.png', 'assets/images/nav_video_inactive.png', 'Video', isDark: isDark),
            _buildNavItem(context, 4, 'assets/images/nav_profile_active.png', 'assets/images/nav_profile_inactive.png', 'Profil', isDark: isDark),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    String activeAsset,
    String inactiveAsset,
    String label, {
    bool hasBadge = false,
    bool isDark = false,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = GageTheme.primary;
    final inactiveColor = isDark ? Colors.grey.shade400 : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Image.asset(
                    isSelected ? activeAsset : inactiveAsset,
                    width: 24,
                    height: 24,
                    errorBuilder: (ctx, err, stack) => Icon(
                      index == 0
                          ? Icons.home_rounded
                          : (index == 1
                              ? Icons.receipt_long_rounded
                              : (index == 2
                                  ? Icons.local_offer_rounded
                                  : (index == 3 ? Icons.play_circle_fill_rounded : Icons.person_rounded))),
                      size: 24,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                  if (hasBadge)
                    Positioned(
                      top: -2,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: GageTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 8, minHeight: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
