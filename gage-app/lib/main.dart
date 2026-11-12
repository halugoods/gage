import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/auth/presentation/login_screen.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/providers/theme_provider.dart';
import 'package:gage_app/providers/language_provider.dart';
import 'package:gage_app/core/routing/portal_routes.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/video/presentation/video_feed_screen.dart';
import 'package:gage_app/features/profile/presentation/profile_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_profile_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_root_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_root_screen.dart';
import 'package:gage_app/features/admin/presentation/admin_root_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
  } catch (_) {}

  await GagePricingService.loadAdminPricingConfig();
  await FareCalculationService.loadConfig();
  GageApiClient.getPricingConfig().then((remote) {
    if (remote != null) {
      GagePricingService.applyRemoteConfig(remote);
    }
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('CRITICAL_FLUTTER_ERROR: ${details.exceptionAsString()}');
    debugPrint(details.stack.toString());
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('CRITICAL_ASYNC_ERROR: $error');
    debugPrint(stack.toString());
    return true;
  };

  runApp(const GageApp());
}

class GageApp extends StatelessWidget {
  const GageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider(create: (_) => MerchantOrderProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Gage Pracimantoro',
            debugShowCheckedModeBanner: false,
            theme: GageTheme.lightTheme,
            darkTheme: GageTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            home: const AuthGate(),
            routes: {
              CustomerRoutes.home: (context) => const HomeScreen(),
              CustomerRoutes.orders: (context) => const OrdersScreen(),
              CustomerRoutes.promo: (context) => const PromoScreen(),
              CustomerRoutes.video: (context) => const VideoFeedScreen(),
              CustomerRoutes.profile: (context) => const ProfileScreen(),
              CustomerRoutes.checkout: (context) => const CheckoutScreen(),
              MerchantRoutes.root: (context) => const MerchantRootScreen(),
              MerchantRoutes.profile: (context) => const MerchantProfileScreen(),
              DriverRoutes.root: (context) => const _DriverPortalGuard(),
              AdminRoutes.root: (context) => const AdminRootScreen(),
            },
          );
        },
      ),
    );
  }
}

// Gerbang Autentikasi Pengguna
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.isLoading) {
      return Scaffold(
        backgroundColor: GageTheme.primary,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'GAGE',
                    style: TextStyle(
                      color: GageTheme.primary,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ],
          ),
        ),
      );
    }

    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    return const HomeScreen();
  }
}

class _DriverPortalGuard extends StatelessWidget {
  const _DriverPortalGuard();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
      ],
      child: const DriverRootScreen(),
    );
  }
}

