import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_order_dispatch_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_whatsapp_center_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_curation_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_settings_screen.dart';

/// Universal Bottom Navigation Bar untuk GAGE Admin (Command Tower Style)
/// Menggunakan arsitektur Independent Top-Level Route (tanpa nested Scaffold di IndexedStack)
/// 100% bebas dari risiko viewport collapse AOT di seluruh device.
class AdminBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AdminBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  void _onTap(BuildContext context, int index) {
    if (index == currentIndex) return;

    HapticFeedback.selectionClick();

    Widget target;
    switch (index) {
      case 0:
        target = const AdminScreen();
        break;
      case 1:
        target = const AdminOrderDispatchScreen();
        break;
      case 2:
        target = const AdminWhatsappCenterScreen();
        break;
      case 3:
        target = const AdminCurationScreen();
        break;
      case 4:
        target = const AdminSettingsScreen();
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
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        decoration: BoxDecoration(
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
              _buildNavItem(context, 0, Icons.space_dashboard_rounded, 'Beranda', isDark: isDark),
              _buildNavItem(context, 1, Icons.receipt_long_rounded, 'Riwayat', isDark: isDark),
              _buildNavItem(context, 2, Icons.chat_bubble_rounded, 'Chat', hasBadge: true, isDark: isDark),
              _buildNavItem(context, 3, Icons.verified_rounded, 'Kurasi', isDark: isDark),
              _buildNavItem(context, 4, Icons.tune_rounded, 'Pengaturan', isDark: isDark),
            ],
          ),
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
                  fontSize: 10,
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
