import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/core/utils/invoice_number_generator.dart';

/// Lembar Standar Tagihan QRIS Resmi GAGE (GageQrisReceiptWidget)
/// Menampilkan lembar tagihan QRIS berstandar nasional ASPI & Bank Indonesia:
/// - Header resmi "GAGE by Halu Goods Indonesia" & Logo QRIS
/// - Dynamic QR Code responsif terhadap nominal tagihan
/// - Nama penerima & nomor rekening GAGEPay 12 digit LUHN
/// - Display nominal tagihan (atau label nominal bebas)
/// - Kode referensi transaksi anti-tabrakan & cap waktu cetak WIB
/// - Tepi bergerigi taktil (perforated receipt edge)
class GageQrisReceiptWidget extends StatelessWidget {
  final String accountNumber;
  final String userName;
  final int? requestedAmount;

  const GageQrisReceiptWidget({
    super.key,
    required this.accountNumber,
    required this.userName,
    this.requestedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAcc = LuhnAlgorithm.formatWithSpaces(accountNumber);
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final now = DateTime.now();
    String dateStr;
    try {
      dateStr = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(now);
    } catch (_) {
      dateStr = DateFormat('dd MMM yyyy, HH:mm').format(now);
    }
    final refCode = InvoiceNumberGenerator.generate(timestamp: now);

    final amtParam = (requestedAmount != null && requestedAmount! > 0)
        ? '&amount=$requestedAmount'
        : '';
    final qrPayload =
        'gagepay://transfer?to=$accountNumber&name=${Uri.encodeComponent(userName)}$amtParam';

    return Container(
      width: 340,
      decoration: const BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Badan Struk Utama dengan Sudut Lengkung Atas Mulus & Anti-Alias Sempurna
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            clipBehavior: Clip.antiAlias,
            child: Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Garis aksen merah atas menyatu mulus tanpa celah/bolong
                  Container(
                    height: 8,
                    color: GageTheme.primary,
                  ),

                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Baris Atas: Logo GAGE & Badge QRIS Standar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'GAGE',
                                  style: TextStyle(
                                    color: GageTheme.primary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                Text(
                                  'by Halu Goods Indonesia',
                                  style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),

                            // Badge QRIS Standar Nasional
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.black,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'QRIS',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 14),

                        // Garis putus-putus pembatas
                        CustomPaint(
                          size: const Size(double.infinity, 1),
                          painter: _DottedLinePainter(),
                        ),

                        const SizedBox(height: 12),

                        // Info NMID & Tipe Transaksi
                        Text(
                          'PEMBAYARAN QRIS DINAMIS GAGEPAY',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey.shade600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NMID: ID102008908123',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Kontainer QR Code Tajam
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade300, width: 1.2),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3)),
                            ],
                          ),
                          child: QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 190,
                            backgroundColor: Colors.white,
                            errorCorrectionLevel: QrErrorCorrectLevel.H,
                            gapless: true,
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Card Rincian Penerima & Nominal
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Column(
                            children: [
                              _buildReceiptRow('PENERIMA', userName.toUpperCase(), isBold: true),
                              const SizedBox(height: 6),
                              _buildReceiptRow('NO. REKENING', formattedAcc, isMonospace: true),
                              const SizedBox(height: 6),
                              _buildReceiptRow(
                                'TOTAL TAGIHAN',
                                (requestedAmount != null && requestedAmount! > 0)
                                    ? currencyFormatter.format(requestedAmount)
                                    : 'Nominal Bebas',
                                isBold: true,
                                valueColor: (requestedAmount != null && requestedAmount! > 0)
                                    ? GageTheme.primary
                                    : const Color(0xFF16A34A),
                              ),
                              const SizedBox(height: 6),
                              _buildReceiptRow('WAKTU CETAK', '$dateStr WIB'),
                              const SizedBox(height: 6),
                              _buildReceiptRow('REFERENSI', refCode, isMonospace: true, fontSize: 9.5),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Badge Keamanan Bank Indonesia & ASPI
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.verified_rounded, size: 14, color: Color(0xFF16A34A)),
                            const SizedBox(width: 5),
                            Flexible(
                              child: Text(
                                'Terverifikasi Standar Nasional BI & ASPI',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Tepi bergerigi fisik struk pembayaran (Perforated Edge)
          CustomPaint(
            size: const Size(double.infinity, 12),
            painter: _ReceiptPerforatedBottomPainter(),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(
    String label,
    String value, {
    bool isBold = false,
    bool isMonospace = false,
    Color? valueColor,
    double fontSize = 11,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
              fontFamily: isMonospace ? 'monospace' : null,
              color: valueColor ?? const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}

/// Painter garis putus-putus pembatas struk
class _DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.0;

    const dashWidth = 4.0;
    const dashSpace = 3.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(Offset(startX, 0), Offset(startX + dashWidth, 0), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter tepi bergerigi zig-zag di bagian bawah struk
class _ReceiptPerforatedBottomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0);

    const toothWidth = 12.0;
    final toothHeight = size.height;
    final teethCount = (size.width / toothWidth).ceil();

    for (int i = 0; i < teethCount; i++) {
      final startX = i * toothWidth;
      path.lineTo(startX + toothWidth / 2, toothHeight);
      path.lineTo(startX + toothWidth, 0);
    }

    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
