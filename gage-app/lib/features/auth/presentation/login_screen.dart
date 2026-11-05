import 'package:flutter/material.dart';
import 'package:gage_app/features/auth/presentation/gage_auth_screen.dart';

export 'package:gage_app/features/auth/presentation/gage_auth_screen.dart';

/// Backward-compatible alias for GageAuthScreen
class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const GageAuthScreen();
  }
}
