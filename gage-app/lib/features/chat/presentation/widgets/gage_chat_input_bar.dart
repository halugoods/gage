import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// GageChatInputBar
/// Diadaptasi dari spesifikasi visual:
/// - State 1 (Normal / Unfocused): 3 ikon media di kiri (Kamera, Gambar, Berkas)
/// - State 2 (Focused / HasText): 3 ikon media memudar berganti dengan tombol '+' bulat di kiri
/// - Input pill utama dengan placeholder 'Ketik pesan disini...'
/// - State Kanan Dinamis: Tombol Mic Gelombang Suara (animasi denyut merah saat merekam inline) vs Tombol Kirim Gradien
class GageChatInputBar extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSend;
  final VoidCallback? onVoiceTap;
  final ValueChanged<int>? onVoiceRecorded;
  final VoidCallback? onCameraTap;
  final VoidCallback? onGalleryTap;
  final VoidCallback? onFileTap;
  final String hintText;

  const GageChatInputBar({
    super.key,
    required this.controller,
    required this.onSend,
    this.onVoiceTap,
    this.onVoiceRecorded,
    this.onCameraTap,
    this.onGalleryTap,
    this.onFileTap,
    this.hintText = 'Ketik pesan disini...',
  });

  @override
  State<GageChatInputBar> createState() => _GageChatInputBarState();
}

class _GageChatInputBarState extends State<GageChatInputBar> with SingleTickerProviderStateMixin {
  final FocusNode _focusNode = FocusNode();
  bool _hasText = false;
  bool _isAttachmentsForcedOpen = false;

  // Inline Voice Recording State
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
  late final AnimationController _waveAnimCtrl;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;

    _waveAnimCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  void _onTextChanged() {
    final nowHasText = widget.controller.text.trim().isNotEmpty;
    if (nowHasText != _hasText) {
      setState(() => _hasText = nowHasText);
    }
  }

  void _onFocusChanged() {
    if (mounted) setState(() {});
  }

  void _toggleRecording() {
    HapticFeedback.heavyImpact();
    setState(() {
      if (!_isRecording) {
        _isRecording = true;
        _recordDuration = 0;
        GageAudioService.instance.playRecordStartChime();
        _waveAnimCtrl.repeat(reverse: true);
        _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (mounted) {
            setState(() => _recordDuration++);
          }
        });
        widget.onVoiceTap?.call();
      } else {
        _isRecording = false;
        _waveAnimCtrl.stop();
        _recordTimer?.cancel();
        final finalDuration = _recordDuration > 0 ? _recordDuration : 3;
        widget.onVoiceRecorded?.call(finalDuration);
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    _waveAnimCtrl.dispose();
    _recordTimer?.cancel();
    super.dispose();
  }

  void _handleSend() {
    final txt = widget.controller.text.trim();
    if (txt.isNotEmpty) {
      HapticFeedback.lightImpact();
      widget.onSend(txt);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isInputActive = (_focusNode.hasFocus || _hasText) && !_isAttachmentsForcedOpen;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Container Upload Files (Kamera, Gambar, Berkas) vs Plus Button
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: isInputActive
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildUploadIcon(
                    icon: Icons.camera_alt_outlined,
                    onTap: widget.onCameraTap,
                    isDark: isDark,
                  ),
                  _buildUploadIcon(
                    icon: Icons.image_outlined,
                    onTap: widget.onGalleryTap,
                    isDark: isDark,
                  ),
                  _buildUploadIcon(
                    icon: Icons.folder_outlined,
                    onTap: widget.onFileTap,
                    isDark: isDark,
                  ),
                ],
              ),
              secondChild: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _isAttachmentsForcedOpen = !_isAttachmentsForcedOpen;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE9E9E9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isAttachmentsForcedOpen ? Icons.close_rounded : Icons.add_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : const Color(0xFF959595),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 6),

            // Input Pill Utama dengan Placeholder dan Tombol Aksi Terintegrasi
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minHeight: 42, maxHeight: 110),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE9E9E9)),
                  borderRadius: BorderRadius.circular(25),
                  border: _isRecording
                      ? Border.all(color: GageTheme.primary.withValues(alpha: 0.6), width: 1.2)
                      : null,
                ),
                padding: const EdgeInsets.only(left: 16, right: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: _isRecording
                          ? Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Merekam (${_recordDuration}d)... Ketuk icon untuk kirim',
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ],
                            )
                          : TextField(
                              controller: widget.controller,
                              focusNode: _focusNode,
                              maxLines: null,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontFamily: 'Segoe UI',
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : const Color(0xFF4C4C4C),
                              ),
                              decoration: InputDecoration(
                                hintText: widget.hintText,
                                hintStyle: TextStyle(
                                  fontSize: 13.5,
                                  color: isDark ? Colors.grey.shade500 : const Color(0xFF959595),
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                              ),
                            ),
                    ),

                    const SizedBox(width: 4),

                    // Kanan Dinamis: Mic Gelombang Suara vs Tombol Kirim Gradien
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      transitionBuilder: (child, anim) =>
                          ScaleTransition(scale: anim, child: child),
                      child: _hasText
                          ? InkWell(
                              key: const ValueKey('btn_submit'),
                              onTap: _handleSend,
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Color(0xFF9147FF), Color(0xFFFF4141)],
                                    begin: Alignment.bottomLeft,
                                    end: Alignment.topRight,
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0x409147FF),
                                      blurRadius: 6,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.arrow_upward_rounded,
                                  color: Colors.white,
                                  size: 19,
                                ),
                              ),
                            )
                          : InkWell(
                              key: const ValueKey('btn_voice'),
                              onTap: _toggleRecording,
                              borderRadius: BorderRadius.circular(20),
                              child: AnimatedBuilder(
                                animation: _waveAnimCtrl,
                                builder: (context, _) {
                                  return Container(
                                    width: 34,
                                    height: 34,
                                    alignment: Alignment.center,
                                    decoration: _isRecording
                                        ? BoxDecoration(
                                            color: GageTheme.primary.withValues(alpha: 0.15),
                                            shape: BoxShape.circle,
                                          )
                                        : null,
                                    child: CustomPaint(
                                      size: const Size(20, 20),
                                      painter: _VoiceWaveformPainter(
                                        color: _isRecording
                                            ? GageTheme.primary
                                            : (isDark ? Colors.white70 : const Color(0xFF959595)),
                                        pulseProgress: _isRecording ? _waveAnimCtrl.value : 0.0,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadIcon({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap?.call();
        },
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            size: 21,
            color: isDark ? Colors.white60 : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

/// CustomPainter untuk menggambar 5 bar gelombang suara:
/// d="M12 4v16m4-13v10M8 7v10m12-6v2M4 11v2"
/// Saat merekam (pulseProgress > 0), bar berdenyut dinamis layaknya visual soundwave aktif.
class _VoiceWaveformPainter extends CustomPainter {
  final Color color;
  final double pulseProgress;

  const _VoiceWaveformPainter({
    required this.color,
    this.pulseProgress = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Pulse modulation deltas
    final p1 = sin(pulseProgress * pi) * 2.0;
    final p2 = cos(pulseProgress * pi) * 3.5;
    final p3 = sin(pulseProgress * pi * 1.5) * 4.5;
    final p4 = cos(pulseProgress * pi * 1.2) * 3.5;
    final p5 = sin(pulseProgress * pi) * 2.0;

    // 5 Bar vertikal sesuai rasio SVG 24x24
    // Bar 1: x = 4 / 24, y = 11 to 13
    canvas.drawLine(
      Offset(w * (4 / 24), max(0, h * (11 / 24) - p1)),
      Offset(w * (4 / 24), min(h, h * (13 / 24) + p1)),
      paint,
    );
    // Bar 2: x = 8 / 24, y = 7 to 17
    canvas.drawLine(
      Offset(w * (8 / 24), max(0, h * (7 / 24) - p2)),
      Offset(w * (8 / 24), min(h, h * (17 / 24) + p2)),
      paint,
    );
    // Bar 3: x = 12 / 24, y = 4 to 20
    canvas.drawLine(
      Offset(w * (12 / 24), max(0, h * (4 / 24) - p3)),
      Offset(w * (12 / 24), min(h, h * (20 / 24) + p3)),
      paint,
    );
    // Bar 4: x = 16 / 24, y = 7 to 17
    canvas.drawLine(
      Offset(w * (16 / 24), max(0, h * (7 / 24) - p4)),
      Offset(w * (16 / 24), min(h, h * (17 / 24) + p4)),
      paint,
    );
    // Bar 5: x = 20 / 24, y = 11 to 13
    canvas.drawLine(
      Offset(w * (20 / 24), max(0, h * (11 / 24) - p5)),
      Offset(w * (20 / 24), min(h, h * (13 / 24) + p5)),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _VoiceWaveformPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pulseProgress != pulseProgress;
}
