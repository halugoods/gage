import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/orders/presentation/order_detail_screen.dart';
import 'package:gage_app/features/orders/presentation/widgets/rating_review_sheet.dart';
import 'package:gage_app/shared/widgets/gage_receipt_share_dialog.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final Map<String, Map<String, dynamic>> _ratedOrders = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh();
    });
  }

  Future<void> _refresh() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.currentUser?.id ??
        (GageApiClient.useDevSeedData ? 'usr-cust-01' : '');
    if (userId.isEmpty) return;
    await context.read<OrderProvider>().fetchUserOrders(userId);
  }

  Future<void> _confirmCancelOrder(BuildContext context, OrderModel order) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, color: Color(0xFFDC2626), size: 36),
            ),
            const SizedBox(height: 14),
            Text(
              'Batalkan Pesanan Ini?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.isTransportService
                  ? 'Mitra driver belum ditugaskan. Apakah Anda yakin ingin membatalkan perjalanan/pengiriman ini?'
                  : 'Merchant belum mengonfirmasi pesanan. Apakah Anda yakin ingin membatalkan pesanan ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && context.mounted) {
      final ok = await context.read<OrderProvider>().updateOrderStage(
        order.id,
        'CANCELLED',
        reason: 'Dibatalkan oleh pelanggan',
      );
      if (context.mounted) {
        if (ok) {
          _refresh();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pesanan berhasil dibatalkan'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal membatalkan pesanan. Silakan coba kembali.'),
              backgroundColor: Color(0xFFDC2626),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final activeOrders = orderProvider.activeOrders;
    final historyOrders = orderProvider.orderHistory;
    final unratedOrdersCount = historyOrders.where((o) => o.status == 'COMPLETED' && !_ratedOrders.containsKey(o.id)).length;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
          appBar: AppBar(
            title: const Text('Pesanan Saya', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
            foregroundColor: isDark ? Colors.white : Colors.black87,
            elevation: 0.5,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Segarkan',
                onPressed: _refresh,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                color: isDark ? GageTheme.darkSurface : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
                child: Container(
                  height: 42,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    onTap: (_) => HapticFeedback.selectionClick(),
                    indicator: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: GageTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                    tabs: [
                      Tab(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Dalam Proses'),
                              if (activeOrders.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${activeOrders.length}',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: GageTheme.primary,
                                    ),
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
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('Riwayat Selesai'),
                              if (unratedOrdersCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '$unratedOrdersCount',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            onRefresh: _refresh,
            color: GageTheme.primary,
            child: TabBarView(
              children: [
                // Tab 1: Pesanan Aktif
                orderProvider.isLoading
                    ? ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: 3,
                        itemBuilder: (ctx, idx) => const GageSkeletonOrderTicket(),
                      )
                    : activeOrders.isEmpty
                        ? _buildEmptyState(
                            'Belum Ada Pesanan Aktif',
                            'Pesanan yang sedang disiapkan resto atau diantar driver akan tampil di sini secara real-time.',
                            icon: Icons.delivery_dining_outlined,
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: activeOrders.length,
                            itemBuilder: (ctx, idx) => _buildOrderCard(context, activeOrders[idx], isActive: true),
                          ),

                // Tab 2: Riwayat Pesanan
                orderProvider.isLoading
                    ? ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: 4,
                        itemBuilder: (ctx, idx) => const GageSkeletonOrderTicket(),
                      )
                    : historyOrders.isEmpty
                        ? _buildEmptyState(
                            'Belum Ada Riwayat Pesanan',
                            'Semua pesanan yang telah selesai atau dinikmati akan tersimpan di sini.',
                            icon: Icons.receipt_long_outlined,
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: historyOrders.length,
                            itemBuilder: (ctx, idx) => _buildOrderCard(context, historyOrders[idx], isActive: false),
                          ),
              ],
            ),
          ),
          bottomNavigationBar: const GageBottomNavBar(currentIndex: 1),
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order, {required bool isActive}) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final merchantNames = order.merchantNamesList;
    final merchantTitle = merchantNames.isNotEmpty ? merchantNames.join(', ') : order.merchantName;
    final isMultiMerchant = merchantNames.length > 1;

    // Kumpulkan daftar gambar untuk gallery scroll horizontal
    final imageList = <String>[];
    for (final it in order.items) {
      if (it.imageUrl != null && it.imageUrl!.trim().isNotEmpty) {
        if (!imageList.contains(it.imageUrl!.trim())) {
          imageList.add(it.imageUrl!.trim());
        }
      }
    }
    // Fallback jika item tidak ada gambar
    if (imageList.isEmpty) {
      final svc = order.serviceType.toLowerCase();
      if (svc == 'ride') {
        imageList.add('assets/icons/ic_ride.png');
      } else if (svc == 'car') {
        imageList.add('assets/icons/ic_car.png');
      } else if (svc == 'send') {
        imageList.add('assets/icons/ic_send.png');
      } else if (order.merchantName.toLowerCase().contains('rocket')) {
        imageList.add('assets/images/resto_rocket_chicken.png');
      } else if (order.merchantName.toLowerCase().contains('dimsum')) {
        imageList.add('assets/images/resto_dimsum_sewu.png');
      } else {
        imageList.add('assets/images/dish_bakso_urat.png');
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCancelled = order.status == 'CANCELLED';
    final badgeBg = isCancelled
        ? (isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFEE2E2))
        : isActive
            ? (isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFEF3C7))
            : (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFDCFCE7));
    final badgeFg = isCancelled
        ? (isDark ? Colors.red.shade300 : const Color(0xFFB91C1C))
        : isActive
            ? (isDark ? Colors.amber.shade300 : const Color(0xFFB45309))
            : (isDark ? Colors.green.shade300 : const Color(0xFF15803D));
    final badgeIcon = isCancelled
        ? Icons.cancel_rounded
        : (isActive ? Icons.access_time_rounded : Icons.check_circle_rounded);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : const Color(0x0A000000),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => OrderDetailScreen(order: order)),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris 1: Chip Invoice Unik + Badge Status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(child: _buildInvoiceChip(context, order.orderNumber)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 13, color: badgeFg),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              order.statusLabel,
                              style: TextStyle(
                                color: badgeFg,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris 2: Profil Toko & Hero Text (Multi-Merchant Supported) - Clean Pure Text
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            merchantTitle,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isMultiMerchant) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.orange.withValues(alpha: 0.15) : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.orange.shade200),
                            ),
                            child: const Text(
                              'Multi Toko',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.orange),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      order.merchantAddress,
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11.5),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Baris 3: Scroll Horizontal Deretan Gambar dengan Efek Vignette / Faded Gradient
                _buildThumbnailGalleryWithVignette(imageList),
                const SizedBox(height: 10),

                // Rincian Singkat Menu / Rute
                Text(
                  order.items.isNotEmpty
                      ? '${order.items.first.quantity}x ${order.items.first.name}${order.items.length > 1 ? " dan ${order.items.length - 1} item lainnya" : ""}'
                      : (order.deliveryAddress.trim().isNotEmpty
                          ? 'Tujuan: ${order.deliveryAddress}'
                          : 'Pesanan Layanan GAGE'),
                  style: TextStyle(color: isDark ? Colors.white70 : GageTheme.textSecondary, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),
                Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                const SizedBox(height: 12),

                // Baris 4: Total Pembayaran & Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Total Pembayaran', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary)),
                          const SizedBox(height: 2),
                          Text(
                            currencyFormatter.format(order.totalAmount),
                            style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 15.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white70 : Colors.black87,
                            side: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (ctx) => OrderDetailScreen(order: order)),
                            );
                          },
                          child: const Text('Rincian', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                        if (isActive && order.canBeCancelledByCustomer) ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                              side: const BorderSide(color: Color(0xFFDC2626), width: 1.2),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _confirmCancelOrder(context, order),
                            icon: const Icon(Icons.cancel_outlined, size: 14),
                            label: const Text('Batalkan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (!isActive && order.status == 'COMPLETED') ...[
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              side: const BorderSide(color: GageTheme.primary, width: 1.2),
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              GageReceiptShareDialog.show(context, order);
                            },
                            icon: const Icon(Icons.receipt_long_rounded, size: 14),
                            label: const Text('Struk', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                        if (isActive &&
                            !order.isPickup &&
                            !const {'PAYMENT_PENDING', 'PENDING'}.contains(order.status)) ...[
                          const SizedBox(width: 8),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (ctx) => OrderTrackingScreen(
                                    orderId: order.id,
                                    initialOrder: order,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.navigation_rounded, size: 14),
                            label: const Text('Lacak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ] else if (!isActive && order.items.isNotEmpty && !order.isTransportService) ...[
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () {
                              _reorder(context, order);
                            },
                            child: const Text('Pesan Lagi', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Baris Penilaian Toko & Driver untuk Pesanan Selesai (Interactive 5 Stars)
                if (!isActive && order.status == 'COMPLETED') ...[
                  const SizedBox(height: 12),
                  if (_ratedOrders.containsKey(order.id))
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isDark ? Colors.green.shade800 : const Color(0xFFBBF7D0)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              '★ ${_ratedOrders[order.id]!['merchantRating']}.0 • Penilaian Anda telah terkirim',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.green.shade200 : const Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7).withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isDark ? Colors.amber.shade800 : const Color(0xFFFDE68A)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Selesaikan Penilaian',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                    color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
                                  ),
                                ),
                                Text(
                                  'Ketuk bintang untuk menilai:',
                                  style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : const Color(0xFFB45309)),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (starIdx) {
                              final starNum = starIdx + 1;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  RatingReviewSheet.show(
                                    context,
                                    orderId: order.orderNumber,
                                    merchantId: order.merchantId,
                                    serviceType: order.serviceType,
                                    merchantName: merchantTitle,
                                    merchantAvatar: order.merchantAvatar,
                                    driverName: order.driverName ?? '',
                                    driverAvatar: order.driverAvatar,
                                    driverVehicle: order.driverVehicle ?? order.driverPlate,
                                    initialStar: starNum,
                                    onSubmitted: (mRating, dRating) {
                                      setState(() {
                                        _ratedOrders[order.id] = {
                                          'merchantRating': mRating,
                                          'driverRating': dRating,
                                        };
                                      });
                                    },
                                  );
                                },
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 2),
                                  child: Icon(
                                    Icons.star_outline_rounded,
                                    size: 23,
                                    color: Color(0xFFF59E0B),
                                  ),
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Nomor Invoice Unik dengan Tombol Salin (Tanpa Card Wrap)
  Widget _buildInvoiceChip(BuildContext context, String invoice) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: invoice));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Nomor invoice disalin: $invoice'),
            backgroundColor: GageTheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                invoice,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: isDark ? Colors.white : Colors.black87,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 5),
            const Icon(Icons.copy_rounded, size: 13, color: GageTheme.primary),
          ],
        ),
      ),
    );
  }

  // Gallery Deretan Gambar dengan Efek Vignette / Faded Gradient pada Item ke-2 dan Seterusnya
  Widget _buildThumbnailGalleryWithVignette(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    Widget gallery = SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final img = images[idx];
          return ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: Colors.grey.shade100,
              child: _buildThumbnailImage(img),
            ),
          );
        },
      ),
    );

    // Jika gambar lebih dari 1, berikan ShaderMask vignette faded di sisi kanan
    if (images.length >= 2) {
      gallery = ShaderMask(
        shaderCallback: (Rect bounds) {
          return const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.black,
              Colors.black,
              Colors.black87,
              Colors.transparent,
            ],
            stops: [0.0, 0.65, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: gallery,
      );
    }

    return gallery;
  }

  Widget _buildThumbnailImage(String img) {
    final clean = img.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => const Center(
          child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 22),
        ),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => const Center(
        child: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 22),
      ),
    );
  }

  void _reorder(BuildContext context, OrderModel order) {
    final cart = context.read<CartProvider>();
    cart.clearCart();
    for (var item in order.items) {
      cart.addItem(CartItemModel(
        menuId: item.id,
        merchantId: order.merchantId,
        merchantName: item.merchantName ?? order.merchantName,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        notes: item.notes,
        imageUrl: item.imageUrl,
      ));
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, {required IconData icon}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 64.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/empty_orders_blob.png',
                width: 140,
                height: 140,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => Icon(icon, size: 64, color: isDark ? Colors.white30 : Colors.grey.shade400),
              ),
              const SizedBox(height: 16),
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : GageTheme.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
