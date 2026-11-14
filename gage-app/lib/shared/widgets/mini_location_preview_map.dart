import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
