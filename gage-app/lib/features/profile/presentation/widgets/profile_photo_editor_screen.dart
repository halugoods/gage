import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Screen editor foto profil interaktif (Crop, Zoom in/out, Pan, dan Rotate 90°).
/// Memproses gambar secara murni di Flutter tanpa native dependency tambahan.
class ProfilePhotoEditorScreen extends StatefulWidget {
  final File imageFile;

  const ProfilePhotoEditorScreen({
    super.key,
    required this.imageFile,
  });

  @override
  State<ProfilePhotoEditorScreen> createState() => _ProfilePhotoEditorScreenState();
}

class _ProfilePhotoEditorScreenState extends State<ProfilePhotoEditorScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  final TransformationController _transformationController = TransformationController();

  int _quarterTurns = 0;
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _rotate90() {
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
    });
  }

  void _zoom(double factor) {
    final matrix = _transformationController.value.clone();
    matrix.scaleByDouble(factor, factor, 1.0, 1.0);
    _transformationController.value = matrix;
  }

  void _reset() {
    setState(() {
      _quarterTurns = 0;
      _transformationController.value = Matrix4.identity();
    });
  }

  Future<void> _applyAndSave() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Render boundary tidak ditemukan.');
      }

      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 60));
      }

      // Render hasil crop ke gambar high-res (pixelRatio 2.5)
      final ui.Image image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal mengekspor data gambar.');
      }

      final pngBytes = byteData.buffer.asUint8List();
      final tempDir = Directory.systemTemp;
      final savedFile = File(
        '${tempDir.path}/gage_avatar_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await savedFile.writeAsBytes(pngBytes);

      if (mounted) {
        Navigator.pop(context, savedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        GageToast.show(
          context,
          'Gagal memproses foto: $e',
          type: GageToastType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0);
    final canvasBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

    final screenWidth = MediaQuery.of(context).size.width;
    final cropSize = math.min(screenWidth - 72, 300.0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, size: 24, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sesuaikan Foto',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
            color: textColor,
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: _reset,
            icon: Icon(Icons.refresh_rounded, size: 18, color: secondaryTextColor),
            label: Text(
              'Reset',
              style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Viewport Crop dengan Circle Mask & Visual Viewfinder Accents
            Center(
              child: SizedBox(
                width: cropSize,
                height: cropSize,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Lingkaran RepaintBoundary yang akan diekstrak sebagai foto avatar
                    RepaintBoundary(
                      key: _boundaryKey,
                      child: ClipOval(
                        child: Container(
                          width: cropSize,
                          height: cropSize,
                          color: canvasBg,
                          child: InteractiveViewer(
                            transformationController: _transformationController,
                            minScale: 0.6,
                            maxScale: 5.0,
                            boundaryMargin: EdgeInsets.all(cropSize * 0.9),
                            clipBehavior: Clip.none,
                            child: Center(
                              child: RotatedBox(
                                quarterTurns: _quarterTurns,
                                child: Image.file(
                                  widget.imageFile,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Guide border lingkaran
                    IgnorePointer(
                      child: Container(
                        width: cropSize,
                        height: cropSize,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? Colors.white.withValues(alpha: 0.9) : GageTheme.primary,
                            width: 2.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: GageTheme.primary.withValues(alpha: 0.20),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Viewfinder corner L-marks
                    IgnorePointer(
                      child: SizedBox(
                        width: cropSize + 22,
                        height: cropSize + 22,
                        child: CustomPaint(
                          painter: _ViewfinderCornerPainter(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            // Petunjuk interaksi gesture
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pinch_rounded, size: 15, color: secondaryTextColor),
                const SizedBox(width: 6),
                Text(
                  'Cubit untuk zoom • Seret untuk posisi terbaik',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Toolbar Controls (Zoom Out, Rotate 90, Zoom In)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildToolbarButton(
                        icon: Icons.zoom_out_rounded,
                        label: 'Perkecil',
                        isDark: isDark,
                        onTap: () => _zoom(0.85),
                      ),
                      const SizedBox(width: 14),
                      _buildToolbarButton(
                        icon: Icons.rotate_right_rounded,
                        label: 'Putar 90°',
                        isDark: isDark,
                        isPrimary: true,
                        onTap: _rotate90,
                      ),
                      const SizedBox(width: 14),
                      _buildToolbarButton(
                        icon: Icons.zoom_in_rounded,
                        label: 'Perbesar',
                        isDark: isDark,
                        onTap: () => _zoom(1.2),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tombol Terapkan Foto
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isProcessing ? null : _applyAndSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        disabledBackgroundColor: GageTheme.primary.withValues(alpha: 0.6),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Gunakan Foto Profil',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    final btnBg = isPrimary
        ? GageTheme.primary.withValues(alpha: isDark ? 0.22 : 0.10)
        : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFF1F5F9));
    final btnBorder = isPrimary
        ? GageTheme.primary
        : (isDark ? Colors.white.withValues(alpha: 0.14) : const Color(0xFFE2E8F0));
    final btnIconColor = isPrimary ? GageTheme.primary : (isDark ? Colors.white : const Color(0xFF334155));
    final btnTextColor = isPrimary ? (isDark ? Colors.white : GageTheme.primary) : (isDark ? Colors.white70 : const Color(0xFF334155));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: btnBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: btnBorder,
            width: isPrimary ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 19,
              color: btnIconColor,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isPrimary ? FontWeight.bold : FontWeight.w600,
                color: btnTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewfinderCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFEF4444) // GAGE red accent
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const cornerLength = 18.0;

    // Top-left
    canvas.drawLine(const Offset(0, 0), const Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(0, cornerLength), paint);

    // Top-right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom-left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom-right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
