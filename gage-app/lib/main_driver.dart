import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';

import 'package:gage_app/core/services/banner_manager_service.dart';

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

  runApp(const GageDriverApp());
}

class GageDriverApp extends StatelessWidget {
  const GageDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: MaterialApp(
        title: 'GAGE Driver',
        debugShowCheckedModeBanner: false,
        theme: GageTheme.lightTheme,
        darkTheme: GageTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const DriverScreen(),
      ),
    );
  }
}
