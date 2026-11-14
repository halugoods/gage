import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/pracimantoro_places_database.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/features/orders/presentation/widgets/rating_review_sheet.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_receipt_share_dialog.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  int _selectedStar = 0;
  bool _isReviewed = false;
  late OrderModel _currentOrder = widget.order;
  late final AnimationController _dotsCtrl;

  @override
  void initState() {
    super.initState();
    _dotsCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotsCtrl.dispose();
    super.dispose();
  }

  OrderModel get order => _currentOrder;

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      if (order.userId.trim().isNotEmpty) {
        await context.read<OrderProvider>().fetchUserOrders(order.userId);
      }
    } catch (_) {
      // Abaikan jika provider tidak tersedia pada widget test terisolasi
    }
    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    try {
      final live = context.watch<OrderProvider>().getOrderById(widget.order.id);
      _currentOrder = live ?? widget.order;
    } on ProviderNotFoundException {
      _currentOrder = widget.order;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final dateStr = order.createdAt > 0
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order.createdAt * 1000))
        : DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now());

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      appBar: AppBar(
        title: const Text('Rincian Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Bagikan Struk',
            onPressed: () {
              GageReceiptShareDialog.show(context, order);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: GageTheme.primary,
        child: _isLoading
            ? const GageSkeletonOrderDetail()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card 1: Invoice & Status Header
                    _buildInvoiceStatusCard(context, dateStr, isDark),
                    const SizedBox(height: 14),

                    // Card 2: Status Timeline
                    _buildStatusTimeline(isDark),
                    const SizedBox(height: 14),

                    // Card 3: Toko / Layanan Info
                    _buildMerchantSection(isDark),
                    const SizedBox(height: 14),

                    // Card 4: Rincian Produk / Menu atau Layanan Transport/Pengiriman
                    if (order.isTransportService ||
                        order.items.isNotEmpty ||
                        (order.packageDetails != null && order.packageDetails!.isNotEmpty)) ...[
                      _buildItemsSection(currencyFormatter, isDark),
                      const SizedBox(height: 14),
                    ],

                    // Card 5: Pengantaran & Alamat
                    _buildDeliverySection(isDark),
                    const SizedBox(height: 14),

                    // Card 6: Info Pengemudi / Driver (hanya jika sudah terassign dan bukan pickup)
                    if (order.hasAssignedDriver && !order.isPickup) ...[
                      _buildDriverSection(context, isDark),
                      const SizedBox(height: 14),
                    ],

                    // Card 6.5: Penilaian Toko & Driver (Pesanan Selesai)
                    if (order.status == 'COMPLETED') ...[
                      _buildRatingReviewSection(context, isDark),
                      const SizedBox(height: 14),
                    ],

                    // Card 7: Rincian Pembayaran
                    _buildPaymentSummaryCard(currencyFormatter, isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: _buildBottomBar(context, isDark),
    );
  }

  Widget _buildInvoiceStatusCard(BuildContext context, String dateStr, bool isDark) {
    final isCancelled = order.status == 'CANCELLED';
    final badgeBg = isCancelled
        ? (isDark ? Colors.red.withValues(alpha: 0.2) : const Color(0xFFFEE2E2))
        : order.isActive
            ? (isDark ? Colors.amber.withValues(alpha: 0.2) : const Color(0xFFFEF3C7))
            : (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFDCFCE7));
    final badgeFg = isCancelled
        ? (isDark ? Colors.red.shade300 : const Color(0xFFB91C1C))
        : order.isActive
            ? (isDark ? Colors.amber.shade300 : const Color(0xFFB45309))
            : (isDark ? Colors.green.shade300 : const Color(0xFF15803D));
    final badgeIcon = isCancelled
        ? Icons.cancel_rounded
        : (order.isActive ? Icons.access_time_rounded : Icons.check_circle_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        boxShadow: isDark ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 5),
                    Text(
                      order.statusLabel,
                      style: TextStyle(
                        color: badgeFg,
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(dateStr, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Nomor Invoice Unik',
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: SelectableText(
                  order.orderNumber,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  Clipboard.setData(ClipboardData(text: order.orderNumber));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Nomor invoice disalin: ${order.orderNumber}'),
                      backgroundColor: GageTheme.primary,
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkElevated : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy_rounded, size: 13, color: GageTheme.primary),
                      SizedBox(width: 4),
                      Text('Salin', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildSequentialStages() {
    final s = order.status;
    final paidOrPast = !const {'PAYMENT_PENDING', 'PENDING', 'CANCELLED'}.contains(s);
    final svc = order.serviceType.toLowerCase();

    if (svc == 'ride' || svc == 'car') {
      final driverAssigned = const {
        'DRIVER_ASSIGNED',
        'AT_MERCHANT',
        'PICKED_UP',
        'ON_DELIVERY',
        'COMPLETED',
      }.contains(s);
      final onTrip = const {'PICKED_UP', 'ON_DELIVERY', 'COMPLETED'}.contains(s);
      return [
        {
          'title': 'Dipesan',
          'icon': Icons.receipt_long_rounded,
          'done': paidOrPast,
          'active': s == 'PAYMENT_PENDING' || s == 'PENDING',
        },
        {
          'title': 'Cari Driver',
          'icon': Icons.person_search_rounded,
          'done': driverAssigned,
          'active': paidOrPast && !driverAssigned,
        },
        {
          'title': 'Dijemput',
          'icon': Icons.location_on_rounded,
          'done': onTrip,
          'active': s == 'DRIVER_ASSIGNED' || s == 'AT_MERCHANT',
        },
        {
          'title': 'Perjalanan',
          'icon': svc == 'car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
          'done': s == 'COMPLETED',
          'active': s == 'PICKED_UP' || s == 'ON_DELIVERY',
        },
        {
          'title': 'Selesai',
          'icon': Icons.flag_rounded,
          'done': s == 'COMPLETED',
          'active': false,
        },
      ];
    }

    if (svc == 'send') {
      final kurirAssigned = const {
        'DRIVER_ASSIGNED',
        'AT_MERCHANT',
        'PICKED_UP',
        'ON_DELIVERY',
        'COMPLETED',
      }.contains(s);
      final inTransit = const {'PICKED_UP', 'ON_DELIVERY', 'COMPLETED'}.contains(s);
      return [
        {
          'title': 'Dipesan',
          'icon': Icons.receipt_long_rounded,
          'done': paidOrPast,
          'active': s == 'PAYMENT_PENDING' || s == 'PENDING',
        },
        {
          'title': 'Cari Kurir',
          'icon': Icons.person_search_rounded,
          'done': kurirAssigned,
          'active': paidOrPast && !kurirAssigned,
        },
        {
          'title': 'Dijemput',
          'icon': Icons.location_on_rounded,
          'done': inTransit,
          'active': s == 'DRIVER_ASSIGNED' || s == 'AT_MERCHANT',
        },
        {
          'title': 'Dikirim',
          'icon': Icons.local_shipping_rounded,
          'done': s == 'COMPLETED',
          'active': s == 'PICKED_UP' || s == 'ON_DELIVERY',
        },
        {
          'title': 'Selesai',
          'icon': Icons.task_alt_rounded,
          'done': s == 'COMPLETED',
          'active': false,
        },
      ];
    }

    if (order.isPickup) {
      final merchantConfirmed = const {'COOKING', 'READY_FOR_PICKUP', 'COMPLETED'}.contains(s);
      final readyPickup = const {'READY_FOR_PICKUP', 'COMPLETED'}.contains(s);
      return [
        {
          'title': 'Dipesan',
          'icon': Icons.receipt_long_rounded,
          'done': paidOrPast,
          'active': s == 'PAYMENT_PENDING' || s == 'PENDING',
        },
        {
          'title': 'Konfirmasi',
          'icon': Icons.storefront_rounded,
          'done': merchantConfirmed,
          'active': const {'NEW', 'PAID'}.contains(s),
        },
        {
          'title': 'Disiapkan',
          'icon': Icons.inventory_2_rounded,
          'done': readyPickup,
          'active': s == 'COOKING',
        },
        {
          'title': 'Siap Ambil',
          'icon': Icons.location_on_rounded,
          'done': s == 'COMPLETED',
          'active': s == 'READY_FOR_PICKUP',
        },
        {
          'title': 'Selesai',
          'icon': Icons.task_alt_rounded,
          'done': s == 'COMPLETED',
          'active': false,
        },
      ];
    }

    // Merchant delivery: Food, Shop, Farm, Build
    final merchantConfirmed = const {
      'SEARCHING_DRIVER',
      'DRIVER_ASSIGNED',
      'AT_MERCHANT',
      'COOKING',
      'READY_FOR_PICKUP',
      'PICKED_UP',
      'ON_DELIVERY',
      'COMPLETED',
    }.contains(s);
    final prepFinished = const {'READY_FOR_PICKUP', 'PICKED_UP', 'ON_DELIVERY', 'COMPLETED'}.contains(s);
    final outForDelivery = const {'PICKED_UP', 'ON_DELIVERY', 'COMPLETED'}.contains(s);
    return [
      {
        'title': 'Dipesan',
        'icon': Icons.receipt_long_rounded,
        'done': paidOrPast,
        'active': s == 'PAYMENT_PENDING' || s == 'PENDING',
      },
      {
        'title': 'Konfirmasi',
        'icon': Icons.storefront_rounded,
        'done': merchantConfirmed,
        'active': const {'NEW', 'PAID'}.contains(s),
      },
      {
        'title': 'Disiapkan',
        'icon': Icons.soup_kitchen_rounded,
        'done': prepFinished,
        'active': const {'SEARCHING_DRIVER', 'DRIVER_ASSIGNED', 'AT_MERCHANT', 'COOKING'}.contains(s),
      },
      {
        'title': 'Diantar',
        'icon': Icons.delivery_dining_rounded,
        'done': s == 'COMPLETED',
        'active': outForDelivery && s != 'COMPLETED',
      },
      {
        'title': 'Selesai',
        'icon': Icons.location_on_rounded,
        'done': s == 'COMPLETED',
        'active': false,
      },
    ];
  }

  Widget _buildStatusTimeline(bool isDark) {
    if (order.status == 'CANCELLED') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withValues(alpha: 0.12) : const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cancel_rounded, color: isDark ? Colors.red.shade300 : const Color(0xFFDC2626), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pesanan Dibatalkan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.red.shade200 : const Color(0xFF991B1B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    (order.cancellationReason != null && order.cancellationReason!.trim().isNotEmpty)
                        ? order.cancellationReason!
                        : 'Pesanan ini telah dibatalkan dan tidak dilanjutkan ke tahap berikutnya.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF7F1D1D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final stages = _buildSequentialStages();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(stages.length, (idx) {
              final s = stages[idx];
              final isDone = s['done'] as bool;
              final isCurrent = s['active'] as bool;
              final stageIcon = s['icon'] as IconData;
              final isLast = idx == stages.length - 1;
              final stageColor = isDone
                  ? GageTheme.primary
                  : (isCurrent
                      ? GageTheme.primary.withValues(alpha: 0.14)
                      : (isDark ? Colors.white12 : Colors.grey.shade200));
              final stageWidget = AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: stageColor,
                  border: isCurrent && !isDone
                      ? Border.all(color: GageTheme.primary, width: 1.8)
                      : null,
                ),
                child: Icon(
                  stageIcon,
                  color: isDone
                      ? Colors.white
                      : (isCurrent
                          ? GageTheme.primary
                          : (isDark ? Colors.white54 : Colors.grey.shade500)),
                  size: 15,
                ),
              );

              return Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          stageWidget,
                          const SizedBox(height: 6),
                          Text(
                            s['title'] as String,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: (isDone || isCurrent) ? FontWeight.bold : FontWeight.normal,
                              color: (isDone || isCurrent)
                                  ? (isDark ? Colors.white : Colors.black87)
                                  : (isDark ? Colors.white38 : Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast)
                      if (isCurrent && !isDone)
                        _buildWalkingDotsConnector(isDark)
                      else
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 280),
                          width: 14,
                          height: 2,
                          color: ((stages[idx + 1]['done'] as bool) || (stages[idx + 1]['active'] as bool)) && isDone
                              ? GageTheme.primary
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                          margin: const EdgeInsets.only(bottom: 18),
                        ),
                  ],
                ),
              );
            }),
          ),
          if (order.isPickup && order.status == 'READY_FOR_PICKUP') ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withValues(alpha: 0.15) : const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.green.shade800 : const Color(0xFFBBF7D0)),
              ),
              child: Text(
                'Pesanan siap diambil. Tunjukkan nomor invoice ${order.orderNumber} kepada petugas merchant.',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.green.shade200 : const Color(0xFF166534),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  LatLng _resolveMerchantLocation(String mName) {
    if (order.pickupLat != null && order.pickupLng != null) {
      return LatLng(order.pickupLat!, order.pickupLng!);
    }
    if (mName.trim().isNotEmpty) {
      final matches = PracimantoroPlacesDatabase.searchLocalPlaces(mName);
      if (matches.isNotEmpty) {
        return matches.first.location;
      }
    }
    return PracimantoroPlacesDatabase.centerPracimantoro;
  }

  Widget _buildWalkingDotsConnector(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: AnimatedBuilder(
        animation: _dotsCtrl,
        builder: (context, _) {
          final step = (_dotsCtrl.value * 3).floor() % 3;
          return SizedBox(
            width: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(3, (dotIdx) {
                final isLit = dotIdx == step;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isLit
                        ? GageTheme.primary
                        : GageTheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                  ),
                );
              }),
            ),
          );
        },
      ),
    );
  }

  void _showMerchantMapDialog(BuildContext context, String merchantName, String address, LatLng location) {
    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.isTransportService ? 'Lokasi Penjemputan' : 'Lokasi Toko Mitra',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        merchantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AspectRatio(
              aspectRatio: 1.0,
              child: MiniLocationPreviewMap(
                location: location,
                width: double.infinity,
                height: double.infinity,
                borderRadius: 16,
                zoom: 16.8,
                markerImagePath: order.isTransportService ? null : order.resolveMerchantAvatarAsset(merchantName),
                useMerchantPin: !order.isTransportService,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              address,
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMerchantSection(bool isDark) {
    final merchants = order.merchantNamesList;
    final headerTitle = order.isTransportService
        ? 'Layanan GAGE'
        : (merchants.length > 1 ? 'Mitra Toko (${merchants.length} Toko)' : 'Mitra Toko');
    final displayAddress = order.isTransportService
        ? (order.pickupAddress ?? order.merchantAddress)
        : order.merchantAddress;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                headerTitle,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13.5,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              if (merchants.length > 1 && !order.isTransportService) ...[
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.orange.withValues(alpha: 0.18) : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: const Text('Multi-Merchant', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...merchants.map((mName) {
            final avatarAsset = order.resolveMerchantAvatarAsset(mName);
            final merchantLoc = _resolveMerchantLocation(mName);
            final modeLabel = order.isPickup
                ? 'Ambil di Toko Mitra'
                : (order.isTransportService
                    ? 'Layanan ${order.serviceType.toUpperCase()}'
                    : 'GAGE ${order.serviceType.toUpperCase()}');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GageAvatar(
                    imageUrl: avatarAsset,
                    fallbackName: mName,
                    radius: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: order.isPickup
                                ? (isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFDCFCE7))
                                : (isDark ? GageTheme.darkElevated : const Color(0xFFF1F5F9)),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            modeLabel,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: order.isPickup
                                  ? (isDark ? Colors.green.shade300 : const Color(0xFF166534))
                                  : (isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          mName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayAddress,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Stack(
                    children: [
                      MiniLocationPreviewMap(
                        location: merchantLoc,
                        size: 58,
                        borderRadius: 10,
                        zoom: 16.5,
                        markerImagePath: order.isTransportService ? null : avatarAsset,
                        onTap: () => _showMerchantMapDialog(context, mName, displayAddress, merchantLoc),
                      ),
                      Positioned(
                        bottom: 3,
                        right: 3,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 11),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildItemsSection(NumberFormat formatter, bool isDark) {
    final pkg = order.packageDetails;
    if (order.isTransportService) {
      final svc = order.serviceType.toLowerCase();
      final isSend = svc == 'send';
      final serviceLabel = isSend
          ? 'GAGE Send'
          : (svc == 'car' ? 'GAGE Car' : 'GAGE Ride');
      final baseFare = order.itemsSubtotal > 0
          ? order.itemsSubtotal
          : (order.shippingFee > 0
              ? order.shippingFee
              : (order.items.isNotEmpty ? order.items.first.price : order.totalAmount));
      final pkgType = (pkg?['package_type'] ?? pkg?['category'] ?? '').toString().trim();
      final weightTier = (pkg?['weight_tier'] ?? pkg?['weight'] ?? '').toString().trim();
      final desc = (pkg?['description'] ?? pkg?['item_name'] ?? '').toString().trim();
      final recipientName = (pkg?['recipient_name'] ?? '').toString().trim();
      final recipientPhone = (pkg?['recipient_phone'] ?? '').toString().trim();

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSend
                      ? Icons.local_shipping_outlined
                      : (svc == 'car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded),
                  size: 18,
                  color: GageTheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isSend ? 'Detail Pengiriman & Barang' : 'Rincian Perjalanan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    isSend
                        ? (order.deliveryOption.toUpperCase().contains('HEMAT') ? 'Hemat' : 'Instant')
                        : order.deliveryOption,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildRowDetail(
              'Layanan',
              isSend
                  ? '$serviceLabel (${order.deliveryOption.toUpperCase().contains('HEMAT') ? 'Hemat' : 'Instant'})'
                  : '$serviceLabel (${order.deliveryOption})',
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildRowDetail(
              isSend ? 'Jarak Pengiriman' : 'Jarak Perjalanan',
              '${order.distanceKm.toStringAsFixed(1)} km',
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _buildRowDetail(
              isSend ? 'Tarif Ongkir' : 'Tarif Perjalanan',
              formatter.format(baseFare),
              isDark: isDark,
            ),
            if (isSend) ...[
              if (pkgType.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRowDetail('Jenis Barang', pkgType, isDark: isDark),
              ],
              if (weightTier.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRowDetail('Berat Paket', weightTier, isDark: isDark),
              ],
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRowDetail('Deskripsi Barang', desc, isDark: isDark),
              ],
              if (recipientName.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRowDetail('Penerima', recipientName, isDark: isDark),
              ],
              if (recipientPhone.isNotEmpty) ...[
                const SizedBox(height: 6),
                _buildRowDetail('No. HP Penerima', recipientPhone, isDark: isDark),
              ],
            ],
            if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Catatan Driver: ${order.notes!.trim()}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final totalQty = order.items.fold<int>(0, (prev, e) => prev + e.quantity);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.items.isNotEmpty
                ? 'Daftar Menu / Produk ($totalQty Item)'
                : 'Detail Paket & Barang',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 50,
                      height: 50,
                      color: isDark ? GageTheme.darkElevated : Colors.grey.shade100,
                      child: _buildItemImage(item.imageUrl, item.name),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (item.merchantName != null && item.merchantName!.isNotEmpty)
                          Text(
                            item.merchantName!,
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                          ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text(
                            'Catatan: ${item.notes!}',
                            style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.quantity}x @ ${formatter.format(item.price)}',
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade700),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatter.format(item.subtotal > 0 ? item.subtotal : item.price * item.quantity),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }),
          if (pkg != null && pkg.isNotEmpty) ...[
            if (pkg['item_name'] != null && pkg['item_name'].toString().isNotEmpty)
              _buildRowDetail('Nama Barang', pkg['item_name'].toString(), isDark: isDark),
            if (pkg['category'] != null && pkg['category'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildRowDetail('Kategori Paket', pkg['category'].toString(), isDark: isDark),
            ],
            if (pkg['weight'] != null && pkg['weight'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildRowDetail('Berat Paket', pkg['weight'].toString(), isDark: isDark),
            ],
            if (pkg['recipient_name'] != null && pkg['recipient_name'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildRowDetail('Penerima', pkg['recipient_name'].toString(), isDark: isDark),
            ],
            if (pkg['recipient_phone'] != null && pkg['recipient_phone'].toString().isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildRowDetail('No. HP Penerima', pkg['recipient_phone'].toString(), isDark: isDark),
            ],
          ],
          if (order.notes != null && order.notes!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Catatan: ${order.notes!.trim()}',
              style: TextStyle(
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemImage(String? imageUrl, String itemName) {
    String? resolvedUrl = imageUrl;
    if (resolvedUrl == null || resolvedUrl.trim().isEmpty) {
      final nameLower = itemName.toLowerCase();
      if (nameLower.contains('dimsum') || nameLower.contains('siomay')) {
        resolvedUrl = 'assets/images/dish_dimsum_original.png';
      } else if (nameLower.contains('rocket') || nameLower.contains('ayam') || nameLower.contains('geprek')) {
        resolvedUrl = 'assets/images/resto_rocket_chicken.png';
      } else if (nameLower.contains('bakso') || nameLower.contains('urat')) {
        resolvedUrl = 'assets/images/dish_bakso_urat.png';
      } else if (nameLower.contains('mie')) {
        resolvedUrl = 'assets/images/resto_mie_ayam.png';
      } else if (nameLower.contains('seblak')) {
        resolvedUrl = 'assets/images/resto_seblak.png';
      } else if (nameLower.contains('roti')) {
        resolvedUrl = 'assets/images/resto_roti_gembong.png';
      } else if (nameLower.contains('beras') || nameLower.contains('minyak') || nameLower.contains('telur') || nameLower.contains('sembako')) {
        resolvedUrl = 'assets/images/prod_beras.png';
      } else if (nameLower.contains('pupuk') || nameLower.contains('benih')) {
        resolvedUrl = 'assets/images/prod_pupuk.png';
      } else if (nameLower.contains('pakan') || nameLower.contains('konsentrat')) {
        resolvedUrl = 'assets/images/prod_pakan.png';
      } else if (nameLower.contains('ride') || nameLower.contains('motor')) {
        resolvedUrl = 'assets/icons/ic_ride.png';
      } else if (nameLower.contains('car') || nameLower.contains('mobil')) {
        resolvedUrl = 'assets/icons/ic_car.png';
      } else {
        resolvedUrl = 'assets/images/dish_dimsum_original.png';
      }
    }

    final clean = resolvedUrl.trim();
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      return Image.network(
        clean,
        fit: BoxFit.cover,
        errorBuilder: (c, e, s) => Image.asset(
          'assets/images/dish_dimsum_original.png',
          fit: BoxFit.cover,
        ),
      );
    }
    return Image.asset(
      clean,
      fit: BoxFit.cover,
      errorBuilder: (c, e, s) => Image.asset(
        'assets/images/dish_dimsum_original.png',
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildDeliverySection(bool isDark) {
    final pickupLabel = order.isTransportService
        ? 'Titik Jemput'
        : 'Lokasi Merchant';
    final dropoffLabel = order.isPickup
        ? 'Ambil Sendiri di Toko'
        : (order.isTransportService ? 'Titik Tujuan' : 'Tujuan Pengantaran');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.isPickup ? 'Info Ambil Sendiri' : 'Alamat & Rute',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: order.isPickup
                      ? (isDark ? Colors.teal.withValues(alpha: 0.2) : const Color(0xFFCCFBF1))
                      : (isDark ? GageTheme.darkElevated : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order.isPickup ? 'Ambil Sendiri' : order.deliveryOption,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: order.isPickup
                        ? (isDark ? Colors.teal.shade200 : const Color(0xFF0F766E))
                        : (isDark ? Colors.white70 : const Color(0xFF475569)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (order.pickupAddress != null && order.pickupAddress!.trim().isNotEmpty) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.my_location_rounded, color: Color(0xFF16A34A), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pickupLabel,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.pickupAddress!.trim(),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dropoffLabel,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.isPickup ? order.merchantAddress : order.deliveryAddress,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!order.isPickup && order.distanceKm > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.route_rounded, color: GageTheme.primary, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Estimasi Jarak: ${order.distanceKm.toStringAsFixed(1)} km',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDriverSection(BuildContext context, bool isDark) {
    final vehicleLabel = [
      if (order.driverVehicle != null && order.driverVehicle!.trim().isNotEmpty) order.driverVehicle!.trim(),
      if (order.driverPlate != null && order.driverPlate!.trim().isNotEmpty) order.driverPlate!.trim(),
    ].join(' | ');
    final phone = order.driverPhone?.trim() ?? '';
    final hasValidPhone = phone.isNotEmpty && phone != '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          GageAvatar(
            imageUrl: order.driverAvatar,
            fallbackName: order.driverName ?? 'Driver GAGE',
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.driverName ?? 'Driver GAGE',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  vehicleLabel.isNotEmpty ? vehicleLabel : 'Mitra Driver GAGE',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                if (order.driverRating != null)
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 13, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 3),
                      Text(
                        order.driverRating!.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline_rounded, color: GageTheme.primary),
            tooltip: 'Chat Driver',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InAppChatScreen(
                    orderId: order.id,
                    recipientName: order.driverName ?? 'Driver GAGE',
                    recipientRole: 'driver',
                    recipientPhone: phone,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.phone_rounded,
              color: hasValidPhone ? GageTheme.primary : (isDark ? Colors.white30 : Colors.grey.shade400),
            ),
            tooltip: 'Telepon Driver',
            onPressed: () async {
              if (!hasValidPhone) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor telepon driver belum tersedia.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              final uri = Uri.parse('tel:$phone');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard(NumberFormat formatter, bool isDark) {
    final subtotalLabel = order.isTransportService ? 'Tarif Layanan' : 'Subtotal Pesanan';
    final shippingLabel = order.isTransportService ? 'Biaya Jarak & Opsi' : 'Biaya Ongkos Kirim';
    final isPaid = order.paymentStatus == 'PAID';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Pembayaran',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13.5,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          _buildRowDetail(subtotalLabel, formatter.format(order.itemsSubtotal), isDark: isDark),
          if (!order.isPickup) ...[
            const SizedBox(height: 6),
            _buildRowDetail(shippingLabel, formatter.format(order.shippingFee), isDark: isDark),
          ],
          if (order.shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildRowDetail('Diskon & Voucher', '- ${formatter.format(order.shippingDiscount)}', isDiscount: true, isDark: isDark),
          ],
          if (order.driverTip > 0) ...[
            const SizedBox(height: 6),
            _buildRowDetail('Tip Driver', formatter.format(order.driverTip), isDark: isDark),
          ],
          const SizedBox(height: 6),
          _buildRowDetail('Biaya Layanan & Admin', formatter.format(order.adminFee), isDark: isDark),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Pembayaran',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                formatter.format(order.totalAmount),
                style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkElevated : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.payment_rounded, size: 16, color: isDark ? Colors.white70 : Colors.black54),
                    const SizedBox(width: 6),
                    Text(
                      'Metode: ${_formatPaymentMethod(order.paymentMethod)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  isPaid ? 'LUNAS' : 'BELUM BAYAR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isPaid
                        ? (isDark ? Colors.green.shade300 : Colors.green.shade700)
                        : (isDark ? Colors.orange.shade300 : Colors.orange.shade800),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRowDetail(String label, String value, {bool isDiscount = false, bool isDark = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : GageTheme.textSecondary)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDiscount
                  ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                  : (isDark ? Colors.white : Colors.black87),
            ),
          ),
        ),
      ],
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toUpperCase()) {
      case 'GAGEPAY':
        return 'GAGE Pay';
      case 'QRIS':
        return 'QRIS';
      case 'CASH_COD':
      case 'COD':
        return 'Tunai (COD)';
      default:
        return method;
    }
  }

  Widget _buildRatingReviewSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.amber.shade700.withValues(alpha: 0.45) : const Color(0xFFFEF08A)),
        boxShadow: isDark ? null : const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 6),
              Text(
                _isReviewed ? 'Penilaian Telah Dikirim' : 'Beri Penilaian Pesanan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _isReviewed
                ? 'Terima kasih telah membantu mitra merchant & driver GAGE!'
                : 'Ketuk bintang untuk menilai kualitas layanan pesanan ini',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final starIndex = index + 1;
              final isFilled = starIndex <= (_selectedStar > 0 ? _selectedStar : 0);
              return InkWell(
                onTap: _isReviewed
                    ? null
                    : () async {
                        final res = await RatingReviewSheet.show(
                          context,
                          orderId: order.id,
                          merchantId: order.merchantId,
                          serviceType: order.serviceType,
                          merchantName: order.merchantName,
                          merchantAvatar: order.merchantAvatar,
                          driverName: order.driverName ?? '',
                          driverAvatar: order.driverAvatar,
                          driverVehicle: order.driverVehicle ?? order.driverPlate,
                          initialStar: starIndex,
                          onSubmitted: (mRating, dRating) {
                            setState(() {
                              _selectedStar = starIndex;
                              _isReviewed = true;
                            });
                          },
                        );
                        if (res == true && mounted) {
                          setState(() {
                            _selectedStar = starIndex;
                            _isReviewed = true;
                          });
                        }
                      },
                borderRadius: BorderRadius.circular(999),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    size: 34,
                    color: isFilled ? const Color(0xFFF59E0B) : Colors.amber.shade300,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 12),
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
                      side: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Kembali', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
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

    if (confirmed == true && mounted) {
      final orderProvider = this.context.read<OrderProvider>();
      final ok = await orderProvider.updateOrderStage(
        order.id,
        'CANCELLED',
        reason: 'Dibatalkan oleh pelanggan',
      );
      if (!mounted) return;
      if (ok) {
        setState(() {
          _currentOrder = _currentOrder.copyWith(
            status: 'CANCELLED',
            cancellationReason: 'Dibatalkan oleh pelanggan',
          );
        });
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openSupportChat(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InAppChatScreen(
          orderId: order.id,
          recipientName: 'Pusat Bantuan GAGE',
          recipientRole: 'ai',
          recipientPhone: '',
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final canTrack = order.isActive &&
        !order.isPickup &&
        order.status != 'PAYMENT_PENDING' &&
        order.status != 'PENDING';
    final trackLabel = order.isTransportService ? 'Lacak Driver' : 'Pantau Pengantaran';
    final canCancel = order.canBeCancelledByCustomer;

    if (order.isActive) {
      return SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          color: Colors.transparent,
          child: Row(
            children: [
              if (canCancel) ...[
                Expanded(
                  flex: 3,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isDark ? Colors.red.withValues(alpha: 0.12) : const Color(0xFFFEF2F2),
                      foregroundColor: const Color(0xFFDC2626),
                      side: BorderSide(color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA), width: 1.4),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => _confirmCancelOrder(context),
                    icon: const Icon(Icons.cancel_outlined, size: 16),
                    label: const Text('Batalkan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                flex: canTrack ? 2 : (canCancel ? 3 : 2),
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                    foregroundColor: GageTheme.primary,
                    side: const BorderSide(color: GageTheme.primary, width: 1.5),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () => _openSupportChat(context),
                  icon: const Icon(Icons.support_agent_rounded, size: 18),
                  label: const Text('Bantuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
              if (canTrack) ...[
                const SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 2,
                    ),
                    icon: const Icon(Icons.navigation_rounded, size: 18),
                    label: Text(trackLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
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
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        color: Colors.transparent,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300, width: 1.2),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _openSupportChat(context),
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Bantuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: (order.items.isNotEmpty && !order.isTransportService)
                  ? ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      onPressed: () {
                        _reorder(context, order);
                      },
                      child: const Text('Pesan Lagi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    )
                  : ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 2,
                      ),
                      onPressed: () => GageReceiptShareDialog.show(context, order),
                      icon: const Icon(Icons.receipt_long_rounded, size: 18),
                      label: const Text('Struk Gambar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    ),
            ),
          ],
        ),
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
}
