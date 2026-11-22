import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Modal Floating Sheet untuk Pratinjau & Cetak Struk Kasir Thermal (58mm / 80mm)
/// Meniru roll kertas kasir fisik asli dengan font monospace, garis putus-putus,
/// rincian pesanan, serta PIN verifikasi kurir 4-digit acak.
class MerchantThermalReceiptSheet extends StatefulWidget {
  final OrderModel order;
  final NumberFormat currencyFormatter;

  const MerchantThermalReceiptSheet({
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
      title: 'Struk Thermal Pesanan',
      builder: (sheetCtx) => MerchantThermalReceiptSheet(
        order: order,
        currencyFormatter: formatter,
      ),
    );
  }

  @override
  State<MerchantThermalReceiptSheet> createState() =>
      _MerchantThermalReceiptSheetState();
}

class _MerchantThermalReceiptSheetState
    extends State<MerchantThermalReceiptSheet> {
  String _paperSize = '58mm'; // '58mm' | '80mm'
  int _activePreviewCopy = 1; // 1: Dapur, 2: Kurir/Pelanggan, 3: Kasir
  bool _isPrinting = false;

  String _formatDateTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(dt);
  }

  String _generatePlainTextReceipt({int copyIndex = 1}) {
    final o = widget.order;
    final divider = _paperSize == '58mm'
        ? '--------------------------------'
        : '------------------------------------------------';
    final buf = StringBuffer();
    buf.writeln('          GAGE FOOD PRACIMANTORO          ');
    buf.writeln('        ${o.merchantName}        ');
    buf.writeln('   ${o.merchantAddress}   ');
    buf.writeln(divider);
    if (copyIndex == 1) {
      buf.writeln('>>> [ RANGKAP 1: SALINAN DAPUR ] <<<');
    } else if (copyIndex == 2) {
      buf.writeln('>>> [ RANGKAP 2: KURIR / PELANGGAN ] <<<');
    } else if (copyIndex == 3) {
      buf.writeln('>>> [ RANGKAP 3: ARSIP KASIR ] <<<');
    }
    buf.writeln('No. Nota : ${o.orderNumber}');
    buf.writeln('Waktu    : ${_formatDateTime(o.createdAt)}');
    buf.writeln('Pelanggan: ${o.customerName} (${o.customerPhone})');
    if (o.driverName != null) {
      buf.writeln('Driver   : ${o.driverName} (${o.driverPlate ?? "-"})');
    }
    buf.writeln(divider);
    buf.writeln('PESANAN:');
    for (final it in o.items) {
      buf.writeln('${it.quantity}x ${it.name}');
      if (it.notes != null && it.notes!.isNotEmpty) {
        buf.writeln('   Catatan: ${it.notes}');
      }
      buf.writeln('   @${widget.currencyFormatter.format(it.price)} = ${widget.currencyFormatter.format(it.subtotal)}');
    }
    buf.writeln(divider);
    buf.writeln('Subtotal Menu  : ${widget.currencyFormatter.format(o.itemsSubtotal)}');
    buf.writeln('Ongkos Kirim   : ${widget.currencyFormatter.format(o.shippingFee)}');
    buf.writeln('Biaya Layanan  : ${widget.currencyFormatter.format(o.adminFee)}');
    buf.writeln('TOTAL BAYAR    : ${widget.currencyFormatter.format(o.totalAmount)}');
    buf.writeln('Metode Bayar   : ${o.paymentMethod} (${o.paymentStatus})');
    buf.writeln(divider);
    buf.writeln('PAYOUT BERSIH  : ${widget.currencyFormatter.format(o.merchantNetPayout)}');
    buf.writeln('(MDR Komisi GAGE: ${widget.currencyFormatter.format(o.platformCommissionAmount)})');
    buf.writeln(divider);
    buf.writeln('*** PIN VERIFIKASI KURIR: [ ${o.courierVerificationPin} ] ***');
    buf.writeln('Berikan PIN ini ke kurir saat menyerahkan makanan.');
    buf.writeln(divider);
    buf.writeln('      Terima Kasih Atas Pesanan Anda!     ');
    buf.writeln('           Simpan Struk Ini Kasir         ');
    return buf.toString();
  }

  Future<void> _handlePrint() async {
    final provider = Provider.of<MerchantOrderProvider>(context, listen: false);
    if (!provider.printerConnected) {
      GageToast.show(
        context,
        'Printer Thermal belum terhubung. Aktifkan printer Bluetooth di Pengaturan.',
      );
      return;
    }

    setState(() => _isPrinting = true);
    final copies = provider.receiptCopies;
    final ok = await provider.printOrderReceipt(widget.order.id, paperSize: _paperSize, copies: copies);
    if (!mounted) return;
    setState(() => _isPrinting = false);
    if (ok) {
      GageToast.show(context, 'Struk berhasil dicetak ($copies rangkap) ke printer $_paperSize');
      Navigator.pop(context);
    } else {
      GageToast.show(context, 'Gagal mencetak struk thermal.');
    }
  }

  void _copyToClipboard(BuildContext context) {
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _generatePlainTextReceipt(copyIndex: _activePreviewCopy)));
    GageToast.show(context, 'Teks struk berhasil disalin ke papan klip');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final order = widget.order;
    final provider = context.watch<MerchantOrderProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Segmented Switcher Ukuran Kertas Thermal (Capsule 999 Paritas GAGE)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _paperSize = '58mm');
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _paperSize == '58mm'
                            ? GageTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '58 mm (Standard POS)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _paperSize == '58mm'
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _paperSize = '80mm');
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _paperSize == '80mm'
                            ? GageTheme.primary
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '80 mm (Format Lebar)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _paperSize == '80mm'
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Status Printer Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: provider.printerConnected
                  ? const Color(0xFFECFDF5)
                  : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: provider.printerConnected
                    ? const Color(0xFFA7F3D0)
                    : const Color(0xFFFECACA),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  provider.printerConnected
                      ? Icons.print_rounded
                      : Icons.print_disabled_rounded,
                  size: 16,
                  color: provider.printerConnected
                      ? const Color(0xFF059669)
                      : const Color(0xFFDC2626),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    provider.printerConnected
                        ? 'Printer SPP Bluetooth Siap (GAGE Thermal-58)'
                        : 'Printer Tidak Terhubung',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: provider.printerConnected
                          ? const Color(0xFF065F46)
                          : const Color(0xFF991B1B),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => provider.togglePrinter(!provider.printerConnected),
                  child: Text(
                    provider.printerConnected ? 'Matikan' : 'Hubungkan',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: provider.printerConnected
                          ? const Color(0xFF059669)
                          : GageTheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 2b. Pengaturan Rangkap Struk (Kapsul Penuh 999)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jumlah Rangkap Cetak:',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white70 : const Color(0xFF334155),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  height: 34,
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: _buildCopyPill(provider, 1, '1x Tunggal', isDark)),
                      Expanded(child: _buildCopyPill(provider, 2, '2x (Dapur+Kurir)', isDark)),
                      Expanded(child: _buildCopyPill(provider, 3, '3x (+Kasir)', isDark)),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: GageTheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cetak Otomatis saat Pesanan Diterima (${provider.receiptCopies} rangkap)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: provider.autoPrintOnAccept,
                        activeThumbColor: GageTheme.primary,
                        onChanged: (val) {
                          provider.toggleAutoPrintOnAccept(val);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Tab Pratinjau Salinan jika Multi-Rangkap
          if (provider.receiptCopies > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    Text(
                      'Pilih Pratinjau: ',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white60 : Colors.grey.shade600,
                      ),
                    ),
                    for (int i = 1; i <= provider.receiptCopies; i++) ...[
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text(
                            i == 1 ? 'Rangkap 1 (Dapur)' : (i == 2 ? 'Rangkap 2 (Kurir)' : 'Rangkap 3 (Kasir)'),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: _activePreviewCopy == i ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          selected: _activePreviewCopy == i,
                          selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          onSelected: (_) {
                            HapticFeedback.selectionClick();
                            setState(() => _activePreviewCopy = i);
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),

          // 3. Roll Kertas Thermal Preview (Fisik Putih ala Kertas Kasir)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 280),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: [
                          if (_activePreviewCopy == 1)
                            const Text(
                              '>>> [ RANGKAP 1: DAPUR ] <<<',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFDC2626),
                              ),
                            )
                          else if (_activePreviewCopy == 2)
                            const Text(
                              '>>> [ RANGKAP 2: KURIR / PELANGGAN ] <<<',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2563EB),
                              ),
                            )
                          else if (_activePreviewCopy == 3)
                            const Text(
                              '>>> [ RANGKAP 3: ARSIP KASIR ] <<<',
                              style: TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF059669),
                              ),
                            ),
                          const SizedBox(height: 2),
                          const Text(
                            'GAGE FOOD PRACIMANTORO',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            order.merchantName,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            order.merchantAddress,
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptDashedLine(),
                    const SizedBox(height: 6),
                    _buildReceiptRow('No. Invoice', order.orderNumber),
                    _buildReceiptRow('Waktu', _formatDateTime(order.createdAt)),
                    _buildReceiptRow('Pelanggan', order.customerName ?? '-'),
                    _buildReceiptRow('Telp', order.customerPhone ?? '-'),
                    if (order.driverName != null) ...[
                      _buildReceiptRow('Kurir', order.driverName!),
                      _buildReceiptRow('Plat', order.driverPlate ?? "-"),
                    ],
                    const SizedBox(height: 6),
                    _buildReceiptDashedLine(),
                    const SizedBox(height: 6),
                    for (final item in order.items) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity}x ',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              item.name,
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Text(
                            widget.currencyFormatter.format(item.subtotal),
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 11,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      if (item.notes != null && item.notes!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 18, bottom: 2),
                          child: Text(
                            '- ${item.notes}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9.5,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                    ],
                    const SizedBox(height: 6),
                    _buildReceiptDashedLine(),
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'Subtotal Menu',
                      widget.currencyFormatter.format(order.itemsSubtotal),
                    ),
                    _buildReceiptRow(
                      'Ongkos Kirim',
                      widget.currencyFormatter.format(order.shippingFee),
                    ),
                    _buildReceiptRow(
                      'Biaya Layanan',
                      widget.currencyFormatter.format(order.adminFee),
                    ),
                    const SizedBox(height: 4),
                    _buildReceiptRow(
                      'TOTAL BAYAR',
                      widget.currencyFormatter.format(order.totalAmount),
                      isBold: true,
                    ),
                    _buildReceiptRow(
                      'Status Bayar',
                      '${order.paymentMethod} (${order.paymentStatus})',
                    ),
                    const SizedBox(height: 6),
                    _buildReceiptDashedLine(),
                    const SizedBox(height: 6),
                    _buildReceiptRow(
                      'PAYOUT TOKO',
                      widget.currencyFormatter.format(order.merchantNetPayout),
                      isBold: true,
                    ),
                    _buildReceiptRow(
                      'MDR GAGE (10%)',
                      '- ${widget.currencyFormatter.format(order.platformCommissionAmount)}',
                    ),
                    const SizedBox(height: 8),
                    // Box PIN Serah Terima Kurir
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: GageTheme.primary, width: 1),
                      ),
                      child: Column(
                        children: [
                          const Text(
                            'PIN VERIFIKASI KURIR',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: GageTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            order.courierVerificationPin.split('').join('  '),
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: GageTheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Sebutkan ke kurir saat menyerahkan makanan',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 8.5,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Center(
                      child: Text(
                        '*** TERIMA KASIH ***\nSimpan bukti struk kasir ini',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Courier',
                          fontSize: 9.5,
                          color: Colors.black45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 4. Tombol Aksi Cetak & Bagikan
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
                  onPressed: () => _copyToClipboard(context),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: const Text(
                    'Salin Struk',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 2,
                  ),
                  onPressed: _isPrinting ? null : () => _handlePrint(),
                  icon: _isPrinting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.print_rounded, size: 18),
                  label: Text(
                    _isPrinting ? 'Mencetak...' : 'Cetak Struk Sekarang',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Courier',
                fontSize: 10.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: Colors.black,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyPill(MerchantOrderProvider provider, int copies, String label, bool isDark) {
    final isSelected = provider.receiptCopies == copies;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        provider.setReceiptCopies(copies);
        if (_activePreviewCopy > copies) {
          setState(() => _activePreviewCopy = 1);
        }
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? GageTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / 6).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
            (_) => const SizedBox(
              width: 3.5,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFFCBD5E1)),
              ),
            ),
          ),
        );
      },
    );
  }
}
