import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';
import 'package:gage_app/features/running/presentation/pacu_screen.dart';
import 'package:gage_app/features/running/services/gfit_service.dart';
import 'package:gage_app/features/running/widgets/gfit_map_view.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';

Position _mockPosition({
  required double lat,
  required double lng,
  double accuracy = 8.0,
}) {
  return Position(
    longitude: lng,
    latitude: lat,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 120.0,
    altitudeAccuracy: 3.0,
    heading: 0.0,
    headingAccuracy: 1.0,
    speed: 3.0,
    speedAccuracy: 0.5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    GFitService.unlockedVouchersNotifier.value = <String>{};
  });

  tearDown(() {
    GFitService.unlockedVouchersNotifier.value = <String>{};
  });

  group('GFitService Real GPS Domain & Voucher Logic', () {
    test('starts with empty workout history without fake seed sessions', () async {
      final state = await GFitService.loadUserState(userId: 'fresh-user');
      expect(state.sessions, isEmpty);
    });

    test('calculates MET calories accurately across weight & activity type', () {
      final runCalLight = GFitService.computeCalories(
        type: GFitActivityType.run,
        weightKg: 55,
        distanceKm: 5.0,
        durationSeconds: 1800,
      );
      final runCalHeavy = GFitService.computeCalories(
        type: GFitActivityType.run,
        weightKg: 80,
        distanceKm: 5.0,
        durationSeconds: 1800,
      );
      expect(runCalLight, greaterThan(200));
      expect(runCalHeavy, greaterThan(runCalLight));

      final walkCal = GFitService.computeCalories(
        type: GFitActivityType.walk,
        weightKg: 65,
        distanceKm: 3.0,
        durationSeconds: 1800,
      );
      expect(walkCal, greaterThan(80));
      expect(walkCal, lessThan(runCalHeavy));
    });

    test('enforces daily points cap and per-activity point rates', () {
      expect(
        GFitService.calculateEarnedPoints(
          type: GFitActivityType.run,
          distanceKm: 4.0,
          alreadyEarnedToday: 0,
        ),
        60,
      );
      expect(
        GFitService.calculateEarnedPoints(
          type: GFitActivityType.bike,
          distanceKm: 5.0,
          alreadyEarnedToday: 0,
        ),
        40,
      );
      expect(
        GFitService.calculateEarnedPoints(
          type: GFitActivityType.run,
          distanceKm: 4.0,
          alreadyEarnedToday: 290,
        ),
        10,
      );
      expect(
        GFitService.calculateEarnedPoints(
          type: GFitActivityType.run,
          distanceKm: 0.02,
          alreadyEarnedToday: 0,
        ),
        0,
      );
    });

    test('filters GPS jitter, poor accuracy, and impossible teleport spikes', () {
      const origin = LatLng(-8.05450, 110.80900);
      expect(
        GFitService.shouldAcceptGpsSample(
          candidate: _mockPosition(lat: -8.05451, lng: 110.80901, accuracy: 8),
          lastPoint: origin,
          elapsedDeltaSec: 2,
        ),
        isFalse,
      );
      expect(
        GFitService.shouldAcceptGpsSample(
          candidate: _mockPosition(lat: -8.05490, lng: 110.80940, accuracy: 55),
          lastPoint: origin,
          elapsedDeltaSec: 5,
        ),
        isFalse,
      );
      expect(
        GFitService.shouldAcceptGpsSample(
          candidate: _mockPosition(lat: -8.04000, lng: 110.82000, accuracy: 6),
          lastPoint: origin,
          elapsedDeltaSec: 2,
        ),
        isFalse,
      );
      expect(
        GFitService.shouldAcceptGpsSample(
          candidate: _mockPosition(lat: -8.05460, lng: 110.80900, accuracy: 8),
          lastPoint: origin,
          elapsedDeltaSec: 3,
        ),
        isTrue,
      );
    });

    test('claiming 5KM mission unlocks GFITSEHAT into GageVoucherData', () async {
      expect(GageVoucherData.findByCode('GFITSEHAT'), isNull);

      final mission = GFitService.weeklyMissions.first;
      await GFitService.claimMission(mission: mission, userId: 'u-test');

      expect(
        GFitService.unlockedVouchersNotifier.value.contains('GFITSEHAT'),
        isTrue,
      );
      expect(GageVoucherData.findByCode('GFITSEHAT'), isNotNull);
      final foodVouchers = GageVoucherData.vouchersForService('food');
      expect(
        foodVouchers.any((v) => v['code'] == 'GFITSEHAT'),
        isTrue,
      );
    });
  });

  group('PacuScreen (G-Fit) Simplified Real GPS UI', () {
    testWidgets('omits simulation and route presets, keeps one TabBar, switches sport via sheet, and claims mission', (tester) async {
      final now = DateTime.now();
      await GFitService.saveSessions([
        GFitWorkoutSession(
          id: 'w-real-gps-1',
          activityType: GFitActivityType.run,
          startedAt: now,
          durationSeconds: 1800,
          distanceKm: 5.4,
          calories: 360,
          pointsEarned: 81,
          routePoints: const [
            LatLng(-8.05450, 110.80900),
            LatLng(-8.05580, 110.80900),
          ],
        ),
      ]);

      final walletProv = WalletProvider();
      final initialPts = walletProv.points;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider.value(value: walletProv),
          ],
          child: const MaterialApp(
            home: PacuScreen(),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('G-Fit'), findsOneWidget);
      expect(find.byType(GFitMapView), findsOneWidget);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Mulai'), findsOneWidget);
      expect(find.text('Riwayat'), findsOneWidget);
      expect(find.text('Misi'), findsOneWidget);

      // Pastikan Simulasi & Rute Rekomendasi benar-benar dihilangkan
      expect(find.text('Simulasi Rute'), findsNothing);
      expect(find.text('GPS Akurat'), findsNothing);
      expect(find.textContaining('Rute Rekomendasi'), findsNothing);
      expect(find.textContaining('Lingkar Lapangan Merdeka'), findsNothing);

      // Ubah olahraga lewat tombol pemilih ringkas (bukan segmented bar)
      final sportFinder = find.text('Lari');
      await tester.ensureVisible(sportFinder);
      await tester.pumpAndSettle();
      await tester.tap(sportFinder);
      await tester.pumpAndSettle();
      expect(find.text('Pilih Jenis Olahraga'), findsOneWidget);
      await tester.tap(find.text('Bersepeda'));
      await tester.pumpAndSettle();
      expect(find.text('Mulai Bersepeda'), findsOneWidget);

      // Klaim misi 5 KM di tab Misi
      await tester.tap(find.text('Misi'));
      await tester.pumpAndSettle();

      expect(find.text('Langkah Awal 5 KM'), findsOneWidget);
      final claimBtn = find.text('Klaim +100 Poin & Voucher');
      expect(claimBtn, findsOneWidget);

      await tester.tap(claimBtn);
      await tester.pump(const Duration(seconds: 3));

      expect(walletProv.points, initialPts + 100);
      expect(GageVoucherData.findByCode('GFITSEHAT'), isNotNull);
    });
  });
}
