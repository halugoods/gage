import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/gage_image_crop_rotate_dialog.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Production-Grade Photo Picker Sheet for GAGE Merchant Portal (Food, Shop, Farm).
/// Mengikuti standar arsitektur NUSA Kasir tanpa mockup sandbox:
/// - Ambil foto langsung dari Kamera Fisik HP
/// - Pilih dari Galeri HP
/// - Otomatis downscale (maxWidth 1024px) untuk mencegah crash memori/OOM
/// - Langsung membuka GageImageCropRotateDialog (1:1 square crop & rotate)
class MerchantPhotoPickerSheet extends StatelessWidget {
  const MerchantPhotoPickerSheet({super.key});

  /// Membuka bottom sheet sumber foto dan mengembalikan path file JPG hasil crop (1:1 atau 16:9)
  static Future<String?> show(
    BuildContext context, {
    String? initialCategory,
    double aspectRatio = 1.0,
  }) async {
    final source = await GageFloatingSheet.show<ImageSource>(
      context: context,
      title: 'Pilih Sumber Foto',
      builder: (_) => const MerchantPhotoPickerSheet(),
    );
    if (source == null || !context.mounted) return null;

    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !context.mounted) return null;

      final croppedPath = await GageImageCropRotateDialog.show(
        context,
        picked.path,
        aspectRatio: aspectRatio,
      );
      return croppedPath ?? picked.path;
    } catch (_) {
      return null;
    }
  }

  /// Helper untuk memotong ulang (re-crop / rotate) foto yang sudah ada
  static Future<String?> recrop(
    BuildContext context,
    String currentPath, {
    double aspectRatio = 1.0,
  }) {
    return GageImageCropRotateDialog.show(
      context,
      currentPath,
      aspectRatio: aspectRatio,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle Bar Kapsul
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.add_a_photo_rounded, size: 20, color: GageTheme.primary),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pilih Sumber Foto Produk',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              'Foto otomatis diatur dengan rasio 1:1 persegi resmi katalog',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: isDark ? Colors.white60 : Colors.grey.shade600, size: 20),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),

            const SizedBox(height: 18),

            // Opsi 1: Kamera HP Langsung
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(ImageSource.camera);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.camera_alt_rounded, color: GageTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ambil Foto Kamera',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Buka kamera perangkat untuk memotret produk langsung',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Opsi 2: Galeri HP
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                Navigator.of(context).pop(ImageSource.gallery);
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.25 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.photo_library_rounded, color: Color(0xFF10B981), size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pilih dari Galeri HP',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Pilih foto berkualitas yang tersimpan di memori perangkat',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
