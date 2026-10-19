import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_activity_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_earnings_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_chat_list_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_account_screen.dart';

/// Universal Bottom Navigation Bar untuk GAGE Driver (GoPartner Style)
/// Menggunakan arsitektur Independent Top-Level Route (tanpa nested Scaffold di IndexedStack)
/// 100% bebas dari risiko viewport collapse AOT di seluruh device.
class DriverBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const DriverBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    HapticFeedback.selectionClick();

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
    final activeColor = GageTheme.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(context, index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  if (hasBadge)
                    Positioned(
                      top: -2,
                      right: -3,
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
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
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
}
