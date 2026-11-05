import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_activity_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_earnings_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_chat_list_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_account_screen.dart';

/// Universal Bottom Navigation Bar untuk GAGE Driver (GoPartner Style)
/// Mendukung callback [onTabSelected] untuk workstation terpusat (DriverRootScreen)
/// serta fallback navigasi mandiri antar layar.
class DriverBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int>? onTabSelected;

  const DriverBottomNavBar({
    super.key,
    required this.currentIndex,
    this.onTabSelected,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    HapticFeedback.selectionClick();

    if (onTabSelected != null) {
      onTabSelected!(index);
      return;
    }

    Widget target;
    switch (index) {
      case 0:
        target = const DriverScreen();
        break;
      case 1:
        target = const DriverActivityScreen();
        break;
      case 2:
        target = const DriverEarningsScreen();
        break;
      case 3:
        target = const DriverChatListScreen();
        break;
      case 4:
        target = const DriverAccountScreen();
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

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(context, 0, Icons.navigation_rounded, 'Beranda', isDark: isDark),
            _buildNavItem(context, 1, Icons.receipt_long_rounded, 'Aktivitas', isDark: isDark),
            _buildNavItem(context, 2, Icons.account_balance_wallet_rounded, 'Pendapatan', isDark: isDark),
            _buildNavItem(context, 3, Icons.chat_bubble_rounded, 'Pesan', hasBadge: true, isDark: isDark),
            _buildNavItem(context, 4, Icons.person_rounded, 'Akun', isDark: isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    int index,
    IconData icon,
    String label, {
    bool hasBadge = false,
    bool isDark = false,
  }) {
    final isSelected = index == currentIndex;
    final color = isSelected ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black54);

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _onTap(context, index),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(icon, color: color, size: 22),
                    if (hasBadge)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          width: 8,
                          height: 8,
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
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
