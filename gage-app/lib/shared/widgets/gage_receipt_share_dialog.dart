import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/gage_theme.dart';
import '../../data/models/order_model.dart';

/// Modal dialog interaktif dan kaya visual untuk melihat, menyimpan, dan membagikan
/// struk/invoice pesanan sebagai gambar PNG berkualitas tinggi.
class GageReceiptShareDialog extends StatefulWidget {
  final OrderModel order;

  const GageReceiptShareDialog({
    super.key,
    required this.order,
  });

  static Future<void> show(BuildContext context, OrderModel order) {
    HapticFeedback.mediumImpact();
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => GageReceiptShareDialog(order: order),
      ),
    );
  }

  @override
  State<GageReceiptShareDialog> createState() => _GageReceiptShareDialogState();
}

class _GageReceiptShareDialogState extends State<GageReceiptShareDialog> {
  final GlobalKey _receiptBoundaryKey = GlobalKey();
  bool _isProcessing = false;

  Future<Uint8List?> _captureReceiptPng() async {
    try {
      final boundary = _receiptBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }

  Future<void> _shareReceiptImage() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) {
        throw Exception('Gagal merender struk');
      }

      final tempDir = await getTemporaryDirectory();
      final cleanOrderNum = widget.order.orderNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '${tempDir.path}/struk_gage_$cleanOrderNum.png';
      final file = File(filePath);
      await file.writeAsBytes(pngBytes);

      setState(() {
        _isProcessing = false;
      });

      final shareText = 'Struk Pesanan #${widget.order.orderNumber}\n'
          'Total: Rp ${widget.order.totalAmount}';

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Struk Pesanan GAGE #${widget.order.orderNumber}',
          files: [XFile(file.path, mimeType: 'image/png')],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membagikan struk. Silakan coba kembali.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveReceiptToGallery() async {
    HapticFeedback.lightImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      final pngBytes = await _captureReceiptPng();
      if (pngBytes == null) {
        throw Exception('Gagal merender struk');
      }

      final cleanOrderNum = widget.order.orderNumber.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final fileName = 'struk_gage_$cleanOrderNum.png';

      // Simpan langsung ke MediaStore Android album "Gage by Halu Goods Indonesia" via Native Platform Channel
      const channel = MethodChannel('com.gage/media_scanner');
      try {
        await channel.invokeMethod('saveImageToGallery', {
          'bytes': pngBytes,
          'fileName': fileName,
        });
      } catch (nativeErr) {
        // Fallback untuk non-Android platform
        final appDir = await getApplicationDocumentsDirectory();
        final targetFile = File('${appDir.path}/$fileName');
        await targetFile.writeAsBytes(pngBytes);
      }

      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Struk berhasil disimpan di galeri album "Gage by Halu Goods Indonesia"'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan gambar. Silakan gunakan opsi Bagikan.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final order = widget.order;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      appBar: AppBar(
        title: const Text(
          'Struk Pembayaran Digital',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 20),
            tooltip: 'Bagikan Struk',
            onPressed: _isProcessing ? null : _shareReceiptImage,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        physics: const BouncingScrollPhysics(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: RepaintBoundary(
              key: _receiptBoundaryKey,
              child: _buildTactileReceiptCard(order, currencyFormatter),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200)),
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, -3)),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: GageTheme.primary, width: 1.4),
                  foregroundColor: GageTheme.primary,
                  backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: _isProcessing ? null : _saveReceiptToGallery,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Simpan Gambar',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  elevation: 0,
                ),
                onPressed: _isProcessing ? null : _shareReceiptImage,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text(
                  'Bagikan Struk',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Membangun kartu struk interaktif dengan perforated edge, QR resmi, dan styling Gage
  Widget _buildTactileReceiptCard(OrderModel order, NumberFormat currencyFormatter) {
    final dt = order.createdAt > 0
        ? (order.createdAt > 10000000000
            ? DateTime.fromMillisecondsSinceEpoch(order.createdAt)
            : DateTime.fromMillisecondsSinceEpoch(order.createdAt * 1000))
        : DateTime.now();
    final createdAtDate = '${DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(dt)} WIB';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sleek Minimalist Brand Header dengan Logo Resmi GAGE
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Logo Resmi GAGE Asli di Bagian Atas
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/gage_logo.png',
                    width: 54,
                    height: 54,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'GAGE by Halu Goods Indonesia',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'BUKTI TRANSAKSI PEMBAYARAN RESMI',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          _buildPerforatedDivider(),

          // 2. Status Stamp & Invoice Metadata
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              children: [
                // Status Ribbon Stamp
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDCFCE7),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFF86EFAC)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Text(
                        order.status == 'CANCELLED' ? 'PESANAN DIBATALKAN' : 'LUNAS / PESANAN SELESAI',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: order.status == 'CANCELLED' ? const Color(0xFFDC2626) : const Color(0xFF15803D),
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Nomor Invoice', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          const SizedBox(height: 2),
                          Text(
                            order.orderNumber,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Tanggal Transaksi', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                        const SizedBox(height: 2),
                        Text(
                          createdAtDate,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Perforated Divider
          _buildPerforatedDivider(),

          // 3. Merchant / Service Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'LAYANAN ${order.serviceType.toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                    ),
                    if (order.driverName != null && order.driverName!.trim().isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.person_pin_circle_rounded, size: 14, color: Color(0xFF64748B)),
                          const SizedBox(width: 4),
                          Text(
                            'Driver: ${order.driverName}',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.merchantName,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                if (order.pickupAddress != null && order.pickupAddress!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.circle, size: 9, color: Color(0xFF16A34A)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Jemput: ${order.pickupAddress}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (order.deliveryAddress.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 11, color: Color(0xFFDC2626)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Tujuan: ${order.deliveryAddress}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Perforated Divider
          _buildPerforatedDivider(),

          // 4. Itemized Product / Service Details
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('RINCIAN ITEM', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                    Text('TOTAL', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 8),

                if (order.items.isNotEmpty)
                  ...order.items.map((item) {
                    final itemTotal = item.quantity * item.price;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                            ),
                          ),
                          Text(
                            currencyFormatter.format(itemTotal),
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          ),
                        ],
                      ),
                    );
                  })
                else ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '1x',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            order.isTransportService
                                ? 'Perjalanan ${order.serviceType.toUpperCase()} (${order.distanceKm.toStringAsFixed(1)} km)'
                                : 'Layanan Pengiriman',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF1E293B)),
                          ),
                        ),
                        Text(
                          currencyFormatter.format(order.itemsSubtotal > 0 ? order.itemsSubtotal : order.totalAmount),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 10),
                Divider(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 10),

                // Pricing Summary
                _buildPriceRow('Subtotal Item', currencyFormatter.format(order.itemsSubtotal)),
                if (order.shippingFee > 0)
                  _buildPriceRow('Ongkos Kirim', currencyFormatter.format(order.shippingFee)),
                if (order.shippingDiscount > 0)
                  _buildPriceRow('Diskon Ongkir', '-${currencyFormatter.format(order.shippingDiscount)}', isDiscount: true),
                if (order.adminFee > 0)
                  _buildPriceRow('Biaya Layanan', currencyFormatter.format(order.adminFee)),
                if (order.driverTip > 0)
                  _buildPriceRow('Tip Driver', currencyFormatter.format(order.driverTip)),
              ],
            ),
          ),

          // Perforated Divider
          _buildPerforatedDivider(),

          // 5. Total & Payment Method
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'TOTAL BAYAR',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                    Text(
                      currencyFormatter.format(order.totalAmount),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Metode Pembayaran', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        _formatPaymentMethod(order.paymentMethod),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Perforated Divider
          _buildPerforatedDivider(),

          // 6. QR Code Verification & Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: QrImageView(
                        data: 'https://gagepracimantoro.com/receipt/${order.orderNumber}',
                        version: QrVersions.auto,
                        size: 72,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Verifikasi Keaslian Struk',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Pindai kode QR untuk validasi transaksi di sistem pusat GAGE Pracimantoro.',
                            style: TextStyle(fontSize: 10, color: Color(0xFF64748B), height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Terima kasih telah menggunakan GAGE Pracimantoro!',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF64748B),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Saw-Tooth Cut Bottom Edge
          ClipPath(
            clipper: _SawtoothClipper(),
            child: Container(
              height: 12,
              color: const Color(0xFFE2E8F0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF64748B))),
          Text(
            value,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: isDiscount ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
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

  /// Garis pembatas putus-putus dengan lekukan tiket berlubang di kiri & kanan
  Widget _buildPerforatedDivider() {
    return SizedBox(
      height: 20,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Garis Putus-putus
          LayoutBuilder(
            builder: (context, constraints) {
              const dashWidth = 5.0;
              const dashSpace = 4.0;
              final count = (constraints.maxWidth / (dashWidth + dashSpace)).floor();
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(count, (_) {
                  return Container(
                    width: dashWidth,
                    height: 1,
                    margin: const EdgeInsets.symmetric(horizontal: dashSpace / 2),
                    color: const Color(0xFFCBD5E1),
                  );
                }),
              );
            },
          ),
          // Lubang tiket kiri
          Positioned(
            left: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Lubang tiket kanan
          Positioned(
            right: -10,
            child: Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom clipper untuk tepi robekan struk fisik gerigi (saw-tooth)
class _SawtoothClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, 0);

    const toothWidth = 8.0;
    const toothHeight = 6.0;
    final teethCount = (size.width / toothWidth).ceil();

    for (int i = 0; i < teethCount; i++) {
      final x1 = i * toothWidth + (toothWidth / 2);
      final x2 = (i + 1) * toothWidth;
      path.lineTo(x1, toothHeight);
      path.lineTo(x2, 0);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
