import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gage_app/main.dart';

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
  ErrorWidget.builder = (FlutterErrorDetails details) {
    debugPrint('SAFE_RENDER_FALLBACK: ${details.exceptionAsString()}');
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Icon(Icons.info_outline, color: Colors.grey.shade400, size: 20),
        ),
      ),
    );
  };
  runApp(const GageApp());
}
