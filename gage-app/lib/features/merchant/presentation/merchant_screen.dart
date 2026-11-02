import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_standalone_banner.dart';

/// Screen Utama GAGE Merchant (Pesanan & Kitchen Display System)
/// Mengadopsi arsitektur GoBiz (GoFood & GoMart) dengan standar desain
/// Full-Custom kesukaan user yang identik dengan Portal Customer GAGE.
class MerchantScreen extends StatefulWidget {
  const MerchantScreen({super.key});

  @override
  State<MerchantScreen> createState() => _MerchantScreenState();
}

class _MerchantScreenState extends State<MerchantScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MerchantOrderProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final merchant = context.watch<MerchantOrderProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      appBar: _buildCustomHeader(context, merchant, isDark),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Sub-header: Hardware Printer SPP status & Auto-Accept indicator
            _buildPrinterAndStatusBar(context, merchant, isDark),

            // Banner Standalone Toko (Managed via Cloudflare D1 Admin)
            const GageStandaloneBanner(
              screenTarget: 'merchant_home_info',
              margin: EdgeInsets.fromLTRB(16, 6, 16, 6),
            ),

            // Tab bar 3 status alur pesanan (Dalam proses, Selesai, Batal)
            _buildCustomTabBar(context, merchant, isDark),

            // Content per Tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Dalam proses
                  _buildOngoingTabContent(context, merchant, isDark),

                  // Tab 2: Selesai
                  _buildCompletedTabContent(context, merchant, isDark),

                  // Tab 3: Batal / Ditolak
                  _buildCancelledTabContent(context, merchant, isDark),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 0),
    );
  }

  /// Header Kios Utama (Adopsi Header GoBiz + Customer Portal Style)
  PreferredSizeWidget _buildCustomHeader(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
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
              color: GageTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: GageTheme.primary.withValues(alpha: 0.2)),
            ),
            child: const Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 22),
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
                        'Dimsum Sewu',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
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
                // Dropdown Pill Buka/Tutup Resto (Gojek GoBiz Style)
                InkWell(
                  onTap: () => _showStoreStatusBottomSheet(context, merchant),
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
                            color: merchant.isOpen ? const Color(0xFF16A34A) : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          merchant.isOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: merchant.isOpen ? const Color(0xFF15803D) : Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          Icons.arrow_drop_down_rounded,
                          size: 14,
                          color: merchant.isOpen ? const Color(0xFF15803D) : Colors.red.shade800,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        // Tombol Simulator Pesanan Masuk (Uji Coba Cepat Kasir / KDS)
        IconButton(
          icon: const Icon(Icons.flash_on_rounded, color: Colors.amber, size: 22),
          tooltip: 'Simulasi Pesanan Baru',
          onPressed: () {
            merchant.triggerMockIncomingOrder();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚡ Simulasi pesanan baru masuk ke dapur!'),
                backgroundColor: GageTheme.primary,
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),

        // Pencarian Pesanan
        IconButton(
          icon: const Icon(Icons.search_rounded, size: 22),
          tooltip: 'Cari Pesanan',
          onPressed: () => _showSearchOrderDialog(context, merchant),
        ),

        // Refresh
        IconButton(
          icon: const Icon(Icons.refresh_rounded, size: 22),
          tooltip: 'Segarkan',
          onPressed: () => merchant.fetchOrders(),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  /// Sub-Header: Status Printer Thermal 58mm & Auto-Accept
  Widget _buildPrinterAndStatusBar(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Printer thermal badge
          InkWell(
            onTap: () {
              merchant.togglePrinter(!merchant.printerConnected);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(merchant.printerConnected ? 'Thermal SPP 58mm Siap' : 'Thermal SPP Dimatikan'),
                  duration: const Duration(seconds: 1),
                ),
              );
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: merchant.printerConnected
                    ? GageTheme.accentGreen.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: merchant.printerConnected
                      ? GageTheme.accentGreen.withValues(alpha: 0.3)
                      : Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.print_rounded,
                    size: 13,
                    color: merchant.printerConnected ? GageTheme.accentGreen : Colors.orange.shade800,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    merchant.printerConnected ? 'SPP 58mm Terhubung' : 'Printer Offline',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: merchant.printerConnected ? GageTheme.accentGreen : Colors.orange.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Auto-Accept toggle pill
          InkWell(
            onTap: () {
              merchant.toggleAutoAccept(!merchant.autoAccept);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? GageTheme.darkBackground : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    merchant.autoAccept ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 12,
                    color: merchant.autoAccept ? GageTheme.primary : GageTheme.textSecondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    merchant.autoAccept ? 'Terima Otomatis' : 'Terima Manual',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : GageTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Custom Segmented Tab Bar (Persis dengan OrdersScreen Customer Portal)
  Widget _buildCustomTabBar(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    return Container(
      color: isDark ? GageTheme.darkSurface : Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: GageTheme.primary,
        indicatorWeight: 3,
        labelColor: GageTheme.primary,
        unselectedLabelColor: isDark ? Colors.white60 : GageTheme.textSecondary,
        labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 12.5),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 12.5),
        tabs: [
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Dalam proses'),
                  if (merchant.activeOrderCount > 0) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: GageTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${merchant.activeOrderCount}',
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Tab(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Selesai'),
                  if (merchant.completedOrders.isNotEmpty) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${merchant.completedOrders.length}',
                        style: const TextStyle(color: Color(0xFF15803D), fontSize: 9.5, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const Tab(text: 'Batal'),
        ],
      ),
    );
  }

  /// Konten Tab 1: Pesanan Dalam Proses
  Widget _buildOngoingTabContent(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    final activeOrders = merchant.activeOrders;

    return Column(
      children: [
        // Sub-filter chips (Semua, Perlu Disiapkan, Siap Diambil)
        _buildStageFilterChips(context, merchant, isDark),

        // List Tiket Pesanan
        Expanded(
          child: merchant.isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 3,
                  itemBuilder: (ctx, idx) => const GageSkeletonKitchenOrderCard(),
                )
              : activeOrders.isEmpty
                  ? _buildEmptyState(
                      'Dapur Bersih, Tidak Ada Antrean',
                      'Pesanan masuk dari pelanggan Pracimantoro akan otomatis muncul di sini secara real-time.',
                      Icons.soup_kitchen_rounded,
                      isDark,
                    )
                  : RefreshIndicator(
                      onRefresh: () => merchant.fetchOrders(),
                      color: GageTheme.primary,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: activeOrders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 14),
                        itemBuilder: (ctx, idx) => _buildOrderCard(context, activeOrders[idx], merchant, isDark),
                      ),
                    ),
        ),
      ],
    );
  }

  /// Konten Tab 2: Riwayat Selesai
  Widget _buildCompletedTabContent(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    final history = merchant.completedOrders;

    return history.isEmpty
        ? _buildEmptyState(
            'Belum Ada Pesanan Selesai',
            'Semua pesanan yang telah diserahkan ke kurir atau dinikmati pelanggan hari ini akan tersimpan di sini.',
            Icons.receipt_long_rounded,
            isDark,
          )
        : RefreshIndicator(
            onRefresh: () => merchant.fetchOrders(),
            color: GageTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: history.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (ctx, idx) => _buildOrderCard(context, history[idx], merchant, isDark),
            ),
          );
  }

  /// Konten Tab 3: Batal / Ditolak
  Widget _buildCancelledTabContent(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    final cancelled = merchant.cancelledOrders;

    return cancelled.isEmpty
        ? _buildEmptyState(
            'Tidak Ada Pesanan Dibatalkan',
            'Bagus! Belum ada pesanan yang ditolak atau dibatalkan.',
            Icons.check_circle_outline_rounded,
            isDark,
          )
        : RefreshIndicator(
            onRefresh: () => merchant.fetchOrders(),
            color: GageTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: cancelled.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (ctx, idx) => _buildOrderCard(context, cancelled[idx], merchant, isDark),
            ),
          );
  }

  /// Filter Chips (Semua, Perlu Disiapkan, Siap Diambil)
  Widget _buildStageFilterChips(BuildContext context, MerchantOrderProvider merchant, bool isDark) {
    final filters = [
      {'key': 'SEMUA', 'label': 'Semua', 'icon': Icons.all_inbox_rounded},
      {'key': 'PERLU_DISIAPKAN', 'label': 'Perlu Disiapkan', 'icon': Icons.outdoor_grill_rounded},
      {'key': 'SIAP_DIAMBIL', 'label': 'Siap Diambil', 'icon': Icons.check_circle_rounded},
    ];

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final f = filters[idx];
          final isSelected = merchant.selectedStageFilter == f['key'];

          return InkWell(
            onTap: () => merchant.setStageFilter(f['key'] as String),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? GageTheme.primary : (isDark ? GageTheme.darkSurface : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? GageTheme.primary : (isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    f['icon'] as IconData,
                    size: 13,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    f['label'] as String,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// CUSTOM ORDER CARD (Full-Custom Standard Customer Portal)
  Widget _buildOrderCard(BuildContext context, MerchantOrder order, MerchantOrderProvider merchant, bool isDark) {
    final isFood = order.channel == 'food';
    final isNew = order.stage == 'NEW';
    final isCooking = order.stage == 'COOKING';
    final isReady = order.stage == 'READY_FOR_PICKUP';
    final isCompleted = order.stage == 'COMPLETED';

    // Status Badge Styling (Mengikuti Customer Portal)
    Color badgeBg;
    Color badgeTextColor;
    String badgeText;
    IconData badgeIcon;

    if (isNew) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeTextColor = GageTheme.primary;
      badgeText = 'PESANAN BARU';
      badgeIcon = Icons.notifications_active_rounded;
    } else if (isCooking) {
      badgeBg = const Color(0xFFFEF3C7);
      badgeTextColor = const Color(0xFFB45309);
      badgeText = isFood ? 'SEDANG DIMASAK' : 'SEDANG DI-PACKING';
      badgeIcon = Icons.access_time_rounded;
    } else if (isReady) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeTextColor = const Color(0xFF15803D);
      badgeText = 'SIAP DIAMBIL KURIR';
      badgeIcon = Icons.check_circle_rounded;
    } else if (isCompleted) {
      badgeBg = const Color(0xFFEFF6FF);
      badgeTextColor = const Color(0xFF2563EB);
      badgeText = 'SELESAI';
      badgeIcon = Icons.task_alt_rounded;
    } else {
      badgeBg = Colors.grey.shade100;
      badgeTextColor = Colors.grey.shade700;
      badgeText = 'DIBATALKAN';
      badgeIcon = Icons.cancel_outlined;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isNew
              ? GageTheme.primary.withValues(alpha: 0.35)
              : (isDark ? GageTheme.darkBorder : Colors.grey.shade200),
          width: isNew ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Chip Invoice + Channel Badge + Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildInvoiceChip(context, order.orderNumber),
                    const SizedBox(width: 6),
                    // Channel Badge (FOOD vs SHOP)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isFood ? const Color(0xFFFEE2E2) : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isFood ? 'GAGE FOOD' : 'GAGE SHOP',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: isFood ? GageTheme.primary : const Color(0xFF0284C7),
                        ),
                      ),
                    ),
                  ],
                ),
                // Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(badgeIcon, size: 12, color: badgeTextColor),
                      const SizedBox(width: 4),
                      Text(
                        badgeText,
                        style: TextStyle(
                          color: badgeTextColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Baris 2: Banner Pelanggan (Adopsi GoBiz: Nama, Jam Masuk, Chat & Call)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline_rounded, size: 16, color: GageTheme.primary),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          order.customerName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : GageTheme.textPrimary,
                          ),
                        ),
                        Text(
                          '${DateFormat('HH:mm').format(order.createdAt)} WIB • ${order.deliveryAddress}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Chat Pelanggan Action
                  InkWell(
                    onTap: () => _openChatWithCustomer(order),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: GageTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 12, color: GageTheme.primary),
                          SizedBox(width: 4),
                          Text('Chat', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Call Pelanggan
                  InkWell(
                    onTap: () async {
                      final uri = Uri.parse('tel:${order.customerPhone}');
                      if (await canLaunchUrl(uri)) launchUrl(uri);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.call_rounded, size: 13, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Baris 3: Daftar Item (KDS Food vs Mart Picking Checklist)
            for (int i = 0; i < order.items.length; i++) ...[
              _buildOrderItemRow(order, order.items[i], i, merchant, isDark),
              if (i < order.items.length - 1) const SizedBox(height: 6),
            ],

            // Catatan Dapur / Resto (Gojek Highlighted Peach Box)
            if (order.kitchenNote != null && order.kitchenNote!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED), // Peach Amber Tint
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.note_alt_outlined, size: 15, color: Color(0xFFEA580C)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Catatan: ${order.kitchenNote}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFC2410C),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const Divider(height: 22),

            // Baris 4: Info Driver / Kurir & Total Pembayaran
            _buildDriverAndTotalSection(order, isDark),

            const SizedBox(height: 14),

            // Baris 5: Tombol Aksi KDS GoBiz
            _buildOrderActionButtons(order, merchant),
          ],
        ),
      ),
    );
  }

  /// Row Item Pesanan (Dukungan Checkbox Picking untuk Mart)
  Widget _buildOrderItemRow(MerchantOrder order, MerchantOrderItem it, int index, MerchantOrderProvider merchant, bool isDark) {
    final isShop = order.channel == 'shop';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (isShop) ...[
          // Checkbox Picking GoMart style
          InkWell(
            onTap: () => merchant.togglePickingItem(order.id, index),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 22,
              height: 22,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: it.isPicked ? GageTheme.accentGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: it.isPicked ? GageTheme.accentGreen : Colors.grey.shade400,
                  width: 1.5,
                ),
              ),
              child: it.isPicked
                  ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                  : null,
            ),
          ),
        ] else ...[
          // Badge Qty Dapur
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${it.quantity}x',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
        ],

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                it.name,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  decoration: (isShop && it.isPicked) ? TextDecoration.lineThrough : null,
                  color: (isShop && it.isPicked)
                      ? GageTheme.textSecondary
                      : (isDark ? Colors.white : GageTheme.textPrimary),
                ),
              ),
              if (it.variant != null && it.variant!.isNotEmpty)
                Text(
                  it.variant!,
                  style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                ),
            ],
          ),
        ),

        Text(
          currencyFormatter.format(it.price * it.quantity),
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  /// Bagian Kurir & Total Tagihan
  Widget _buildDriverAndTotalSection(MerchantOrder order, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? GageTheme.darkBorder : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pendapatan:', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
              Text(
                currencyFormatter.format(order.totalAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: GageTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Driver status
          if (order.driver != null) ...[
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFDCFCE7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.two_wheeler_rounded, size: 14, color: Color(0xFF16A34A)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '${order.driver!.name} • ${order.driver!.plateNumber}',
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Chat Driver
                InkWell(
                  onTap: () => _openChatWithDriver(order),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: GageTheme.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.chat_rounded, size: 11, color: GageTheme.accentGreen),
                        SizedBox(width: 4),
                        Text('Chat Driver', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Call Driver
                InkWell(
                  onTap: () async {
                    final uri = Uri.parse('https://wa.me/${order.driver!.phone}');
                    if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.call_rounded, size: 13, color: Colors.green),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Row(
              children: [
                Icon(Icons.search_rounded, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  'Sedang mencari kurir terdekat di Pracimantoro...',
                  style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Tombol Pemicu Aksi KDS GoBiz (Terima, Tolak, Tandai Siap, Serahkan)
  Widget _buildOrderActionButtons(MerchantOrder order, MerchantOrderProvider merchant) {
    final isNew = order.stage == 'NEW';
    final isCooking = order.stage == 'COOKING';
    final isReady = order.stage == 'READY_FOR_PICKUP';

    if (isNew) {
      final min = (order.autoAcceptSecondsRemaining ~/ 60).toString().padLeft(2, '0');
      final sec = (order.autoAcceptSecondsRemaining % 60).toString().padLeft(2, '0');

      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showRejectDialog(context, order, merchant),
              child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => merchant.acceptOrder(order.id),
              child: Text(
                'Terima Pesanan ($min:$sec)',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ),
          ),
        ],
      );
    }

    if (isCooking) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: GageTheme.accentGreen,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 13),
          ),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 17, color: Colors.white),
          label: const Text(
            'Tandai Pesanan Siap (Kabari Kurir)',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
          onPressed: () => merchant.markReadyForPickup(order.id),
        ),
      );
    }

    if (isReady) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: GageTheme.primary,
                side: const BorderSide(color: GageTheme.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.notifications_active_rounded, size: 16),
              label: const Text('Panggil Kurir', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              onPressed: () {
                HapticFeedback.mediumImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Notifikasi siap ambil dikirimkan ke HP Driver.'),
                    backgroundColor: GageTheme.accentGreen,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => merchant.completeOrder(order.id),
              child: const Text('Serahkan ke Kurir', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Text(
        'Pesanan Selesai Diambil',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey),
      ),
    );
  }

  /// Chip Invoice Unik (Exact Customer Portal Implementation)
  Widget _buildInvoiceChip(BuildContext context, String invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        invoice,
        style: GoogleFonts.jetBrainsMono(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
        ),
      ),
    );
  }

  /// Empty State Elegan (Persis dengan OrdersScreen Customer Portal)
  Widget _buildEmptyState(String title, String subtitle, IconData icon, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: GageTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : GageTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : GageTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom Sheet Pengaturan Status Buka/Tutup Resto
  void _showStoreStatusBottomSheet(BuildContext context, MerchantOrderProvider merchant) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Status Kios Dimsum Sewu',
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 14),
              // Switch status
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: GageTheme.accentGreen,
                title: const Text('Buka Kios untuk Terima Pesanan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Text(
                  merchant.isOpen
                      ? 'Kios saat ini tampil di aplikasi pelanggan & siap terima pesanan.'
                      : 'Kios saat ini tutup sementara. Pelanggan tidak dapat order.',
                  style: const TextStyle(fontSize: 12),
                ),
                value: merchant.isOpen,
                onChanged: (val) {
                  merchant.toggleStoreOpen(val);
                  setSheetState(() {});
                },
              ),
              const Divider(),
              const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.access_time_rounded, color: GageTheme.textSecondary),
                title: Text('Jam Operasional', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                trailing: Text('09:00 - 21:00 WIB', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Simpan Perubahan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Dialog Penolakan Pesanan
  void _showRejectDialog(BuildContext context, MerchantOrder order, MerchantOrderProvider merchant) {
    HapticFeedback.lightImpact();
    final reasons = [
      'Bahan / Stok menu habis',
      'Kios sedang sangat ramai / antre panjang',
      'Resto mau tutup / jam operasional selesai',
      'Lainnya',
    ];
    String selectedReason = reasons.first;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Tolak Pesanan Ini?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Pilih alasan penolakan agar pelanggan mendapat penjelasan jelas:', style: TextStyle(fontSize: 12.5)),
              const SizedBox(height: 10),
              for (final r in reasons)
                InkWell(
                  onTap: () => setDialogState(() => selectedReason = r),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          selectedReason == r ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          size: 18,
                          color: selectedReason == r ? Colors.red : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(r, style: const TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                merchant.rejectOrder(order.id, selectedReason);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Pesanan ditolak: $selectedReason'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              child: const Text('Ya, Tolak', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Dialog Cari Pesanan (Berdasarkan No Order / Pelanggan)
  void _showSearchOrderDialog(BuildContext context, MerchantOrderProvider merchant) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cari Pesanan Dapur', style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: searchCtrl,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Ketik no. pesanan (#GF-...) atau nama pelanggan',
                hintStyle: const TextStyle(fontSize: 12.5),
                prefixIcon: const Icon(Icons.search_rounded),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  // Filter trigger
                },
                child: const Text('Cari', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openChatWithDriver(MerchantOrder order) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppChatScreen(
          orderId: order.orderNumber,
          recipientName: order.driver?.name ?? 'Kurir GAGE',
          recipientRole: 'driver',
          recipientPhone: order.driver?.phone ?? '081234567890',
          currentRole: 'merchant',
        ),
      ),
    );
  }

  void _openChatWithCustomer(MerchantOrder order) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppChatScreen(
          orderId: order.orderNumber,
          recipientName: order.customerName,
          recipientRole: 'customer',
          recipientPhone: order.customerPhone,
          currentRole: 'merchant',
        ),
      ),
    );
  }
}
