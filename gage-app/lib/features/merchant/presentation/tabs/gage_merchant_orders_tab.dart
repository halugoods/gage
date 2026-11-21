import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_order_detail_sheet.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_thermal_receipt_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 0: Pesanan Masuk & Dapur (Workstation Mitra Usaha GAGE)
/// Dilengkapi 4 Segmented Tab Kapsul GAGE:
/// - Disiapkan (NEW, PAID, COOKING)
/// - Siap Diambil (READY_FOR_PICKUP, DRIVER_ASSIGNED, AT_MERCHANT)
/// - Sedang Diantar (PICKED_UP, ON_DELIVERY)
/// - Selesai (COMPLETED, CANCELLED)
/// Serta penampil PIN Penyerahan 4-digit yang diinput oleh mitra driver.
class GageMerchantOrdersTab extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const GageMerchantOrdersTab({
    super.key,
    required this.currencyFormatter,
  });

  @override
  State<GageMerchantOrdersTab> createState() => _GageMerchantOrdersTabState();
}

class _GageMerchantOrdersTabState extends State<GageMerchantOrdersTab> {
  int _activeSegment = 0; // 0: Disiapkan, 1: Siap Diambil, 2: Sedang Diantar, 3: Selesai

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    switch (_activeSegment) {
      case 0:
        return orders.where((o) =>
            o.status == 'NEW' || o.status == 'PAID' || o.status == 'COOKING').toList();
      case 1:
        return orders.where((o) =>
            o.status == 'READY_FOR_PICKUP' ||
            o.status == 'DRIVER_ASSIGNED' ||
            o.status == 'AT_MERCHANT').toList();
      case 2:
        return orders.where((o) =>
            o.status == 'PICKED_UP' || o.status == 'ON_DELIVERY').toList();
      case 3:
        return orders.where((o) =>
            o.status == 'COMPLETED' || o.status == 'CANCELLED').toList();
      default:
        return orders;
    }
  }

  String _formatTimeElapsed(int createdAt) {
    if (createdAt <= 0) return 'Baru saja';
    final nowSec = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final diffMinutes = (nowSec - createdAt) ~/ 60;
    if (diffMinutes < 1) return 'Baru saja';
    if (diffMinutes < 60) return '$diffMinutes mnt lalu';
    final diffHours = diffMinutes ~/ 60;
    return '$diffHours jam lalu';
  }

  void _showRejectOrderDialog(BuildContext context, OrderModel order) {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reasons = [
      'Bahan baku habis',
      'Kios sedang sangat ramai / antre',
      'Toko bersiap tutup',
      'Lainnya',
    ];
    String selectedReason = reasons.first;

    GageFloatingSheet.show(
      context: context,
      title: 'Tolak Pesanan #${order.orderNumber}',
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pilih alasan resmi penolakan untuk pelanggan:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              ...reasons.map((r) {
                final isSelected = selectedReason == r;
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setSheetState(() => selectedReason = r);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary.withValues(alpha: isDark ? 0.20 : 0.08)
                          : (isDark ? Colors.white.withValues(alpha: 0.04) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          size: 18,
                          color: isSelected ? GageTheme.primary : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          r,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        context.read<MerchantOrderProvider>().rejectOrder(order.id, selectedReason);
                        GageToast.show(context, 'Pesanan #${order.orderNumber} telah ditolak');
                      },
                      child: const Text('Konfirmasi Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();
    final allOrders = provider.orders;

    final countDisiapkan = allOrders.where((o) =>
        o.status == 'NEW' || o.status == 'PAID' || o.status == 'COOKING').length;
    final countSiap = allOrders.where((o) =>
        o.status == 'READY_FOR_PICKUP' ||
        o.status == 'DRIVER_ASSIGNED' ||
        o.status == 'AT_MERCHANT').length;
    final countDiantar = allOrders.where((o) =>
        o.status == 'PICKED_UP' || o.status == 'ON_DELIVERY').length;
    final countSelesai = allOrders.where((o) =>
        o.status == 'COMPLETED' || o.status == 'CANCELLED').length;

    final displayedOrders = _filterOrders(allOrders);

    return Column(
      children: [
        // 1. Segmented Tab Switch Kapsul Penuh (BorderRadius.circular(999))
        Container(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: Container(
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                _buildSegmentItem(
                  index: 0,
                  label: 'Disiapkan',
                  count: countDisiapkan,
                  isDark: isDark,
                ),
                _buildSegmentItem(
                  index: 1,
                  label: 'Siap',
                  count: countSiap,
                  isDark: isDark,
                ),
                _buildSegmentItem(
                  index: 2,
                  label: 'Diantar',
                  count: countDiantar,
                  isDark: isDark,
                ),
                _buildSegmentItem(
                  index: 3,
                  label: 'Selesai',
                  count: countSelesai,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),

        // 2. Daftar Pesanan Interaktif (Breathing Room Lapang)
        Expanded(
          child: displayedOrders.isEmpty
              ? _buildEmptyState(isDark)
              : RefreshIndicator(
                  color: GageTheme.primary,
                  onRefresh: () => provider.fetchOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
                    itemCount: displayedOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final order = displayedOrders[index];
                      return _buildOrderCard(context, order, provider, isDark);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSegmentItem({
    required int index,
    required String label,
    required int count,
    required bool isDark,
  }) {
    final isSelected = _activeSegment == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_activeSegment == index) return;
          HapticFeedback.selectionClick();
          setState(() => _activeSegment = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GageTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                ),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.white : (isDark ? Colors.white24 : Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? GageTheme.primary : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
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

  Widget _buildOrderCard(
    BuildContext context,
    OrderModel order,
    MerchantOrderProvider provider,
    bool isDark,
  ) {
    final isCooking = order.status == 'COOKING' || order.status == 'NEW' || order.status == 'PAID';
    final isReadyForPickup = order.status == 'READY_FOR_PICKUP' ||
        order.status == 'DRIVER_ASSIGNED' ||
        order.status == 'AT_MERCHANT';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        MerchantOrderDetailSheet.show(
          context,
          order,
          currencyFormatter: widget.currencyFormatter,
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Baris 1: Header Invoice & Jenis Layanan
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.10),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            order.orderNumber.contains('/')
                                ? '#${order.orderNumber.split('/').last}'
                                : '#${order.orderNumber}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: GageTheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: order.isPickup
                              ? const Color(0xFFEFF6FF)
                              : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          order.isPickup ? 'Ambil di Toko' : 'Pesan Antar',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: order.isPickup
                                ? const Color(0xFF1D4ED8)
                                : const Color(0xFF047857),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        MerchantThermalReceiptSheet.show(
                          context,
                          order,
                          currencyFormatter: widget.currencyFormatter,
                        );
                      },
                      icon: Icon(
                        Icons.print_outlined,
                        size: 18,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                      tooltip: 'Cetak Struk Thermal',
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _formatTimeElapsed(order.createdAt),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 10),
            Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
            const SizedBox(height: 10),

          // Baris 2: Informasi Pelanggan & Catatan
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 16,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  order.customerName ?? 'Pelanggan GAGE',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              if (order.hasAssignedDriver) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 14, color: GageTheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        order.driverName ?? 'Driver',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Baris 3: Daftar Menu Hidangan
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.quantity}x',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white54 : Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      widget.currencyFormatter.format(item.price * item.quantity),
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              )),

          const SizedBox(height: 8),
          Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
          const SizedBox(height: 10),

          // Baris 4: Pendapatan Bersih Toko
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pendapatan Bersih Toko:',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
              Text(
                widget.currencyFormatter.format(order.merchantNetPayout),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF16A34A),
                ),
              ),
            ],
          ),

          // Baris 5: PIN Penyerahan ke Driver (Merchant Generate / Display)
          if (isReadyForPickup && !order.isPickup) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PIN Penyerahan ke Driver',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF92400E),
                          ),
                        ),
                        Text(
                          'Tunjukkan PIN ini ke Driver saat mengambil makanan',
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.courierVerificationPin,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 3,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 14),

          // Baris 6: Tombol Aksi Ergonomis
          Row(
            children: [
              // Tombol Chat Pelanggan/Driver
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  side: BorderSide(
                    color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                  ),
                ),
                icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                label: const Text('Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InAppChatScreen(
                        recipientName: order.hasAssignedDriver
                            ? (order.driverName ?? 'Driver GAGE')
                            : (order.customerName ?? 'Pelanggan GAGE'),
                        recipientRole: order.hasAssignedDriver ? 'driver' : 'customer',
                        orderId: order.orderNumber,
                        recipientPhone: order.hasAssignedDriver
                            ? (order.driverPhone ?? '')
                            : (order.customerPhone ?? ''),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(width: 8),

              // Tombol Tolak jika masih baru
              if (order.status == 'NEW' || order.status == 'PAID') ...[
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    side: const BorderSide(color: Color(0xFFFCA5A5)),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onPressed: () => _showRejectOrderDialog(context, order),
                  child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
              ],

              // Tombol Utama Aksi Operasional
              Expanded(
                child: isCooking
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          provider.markReadyForPickup(order.id);
                          GageToast.show(context, 'Makanan #${order.orderNumber} siap diambil!');
                        },
                        child: const Text(
                          'Pesanan Siap Diambil',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                      )
                    : (isReadyForPickup && order.isPickup)
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              shape: const StadiumBorder(),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              elevation: 0,
                            ),
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              provider.completeOrder(order.id);
                              GageToast.show(context, 'Pesanan #${order.orderNumber} telah diserahkan ke pelanggan');
                            },
                            child: const Text(
                              'Selesaikan (Ambil di Toko)',
                              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                            ),
                          )
                        : (order.status == 'COMPLETED')
                            ? Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFECFDF5),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  '✓ Transaksi Selesai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF047857),
                                  ),
                                ),
                              )
                            : (order.status == 'CANCELLED')
                                ? Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      'Pesanan Dibatalkan',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                  )
                                : Container(
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      order.statusLabel,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 36,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pesanan pada tahap ini akan otomatis muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
