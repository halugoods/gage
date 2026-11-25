import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/running/services/gfit_service.dart';
import 'package:gage_app/features/running/widgets/gfit_map_view.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class GFitShareSheet extends StatefulWidget {
  final GFitWorkoutSession session;
  final String? userAvatarUrl;
  final String userName;
  final bool isJustFinished;
  final VoidCallback? onDelete;

  const GFitShareSheet({
    super.key,
    required this.session,
    this.userAvatarUrl,
    this.userName = 'Sobat GAGE',
    this.isJustFinished = false,
    this.onDelete,
  });

  static Future<void> show(
    BuildContext context, {
    required GFitWorkoutSession session,
    String? userAvatarUrl,
    String userName = 'Sobat GAGE',
    bool isJustFinished = false,
    VoidCallback? onDelete,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => GFitShareSheet(
        session: session,
        userAvatarUrl: userAvatarUrl,
        userName: userName,
        isJustFinished: isJustFinished,
        onDelete: onDelete,
      ),
    );
  }

  @override
  State<GFitShareSheet> createState() => _GFitShareSheetState();
}

class _GFitShareSheetState extends State<GFitShareSheet> {
  final GlobalKey _posterKey = GlobalKey();
  bool _isSharing = false;

  Future<void> _shareAchievementCard() async {
    if (_isSharing) return;
    setState(() => _isSharing = true);
    HapticFeedback.lightImpact();

    try {
      final boundary =
          _posterKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) {
        throw Exception('Poster visual belum siap');
      }
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Gagal memproses gambar PNG');
      }
      final bytes = byteData.buffer.asUint8List();
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/gfit_workout_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      final s = widget.session;
      final text =
          'Baru saja menuntaskan ${s.activityType.fullName} ${s.distanceKm.toStringAsFixed(2)} km '
          'dalam ${s.formattedDuration} (Pace ${s.formattedPace}/km, ${s.calories} kcal) '
          'di G-Fit GAGE!';

      if (!mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: text,
        ),
      );
    } catch (e) {
      if (mounted) {
        GageToast.show(context, 'Gagal membagikan sesi: $e', type: GageToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = widget.session;
    final center = s.routePoints.isNotEmpty
        ? s.routePoints.last
        : LocationService.defaultLocation;
    final dateStr = DateFormat('d MMM yyyy • HH:mm').format(s.startedAt);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.isJustFinished
                            ? 'Latihan Selesai!'
                            : s.sessionTitle,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateStr,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (widget.onDelete != null && !widget.isJustFinished)
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: GageTheme.primary),
                    tooltip: 'Hapus riwayat',
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onDelete?.call();
                    },
                  ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (s.routePoints.length >= 2) ...[
                    GFitMapView(
                      center: center,
                      recordedPoints: s.routePoints,
                      accentColor: s.activityType.accentColor,
                      height: 210,
                      isTracking: false,
                      userAvatarUrl: widget.userAvatarUrl,
                      userName: widget.userName,
                      allowControls: true,
                      showHudPill: false,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Achievement Poster Captured as PNG on Share
                  RepaintBoundary(
                    key: _posterKey,
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: s.activityType.accentColor.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  'G-FIT • ${s.activityType.label.toUpperCase()}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Text(
                                'PRACIMANTORO',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.9,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          s.distanceKm.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 40,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        const Text(
                                          'KM',
                                          style: TextStyle(
                                            color: Color(0xFFE52320),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '${widget.userName} • ${s.pointsEarned > 0 ? "+${s.pointsEarned} Poin GAGE" : "Sesi Tercatat"}',
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (s.routePoints.length >= 2)
                                SizedBox(
                                  width: 82,
                                  height: 64,
                                  child: CustomPaint(
                                    painter: _RouteSilhouettePainter(
                                      points: s.routePoints,
                                      color: s.activityType.accentColor,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _PosterMetric('DURASI', s.formattedDuration),
                                _PosterMetric('AVG PACE', '${s.formattedPace}/km'),
                                _PosterMetric('KALORI', '${s.calories} kcal'),
                                _PosterMetric(
                                  'ELEVASI',
                                  '+${s.elevationGainM.round()} m',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (s.splitLaps.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Split Pace Per Kilometer',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? GageTheme.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        children: s.splitLaps.map((lap) {
                          final isLast = lap.kmIndex == s.splitLaps.last.kmIndex;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: isLast
                                  ? null
                                  : Border(
                                      bottom: BorderSide(
                                        color: isDark
                                            ? GageTheme.darkBorder
                                            : const Color(0xFFF1F5F9),
                                      ),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 9,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: s.activityType.accentColor
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'KM ${lap.kmIndex}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: s.activityType.accentColor,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${lap.formattedSplitPace}/km',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Text(
                                  GFitService.formatDuration(lap.elapsedSeconds),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.white60
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            side: BorderSide(
                              color: isDark
                                  ? GageTheme.darkBorder
                                  : const Color(0xFFCBD5E1),
                            ),
                            foregroundColor:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Tutup',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            elevation: 0,
                          ),
                          onPressed: _isSharing ? null : _shareAchievementCard,
                          icon: _isSharing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.share_rounded, size: 18),
                          label: Text(
                            _isSharing ? 'Menyiapkan...' : 'Bagikan Pencapaian',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PosterMetric extends StatelessWidget {
  final String label;
  final String value;

  const _PosterMetric(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _RouteSilhouettePainter extends CustomPainter {
  final List<LatLng> points;
  final Color color;

  _RouteSilhouettePainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;
    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }
    final latSpan = (maxLat - minLat).abs().clamp(0.0002, 10.0);
    final lngSpan = (maxLng - minLng).abs().clamp(0.0002, 10.0);

    final path = ui.Path();
    const pad = 6.0;
    final drawW = size.width - pad * 2;
    final drawH = size.height - pad * 2;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final nx = (p.longitude - minLng) / lngSpan;
      final ny = 1.0 - ((p.latitude - minLat) / latSpan);
      final x = pad + nx * drawW;
      final y = pad + ny * drawH;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _RouteSilhouettePainter oldDelegate) =>
      oldDelegate.points != points || oldDelegate.color != color;
}
