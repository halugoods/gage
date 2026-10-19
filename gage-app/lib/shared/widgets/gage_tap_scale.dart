import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Interactive Tap Scale Wrapper with instant tactile Haptic Feedback
/// Memberikan respon sentuhan instan dan animasi pegas halus (tactile micro-interaction)
class GageTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  final double scaleDown;
  final Duration duration;

  const GageTapScale({
    super.key,
    required this.child,
    required this.onTap,
    this.scaleDown = 0.92,
    this.duration = const Duration(milliseconds: 100),
  });

  @override
  State<GageTapScale> createState() => _GageTapScaleState();
}

class _GageTapScaleState extends State<GageTapScale> {
  bool _isDown = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        if (mounted) setState(() => _isDown = true);
      },
      onTapUp: (_) {
        if (mounted) setState(() => _isDown = false);
        widget.onTap();
      },
      onTapCancel: () {
        if (mounted) setState(() => _isDown = false);
      },
      child: AnimatedScale(
        scale: _isDown ? widget.scaleDown : 1.0,
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        child: widget.child,
      ),
    );
  }
}
