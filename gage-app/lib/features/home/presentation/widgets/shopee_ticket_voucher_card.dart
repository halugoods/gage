import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:intl/intl.dart';

/// ShopeeTicketVoucherCard
/// Desain kupon tiket berpori (scalloped ticket stub) adaptasi ShopeeFood:
/// - Stub kiri berwarna kategori (Food: Red/Orange, Ongkir: Teal, Transport: Blue, Pay: Amber)
/// - Notches setengah lingkaran atas & bawah pada garis pembatas
/// - Konten kanan ramping tanpa gambar hero: Judul diskon tebal, minimal belanja, tag badge, tanggal kedaluwarsa, link S&K, dan tombol 'Pakai' outline
class ShopeeTicketVoucherCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final VoidCallback onApply;
  final VoidCallback onTermsTap;

  const ShopeeTicketVoucherCard({
    super.key,
    required this.voucher,
    required this.onApply,
    required this.onTermsTap,
  });

  Color _getStubColor(String service, String type) {
    if (type == 'delivery') {
      return const Color(0xFF0D9488); // Teal untuk Ongkir Xtra
    }
    switch (service) {
      case 'GAGE Food':
        return GageTheme.primary; // Oranye/Merah ShopeeFood
      case 'GAGE Ride':
      case 'GAGE Car':
        return const Color(0xFF2563EB); // Royal Blue Transport
      case 'GAGE Mart':
        return const Color(0xFF16A34A); // Emerald Green Mart
      case 'GAGE Send':
        return const Color(0xFFEA580C); // Vibrant Orange Send
      case 'GAGE Pay':
        return const Color(0xFFD97706); // Amber Gold Pay
      default:
        return GageTheme.primary;
    }
  }

  IconData _getCategoryIcon(String service, String type) {
    if (type == 'delivery') {
      return Icons.delivery_dining_rounded;
    }
    switch (service) {
      case 'GAGE Food':
        return Icons.restaurant_rounded;
      case 'GAGE Ride':
        return Icons.two_wheeler_rounded;
      case 'GAGE Car':
        return Icons.directions_car_rounded;
      case 'GAGE Mart':
        return Icons.storefront_rounded;
      case 'GAGE Send':
        return Icons.local_shipping_rounded;
      case 'GAGE Pay':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.confirmation_number_rounded;
    }
  }

  String _getCategoryLabel(String service, String type) {
    if (type == 'delivery') return 'GRATIS\nONGKIR';
    switch (service) {
      case 'GAGE Food':
        return 'GAGE\nFOOD';
      case 'GAGE Ride':
        return 'GAGE\nRIDE';
      case 'GAGE Car':
        return 'GAGE\nCAR';
      case 'GAGE Mart':
        return 'GAGE\nMART';
      case 'GAGE Send':
        return 'GAGE\nSEND';
      case 'GAGE Pay':
        return 'GAGE\nPAY';
      default:
        return 'GAGE\nPROMO';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GageTheme.darkSurface : Colors.white;
    final screenBgColor = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final borderColor = isDark ? GageTheme.darkBorder : Colors.grey.shade200;

    final service = voucher['service'] as String? ?? 'GAGE Food';
    final type = voucher['type'] as String? ?? 'order';
    final stubColor = _getStubColor(service, type);
    final icon = _getCategoryIcon(service, type);
    final label = _getCategoryLabel(service, type);

    final title = voucher['discountText'] as String? ?? voucher['title'] as String? ?? 'Diskon Spesial';
    final minOrder = voucher['minOrder'] as int? ?? 0;
    final expiry = voucher['expiry'] as String? ?? '31 Des 2026';
    final quantity = voucher['quantity'] as int? ?? 1;
    final tag = voucher['tag'] as String? ?? (service == 'GAGE Food' ? 'Diskon Terus' : 'Pengguna Baru');

    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final minOrderText = minOrder > 0 ? 'Min. blj ${currencyFmt.format(minOrder)}' : 'Tanpa min. belanja';

    const double stubWidth = 86.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 114,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Stack(
          children: [
            Row(
              children: [
                // 1. Stub Kiri Berwarna
                Container(
                  width: stubWidth,
                  height: double.infinity,
                  color: stubColor,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: Colors.white, size: 22),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. Garis Putus-putus Pembatas (Dashed Divider)
                SizedBox(
                  width: 1,
                  child: CustomPaint(
                    painter: _DashedLinePainter(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                ),

                // 3. Konten Kanan Tiket
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Baris Judul & Badge Kuantitas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                            ),
                            if (quantity > 1) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F2),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: const Color(0xFFFECDD3)),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // Subtitle: Min Belanja & Tag Pill (Flex-Safe)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                minOrderText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.white10 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                tag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Baris Bawah: Expiry + S&K Link + Tombol Pakai Outline
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Flexible(
                                    child: Text(
                                      's.d. $expiry',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  InkWell(
                                    onTap: onTermsTap,
                                    child: const Text(
                                      'S&K',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w700,
                                        color: GageTheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            SizedBox(
                              height: 30,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GageTheme.primary,
                                  side: const BorderSide(color: GageTheme.primary, width: 1.2),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: onApply,
                                child: const Text(
                                  'Pakai',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 4. Scallop Notches (Setengah lingkaran atas & bawah di sambungan divider)
            Positioned(
              left: stubWidth - 7,
              top: -7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: screenBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
              ),
            ),
            Positioned(
              left: stubWidth - 7,
              bottom: -7,
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: screenBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    const dashHeight = 4.0;
    const dashSpace = 3.0;
    double startY = 12.0;
    final endY = size.height - 12.0;

    while (startY < endY) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
