import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/profile/presentation/widgets/creator_profile_header.dart';
import 'package:gage_app/features/profile/presentation/widgets/social_showcase_grid.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/language_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GageBottomNavBar Tests', () {
    testWidgets('Renders 5 standard tabs with glassmorphic pill on standard mode', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GageBottomNavBar(currentIndex: 0, isProfileMode: false),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GageBottomNavBar), findsOneWidget);
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.byIcon(Icons.home_rounded), findsOneWidget);
      expect(find.byIcon(Icons.receipt), findsOneWidget);
    });

    testWidgets('Renders standard floating capsule in Profile Mode without split island', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            bottomNavigationBar: GageBottomNavBar(
              currentIndex: 4,
              isProfileMode: false,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(GageBottomNavBar), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
    });
  });

  group('CreatorProfileHeader and Profile Sub-Tabs Tests', () {
    testWidgets('Header renders chat icon and Buat Video buttons below bio for own profile', (tester) async {
      bool chatTapped = false;
      bool createVideoTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CreatorProfileHeader(
              displayName: 'Syams Djuhair',
              handle: '@syams.djuhair',
              avatarUrl: '',
              bio: 'Kuliner Pracimantoro',
              isOwnProfile: true,
              onChatTap: () => chatTapped = true,
              onCreateVideoTap: () => createVideoTapped = true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Syams Djuhair'), findsOneWidget);
      expect(find.text('@syams.djuhair'), findsOneWidget);
      expect(find.text('Kuliner Pracimantoro'), findsOneWidget);
      // Tombol Edit Profil di bawah bio sudah digantikan dengan Chat + Buat Video
      expect(find.text('Edit Profil'), findsNothing);
      expect(find.text('Buat Video'), findsOneWidget);
      expect(find.byIcon(Icons.chat_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.chat_rounded));
      await tester.pump();
      expect(chatTapped, isTrue);

      await tester.tap(find.text('Buat Video'));
      await tester.pump();
      expect(createVideoTapped, isTrue);
    });

    testWidgets('Renders 5 TikTok-style pure icon sub-tabs below bio in ProfileScreen', (tester) async {
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

      // Header pencil icon
      expect(find.byIcon(Icons.edit_rounded), findsOneWidget);

      // 5 pure icon sub-tabs below bio (with shopping bag for showcase)
      expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
      expect(find.byIcon(Icons.shopping_bag_rounded), findsOneWidget);
      expect(find.byIcon(Icons.repeat_rounded), findsOneWidget);
      expect(find.byIcon(Icons.bookmark_rounded), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
    });
  });

  group('SocialShowcaseGrid Tests', () {
    testWidgets('Showcase renders rich cards and navigates directly to RestoDetailScreen', (tester) async {
      final sampleProducts = [
        {
          'productId': 'p-test-01',
          'productTitle': 'Dimsum Mentai Spesial',
          'productPrice': 15000,
          'originalPrice': 20000,
          'merchantId': 'mrc-dimsum-sewu',
          'merchantName': 'Dimsum Sewu Praci',
          'merchantRating': 4.9,
          'thumbnailUrl': 'assets/images/resto_dimsum_sewu.png',
        }
      ];

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => CartProvider()),
            ChangeNotifierProvider(create: (_) => AuthProvider()),
            ChangeNotifierProvider(create: (_) => OrderProvider()),
            ChangeNotifierProvider(create: (_) => ThemeProvider()),
            ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ],
          child: MaterialApp(
            theme: GageTheme.lightTheme,
            home: Scaffold(
              body: SocialShowcaseGrid(
                products: sampleProducts,
                isOwnProfile: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // No external GAGE Cuan button
      expect(find.textContaining('Kelola produk etalase di GAGE Cuan'), findsNothing);

      // Rich card elements
      expect(find.text('Dimsum Mentai Spesial'), findsOneWidget);
      expect(find.text('Dimsum Sewu Praci'), findsOneWidget);
      expect(find.text('Rp 15.000'), findsOneWidget);
      expect(find.text('Rp 20.000'), findsOneWidget);

      // In-card 3 action icons (showcase check, share arrow, video call)
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
      expect(find.byIcon(Icons.reply_rounded), findsOneWidget);
      expect(find.byIcon(Icons.video_call_rounded), findsOneWidget);

      // Tap card navigates directly to RestoDetailScreen
      await tester.tap(find.text('Dimsum Mentai Spesial'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(RestoDetailScreen), findsOneWidget);
    });
  });
}
