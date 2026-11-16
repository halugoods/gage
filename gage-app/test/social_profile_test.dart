import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/services/social_profile_service.dart';
import 'package:gage_app/core/services/gage_video_feed_service.dart';
import 'package:gage_app/data/models/user_model.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SocialProfileService Tests', () {
    test('Follow and unfollow targets correctly', () async {
      final service = SocialProfileService.instance;
      const targetCreator = '@wonogirifoodie';

      expect(service.isFollowing(targetCreator), isFalse);

      final nowFollowed = await service.toggleFollow(targetCreator);
      expect(nowFollowed, isTrue);
      expect(service.isFollowing(targetCreator), isTrue);

      final nowUnfollowed = await service.toggleFollow(targetCreator);
      expect(nowUnfollowed, isFalse);
      expect(service.isFollowing(targetCreator), isFalse);
    });

    test('Like and unlike video correctly', () async {
      final service = SocialProfileService.instance;
      const videoId = 'vid-praci-01';

      final liked = await service.toggleLikeVideo(videoId);
      expect(liked, isTrue);
      expect(service.likedVideoIds.contains(videoId), isTrue);

      final unliked = await service.toggleLikeVideo(videoId);
      expect(unliked, isFalse);
      expect(service.likedVideoIds.contains(videoId), isFalse);
    });

    test('getVideosByCreator returns videos for creator', () {
      final service = SocialProfileService.instance;
      final videos = service.getVideosByCreator('@wonogirifoodie');
      expect(videos, isNotEmpty);
    });

    test('isMerchantAccount detects merchant role properly', () {
      final service = SocialProfileService.instance;
      const customer = UserModel(id: 'c1', name: 'User', phone: '0812', role: 'customer');
      const merchant = UserModel(id: 'm1', name: 'Toko', phone: '0813', role: 'merchant');

      expect(service.isMerchantAccount(customer), isFalse);
      expect(service.isMerchantAccount(merchant), isTrue);
      expect(service.isMerchantAccount(null), isFalse);
    });

    test('updateBioAndHandle updates bio and username correctly', () async {
      final service = SocialProfileService.instance;
      await service.updateBioAndHandle(bio: 'Pecinta Sate Praci', handle: '@satelover');
      expect(service.userBio, 'Pecinta Sate Praci');
      expect(service.userHandle, 'satelover');
    });

    test('Showcase custom product add and remove', () async {
      final service = SocialProfileService.instance;
      final testProd = <String, dynamic>{
        'productId': 'test-p1',
        'productTitle': 'Sate Ayam Spesial',
        'productPrice': 20000,
        'thumbnailUrl': 'https://images.unsplash.com/photo-1544025162-d76694265947',
        'merchantId': 'm-01',
        'merchantName': 'Warung Bu Siti',
      };

      expect(service.isProductInShowcase('test-p1'), isFalse);
      await service.addProductToShowcase(testProd);
      expect(service.isProductInShowcase('test-p1'), isTrue);

      final showcaseList = service.getShowcaseProducts();
      expect(showcaseList.any((p) => p['productId'] == 'test-p1'), isTrue);

      await service.removeProductFromShowcase('test-p1');
      expect(service.isProductInShowcase('test-p1'), isFalse);
    });
  });

  group('ProfileScreen Widget Tests', () {
    testWidgets('Renders clean minimal profile header, action row, and settings menu navigation', (tester) async {
      tester.binding.window.physicalSizeTestValue = const Size(1080, 2400);
      tester.binding.window.devicePixelRatioTestValue = 1.0;
      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top Header: user handle, share icon, and 3-line menu icon
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);

      // Default tab adalah Profil (Sosmed murni tanpa card cuan)
      expect(find.text('Mengikuti'), findsOneWidget);
      expect(find.text('Pengikut'), findsOneWidget);
      expect(find.text('Suka'), findsOneWidget);
      expect(find.textContaining('Cuan'), findsNothing);
      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Buat Video'), findsOneWidget);

      // Sub-tabs tanpa count kurung
      expect(find.text('Video'), findsNWidgets(2)); // Sub-tab konten + Bottom Nav Bar
      expect(find.text('Disukai'), findsOneWidget);
      expect(find.text('Etalase'), findsOneWidget);

      // Tap 3-line menu icon ke Pengaturan
      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      // Pastikan pengaturan akun tampil & back arrow tersedia
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      expect(find.text('Keamanan & Transaksi'), findsOneWidget);
      expect(find.text('Alamat & Lokasi'), findsOneWidget);

      // Tap back arrow untuk kembali ke Profil
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();
      expect(find.text('Edit Profil'), findsOneWidget);
    });
  });
}
