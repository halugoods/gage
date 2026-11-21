import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Standard location pin marker with a circular merchant profile photo centered inside its head.
class MerchantLocationPin extends StatelessWidget {
  final String? imagePath;
  final IconData fallbackIcon;
  final double size;

  const MerchantLocationPin({
    super.key,
    this.imagePath,
    this.fallbackIcon = Icons.storefront_rounded,
    this.size = 38.0,
  });

  @override
  Widget build(BuildContext context) {
    final pinSize = size * 1.26;
    final avatarSize = pinSize * 0.44;
    final topOffset = pinSize * 0.16;
    return SizedBox(
      width: pinSize,
      height: pinSize,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on_rounded,
            size: pinSize,
            color: GageTheme.primary,
            shadows: [
              Shadow(
                color: Colors.black.withValues(alpha: 0.30),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          Positioned(
            top: topOffset,
            child: Container(
              width: avatarSize,
              height: avatarSize,
              padding: const EdgeInsets.all(1.5),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Container(
                  color: Colors.white,
                  child: (imagePath != null && imagePath!.trim().isNotEmpty)
                      ? StorefrontImage(
                          path: imagePath,
                          fit: BoxFit.cover,
                          fallback: Icon(
                            fallbackIcon,
                            color: GageTheme.primary,
                            size: avatarSize * 0.56,
                          ),
                        )
                      : Icon(
                          fallbackIcon,
                          color: GageTheme.primary,
                          size: avatarSize * 0.56,
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Mini preview map widget for delivery addresses & merchant location cards.
/// Syncs camera center reactively whenever [location] updates.
class MiniLocationPreviewMap extends StatefulWidget {
  final LatLng location;
  final double size;
  final double? width;
  final double? height;
  final double borderRadius;
  final double zoom;
  final VoidCallback? onTap;
  final String? markerImagePath;
  final IconData markerFallbackIcon;
  final bool useMerchantPin;

  const MiniLocationPreviewMap({
    super.key,
    required this.location,
    this.size = 52.0,
    this.width,
    this.height,
    this.borderRadius = 14.0,
    this.zoom = 16.5,
    this.onTap,
    this.markerImagePath,
    this.markerFallbackIcon = Icons.location_on_rounded,
    this.useMerchantPin = false,
  });

  @override
  State<MiniLocationPreviewMap> createState() => _MiniLocationPreviewMapState();
}

class _MiniLocationPreviewMapState extends State<MiniLocationPreviewMap> {
  final MapController _mapController = MapController();
  bool _isMapReady = false;

  void _syncCamera() {
    if (!_isMapReady || !mounted) return;
    try {
      _mapController.move(widget.location, widget.zoom);
    } catch (_) {}
  }

  @override
  void didUpdateWidget(covariant MiniLocationPreviewMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.latitude != widget.location.latitude ||
        oldWidget.location.longitude != widget.location.longitude ||
        oldWidget.zoom != widget.zoom) {
      _syncCamera();
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Container(
        width: widget.width ?? widget.size,
        height: widget.height ?? widget.size,
        decoration: BoxDecoration(
          color: const Color(0xFFE5E7EB),
          borderRadius: BorderRadius.circular(widget.borderRadius),
          border: Border.all(
            color: GageTheme.primary.withValues(alpha: 0.25),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(widget.borderRadius - 1.2),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 0. Base Static Road Map Canvas (Always renders instantly, never gray)
              const Positioned.fill(
                child: CustomPaint(
                  painter: _StaticRoadMapPainter(),
                ),
              ),

              IgnorePointer(
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.location,
                    initialZoom: widget.zoom,
                    minZoom: 10.0,
                    maxZoom: 21.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.none,
                    ),
                    onMapReady: () {
                      _isMapReady = true;
                      _syncCamera();
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                      subdomains: const ['0', '1', '2', '3'],
                      tileDimension: 256,
                      maxZoom: 21.0,
                      userAgentPackageName: 'com.gagepracimantoro.customer',
                      fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                  ],
                ),
              ),
              Center(
                child: (widget.useMerchantPin ||
                        (widget.markerImagePath != null && widget.markerImagePath!.trim().isNotEmpty))
                    ? MerchantLocationPin(
                        imagePath: widget.markerImagePath,
                        fallbackIcon: widget.markerFallbackIcon,
                        size: 36,
                      )
                    : Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: GageTheme.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          widget.markerFallbackIcon,
                          color: Colors.white,
                          size: 14,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fallback / Base Static Road Map Painter
/// Menjamin pratinjau peta di kartu share / delivery selalu menampilkan layout peta visual yang riil
/// (jalan arteri, persimpangan, area hijau) secara instan tanpa menunggu unduhan network tiles.
class _StaticRoadMapPainter extends CustomPainter {
  const _StaticRoadMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base Land Color
    final landPaint = Paint()..color = const Color(0xFFF1EDE6);
    canvas.drawRect(Offset.zero & size, landPaint);

    // 2. Green Parks / Natural Spaces
    final greenPaint = Paint()..color = const Color(0xFFD6ECD7);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.05, size.height * 0.08, size.width * 0.35, size.height * 0.28),
        const Radius.circular(12),
      ),
      greenPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.62, size.height * 0.58, size.width * 0.32, size.height * 0.34),
        const Radius.circular(14),
      ),
      greenPaint,
    );

    // 3. Minor Roads (Grid lines)
    final minorRoadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.5
      ..style = PaintingStyle.stroke;

    final minorRoadBorder = Paint()
      ..color = const Color(0xFFE2E0D8)
      ..strokeWidth = 5.0
      ..style = PaintingStyle.stroke;

    // Horizontal minor roads
    for (double y = 0.22; y <= 0.85; y += 0.24) {
      final p1 = Offset(0, size.height * y);
      final p2 = Offset(size.width, size.height * y);
      canvas.drawLine(p1, p2, minorRoadBorder);
      canvas.drawLine(p1, p2, minorRoadPaint);
    }

    // Vertical minor roads
    for (double x = 0.28; x <= 0.78; x += 0.26) {
      final p1 = Offset(size.width * x, 0);
      final p2 = Offset(size.width * x, size.height);
      canvas.drawLine(p1, p2, minorRoadBorder);
      canvas.drawLine(p1, p2, minorRoadPaint);
    }

    // 4. Major Arterial Road (Jl. Raya Pracimantoro - Yellow / Orange Highlight)
    final majorBorder = Paint()
      ..color = const Color(0xFFD4B886)
      ..strokeWidth = 9.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final majorFill = Paint()
      ..color = const Color(0xFFFED7AA)
      ..strokeWidth = 7.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(0, size.height * 0.52)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.48,
        size.width * 0.65,
        size.height * 0.54,
        size.width,
        size.height * 0.49,
      );

    canvas.drawPath(path, majorBorder);
    canvas.drawPath(path, majorFill);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
