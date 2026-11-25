import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_thermal_receipt_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_delivery_track_progress.dart';
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
      extendBody: true,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. PIN Serah Terima Kurir / Pelanggan (Modern Digit Tiles)
            _buildPinCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 2. Info Driver / Kurir GAGE (Kontainer Terpisah Berjudul)
            if (latestOrder.hasAssignedDriver) ...[
              _buildDriverCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
              const SizedBox(height: 12),
            ] else if (!latestOrder.isPickup && (latestOrder.status == 'COOKING' || latestOrder.status == 'READY_FOR_PICKUP')) ...[
              _buildSearchingDriverCard(isDark, borderColor),
              const SizedBox(height: 12),
            ],

            // 3. Info Pembeli (Kontainer Terpisah Berjudul)
            _buildCustomerCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 4. Daftar Rincian Produk
            _buildItemsCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
            const SizedBox(height: 12),

            // 5. Transparansi Finansial & Penerimaan Bersih Toko
            _buildFinancialSummaryCard(latestOrder, isDark, cardBg, textColor, subColor, borderColor),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        child: _buildStageButton(context, latestOrder, provider, isDark, textColor, borderColor),
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
    final digits = order.courierVerificationPin.padLeft(4, '0').split('');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.vpn_key_rounded, color: GageTheme.primary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PIN Verifikasi Serah Terima',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: digits.map((digit) {
              return Container(
                width: 44,
                height: 48,
                margin: const EdgeInsets.symmetric(horizontal: 5),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: GageTheme.primary.withValues(alpha: isDark ? 0.35 : 0.25),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: GageTheme.primary.withValues(alpha: 0.06),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: GageTheme.primary,
                    letterSpacing: -0.5,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Tunjukkan 4 digit PIN ini kepada kurir / pembeli saat serah terima barang agar status tuntas otomatis.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: subColor, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverCard(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Driver',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GageTheme.primary.withValues(alpha: 0.6),
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
                            size: 20,
                            color: GageTheme.primary,
                          ),
                        )
                      : const Icon(
                          Icons.two_wheeler_rounded,
                          size: 20,
                          color: GageTheme.primary,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.driverName!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.driverVehicle ?? "Kurir G-Ride"} • ${order.driverPlate ?? "-"}',
                      style: TextStyle(fontSize: 11, color: subColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Tombol Telepon In-App ke Kurir (Paritas Gambar 3)
              InkWell(
                onTap: () => _showInAppCallSheet(
                  order.driverName ?? 'Driver GAGE',
                  'Kurir GAGE',
                  '08111222333',
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GageDeliveryTrackProgress(
            isSearchingDriver: false,
            isDriverArrived: order.status == 'READY_FOR_PICKUP',
            labelPrefix: order.status == 'READY_FOR_PICKUP' ? 'Pengemudi telah tiba di kios' : 'Menuju Kios',
            labelHighlight: order.status == 'READY_FOR_PICKUP' ? '' : ' • Est. 5 mnt',
          ),
        ],
      ),
    );
  }

  Widget _buildSearchingDriverCard(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFFF1F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const GageDeliveryTrackProgress(
        isSearchingDriver: true,
        labelPrefix: 'Sedang mencari kurir terdekat',
        labelHighlight: '...',
      ),
    );
  }

  Future<void> _showInAppCallSheet(String targetName, String roleLabel, String phone) async {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GageTheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.phone_in_talk_rounded, color: GageTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Telepon In-App',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    '$roleLabel • $targetName',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Text(
          'Panggilan suara berlangsung melalui jalur aman sistem GAGE tanpa menampilkan nomor pribadi Anda.',
          style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.grey.shade700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uri = Uri(scheme: 'tel', path: phone.isNotEmpty ? phone : '08111222333');
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri);
              } else if (mounted) {
                GageToast.show(context, 'Menghubungkan panggilan suara ke $targetName...');
              }
            },
            icon: const Icon(Icons.call_rounded, size: 16),
            label: const Text('Hubungi Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pembeli',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 19,
                backgroundColor: GageTheme.primary.withValues(alpha: isDark ? 0.2 : 0.08),
                child: const Icon(
                  Icons.person_rounded,
                  size: 20,
                  color: GageTheme.primary,
                ),
              ),
              const SizedBox(width: 12),
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
                  ],
                ),
              ),
              // Dual Action Icons: Chat Pembeli & Telepon In-App (Paritas Gambar 3)
              InkWell(
                onTap: () {
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
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showInAppCallSheet(
                  order.customerName ?? 'Pelanggan GAGE',
                  'Pelanggan',
                  order.customerPhone ?? '085156955735',
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? Colors.white24 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.phone_outlined,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
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
                      child: _buildProductImage(item.effectiveImageUrl, isDark, width: 38, height: 38),
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
    bool isDark,
    Color textColor,
    Color borderColor,
  ) {
    if (order.status == 'NEW' || order.status == 'PAID') {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: GageTheme.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GageTheme.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await provider.acceptOrder(order.id);
            if (context.mounted) {
              final msg = (provider.autoPrintOnAccept && provider.printerConnected)
                  ? 'Pesanan diterima & ${provider.receiptCopies} rangkap struk dicetak otomatis!'
                  : 'Pesanan diterima! Mulai siapkan.';
              GageToast.show(context, msg);
            }
          },
          child: const Text('Terima Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );
    }

    if (order.status == 'COOKING') {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: GageTheme.primary.withValues(alpha: 0.22),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: GageTheme.primary,
            foregroundColor: Colors.white,
            shape: const StadiumBorder(),
            elevation: 0,
          ),
          onPressed: () async {
            HapticFeedback.mediumImpact();
            await provider.markReadyForPickup(order.id);
            if (context.mounted) {
              GageToast.show(context, 'Pesanan siap diambil kurir / pembeli!');
            }
          },
          child: Text(
            (order.hasAssignedDriver || order.isPickup)
                ? 'Pesanan Siap Diambil (${order.formattedCookingTimeRemaining})'
                : 'Pesanan Siap Diambil',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ),
      );
    }

    if (order.status == 'READY_FOR_PICKUP' || order.status == 'AT_MERCHANT') {
      if (order.isPickup) {
        return Container(
          width: double.infinity,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: GageTheme.primary.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              await provider.completeOrder(order.id);
              if (context.mounted) {
                GageToast.show(context, 'Pesanan telah diserahkan ke pelanggan');
              }
            },
            child: const Text('Selesaikan (Ambil di Toko)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ),
        );
      }
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            foregroundColor: textColor,
            shape: const StadiumBorder(),
            side: BorderSide(color: borderColor),
            elevation: 0,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
          child: const Text('Kembali ke Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          foregroundColor: textColor,
          shape: const StadiumBorder(),
          side: BorderSide(color: borderColor),
          elevation: 0,
        ),
        onPressed: () {
          HapticFeedback.lightImpact();
          Navigator.of(context).pop();
        },
        child: const Text('Kembali ke Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildProductImage(String imgUrl, bool isDark, {double width = 38, double height = 38}) {
    if (imgUrl.startsWith('assets/')) {
      return Image.asset(
        imgUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          child: Icon(
            Icons.fastfood_rounded,
            size: width * 0.45,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
      );
    }
    if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
      return Image.network(
        imgUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          child: Icon(
            Icons.fastfood_rounded,
            size: width * 0.45,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
      );
    }
    if (imgUrl.isNotEmpty) {
      final assetPath = imgUrl.startsWith('assets/') ? imgUrl : 'assets/images/$imgUrl';
      return Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          width: width,
          height: height,
          color: isDark ? Colors.white10 : Colors.grey.shade200,
          child: Icon(
            Icons.fastfood_rounded,
            size: width * 0.45,
            color: isDark ? Colors.white38 : Colors.grey.shade500,
          ),
        ),
      );
    }
    return Container(
      width: width,
      height: height,
      color: isDark ? Colors.white10 : Colors.grey.shade200,
      child: Icon(
        Icons.fastfood_rounded,
        size: width * 0.45,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
    );
  }
}

class _LivePulsingDot extends StatefulWidget {
  final Color color;

  const _LivePulsingDot({required this.color});

  @override
  State<_LivePulsingDot> createState() => _LivePulsingDotState();
}

class _LivePulsingDotState extends State<_LivePulsingDot> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_ctrl),
      child: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _LivePulsingRadarIcon extends StatefulWidget {
  const _LivePulsingRadarIcon();

  @override
  State<_LivePulsingRadarIcon> createState() => _LivePulsingRadarIconState();
}

class _LivePulsingRadarIconState extends State<_LivePulsingRadarIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (!WidgetsBinding.instance.runtimeType.toString().contains('Test')) {
      _ctrl.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1.0).animate(_ctrl),
      child: const Icon(
        Icons.radar_rounded,
        size: 16,
        color: GageTheme.primary,
      ),
    );
  }
}
