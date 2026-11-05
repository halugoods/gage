import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Reusable Filter Pill Capsule GAGE SuperApp (Master Design Blueprint)
/// Kiblat UI dari desain filter modern anti-slop:
/// - Bentuk kapsul penuh (BorderRadius.circular(50))
/// - State Inactive: Pastel crimson tint (Rose-50 #FFF1F2), border halus (#FECDD3), text GageTheme.primary
/// - State Active: Solid crimson red GageTheme.primary, text putih, glow shadow lembut
/// - Micro-interaction: HapticFeedback.selectionClick() saat disentuh
/// - Zero clutter: Tanpa ikon silang (X) yang tidak perlu
class GageFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  const GageFilterPill({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final inactiveBg = isDark ? const Color(0xFF2C1315) : const Color(0xFFFFF1F2);
    final inactiveBorder = isDark
        ? const Color(0xFF991B1B).withValues(alpha: 0.6)
        : const Color(0xFFFECDD3);
    final inactiveText = isDark ? const Color(0xFFFCA5A5) : GageTheme.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(50),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7.5),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary : inactiveBg,
          borderRadius: BorderRadius.circular(50),
          border: Border.all(
            color: isSelected ? GageTheme.primary : inactiveBorder,
            width: 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.28),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : inactiveText,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : inactiveText,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
