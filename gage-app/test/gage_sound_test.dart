import 'package:flutter_test/flutter_test.dart';
import 'package:gage_app/core/services/gage_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GageSoundService Tests', () {
    test('Default sound catalogue contains Pracimantoro tracks', () {
      final service = GageSoundService.instance;
      expect(service.sounds, isNotEmpty);
      expect(service.sounds.any((s) => s.id == 'sound-wonogiri-foodie-01'), isTrue);
      expect(service.sounds.first.title, contains('Wonogiri'));
    });

    test('getSoundById finds correct track or fallback', () {
      final service = GageSoundService.instance;
      final sound = service.getSoundById('sound-dangdut-koplo-praci');
      expect(sound, isNotNull);
      expect(sound!.artist, contains('GAGE Audio'));

      final nonExistent = service.getSoundById('sound-999');
      expect(nonExistent, isNotNull);
    });

    test('toggleSaveSound toggles saved status correctly', () {
      final service = GageSoundService.instance;
      const targetId = 'sound-dangdut-koplo-praci';
      final initialSaved = service.isSoundSaved(targetId);

      final newSaved = service.toggleSaveSound(targetId);
      expect(newSaved, !initialSaved);
      expect(service.isSoundSaved(targetId), newSaved);

      // Revert back
      service.toggleSaveSound(targetId);
      expect(service.isSoundSaved(targetId), initialSaved);
    });
  });
}
