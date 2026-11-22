import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_thermal_receipt_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Halaman Layar Penuh (Full-Screen Menu) untuk Rincian Lengkap Pesanan Mitra Usaha GAGE.
/// Dirancang dengan standar kemewahan (luxury / anti-slop) ala Customer Portal & NUSA Kasir:
/// - Layout lapang, breathing room proporsional, dan hirarki kartu yang bersih.
/// - PIN Serah Terima Kurir terpusat dengan live countdown timer pergantian.
/// - Countdown batas waktu penyiapan pesanan (SLA) & peringatan penalti performa toko.
/// - Sticky bottom operational action bar dengan full capsule (StadiumBorder).
class MerchantOrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  final NumberFormat currencyFormatter;

  const MerchantOrderDetailScreen({
    super.key,
    required this.order,
    required this.currencyFormatter,
  });

  @override
  State<MerchantOrderDetailScreen> createState() => _MerchantOrderDetailScreenState();
}

class _MerchantOrderDetailScreenState extends State<MerchantOrderDetailScreen> {
  late OrderModel _currentOrder;
  Timer? _tickerTimer;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    super.dispose();
  }

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y, $h:$min';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final provider = context.watch<MerchantOrderProvider>();
    final latestOrder = provider.orders.firstWhere(
      (o) => o.id == _currentOrder.id,
      orElse: () => _currentOrder,
    );

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  latestOrder.orderNumber.contains('/')
                      ? '#${latestOrder.orderNumber.split('/').last}'
                      : '#${latestOrder.orderNumber}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: latestOrder.isPickup
                        ? const Color(0xFFEFF6FF)
                        : const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    latestOrder.isPickup ? 'Ambil Sendiri' : 'Pesan Antar',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: latestOrder.isPickup
                          ? const Color(0xFF1D4ED8)
                          : const Color(0xFF047857),
                    ),
                  ),
                ),
              ],
            ),
            Text(
              _formatDateTime(latestOrder.createdAt),
              style: TextStyle(fontSize: 11, color: subColor),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              MerchantThermalReceiptSheet.show(
                context,
                latestOrder,
                currencyFormatter: widget.currencyFormatter,
              );
            },
            icon: Icon(Icons.print_outlined, color: textColor, size: 22),
            tooltip: 'Cetak Struk Thermal',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Status Banner Operasional Universal
            _buildStatusCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 2. PIN Serah Terima Kurir / Pelanggan (Tanpa Solid Divider)
            _buildPinCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 3. Info Pelanggan & Kurir GAGE
            _buildCustomerAndDriverCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 4. Daftar Rincian Produk (Tanpa Solid Divider)
            _buildItemsCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 5. Transparansi Finansial & Penerimaan Bersih Toko (Tanpa Solid Divider)
            _buildFinancialSummaryCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Row(
          children: [
            // Tombol Cetak Cepat
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: const StadiumBorder(),
                side: BorderSide(color: borderColor),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
              ),
              onPressed: () {
                MerchantThermalReceiptSheet.show(
                  context,
                  latestOrder,
                  currencyFormatter: widget.currencyFormatter,
                );
              },
              child: Icon(Icons.print_rounded, size: 18, color: textColor),
            ),
            const SizedBox(width: 10),

            // Tombol Aksi Utama Sesuai Status
            Expanded(
              child: _buildStageButton(context, latestOrder, provider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    Color badgeBg;
    Color badgeFg;
    IconData statusIcon;
    String statusTitle;
    String statusDesc;

    switch (order.status) {
      case 'NEW':
      case 'PAID':
        badgeBg = const Color(0xFFEFF6FF);
        badgeFg = const Color(0xFF2563EB);
        statusIcon = Icons.notifications_active_rounded;
        statusTitle = 'Pesanan Baru Masuk';
        statusDesc = 'Segera konfirmasi dan mulai siapkan barang pesanan.';
        break;
      case 'COOKING':
        badgeBg = const Color(0xFFFEF3C7);
        badgeFg = const Color(0xFFD97706);
        statusIcon = Icons.timer_rounded;
        statusTitle = 'Sedang Disiapkan';
        statusDesc = 'Produk sedang dikemas / diproses di etalase toko.';
        break;
      case 'READY_FOR_PICKUP':
      case 'DRIVER_ASSIGNED':
      case 'AT_MERCHANT':
        badgeBg = const Color(0xFFECFDF5);
        badgeFg = const Color(0xFF059669);
        statusIcon = Icons.check_circle_rounded;
        statusTitle = 'Pesanan Siap Diambil';
        statusDesc = 'Toko telah menyelesaikan penyiapan, menunggu kurir / pembeli.';
        break;
      case 'PICKED_UP':
      case 'ON_DELIVERY':
        badgeBg = const Color(0xFFF3E8FF);
        badgeFg = const Color(0xFF9333EA);
        statusIcon = Icons.delivery_dining_rounded;
        statusTitle = 'Sedang Diantar';
        statusDesc = 'Kurir sedang dalam perjalanan menuju alamat pelanggan.';
        break;
      case 'COMPLETED':
        badgeBg = const Color(0xFFECFDF5);
        badgeFg = const Color(0xFF059669);
        statusIcon = Icons.task_alt_rounded;
        statusTitle = 'Pesanan Selesai';
        statusDesc = 'Transaksi tuntas. Dana telah dikreditkan ke saldo GagePay.';
        break;
      case 'CANCELLED':
      default:
        badgeBg = const Color(0xFFFEF2F2);
        badgeFg = const Color(0xFFDC2626);
        statusIcon = Icons.cancel_rounded;
        statusTitle = 'Pesanan Dibatalkan';
        statusDesc = order.cancellationReason ?? 'Pesanan dibatalkan.';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: badgeBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(statusIcon, color: badgeFg, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      statusTitle,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        order.status,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  statusDesc,
                  style: TextStyle(fontSize: 11.5, color: subColor, height: 1.3),
                ),
                if (order.status == 'COOKING') ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: GageTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: GageTheme.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Batas Waktu Penyiapan: ${order.formattedCookingTimeRemaining}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: GageTheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Selesaikan sebelum waktu habis untuk menghindari penalti performa toko (-1 Poin).',
                    style: TextStyle(
                      fontSize: 10.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFFECACA),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pin_rounded, color: GageTheme.primary, size: 18),
              const SizedBox(width: 6),
              Text(
                'PIN VERIFIKASI SERAH TERIMA',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : GageTheme.primary,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: GageTheme.primary.withValues(alpha: 0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: GageTheme.primary.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              order.courierVerificationPin.split('').join('   '),
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 4,
                color: GageTheme.primary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sebutkan 4-digit PIN ini kepada kurir / pembeli saat penyerahan barang agar transaksi tuntas dan aman.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subColor, height: 1.3),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: GageTheme.primary.withValues(alpha: isDark ? 0.20 : 0.08),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.timer_outlined, size: 13, color: GageTheme.primary),
                const SizedBox(width: 5),
                Text(
                  'Berganti otomatis dalam ${order.formattedPinTimeRemaining}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isDark ? const Color(0xFFFCA5A5) : GageTheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerAndDriverCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Informasi Pelanggan (Avatar Border Lingkaran)
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: order.customerAvatar != null && order.customerAvatar!.isNotEmpty
                      ? Image.network(
                          order.customerAvatar!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.person_rounded,
                            size: 20,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          size: 20,
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.customerName ?? 'Pelanggan GAGE',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    Text(
                      order.deliveryAddress,
                      style: TextStyle(fontSize: 11, color: subColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InAppChatScreen(
                        recipientName: order.customerName ?? 'Pelanggan GAGE',
                        recipientRole: 'customer',
                        orderId: order.orderNumber,
                        recipientPhone: order.customerPhone ?? '',
                        currentRole: 'merchant',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: GageTheme.primary),
                tooltip: 'Chat Pelanggan',
              ),
            ],
          ),

          if (order.notes != null && order.notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.notes_rounded, size: 14, color: GageTheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Catatan: ${order.notes}',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: subColor,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // 2. Informasi Kurir (Jika order delivery dan driver sudah ada)
          if (order.hasAssignedDriver) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(height: 1, thickness: 0.8, color: borderColor),
            ),
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: GageTheme.primary.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                  ),
                  child: ClipOval(
                    child: order.driverAvatar != null && order.driverAvatar!.isNotEmpty
                        ? Image.network(
                            order.driverAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.two_wheeler_rounded,
                              size: 18,
                              color: GageTheme.primary,
                            ),
                          )
                        : const Icon(
                            Icons.two_wheeler_rounded,
                            size: 18,
                            color: GageTheme.primary,
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.driverName!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        '${order.driverVehicle ?? "Kurir G-Ride"} • ${order.driverPlate ?? "-"}',
                        style: TextStyle(fontSize: 11, color: subColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InAppChatScreen(
                          recipientName: order.driverName!,
                          recipientRole: 'driver',
                          orderId: order.orderNumber,
                          recipientPhone: order.driverPhone ?? '',
                          currentRole: 'merchant',
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: GageTheme.primary),
                  tooltip: 'Chat Kurir',
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildItemsCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Item Pesanan',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: textColor,
                ),
              ),
              Text(
                '${order.items.length} Macam',
                style: TextStyle(fontSize: 11.5, color: subColor, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in order.items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
                          ? Image.network(
                              item.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.inventory_2_outlined,
                                size: 18,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              size: 18,
                              color: isDark ? Colors.white54 : Colors.grey.shade500,
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text(
                            item.notes!,
                            style: TextStyle(fontSize: 11, color: subColor),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    widget.currencyFormatter.format(item.subtotal),
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummaryCard(
    OrderModel order,
    bool isDark,
    Color cardBg,
    Color textColor,
    Color subColor,
    Color borderColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rincian Pembayaran & Pendapatan',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 10),
          _buildRow('Subtotal Produk', widget.currencyFormatter.format(order.itemsSubtotal), textColor, subColor),
          _buildRow('Ongkos Kirim', widget.currencyFormatter.format(order.shippingFee), textColor, subColor),
          _buildRow('Biaya Layanan', widget.currencyFormatter.format(order.adminFee), textColor, subColor),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 12, thickness: 0.8, color: borderColor),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Bayar Pelanggan',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: textColor),
                ),
                Text(
                  widget.currencyFormatter.format(order.totalAmount),
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: textColor),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Divider(height: 12, thickness: 0.8, color: borderColor),
          ),
          _buildRow(
            'Potongan Komisi GAGE (10%)',
            '- ${widget.currencyFormatter.format(order.platformCommissionAmount)}',
            const Color(0xFFDC2626),
            subColor,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendapatan Bersih Toko',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF065F46),
                      ),
                    ),
                    Text(
                      'Otomatis cair ke saldo GagePay',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
                Text(
                  widget.currencyFormatter.format(order.merchantNetPayout),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, Color textCol, Color subCol) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: subCol)),
          Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textCol)),
        ],
      ),
    );
  }

  Widget _buildStageButton(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider provider,
  ) {
    if (order.status == 'NEW' || order.status == 'PAID') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GageTheme.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        onPressed: () async {
          await provider.acceptOrder(order.id);
          if (context.mounted) {
            final msg = (provider.autoPrintOnAccept && provider.printerConnected)
                ? 'Pesanan diterima & ${provider.receiptCopies} rangkap struk dicetak otomatis!'
                : 'Pesanan diterima! Mulai siapkan.';
            GageToast.show(context, msg);
          }
        },
        child: const Text('Terima Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
      );
    }

    if (order.status == 'COOKING') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GageTheme.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        onPressed: () async {
          await provider.markReadyForPickup(order.id);
          if (context.mounted) {
            GageToast.show(context, 'Pesanan siap diambil kurir / pembeli!');
          }
        },
        child: const Text('Pesanan Siap Diambil', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
      );
    }

    if (order.status == 'READY_FOR_PICKUP' || order.status == 'AT_MERCHANT') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: GageTheme.primary,
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 14),
          elevation: 0,
        ),
        onPressed: () async {
          await provider.handoverToCourier(order.id);
          if (context.mounted) {
            GageToast.show(context, 'Pesanan berhasil diserahkan!');
          }
        },
        child: const Text('Serahkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: () => Navigator.of(context).pop(),
      child: const Text('Kembali ke Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
    );
  }
}
