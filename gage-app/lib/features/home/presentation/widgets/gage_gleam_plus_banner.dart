import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/membership/presentation/membership_screen.dart';

/// GageGleamPlusBanner
/// Banner promosi langganan GAGE Plus di Beranda dengan efek kilauan cahaya (gleam/shimmer)
/// yang melintas diagonal selama ~1 detik, lalu berhenti sejenak selama 2.5 detik sebelum berulang kembali (total 3.5s).
/// Dihiasi aset grafis 3D nyata kupon voucher (Nano Banana 2.1) di atas rounded mound di sisi kiri & kanan.
class GageGleamPlusBanner extends StatefulWidget {
  const GageGleamPlusBanner({super.key});

  @override
  State<GageGleamPlusBanner> createState() => _GageGleamPlusBannerState();
}

class _GageGleamPlusBannerState extends State<GageGleamPlusBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // Total durasi 3.5 detik (sesuai arahan user):
    // ~1.0 detik pertama (0.0 -> 0.285) kilatan miring menyapu seluruh kartu,
    // sisa 2.5 detik (0.285 -> 1.0) jeda diam sebelum mengulang.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Warna solid merah muda berani (blush rose) di light mode, dan deep crimson di dark mode
    final cardBgColor = isDark ? const Color(0xFF280F16) : const Color(0xFFFFDDE2);
    final borderColor = isDark
        ? GageTheme.primary.withValues(alpha: 0.45)
        : const Color(0xFFFDA4AF);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (ctx) => const MembershipScreen()),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                // 1. Bayangan Hitam di Bawah Kupon Kiri
                Positioned(
                  left: 20,
                  top: 51,
                  child: Transform.rotate(
                    angle: 0.14,
                    child: Container(
                      width: 38,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(38, 8)),
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.40 : 0.20),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 2. Motif Kupon Tiket 3D di Kiri (Aset Bersih Transparan Tanpa Residu Putih)
                Positioned(
                  left: 14,
                  top: 11,
                  child: Transform.rotate(
                    angle: 0.14,
                    child: Image.asset(
                      'assets/images/voucher_ticket_3d.png',
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) =>
                          const SizedBox(width: 50, height: 50),
                    ),
                  ),
                ),

                // 3. Bayangan Hitam di Bawah Kupon Kanan
                Positioned(
                  right: 20,
                  top: 51,
                  child: Transform.rotate(
                    angle: -0.14,
                    child: Container(
                      width: 38,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.elliptical(38, 8)),
                        color:
                            Colors.black.withValues(alpha: isDark ? 0.45 : 0.22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black
                                .withValues(alpha: isDark ? 0.40 : 0.20),
                            blurRadius: 5,
                            spreadRadius: 1,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 4. Motif Kupon Tiket 3D di Kanan (Flip Horizontal Agar Kanan Kiri Berhadapan Simetris)
                Positioned(
                  right: 14,
                  top: 11,
                  child: Transform.rotate(
                    angle: -0.14,
                    child: Transform.flip(
                      flipX: true,
                      child: Image.asset(
                        'assets/images/voucher_ticket_3d.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox(width: 50, height: 50),
                      ),
                    ),
                  ),
                ),

                // 5. Konten Utama Banner (Teks + Tombol Kapsul PLUS)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 68),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Pasti dapet diskon tiap hari',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE52320), Color(0xFFB91C1C)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: GageTheme.primary.withValues(alpha: 0.35),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Lihat keuntungan ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '+PLUS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
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

                // 6. Efek Animasi Kilatan Cahaya Miring Menyapu SELURUH Card Container (Full Height & Width)
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        final double t = _controller.value;
                        // Kilatan hanya aktif pada 0.0 - 0.285 (~1.0 detik pertama)
                        // Pada 0.285 - 1.0 (sisa ~2.5 detik) jeda diam sebelum mengulang
                        if (t > 0.285) {
                          return const SizedBox.shrink();
                        }
                        final double progress = t / 0.285;

                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final double cardWidth = constraints.maxWidth;
                            final double cardHeight = constraints.maxHeight;

                            const double angle = -0.35; // ~20 derajat miring
                            const double beamWidth = 160.0;
                            const double beamHeight = 400.0; // Melebihi tinggi kartu secara penuh

                            final double startX = -beamWidth - 100.0;
                            final double endX = cardWidth + 100.0;
                            final double currentX = startX + progress * (endX - startX);

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Positioned(
                                  left: currentX,
                                  top: (cardHeight - beamHeight) / 2,
                                  child: Transform.rotate(
                                    angle: angle,
                                    child: Container(
                                      width: beamWidth,
                                      height: beamHeight,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.white.withValues(alpha: 0.0),
                                            Colors.white.withValues(
                                                alpha: isDark ? 0.15 : 0.25),
                                            Colors.white.withValues(
                                                alpha: isDark ? 0.45 : 0.70),
                                            Colors.white.withValues(
                                                alpha: isDark ? 0.15 : 0.25),
                                            Colors.white.withValues(alpha: 0.0),
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
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
