import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_printer_settings_sheet.dart';

/// Full Screen Page: Konfigurasi Printer Bluetooth Thermal & Rangkap Cetak
class MerchantPrinterSettingsScreen extends StatelessWidget {
  const MerchantPrinterSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Printer Bluetooth Thermal',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
      body: const SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 14, 16, 32),
        child: MerchantPrinterSettingsSheet(),
      ),
    );
  }
}
