import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/core/services/notification_service.dart';

/// Standalone Floating Bottom Navigation Bar untuk GAGE App (Telegram Floating Capsule Style)
/// - Meniru estetika floating capsule modern Telegram: rounded pill 32px melayang di atas gesture bar
/// - Frosted glass / backdrop blur semi-transparan dengan hairline border halus
/// - Micro-interaction: Active pill highlight di belakang icon + Haptic tactile feedback
/// - Dynamic real-time badge: Counter pesanan aktif & notifikasi promo
/// - Arsitektur zero-duration PageRouteBuilder: Navigasi tab secepat kilat tanpa lag
class GageBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const GageBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    HapticFeedback.lightImpact();

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
    final isVideoTab = currentIndex == 3;
    final effectiveDark = isDark || isVideoTab;

    LanguageProvider? lang;
    try {
      lang = Provider.of<LanguageProvider?>(context);
    } catch (_) {}

    int activeOrdersCount = 0;
    try {
      final orderProvider = Provider.of<OrderProvider?>(context, listen: true);
      activeOrdersCount = orderProvider?.activeOrders.length ?? 0;
    } catch (_) {}

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: effectiveDark
                  ? (isVideoTab
                      ? const Color(0xFF0F172A).withValues(alpha: 0.88)
                      : const Color(0xFF1E293B).withValues(alpha: 0.94))
                  : Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: effectiveDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : const Color(0xFFE2E8F0),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: effectiveDark ? 0.45 : 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                  spreadRadius: 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Row(
                  children: [
                    _buildNavItem(
                      context,
                      0,
                      'assets/images/nav_home_active.png',
                      'assets/images/nav_home_inactive.png',
                      lang?.tr('nav_home') ?? 'Beranda',
                      isDark: effectiveDark,
                    ),
                    _buildNavItem(
                      context,
                      1,
                      'assets/images/nav_orders_active.png',
                      'assets/images/nav_orders_inactive.png',
                      lang?.tr('nav_orders') ?? 'Pesanan',
                      badgeText: activeOrdersCount > 0 ? '$activeOrdersCount' : null,
                      isDark: effectiveDark,
                    ),
                    _buildNavItem(
                      context,
                      2,
                      'assets/images/nav_promo_active.png',
                      'assets/images/nav_promo_inactive.png',
                      lang?.tr('nav_promo') ?? 'Promo',
                      badgeText: NotificationService.instance.unreadPromoCount > 0
                          ? '${NotificationService.instance.unreadPromoCount}'
                          : null,
                      isDark: effectiveDark,
                    ),
                    _buildNavItem(
                      context,
                      3,
                      'assets/images/nav_video_active.png',
                      'assets/images/nav_video_inactive.png',
                      lang?.tr('nav_video') ?? 'Video',
                      isDark: effectiveDark,
                    ),
                    _buildNavItem(
                      context,
                      4,
                      'assets/images/nav_profile_active.png',
                      'assets/images/nav_profile_inactive.png',
                      lang?.tr('nav_profile') ?? 'Profil',
                      isDark: effectiveDark,
                    ),
                  ],
                ),
              ),
            ),
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
    IconData? iconOverride,
    String? badgeText,
    bool hasDotBadge = false,
    bool isDark = false,
  }) {
    final isSelected = currentIndex == index;
    final activeColor = GageTheme.primary;
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  iconOverride != null
                      ? Icon(
                          iconOverride,
                          size: 22,
                          color: isSelected ? activeColor : inactiveColor,
                        )
                      : Image.asset(
                          isSelected ? activeAsset : inactiveAsset,
                          width: 22,
                          height: 22,
                          errorBuilder: (ctx, err, stack) => Icon(
                            _getFallbackIcon(index),
                            size: 22,
                            color: isSelected ? activeColor : inactiveColor,
                          ),
                        ),
                  if (badgeText != null && badgeText.isNotEmpty)
                    Positioned(
                      top: -4,
                      right: -7,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: GageTheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                        child: Text(
                          badgeText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                            height: 1.1,
                          ),
                        ),
                      ),
                    )
                  else if (hasDotBadge)
                    Positioned(
                      top: 0,
                      right: -2,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: GageTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  color: isSelected ? activeColor : inactiveColor,
                  height: 1.1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getFallbackIcon(int index) {
    switch (index) {
      case 0:
        return Icons.home_rounded;
      case 1:
        return Icons.receipt_long_rounded;
      case 2:
        return Icons.local_offer_rounded;
      case 3:
        return Icons.chat_bubble_rounded;
      case 4:
        return Icons.play_circle_filled_rounded;
      case 5:
        return Icons.person_rounded;
      default:
        return Icons.circle;
    }
  }
}
