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
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/auth/presentation/login_screen.dart';

void main() {
  final viewports = [
    const Size(360, 640), // Compact
    const Size(390, 844), // Standard
    const Size(411, 1005), // Flip 3
  ];

  Widget wrapWithProviders(Widget child) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  final screens = <String, Widget Function()>{
    'HomeScreen': () => const HomeScreen(),
    'OrdersScreen': () => const OrdersScreen(),
    'PromoScreen': () => const PromoScreen(),
    'ProfileScreen': () => const ProfileScreen(),
    'LoginScreen': () => const LoginScreen(),
  };

  for (final entry in screens.entries) {
    for (final size in viewports) {
      testWidgets('Scan ${entry.key} on ${size.width.toInt()}x${size.height.toInt()} for overflows', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final List<String> overflows = [];
        final previousOnError = FlutterError.onError;
        FlutterError.onError = (details) {
          final msg = details.exceptionAsString();
          if (msg.contains('overflowed') || msg.contains('RenderFlex') || msg.contains('unbounded')) {
            overflows.add(msg);
            debugPrint('⚠️ OVERFLOW FOUND on ${entry.key} [${size.width.toInt()}x${size.height.toInt()}]:\n$details');
          }
        };

        try {
          await tester.pumpWidget(wrapWithProviders(entry.value()));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
        } finally {
          FlutterError.onError = previousOnError;
        }

        if (overflows.isNotEmpty) {
          debugPrint('❌ Total ${overflows.length} overflows on ${entry.key} (${size.width.toInt()}x${size.height.toInt()})');
        }
      });
    }
  }
}
