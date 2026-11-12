import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/main.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
  ));
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  try {
    await initializeDateFormatting('id_ID', null);
    await initializeDateFormatting('id', null);
  } catch (_) {}

  await GagePricingService.loadAdminPricingConfig();
  await FareCalculationService.loadConfig();
  GageApiClient.getPricingConfig().then((remote) {
    if (remote != null) {
      GagePricingService.applyRemoteConfig(remote);
    }
  });

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    return true;
  };

  runApp(const GageApp());
}
