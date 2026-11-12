import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_profile_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_standalone_banner.dart';

const Color _redColor = Color(0xFFDC2626);
const Color _orangeColor = Color(0xFFD97706);
const Color _greenColor = Color(0xFF16A34A);

/// Workstation Mitra Usaha GAGE (Merchant Portal)
/// Unit: GAGE Pracimantoro - Mitra Resmi Halu Goods Indonesia
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
      body: SafeArea(
        top: false,
        child: IndexedStack(
          index: _currentIndex,
          children: [
            // Tab 1: Pesanan Masuk (Order Card Interaktif)
            _MerchantOrdersTab(currencyFormatter: currencyFormatter),

            // Tab 2: Manajemen Menu & Stok
            _MerchantMenuTab(currencyFormatter: currencyFormatter),

            // Tab 3: Pengaturan Toko
            _MerchantSettingsTab(currencyFormatter: currencyFormatter),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context, merchant, isDark),
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
          // Logo Kios Bulat
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GageTheme.primary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 22),
          ),
          const SizedBox(width: 10),
          // Nama Kios & Dropdown Status Buka
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        'Dimsum Sewu Pracimantoro',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.verified_rounded, size: 14, color: GageTheme.primary),
                  ],
                ),
                const SizedBox(height: 2),
                // Quick Toggle Status Buka / Tutup
                InkWell(
                  onTap: () {
                    merchant.toggleStoreOpen(!merchant.isOpen);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: merchant.isOpen ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: merchant.isOpen ? _greenColor : _redColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          merchant.isOpen ? 'TOKO BUKA' : 'TOKO TUTUP',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: merchant.isOpen ? _greenColor : _redColor,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.swap_horiz_rounded,
                          size: 11,
                          color: merchant.isOpen ? _greenColor : _redColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Simulasi Pesanan Masuk (Tombol Uji Alur Live)
          IconButton(
            tooltip: 'Simulasi Pesanan Baru',
            icon: const Icon(Icons.add_alert_rounded, color: GageTheme.primary, size: 22),
            onPressed: () {
              merchant.triggerMockIncomingOrder();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pesanan baru masuk ke workstation!'),
                  duration: Duration(seconds: 2),
                  backgroundColor: GageTheme.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
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
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.receipt_long_rounded,
              label: 'Pesanan Masuk',
              badgeCount: merchant.newOrderCount,
              isDark: isDark,
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.restaurant_menu_rounded,
              label: 'Menu & Stok',
              isDark: isDark,
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.storefront_rounded,
              label: 'Pengaturan Toko',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
    required bool isDark,
  }) {
    final isSelected = _currentIndex == index;
    final color = isSelected
        ? GageTheme.primary
        : (isDark ? Colors.grey.shade400 : Colors.grey.shade600);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabSelected(index),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: color, size: 24),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: _redColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          badgeCount > 99 ? '99+' : badgeCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 1: PESANAN MASUK (ORDER CARD INTERAKTIF)
// ─────────────────────────────────────────────────────────────────────────────

class _MerchantOrdersTab extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const _MerchantOrdersTab({required this.currencyFormatter});

  @override
  State<_MerchantOrdersTab> createState() => _MerchantOrdersTabState();
}

class _MerchantOrdersTabState extends State<_MerchantOrdersTab> {
  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantOrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orders = merchant.activeOrders;

    return Column(
      children: [
        // Status Bar Hardware Printer SPP & Auto-Accept
        _buildHardwareStatusBar(context, merchant, isDark),

        // Standalone Banner untuk Informasi Merchant
        const GageStandaloneBanner(
          screenTarget: 'merchant_home_info',
          margin: EdgeInsets.fromLTRB(16, 6, 16, 6),
        ),

        // Filter Stage Pesanan
        _buildStageFilterChips(context, merchant, isDark),

        // Daftar Kartu Pesanan
        Expanded(
          child: orders.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  onRefresh: () => merchant.fetchOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: orders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return _MerchantOrderCard(
                        order: order,
                        currencyFormatter: widget.currencyFormatter,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildHardwareStatusBar(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                merchant.printerConnected ? Icons.print_rounded : Icons.print_disabled_rounded,
                size: 16,
                color: merchant.printerConnected ? _greenColor : GageTheme.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                merchant.printerConnected ? 'Thermal SPP 58mm: Siap' : 'Printer Offline',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: merchant.printerConnected ? _greenColor : GageTheme.textSecondary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(
                Icons.auto_mode_rounded,
                size: 16,
                color: GageTheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                merchant.autoAccept ? 'Terima Otomatis (180s)' : 'Konfirmasi Manual',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GageTheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageFilterChips(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    final filters = [
      {'key': 'SEMUA', 'label': 'Semua', 'count': merchant.activeOrderCount},
      {'key': 'NEW', 'label': 'Pesanan Baru', 'count': merchant.newOrderCount},
      {'key': 'COOKING', 'label': 'Sedang Disiapkan', 'count': merchant.cookingOrderCount},
      {'key': 'READY_FOR_PICKUP', 'label': 'Siap Dijemput', 'count': merchant.readyOrderCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: filters.map((f) {
          final isSelected = merchant.selectedStageFilter == f['key'];
          final count = f['count'] as int;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              onSelected: (_) => merchant.setStageFilter(f['key'] as String),
              selectedColor: GageTheme.primary,
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    f['label'] as String,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.grey.shade300 : GageTheme.textPrimary),
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.white.withValues(alpha: 0.25) : GageTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: isSelected ? Colors.white : GageTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? GageTheme.primary : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 54, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'Tidak ada pesanan aktif',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pesanan masuk dari pelanggan akan tampil di sini secara real-time.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: GageTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ORDER CARD INTERAKTIF (STATUS NEW, COOKING, READY_FOR_PICKUP)
// ─────────────────────────────────────────────────────────────────────────────

class _MerchantOrderCard extends StatelessWidget {
  final OrderModel order;
  final NumberFormat currencyFormatter;

  const _MerchantOrderCard({
    required this.order,
    required this.currencyFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final merchant = context.read<MerchantOrderProvider>();
    final chatProvider = context.read<InAppChatProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: order.status == 'NEW'
              ? _orangeColor.withValues(alpha: 0.6)
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: order.status == 'NEW' ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Invoice & Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: order.channel == 'shop'
                          ? const Color(0xFFE0E7FF)
                          : GageTheme.primaryLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      order.channel == 'shop' ? 'GAGE MART' : 'GAGE FOOD',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: order.channel == 'shop'
                            ? const Color(0xFF4338CA)
                            : GageTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.orderNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              _buildStatusPill(order.status),
            ],
          ),

          const Divider(height: 16),

          // Info Pelanggan & Alamat
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.person_pin_circle_rounded, size: 18, color: GageTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'Pelanggan GAGE',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${order.deliveryAddress} • ${order.distanceKm.toStringAsFixed(1)} km',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: GageTheme.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormatter.format(order.totalAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w900,
                  fontSize: 14.5,
                  color: GageTheme.primary,
                ),
              ),
            ],
          ),

          // Catatan Khusus Pelanggan (jika ada)
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFFDE68A)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.sticky_note_2_rounded, size: 14, color: _orangeColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: ${order.notes}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Informasi Koreksi Selisih (Refund GagePay atau COD Tambahan)
          if (order.refundAmount > 0 || order.codAdjustment > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (order.refundAmount > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.replay_rounded, size: 12, color: _greenColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Refund GagePay: ${currencyFormatter.format(order.refundAmount)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _greenColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (order.refundAmount > 0 && order.codAdjustment > 0) const SizedBox(width: 6),
                if (order.codAdjustment > 0)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_card_rounded, size: 12, color: _orangeColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tagihan COD: +${currencyFormatter.format(order.codAdjustment)}',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _orangeColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],

          const SizedBox(height: 10),

          // Daftar Item Pesanan
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: List.generate(order.items.length, (i) {
                final item = order.items[i];
                return Padding(
                  padding: EdgeInsets.only(bottom: i == order.items.length - 1 ? 0 : 6),
                  child: Row(
                    children: [
                      // Checklist item (picking mode)
                      if (order.channel == 'shop') ...[
                        GestureDetector(
                          onTap: () => merchant.togglePickingItem(order.id, i),
                          child: Icon(
                            item.isPicked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            size: 16,
                            color: item.isPicked ? _greenColor : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                decoration: item.isPicked ? null : TextDecoration.lineThrough,
                              ),
                            ),
                            if (item.notes != null)
                              Text(
                                item.notes!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  color: GageTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        currencyFormatter.format(item.subtotal),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),

          // Driver info jika sudah siap dijemput
          if (order.driverName != null && order.driverName!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: GageTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.two_wheeler_rounded, size: 16, color: GageTheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Kurir: ${order.driverName} (${order.driverPlate ?? "Kurir GAGE"})',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GageTheme.primary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'PIN: ${order.orderNumber.replaceAll(RegExp(r"[^0-9]"), "").padLeft(4, "0").substring(0, 4)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ─────────────────────────────────────────────────────────────────
          // AKSI SPESIFIK BERDASARKAN STATUS PESANAN (100% WIRED)
          // ─────────────────────────────────────────────────────────────────
          if (order.status == 'NEW') ...[
            // Status Pesanan Baru: Terima Pesanan (Hijau) & Tolak Pesanan (Merah)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _redColor,
                      side: const BorderSide(color: _redColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    onPressed: () {
                      _showRejectOrderModal(context, order, merchant);
                    },
                    child: Text(
                      'Tolak Pesanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      elevation: 0,
                    ),
                    onPressed: () {
                      merchant.acceptOrder(order.id);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'Terima Pesanan',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (order.status == 'COOKING') ...[
            // Status Sedang Disiapkan:
            // 1. Hubungi Pembeli (Chat In-App native)
            // 2. Ubah Pesanan (Stok Habis) -> 3 Alur Cerdas
            // 3. Pesanan Siap (Memicu notifikasi ke kurir)
            Row(
              children: [
                // Tombol Hubungi Pembeli
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: GageTheme.primary,
                      side: const BorderSide(color: GageTheme.primary, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InAppChatScreen(
                            orderId: order.id,
                            recipientName: order.customerName ?? 'Pelanggan GAGE',
                            recipientRole: 'customer',
                            recipientPhone: order.customerPhone ?? '081226001000',
                            currentRole: 'merchant',
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.chat_bubble_rounded, size: 15),
                        const SizedBox(width: 5),
                        Text(
                          'Hubungi',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Ubah Pesanan (Stok Habis)
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _orangeColor,
                      side: const BorderSide(color: _orangeColor, width: 1.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      _showModifyOrderStockOutModal(context, order, merchant, chatProvider);
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.edit_note_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Ubah Stok',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Tombol Pesanan Siap (Memicu Notifikasi Kurir)
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _greenColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    onPressed: () {
                      merchant.markReadyForPickup(order.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Notifikasi dikirim ke kurir: Pesanan siap diambil!'),
                          backgroundColor: _greenColor,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_rounded, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Siap',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (order.status == 'READY_FOR_PICKUP') ...[
            // Status Siap Dijemput
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.delivery_dining_rounded, size: 18),
                label: Text(
                  'Serahkan ke Kurir & Selesaikan',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  merchant.completeOrder(order.id);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'NEW':
        bg = const Color(0xFFFEF3C7);
        fg = _orangeColor;
        label = 'Pesanan Baru';
        break;
      case 'COOKING':
        bg = const Color(0xFFDBEAFE);
        fg = const Color(0xFF1D4ED8);
        label = 'Sedang Disiapkan';
        break;
      case 'READY_FOR_PICKUP':
        bg = const Color(0xFFDCFCE7);
        fg = _greenColor;
        label = 'Siap Dijemput';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFE2E8F0);
        fg = const Color(0xFF475569);
        label = 'Selesai';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFFEE2E2);
        fg = _redColor;
        label = 'Dibatalkan';
        break;
      default:
        bg = const Color(0xFFF1F5F9);
        fg = const Color(0xFF64748B);
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODAL TOLAK PESANAN (DENGAN PILIHAN ALASAN & PENALTI POIN PENERIMAAN)
  // ─────────────────────────────────────────────────────────────────────────
  void _showRejectOrderModal(BuildContext context, OrderModel order, MerchantOrderProvider merchant) {
    String selectedReason = 'Bahan baku / stok menu habis';
    final reasons = [
      'Bahan baku / stok menu habis',
      'Dapur / antrian sedang sangat padat (overload)',
      'Toko sudah tutup / persiapan tutup lebih awal',
      'Kendala teknis (mati listrik / gas habis)',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final projectedScore = (merchant.acceptanceScore - 5.0).clamp(0.0, 100.0);

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _redColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.warning_amber_rounded, color: _redColor, size: 22),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Konfirmasi Tolak Pesanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Kotak Peringatan Penalti Penerimaan
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.trending_down_rounded, color: _redColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Konsekuensi Penalti Poin Penerimaan',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                                color: _redColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Menolak pesanan akan mengurangi Tingkat Penerimaan Mitra sebesar -5% (${merchant.acceptanceScore}% -> ${projectedScore.toStringAsFixed(1)}%). Skor di bawah 85% dapat membatasi alokasi pesanan otomatis.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: const Color(0xFF7F1D1D),
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),
                  Text(
                    'Pilih Alasan Penolakan:',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 6),

                  ...reasons.map((r) {
                    final isSel = selectedReason == r;
                    return InkWell(
                      onTap: () => setModalState(() => selectedReason = r),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSel ? _redColor : Colors.grey.shade400,
                                  width: isSel ? 5 : 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                r,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _redColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        merchant.rejectOrder(order.id, selectedReason);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Pesanan ditolak: "$selectedReason". Dana pelanggan di-refund penuh.'),
                            backgroundColor: _redColor,
                          ),
                        );
                      },
                      child: Text(
                        'Konfirmasi Tolak & Terima Penalti',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODAL 3 ALUR CERDAS: UBAH PESANAN (STOK HABIS)
  // ─────────────────────────────────────────────────────────────────────────
  void _showModifyOrderStockOutModal(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider merchant,
    InAppChatProvider chatProvider,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.rule_rounded, color: _orangeColor, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Ubah Pesanan (Stok Habis)',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Pilih salah satu dari 3 alur cerdas operasional GAGE Pracimantoro:',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: GageTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),

              // ALUR 1: GANTI ITEM
              _buildSmartFlowOptionCard(
                icon: Icons.published_with_changes_rounded,
                iconColor: GageTheme.primary,
                title: '1. Ganti Item (Substitusi Menu)',
                subtitle: 'Selisih lebih murah refund instan ke GagePay | Lebih mahal otomatis jadi tagihan COD ke kurir.',
                onTap: () {
                  Navigator.pop(ctx);
                  _showSubstituteItemDialog(context, order, merchant, chatProvider);
                },
              ),

              const SizedBox(height: 10),

              // ALUR 2: KIRIM YANG READY SAJA
              _buildSmartFlowOptionCard(
                icon: Icons.playlist_remove_rounded,
                iconColor: _orangeColor,
                title: '2. Kirim yang Ready Saja',
                subtitle: 'Nilai barang kosong refund instan ke GagePay, nota terkoreksi otomatis tanpa membatalkan order.',
                onTap: () {
                  Navigator.pop(ctx);
                  _showPartialFulfillDialog(context, order, merchant, chatProvider);
                },
              ),

              const SizedBox(height: 10),

              // ALUR 3: BATALKAN SELURUH PESANAN
              _buildSmartFlowOptionCard(
                icon: Icons.cancel_outlined,
                iconColor: _redColor,
                title: '3. Batalkan Seluruh Pesanan',
                subtitle: 'Refund 100% total transaksi ke saldo GagePay pelanggan & notifikasi otomatis.',
                onTap: () {
                  Navigator.pop(ctx);
                  _showFullCancellationDialog(context, order, merchant, chatProvider);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSmartFlowOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: GageTheme.textSecondary,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // DIALOG ALUR 1: GANTI ITEM
  void _showSubstituteItemDialog(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider merchant,
    InAppChatProvider chatProvider,
  ) {
    int selectedIndex = 0;
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();

    // Default item pengganti dari katalog Dimsum Sewu
    final suggestions = [
      {'name': 'Dimsum Mozzarella Keju Lumer (4 pcs)', 'price': 18000},
      {'name': 'Siomay Udang Spesial (4 pcs)', 'price': 16000},
      {'name': 'Lumpia Kulit Tahu Crispy', 'price': 12000},
      {'name': 'Es Teh Manis Jumbo 22oz', 'price': 3000},
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final origItem = order.items[selectedIndex];
            final replacementPrice = int.tryParse(priceCtrl.text) ?? 0;
            final origTotal = origItem.price * origItem.quantity;
            final newTotal = replacementPrice * origItem.quantity;
            final diff = replacementPrice > 0 ? (newTotal - origTotal) : 0;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Alur 1: Ganti Item Pesanan',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Pilih item yang stoknya habis:',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      initialValue: selectedIndex,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      items: List.generate(order.items.length, (idx) {
                        final it = order.items[idx];
                        return DropdownMenuItem(
                          value: idx,
                          child: Text(
                            '${it.name} (${currencyFormatter.format(it.price)})',
                            style: const TextStyle(fontSize: 12),
                          ),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => selectedIndex = val);
                      },
                    ),

                    const SizedBox(height: 12),
                    Text(
                      'Pilihan Menu Pengganti Siap:',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: suggestions.map((s) {
                        return ActionChip(
                          label: Text('${s["name"]} (${currencyFormatter.format(s["price"])})', style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setDialogState(() {
                              nameCtrl.text = s['name'] as String;
                              priceCtrl.text = (s['price'] as int).toString();
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 12),
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Menu Pengganti',
                        hintText: 'Misal: Dimsum Mozzarella Lumer',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: priceCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Harga Baru Per Porsi',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),

                    if (replacementPrice > 0) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: diff < 0 ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: diff < 0 ? const Color(0xFF86EFAC) : const Color(0xFFFDE68A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              diff < 0
                                  ? 'Lebih Murah (Refund Instan ke GagePay):'
                                  : (diff > 0 ? 'Lebih Mahal (Tagihan COD ke Kurir):' : 'Harga Sama:'),
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: diff < 0 ? _greenColor : _orangeColor,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              diff < 0
                                  ? 'Pelanggan menerima pengembalian instan ${currencyFormatter.format(-diff)} ke saldo GagePay.'
                                  : (diff > 0
                                      ? 'Kurir akan menagih tambahan COD sebesar ${currencyFormatter.format(diff)} saat tiba di alamat pelanggan.'
                                      : 'Tidak ada perubahan total nominal.'),
                              style: TextStyle(
                                fontSize: 11,
                                color: diff < 0 ? const Color(0xFF14532D) : const Color(0xFF78350F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: nameCtrl.text.trim().isEmpty || replacementPrice <= 0
                            ? null
                            : () async {
                                final newName = nameCtrl.text.trim();
                                Navigator.pop(ctx);
                                await merchant.substituteOrderItem(
                                  orderId: order.id,
                                  itemIndex: selectedIndex,
                                  newItemName: newName,
                                  newItemPrice: replacementPrice,
                                  chatProvider: chatProvider,
                                );
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Item berhasil diganti ke "$newName". Notifikasi dikirim ke pembeli.'),
                                    backgroundColor: _greenColor,
                                  ),
                                );
                              },
                        child: Text(
                          'Simpan Perubahan & Notifikasi Pembeli',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // DIALOG ALUR 2: KIRIM YANG READY SAJA
  void _showPartialFulfillDialog(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider merchant,
    InAppChatProvider chatProvider,
  ) {
    final List<int> oosIndices = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            int refundSum = 0;
            for (final idx in oosIndices) {
              refundSum += order.items[idx].subtotal;
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alur 2: Kirim yang Ready Saja',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Centang item yang STOKNYA HABIS untuk di-refund instan ke GagePay pembeli:',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      color: GageTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...List.generate(order.items.length, (i) {
                    final it = order.items[i];
                    final isOOS = oosIndices.contains(i);

                    return InkWell(
                      onTap: () {
                        setDialogState(() {
                          if (isOOS) {
                            oosIndices.remove(i);
                          } else {
                            oosIndices.add(i);
                          }
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: isOOS,
                              activeColor: _redColor,
                              onChanged: (val) {
                                setDialogState(() {
                                  if (val == true) {
                                    oosIndices.add(i);
                                  } else {
                                    oosIndices.remove(i);
                                  }
                                });
                              },
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    it.name,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isOOS ? FontWeight.w800 : FontWeight.w600,
                                      color: isOOS ? _redColor : GageTheme.textPrimary,
                                      decoration: isOOS ? TextDecoration.lineThrough : null,
                                    ),
                                  ),
                                  Text(
                                    '${it.quantity}x @ ${currencyFormatter.format(it.price)} = ${currencyFormatter.format(it.subtotal)}',
                                    style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),

                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Refund Instan GagePay:',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          currencyFormatter.format(refundSum),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: _greenColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: oosIndices.isEmpty
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              await merchant.fulfillPartialOrder(
                                orderId: order.id,
                                outOfStockItemIndices: oosIndices,
                                chatProvider: chatProvider,
                              );
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Nota terkoreksi otomatis! Saldo ${currencyFormatter.format(refundSum)} di-refund ke GagePay pembeli.'),
                                  backgroundColor: _greenColor,
                                ),
                              );
                            },
                      child: Text(
                        'Konfirmasi Kirim Ready & Refund Selisih',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // DIALOG ALUR 3: BATALKAN SELURUH PESANAN (REFUND 100%)
  void _showFullCancellationDialog(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider merchant,
    InAppChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.cancel_outlined, color: _redColor),
              SizedBox(width: 8),
              Text('Batalkan Seluruh Pesanan?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pesanan ${order.orderNumber} akan dibatalkan 100% dan seluruh dana sebesar ${currencyFormatter.format(order.totalAmount)} langsung dikembalikan ke saldo GagePay pelanggan.',
                style: const TextStyle(fontSize: 12, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: _redColor),
              onPressed: () async {
                Navigator.pop(ctx);
                await merchant.cancelOrderWithFullRefund(
                  orderId: order.id,
                  reason: 'Seluruh stok bahan baku habis',
                  chatProvider: chatProvider,
                );
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Pesanan dibatalkan & dana 100% di-refund ke GagePay pelanggan.'),
                    backgroundColor: _redColor,
                  ),
                );
              },
              child: const Text('Batalkan & Refund 100%'),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 2: MANAJEMEN MENU & STOK + KALKULATOR MARKUP OTOMATIS
// ─────────────────────────────────────────────────────────────────────────────

class _MerchantMenuTab extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const _MerchantMenuTab({required this.currencyFormatter});

  @override
  State<_MerchantMenuTab> createState() => _MerchantMenuTabState();
}

class _MerchantMenuTabState extends State<_MerchantMenuTab> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _menuCatalog = [];
  String _selectedCategory = 'Semua';
  String _searchQuery = '';

  final List<String> _categories = [
    'Semua',
    'Dimsum Kukus',
    'Dimsum Goreng',
    'Minuman',
    'Paket Hemat',
  ];

  @override
  void initState() {
    super.initState();
    _fetchMenuCatalog();
  }

  Future<void> _fetchMenuCatalog() async {
    setState(() => _isLoading = true);
    final menus = await GageApiClient.getMerchantMenu('m-dimsum-sewu');
    if (!mounted) return;
    setState(() {
      _menuCatalog = menus;
      _isLoading = false;
    });
  }

  Future<void> _toggleStock(Map<String, dynamic> item) async {
    HapticFeedback.lightImpact();
    final itemId = item['id']?.toString() ?? '';
    final current = (item['is_available'] == 1 || item['is_available'] == true);
    final next = !current;
    setState(() {
      item['is_available'] = next ? 1 : 0;
    });
    await GageApiClient.toggleMerchantStock(itemId, next);
  }

  List<Map<String, dynamic>> get _filteredMenus {
    return _menuCatalog.where((item) {
      final name = (item['name'] ?? '').toString().toLowerCase();
      final cat = (item['category'] ?? '').toString();
      final matchesSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchesCat = _selectedCategory == 'Semua' || cat.toLowerCase().contains(_selectedCategory.toLowerCase());
      return matchesSearch && matchesCat;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Action Bar: Kalkulator Markup & Tambah Menu
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.calculate_rounded, size: 18),
                  label: Text(
                    'Kalkulator Markup Komisi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  onPressed: () {
                    _showMarkupCalculatorDialog(context);
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF334155) : Colors.white,
                  foregroundColor: isDark ? Colors.white : GageTheme.textPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: isDark ? Colors.transparent : Colors.grey.shade300),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  elevation: 0,
                ),
                icon: const Icon(Icons.add_rounded, size: 18, color: GageTheme.primary),
                label: Text(
                  'Tambah Menu',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                onPressed: () {
                  _showAddMenuDialog(context);
                },
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            decoration: InputDecoration(
              hintText: 'Cari nama menu atau minuman...',
              hintStyle: const TextStyle(fontSize: 12.5),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
              ),
            ),
          ),
        ),

        // Filter Kategori
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: _categories.map((c) {
              final isSel = _selectedCategory == c;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: isSel,
                  onSelected: (_) => setState(() => _selectedCategory = c),
                  selectedColor: GageTheme.primary,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  label: Text(
                    c,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : GageTheme.textPrimary),
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSel ? GageTheme.primary : (isDark ? const Color(0xFF334155) : Colors.grey.shade300),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        // Daftar Menu
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _filteredMenus.isEmpty
                  ? Center(
                      child: Text(
                        'Tidak ada menu ditemukan',
                        style: GoogleFonts.plusJakartaSans(color: GageTheme.textSecondary),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchMenuCatalog,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: _filteredMenus.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = _filteredMenus[index];
                          final isAvailable = (item['is_available'] == 1 || item['is_available'] == true);
                          final offlinePrice = (item['offline_price'] ?? item['price'] ?? 0) is num
                              ? (item['offline_price'] ?? item['price'] ?? 0).toInt()
                              : int.tryParse((item['offline_price'] ?? item['price'] ?? 0).toString()) ?? 0;
                          final gagePrice = (item['gage_price'] ?? item['price'] ?? 0) is num
                              ? (item['gage_price'] ?? item['price'] ?? 0).toInt()
                              : int.tryParse((item['gage_price'] ?? item['price'] ?? 0).toString()) ?? 0;

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              children: [
                                // Thumbnail / Icon Menu
                                Container(
                                  width: 52,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    color: GageTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.fastfood_rounded, color: GageTheme.primary, size: 26),
                                ),
                                const SizedBox(width: 12),
                                // Detail Nama & Harga
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name']?.toString() ?? 'Menu Dapur',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Harga Asli Warung: ${widget.currencyFormatter.format(offlinePrice)}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: GageTheme.textSecondary,
                                        ),
                                      ),
                                      Row(
                                        children: [
                                          Text(
                                            'Harga GAGE: ${widget.currencyFormatter.format(gagePrice)}',
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w800,
                                              color: GageTheme.primary,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: isAvailable ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              isAvailable ? 'TERSEDIA' : 'HABIS',
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w900,
                                                color: isAvailable ? _greenColor : _redColor,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Toggle Cepat "Tersedia / Stok Habis"
                                Switch.adaptive(
                                  value: isAvailable,
                                  activeTrackColor: _greenColor,
                                  onChanged: (_) => _toggleStock(item),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MODAL KALKULATOR MARKUP OTOMATIS:
  // CEIL((Harga Asli / 0.90) / 500) * 500
  // ─────────────────────────────────────────────────────────────────────────
  void _showMarkupCalculatorDialog(BuildContext context) {
    int originalPrice = 12000;
    final calcCtrl = TextEditingController(text: '12000');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setCalcState) {
            final gagePrice = MerchantOrderProvider.calculateMarkupPrice(originalPrice);
            final commission = (gagePrice * 0.10).round();
            final netPayout = gagePrice - commission;
            final surplus = netPayout - originalPrice;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.calculate_rounded, color: GageTheme.primary, size: 24),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kalkulator Markup Otomatis GAGE',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              'Formula: CEIL((Harga Asli / 0.90) / 500) * 500',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                color: GageTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: calcCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Masukkan Harga Asli Warung (Offline)',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onChanged: (val) {
                        setCalcState(() {
                          originalPrice = int.tryParse(val) ?? 0;
                        });
                      },
                    ),

                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      children: [10000, 12000, 15000, 20000, 25000].map((p) {
                        return ActionChip(
                          label: Text(widget.currencyFormatter.format(p), style: const TextStyle(fontSize: 11)),
                          onPressed: () {
                            setCalcState(() {
                              originalPrice = p;
                              calcCtrl.text = p.toString();
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),

                    // Rincian Breakdown Transparansi
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        children: [
                          _buildCalcRow('Harga Asli Warung:', widget.currencyFormatter.format(originalPrice)),
                          const Divider(height: 12),
                          _buildCalcRow('Harga Jual di Aplikasi GAGE:', widget.currencyFormatter.format(gagePrice), isBold: true, highlightColor: GageTheme.primary),
                          const SizedBox(height: 4),
                          _buildCalcRow('Potongan Komisi Platform (10%):', '- ${widget.currencyFormatter.format(commission)}', color: _redColor),
                          const Divider(height: 12),
                          _buildCalcRow('Penerimaan Bersih Warung:', widget.currencyFormatter.format(netPayout), isBold: true, color: _greenColor),
                          if (surplus >= 0) ...[
                            const SizedBox(height: 4),
                            _buildCalcRow('Selisih Surplus Mitra:', '+ ${widget.currencyFormatter.format(surplus)}', color: _greenColor),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.shield_rounded, size: 16, color: _greenColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Jaminan 100% Aman: Warung tidak nombok sepeserpun karena pembulatan ke atas kelipatan Rp 500.',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: _greenColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _showAddMenuDialog(context, initialPrice: originalPrice);
                        },
                        child: Text(
                          'Terapkan Harga Ini ke Menu Baru',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCalcRow(String title, String value, {bool isBold = false, Color? color, Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: color ?? GageTheme.textPrimary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: highlightColor ?? color ?? GageTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // MODAL TAMBAH MENU BARU
  void _showAddMenuDialog(BuildContext context, {int initialPrice = 0}) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController(text: initialPrice > 0 ? initialPrice.toString() : '');
    String category = 'Dimsum Kukus';
    int offlinePrice = initialPrice;
    int suggestedGage = MerchantOrderProvider.calculateMarkupPrice(initialPrice);
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tambah Menu Baru Dapur',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Harga jual di aplikasi dihitung otomatis dengan formula resmi GAGE.',
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nama Menu',
                    hintText: 'Misal: Dimsum Mozzarella Keju Lumer',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  decoration: InputDecoration(
                    labelText: 'Deskripsi Singkat',
                    hintText: 'Bahan, porsi isi berapa biji, atau level pedas',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: category,
                        decoration: InputDecoration(
                          labelText: 'Kategori',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: _categories
                            .where((c) => c != 'Semua')
                            .map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 12))))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: priceCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Warung',
                          prefixText: 'Rp ',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) {
                          final num = int.tryParse(val) ?? 0;
                          setModalState(() {
                            offlinePrice = num;
                            suggestedGage = MerchantOrderProvider.calculateMarkupPrice(num);
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (suggestedGage > 0) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GageTheme.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: GageTheme.primary.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga Jual GAGE (Potong 10% Aman):',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Pembulatan kelipatan 500 ke atas.',
                              style: TextStyle(fontSize: 10, color: GageTheme.textSecondary),
                            ),
                          ],
                        ),
                        Text(
                          widget.currencyFormatter.format(suggestedGage),
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final messenger = ScaffoldMessenger.of(context);
                            final navigator = Navigator.of(ctx);
                            final name = nameCtrl.text.trim();
                            if (name.isEmpty || offlinePrice <= 0) {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Nama menu dan harga warung wajib diisi.')),
                              );
                              return;
                            }
                            setModalState(() => isSubmitting = true);
                            final res = await GageApiClient.createMerchantMenu(
                              merchantId: 'm-dimsum-sewu',
                              name: name,
                              description: descCtrl.text.trim(),
                              category: category,
                              offlinePrice: offlinePrice,
                              gagePrice: suggestedGage,
                            );
                            if (!mounted) return;
                            navigator.pop();
                            if (res != null) {
                              messenger.showSnackBar(
                                const SnackBar(
                                  content: Text('Menu berhasil ditambahkan ke katalog.'),
                                  backgroundColor: _greenColor,
                                ),
                              );
                              _fetchMenuCatalog();
                            } else {
                              messenger.showSnackBar(
                                const SnackBar(content: Text('Gagal menambahkan menu ke server.')),
                              );
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Simpan Menu Baru', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB 3: PENGATURAN TOKO (BUKA/TUTUP TOKO INSTAN, OPERASIONAL & PERFORMA)
// ─────────────────────────────────────────────────────────────────────────────

class _MerchantSettingsTab extends StatelessWidget {
  final NumberFormat currencyFormatter;

  const _MerchantSettingsTab({required this.currencyFormatter});

  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantOrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. HERO CARD: BUKA / TUTUP TOKO INSTAN
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: merchant.isOpen
                ? (isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5))
                : (isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFEF2F2)),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: merchant.isOpen ? const Color(0xFF34D399) : const Color(0xFFF87171),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: merchant.isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                ),
                child: Icon(
                  merchant.isOpen ? Icons.store_rounded : Icons.store_mall_directory_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant.isOpen ? 'LAPAK SEDANG BUKA' : 'LAPAK SEDANG TUTUP',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: merchant.isOpen ? const Color(0xFF065F46) : const Color(0xFF991B1B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      merchant.isOpen
                          ? 'Siap menerima pesanan masuk dari pelanggan Pracimantoro.'
                          : 'Lapak tidak akan menerima pesanan baru sampai dibuka kembali.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: merchant.isOpen ? const Color(0xFF047857) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: merchant.isOpen,
                activeTrackColor: const Color(0xFF10B981),
                inactiveThumbColor: const Color(0xFFEF4444),
                onChanged: (val) {
                  merchant.toggleStoreOpen(val);
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 2. KARTU POIN PERFORMA & TINGKAT PENERIMAAN MITRA
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.stars_rounded, color: GageTheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Performa & Penerimaan Pesanan',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: _greenColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${merchant.acceptanceScore}%',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: _greenColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatTile('Diterima Hari Ini', '${merchant.dailyAcceptedCount} order', _greenColor),
                  const SizedBox(width: 10),
                  _buildStatTile('Ditolak Hari Ini', '${merchant.dailyRejectedCount} order', _redColor),
                  const SizedBox(width: 10),
                  _buildStatTile('Waktu Masak', '${merchant.cookingTime} Menit', GageTheme.primary),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 3. FITUR OPERASIONAL (AUTO-ACCEPT, PRINTER THERMAL, ESTIMASI WAKTU)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preferensi Otomatisasi Kios',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),

              // Auto Accept Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Terima Pesanan Otomatis (Auto-Accept)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Pesanan baru otomatis diterima setelah hitung mundur 180 detik.',
                          style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: merchant.autoAccept,
                    activeTrackColor: GageTheme.primary,
                    onChanged: (val) => merchant.toggleAutoAccept(val),
                  ),
                ],
              ),

              const Divider(height: 14),

              // Printer SPP Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Thermal Printer Bluetooth (SPP 58mm)',
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Cetak struk dapur & picking otomatis saat pesanan diterima.',
                          style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: merchant.printerConnected,
                    activeTrackColor: _greenColor,
                    onChanged: (val) => merchant.togglePrinter(val),
                  ),
                ],
              ),

              const Divider(height: 14),

              // Slider Waktu Masak
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Waktu Persiapan Masak',
                        style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700),
                      ),
                      const Text(
                        'Membantu kurir memperkirakan waktu penjemputan.',
                        style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                      ),
                    ],
                  ),
                  DropdownButton<int>(
                    value: merchant.cookingTime,
                    items: [10, 15, 20, 25, 30].map((m) {
                      return DropdownMenuItem(value: m, child: Text('$m Menit', style: const TextStyle(fontSize: 12)));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) merchant.setCookingTime(val);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // 4. INFORMASI OUTLET & PUSAT BANTUAN
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Identitas Mitra GAGE',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 13.5,
                ),
              ),
              const SizedBox(height: 10),
              _buildInfoRow('Nama Lapak', 'Dimsum Sewu Pracimantoro'),
              _buildInfoRow('Alamat', 'Jl. Raya Pracimantoro No. 14, Depan Pasar'),
              const _LiveMerchantScheduleInfoRow(),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: GageTheme.primary,
                  side: const BorderSide(color: GageTheme.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  minimumSize: const Size(double.infinity, 40),
                ),
                icon: const Icon(Icons.storefront_rounded, size: 17),
                label: const Text('Kelola Jam Buka, Foto Lapak & Pin Peta', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MerchantProfileScreen()),
                  );
                },
              ),
              _buildInfoRow('Unit Wilayah', 'GAGE Pracimantoro - Wonogiri Selatan'),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.headset_mic_rounded, size: 18),
                  label: const Text('Hubungi Support GAGE Pracimantoro (WhatsApp)'),
                  onPressed: () async {
                    final uri = Uri.parse('https://wa.me/6281226001000?text=Halo%20Tim%20GAGE%20Pracimantoro,%20saya%20Mitra%20Dimsum%20Sewu');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w900, color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              title,
              style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}


class _LiveMerchantScheduleInfoRow extends StatefulWidget {
  const _LiveMerchantScheduleInfoRow();

  @override
  State<_LiveMerchantScheduleInfoRow> createState() => _LiveMerchantScheduleInfoRowState();
}

class _LiveMerchantScheduleInfoRowState extends State<_LiveMerchantScheduleInfoRow> {
  MerchantOperatingSchedule _schedule = MerchantOperatingSchedule.defaults();
  MerchantStorefrontData? _stored;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final stored = await MerchantStorefrontService.loadStorefront(
      MerchantStorefrontService.defaultPortalMerchantId,
    );
    if (!mounted) return;
    setState(() {
      _stored = stored;
      if (stored?.schedule != null) _schedule = stored!.schedule!;
    });
  }

  Future<void> _edit() async {
    final updated = await showOperatingScheduleEditorSheet(
      context: context,
      initialSchedule: _schedule,
    );
    if (updated != null && mounted) {
      setState(() => _schedule = updated);
      await MerchantStorefrontService.saveStorefront(
        (_stored ?? const MerchantStorefrontData(merchantId: MerchantStorefrontService.defaultPortalMerchantId))
            .copyWith(schedule: updated),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _edit,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              width: 110,
              child: Text(
                'Jam Operasional',
                style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
              ),
            ),
            Expanded(
              child: Text(
                _schedule.portalSubtitle(),
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: GageTheme.primary),
              ),
            ),
            const Icon(Icons.edit_rounded, size: 14, color: GageTheme.primary),
          ],
        ),
      ),
    );
  }
}
