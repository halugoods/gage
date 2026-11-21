import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Floating Frosted Glass Bottom Navigation Bar untuk Workstation Mitra Usaha (Merchant Portal)
/// Paritas 1:1 dengan GageBottomNavBar (Customer Portal):
/// - Mengambang 12px di atas bottom safe area (padding 16, 0, 16, 12)
/// - Dimensi presisi: height 60px, outer radius 32, blur 24x24
/// - Selected tab pill: height 50px, borderRadius 999 (full capsule), snug-fit tightly to edges
/// - Active text & icon color: Color(0xFF0F172A) di Light / Colors.white di Dark
/// - Badge counter merah untuk pesanan baru & chat yang belum dibaca
/// - 100% responsif terhadap Dark & Light Mode
class MerchantFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int newOrderCount;
  final int unreadChatCount;

  const MerchantFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.newOrderCount = 0,
    this.unreadChatCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SizedBox(
            height: 60,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
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
                      color: isDark
                          ? const Color(0xFF1E293B).withValues(alpha: 0.50)
                          : Colors.white.withValues(alpha: 0.52),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.white.withValues(alpha: 0.60),
                        width: 1.0,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 0,
                            label: 'Pesanan',
                            icon: Icons.receipt,
                            badgeText: newOrderCount > 0
                                ? (newOrderCount > 99 ? '99+' : '$newOrderCount')
                                : null,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 1,
                            label: 'Chat',
                            icon: Icons.chat_bubble_rounded,
                            badgeText: unreadChatCount > 0
                                ? (unreadChatCount > 99 ? '99+' : '$unreadChatCount')
                                : null,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 2,
                            label: 'Outlet',
                            icon: Icons.storefront_rounded,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 3,
                            label: 'Marketing',
                            icon: Icons.campaign_rounded,
                            isDark: isDark,
                          ),
                        ),
                        Expanded(
                          child: _buildNavItem(
                            context: context,
                            index: 4,
                            label: 'GagePay',
                            icon: Icons.account_balance_wallet_rounded,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required String label,
    required IconData icon,
    String? badgeText,
    required bool isDark,
  }) {
    final isSelected = currentIndex == index;
    final activeTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final inactiveColor = isDark ? Colors.white70 : const Color(0xFF64748B);

    final pillBg = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.38);

    final pillBorder = isDark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.55);

    final iconWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        icon == Icons.receipt
            ? Transform.scale(
                scaleX: 0.85,
                scaleY: 0.95,
                child: Icon(
                  icon,
                  size: 20,
                  color: isSelected ? activeTextColor : inactiveColor,
                ),
              )
            : Icon(
                icon,
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
        onTap: () {
          HapticFeedback.selectionClick();
          onTabSelected(index);
        },
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
      onTap: () {
        HapticFeedback.selectionClick();
        onTabSelected(index);
      },
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
}
