import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/tabs/admin_order_radar_tab.dart';
import 'package:gage_app/features/admin/presentation/tabs/admin_financial_dashboard_tab.dart';
import 'package:gage_app/features/admin/presentation/tabs/admin_tariff_tab.dart';
import 'package:gage_app/features/admin/presentation/tabs/admin_curation_banner_tab.dart';

/// Workstation Kontrol Operasional & Portal Pemilik Usaha
/// GAGE by Halu Goods Indonesia - Unit Teritorial: GAGE Pracimantoro
/// Entrypoint: lib/main_admin.dart -> AdminRootScreen
class AdminRootScreen extends StatefulWidget {
  final int initialTabIndex;

  const AdminRootScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<AdminRootScreen> createState() => _AdminRootScreenState();
}

class _AdminRootScreenState extends State<AdminRootScreen> {
  late int _currentTabIndex;

  @override
  void initState() {
    super.initState();
    _currentTabIndex = widget.initialTabIndex;
  }

  void _onTabTapped(int index) {
    if (index == _currentTabIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentTabIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final List<Widget> tabs = const [
      AdminOrderRadarTab(),
      AdminFinancialDashboardTab(),
      AdminTariffTab(),
      AdminCurationBannerTab(),
    ];

    final List<String> tabTitles = [
      'Radar Order & Armada',
      'Dashboard Finansial & GMV',
      'Pengaturan Tarif Dinamis',
      'Kurasi Merchant & Banner',
    ];

    final List<String> tabSubtitles = [
      'Monitoring se-Kecamatan Pracimantoro',
      'Sinkron Cloudflare D1 (Take Rate 16.7%)',
      'Konfigurasi Jarak Dasar & Margin Driver',
      'Verifikasi Mitra & In-Place Banner CRUD',
    ];

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: GageTheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.security_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        tabTitles[_currentTabIndex],
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: const Color(0xFF00AA13).withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'PRACI',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF00AA13),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    tabSubtitles[_currentTabIndex],
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: tabs,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.radar_rounded,
                label: 'Radar Order',
                isDark: isDark,
                hasBadge: true,
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.account_balance_wallet_rounded,
                label: 'Finansial',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.tune_rounded,
                label: 'Tarif',
                isDark: isDark,
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.verified_user_rounded,
                label: 'Kurasi/Banner',
                isDark: isDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isDark,
    bool hasBadge = false,
  }) {
    final isSelected = _currentTabIndex == index;
    final activeColor = GageTheme.primary;
    final inactiveColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                  if (hasBadge)
                    Positioned(
                      top: -1,
                      right: -3,
                      child: Container(
                        width: 7,
                        height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE11D48),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? activeColor : inactiveColor,
                  letterSpacing: -0.1,
                ),
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
