import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';

/// Widget Kartu ATM 2.5D Digital Virtual GAGEPay
/// Menampilkan kartu ATM mewah dengan EMV chip, gelombang contactless,
/// nomor rekening timbul berbasis standar LUHN ISO/IEC 7812, dan branding resmi.
class GageAtmCardWidget extends StatelessWidget {
  final String accountNumber;
  final String userName;
  final int? requestedAmount;
  final bool isLocked;

  const GageAtmCardWidget({
    super.key,
    required this.accountNumber,
    required this.userName,
    this.requestedAmount,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAcc = LuhnAlgorithm.formatWithSpaces(accountNumber);

    return AspectRatio(
      aspectRatio: 1.586, // Standar ISO ID-1 credit/debit card ratio
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF18181B), // Dark Titanium Obsidian
              Color(0xFF27131A), // Deep Crimson Ruby
              Color(0xFF0F0F12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Efek Spekular Cahaya Studio 2.5D
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Konten Kartu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Baris Atas: Branding GAGEPAY by Halu Goods Indonesia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GAGEPAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'by Halu Goods Indonesia',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: isLocked ? Colors.red.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: isLocked ? Colors.redAccent : Colors.white24, width: 0.8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLocked) ...[
                                const Icon(Icons.lock_rounded, size: 9, color: Colors.redAccent),
                                const SizedBox(width: 3),
                              ],
                              Text(
                                isLocked ? 'KARTU DIKUNCI' : 'REKENING UTAMA',
                                style: TextStyle(
                                  color: isLocked ? Colors.redAccent : const Color(0xFFFDE047),
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Baris Tengah: Realistic Gold EMV Chip & Contactless Wave
                    Row(
                      children: [
                        // Chip EMV Emas
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFFEAB308)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFEF08A), width: 0.8),
                          ),
                          child: CustomPaint(
                            painter: _EmvChipPainter(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white.withValues(alpha: 0.65),
                          size: 22,
                        ),
                      ],
                    ),

                    // Baris Nomor Rekening Timbul (Embossed 12-Digit)
                    Text(
                      formattedAcc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),

                    // Baris Bawah: Nama Pemilik & Tagihan (jika ada)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NAMA PEMILIK',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                userName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (requestedAmount != null && requestedAmount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GageTheme.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              'Rp ${requestedAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Painter garis-garis mikro chip EMV kartu ATM
class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF78350F).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Garis pembagi horizontal
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), paint);
    // Garis pembagi vertikal
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), paint);
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
