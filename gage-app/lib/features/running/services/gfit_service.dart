import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

enum GFitActivityType {
  run,
  walk,
  bike;

  String get label {
    switch (this) {
      case GFitActivityType.run:
        return 'Lari';
      case GFitActivityType.walk:
        return 'Jalan';
      case GFitActivityType.bike:
        return 'Sepeda';
    }
  }

  String get fullName {
    switch (this) {
      case GFitActivityType.run:
        return 'Lari';
      case GFitActivityType.walk:
        return 'Jalan Sehat';
      case GFitActivityType.bike:
        return 'Bersepeda';
    }
  }

  double get metBase {
    switch (this) {
      case GFitActivityType.run:
        return 9.8;
      case GFitActivityType.walk:
        return 3.8;
      case GFitActivityType.bike:
        return 7.5;
    }
  }

  int get pointsPerKm {
    switch (this) {
      case GFitActivityType.run:
        return 15;
      case GFitActivityType.walk:
        return 15;
      case GFitActivityType.bike:
        return 8;
    }
  }

  Color get accentColor {
    switch (this) {
      case GFitActivityType.run:
        return GageTheme.primary;
      case GFitActivityType.walk:
        return const Color(0xFF0284C7);
      case GFitActivityType.bike:
        return const Color(0xFF16A34A);
    }
  }

  IconData get icon {
    switch (this) {
      case GFitActivityType.run:
        return Icons.directions_run_rounded;
      case GFitActivityType.walk:
        return Icons.directions_walk_rounded;
      case GFitActivityType.bike:
        return Icons.directions_bike_rounded;
    }
  }

  static GFitActivityType fromName(String? raw) {
    for (final v in GFitActivityType.values) {
      if (v.name == raw) return v;
    }
    return GFitActivityType.run;
  }
}

class GFitSplitLap {
  final int kmIndex;
  final int splitSeconds;
  final int elapsedSeconds;

  const GFitSplitLap({
    required this.kmIndex,
    required this.splitSeconds,
    required this.elapsedSeconds,
  });

  String get formattedSplitPace => GFitService.formatPaceFromSeconds(splitSeconds);

  Map<String, dynamic> toJson() => {
        'kmIndex': kmIndex,
        'splitSeconds': splitSeconds,
        'elapsedSeconds': elapsedSeconds,
      };

  factory GFitSplitLap.fromJson(Map<String, dynamic> json) => GFitSplitLap(
        kmIndex: (json['kmIndex'] as num?)?.toInt() ?? 1,
        splitSeconds: (json['splitSeconds'] as num?)?.toInt() ?? 0,
        elapsedSeconds: (json['elapsedSeconds'] as num?)?.toInt() ?? 0,
      );
}

class GFitWorkoutSession {
  final String id;
  final GFitActivityType activityType;
  final DateTime startedAt;
  final int durationSeconds;
  final double distanceKm;
  final int calories;
  final double elevationGainM;
  final int pointsEarned;
  final List<LatLng> routePoints;
  final List<GFitSplitLap> splitLaps;

  const GFitWorkoutSession({
    required this.id,
    required this.activityType,
    required this.startedAt,
    required this.durationSeconds,
    required this.distanceKm,
    required this.calories,
    this.elevationGainM = 0.0,
    this.pointsEarned = 0,
    this.routePoints = const [],
    this.splitLaps = const [],
  });

  double get avgSpeedKmh {
    if (durationSeconds <= 0 || distanceKm <= 0) return 0;
    return distanceKm / (durationSeconds / 3600.0);
  }

  String get formattedDuration => GFitService.formatDuration(durationSeconds);

  String get formattedPace {
    if (distanceKm < 0.03 || durationSeconds <= 0) return "--'--\"";
    final secPerKm = (durationSeconds / distanceKm).round();
    return GFitService.formatPaceFromSeconds(secPerKm);
  }

  String get sessionTitle {
    final hour = startedAt.hour;
    final part = hour < 11
        ? 'Pagi'
        : (hour < 15 ? 'Siang' : (hour < 18 ? 'Sore' : 'Malam'));
    return '${activityType.fullName} $part';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'activityType': activityType.name,
        'startedAt': startedAt.toIso8601String(),
        'durationSeconds': durationSeconds,
        'distanceKm': distanceKm,
        'calories': calories,
        'elevationGainM': elevationGainM,
        'pointsEarned': pointsEarned,
        'routePoints': routePoints
            .map((p) => {'lat': p.latitude, 'lng': p.longitude})
            .toList(),
        'splitLaps': splitLaps.map((l) => l.toJson()).toList(),
      };

  factory GFitWorkoutSession.fromJson(Map<String, dynamic> json) {
    final rawPts = (json['routePoints'] as List<dynamic>?) ?? const [];
    final pts = <LatLng>[];
    for (final item in rawPts) {
      if (item is Map) {
        final lat = (item['lat'] as num?)?.toDouble();
        final lng = (item['lng'] as num?)?.toDouble();
        if (lat != null && lng != null) {
          pts.add(LatLng(lat, lng));
        }
      }
    }
    final rawLaps = (json['splitLaps'] as List<dynamic>?) ?? const [];
    final laps = rawLaps
        .whereType<Map>()
        .map((m) => GFitSplitLap.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return GFitWorkoutSession(
      id: (json['id'] as String?) ?? '',
      activityType: GFitActivityType.fromName(json['activityType'] as String?),
      startedAt: DateTime.tryParse((json['startedAt'] as String?) ?? '') ??
          DateTime.now(),
      durationSeconds: (json['durationSeconds'] as num?)?.toInt() ?? 0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0.0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      elevationGainM: (json['elevationGainM'] as num?)?.toDouble() ?? 0.0,
      pointsEarned: (json['pointsEarned'] as num?)?.toInt() ?? 0,
      routePoints: pts,
      splitLaps: laps,
    );
  }
}

class GFitMissionDefinition {
  final String id;
  final String title;
  final String subtitle;
  final double targetKm;
  final int bonusPoints;
  final String rewardVoucherCode;
  final String rewardVoucherTitle;
  final IconData icon;

  const GFitMissionDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.targetKm,
    required this.bonusPoints,
    required this.rewardVoucherCode,
    required this.rewardVoucherTitle,
    required this.icon,
  });
}

class GFitUserState {
  final List<GFitWorkoutSession> sessions;
  final double weeklyTargetKm;
  final double weightKg;
  final bool autoPauseEnabled;
  final bool voiceCueEnabled;
  final Set<String> claimedMissionIds;
  final Set<String> unlockedVoucherCodes;
  final int dailyPointsUsed;

  const GFitUserState({
    required this.sessions,
    required this.weeklyTargetKm,
    required this.weightKg,
    required this.autoPauseEnabled,
    required this.voiceCueEnabled,
    required this.claimedMissionIds,
    required this.unlockedVoucherCodes,
    required this.dailyPointsUsed,
  });
}

class GFitService {
  static const int dailyPointsCap = 300;
  static const String _guestUser = 'guest';

  static final ValueNotifier<Set<String>> unlockedVouchersNotifier =
      ValueNotifier<Set<String>>(<String>{});

  static const List<GFitMissionDefinition> weeklyMissions = [
    GFitMissionDefinition(
      id: 'mission_5km_starter',
      title: 'Langkah Awal 5 KM',
      subtitle: 'Tempuh total 5 km minggu ini untuk buka diskon G-Food & G-Shop',
      targetKm: 5.0,
      bonusPoints: 100,
      rewardVoucherCode: 'GFITSEHAT',
      rewardVoucherTitle: 'Diskon G-Food & G-Shop Rp5.000',
      icon: Icons.directions_walk_rounded,
    ),
    GFitMissionDefinition(
      id: 'mission_10km_runner',
      title: 'Penjelajah Praci 10 KM',
      subtitle: 'Capai 10 km minggu ini untuk Gratis Ongkir G-Food / G-Send',
      targetKm: 10.0,
      bonusPoints: 250,
      rewardVoucherCode: 'GFITONGKIR',
      rewardVoucherTitle: 'Gratis Ongkir s/d Rp10.000',
      icon: Icons.directions_run_rounded,
    ),
    GFitMissionDefinition(
      id: 'mission_21km_champion',
      title: 'Juara G-Fit 21 KM',
      subtitle: 'Tuntaskan Half Marathon mingguan & klaim Cashback 25%',
      targetKm: 21.0,
      bonusPoints: 500,
      rewardVoucherCode: 'GFITJUARA',
      rewardVoucherTitle: 'Cashback 25% s/d Rp15.000',
      icon: Icons.emoji_events_rounded,
    ),
  ];

  static String _prefix(String? userId) {
    final clean = (userId == null || userId.trim().isEmpty)
        ? _guestUser
        : userId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'gfit_v2_${clean}_';
  }

  static String currentWeekKey([DateTime? now]) {
    final d = now ?? DateTime.now();
    final monday = DateTime(d.year, d.month, d.day)
        .subtract(Duration(days: d.weekday - 1));
    return '${monday.year}-${monday.month.toString().padLeft(2, '0')}-${monday.day.toString().padLeft(2, '0')}';
  }

  static String _dayKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  static DateTime startOfCurrentWeek([DateTime? now]) {
    final d = now ?? DateTime.now();
    final midnight = DateTime(d.year, d.month, d.day);
    return midnight.subtract(Duration(days: d.weekday - 1));
  }

  static Future<Set<String>> loadUnlockedVoucherCodes({String? userId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final p = _prefix(userId);
      final raw = prefs.getStringList('${p}unlocked_vouchers') ?? const [];
      final result = raw
          .map((e) => e.trim().toUpperCase())
          .where((e) => e.isNotEmpty)
          .toSet();
      unlockedVouchersNotifier.value = result;
      return result;
    } catch (_) {
      return unlockedVouchersNotifier.value;
    }
  }

  static Future<GFitUserState> loadUserState({String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final p = _prefix(userId);

    final rawSessions = prefs.getString('${p}sessions');
    var sessions = <GFitWorkoutSession>[];
    if (rawSessions != null && rawSessions.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSessions) as List<dynamic>;
        sessions = decoded
            .whereType<Map>()
            .map((m) => GFitWorkoutSession.fromJson(Map<String, dynamic>.from(m)))
            .where((s) => s.distanceKm >= 0.05 && !s.id.startsWith('seed-'))
            .toList();
      } catch (_) {
        sessions = [];
      }
    }

    sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    final weeklyTargetKm = prefs.getDouble('${p}weekly_target_km') ?? 10.0;
    final weightKg = prefs.getDouble('${p}weight_kg') ?? 62.0;
    final autoPauseEnabled = prefs.getBool('${p}auto_pause') ?? true;
    final voiceCueEnabled = prefs.getBool('${p}voice_cue') ?? true;

    final storedWeek = prefs.getString('${p}mission_week_key');
    final activeWeek = currentWeekKey();
    var claimed = <String>{};
    if (storedWeek == activeWeek) {
      claimed = (prefs.getStringList('${p}claimed_missions') ?? const []).toSet();
    } else {
      await prefs.setString('${p}mission_week_key', activeWeek);
      await prefs.setStringList('${p}claimed_missions', const []);
    }

    final unlocked =
        (prefs.getStringList('${p}unlocked_vouchers') ?? const [])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();
    unlockedVouchersNotifier.value = unlocked;

    final today = _dayKey(DateTime.now());
    final savedDate = prefs.getString('${p}daily_points_date');
    final dailyUsed =
        (savedDate == today) ? (prefs.getInt('${p}daily_points_used') ?? 0) : 0;
    if (savedDate != today) {
      await prefs.setString('${p}daily_points_date', today);
      await prefs.setInt('${p}daily_points_used', 0);
    }

    return GFitUserState(
      sessions: sessions,
      weeklyTargetKm: weeklyTargetKm.clamp(2.0, 100.0),
      weightKg: weightKg.clamp(35.0, 160.0),
      autoPauseEnabled: autoPauseEnabled,
      voiceCueEnabled: voiceCueEnabled,
      claimedMissionIds: claimed,
      unlockedVoucherCodes: unlocked,
      dailyPointsUsed: dailyUsed,
    );
  }

  static Future<void> saveSessions(
    List<GFitWorkoutSession> sessions, {
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final p = _prefix(userId);
    final encoded = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await prefs.setString('${p}sessions', encoded);
  }

  static Future<void> savePreferences({
    String? userId,
    double? weeklyTargetKm,
    double? weightKg,
    bool? autoPauseEnabled,
    bool? voiceCueEnabled,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final p = _prefix(userId);
    if (weeklyTargetKm != null) {
      await prefs.setDouble('${p}weekly_target_km', weeklyTargetKm.clamp(2.0, 100.0));
    }
    if (weightKg != null) {
      await prefs.setDouble('${p}weight_kg', weightKg.clamp(35.0, 160.0));
    }
    if (autoPauseEnabled != null) {
      await prefs.setBool('${p}auto_pause', autoPauseEnabled);
    }
    if (voiceCueEnabled != null) {
      await prefs.setBool('${p}voice_cue', voiceCueEnabled);
    }
  }

  static Future<int> recordDailyPointsEarned(int points, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    final p = _prefix(userId);
    final today = _dayKey(DateTime.now());
    final savedDate = prefs.getString('${p}daily_points_date');
    final used = (savedDate == today) ? (prefs.getInt('${p}daily_points_used') ?? 0) : 0;
    final nextUsed = (used + points).clamp(0, dailyPointsCap);
    await prefs.setString('${p}daily_points_date', today);
    await prefs.setInt('${p}daily_points_used', nextUsed);
    return nextUsed;
  }

  static Future<Set<String>> claimMission({
    required GFitMissionDefinition mission,
    String? userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final p = _prefix(userId);
    final week = currentWeekKey();
    await prefs.setString('${p}mission_week_key', week);

    final claimed =
        (prefs.getStringList('${p}claimed_missions') ?? const []).toSet();
    claimed.add(mission.id);
    await prefs.setStringList('${p}claimed_missions', claimed.toList());

    final unlocked =
        (prefs.getStringList('${p}unlocked_vouchers') ?? const [])
            .map((e) => e.trim().toUpperCase())
            .where((e) => e.isNotEmpty)
            .toSet();
    unlocked.add(mission.rewardVoucherCode.toUpperCase());
    await prefs.setStringList('${p}unlocked_vouchers', unlocked.toList());
    unlockedVouchersNotifier.value = unlocked;
    return claimed;
  }

  /// Filter anti-jitter GPS agar titik loncatan liar atau diam tidak menambah jarak semu.
  static bool shouldAcceptGpsSample({
    required Position candidate,
    LatLng? lastPoint,
    required int elapsedDeltaSec,
  }) {
    if (lastPoint == null) {
      return candidate.accuracy <= 65.0;
    }
    if (candidate.accuracy > 35.0) {
      return false;
    }
    final distM = Geolocator.distanceBetween(
      lastPoint.latitude,
      lastPoint.longitude,
      candidate.latitude,
      candidate.longitude,
    );
    if (distM < 3.0) {
      return false;
    }
    final dt = math.max(1, elapsedDeltaSec);
    final speedMps = distM / dt;
    if (speedMps > 32.0) {
      return false;
    }
    return true;
  }

  /// Menghitung kalori menggunakan rumus standar MET x Berat Badan (kg) x Jam.
  static int computeCalories({
    required GFitActivityType type,
    required double weightKg,
    required double distanceKm,
    required int durationSeconds,
    double? speedKmh,
  }) {
    if (durationSeconds <= 0) return 0;
    final spd = speedKmh ??
        (durationSeconds > 0 ? distanceKm / (durationSeconds / 3600.0) : 0.0);

    var met = type.metBase;
    switch (type) {
      case GFitActivityType.run:
        if (spd >= 11.0) {
          met = 11.5;
        } else if (spd >= 8.0) {
          met = 9.8;
        } else if (spd >= 6.0) {
          met = 8.3;
        } else {
          met = 6.0;
        }
        break;
      case GFitActivityType.walk:
        if (spd >= 6.0) {
          met = 4.8;
        } else if (spd >= 4.5) {
          met = 3.8;
        } else {
          met = 3.0;
        }
        break;
      case GFitActivityType.bike:
        if (spd >= 22.0) {
          met = 10.0;
        } else if (spd >= 16.0) {
          met = 7.5;
        } else {
          met = 5.5;
        }
        break;
    }

    final hours = durationSeconds / 3600.0;
    return (met * weightKg * hours).round();
  }

  /// Menghitung Poin GAGE dari jarak & jenis aktivitas nyata dengan batas harian 300 poin.
  static int calculateEarnedPoints({
    required GFitActivityType type,
    required double distanceKm,
    required int alreadyEarnedToday,
  }) {
    if (distanceKm < 0.05) return 0;
    final raw = (distanceKm * type.pointsPerKm).round();
    final remaining = math.max(0, dailyPointsCap - alreadyEarnedToday);
    return raw.clamp(0, remaining);
  }

  static double totalWeeklyDistanceKm(
    List<GFitWorkoutSession> sessions, [
    DateTime? now,
  ]) {
    final start = startOfCurrentWeek(now);
    final end = start.add(const Duration(days: 7));
    var sum = 0.0;
    for (final s in sessions) {
      if (!s.startedAt.isBefore(start) && s.startedAt.isBefore(end)) {
        sum += s.distanceKm;
      }
    }
    return sum;
  }

  static double totalWeeklyCalories(
    List<GFitWorkoutSession> sessions, [
    DateTime? now,
  ]) {
    final start = startOfCurrentWeek(now);
    final end = start.add(const Duration(days: 7));
    var sum = 0.0;
    for (final s in sessions) {
      if (!s.startedAt.isBefore(start) && s.startedAt.isBefore(end)) {
        sum += s.calories;
      }
    }
    return sum;
  }

  /// Mengembalikan total jarak 7 hari dalam minggu berjalan (Senin..Minggu).
  static List<double> weeklyDailyDistances(
    List<GFitWorkoutSession> sessions, [
    DateTime? now,
  ]) {
    final start = startOfCurrentWeek(now);
    final buckets = List<double>.filled(7, 0.0);
    for (final s in sessions) {
      final diffDays = DateTime(s.startedAt.year, s.startedAt.month, s.startedAt.day)
          .difference(start)
          .inDays;
      if (diffDays >= 0 && diffDays < 7) {
        buckets[diffDays] += s.distanceKm;
      }
    }
    return buckets;
  }

  static double longestDistanceKm(List<GFitWorkoutSession> sessions) {
    var best = 0.0;
    for (final s in sessions) {
      if (s.distanceKm > best) best = s.distanceKm;
    }
    return best;
  }

  static String bestPaceFormatted(List<GFitWorkoutSession> sessions) {
    int? bestSec;
    for (final s in sessions) {
      if (s.distanceKm >= 0.3 && s.durationSeconds > 0) {
        final secPerKm = (s.durationSeconds / s.distanceKm).round();
        if (bestSec == null || secPerKm < bestSec) {
          bestSec = secPerKm;
        }
      }
    }
    if (bestSec == null) return "--'--\"";
    return formatPaceFromSeconds(bestSec);
  }

  static String formatDuration(int totalSeconds) {
    final s = math.max(0, totalSeconds);
    final h = s ~/ 3600;
    final m = (s % 3600) ~/ 60;
    final sec = s % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  static String formatPaceFromSeconds(int secPerKm) {
    final safe = secPerKm.clamp(0, 3599);
    final m = safe ~/ 60;
    final s = safe % 60;
    return "$m'${s.toString().padLeft(2, '0')}\"";
  }
}
