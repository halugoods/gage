import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GageMerchantApp());
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
