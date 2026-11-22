import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_profile_screen.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_chat_tab.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_marketing_tab.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_orders_tab.dart';
import 'package:gage_app/features/merchant/presentation/tabs/gage_merchant_outlet_tab.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_floating_nav_bar.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/features/notification/presentation/notification_screen.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_merchant_tier_badge.dart';

const Color _redColor = Color(0xFFDC2626);
const Color _orangeColor = Color(0xFFD97706);
const Color _greenColor = Color(0xFF16A34A);

/// Workstation Mitra Usaha GAGE (Merchant Portal)
/// Arsitektur 5-Tab Resmi:
/// 0: Pesanan (GageMerchantOrdersTab)
/// 1: Chat (GageMerchantChatTab)
/// 2: Outlet (GageMerchantOutletTab)
/// 3: Marketing (GageMerchantMarketingTab)
/// 4: GagePay (GageMerchantGagePayTab)
/// Menggunakan arsitektur Stack tanpa kontainer penampung di belakang floating frosted navbar.
class MerchantRootScreen extends StatefulWidget {
  final int initialTabIndex;

  const MerchantRootScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<MerchantRootScreen> createState() => _MerchantRootScreenState();
}

class _MerchantRootScreenState extends State<MerchantRootScreen> {
  late int _currentIndex;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MerchantOrderProvider>().fetchOrders();
    });
  }

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantOrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: _buildWorkstationHeader(context, merchant, isDark),
      body: Stack(
        children: [
          // Lapisan Utama Tab (IndexedStack dengan SafeArea)
          Positioned.fill(
            child: SafeArea(
              top: false,
              bottom: false,
              child: IndexedStack(
                index: _currentIndex,
                children: [
                  // Tab 0: Pesanan Masuk & Dapur
                  GageMerchantOrdersTab(currencyFormatter: currencyFormatter),

                  // Tab 1: Chat Mitra (1:1 Customer In-App Chat Hub)
                  const GageMerchantChatTab(),

                  // Tab 2: Outlet & Manajemen Toko (Hero Omset, 8 Grid, Star Resto, NIB)
                  GageMerchantOutletTab(
                    currencyFormatter: currencyFormatter,
                    onNavigateTab: _onTabSelected,
                  ),

                  // Tab 3: Marketing & Promosi (Promo Diskon Menu, Voucher Toko, Iklan Banner)
                  const GageMerchantMarketingTab(),

                  // Tab 4: GagePay Toko (1:1 Customer GagePayScreen: 3D Leather Pocket Wallet, 3D Flip Card, Dual Action, History)
                  const GagePayScreen(isEmbeddedInTab: true),
                ],
              ),
            ),
          ),

          // Lapisan Floating Navigation Bar (Melayang Jernih Tanpa Kontainer Belakang)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MerchantFloatingNavBar(
              currentIndex: _currentIndex,
              onTabSelected: _onTabSelected,
              newOrderCount: merchant.newOrderCount,
              unreadChatCount: 1,
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildWorkstationHeader(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    return AppBar(
      titleSpacing: 16,
      elevation: 0.5,
      backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
      foregroundColor: isDark ? Colors.white : GageTheme.textPrimary,
      title: Row(
        children: [
          // Storefront Avatar Bulat Resmi
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  width: 1.5,
                ),
              ),
              child: Image.asset(
                'assets/images/resto_dimsum_sewu.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.storefront_rounded, color: GageTheme.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),

          // Nama Kios & Dropdown Status Buka Kapsul Penuh
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Dimsum Sewu Pracimantoro',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6),
                    GageMerchantTierBadge(tier: 'star', height: 16),
                  ],
                ),
                const SizedBox(height: 2),

                // Quick Toggle Status Buka / Mode Sibuk / Tutup (Full Rounded Capsule Pill 999)
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _showStoreStatusSheet(context, merchant);
                  },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                    decoration: BoxDecoration(
                      color: merchant.isBusy
                          ? const Color(0xFFFEF3C7)
                          : (merchant.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: merchant.isBusy
                                ? _orangeColor
                                : (merchant.isOpen ? _greenColor : _redColor),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          merchant.isBusy
                              ? 'ISTIRAHAT (${merchant.busyRemainingMinutes}m)'
                              : (merchant.isOpen ? 'TOKO BUKA' : 'TOKO TUTUP'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: merchant.isBusy
                                ? _orangeColor
                                : (merchant.isOpen ? _greenColor : _redColor),
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 14,
                          color: merchant.isBusy
                              ? _orangeColor
                              : (merchant.isOpen ? _greenColor : _redColor),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lonceng Notifikasi Tunggal (1:1 Customer Clutter-Free)
          AnimatedBuilder(
            animation: NotificationService.instance,
            builder: (context, _) {
              final unread = NotificationService.instance.unreadCount;
              return IconButton(
                tooltip: 'Notifikasi',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      size: 23,
                      color: isDark ? Colors.white : GageTheme.textPrimary,
                    ),
                    if (unread > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: GageTheme.primary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.white, width: 1.2),
                          ),
                          constraints: const BoxConstraints(minWidth: 15, minHeight: 14),
                          child: Text(
                            '${unread.clamp(1, 99)}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              height: 1.05,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationScreen()),
                  );
                },
              );
            },
          ),

          // Pengaturan Kios
          IconButton(
            tooltip: 'Pengaturan Kios',
            icon: Icon(
              Icons.settings_outlined,
              size: 22,
              color: isDark ? Colors.white : GageTheme.textPrimary,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MODAL STATUS OPERASIONAL LAPAK (BUKA / MODE SIBUK / TUTUP)
// ─────────────────────────────────────────────────────────────────────────────
void _showStoreStatusSheet(BuildContext context, MerchantOrderProvider merchant) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  GageFloatingSheet.show<void>(
    context: context,
    builder: (ctx) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                'Pengaturan Status Toko',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Opsi 1: Buka Normal
          InkWell(
            onTap: () {
              merchant.toggleStoreOpen(true);
              merchant.resumeOrders();
              Navigator.of(ctx).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: merchant.isOpen && !merchant.isBusy
                    ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFDCFCE7))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: merchant.isOpen && !merchant.isBusy
                      ? const Color(0xFF16A34A)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toko Buka Normal',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Menerima semua pesanan masuk tanpa jeda',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (merchant.isOpen && !merchant.isBusy)
                    const Icon(Icons.radio_button_checked_rounded, color: Color(0xFF16A34A), size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Opsi 2: Mode Sibuk (Jeda 15 Menit)
          InkWell(
            onTap: () {
              merchant.toggleStoreOpen(true);
              merchant.pauseOrders(const Duration(minutes: 15));
              Navigator.of(ctx).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: merchant.isBusy
                    ? (isDark ? const Color(0xFF78350F) : const Color(0xFFFEF3C7))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: merchant.isBusy
                      ? const Color(0xFFD97706)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Sibuk (Jeda 15 Menit)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Dapur sedang ramai. Jeda pesanan baru sementara.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (merchant.isBusy)
                    const Icon(Icons.radio_button_checked_rounded, color: Color(0xFFD97706), size: 18),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Opsi 3: Mode Sibuk (Jeda 30 Menit)
          InkWell(
            onTap: () {
              merchant.toggleStoreOpen(true);
              merchant.pauseOrders(const Duration(minutes: 30));
              Navigator.of(ctx).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.more_time_rounded, color: Color(0xFFD97706), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode Sibuk (Jeda 30 Menit)',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Jeda pesanan 30 menit dengan auto-resume',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Opsi 4: Tutup Toko Sementara
          InkWell(
            onTap: () {
              merchant.toggleStoreOpen(false);
              Navigator.of(ctx).pop();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: !merchant.isOpen
                    ? (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEE2E2))
                    : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !merchant.isOpen
                      ? const Color(0xFFDC2626)
                      : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.block_flipped, color: Color(0xFFDC2626), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tutup Toko Sementara',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Toko tutup total dan tidak menerima pesanan apapun',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!merchant.isOpen)
                    const Icon(Icons.radio_button_checked_rounded, color: Color(0xFFDC2626), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      );
    },
  );
}
