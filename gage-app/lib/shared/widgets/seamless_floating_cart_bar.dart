import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';

/// Floating Cart Bar 1 Card Tunggal Kompak & Seamless (Gojek / Taste-skill standard)
/// - Desain 1 Card floating rounded kompak (tinggi ~62px), tidak bulky
/// - Inline progress bar dengan animasi glow berdenyut di dalam informasi pesanan
/// - Kiri: Jumlah menu, subtotal, hint diskon, dan glowing inline progress bar
/// - Kanan: Action button "Lihat Pesanan" merah GAGE dengan sudut kotak tumpul (10px)
class SeamlessFloatingCartBar extends StatefulWidget {
  const SeamlessFloatingCartBar({super.key});

  @override
  State<SeamlessFloatingCartBar> createState() => _SeamlessFloatingCartBarState();
}

class _SeamlessFloatingCartBarState extends State<SeamlessFloatingCartBar> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.45, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    if (cart.totalItemCount <= 0) return const SizedBox.shrink();

    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtotal = cart.subtotal;

    String discountHint;
    double progress;
    bool isDiscountAchieved = false;

    if (subtotal < 15000) {
      final needed = 15000 - subtotal;
      discountHint = '+Rp ${NumberFormat("#,###", "id_ID").format(needed)} lagi untuk diskon';
      progress = (subtotal / 15000).clamp(0.0, 1.0);
    } else if (subtotal < 35000) {
      final needed = 35000 - subtotal;
      discountHint = 'Hemat 7rb! +Rp ${NumberFormat("#,###", "id_ID").format(needed)} lagi diskon 25rb';
      progress = (subtotal / 35000).clamp(0.0, 1.0);
      isDiscountAchieved = true;
    } else {
      discountHint = 'Mantap! Diskon maksimal 25rb aktif';
      progress = 1.0;
      isDiscountAchieved = true;
    }

    final barColor = progress >= 1.0
        ? const Color(0xFF10B981)
        : (isDiscountAchieved ? const Color(0xFFF59E0B) : GageTheme.primary);

    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
              );
            },
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  // Left side: Item count + subtotal + discount hint + glowing inline progress bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${cart.totalItemCount} Menu',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              width: 3.5,
                              height: 3.5,
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              currencyFormatter.format(subtotal),
                              style: TextStyle(
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          discountHint,
                          style: TextStyle(
                            color: isDiscountAchieved
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            fontSize: 11,
                            fontWeight: isDiscountAchieved ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Inline Glowing Pulsing Progress Bar
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Stack(
                              children: [
                                // Background track
                                Container(
                                  height: 3.5,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                // Glowing Progress Fill
                                LayoutBuilder(
                                  builder: (ctx, constraints) {
                                    final fillWidth = constraints.maxWidth * progress;
                                    return Container(
                                      height: 3.5,
                                      width: fillWidth,
                                      decoration: BoxDecoration(
                                        color: barColor,
                                        borderRadius: BorderRadius.circular(3),
                                        boxShadow: isDiscountAchieved
                                            ? [
                                                BoxShadow(
                                                  color: barColor.withValues(alpha: 0.6 * _pulseAnimation.value),
                                                  blurRadius: 6 * _pulseAnimation.value,
                                                  spreadRadius: 1 * _pulseAnimation.value,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Right side: Compact red CTA button with standardized 10px rounded corner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(10), // Standarisasi kotak corner GAGE
                      boxShadow: [
                        BoxShadow(
                          color: GageTheme.primary.withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Lihat Pesanan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
