import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/dynamic_asset_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DynamicAssetService.instance.resetAll();
  });

  group('DynamicAssetService Unit Tests', () {
    test('Initializes with default slots registered', () {
      final slots = DynamicAssetService.instance.allSlots;
      expect(slots.isNotEmpty, isTrue);

      final rideSlot = slots.firstWhere((s) => s.key == 'vehicle_ride');
      expect(rideSlot.defaultPath, equals('assets/images/gage_ride_3d.png'));
      expect(rideSlot.currentPath, equals('assets/images/gage_ride_3d.png'));
      expect(rideSlot.isCustomized, isFalse);

      final carSlot = slots.firstWhere((s) => s.key == 'vehicle_car');
      expect(carSlot.defaultPath, equals('assets/images/gage_car_3d.png'));
      expect(carSlot.isCustomized, isFalse);

      final coinSlot = slots.firstWhere((s) => s.key == 'cuan_hero_coin');
      expect(coinSlot.defaultPath, equals('assets/icons/clay/ic_clay_coin.png'));
    });

    test('Grid menu slots are correctly registered', () {
      final slots = DynamicAssetService.instance.allSlots;
      final gridSlots = slots.where((s) => s.category == 'Menu Grid Beranda').toList();
      expect(gridSlots.length, equals(8));

      final rideCarMenu = gridSlots.firstWhere((s) => s.key == 'grid_menu_ride_car');
      expect(rideCarMenu.defaultPath, equals('assets/icons/ic_ride.png'));
      expect(rideCarMenu.label, equals('Menu: Ride & Car'));
    });

    test('Can override slot asset and reset individual slot', () async {
      final service = DynamicAssetService.instance;
      expect(service.getAsset('vehicle_car'), equals('assets/images/gage_car_3d.png'));

      await service.setAsset('vehicle_car', 'assets/icons/ic_ride_car.png');
      expect(service.getAsset('vehicle_car'), equals('assets/icons/ic_ride_car.png'));

      final carSlot = service.allSlots.firstWhere((s) => s.key == 'vehicle_car');
      expect(carSlot.isCustomized, isTrue);

      await service.resetSlot('vehicle_car');
      expect(service.getAsset('vehicle_car'), equals('assets/images/gage_car_3d.png'));
      expect(service.allSlots.firstWhere((s) => s.key == 'vehicle_car').isCustomized, isFalse);
    });

    test('getLibraryPresetsForCategory returns expected presets', () {
      final service = DynamicAssetService.instance;
      final mobilityPresets = service.getLibraryPresetsForCategory('Mobilitas & Armada');
      expect(mobilityPresets, contains('assets/images/gage_car_3d.png'));
      expect(mobilityPresets, contains('assets/images/gage_ride_3d.png'));

      final cuanPresets = service.getLibraryPresetsForCategory('Cuan & Finansial');
      expect(cuanPresets, contains('assets/icons/clay/ic_clay_coin.png'));
      expect(cuanPresets, contains('assets/icons/clay/ic_clay_wallet_withdraw.png'));

      final metricPresets = service.getLibraryPresetsForCategory('Metrik & Statistik');
      expect(metricPresets, contains('assets/icons/clay/ic_clay_clicks.png'));
      expect(metricPresets, contains('assets/icons/clay/ic_clay_conversion.png'));
      expect(metricPresets, contains('assets/icons/clay/ic_clay_order_success.png'));
      expect(metricPresets, contains('assets/icons/clay/ic_clay_referral_users.png'));
    });

    test('isLocalFile returns false for assets/ and true for file paths', () {
      final service = DynamicAssetService.instance;
      expect(service.isLocalFile('assets/images/gage_car_3d.png'), isFalse);
      expect(service.isLocalFile('/data/user/0/com.gage.customer/cache/custom.png'), isTrue);
    });
  });
}
