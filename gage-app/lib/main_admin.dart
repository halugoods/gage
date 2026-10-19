import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
  } catch (_) {}

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: const GageAdminApp(),
    ),
  );
}

class GageAdminApp extends StatelessWidget {
  const GageAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAGE Admin',
      debugShowCheckedModeBanner: false,
      theme: GageTheme.lightTheme,
      darkTheme: GageTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const AdminScreen(),
    );
  }
}
