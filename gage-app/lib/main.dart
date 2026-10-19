import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/auth/presentation/login_screen.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        title: 'Gage Pracimantoro',
        debugShowCheckedModeBanner: false,
        theme: GageTheme.lightTheme,
        darkTheme: GageTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
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

