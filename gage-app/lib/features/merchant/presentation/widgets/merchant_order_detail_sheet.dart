import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_thermal_receipt_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Modal Floating Sheet untuk Rincian Lengkap Pesanan Mitra Usaha GAGE
/// Memuat data pelanggan, catatan menu, verifikasi PIN penyerahan kurir,
/// transparansi margin MDR 10%, serta tombol aksi cetak struk thermal dan chat.
class MerchantOrderDetailSheet extends StatefulWidget {
  final OrderModel order;
  final NumberFormat currencyFormatter;

  const MerchantOrderDetailSheet({
    super.key,
    required this.order,
    required this.currencyFormatter,
  });

  static Future<void> show(
    BuildContext context,
    OrderModel order, {
    NumberFormat? currencyFormatter,
  }) {
    final formatter = currencyFormatter ??
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return GageFloatingSheet.show(
      context: context,
      title: 'Rincian Pesanan',
      builder: (sheetCtx) => MerchantOrderDetailSheet(
        order: order,
        currencyFormatter: formatter,
      ),
    );
  }

  @override
  State<MerchantOrderDetailSheet> createState() =>
      _MerchantOrderDetailSheetState();
}

class _MerchantOrderDetailSheetState extends State<MerchantOrderDetailSheet> {
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt);
  }

  void _regeneratePin(BuildContext context) {
    final provider = Provider.of<MerchantOrderProvider>(context, listen: false);
    final newPin = provider.regenerateHandoverPin(_currentOrder.id);
    if (newPin.isNotEmpty) {
      setState(() {
        _currentOrder = _currentOrder.copyWith(handoverPin: newPin);
      });
      GageToast.show(context, 'PIN Serah Terima diperbarui: $newPin');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = _currentOrder;
    final provider = context.watch<MerchantOrderProvider>();

    // Ambil order paling update dari provider jika ada perubahan state
    final latestOrder = provider.orders.firstWhere(
      (o) => o.id == order.id,
      orElse: () => order,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Invoice & Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          latestOrder.orderNumber,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      _buildStatusBadge(latestOrder.status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Waktu Pesan: ${_formatDateTime(latestOrder.createdAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 2. PIN Serah Terima Kurir (Merchant yang generate, Driver yang input)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFFECACA),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.pin_rounded, color: GageTheme.primary, size: 18),
                      const SizedBox(width: 6),
                      Text(
                        'PIN SERAH TERIMA KURIR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : GageTheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: GageTheme.primary.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      latestOrder.courierVerificationPin.split('').join('   '),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: GageTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sebutkan 4-digit PIN ini kepada mitra kurir saat menyerahkan makanan. Kurir akan memasukkan PIN ini di aplikasinya.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () => _regeneratePin(context),
                    borderRadius: BorderRadius.circular(999),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: GageTheme.primary),
                          const SizedBox(width: 4),
                          Text(
                            'Acak Ulang PIN',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: GageTheme.primary,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Info Pelanggan & Kurir
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pelanggan
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF2563EB), size: 18),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              latestOrder.customerName ?? 'Pelanggan GAGE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            Text(
                              latestOrder.deliveryAddress,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                              ),
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
                                recipientName: latestOrder.customerName ?? 'Pelanggan GAGE',
                                recipientRole: 'customer',
                                orderId: latestOrder.orderNumber,
                                recipientPhone: latestOrder.customerPhone ?? '',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF2563EB)),
                        tooltip: 'Chat Pelanggan',
                      ),
                    ],
                  ),
                  if (latestOrder.notes != null && latestOrder.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notes_rounded, size: 14, color: Color(0xFFB45309)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Catatan: ${latestOrder.notes}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (latestOrder.driverName != null) ...[
                    const SizedBox(height: 8),
                    Divider(height: 1, color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                    const SizedBox(height: 8),
                    // Kurir
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF059669), size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                latestOrder.driverName!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Plat: ${latestOrder.driverPlate ?? "-"} • ${latestOrder.driverPhone ?? "-"}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
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
                                  recipientName: latestOrder.driverName!,
                                  recipientRole: 'driver',
                                  orderId: latestOrder.orderNumber,
                                  recipientPhone: latestOrder.driverPhone ?? '',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20, color: Color(0xFF059669)),
                          tooltip: 'Chat Kurir',
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 4. Rincian Item Menu
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Item Pesanan (${latestOrder.items.length})',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final item in latestOrder.items) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey.shade800 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${item.quantity}x',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                if (item.notes != null && item.notes!.isNotEmpty)
                                  Text(
                                    item.notes!,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            widget.currencyFormatter.format(item.subtotal),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 5. Kalkulasi Transparansi Margin Toko
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rincian Pembayaran & Margin',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildFinancialRow(
                    'Subtotal Menu',
                    widget.currencyFormatter.format(latestOrder.itemsSubtotal),
                    isDark,
                  ),
                  _buildFinancialRow(
                    'Ongkos Kirim',
                    widget.currencyFormatter.format(latestOrder.shippingFee),
                    isDark,
                  ),
                  _buildFinancialRow(
                    'Biaya Layanan',
                    widget.currencyFormatter.format(latestOrder.adminFee),
                    isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                    ),
                  ),
                  _buildFinancialRow(
                    'Total Belanja Pelanggan',
                    widget.currencyFormatter.format(latestOrder.totalAmount),
                    isDark,
                    isBold: true,
                  ),
                  _buildFinancialRow(
                    'Komisi Platform GAGE (10%)',
                    '- ${widget.currencyFormatter.format(latestOrder.platformCommissionAmount)}',
                    isDark,
                    color: const Color(0xFFDC2626),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Divider(
                      height: 1,
                      color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pendapatan Bersih Toko',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          Text(
                            'Langsung masuk saldo GagePay',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark ? Colors.white60 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        widget.currencyFormatter.format(latestOrder.merchantNetPayout),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 6. Tombol Aksi Cetak Struk Thermal & Status
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: isDark ? Colors.white24 : Colors.grey.shade300,
                      ),
                    ),
                    onPressed: () {
                      MerchantThermalReceiptSheet.show(
                        context,
                        latestOrder,
                        currencyFormatter: widget.currencyFormatter,
                      );
                    },
                    icon: const Icon(Icons.print_rounded, size: 16),
                    label: const Text(
                      'Struk Thermal',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _buildStageActionButton(context, latestOrder, provider),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'NEW':
      case 'PAID':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF2563EB);
        label = 'Baru Masuk';
        break;
      case 'COOKING':
        bg = const Color(0xFFFEF3C7);
        fg = const Color(0xFFD97706);
        label = 'Sedang Disiapkan';
        break;
      case 'READY_FOR_PICKUP':
      case 'DRIVER_ASSIGNED':
      case 'AT_MERCHANT':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Siap Diambil';
        break;
      case 'PICKED_UP':
      case 'ON_DELIVERY':
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF9333EA);
        label = 'Sedang Diantar';
        break;
      case 'COMPLETED':
        bg = const Color(0xFFECFDF5);
        fg = const Color(0xFF059669);
        label = 'Selesai';
        break;
      case 'CANCELLED':
      default:
        bg = const Color(0xFFFEF2F2);
        fg = const Color(0xFFDC2626);
        label = 'Dibatalkan';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }

  Widget _buildFinancialRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageActionButton(
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
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          await provider.acceptOrder(order.id);
          if (context.mounted) {
            GageToast.show(context, 'Pesanan diterima! Mulai memasak.');
          }
        },
        child: const Text('Terima & Masak', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (order.status == 'COOKING') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF059669),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          await provider.markReadyForPickup(order.id);
          if (context.mounted) {
            GageToast.show(context, 'Pesanan siap diambil kurir!');
          }
        },
        child: const Text('Pesanan Siap', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    if (order.status == 'READY_FOR_PICKUP' || order.status == 'AT_MERCHANT') {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: () async {
          await provider.handoverToCourier(order.id);
          if (context.mounted) {
            GageToast.show(context, 'Makanan diserahkan ke kurir!');
          }
        },
        child: const Text('Serahkan ke Kurir', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      onPressed: () => Navigator.pop(context),
      child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
