import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';

class GFitMapView extends StatefulWidget {
  final LatLng center;
  final List<LatLng> recordedPoints;
  final Color accentColor;
  final double height;
  final bool isTracking;
  final bool isPaused;
  final bool isAutoPaused;
  final double? gpsAccuracyMeters;
  final String? userAvatarUrl;
  final String userName;
  final bool allowControls;
  final bool showHudPill;
  final bool autoFollow;
  final VoidCallback? onRequestRecenter;

  const GFitMapView({
    super.key,
    required this.center,
    this.recordedPoints = const [],
    this.accentColor = GageTheme.primary,
    this.height = 300,
    this.isTracking = false,
    this.isPaused = false,
    this.isAutoPaused = false,
    this.gpsAccuracyMeters,
    this.userAvatarUrl,
    this.userName = 'Anda',
    this.allowControls = true,
    this.showHudPill = true,
    this.autoFollow = true,
    this.onRequestRecenter,
  });

  @override
  State<GFitMapView> createState() => _GFitMapViewState();
}

class _GFitMapViewState extends State<GFitMapView> {
  final MapController _mapController = MapController();
  bool _isSatellite = false;
  bool _mapReady = false;

  LatLng get _activeHead {
    if (widget.recordedPoints.isNotEmpty) return widget.recordedPoints.last;
    return widget.center;
  }

  @override
  void didUpdateWidget(covariant GFitMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_mapReady) return;

    if (widget.isTracking &&
        widget.autoFollow &&
        widget.recordedPoints.isNotEmpty &&
        (oldWidget.recordedPoints.isEmpty ||
            widget.recordedPoints.last != oldWidget.recordedPoints.last)) {
      _safeMove(widget.recordedPoints.last, zoom: _mapController.camera.zoom);
    } else if (!widget.isTracking &&
        widget.center != oldWidget.center &&
        widget.recordedPoints.isEmpty) {
      _safeMove(widget.center, zoom: 16.5);
    }
  }

  void _safeMove(LatLng target, {double? zoom}) {
    if (!_mapReady) return;
    try {
      _mapController.move(target, zoom ?? _mapController.camera.zoom);
    } catch (_) {}
  }

  void _fitRoute() {
    if (!_mapReady) return;
    if (widget.recordedPoints.length < 2) {
      _safeMove(_activeHead, zoom: 16.5);
      return;
    }
    try {
      final bounds = LatLngBounds.fromPoints(widget.recordedPoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(42),
        ),
      );
    } catch (_) {
      _safeMove(_activeHead, zoom: 15.8);
    }
  }

  void _openFullscreen() {
    HapticFeedback.lightImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (ctx) => _GFitFullscreenMapDialog(widget: widget),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tileUrl = _isSatellite
        ? 'https://mt{s}.google.com/vt/lyrs=y&scale=2&hl=id&x={x}&y={y}&z={z}'
        : 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}';

    final startPoint =
        widget.recordedPoints.length >= 2 ? widget.recordedPoints.first : null;
    final currentPoint = _activeHead;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(23),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _activeHead,
                initialZoom: 16.5,
                minZoom: 11.0,
                maxZoom: 21.0,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
                onMapReady: () {
                  _mapReady = true;
                  if (widget.recordedPoints.length >= 2) {
                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (mounted) _fitRoute();
                    });
                  }
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: tileUrl,
                  subdomains: const ['0', '1', '2', '3'],
                  tileDimension: 256,
                  maxZoom: 21.0,
                  userAgentPackageName: 'com.gagepracimantoro.customer',
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),
                if (widget.recordedPoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: widget.recordedPoints,
                        strokeWidth: 8.5,
                        color: Colors.white,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                      Polyline(
                        points: widget.recordedPoints,
                        strokeWidth: 5.0,
                        color: widget.accentColor,
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                    ],
                  ),
                MarkerLayer(
                  markers: [
                    if (startPoint != null)
                      Marker(
                        point: startPoint,
                        width: 28,
                        height: 28,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2.5),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flag_rounded,
                            color: Colors.white,
                            size: 13,
                          ),
                        ),
                      ),
                    Marker(
                      point: currentPoint,
                      width: 48,
                      height: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: widget.accentColor.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: widget.accentColor,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: GageAvatar(
                              imageUrl: widget.userAvatarUrl,
                              fallbackName: widget.userName,
                              radius: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Top-left Real GPS Signal Pill
            if (widget.showHudPill)
              Positioned(
                top: 12,
                left: 12,
                right: widget.allowControls ? 64 : 12,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F172A).withValues(alpha: 0.92)
                          : Colors.white.withValues(alpha: 0.94),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: widget.isTracking
                                ? (widget.isPaused
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF16A34A))
                                : (widget.gpsAccuracyMeters != null
                                    ? const Color(0xFF16A34A)
                                    : widget.accentColor),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            _hudLabelText(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Top-right Google Maps Style Controls
            if (widget.allowControls)
              Positioned(
                top: 12,
                right: 12,
                child: Column(
                  children: [
                    _MapActionCircleButton(
                      icon: _isSatellite
                          ? Icons.map_rounded
                          : Icons.layers_rounded,
                      tooltip: _isSatellite ? 'Mode Peta' : 'Mode Satelit',
                      active: _isSatellite,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _isSatellite = !_isSatellite);
                      },
                    ),
                    if (widget.recordedPoints.length >= 2) ...[
                      const SizedBox(height: 8),
                      _MapActionCircleButton(
                        icon: Icons.zoom_out_map_rounded,
                        tooltip: 'Lihat Seluruh Jejak',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _fitRoute();
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    _MapActionCircleButton(
                      icon: Icons.my_location_rounded,
                      tooltip: 'Fokus ke Lokasi Saya',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _safeMove(_activeHead, zoom: 16.5);
                        widget.onRequestRecenter?.call();
                      },
                    ),
                    const SizedBox(height: 8),
                    _MapActionCircleButton(
                      icon: Icons.fullscreen_rounded,
                      tooltip: 'Perbesar Peta',
                      onTap: _openFullscreen,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _hudLabelText() {
    final acc = widget.gpsAccuracyMeters != null
        ? ' (±${widget.gpsAccuracyMeters!.round()} m)'
        : '';
    if (widget.isTracking) {
      if (widget.isAutoPaused) return 'AUTO-PAUSE • Menunggu gerakan';
      if (widget.isPaused) return 'DIJEDA';
      return 'GPS AKTIF$acc';
    }
    return widget.gpsAccuracyMeters != null
        ? 'GPS Siap$acc'
        : 'Lokasi Saat Ini';
  }
}

class _MapActionCircleButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  const _MapActionCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: active
          ? GageTheme.primary
          : (isDark ? const Color(0xFF1E293B) : Colors.white),
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            size: 18,
            color: active
                ? Colors.white
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ),
    );
  }
}

class _GFitFullscreenMapDialog extends StatelessWidget {
  final GFitMapView widget;

  const _GFitFullscreenMapDialog({required this.widget});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: GFitMapView(
              center: widget.center,
              recordedPoints: widget.recordedPoints,
              accentColor: widget.accentColor,
              height: MediaQuery.of(context).size.height,
              isTracking: widget.isTracking,
              isPaused: widget.isPaused,
              isAutoPaused: widget.isAutoPaused,
              gpsAccuracyMeters: widget.gpsAccuracyMeters,
              userAvatarUrl: widget.userAvatarUrl,
              userName: widget.userName,
              allowControls: false,
              showHudPill: true,
              autoFollow: false,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'gfit_close_fullscreen',
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0F172A),
              onPressed: () => Navigator.pop(context),
              child: const Icon(Icons.close_rounded),
            ),
          ),
        ],
      ),
    );
  }
}
