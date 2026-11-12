import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/profile/presentation/edit_profile_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  const viewports = [
    Size(360, 640), // Compact Android (e.g., Redmi 9A / A03)
    Size(390, 844), // Standard Modern Screen
    Size(412, 915), // Wide Screen (Pixel 7 / S23+)
  ];

  group('Flutter Overflow Doctor - Multi-Resolution Suite', () {
    for (final size in viewports) {
      testWidgets('EditProfileScreen has zero overflows on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        List<String> overflowErrors = [];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('overflowed') || msg.contains('RenderFlex')) {
            overflowErrors.add(msg);
          }
          originalOnError?.call(details);
        };

        final authProvider = AuthProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
            ],
            child: const MaterialApp(
              home: EditProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(overflowErrors, isEmpty, reason: 'RenderFlex overflow occurred on EditProfileScreen on viewport $size: $overflowErrors');
      });

      testWidgets('ProfileScreen has zero overflows on ${size.width}x${size.height}', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        List<String> overflowErrors = [];
        final originalOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('overflowed') || msg.contains('RenderFlex')) {
            overflowErrors.add(msg);
          }
          originalOnError?.call(details);
        };

        final authProvider = AuthProvider();
        final walletProvider = WalletProvider();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
              ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
            ],
            child: const MaterialApp(
              home: ProfileScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        FlutterError.onError = originalOnError;
        expect(overflowErrors, isEmpty, reason: 'RenderFlex overflow occurred on ProfileScreen on viewport $size: $overflowErrors');
      });
    }
  });
}
