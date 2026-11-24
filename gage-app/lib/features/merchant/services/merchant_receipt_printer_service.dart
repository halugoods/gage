import 'dart:async';
import 'package:intl/intl.dart';
import 'package:gage_app/data/models/order_model.dart';

/// Service engine cetak struk thermal kasir GAGE (Adaptasi arsitektur Nusa Kasir)
/// Mendukung ukuran kertas 58mm (32 kolom) dan 80mm (48 kolom) dengan perataan monospace presisi.
class MerchantReceiptPrinterService {
  MerchantReceiptPrinterService._();
  static final MerchantReceiptPrinterService instance = MerchantReceiptPrinterService._();

  /// Format baris dua kolom (Kiri rata kiri, Kanan rata kanan) dengan lebar kolom pas
  static String formatTwoColumns(String left, String right, int totalWidth) {
    if (left.length + right.length >= totalWidth) {
      final maxLeft = totalWidth - right.length - 1;
      if (maxLeft > 0) {
        left = '${left.substring(0, maxLeft - 1)}.';
      }
    }
    final spaces = totalWidth - left.length - right.length;
    return '$left${' ' * (spaces > 0 ? spaces : 1)}$right';
  }

  /// Format teks rata tengah (Center align)
  static String formatCenter(String text, int totalWidth) {
    if (text.length >= totalWidth) return text;
    final pad = (totalWidth - text.length) ~/ 2;
    return '${' ' * pad}$text';
  }

  /// Format tanggal transaksi
  static String formatDateTime(int timestamp) {
    if (timestamp <= 0) return '-';
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    try {
      return DateFormat('dd/MM/yyyy HH:mm', 'id_ID').format(dt);
    } catch (_) {
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      final h = dt.hour.toString().padLeft(2, '0');
      final min = dt.minute.toString().padLeft(2, '0');
      return '$d/$m/$y $h:$min';
    }
  }

  /// Menghasilkan plain text nota transaksi toko
  String generateReceiptText({
    required OrderModel order,
    required NumberFormat currencyFormatter,
    String paperSize = '58mm',
    int copyIndex = 1,
  }) {
    final width = paperSize == '80mm' ? 48 : 32;
    final divider = '=' * width;
    final dashDivider = '-' * width;
    final buf = StringBuffer();

    // 1. Header Toko
    buf.writeln(formatCenter('GAGE PRACIMANTORO', width));
    buf.writeln(formatCenter(order.merchantName, width));
    if (order.merchantAddress.isNotEmpty) {
      buf.writeln(formatCenter(order.merchantAddress, width));
    }
    buf.writeln(divider);

    // 2. Keterangan Salinan
    if (copyIndex == 1) {
      buf.writeln(formatCenter('STRUK TRANSAKSI TOKO', width));
    } else {
      buf.writeln(formatCenter('SALINAN TIKET DAPUR', width));
    }
    buf.writeln(dashDivider);

    // 3. Info Transaksi
    buf.writeln(formatTwoColumns('No. Nota :', order.orderNumber, width));
    buf.writeln(formatTwoColumns('Waktu    :', formatDateTime(order.createdAt), width));
    buf.writeln(formatTwoColumns('Pelanggan:', order.customerName ?? 'Pelanggan GAGE', width));
    buf.writeln(formatTwoColumns('Layanan  :', order.isPickup ? 'Ambil di Toko' : 'Pesan Antar', width));
    if (order.hasAssignedDriver) {
      buf.writeln(formatTwoColumns('Kurir    :', '${order.driverName} (${order.driverPlate ?? "-"})', width));
    }
    buf.writeln(divider);

    // 4. Rincian Item Menu
    buf.writeln('RINCIAN PESANAN:');
    for (final item in order.items) {
      final itemHeader = '${item.quantity}x ${item.name}';
      final itemPrice = currencyFormatter.format(item.subtotal);
      buf.writeln(formatTwoColumns(itemHeader, itemPrice, width));
      if (item.notes != null && item.notes!.isNotEmpty) {
        buf.writeln('  Catatan: ${item.notes}');
      }
    }
    buf.writeln(dashDivider);

    // 5. Rincian Pembayaran
    buf.writeln(formatTwoColumns('Subtotal Menu', currencyFormatter.format(order.itemsSubtotal), width));
    if (order.shippingFee > 0) {
      buf.writeln(formatTwoColumns('Ongkos Kirim', currencyFormatter.format(order.shippingFee), width));
    }
    if (order.adminFee > 0) {
      buf.writeln(formatTwoColumns('Biaya Layanan', currencyFormatter.format(order.adminFee), width));
    }
    buf.writeln(divider);
    buf.writeln(formatTwoColumns('TOTAL BAYAR', currencyFormatter.format(order.totalAmount), width));
    buf.writeln(formatTwoColumns('Metode Bayar', '${order.paymentMethod} (${order.paymentStatus})', width));
    buf.writeln(dashDivider);

    // 6. Finansial Merchant
    buf.writeln(formatTwoColumns('Pendapatan Bersih', currencyFormatter.format(order.merchantNetPayout), width));
    buf.writeln(formatTwoColumns('Komisi GAGE (10%)', '- ${currencyFormatter.format(order.platformCommissionAmount)}', width));
    buf.writeln(divider);

    // 7. PIN Verifikasi Serah Terima
    buf.writeln(formatCenter('*** PIN SERAH TERIMA ***', width));
    buf.writeln(formatCenter('[ ${order.courierVerificationPin} ]', width));
    buf.writeln(formatCenter('Tunjukkan PIN saat serah terima', width));
    buf.writeln(dashDivider);

    // 8. Footer Ramah
    buf.writeln(formatCenter('Terima Kasih atas Pesanan Anda!', width));
    buf.writeln(formatCenter('Layanan Pelanggan: 0812-3456-7890', width));
    buf.writeln(formatCenter('www.gage.id', width));
    buf.writeln('');

    return buf.toString();
  }

  /// Menghasilkan teks uji cetak thermal
  String generateTestReceipt({
    String storeName = 'Dimsum Sewu Pracimantoro',
    String paperSize = '58mm',
  }) {
    final width = paperSize == '80mm' ? 48 : 32;
    final divider = '=' * width;
    final buf = StringBuffer();

    buf.writeln(formatCenter('GAGE PRACIMANTORO', width));
    buf.writeln(formatCenter(storeName, width));
    buf.writeln(divider);
    buf.writeln(formatCenter('UJI COBA CETAK THERMAL', width));
    buf.writeln(formatCenter('Ukuran Kertas: $paperSize', width));
    buf.writeln(divider);
    buf.writeln(formatTwoColumns('Status Printer', 'TERHUBUNG', width));
    buf.writeln(formatTwoColumns('Waktu Uji', DateFormat('HH:mm:ss').format(DateTime.now()), width));
    buf.writeln(divider);
    buf.writeln(formatCenter('Printer Siap Operasional!', width));
    buf.writeln('');

    return buf.toString();
  }
}
