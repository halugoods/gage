import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/merchant/presentation/merchant_screen.dart';

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
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: const GageMerchantApp(),
    ),
  );
}

class GageMerchantApp extends StatelessWidget {
  const GageMerchantApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAGE Merchant',
      debugShowCheckedModeBanner: false,
      theme: GageTheme.lightTheme,
      home: const MerchantScreen(),
    );
  }
}
