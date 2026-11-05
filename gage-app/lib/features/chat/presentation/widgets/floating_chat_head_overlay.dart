import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

/// Overlay Floating Chat Head untuk Layar Dalam
/// - Hanya muncul ketika ada pesan chat masuk saat pengguna sedang di layar dalam.
/// - Ikon konsisten: Menggunakan Ikon Chat GAGE tetap (tidak berganti-ganti).
/// - Preview pesan melayang selama 3 detik, lalu mengecil menjadi bubble melayang.
/// - Magnetis: Menempel otomatis ke tepi kiri atau kanan layar.
/// - Ketuk untuk membuka ruang chat, geser ke bawah untuk menutup.
class FloatingChatHeadOverlay {
  static OverlayEntry? _entry;
  static Timer? _tooltipTimer;

  static void showIncomingMessage({
    required BuildContext context,
    required String senderName,
    required String messageText,
    required String orderId,
    required String recipientPhone,
    String recipientRole = 'driver',
  }) {
    dismiss();

    final overlay = Overlay.of(context, rootOverlay: true);

    _entry = OverlayEntry(
      builder: (ctx) => _FloatingChatHeadWidget(
        senderName: senderName,
        messageText: messageText,
        onTap: () {
          dismiss();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => InAppChatScreen(
                orderId: orderId,
                recipientName: senderName,
                recipientRole: recipientRole,
                recipientPhone: recipientPhone,
                currentRole: 'customer',
              ),
            ),
          );
        },
        onDismiss: dismiss,
      ),
    );

    overlay.insert(_entry!);
  }

  static void dismiss() {
    _tooltipTimer?.cancel();
    _tooltipTimer = null;
    _entry?.remove();
    _entry = null;
  }
}

class _FloatingChatHeadWidget extends StatefulWidget {
  final String senderName;
  final String messageText;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _FloatingChatHeadWidget({
    required this.senderName,
    required this.messageText,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_FloatingChatHeadWidget> createState() => _FloatingChatHeadWidgetState();
}

class _FloatingChatHeadWidgetState extends State<_FloatingChatHeadWidget> {
  Offset _position = const Offset(16, 120);
  bool _showTooltip = true;
  Timer? _collapseTimer;

  @override
  void initState() {
    super.initState();
    // 3 detik pertama menampilkan preview balon teks pesan
    _collapseTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showTooltip = false);
      }
    });
  }

  @override
  void dispose() {
    _collapseTimer?.cancel();
    super.dispose();
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) {
    // Snap magnetis ke tepi kiri atau kanan terdekat
    final midX = screenSize.width / 2;
    double targetX = _position.dx < midX ? 12 : screenSize.width - 64;
    double targetY = _position.dy.clamp(60.0, screenSize.height - 120);

    setState(() {
      _position = Offset(targetX, targetY);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: Material(
        color: Colors.transparent,
        child: GestureDetector(
          onPanUpdate: (details) {
            setState(() {
              _position += details.delta;
              _showTooltip = false;
            });
          },
          onPanEnd: (details) => _onPanEnd(details, screenSize),
          onTap: widget.onTap,
          child: Column(
            crossAxisAlignment: _position.dx > screenSize.width / 2 ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tooltip Preview Pesan (Hanya muncul 3 detik pertama)
              if (_showTooltip)
                AnimatedOpacity(
                  opacity: _showTooltip ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    constraints: BoxConstraints(maxWidth: screenSize.width * 0.72),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: GageTheme.primary.withValues(alpha: 0.3),
                        width: 1.2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.mark_chat_unread_rounded, size: 13, color: GageTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              widget.senderName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: GageTheme.primary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.messageText,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),

              // Floating Chat Bubble Bulat
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                      border: Border.all(color: GageTheme.primary, width: 2),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Image.asset(
                      'assets/images/gage_chat_icon.png',
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) => const Icon(
                        Icons.chat_bubble_rounded,
                        color: GageTheme.primary,
                        size: 26,
                      ),
                    ),
                  ),

                  // Red Dot Unread Badge
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: GageTheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
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
}
