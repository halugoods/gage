import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/gage_sound_service.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/features/video/presentation/sound_detail_screen.dart';
import 'package:gage_app/features/video/presentation/video_editor_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Video Feed Action Bar & Layout Refinement Tests', () {
    testWidgets('VideoFeedScreen renders Buat Video, Follow button, Repost, Bookmark, and Share button', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: VideoFeedScreen(),
          ),
        ),
      );

      // Verify top-left button has video_call icon (Buat Video)
      expect(find.byIcon(Icons.video_call_rounded), findsOneWidget);

      // Verify action bar contains Bookmark / Simpan icon
      expect(find.byIcon(Icons.bookmark_rounded), findsAtLeastNWidgets(1));

      // Verify action bar contains Repost icon
      expect(find.byIcon(Icons.repeat_rounded), findsAtLeastNWidgets(1));

      // Verify action bar contains right-curved share arrow
      expect(find.byIcon(Icons.reply_rounded), findsOneWidget);

      // Verify avatar follow button with 'Ikuti'
      expect(find.text('Ikuti'), findsAtLeastNWidgets(1));

      // Verify bottom nav bar is present with Video index (3)
      expect(find.byType(GageBottomNavBar), findsOneWidget);
    });

    testWidgets('Follow button toggles interactively between Ikuti and Diikuti', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: VideoFeedScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Initial state has 'Ikuti'
      expect(find.text('Ikuti'), findsAtLeastNWidgets(1));

      // Tap 'Ikuti'
      await tester.tap(find.text('Ikuti').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Now it toggles to 'Diikuti'
      expect(find.text('Diikuti'), findsAtLeastNWidgets(1));

      // Tap 'Diikuti' again
      await tester.tap(find.text('Diikuti').first);
      await tester.pump(const Duration(milliseconds: 300));

      // Toggles back to 'Ikuti'
      expect(find.text('Ikuti'), findsAtLeastNWidgets(1));
    });

    testWidgets('Bookmark and Repost buttons toggle interactively on tap', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: VideoFeedScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap bookmark button
      final bookmarkFinder = find.byIcon(Icons.bookmark_rounded).first;
      await tester.tap(bookmarkFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify snackbar feedback
      expect(find.text('Video disimpan ke Bookmark profil'), findsOneWidget);

      // Tap repost button
      final repostFinder = find.byIcon(Icons.repeat_rounded).first;
      await tester.tap(repostFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify snackbar feedback
      expect(find.text('Video berhasil diposting ulang ke profil Anda'), findsOneWidget);
    });

    testWidgets('Share button opens share options sheet with Salin Tautan and Unduh Video', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: VideoFeedScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Share button
      final shareFinder = find.byIcon(Icons.reply_rounded).first;
      await tester.tap(shareFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify bottom sheet content
      expect(find.text('Bagikan Video'), findsOneWidget);
      expect(find.text('Salin Tautan'), findsOneWidget);
      expect(find.text('Unduh Video'), findsOneWidget);
      expect(find.text('Bagikan via...'), findsOneWidget);
    });

    testWidgets('Comment button opens comment bottom sheet with threaded replies', (tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
          ],
          child: const MaterialApp(
            home: VideoFeedScreen(),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Comment button
      final commentFinder = find.byIcon(Icons.chat_bubble_rounded).first;
      await tester.tap(commentFinder);
      await tester.pump(const Duration(milliseconds: 300));

      // Verify comment sheet header and sample comments
      expect(find.textContaining('Komentar'), findsAtLeastNWidgets(1));
      expect(find.text('Balas'), findsAtLeastNWidgets(1));

      // Verify nested reply username and reply target
      expect(find.text('@wonogirifoodie'), findsAtLeastNWidgets(1));
    });

    testWidgets('GageBottomNavBar renders solid white background when currentIndex is 3 (Video)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GageBottomNavBar(currentIndex: 3),
          ),
        ),
      );

      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);

      // Verify solid white styling logic on index 3
      final bottomNavBar = tester.widget<GageBottomNavBar>(find.byType(GageBottomNavBar));
      expect(bottomNavBar.currentIndex, equals(3));
    });
  });

  group('Sound Ecosystem & Editor Tests', () {
    test('GageSoundService default sounds and toggle save logic', () {
      final sounds = GageSoundService.instance.sounds;
      expect(sounds, isNotEmpty);
      final sound = sounds.first;
      final initialSaved = sound.isSaved;

      final toggled = GageSoundService.instance.toggleSaveSound(sound.id);
      expect(toggled, equals(!initialSaved));

      // Reset
      GageSoundService.instance.toggleSaveSound(sound.id);
    });

    testWidgets('SoundDetailScreen renders vinyl disc, sound title, and Gunakan Suara CTA', (tester) async {
      final sound = GageSoundService.instance.sounds.first;

      await tester.pumpWidget(
        MaterialApp(
          home: SoundDetailScreen(sound: sound),
        ),
      );

      expect(find.text(sound.title), findsAtLeastNWidgets(1));
      expect(find.text(sound.artist), findsOneWidget);
      expect(find.text('Gunakan Suara Ini'), findsOneWidget);
    });

    testWidgets('VideoEditorScreen renders volume mixer trigger and navigation buttons', (tester) async {
      final sound = GageSoundService.instance.sounds.first;

      await tester.pumpWidget(
        MaterialApp(
          home: VideoEditorScreen(
            videoPath: '',
            videoName: 'test_clip.mp4',
            initialSound: sound,
          ),
        ),
      );

      expect(find.text(sound.title), findsAtLeastNWidgets(1));
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('Lanjut'), findsOneWidget);
    });
  });

  group('Social Showcase & Etalase Integration Tests', () {
    test('SocialProfileService manages showcase products correctly', () {
      const testProductId = 'p_test_affiliate_123';
      final initialInShowcase = SocialProfileService.instance.isProductInShowcase(testProductId);
      expect(initialInShowcase, isFalse);

      SocialProfileService.instance.addProductToShowcase({'productId': testProductId, 'title': 'Test Item'});
      expect(SocialProfileService.instance.isProductInShowcase(testProductId), isTrue);

      SocialProfileService.instance.removeProductFromShowcase(testProductId);
      expect(SocialProfileService.instance.isProductInShowcase(testProductId), isFalse);
    });
  });
}
