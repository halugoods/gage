import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/running/services/gfit_service.dart';
import 'package:gage_app/features/running/widgets/gfit_map_view.dart';
import 'package:gage_app/features/running/widgets/gfit_share_sheet.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/horizontal_ruler_picker.dart';

class PacuScreen extends StatefulWidget {
  const PacuScreen({super.key});

  @override
  State<PacuScreen> createState() => _PacuScreenState();
}

class _PacuScreenState extends State<PacuScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _mainTabs = const ['Mulai', 'Riwayat', 'Misi'];

  // User Profile & Preferences State
  List<GFitWorkoutSession> _sessions = [];
  double _weeklyTargetKm = 10.0;
  double _weightKg = 62.0;
  bool _autoPauseEnabled = true;
  bool _voiceCueEnabled = true;
  Set<String> _claimedMissionIds = <String>{};
  Set<String> _unlockedVouchers = <String>{};
  int _dailyPointsUsed = 0;

  // Tracking State (Real GPS Only)
  GFitActivityType _activityType = GFitActivityType.run;
  LatLng _currentCenter = LocationService.cachedOrFallback;
  double? _gpsAccuracyMeters;
  bool _isTracking = false;
  bool _isPaused = false;
  bool _isAutoPaused = false;
  DateTime? _workoutStartedAt;
  int _elapsedSeconds = 0;
  double _distanceKm = 0.0;
  int _calories = 0;
  double _elevationGainM = 0.0;
  double _currentSpeedKmh = 0.0;
  final List<LatLng> _recordedPoints = [];
  final List<GFitSplitLap> _splitLaps = [];
  int _nextSplitKm = 1;
  int _lastSplitElapsedSec = 0;
  int _lastSampleElapsedSec = 0;
  int _stillSeconds = 0;
  double? _lastAltitude;

  GFitActivityType? _historyFilter;

  Timer? _stopwatchTimer;
  StreamSubscription<Position>? _positionSub;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _mainTabs.length, vsync: this);
    _initScreen();
  }

  @override
  void dispose() {
    _stopwatchTimer?.cancel();
    _positionSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  String? _currentUserId() {
    try {
      return context.read<AuthProvider>().currentUser?.id;
    } catch (_) {
      return null;
    }
  }

  String _currentUserName() {
    try {
      final n = context.read<AuthProvider>().currentUser?.name;
      if (n != null && n.trim().isNotEmpty) return n.trim();
    } catch (_) {}
    return 'Sobat GAGE';
  }

  String? _currentUserAvatar() {
    try {
      return context.read<AuthProvider>().currentUser?.avatarUrl;
    } catch (_) {}
    return null;
  }

  Future<void> _initScreen() async {
    final uid = _currentUserId();
    final state = await GFitService.loadUserState(userId: uid);
    if (!mounted) return;
    setState(() {
      _sessions = state.sessions;
      _weeklyTargetKm = state.weeklyTargetKm;
      _weightKg = state.weightKg;
      _autoPauseEnabled = state.autoPauseEnabled;
      _voiceCueEnabled = state.voiceCueEnabled;
      _claimedMissionIds = state.claimedMissionIds;
      _unlockedVouchers = state.unlockedVoucherCodes;
      _dailyPointsUsed = state.dailyPointsUsed;
    });

    await _refreshCurrentLocation(forceFresh: false);
  }

  Future<void> _refreshCurrentLocation({bool forceFresh = false}) async {
    try {
      final pos = await LocationService.getCurrentLocation(forceFresh: forceFresh);
      if (mounted && !_isTracking) {
        setState(() => _currentCenter = pos);
      }
    } catch (_) {}
  }

  Future<void> _startWorkout() async {
    if (_isTracking) return;
    HapticFeedback.mediumImpact();

    final ready = await _ensureGpsReady();
    if (!ready) return;

    _resetLiveBuffers();

    setState(() {
      _isTracking = true;
      _isPaused = false;
      _isAutoPaused = false;
      _workoutStartedAt = DateTime.now();
    });

    await _startGpsStream();

    _stopwatchTimer?.cancel();
    _stopwatchTimer = Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  Future<bool> _ensureGpsReady() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return false;
        await _showGpsRequirementDialog(
          title: 'GPS Belum Aktif',
          message:
              'Aktifkan layanan lokasi (GPS) di perangkat Anda untuk merekam jarak, kecepatan, dan jejak rute secara akurat.',
          openSettingsAction: Geolocator.openLocationSettings,
        );
        return false;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        if (!mounted) return false;
        await _showGpsRequirementDialog(
          title: 'Izin Lokasi Diperlukan',
          message:
              'Berikan izin akses lokasi agar G-Fit dapat menghitung jarak nyata dan mencatat rute olahraga Anda.',
          openSettingsAction: Geolocator.openAppSettings,
        );
        return false;
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      await _showGpsRequirementDialog(
        title: 'Sensor GPS Tidak Tersedia',
        message:
            'Perangkat tidak merespons sensor lokasi. Pastikan GPS aktif dan coba kembali di area terbuka.',
      );
      return false;
    }
  }

  Future<void> _showGpsRequirementDialog({
    required String title,
    required String message,
    Future<bool> Function()? openSettingsAction,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        content: Text(message, style: const TextStyle(fontSize: 13.5, height: 1.45)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
          if (openSettingsAction != null)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                await openSettingsAction();
              },
              child: const Text('Buka Pengaturan GPS'),
            ),
        ],
      ),
    );
  }

  void _resetLiveBuffers() {
    _elapsedSeconds = 0;
    _distanceKm = 0.0;
    _calories = 0;
    _elevationGainM = 0.0;
    _currentSpeedKmh = 0.0;
    _recordedPoints.clear();
    _splitLaps.clear();
    _nextSplitKm = 1;
    _lastSplitElapsedSec = 0;
    _lastSampleElapsedSec = 0;
    _stillSeconds = 0;
    _lastAltitude = null;
    _gpsAccuracyMeters = null;
  }

  Future<void> _startGpsStream() async {
    try {
      final initial = await LocationService.getCurrentLocation(forceFresh: true);
      if (mounted && _isTracking) {
        setState(() {
          _currentCenter = initial;
          if (_recordedPoints.isEmpty) {
            _recordedPoints.add(initial);
          }
        });
      }
    } catch (_) {}

    _positionSub?.cancel();
    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 4,
      ),
    ).listen(
      _onGpsPosition,
      onError: (_) {},
    );
  }

  void _onGpsPosition(Position pos) {
    if (!_isTracking || !mounted) return;
    setState(() {
      _gpsAccuracyMeters = pos.accuracy;
    });

    final speedMps = pos.speed > 0 ? pos.speed : 0.0;
    final speedKmh = speedMps * 3.6;

    if (_isPaused && _isAutoPaused && _autoPauseEnabled && speedKmh >= 1.2) {
      setState(() {
        _isPaused = false;
        _isAutoPaused = false;
        _stillSeconds = 0;
      });
      GageToast.show(context, 'Gerakan terdeteksi, sesi dilanjutkan.', type: GageToastType.info);
    }

    if (_isPaused) return;

    final lastPt = _recordedPoints.isNotEmpty ? _recordedPoints.last : null;
    final deltaSec = math.max(1, _elapsedSeconds - _lastSampleElapsedSec);
    if (!GFitService.shouldAcceptGpsSample(
      candidate: pos,
      lastPoint: lastPt,
      elapsedDeltaSec: deltaSec,
    )) {
      return;
    }

    final nextPt = LatLng(pos.latitude, pos.longitude);
    var addedKm = 0.0;
    if (lastPt != null) {
      final distM = Geolocator.distanceBetween(
        lastPt.latitude,
        lastPt.longitude,
        nextPt.latitude,
        nextPt.longitude,
      );
      addedKm = distM / 1000.0;
    }

    var gainM = 0.0;
    if (pos.altitude != 0.0) {
      if (_lastAltitude != null) {
        final diff = pos.altitude - _lastAltitude!;
        if (diff > 0.5 && diff < 25.0) {
          gainM = diff;
        }
      }
      _lastAltitude = pos.altitude;
    }

    _applyMovementDelta(
      nextPoint: nextPt,
      addedKm: addedKm,
      gainM: gainM,
      speedKmh: speedKmh > 0.2 ? speedKmh : (addedKm / (deltaSec / 3600.0)),
    );
  }

  void _onTick(Timer timer) {
    if (!mounted || !_isTracking || _isPaused) return;

    setState(() {
      _elapsedSeconds += 1;
      _calories = GFitService.computeCalories(
        type: _activityType,
        weightKg: _weightKg,
        distanceKm: _distanceKm,
        durationSeconds: _elapsedSeconds,
        speedKmh: _currentSpeedKmh,
      );

      final timeSinceMove = _elapsedSeconds - _lastSampleElapsedSec;
      if (_autoPauseEnabled && timeSinceMove >= 10 && _currentSpeedKmh < 0.8) {
        _stillSeconds += 1;
        if (_stillSeconds >= 10) {
          _isPaused = true;
          _isAutoPaused = true;
        }
      }
    });
  }

  void _applyMovementDelta({
    required LatLng nextPoint,
    required double addedKm,
    required double gainM,
    required double speedKmh,
  }) {
    setState(() {
      _distanceKm += addedKm;
      _elevationGainM += gainM;
      _currentSpeedKmh = speedKmh;
      _currentCenter = nextPoint;
      _recordedPoints.add(nextPoint);
      _lastSampleElapsedSec = _elapsedSeconds;
      _stillSeconds = 0;
      _calories = GFitService.computeCalories(
        type: _activityType,
        weightKg: _weightKg,
        distanceKm: _distanceKm,
        durationSeconds: _elapsedSeconds,
        speedKmh: _currentSpeedKmh,
      );

      while (_distanceKm >= _nextSplitKm.toDouble()) {
        final splitSec = math.max(1, _elapsedSeconds - _lastSplitElapsedSec);
        final lap = GFitSplitLap(
          kmIndex: _nextSplitKm,
          splitSeconds: splitSec,
          elapsedSeconds: _elapsedSeconds,
        );
        _splitLaps.add(lap);
        _lastSplitElapsedSec = _elapsedSeconds;
        _nextSplitKm += 1;

        if (_voiceCueEnabled) {
          GageAudioService.instance.playOrderIncomingChime();
          GageToast.show(
            context,
            'Checkpoint KM ${lap.kmIndex} • Pace ${lap.formattedSplitPace}/km',
            type: GageToastType.success,
          );
        }
      }
    });
  }

  void _togglePause() {
    HapticFeedback.selectionClick();
    setState(() {
      _isPaused = !_isPaused;
      _isAutoPaused = false;
      _stillSeconds = 0;
    });
  }

  Future<void> _confirmAndFinishWorkout() async {
    HapticFeedback.mediumImpact();
    if (_distanceKm < 0.05) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Jarak Terlalu Pendek',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Sesi di bawah 50 meter (0.05 km) belum memenuhi syarat simpan riwayat & poin. Hentikan sesi sekarang?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Lanjutkan Latihan'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hentikan Sesi'),
            ),
          ],
        ),
      );
      if (discard == true) {
        _stopTrackingCompletely();
      }
      return;
    }

    final pointsEarned = GFitService.calculateEarnedPoints(
      type: _activityType,
      distanceKm: _distanceKm,
      alreadyEarnedToday: _dailyPointsUsed,
    );

    final session = GFitWorkoutSession(
      id: 'gfit-${DateTime.now().millisecondsSinceEpoch}',
      activityType: _activityType,
      startedAt: _workoutStartedAt ?? DateTime.now(),
      durationSeconds: math.max(1, _elapsedSeconds),
      distanceKm: double.parse(_distanceKm.toStringAsFixed(2)),
      calories: math.max(1, _calories),
      elevationGainM: double.parse(_elevationGainM.toStringAsFixed(1)),
      pointsEarned: pointsEarned,
      routePoints: List<LatLng>.from(_recordedPoints),
      splitLaps: List<GFitSplitLap>.from(_splitLaps),
    );

    _stopTrackingCompletely();

    final uid = _currentUserId();
    final updated = [session, ..._sessions];
    await GFitService.saveSessions(updated, userId: uid);

    var nextDaily = _dailyPointsUsed;
    if (pointsEarned > 0) {
      nextDaily = await GFitService.recordDailyPointsEarned(
        pointsEarned,
        userId: uid,
      );
      _creditWalletPoints(
        points: pointsEarned,
        title:
            'G-Fit ${session.activityType.label} (${session.distanceKm.toStringAsFixed(2)} km)',
      );
    }

    if (!mounted) return;
    setState(() {
      _sessions = updated;
      _dailyPointsUsed = nextDaily;
    });

    await GFitShareSheet.show(
      context,
      session: session,
      userAvatarUrl: _currentUserAvatar(),
      userName: _currentUserName(),
      isJustFinished: true,
    );
  }

  void _stopTrackingCompletely() {
    _stopwatchTimer?.cancel();
    _stopwatchTimer = null;
    _positionSub?.cancel();
    _positionSub = null;
    setState(() {
      _isTracking = false;
      _isPaused = false;
      _isAutoPaused = false;
    });
  }

  void _creditWalletPoints({required int points, required String title}) {
    if (points <= 0) return;
    try {
      final wallet = context.read<WalletProvider>();
      wallet.addPoints(points);
      wallet.addTransaction({
        'id': 'gfit-pts-${DateTime.now().millisecondsSinceEpoch}',
        'title': title,
        'type': 'GFIT_REWARD',
        'amount': points,
        'status': 'SUCCESS',
        'date': DateTime.now().toIso8601String(),
      });
    } catch (_) {}
  }

  Future<void> _claimMission(GFitMissionDefinition mission) async {
    HapticFeedback.mediumImpact();
    final uid = _currentUserId();
    final claimed = await GFitService.claimMission(mission: mission, userId: uid);
    _creditWalletPoints(
      points: mission.bonusPoints,
      title: 'Misi G-Fit: ${mission.title}',
    );
    if (!mounted) return;
    setState(() {
      _claimedMissionIds = claimed;
      _unlockedVouchers = {
        ..._unlockedVouchers,
        mission.rewardVoucherCode.toUpperCase(),
      };
    });
    GageToast.show(
      context,
      '+${mission.bonusPoints} Poin & Voucher ${mission.rewardVoucherCode} aktif!',
      type: GageToastType.success,
    );
  }

  Future<void> _deleteSession(GFitWorkoutSession session) async {
    final uid = _currentUserId();
    final updated = _sessions.where((s) => s.id != session.id).toList();
    await GFitService.saveSessions(updated, userId: uid);
    if (!mounted) return;
    setState(() => _sessions = updated);
    GageToast.show(context, 'Riwayat latihan dihapus.', type: GageToastType.info);
  }

  void _openActivityPickerSheet() {
    if (_isTracking) {
      GageToast.show(
        context,
        'Tidak dapat mengubah olahraga saat sesi berjalan.',
        type: GageToastType.info,
      );
      return;
    }
    HapticFeedback.selectionClick();
    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Jenis Olahraga',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: GFitActivityType.values.map((mode) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final active = _activityType == mode;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: active
                  ? mode.accentColor.withValues(alpha: 0.1)
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: active
                      ? mode.accentColor
                      : (isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0)),
                  width: active ? 1.5 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              leading: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: mode.accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(mode.icon, color: mode.accentColor),
              ),
              title: Text(
                mode.fullName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                '+${mode.pointsPerKm} Poin GAGE / km',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                ),
              ),
              trailing: active
                  ? Icon(Icons.check_circle_rounded, color: mode.accentColor)
                  : null,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _activityType = mode);
                Navigator.pop(context);
              },
            ),
          ),
          );
        }).toList(),
      ),
    );
  }

  void _openSettingsSheet() {
    HapticFeedback.lightImpact();
    var tempTarget = _weeklyTargetKm.round();
    var tempWeight = _weightKg.round();
    var tempAutoPause = _autoPauseEnabled;
    var tempVoiceCue = _voiceCueEnabled;

    GageFloatingSheet.show(
      context: context,
      title: 'Target & Kalibrasi G-Fit',
      child: StatefulBuilder(
        builder: (ctx, setModalState) {
          final isDark = Theme.of(ctx).brightness == Brightness.dark;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Target Jarak Mingguan',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$tempTarget km / minggu',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: HorizontalRulerPicker(
                  initialValue: tempTarget,
                  minValue: 2,
                  maxValue: 50,
                  step: 1,
                  majorInterval: 5,
                  mediumInterval: 1,
                  onChanged: (v) => setModalState(() => tempTarget = v),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Berat Badan (Kalibrasi Kalori MET)',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    '$tempWeight kg',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
                  ),
                ),
                child: HorizontalRulerPicker(
                  initialValue: tempWeight,
                  minValue: 35,
                  maxValue: 130,
                  step: 1,
                  majorInterval: 10,
                  mediumInterval: 5,
                  onChanged: (v) => setModalState(() => tempWeight = v),
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: GageTheme.primary,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                title: const Text(
                  'Auto-Pause Saat Berhenti',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Jeda stopwatch otomatis ketika berhenti sejenak.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                value: tempAutoPause,
                onChanged: (val) => setModalState(() => tempAutoPause = val),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: GageTheme.primary,
                activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                title: const Text(
                  'Notifikasi & Chime Per 1 KM',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  'Bunyikan isyarat audio & info split pace tiap genap 1 kilometer.',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                value: tempVoiceCue,
                onChanged: (val) => setModalState(() => tempVoiceCue = val),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () async {
                    final uid = _currentUserId();
                    await GFitService.savePreferences(
                      userId: uid,
                      weeklyTargetKm: tempTarget.toDouble(),
                      weightKg: tempWeight.toDouble(),
                      autoPauseEnabled: tempAutoPause,
                      voiceCueEnabled: tempVoiceCue,
                    );
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                    }
                    if (!mounted) return;
                    setState(() {
                      _weeklyTargetKm = tempTarget.toDouble();
                      _weightKg = tempWeight.toDouble();
                      _autoPauseEnabled = tempAutoPause;
                      _voiceCueEnabled = tempVoiceCue;
                    });
                    GageToast.show(
                      context,
                      'Target & kalibrasi G-Fit diperbarui.',
                      type: GageToastType.success,
                    );
                  },
                  child: const Text(
                    'Simpan Pengaturan',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final weeklyKm = GFitService.totalWeeklyDistanceKm(_sessions);
    final weeklyPct = (weeklyKm / _weeklyTargetKm).clamp(0.0, 1.0);

    int walletPts = 0;
    try {
      walletPts = context.watch<WalletProvider>().points;
    } catch (_) {}

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () {
            if (_isTracking) {
              GageToast.show(
                context,
                'Selesaikan atau hentikan sesi aktif sebelum keluar.',
                type: GageToastType.info,
              );
              return;
            }
            Navigator.pop(context);
          },
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.directions_run_rounded,
                color: GageTheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'G-Fit',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Target ${weeklyKm.toStringAsFixed(1)} / ${_weeklyTargetKm.toStringAsFixed(0)} km minggu ini',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.16)
                  : const Color(0xFFFEF3C7),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.stars_rounded, size: 14, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  '$walletPts Poin',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.tune_rounded,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
            tooltip: 'Target & Berat Badan',
            onPressed: _openSettingsSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              height: 40,
              padding: const EdgeInsets.all(3.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => HapticFeedback.selectionClick(),
                indicator: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor:
                    isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                unselectedLabelStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                tabs: _mainTabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMulaiTab(isDark, weeklyKm, weeklyPct),
          _buildRiwayatTab(isDark, weeklyKm),
          _buildMisiPoinTab(isDark, weeklyKm),
        ],
      ),
    );
  }

  Widget _buildMulaiTab(bool isDark, double weeklyKm, double weeklyPct) {
    final currentPace = _distanceKm >= 0.03 && _elapsedSeconds > 0
        ? GFitService.formatPaceFromSeconds((_elapsedSeconds / _distanceKm).round())
        : "--'--\"";
    final projectedPts = GFitService.calculateEarnedPoints(
      type: _activityType,
      distanceKm: _distanceKm,
      alreadyEarnedToday: _dailyPointsUsed,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // 1. Google Maps Live GPS View
        GFitMapView(
          center: _currentCenter,
          recordedPoints: _recordedPoints,
          accentColor: _activityType.accentColor,
          height: 270,
          isTracking: _isTracking,
          isPaused: _isPaused,
          isAutoPaused: _isAutoPaused,
          gpsAccuracyMeters: _gpsAccuracyMeters,
          userAvatarUrl: _currentUserAvatar(),
          userName: _currentUserName(),
          onRequestRecenter: () => _refreshCurrentLocation(forceFresh: true),
        ),
        const SizedBox(height: 14),

        // 2. Real-time Telemetry Card + Strava-style Mode & Start Dock
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DURASI LATIHAN',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        GFitService.formatDuration(_elapsedSeconds),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: _isTracking
                          ? (_isPaused
                              ? const Color(0xFFFEF3C7)
                              : const Color(0xFFDCFCE7))
                          : (isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      !_isTracking
                          ? 'Siap Mulai'
                          : (_isAutoPaused
                              ? 'Auto-Pause'
                              : (_isPaused ? 'Dijeda' : 'Berjalan')),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: !_isTracking
                            ? (isDark ? Colors.white70 : const Color(0xFF475569))
                            : (_isPaused
                                ? const Color(0xFFB45309)
                                : const Color(0xFF15803D)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _TelemetryCell(
                      label: 'Jarak',
                      value: '${_distanceKm.toStringAsFixed(2)} km',
                      icon: Icons.straighten_rounded,
                      color: GageTheme.primary,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TelemetryCell(
                      label: _activityType == GFitActivityType.bike
                          ? 'Kecepatan'
                          : 'Pace',
                      value: _activityType == GFitActivityType.bike
                          ? '${_currentSpeedKmh.toStringAsFixed(1)} km/j'
                          : '$currentPace/km',
                      icon: Icons.speed_rounded,
                      color: const Color(0xFF0284C7),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _TelemetryCell(
                      label: 'Kalori (${_weightKg.round()} kg)',
                      value: '$_calories kcal',
                      icon: Icons.local_fire_department_rounded,
                      color: const Color(0xFFEA580C),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TelemetryCell(
                      label: 'Estimasi Poin',
                      value: '+$projectedPts Poin',
                      icon: Icons.stars_rounded,
                      color: const Color(0xFF16A34A),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (!_isTracking)
                Row(
                  children: [
                    // Sleek Strava-style single sport selector button (no segmented bar)
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: _openActivityPickerSheet,
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: isDark
                                ? GageTheme.darkBorder
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _activityType.icon,
                              size: 18,
                              color: _activityType.accentColor,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _activityType.label,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _startWorkout,
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: Text(
                            'Mulai ${_activityType.fullName}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          side: BorderSide(
                            color: _isPaused
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                          foregroundColor: _isPaused
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                        onPressed: _togglePause,
                        icon: Icon(
                          _isPaused
                              ? Icons.play_arrow_rounded
                              : Icons.pause_rounded,
                        ),
                        label: Text(
                          _isPaused ? 'Lanjutkan' : 'Jeda',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                        onPressed: _confirmAndFinishWorkout,
                        icon: const Icon(Icons.stop_circle_rounded, size: 20),
                        label: const Text(
                          'Selesai & Simpan',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 3. Weekly Target Progress Card
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: _openSettingsSheet,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.flag_circle_rounded,
                      color: GageTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        'Progres Target Mingguan (${weeklyKm.toStringAsFixed(1)} / ${_weeklyTargetKm.toStringAsFixed(0)} km)',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: GageTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: weeklyPct,
                    minHeight: 8,
                    backgroundColor:
                        isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      GageTheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatTab(bool isDark, double weeklyKm) {
    final weeklyCal = GFitService.totalWeeklyCalories(_sessions);
    final bestPace = GFitService.bestPaceFormatted(_sessions);
    final longest = GFitService.longestDistanceKm(_sessions);
    final dailyBuckets = GFitService.weeklyDailyDistances(_sessions);

    final filtered = _historyFilter == null
        ? _sessions
        : _sessions.where((s) => s.activityType == _historyFilter).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // 7-Day Activity Bar Chart + Summary KPIs
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Aktivitas 7 Hari Minggu Ini',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '${weeklyKm.toStringAsFixed(2)} km',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 120,
                child: _WeeklyActivityChart(
                  dailyKm: dailyBuckets,
                  isDark: isDark,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MiniStatChip(
                      label: 'Kalori Minggu Ini',
                      value: '${weeklyCal.round()} kcal',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatChip(
                      label: 'Pace Terbaik',
                      value: '$bestPace/km',
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MiniStatChip(
                      label: 'Rekor Jarak',
                      value: '${longest.toStringAsFixed(1)} km',
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Text(
              'Catatan Latihan (${filtered.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            if (_sessions.isNotEmpty)
              PopupMenuButton<GFitActivityType?>(
                onSelected: (val) {
                  HapticFeedback.selectionClick();
                  setState(() => _historyFilter = val);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: null, child: Text('Semua Aktivitas')),
                  ...GFitActivityType.values.map(
                    (t) => PopupMenuItem(value: t, child: Text(t.fullName)),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.filter_list_rounded, size: 15),
                      const SizedBox(width: 5),
                      Text(
                        _historyFilter?.label ?? 'Semua',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.directions_run_rounded,
                  size: 42,
                  color: GageTheme.primary.withValues(alpha: 0.75),
                ),
                const SizedBox(height: 10),
                Text(
                  'Belum ada catatan latihan GPS',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Mulai rekam lari, jalan sehat, atau gowes dengan GPS nyata untuk melihat grafik mingguan dan mengumpulkan Poin GAGE.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () => _tabController.animateTo(0),
                  child: const Text('Mulai Latihan Sekarang'),
                ),
              ],
            ),
          )
        else
          ...filtered.map((s) {
            final dateStr = DateFormat('d MMM yyyy • HH:mm').format(s.startedAt);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  GFitShareSheet.show(
                    context,
                    session: s,
                    userAvatarUrl: _currentUserAvatar(),
                    userName: _currentUserName(),
                    onDelete: () => _deleteSession(s),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: s.activityType.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          s.activityType.icon,
                          color: s.activityType.accentColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.sessionTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '$dateStr • ${s.formattedPace}/km • ${s.calories} kcal',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark
                                    ? Colors.white60
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${s.distanceKm.toStringAsFixed(2)} km',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.pointsEarned > 0
                                ? '+${s.pointsEarned} Poin'
                                : s.formattedDuration,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: s.pointsEarned > 0
                                  ? const Color(0xFF16A34A)
                                  : (isDark
                                      ? Colors.white60
                                      : const Color(0xFF64748B)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildMisiPoinTab(bool isDark, double weeklyKm) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
      children: [
        // Daily Points Quota & Rate Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Kuota Poin Harian G-Fit',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$_dailyPointsUsed / ${GFitService.dailyPointsCap} Poin',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (_dailyPointsUsed / GFitService.dailyPointsCap).clamp(0.0, 1.0),
                  minHeight: 7,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                ),
              ),
              const SizedBox(height: 12),
              const Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _RatePill('Lari & Jalan: +15 Poin / km'),
                  _RatePill('Sepeda: +8 Poin / km'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Weekly Target Overview
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Jarak Minggu Ini',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${weeklyKm.toStringAsFixed(2)} / ${_weeklyTargetKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  elevation: 0,
                ),
                onPressed: _openSettingsSheet,
                child: const Text(
                  'Atur Target',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Misi Mingguan & Voucher Hadiah',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 10),
        ...GFitService.weeklyMissions.map((m) {
          final isClaimed = _claimedMissionIds.contains(m.id);
          final isCompleted = weeklyKm >= m.targetKm;
          final pct = (weeklyKm / m.targetKm).clamp(0.0, 1.0);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkSurface : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isCompleted && !isClaimed
                    ? GageTheme.primary
                    : (isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0)),
                width: isCompleted && !isClaimed ? 1.5 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(m.icon, color: GageTheme.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            m.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '+${m.bonusPoints} Poin • Voucher ${m.rewardVoucherCode}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  m.subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: pct,
                          minHeight: 7,
                          backgroundColor: isDark
                              ? const Color(0xFF0F172A)
                              : const Color(0xFFF1F5F9),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isCompleted ? const Color(0xFF16A34A) : GageTheme.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${math.min(weeklyKm, m.targetKm).toStringAsFixed(1)}/${m.targetKm.toStringAsFixed(0)} km',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white70 : const Color(0xFF334155),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: isClaimed
                      ? Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Center(
                            child: Text(
                              'Sudah Diklaim • Cek di Halaman Promo',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isCompleted
                                ? GageTheme.primary
                                : (isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFE2E8F0)),
                            foregroundColor: isCompleted
                                ? Colors.white
                                : (isDark
                                    ? Colors.white54
                                    : const Color(0xFF64748B)),
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: isCompleted ? () => _claimMission(m) : null,
                          child: Text(
                            isCompleted
                                ? 'Klaim +${m.bonusPoints} Poin & Voucher'
                                : 'Kurang ${(m.targetKm - weeklyKm).toStringAsFixed(1)} km lagi',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          );
        }),

        if (_unlockedVouchers.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: const BorderSide(color: GageTheme.primary, width: 1.4),
                foregroundColor: GageTheme.primary,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PromoScreen()),
                );
              },
              icon: const Icon(Icons.confirmation_number_rounded, size: 18),
              label: Text(
                'Pakai ${_unlockedVouchers.length} Voucher G-Fit di Promo & Checkout',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _TelemetryCell({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.5,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _MiniStatChip({
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }
}

class _RatePill extends StatelessWidget {
  final String text;

  const _RatePill(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _WeeklyActivityChart extends StatelessWidget {
  final List<double> dailyKm;
  final bool isDark;

  const _WeeklyActivityChart({required this.dailyKm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const labels = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
    var maxVal = 2.0;
    for (final v in dailyKm) {
      if (v > maxVal) maxVal = v;
    }

    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _WeeklyBarChartPainter(
              values: dailyKm,
              maxVal: maxVal,
              barColor: GageTheme.primary,
              trackColor:
                  isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
            ),
            child: const SizedBox.expand(),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(7, (i) {
            final v = i < dailyKm.length ? dailyKm[i] : 0.0;
            return Column(
              children: [
                Text(
                  v > 0 ? v.toStringAsFixed(1) : '-',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: v > 0
                        ? GageTheme.primary
                        : (isDark ? Colors.white38 : Colors.grey.shade400),
                  ),
                ),
                Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  ),
                ),
              ],
            );
          }),
        ),
      ],
    );
  }
}

class _WeeklyBarChartPainter extends CustomPainter {
  final List<double> values;
  final double maxVal;
  final Color barColor;
  final Color trackColor;

  _WeeklyBarChartPainter({
    required this.values,
    required this.maxVal,
    required this.barColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const count = 7;
    final colWidth = size.width / count;
    final barWidth = math.min(20.0, colWidth * 0.44);

    final trackPaint = Paint()..color = trackColor;
    final barPaint = Paint()..color = barColor;

    for (var i = 0; i < count; i++) {
      final cx = colWidth * i + colWidth / 2;
      final left = cx - barWidth / 2;
      final trackRRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, 4, barWidth, size.height - 6),
        const Radius.circular(999),
      );
      canvas.drawRRect(trackRRect, trackPaint);

      final v = i < values.length ? values[i] : 0.0;
      if (v > 0 && maxVal > 0) {
        final ratio = (v / maxVal).clamp(0.08, 1.0);
        final h = (size.height - 6) * ratio;
        final top = size.height - 2 - h;
        final barRRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, barWidth, h),
          const Radius.circular(999),
        );
        canvas.drawRRect(barRRect, barPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyBarChartPainter oldDelegate) =>
      oldDelegate.values != values ||
      oldDelegate.maxVal != maxVal ||
      oldDelegate.barColor != barColor ||
      oldDelegate.trackColor != trackColor;
}
