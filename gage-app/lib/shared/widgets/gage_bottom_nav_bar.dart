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
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_video_upload_screen.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/core/services/notification_service.dart';

/// Standalone Floating Bottom Navigation Bar untuk GAGE App (Telegram Floating Capsule Style)
/// - Meniru estetika floating capsule modern Telegram & Apple Dynamic Island
/// - Frosted glass / backdrop blur semi-transparan dengan transparansi tinggi (low alpha, high blur)
/// - Selected tab pill: Frosted glass style (subtle white/dark alpha, snug-fit tightly to edges)
/// - Item tidak aktif hanya menampilkan ikon ringkas dengan jarak proporsional dan presisi
/// - Mode Profil (Split Island):
///   - Left capsule: Exactly 2 action buttons (Chat & Buat Video)
///   - Right capsule: Standalone circular frosted glass container with red Kembali icon (counter-clockwise style) WITHOUT any text label
///   - Micro-interaction: Apple Dynamic Island spring bounce transition (Curves.easeOutBack, ~350ms)
class GageBottomNavBar extends StatefulWidget {
  final int currentIndex;
  final bool isProfileMode;
  final int profileTabIndex;
  final ValueChanged<int>? onProfileTabSelected;
  final VoidCallback? onProfileBack;
  final VoidCallback? onChatTap;
  final VoidCallback? onCreateVideoTap;

  const GageBottomNavBar({
    super.key,
    required this.currentIndex,
    this.isProfileMode = false,
    this.profileTabIndex = 0,
    this.onProfileTabSelected,
    this.onProfileBack,
    this.onChatTap,
    this.onCreateVideoTap,
  });

  @override
  State<GageBottomNavBar> createState() => _GageBottomNavBarState();
}

class _GageBottomNavBarState extends State<GageBottomNavBar> {
  late bool _profileModeActive;

  @override
  void initState() {
    super.initState();
    _profileModeActive = widget.isProfileMode;
  }

  @override
  void didUpdateWidget(covariant GageBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isProfileMode != widget.isProfileMode) {
      _profileModeActive = widget.isProfileMode;
    }
  }

  void _onStandardTap(BuildContext context, int index) {
    HapticFeedback.selectionClick();

    if (index == widget.currentIndex) return;

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

  void _revertToStandardNavBar() {
    HapticFeedback.lightImpact();
    setState(() => _profileModeActive = false);
    widget.onProfileBack?.call();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isVideo = widget.currentIndex == 3;
    final effectiveDark = isVideo ? false : isDark;

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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 60,
            child: Row(
              children: [
                // Main Container (Persis dimensi & styling SeamlessFloatingCartBar: radius 32, blur 24, height 60)
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: effectiveDark ? 0.35 : 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isVideo
                                ? (effectiveDark
                                    ? const Color(0xFF0F172A).withValues(alpha: 0.75)
                                    : Colors.white.withValues(alpha: 0.90))
                                : (effectiveDark
                                    ? const Color(0xFF1E293B).withValues(alpha: 0.50)
                                    : Colors.white.withValues(alpha: 0.52)),
                            borderRadius: BorderRadius.circular(32),
                            border: Border.all(
                              color: isVideo
                                  ? (effectiveDark
                                      ? Colors.white.withValues(alpha: 0.15)
                                      : Colors.white.withValues(alpha: 0.95))
                                  : (effectiveDark
                                      ? Colors.white.withValues(alpha: 0.12)
                                      : Colors.white.withValues(alpha: 0.60)),
                              width: 1.0,
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: NotificationService.instance,
                            builder: (context, _) {
                              final promoUnread = NotificationService.instance.unreadPromoCount;

                              return AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                switchInCurve: Curves.easeOutBack,
                                switchOutCurve: Curves.easeInOut,
                                transitionBuilder: (child, animation) => FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                                child: _profileModeActive
                                    ? _buildProfileLeftActions(effectiveDark)
                                    : _buildStandardNavBar(
                                        key: const ValueKey('standard_nav'),
                                        context: context,
                                        lang: lang,
                                        activeOrdersCount: activeOrdersCount,
                                        promoUnread: promoUnread,
                                        isDark: effectiveDark,
                                        isVideo: isVideo,
                                      ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Right Capsule: Standalone circular frosted glass container with red Kembali icon (hanya aktif jika _profileModeActive)
                AnimatedSize(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  alignment: Alignment.centerRight,
                  child: _profileModeActive
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 8),
                            _buildRightCircularIsland(effectiveDark, isVideo),
                          ],
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 1. Standard Bottom Navigation Bar (5 Items: Beranda, Pesanan, Promo, Video, Profil)
  Widget _buildStandardNavBar({
    required Key key,
    required BuildContext context,
    required LanguageProvider? lang,
    required int activeOrdersCount,
    required int promoUnread,
    required bool isDark,
    bool isVideo = false,
  }) {
    return Container(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 0,
              label: lang?.tr('nav_home') ?? 'Beranda',
              activeAsset: 'assets/images/nav_home_active.png',
              inactiveAsset: 'assets/images/nav_home_inactive.png',
              activeIcon: Icons.home_rounded,
              inactiveIcon: Icons.home_outlined,
              isDark: isDark,
              isVideo: isVideo,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 1,
              label: lang?.tr('nav_orders') ?? 'Pesanan',
              activeAsset: 'assets/images/nav_orders_active.png',
              inactiveAsset: 'assets/images/nav_orders_inactive.png',
              activeIcon: Icons.receipt_rounded,
              inactiveIcon: Icons.receipt_outlined,
              badgeText: activeOrdersCount > 0 ? '$activeOrdersCount' : null,
              isDark: isDark,
              isVideo: isVideo,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 2,
              label: lang?.tr('nav_promo') ?? 'Promo',
              activeAsset: 'assets/images/nav_promo_active.png',
              inactiveAsset: 'assets/images/nav_promo_inactive.png',
              activeIcon: Icons.local_offer_rounded,
              inactiveIcon: Icons.local_offer_outlined,
              badgeText: promoUnread > 0 ? '$promoUnread' : null,
              isDark: isDark,
              isVideo: isVideo,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 3,
              label: lang?.tr('nav_video') ?? 'Video',
              activeAsset: 'assets/images/nav_video_active.png',
              inactiveAsset: 'assets/images/nav_video_inactive.png',
              activeIcon: Icons.play_circle_fill_rounded,
              inactiveIcon: Icons.play_circle_outline_rounded,
              isDark: isDark,
              isVideo: isVideo,
            ),
          ),
          Expanded(
            child: _buildNavItem(
              context: context,
              index: 4,
              label: lang?.tr('nav_profile') ?? 'Profil',
              activeAsset: 'assets/images/nav_profile_active.png',
              inactiveAsset: 'assets/images/nav_profile_inactive.png',
              activeIcon: Icons.person_rounded,
              inactiveIcon: Icons.person_outline_rounded,
              isDark: isDark,
              isVideo: isVideo,
            ),
          ),
        ],
      ),
    );
  }

  /// Komponen NavItem Standar:
  /// - Label menu muncul di bawah semua ikon secara konsisten
  /// - Tab terpilih dibungkus Selected Pill Glassmorphism elegan ber-radius penuh (Stadium/Capsule)
  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required String activeAsset,
    required String inactiveAsset,
    IconData? fallbackIcon,
    IconData? activeIcon,
    IconData? inactiveIcon,
    String? badgeText,
    bool hasDotBadge = false,
    required bool isDark,
    bool isVideo = false,
  }) {
    final isSelected = widget.currentIndex == index;
    final activeTextColor = isVideo
        ? (isDark ? Colors.white : const Color(0xFF0F172A))
        : (isDark ? Colors.white : const Color(0xFF0F172A));
    final inactiveColor = isVideo
        ? (isDark ? Colors.white70 : const Color(0xFF64748B))
        : (isDark ? Colors.white70 : const Color(0xFF64748B));

    final pillBg = isVideo
        ? (isDark
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF1F5F9))
        : (isDark
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.38));

    final pillBorder = isVideo
        ? (isDark
            ? Colors.white.withValues(alpha: 0.30)
            : const Color(0xFFE2E8F0))
        : (isDark
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.55));

    final resolvedIcon = isSelected
        ? (activeIcon ?? fallbackIcon ?? Icons.circle)
        : (inactiveIcon ?? fallbackIcon ?? Icons.circle_outlined);

    final iconWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Icon(
          resolvedIcon,
          size: 20,
          color: isSelected ? activeTextColor : inactiveColor,
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
        else if (hasDotBadge && !isSelected)
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
    );

    final labelWidget = Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        color: isSelected ? activeTextColor : inactiveColor,
        height: 1.1,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (isSelected) {
      return InkWell(
        onTap: () => _onStandardTap(context, index),
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOutCubic,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: pillBg,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: pillBorder,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.06),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              iconWidget,
              const SizedBox(height: 2),
              labelWidget,
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: () => _onStandardTap(context, index),
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            iconWidget,
            const SizedBox(height: 2),
            labelWidget,
          ],
        ),
      ),
    );
  }

  /// 2. Mode Profil (Split Island) - Left Capsule: Exactly 2 Action Buttons
  /// - Chat (Icons.chat_bubble_rounded)
  /// - Buat Video (Icons.video_call_rounded)
  Widget _buildProfileLeftActions(bool isDark) {
    return Container(
      key: const ValueKey('profile_split_actions'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          // 1. Chat Button
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (widget.onChatTap != null) {
                  widget.onChatTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InAppChatScreen(
                        orderId: 'cs-gage-support',
                        recipientName: 'Pusat Bantuan GAGE',
                        recipientRole: 'ai',
                        recipientPhone: '',
                      ),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_rounded,
                      size: 18,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Chat',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // 2. Buat Video Button
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                if (widget.onCreateVideoTap != null) {
                  widget.onCreateVideoTap!();
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AffiliateVideoUploadScreen(),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: [
                    BoxShadow(
                      color: GageTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.video_call_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Buat Video',
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Mode Profil (Split Island) - Right Capsule: Standalone Circular Frosted Glass Container with red Kembali icon WITHOUT text label
  Widget _buildRightCircularIsland(bool isDark, bool isVideo) {
    return Container(
      width: 58,
      height: 58,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isVideo
                  ? Colors.white.withValues(alpha: 0.85)
                  : (isDark
                      ? const Color(0xFF0F172A).withValues(alpha: 0.50)
                      : Colors.white.withValues(alpha: 0.55)),
              border: Border.all(
                color: isVideo
                    ? const Color(0xFFE2E8F0)
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.white.withValues(alpha: 0.40)),
                width: 1.0,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _revertToStandardNavBar,
                customBorder: const CircleBorder(),
                child: const Center(
                  child: Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFFE52320),
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
