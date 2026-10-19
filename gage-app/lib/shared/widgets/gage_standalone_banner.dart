import 'package:flutter/material.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';
import 'package:gage_app/features/admin/presentation/widgets/in_place_banner_editor_sheet.dart';

/// Widget Standalone Banner Per-Layar untuk Ekosistem GAGE
/// Terkoneksi langsung ke Cloudflare Edge Cache & D1 melalui [BannerManagerService].
/// Dijamin berdiri sendiri (standalone) tanpa ada duplikasi banner antar-layar.
class GageStandaloneBanner extends StatelessWidget {
  final String screenTarget;
  final double? aspectRatio;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final VoidCallback? onTap;

  const GageStandaloneBanner({
    super.key,
    required this.screenTarget,
    this.aspectRatio,
    this.margin,
    this.borderRadius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: BannerManagerService.instance,
      builder: (context, _) {
        final banner = BannerManagerService.instance.getBanner(screenTarget);

        if (!banner.isActive) {
          return const SizedBox.shrink();
        }

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final editScope = LiveAppEditScope.of(context);
        final isEditMode = editScope != null && editScope.isEditMode;
        final radius = borderRadius ?? BorderRadius.circular(16);
        final isCompact = screenTarget.contains('driver') || screenTarget.contains('merchant');
        final ratio = aspectRatio ?? (isCompact ? (3.0 / 1.0) : (16.0 / 9.0));

        final content = Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: AspectRatio(
          aspectRatio: ratio,
          child: Stack(
                fit: StackFit.expand,
                children: [
                  // Gambar Banner (Remote URL atau Local Asset)
                  _buildImage(banner.imagePath),

                  // Gradient Scrim untuk Keterbacaan Teks
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.65),
                          Colors.black.withValues(alpha: 0.20),
                          Colors.transparent,
                        ],
                        begin: Alignment.bottomLeft,
                        end: Alignment.topRight,
                      ),
                    ),
                  ),

                  // Teks & Badge Konten
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (banner.badge.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: GageTheme.primary,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              banner.badge.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),
                        if (banner.title.isNotEmpty)
                          Text(
                            banner.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                        if (banner.subtitle.isNotEmpty)
                          Text(
                            banner.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 11,
                              shadows: const [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Edit Badge Indicator (Khusus saat dijalankan di Live App Sandbox Admin)
                  if (isEditMode)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: GageTheme.primary, width: 1.2),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_rounded, size: 10, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'Edit Banner',
                              style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        final effectiveOnTap = isEditMode
            ? () {
                InPlaceBannerEditorSheet.showConfirmationAndOpen(
                  context: context,
                  screenTarget: screenTarget,
                  bannerId: null,
                  title: banner.title,
                  subtitle: banner.subtitle,
                  badge: banner.badge,
                  imageUrl: banner.imagePath,
                  actionUrl: banner.ctaText,
                  aspectRatio: ratio,
                );
              }
            : onTap;

        if (effectiveOnTap != null) {
          return Padding(
            padding: margin ?? EdgeInsets.zero,
            child: GageTapScale(
              onTap: effectiveOnTap,
              scaleDown: 0.98,
              child: content,
            ),
          );
        }

        return Padding(
          padding: margin ?? EdgeInsets.zero,
          child: content,
        );
      },
    );
  }

  Widget _buildImage(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (ctx, err, stack) => _buildFallback(),
      );
    }

    if (path.startsWith('assets/')) {
      return Image.asset(
        path,
        fit: BoxFit.cover,
        alignment: Alignment.center,
        errorBuilder: (ctx, err, stack) => _buildFallback(),
      );
    }

    return _buildFallback();
  }

  Widget _buildFallback() {
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Colors.white24, size: 28),
      ),
    );
  }
}
