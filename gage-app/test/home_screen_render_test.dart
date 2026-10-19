import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';

void main() {
  testWidgets('HomeScreen renders without crashing', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
          ChangeNotifierProvider.value(value: BannerManagerService.instance),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(GageBottomNavBar), findsOneWidget);
  });

  testWidgets('HomeScreen positions GageBottomNavBar at bottom on Flip3 (411x1005)', (tester) async {
    tester.view.physicalSize = const Size(1080, 2640);
    tester.view.devicePixelRatio = 2.625; // 420 dpi
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
          ChangeNotifierProvider(create: (_) => WalletProvider()),
          ChangeNotifierProvider(create: (_) => CartProvider()),
          ChangeNotifierProvider(create: (_) => OrderProvider()),
          ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
          ChangeNotifierProvider.value(value: BannerManagerService.instance),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final navHome = tester.getCenter(find.text('Beranda'));
    debugPrint('*** NAV HOME POSITION ON FLIP3: Y=${navHome.dy} (screen height is 1005.7) ***');
    expect(navHome.dy, greaterThan(900.0));
  });
}
