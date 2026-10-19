import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';

import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_screen.dart';
import 'package:gage_app/features/admin/presentation/widgets/in_place_banner_editor_sheet.dart';

/// Screen Fullscreen Live Sandbox / Interactive Preview
/// Menjalankan aplikasi native portal lain secara 100% interaktif full 1 layar penuh
/// sehingga admin dapat bebas berinteraksi, mencoba fitur, dan melihat wujud banner aktual.
class PortalInteractivePreviewScreen extends StatefulWidget {
  final String initialPortal; // 'Customer', 'Driver', 'Merchant'

  const PortalInteractivePreviewScreen({
    super.key,
    this.initialPortal = 'Customer',
  });

  @override
  State<PortalInteractivePreviewScreen> createState() => _PortalInteractivePreviewScreenState();
}

class _PortalInteractivePreviewScreenState extends State<PortalInteractivePreviewScreen> {
  late String _activePortal;
  bool _isFloatingBarVisible = true;

  @override
  void initState() {
    super.initState();
    _activePortal = widget.initialPortal;
    LiveAppEditScope.globalEditMode = true;
  }

  @override
  void dispose() {
    LiveAppEditScope.globalEditMode = false;
    super.dispose();
  }

  void _switchPortal(String newPortal) {
    HapticFeedback.mediumImpact();
    setState(() {
      _activePortal = newPortal;
    });
  }

  void _showPortalSwitcherSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final portals = [
          {
            'id': 'Customer',
            'title': 'Portal Pelanggan (Customer)',
            'desc': 'SuperApp Beranda, GAGE Food, GAGE Tani, Shop, Cart & Checkout',
            'icon': Icons.person_rounded,
            'color': GageTheme.primary,
          },
          {
            'id': 'Driver',
            'title': 'Portal Pengemudi (Driver)',
            'desc': 'GoPartner Standard, Full Peta GPS, Autobid, Radar Siaga & Tupo',
            'icon': Icons.two_wheeler_rounded,
            'color': const Color(0xFF00AA13), // Gojek Green
          },
          {
            'id': 'Merchant',
            'title': 'Portal Resto / Kios (Merchant)',
            'desc': 'Kitchen Display System (KDS), Pesanan Dapur & Printer SPP',
            'icon': Icons.storefront_rounded,
            'color': Colors.orange.shade700,
          },
        ];

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text(
                'Pilih Portal untuk Live Preview',
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                'Aplikasi akan dibuka penuh 1 screen native dan bebas diinteraksi secara aktual.',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
              ),
              const SizedBox(height: 16),
              ...portals.map((p) {
                final id = p['id'] as String;
                final isSelected = id == _activePortal;
                final color = p['color'] as Color;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.pop(ctx);
                      _switchPortal(id);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.12)
                            : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade200),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(p['icon'] as IconData, color: color, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      p['title'] as String,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13.5,
                                        color: isSelected ? color : null,
                                      ),
                                    ),
                                    if (isSelected) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'AKTIF',
                                          style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  p['desc'] as String,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.white60 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActivePortalBody() {
    switch (_activePortal) {
      case 'Driver':
        return const DriverScreen();
      case 'Merchant':
        return const MerchantScreen();
      case 'Customer':
      default:
        return const HomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Menyediakan seluruh provider yang dibutuhkan oleh portal lain agar tidak red-screen
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
        ChangeNotifierProvider(create: (_) => MultiMerchantCartService()),
        ChangeNotifierProvider(create: (_) => InAppChatProvider()),
        ChangeNotifierProvider(create: (_) => DriverOrderProvider()),
        ChangeNotifierProvider(create: (_) => DriverWalletProvider()),
        ChangeNotifierProvider.value(value: BannerManagerService.instance),
      ],
      child: Material(
        color: Colors.black,
        child: Stack(
          children: [
            // 1. LAYAR UTAMA NATIVE (FULLSCREEN 100% INTERAKTIF)
            Positioned.fill(
              key: ValueKey(_activePortal),
              child: LiveAppEditScope(
                isEditMode: true,
                child: _buildActivePortalBody(),
              ),
            ),

            // 2. FLOATING CONTROL BAR ADMIN (MINIMALIS & ELEGAN)
            if (_isFloatingBarVisible)
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    margin: const EdgeInsets.only(top: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: GageTheme.primary, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Live Pulse Dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: GageTheme.accentGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'KELOLA BANNER: $_activePortal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Tombol Ganti Portal
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _showPortalSwitcherSheet,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.swap_horiz_rounded, size: 14, color: Colors.white),
                                SizedBox(width: 4),
                                Text('Ganti', style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Tombol Sembunyikan Bar (Agar full-bleed murni)
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isFloatingBarVisible = false);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.visibility_off_rounded, size: 13, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Tombol Tutup Preview Kembali ke Admin
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              // Mini Floating Anchor jika bar disembunyikan
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticFeedback.lightImpact();
                        setState(() => _isFloatingBarVisible = true);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GageTheme.primary),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.tune_rounded, size: 12, color: Colors.white),
                            SizedBox(width: 4),
                            Text('Admin Bar', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
