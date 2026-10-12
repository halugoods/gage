import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GageDriverApp());
}

class GageDriverApp extends StatelessWidget {
  const GageDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAGE Driver',
      debugShowCheckedModeBanner: false,
      theme: GageTheme.lightTheme,
      home: const DriverScreen(),
    );
  }
}
