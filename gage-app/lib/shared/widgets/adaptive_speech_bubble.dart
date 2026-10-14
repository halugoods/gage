import 'dart:async';
import 'package:flutter/material.dart';

/// Painter untuk ekor segitiga speech bubble yang natural (Speech Bubble Tail)
class SpeechBubblePainter extends CustomPainter {
  final Color color;
  final Color shadowColor;
  final double tailWidth;
  final double tailHeight;

  SpeechBubblePainter({
    required this.color,
    required this.shadowColor,
    this.tailWidth = 10,
    this.tailHeight = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Gambar ekor lancip di kiri bawah gelembung chat
    final path = Path();
    path.moveTo(14, size.height);
    path.lineTo(6, size.height + tailHeight);
    path.lineTo(18, size.height);
    path.close();

    final paint = Paint()..color = color;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SpeechBubblePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

/// Adaptive Speech Bubble dengan Typewriter Animation Loop
/// Ukuran gelembung chat melebar secara adaptif mengikuti karakter teks yang sedang diketik.
/// Seluruh gelembung chat langsung berfungsi sebagai tombol sentuh (tappable).
/// Clean tanpa wrapper card tambahan.
class AdaptiveSpeechBubble extends StatefulWidget {
  final String fullText;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color textColor;
  final Color iconColor;
  final IconData icon;

  const AdaptiveSpeechBubble({
    super.key,
    this.fullText = 'Konsultasi gratis, klik di sini',
    required this.onTap,
    this.backgroundColor = const Color(0xFF16A34A), // Hijau Agrikultur GAGE
    this.textColor = Colors.white,
    this.iconColor = Colors.white,
    this.icon = Icons.support_agent_rounded,
  });

  @override
  State<AdaptiveSpeechBubble> createState() => _AdaptiveSpeechBubbleState();
}

class _AdaptiveSpeechBubbleState extends State<AdaptiveSpeechBubble> {
  String _displayedText = '';
  int _charIndex = 0;
  bool _isDeleting = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTypewriterLoop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTypewriterLoop() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 70), (t) {
      if (!mounted) return;

      setState(() {
        if (!_isDeleting) {
          // Mengetik maju
          if (_charIndex < widget.fullText.length) {
            _charIndex++;
            _displayedText = widget.fullText.substring(0, _charIndex);
          } else {
            // Selesai mengetik teks utuh, tahan sejenak sebelum menghapus
            _timer?.cancel();
            Future.delayed(const Duration(milliseconds: 2400), () {
              if (mounted) {
                _isDeleting = true;
                _startTypewriterLoop();
              }
            });
          }
        } else {
          // Menghapus mundur (backspace)
          if (_charIndex > 0) {
            _charIndex--;
            _displayedText = widget.fullText.substring(0, _charIndex);
          } else {
            // Selesai menghapus, jeda sejenak lalu mengetik ulang
            _timer?.cancel();
            _isDeleting = false;
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) {
                _startTypewriterLoop();
              }
            });
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Badan Speech Bubble (Otomatis Adaptive Sesuai Karakter)
          AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
                bottomLeft: Radius.circular(4), // Sudut tumpul tempat ekor chat
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.backgroundColor.withValues(alpha: 0.35),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min, // Adaptive wrap content!
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 17),
                const SizedBox(width: 7),
                Text(
                  _displayedText.isEmpty ? ' ' : _displayedText,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.2,
                  ),
                ),
                // Kursor Ketik Berkedip
                AnimatedOpacity(
                  opacity: _charIndex < widget.fullText.length ? 1.0 : 0.4,
                  duration: const Duration(milliseconds: 250),
                  child: Text(
                    ' |',
                    style: TextStyle(
                      color: widget.textColor.withValues(alpha: 0.8),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Ekor Lancip Speech Bubble (Real Chat Tail)
          Positioned(
            left: 6,
            bottom: -6,
            child: CustomPaint(
              size: const Size(18, 7),
              painter: SpeechBubblePainter(
                color: widget.backgroundColor,
                shadowColor: Colors.black26,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
