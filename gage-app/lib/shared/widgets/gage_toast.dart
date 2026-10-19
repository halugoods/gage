import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum GageToastType {
  info,
  success,
  warning,
  error,
}

/// Dynamic Island Top Pill Toast Notification untuk GAGE
/// Meluncur halus dari bawah notch status bar, berlatar glassmorphism elegan,
/// dengan haptic feedback dan auto-dismiss.
class GageToast {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void showSuccess(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2200)}) {
    show(context, message, type: GageToastType.success, duration: duration);
  }

  static void showError(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2500)}) {
    show(context, message, type: GageToastType.error, duration: duration);
  }

  static void showInfo(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2200)}) {
    show(context, message, type: GageToastType.info, duration: duration);
  }

  static void showWarning(BuildContext context, String message, {Duration duration = const Duration(milliseconds: 2200)}) {
    show(context, message, type: GageToastType.warning, duration: duration);
  }

  static void show(
    BuildContext context,
    String message, {
    GageToastType type = GageToastType.success,
    Duration duration = const Duration(milliseconds: 2200),
  }) {
    // Batalkan toast sebelumnya jika masih aktif
    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    // Haptic feedback ringan
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}

    final entry = OverlayEntry(
      builder: (ctx) => _GageToastWidget(
        message: message,
        type: type,
        onDismiss: () {
          _currentEntry?.remove();
          _currentEntry = null;
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    _dismissTimer = Timer(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }
}

class _GageToastWidget extends StatefulWidget {
  final String message;
  final GageToastType type;
  final VoidCallback onDismiss;

  const _GageToastWidget({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_GageToastWidget> createState() => _GageToastWidgetState();
}

class _GageToastWidgetState extends State<_GageToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -0.6),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  IconData get _icon {
    switch (widget.type) {
      case GageToastType.success:
        return Icons.check_circle_rounded;
      case GageToastType.info:
        return Icons.info_rounded;
      case GageToastType.warning:
        return Icons.warning_rounded;
      case GageToastType.error:
        return Icons.error_rounded;
    }
  }

  Color get _iconColor {
    switch (widget.type) {
      case GageToastType.success:
        return const Color(0xFF10B981); // Emerald Green
      case GageToastType.info:
        return const Color(0xFF38BDF8); // Sky Blue
      case GageToastType.warning:
        return const Color(0xFFF59E0B); // Amber Orange
      case GageToastType.error:
        return const Color(0xFFEF4444); // Red
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Positioned(
      top: topPadding + 10,
      left: 16,
      right: 16,
      child: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: widget.onDismiss,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.98),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 24,
                        spreadRadius: 1,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: _iconColor.withValues(alpha: 0.14),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_icon, color: _iconColor, size: 16),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          widget.message,
                          style: const TextStyle(
                            color: Color(0xFF0F172A),
                            fontSize: 13.0,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
