import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/admin_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const GageAdminApp());
}

class GageAdminApp extends StatelessWidget {
  const GageAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAGE Admin',
      debugShowCheckedModeBanner: false,
      theme: GageTheme.lightTheme,
      home: const AdminScreen(),
    );
  }
}
