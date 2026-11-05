import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Badge Level Merchant GAGE:
/// - 'star': Kapsul rounded oranye gradient (#FF9800 -> #F57C00) dengan icon star mini
/// - 'star_plus': Kapsul rounded oranye tua gradient (#FF6F00 -> #FF3D00) dengan icon star & teks STAR+
/// - 'exclusive': Kapsul rounded dengan animasi rotasi SweepGradient 8 warna HSL (CSS Aurora glow),
///   glow blur elegan, dan center capsule gelap (#1E1E24) sesuai referensi desain eksklusif berbayar.
class GageMerchantTierBadge extends StatelessWidget {
  final String tier;
  final double height;

  const GageMerchantTierBadge({
    super.key,
    required this.tier,
    this.height = 18.0,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedTier = tier.toLowerCase().trim();

    if (normalizedTier == 'exclusive') {
      return _ExclusiveTierBadge(height: height);
    } else if (normalizedTier == 'star_plus' || normalizedTier == 'star+') {
      return _StarPlusTierBadge(height: height);
    } else if (normalizedTier == 'star') {
      return _StarTierBadge(height: height);
    }

    return const SizedBox.shrink();
  }
}

/// 1. Star Tier Badge (Kuning Emas Elegan Solid & Bersih)
class _StarTierBadge extends StatelessWidget {
  final double height;
  const _StarTierBadge({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFACC15), Color(0xFFEAB300)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FACC15),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: Color(0xFF78350F), size: 11),
          SizedBox(width: 3),
          Text(
            'STAR',
            style: TextStyle(
              color: Color(0xFF78350F),
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 2. Star+ Tier Badge (Oranye Sunset Deep Gradient)
class _StarPlusTierBadge extends StatelessWidget {
  final double height;
  const _StarPlusTierBadge({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6F00), Color(0xFFFF3D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x44FF3D00),
            blurRadius: 5,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.star_rounded, color: Colors.white, size: 11),
          SizedBox(width: 3),
          Text(
            'STAR+',
            style: TextStyle(
              color: Colors.white,
              fontSize: 9.0,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.3,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// 3. Exclusive Tier Badge (Rotating Conic Rainbow Aurora Glow Border)
class _ExclusiveTierBadge extends StatefulWidget {
  final double height;
  const _ExclusiveTierBadge({required this.height});

  @override
  State<_ExclusiveTierBadge> createState() => _ExclusiveTierBadgeState();
}

class _ExclusiveTierBadgeState extends State<_ExclusiveTierBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;

  // 8 Stop HSL colors sesuai CSS referensi user:
  // hsl(226, 81%, 64%), hsl(271, 81%, 64%), hsl(316, 81%, 64%), hsl(1, 81%, 64%),
  // hsl(46, 81%, 64%), hsl(91, 81%, 64%), hsl(136, 81%, 64%), hsl(181, 81%, 64%)
  static final List<Color> _auroraColors = [
    HSLColor.fromAHSL(1.0, 226, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 271, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 316, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 1, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 46, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 91, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 136, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 181, 0.81, 0.64).toColor(),
    HSLColor.fromAHSL(1.0, 226, 0.81, 0.64).toColor(),
  ];

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = widget.height < 19.0 ? 19.0 : widget.height;
    final radius = BorderRadius.circular(h / 2);

    return AnimatedBuilder(
      animation: _rotationCtrl,
      builder: (context, child) {
        final angle = _rotationCtrl.value * 2 * math.pi;

        return Container(
          height: h,
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              BoxShadow(
                color: _auroraColors[(_rotationCtrl.value * 8).floor() % 8].withValues(alpha: 0.35),
                blurRadius: 6,
                spreadRadius: 0.5,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _RotatingBorderPainter(
              angle: angle,
              colors: _auroraColors,
              borderRadius: radius,
              borderWidth: 1.5,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: radius,
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Color(0xFFFFD700), size: 11),
                  SizedBox(width: 3.5),
                  Text(
                    'EXCLUSIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RotatingBorderPainter extends CustomPainter {
  final double angle;
  final List<Color> colors;
  final BorderRadius borderRadius;
  final double borderWidth;

  _RotatingBorderPainter({
    required this.angle,
    required this.colors,
    required this.borderRadius,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    final paint = Paint()
      ..shader = SweepGradient(
        colors: colors,
        transform: GradientRotation(angle),
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _RotatingBorderPainter oldDelegate) {
    return oldDelegate.angle != angle;
  }
}
