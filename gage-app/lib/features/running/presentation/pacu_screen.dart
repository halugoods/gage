import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar G-Fit: Layanan Lari, Olahraga & Tracking Kebugaran ala Strava
/// Dilengkapi Athletic Dark HUD, live polyline GPS rute OpenStreetMap Pracimantoro,
/// analisis split lap pace per KM, lintasan populer lokal, dan hadiah voucher G-Food.
class PacuScreen extends StatefulWidget {
  const PacuScreen({super.key});

  @override
  State<PacuScreen> createState() => _PacuScreenState();
}

class _PacuScreenState extends State<PacuScreen> {
  // Posisi default: Alun-alun / Pusat Pracimantoro
  final LatLng _defaultLocation = const LatLng(-8.0886, 110.8376);
  final MapController _mapController = MapController();

  int _selectedActivityIndex = 0; // 0: Lari, 1: Sepeda, 2: Jalan Kaki
  final List<String> _activityNames = ['Lari', 'Sepeda', 'Jalan Kaki'];
  final List<IconData> _activityIcons = [
    Icons.directions_run_rounded,
    Icons.directions_bike_rounded,
    Icons.directions_walk_rounded,
  ];

  // Preset Lintasan Populer Pracimantoro
  int _selectedRouteIndex = 0;
  final List<Map<String, dynamic>> _presetRoutes = [
    {
      'title': 'Loop Alun-Alun',
      'distance': 1.2,
      'elevation': '+12m',
      'points': [
        const LatLng(-8.0886, 110.8376),
        const LatLng(-8.0872, 110.8364),
        const LatLng(-8.0855, 110.8378),
        const LatLng(-8.0868, 110.8398),
        const LatLng(-8.0886, 110.8376),
      ],
    },
    {
      'title': 'Jalur Karst Suci',
      'distance': 3.5,
      'elevation': '+48m',
      'points': [
        const LatLng(-8.0886, 110.8376),
        const LatLng(-8.0920, 110.8350),
        const LatLng(-8.0965, 110.8320),
        const LatLng(-8.1010, 110.8290),
        const LatLng(-8.0965, 110.8320),
        const LatLng(-8.0920, 110.8350),
        const LatLng(-8.0886, 110.8376),
      ],
    },
    {
      'title': 'Tanjakan Lingkar',
      'distance': 5.0,
      'elevation': '+75m',
      'points': [
        const LatLng(-8.0886, 110.8376),
        const LatLng(-8.0840, 110.8350),
        const LatLng(-8.0790, 110.8380),
        const LatLng(-8.0820, 110.8430),
        const LatLng(-8.0870, 110.8420),
        const LatLng(-8.0886, 110.8376),
      ],
    },
  ];

  // Tracking state
  bool _isRunning = false;
  bool _isPaused = false;
  int _secondsElapsed = 0;
  double _distanceKm = 0.0;
  Timer? _timer;

  // Live GPS Route Coordinates
  List<LatLng> _liveRoute = [];
  int _routeStepIndex = 0;

  // Split Laps per KM
  final List<Map<String, dynamic>> _laps = [];
  int _lastCompletedKm = 0;

  // Gamifikasi Misi Lari Berhadiah Voucher G-Food & GAGE
  final List<Map<String, dynamic>> _missions = [
    {
      'id': 'misi_2km',
      'title': 'Misi Pemula 2 KM',
      'targetKm': 2.0,
      'reward': 'Voucher Diskon Rp 10.000 G-Food',
      'icon': Icons.fastfood_rounded,
      'claimed': false,
    },
    {
      'id': 'misi_5km',
      'title': 'Praci Runner 5 KM',
      'targetKm': 5.0,
      'reward': 'Gratis Ongkir Semua Layanan (G-Send/G-Food)',
      'icon': Icons.local_shipping_rounded,
      'claimed': false,
    },
    {
      'id': 'misi_10km',
      'title': 'Weekend Warrior 10 KM',
      'targetKm': 10.0,
      'reward': 'Saldo GAGE Pay Rp 15.000',
      'icon': Icons.account_balance_wallet_rounded,
      'claimed': false,
    },
  ];

  @override
  void initState() {
    super.initState();
    _resetRoute();
  }

  void _resetRoute() {
    final routePoints = _presetRoutes[_selectedRouteIndex]['points'] as List<LatLng>;
    _liveRoute = [routePoints.first];
    _routeStepIndex = 0;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTracking() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isRunning = true;
      _isPaused = false;
      if (_liveRoute.isEmpty) {
        _resetRoute();
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused && mounted) {
        setState(() {
          _secondsElapsed++;
          // Simulasi laju lari ~1 km per 5-6 menit
          _distanceKm += 0.0032;

          // Simulasi live route polyline progress
          final points = _presetRoutes[_selectedRouteIndex]['points'] as List<LatLng>;
          if (points.isNotEmpty && _secondsElapsed % 3 == 0) {
            _routeStepIndex = (_routeStepIndex + 1) % points.length;
            final nextPoint = points[_routeStepIndex];
            _liveRoute.add(nextPoint);
            _mapController.move(nextPoint, 16.0);
          }

          // Cek split laps per kilometer
          final currentKmFloor = _distanceKm.floor();
          if (currentKmFloor > _lastCompletedKm) {
            _lastCompletedKm = currentKmFloor;
            _laps.add({
              'km': _lastCompletedKm,
              'pace': _calculatePace(),
              'duration': _formatDuration(_secondsElapsed),
            });
            HapticFeedback.mediumImpact();
          }
        });
      }
    });

    GageToast.show(context, 'Aktivitas G-Fit dimulai. GPS terhubung!', type: GageToastType.success);
  }

  void _pauseTracking() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  void _stopTracking() {
    HapticFeedback.heavyImpact();
    _timer?.cancel();

    final earnedKm = _distanceKm;
    setState(() {
      _isRunning = false;
      _isPaused = false;
    });

    // Cek apakah ada misi yang tercapai
    int newClaimable = 0;
    for (var m in _missions) {
      if (earnedKm >= (m['targetKm'] as double) && !(m['claimed'] as bool)) {
        newClaimable++;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1E293B)
            : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 28),
            SizedBox(width: 10),
            Text('Latihan G-Fit Selesai!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Luar biasa! Kamu menyelesaikan latihan sejauh ${_distanceKm.toStringAsFixed(2)} KM dalam waktu ${_formatDuration(_secondsElapsed)} dengan rata-rata pace ${_calculatePace()}/KM.',
              style: const TextStyle(fontSize: 13.5),
            ),
            const SizedBox(height: 12),
            if (newClaimable > 0)
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.confirmation_number_rounded, color: GageTheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Kamu membuka $newClaimable reward voucher baru! Klaim sekarang di menu misi.',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _secondsElapsed = 0;
                _distanceKm = 0.0;
                _lastCompletedKm = 0;
                _laps.clear();
                _resetRoute();
              });
            },
            child: const Text('Simpan Aktivitas', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _calculatePace() {
    if (_distanceKm <= 0.05 || _secondsElapsed < 5) return "0'00\"";
    final paceSecondsPerKm = (_secondsElapsed / _distanceKm).round();
    final paceMin = paceSecondsPerKm ~/ 60;
    final paceSec = paceSecondsPerKm % 60;
    return "$paceMin'${paceSec.toString().padLeft(2, '0')}\"";
  }

  int _calculateCalories() {
    return (_distanceKm * 64).round();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palet Athletic Dark HUD
    final hudBackground = isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC);
    final cardSurface = isDark ? const Color(0xFF131A29) : Colors.white;
    final cardBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    const neonVolt = Color(0xFF22C55E);

    final activeRoutePoints = _presetRoutes[_selectedRouteIndex]['points'] as List<LatLng>;
    final currentRunnerPos = _liveRoute.isNotEmpty ? _liveRoute.last : _defaultLocation;

    return Scaffold(
      backgroundColor: hudBackground,
      appBar: AppBar(
        backgroundColor: cardSurface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GageTheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Row(
                children: [
                  Icon(Icons.directions_run_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 4),
                  Text(
                    'FIT',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'G-Fit Athletics',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.leaderboard_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
            tooltip: 'Papan Peringkat',
            onPressed: () {
              _showLeaderboardSheet(context, isDark);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Selector Mode Olahraga (Kapsul Penuh)
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: List.generate(_activityNames.length, (idx) {
                  final isSelected = _selectedActivityIndex == idx;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedActivityIndex = idx);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? GageTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _activityIcons[idx],
                              size: 16,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _activityNames[idx],
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 14),

            // 2. Preset Lintasan Populer Pracimantoro (Pills Kapsul Penuh)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(_presetRoutes.length, (index) {
                  final r = _presetRoutes[index];
                  final isSelected = _selectedRouteIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      onTap: () {
                        if (_isRunning) return;
                        HapticFeedback.selectionClick();
                        setState(() {
                          _selectedRouteIndex = index;
                          _resetRoute();
                        });
                        final pts = _presetRoutes[index]['points'] as List<LatLng>;
                        if (pts.isNotEmpty) {
                          _mapController.move(pts.first, 15.5);
                        }
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GageTheme.primary
                              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isSelected ? GageTheme.primary : cardBorder,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.alt_route_rounded,
                              size: 14,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${r['title']} (${r['distance']} KM)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${r['elevation']}',
                              style: TextStyle(
                                fontSize: 9.5,
                                color: isSelected
                                    ? Colors.white70
                                    : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 12),

            // 3. Interactive Map Live GPS Polyline Box
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: _defaultLocation,
                      initialZoom: 15.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.gagepracimantoro.customer',
                      ),
                      // Rute Garis Panduan (Planned Route)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: activeRoutePoints,
                            strokeWidth: 4.0,
                            color: Colors.blue.withValues(alpha: 0.35),
                          ),
                          // Live Tracked Path yang Terukir Secara Real-Time
                          if (_liveRoute.isNotEmpty)
                            Polyline(
                              points: _liveRoute,
                              strokeWidth: 5.0,
                              color: neonVolt,
                            ),
                        ],
                      ),
                      MarkerLayer(
                        markers: [
                          // Titik Start
                          if (activeRoutePoints.isNotEmpty)
                            Marker(
                              point: activeRoutePoints.first,
                              width: 28,
                              height: 28,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(Icons.flag_rounded, color: Colors.white, size: 14),
                              ),
                            ),
                          // Posisi Pelari Aktif
                          Marker(
                            point: currentRunnerPos,
                            width: 36,
                            height: 36,
                            child: Container(
                              decoration: BoxDecoration(
                                color: GageTheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2.5),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.directions_run_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // GPS Signal Tag
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.gps_fixed_rounded, color: neonVolt, size: 14),
                          SizedBox(width: 5),
                          Text(
                            'GPS Pracimantoro Aktif',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Tombol Center Map
                  Positioned(
                    bottom: 10,
                    right: 10,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _mapController.move(currentRunnerPos, 16.0);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: cardSurface,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 18,
                          color: isDark ? Colors.white : GageTheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4. Athletic Metrics HUD Card ala Strava
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardSurface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Durasi Waktu (Hero Metric)
                  Text(
                    _formatDuration(_secondsElapsed),
                    style: TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'WAKTU TEMPUH',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Divider(height: 1, color: cardBorder),
                  const SizedBox(height: 16),

                  // Tiga Metrik Baris Bawah: Jarak, Pace, Kalori
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMetricTile(
                        label: 'JARAK',
                        value: _distanceKm.toStringAsFixed(2),
                        unit: 'KM',
                        isDark: isDark,
                      ),
                      _buildMetricTile(
                        label: 'PACE',
                        value: _calculatePace(),
                        unit: '/KM',
                        isDark: isDark,
                        valueColor: neonVolt,
                      ),
                      _buildMetricTile(
                        label: 'KALORI',
                        value: '${_calculateCalories()}',
                        unit: 'KKAL',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 5. Split Pace Laps Card (KM 1, KM 2, dst)
            if (_laps.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: neonVolt),
                        SizedBox(width: 6),
                        Text(
                          'Split Pace Per Kilometer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ..._laps.map((lap) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'KM ${lap['km']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : const Color(0xFF334155),
                                ),
                              ),
                              Text(
                                '${lap['pace']} /km',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                  color: neonVolt,
                                ),
                              ),
                              Text(
                                '${lap['duration']}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 6. Tombol Utama Kontrol Lari
            if (!_isRunning) ...[
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    elevation: 3,
                  ),
                  onPressed: _startTracking,
                  icon: const Icon(Icons.play_arrow_rounded, size: 24),
                  label: const Text(
                    'Mulai Lari',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isPaused ? Colors.green : Colors.orange,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _pauseTracking,
                        icon: Icon(_isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded),
                        label: Text(_isPaused ? 'Lanjut' : 'Jeda', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                        ),
                        onPressed: _stopTracking,
                        icon: const Icon(Icons.stop_rounded),
                        label: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 24),

            // 7. Misi Lari Berhadiah Voucher Belanja G-Food & G-Send (Gamifikasi)
            Row(
              children: [
                const Icon(Icons.stars_rounded, color: GageTheme.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  'Misi Olahraga & Hadiah Voucher',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Capai jarak tempuh untuk membuka voucher diskon kuliner G-Food dan subsidi ongkir!',
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),

            ..._missions.map((misi) {
              final isUnlocked = _distanceKm >= (misi['targetKm'] as double);
              final isClaimed = misi['claimed'] as bool;
              final progress = (_distanceKm / (misi['targetKm'] as double)).clamp(0.0, 1.0);

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked
                        ? GageTheme.primary.withValues(alpha: 0.4)
                        : cardBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isUnlocked
                                ? GageTheme.primary.withValues(alpha: 0.15)
                                : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            misi['icon'] as IconData,
                            color: isUnlocked ? GageTheme.primary : Colors.grey,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                misi['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                misi['reward'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isClaimed)
                          const Text('Diklaim', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 11.5))
                        else
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isUnlocked ? GageTheme.primary : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                              foregroundColor: isUnlocked ? Colors.white : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                              elevation: 0,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            ),
                            onPressed: isUnlocked
                                ? () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      misi['claimed'] = true;
                                    });
                                    GageToast.show(context, 'Berhasil mengklaim: ${misi['reward']}', type: GageToastType.success);
                                  }
                                : null,
                            child: const Text('Klaim', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                        valueColor: const AlwaysStoppedAnimation<Color>(GageTheme.primary),
                        minHeight: 5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_distanceKm.toStringAsFixed(2)} / ${misi['targetKm']} KM',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required bool isDark,
    Color? valueColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
            const SizedBox(width: 3),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: GageTheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  void _showLeaderboardSheet(BuildContext context, bool isDark) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: GageTheme.primary),
                SizedBox(width: 8),
                Text('Papan Peringkat Pelari Praci', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Peringkat jarak tempuh minggu ini di kawasan Pracimantoro',
              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            _buildLeaderboardRow('#1', 'Bayu Praci Runner', '42.5 KM', isDark, isTop: true),
            _buildLeaderboardRow('#2', 'Siti Running Club', '31.2 KM', isDark, isTop: true),
            _buildLeaderboardRow('#3', 'Rian Pace 5', '28.0 KM', isDark, isTop: true),
            _buildLeaderboardRow('#4', 'Kamu', '${_distanceKm.toStringAsFixed(1)} KM', isDark, isSelf: true),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardRow(String rank, String name, String dist, bool isDark, {bool isTop = false, bool isSelf = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelf
            ? GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.1)
            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelf ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        ),
      ),
      child: Row(
        children: [
          Text(rank, style: TextStyle(fontWeight: FontWeight.w900, color: isTop ? Colors.amber : (isDark ? Colors.white : const Color(0xFF0F172A)))),
          const SizedBox(width: 14),
          Expanded(child: Text(name, style: TextStyle(fontWeight: isSelf ? FontWeight.w900 : FontWeight.w600))),
          Text(dist, style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
        ],
      ),
    );
  }
}
