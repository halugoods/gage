import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Gage3DFlipCardDialog
/// Dialog popup kartu 3D interaktif yang dapat dibalik (flip 180 derajat)
/// berdasarkan spesifikasi visual Mastercard / Kartu Rekening GAGE:
/// - Sisi Depan: Logo brand, gold chip circuit, contactless wave, nomor kartu, valid thru, nama pemegang
/// - Sisi Belakang: Pita magnetik hitam diagonal strip, panel tanda tangan putih, kode CVV
/// - Aksi: Tap kartu untuk flip 3D mulus, tombol 'Jadikan Rekening Utama' & 'Salin Nomor'
class Gage3DFlipCardDialog extends StatefulWidget {
  final Map<String, dynamic> cardData;
  final bool isPrimary;
  final VoidCallback? onSetAsPrimary;

  const Gage3DFlipCardDialog({
    super.key,
    required this.cardData,
    this.isPrimary = false,
    this.onSetAsPrimary,
  });

  static Future<void> show(
    BuildContext context, {
    required Map<String, dynamic> cardData,
    bool isPrimary = false,
    VoidCallback? onSetAsPrimary,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Gage3DFlipCard',
      barrierColor: Colors.black.withValues(alpha: 0.75),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return Gage3DFlipCardDialog(
          cardData: cardData,
          isPrimary: isPrimary,
          onSetAsPrimary: onSetAsPrimary,
        );
      },
      transitionBuilder: (ctx, anim1, anim2, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim1, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim1, child: child),
        );
      },
    );
  }

  @override
  State<Gage3DFlipCardDialog> createState() => _Gage3DFlipCardDialogState();
}

class _Gage3DFlipCardDialogState extends State<Gage3DFlipCardDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  void _toggleFlip() {
    HapticFeedback.mediumImpact();
    if (_isFront) {
      _flipCtrl.forward();
    } else {
      _flipCtrl.reverse();
    }
    setState(() => _isFront = !_isFront);
  }

  @override
  Widget build(BuildContext context) {
    final bankName = widget.cardData['bank'] as String? ?? 'GAGE PAY';
    final fullNumber = widget.cardData['fullNumber'] as String? ?? '5524 9910 4242';
    final holder = widget.cardData['holder'] as String? ?? 'HALU GOODS';
    final validThru = widget.cardData['validThru'] as String? ?? '12 / 28';

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header Petunjuk & Tombol Tutup
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.touch_app_rounded, color: Colors.amber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _isFront ? 'Ketuk kartu untuk lihat sisi belakang' : 'Ketuk kartu untuk lihat sisi depan',
                          style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Interactive 3D Flip Card Container
              GestureDetector(
                onTap: _toggleFlip,
                child: AnimatedBuilder(
                  animation: _flipAnim,
                  builder: (context, child) {
                    final angle = _flipAnim.value * math.pi;
                    final isUnderHalf = _flipAnim.value < 0.5;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateY(angle),
                      child: isUnderHalf
                          ? _buildFrontCard(bankName, fullNumber, holder, validThru)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(math.pi),
                              child: _buildBackCard(fullNumber),
                            ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Tombol-tombol Aksi Full-Rounded di Bawah Kartu
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white30, width: 1.2),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: fullNumber.replaceAll(' ', '')));
                        GageToast.show(
                          context,
                          'Nomor kartu ($fullNumber) disalin ke clipboard!',
                          type: GageToastType.success,
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text(
                        'Salin Nomor',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isPrimary ? const Color(0xFF16A34A) : GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: widget.isPrimary
                          ? null
                          : () {
                              if (widget.onSetAsPrimary != null) {
                                widget.onSetAsPrimary!();
                              }
                              Navigator.pop(context);
                              GageToast.show(
                                context,
                                '$bankName dijadikan sebagai Rekening Utama!',
                                type: GageToastType.success,
                              );
                            },
                      icon: Icon(
                        widget.isPrimary ? Icons.check_circle_rounded : Icons.star_rounded,
                        size: 16,
                      ),
                      label: Text(
                        widget.isPrimary ? 'Rekening Utama' : 'Jadikan Utama',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFrontCard(String bank, String number, String holder, String date) {
    return Container(
      width: 320,
      height: 195,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Stack(
        children: [
          // Background Specular Shimmer
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Header: Brand & Contactless Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                bank.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.0,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.contactless_rounded, color: Colors.white60, size: 24),
                  const SizedBox(width: 8),
                  // Mastercard Circles Logo
                  SizedBox(
                    width: 36,
                    height: 24,
                    child: Stack(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFD50000),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Positioned(
                          left: 13,
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withValues(alpha: 0.90),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Chip Gold Circuit
          Positioned(
            left: 0,
            top: 42,
            child: Container(
              width: 38,
              height: 28,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFBBF24), Color(0xFFD97706)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFFDE68A), width: 0.8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 22,
                      height: 14,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF78350F), width: 0.7),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nomor Kartu Besar & Jelas
          Positioned(
            left: 0,
            bottom: 38,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.5,
                fontFamily: 'monospace',
                shadows: [
                  Shadow(color: Colors.black54, offset: Offset(0, 1.5), blurRadius: 2),
                ],
              ),
            ),
          ),

          // Footer: Pemegang Kartu & Valid Thru
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'CARD HOLDER',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      holder.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'VALID THRU',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 7.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackCard(String number) {
    return Container(
      width: 320,
      height: 195,
      decoration: BoxDecoration(
        color: const Color(0xFF171717),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Pita Magnetik Hitam Tekstur
          Container(
            width: double.infinity,
            height: 38,
            color: const Color(0xFF0F0F0F),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black,
                    const Color(0xFF262626),
                    Colors.black,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Panel Signature Strip & CVV Code
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Signature Panel Putih
                Expanded(
                  flex: 3,
                  child: Container(
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDEDED),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      height: 1,
                      color: Colors.grey.shade400,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // CVV Strip
                Container(
                  width: 50,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '•••',
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 3. Security hologram text & info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'GAGE ELECTRONIC WALLET SYSTEM',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'ISO 27001 • SECURE',
                  style: TextStyle(
                    color: Colors.amber.shade600,
                    fontSize: 7.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
