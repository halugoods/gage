import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gage_app/main.dart';

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

  runApp(const GageApp());
}
