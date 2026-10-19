import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/features/admin/presentation/portal_interactive_preview_screen.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:gage_app/features/admin/presentation/widgets/tariff_edit_bottom_sheet.dart';

/// Screen Pengaturan Tarif & Sistem GAGE - Tab 4
/// Didesain dengan arsitektur iOS Inset Grouped:
/// - Setiap kategori tarif disajikan dalam card ringkas yang membuka iOS Floating Bottom Sheet saat ditekan
/// - Bersih dari teks redundant / status server slop
class AdminSettingsScreen extends StatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  State<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends State<AdminSettingsScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pengaturan Tarif & Layanan',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Konfigurasi Jarak Dasar, Tarif Kendaraan & Biaya Layanan',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSectionHeader('KONFIGURASI TARIF & PENGANTARAN'),
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  // 1. Motor (GageRide)
                  _buildTariffOptionTile(
                    icon: Icons.two_wheeler_rounded,
                    iconColor: GageTheme.primary,
                    title: 'Tarif Motor (GageRide)',
                    subtitle: 'Reguler: ${GagePricingService.rideRegulerBaseKm} km awal ${currencyFormatter.format(GagePricingService.rideRegulerBase)} (+${currencyFormatter.format(GagePricingService.rideRegulerPerKm)}/km)\nHemat: ${GagePricingService.rideHematBaseKm} km awal ${currencyFormatter.format(GagePricingService.rideHematBase)} (+${currencyFormatter.format(GagePricingService.rideHematPerKm)}/km)',
                    onTap: () => TariffEditBottomSheet.show(
                      context: context,
                      category: 'motor',
                      onSaved: () => setState(() {}),
                    ),
                    isDark: isDark,
                  ),
                  const Divider(height: 1),

                  // 2. Mobil (GageCar)
                  _buildTariffOptionTile(
                    icon: Icons.directions_car_rounded,
                    iconColor: Colors.blue.shade700,
                    title: 'Tarif Mobil (GageCar)',
                    subtitle: '${GagePricingService.carBaseKm} km awal ${currencyFormatter.format(GagePricingService.carBase)} (+${currencyFormatter.format(GagePricingService.carPerKm)}/km)',
                    onTap: () => TariffEditBottomSheet.show(
                      context: context,
                      category: 'car',
                      onSaved: () => setState(() {}),
                    ),
                    isDark: isDark,
                  ),
                  const Divider(height: 1),

                  // 3. Pengantaran (Food, Shop, Tani, Send)
                  _buildTariffOptionTile(
                    icon: Icons.delivery_dining_rounded,
                    iconColor: Colors.orange.shade800,
                    title: 'Ongkir Pengantaran (Food, Shop, Send)',
                    subtitle: '${GagePricingService.deliveryBaseKm} km awal ${currencyFormatter.format(GagePricingService.deliveryBase)} (+${currencyFormatter.format(GagePricingService.deliveryPerKm)}/km)\nBonus Multi-Toko: ${currencyFormatter.format(GagePricingService.multiMerchantStopBonus)} / toko ekstra',
                    onTap: () => TariffEditBottomSheet.show(
                      context: context,
                      category: 'delivery',
                      onSaved: () => setState(() {}),
                    ),
                    isDark: isDark,
                  ),
                  const Divider(height: 1),

                  // 4. Biaya Layanan & MDR Transaksi
                  _buildTariffOptionTile(
                    icon: Icons.payments_rounded,
                    iconColor: const Color(0xFF00AA13),
                    title: 'Biaya Layanan & MDR Transaksi',
                    subtitle: 'Cashless (GagePay & QRIS): ${currencyFormatter.format(GagePricingService.adminFeeCashlessPerMerchant)}/toko\nCOD Tunai: ${currencyFormatter.format(GagePricingService.adminFeeCashCodBase)} (toko ke-1) + ${currencyFormatter.format(GagePricingService.adminFeeCashCodExtraPerMerchant)} (toko ekstra)',
                    onTap: () => TariffEditBottomSheet.show(
                      context: context,
                      category: 'service_fee',
                      onSaved: () => setState(() {}),
                    ),
                    isDark: isDark,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live App Editor Shortcut
            _buildSectionHeader('LIVE APP WYSIWYG EDITOR'),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PortalInteractivePreviewScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.devices_rounded, color: GageTheme.primary, size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Buka Live App Editor',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Pratinjau interaktif Customer, Driver & Merchant dengan in-place banner editor',
                            style: TextStyle(color: Colors.white70, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 4),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildTariffOptionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54, height: 1.35),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
