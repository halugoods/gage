import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Dialog interaktif pemotong dan pemutar foto produk (1:1 Square Aspect Ratio)
/// Menggunakan pure Flutter canvas/RepaintBoundary: bebas dependensi native,
/// anti-crash/OOM, mendukung pan, zoom, dan rotasi 90 derajat berkelanjutan.
class GageImageCropRotateDialog extends StatefulWidget {
  final String imagePath;

  const GageImageCropRotateDialog({
    super.key,
    required this.imagePath,
  });

  /// Membuka dialog pemotong foto 1:1 dan mengembalikan path file JPG hasil crop
  static Future<String?> show(BuildContext context, String imagePath) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => GageImageCropRotateDialog(imagePath: imagePath),
    );
  }

  @override
  State<GageImageCropRotateDialog> createState() => _GageImageCropRotateDialogState();
}

class _GageImageCropRotateDialogState extends State<GageImageCropRotateDialog> {
  final GlobalKey _cropKey = GlobalKey();
  final TransformationController _transformController = TransformationController();
  int _quarterTurns = 0; // 0, 1, 2, 3 (setiap klik memutar 90 derajat searah jarum jam)
  bool _isProcessing = false;

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _rotateClockwise() {
    HapticFeedback.selectionClick();
    setState(() {
      _quarterTurns = (_quarterTurns + 1) % 4;
      _transformController.value = Matrix4.identity();
    });
  }

  void _resetTransform() {
    HapticFeedback.lightImpact();
    setState(() {
      _quarterTurns = 0;
      _transformController.value = Matrix4.identity();
    });
  }

  Future<void> _applyCropAndSave() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    HapticFeedback.mediumImpact();

    try {
      final boundary = _cropKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      // Render RepaintBoundary ke bitmap 1:1 berkualitas tinggi (target ~800-1024px)
      final image = await boundary.toImage(pixelRatio: 2.5);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        if (mounted) Navigator.of(context).pop(widget.imagePath);
        return;
      }

      final bytes = byteData.buffer.asUint8List();
      final dir = await getApplicationDocumentsDirectory();
      final destPath = '${dir.path}/crop_prod_${DateTime.now().millisecondsSinceEpoch}.png';

      final file = File(destPath);
      await file.writeAsBytes(bytes, flush: true);

      if (mounted) {
        Navigator.of(context).pop(destPath);
      }
    } catch (_) {
      if (mounted) {
        Navigator.of(context).pop(widget.imagePath);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;
    final boxSize = math.min(screenSize.width - 48, 320.0);

    return PopScope(
      canPop: !_isProcessing,
      child: Dialog(
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Dialog
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.crop_rotate_rounded, size: 20, color: GageTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Sesuaikan Foto (1:1)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
                    icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    tooltip: 'Batal',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Geser dan cubit layar untuk menyesuaikan posisi. Foto dipotong rasio 1:1 persegi resmi produk.',
                style: TextStyle(
                  fontSize: 11.5,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),

              // Area Crop Interaktif (Square Box 1:1)
              Center(
                child: Container(
                  width: boxSize,
                  height: boxSize,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: GageTheme.primary,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: RepaintBoundary(
                      key: _cropKey,
                      child: Container(
                        color: Colors.black,
                        child: InteractiveViewer(
                          transformationController: _transformController,
                          minScale: 0.8,
                          maxScale: 4.0,
                          panEnabled: true,
                          scaleEnabled: true,
                          child: RotatedBox(
                            quarterTurns: _quarterTurns,
                            child: widget.imagePath.startsWith('assets/')
                                ? Image.asset(
                                    widget.imagePath,
                                    fit: BoxFit.cover,
                                    width: boxSize,
                                    height: boxSize,
                                  )
                                : Image.file(
                                    File(widget.imagePath),
                                    fit: BoxFit.cover,
                                    width: boxSize,
                                    height: boxSize,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Baris Kontrol Alat (Rotate 90 & Reset)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                    ),
                    onPressed: _isProcessing ? null : _rotateClockwise,
                    icon: const Icon(Icons.rotate_right_rounded, size: 18, color: GageTheme.primary),
                    label: Text(
                      'Putar 90° (${_quarterTurns * 90}°)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onPressed: _isProcessing ? null : _resetTransform,
                    icon: Icon(Icons.refresh_rounded, size: 16, color: isDark ? Colors.white70 : Colors.grey.shade600),
                    label: Text(
                      'Reset',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Tombol Konfirmasi & Batal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
                      ),
                      onPressed: _isProcessing ? null : () => Navigator.of(context).pop(null),
                      child: Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: _isProcessing ? null : _applyCropAndSave,
                      child: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Gunakan Foto 1:1',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
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
