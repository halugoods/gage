import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Modal Percakapan Suara Asisten AI GAGE
/// Diadaptasi dari referensi CSS .container-ia-chat & .voice-chat:
/// - Rotating polygon glowing fire orb dengan palet warna #ffbf48 & #be4a1d
/// - Efek ambient glow pendaran ganda (filter blur)
/// - Teks "Conversation Started" dengan gradient shimmer & "Press to cancel the conversation"
/// - Visualisasi waveform gelombang audio saat mendengarkan
class GageVoiceConvoModal extends StatefulWidget {
  final ValueChanged<String> onResult;

  const GageVoiceConvoModal({
    super.key,
    required this.onResult,
  });

  static Future<void> show(BuildContext context, {required ValueChanged<String> onResult}) {
    HapticFeedback.mediumImpact();
    return GageFloatingSheet.show(
      context: context,
      builder: (_) => GageVoiceConvoModal(onResult: onResult),
    );
  }

  @override
  State<GageVoiceConvoModal> createState() => _GageVoiceConvoModalState();
}

class _GageVoiceConvoModalState extends State<GageVoiceConvoModal> with TickerProviderStateMixin {
  late AnimationController _rotationCtrl;
  late AnimationController _pulseCtrl;
  String _recognizedSpeech = 'Halo asisten GAGE, mau tanya promo hari ini...';
  final bool _isListening = true;

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Simulasi penangkapan suara dinamis
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() {
          _recognizedSpeech = 'Mau pesan dimsum sewu 2 porsi dan es teh';
        });
      }
    });
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header: Status Asisten AI
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFBF48),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'Mendengarkan...' : 'Selesai',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, size: 18),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Central Glowing Fire Orb (.ai .rings .glass)
          Center(
            child: SizedBox(
              width: 140,
              height: 140,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ambient Outer Glow 1 (#be4a1d - Deep Amber Flame)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + (_pulseCtrl.value * 0.18);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFBE4A1D).withValues(alpha: 0.28),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),

                  // Ambient Outer Glow 2 (#ffbf48 - Warm Fire Gold)
                  AnimatedBuilder(
                    animation: _pulseCtrl,
                    builder: (context, _) {
                      final scale = 1.0 + ((1.0 - _pulseCtrl.value) * 0.14);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFFFFBF48).withValues(alpha: 0.38),
                          ),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      );
                    },
                  ),

                  // Rotating Multi-polygon Flame Orb
                  AnimatedBuilder(
                    animation: _rotationCtrl,
                    builder: (context, _) {
                      return Transform.rotate(
                        angle: _rotationCtrl.value * 2 * math.pi,
                        child: CustomPaint(
                          size: const Size(76, 76),
                          painter: _FlameOrbPainter(
                            progress: _rotationCtrl.value,
                          ),
                        ),
                      );
                    },
                  ),

                  // Center Mic Glass Circle
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B).withValues(alpha: 0.85),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFFFBF48), width: 1.5),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: Color(0xFFFFBF48),
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Teks Header Desain CSS (.text-voice: Conversation Started)
          ShaderMask(
            shaderCallback: (bounds) {
              return const LinearGradient(
                colors: [
                  Color(0xFF959595),
                  Color(0xFFE770CD),
                  Color(0xFFFFCEF4),
                  Color(0xFFE770CD),
                  Color(0xFF959595),
                ],
              ).createShader(bounds);
            },
            child: const Text(
              'Conversation Started',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Press to cancel the conversation',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),

          const SizedBox(height: 18),

          // Teks Suara yang Tertangkap
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Text(
              '"$_recognizedSpeech"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Tombol Aksi Bawah: Gunakan Teks Ini & Batal
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white70 : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () {
                    widget.onResult(_recognizedSpeech);
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Kirim ke Pesan', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// CustomPainter untuk mereproduksi rotating polygon glowing fire orb (.loader dari CSS)
class _FlameOrbPainter extends CustomPainter {
  final double progress;

  _FlameOrbPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Layer 1: Polygon Orange-Red (#be4a1d)
    final paint1 = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFFFFBF48), Color(0xFFBE4A1D)],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    final path1 = Path();
    const int sides = 7;
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) + (progress * 2 * math.pi);
      final r = (i % 2 == 0) ? radius : radius * 0.78;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    path1.close();
    canvas.drawPath(path1, paint1);

    // Layer 2: Inner Gold (#ffbf48) Polygon rotated opposite
    final paint2 = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.white, Color(0xFFFFBF48)],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.6))
      ..style = PaintingStyle.fill;

    final path2 = Path();
    for (int i = 0; i < sides; i++) {
      final angle = (i * 2 * math.pi / sides) - (progress * 2 * math.pi);
      final r = (i % 2 == 0) ? radius * 0.65 : radius * 0.45;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path2.moveTo(x, y);
      } else {
        path2.lineTo(x, y);
      }
    }
    path2.close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _FlameOrbPainter oldDelegate) => oldDelegate.progress != progress;
}
