import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:intl/intl.dart';

/// GageTicketVoucherCard
/// Desain kupon tiket berpori (scalloped ticket stub) khas ekosistem GAGE:
/// - Stub kiri 3D khas GAGE (Food, Ongkir Xtra, Ride/Car, Mart, Send)
/// - Notches setengah lingkaran atas & bawah pada garis pembatas
/// - Konten kanan berjarak rapat (tight spacing):
///   - Baris 1: Judul diskon tebal & badge kuantitas
///   - Baris 2: Min. belanja & berlaku sampai (s.d. tanggal) + S&K
///   - Baris 3: Badges status/audiens (terhubung ke portal admin) & tombol aksi "Pakai" FULL ROUNDED
class GageTicketVoucherCard extends StatelessWidget {
  final Map<String, dynamic> voucher;
  final VoidCallback onApply;
  final VoidCallback onTermsTap;

  const GageTicketVoucherCard({
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
        return GageTheme.primary; // Crimson Red GAGE
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

  String _getStubAsset(String service, String type) {
    if (type == 'delivery') {
      return 'assets/icons/vouchers/voucher_stub_delivery.png';
    }
    switch (service) {
      case 'GAGE Food':
        return 'assets/icons/vouchers/voucher_stub_food.png';
      case 'GAGE Ride':
      case 'GAGE Car':
        return 'assets/icons/vouchers/voucher_stub_ride.png';
      case 'GAGE Mart':
        return 'assets/icons/vouchers/voucher_stub_mart.png';
      case 'GAGE Send':
        return 'assets/icons/vouchers/voucher_stub_delivery.png';
      default:
        return 'assets/icons/vouchers/voucher_stub_food.png';
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
    final stubAsset = _getStubAsset(service, type);
    final icon = _getCategoryIcon(service, type);
    final label = _getCategoryLabel(service, type);

    final title = voucher['discountText'] as String? ?? voucher['title'] as String? ?? 'Diskon Spesial';
    final minOrder = voucher['minOrder'] as int? ?? 0;
    final expiry = voucher['expiry'] as String? ?? '31 Des 2026';
    final quantity = voucher['quantity'] as int? ?? 1;

    // Badges terintegrasi dengan arsitektur admin & voucher schema
    final tag = voucher['tag'] as String? ?? (service == 'GAGE Food' ? 'Diskon Terus' : 'Pengguna Baru');
    final secondaryBadge = voucher['badge'] as String? ?? (type == 'delivery' ? 'Semua Resto' : null);

    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final minOrderText = minOrder > 0 ? 'Min. blj ${currencyFmt.format(minOrder)}' : 'Tanpa min. belanja';

    const double stubWidth = 84.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: 116,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
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
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Row(
              children: [
                // 1. Stub Kiri Khas GAGE (Gambar 3D + Label Kategori)
                Container(
                  width: stubWidth,
                  height: double.infinity,
                  color: stubColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gambar 3D MCP Flow dengan fallback cerdas ke circular icon
                      Image.asset(
                        stubAsset,
                        width: 38,
                        height: 38,
                        fit: BoxFit.contain,
                        errorBuilder: (ctx, err, stack) {
                          return Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(icon, color: Colors.white, size: 20),
                          );
                        },
                      ),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
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

                // 3. Konten Kanan Tiket (Rapat & Berstruktur 3 Baris)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 12, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BARIS 1: Judul Voucher & Badge Kuantitas
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
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
                                  color: GageTheme.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  'x$quantity',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        // BARIS 2: Persyaratan Min. Belanja & Berlaku Sampai + S&K (Dirapatkan)
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                minOrderText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text('•', style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade400)),
                            ),
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
                                  fontWeight: FontWeight.w800,
                                  color: GageTheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // BARIS 3: Badges Filter Admin di Kiri & Tombol "Pakai" Full-Rounded di Kanan
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Badges Group (Baris 3 Kiri)
                            Expanded(
                              child: Wrap(
                                spacing: 4,
                                runSpacing: 2,
                                children: [
                                  // Badge Utama
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                      borderRadius: BorderRadius.circular(12),
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
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white70 : const Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  // Secondary Badge jika ada
                                  if (secondaryBadge != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDark ? Colors.white24 : Colors.grey.shade300,
                                          width: 0.8,
                                        ),
                                      ),
                                      child: Text(
                                        secondaryBadge,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? Colors.white70 : const Color(0xFF475569),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(width: 8),

                            // Tombol Pakai FULL ROUNDED (StadiumBorder)
                            SizedBox(
                              height: 30,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: GageTheme.primary,
                                  side: const BorderSide(color: GageTheme.primary, width: 1.4),
                                  shape: const StadiumBorder(),
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  visualDensity: VisualDensity.compact,
                                ),
                                onPressed: onApply,
                                child: const Text(
                                  'Pakai',
                                  style: TextStyle(
                                    fontSize: 11.5,
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

            // 4. Notches Scalloped Atas & Bawah (Semi-Circle Ticket Cutouts)
            Positioned(
              left: stubWidth - 6,
              top: -6,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: screenBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
              ),
            ),
            Positioned(
              left: stubWidth - 6,
              bottom: -6,
              child: Container(
                width: 12,
                height: 12,
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

/// Painter garis putus-putus vertikal pembatas tiket kupon
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 4.0;
    const double dashSpace = 3.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    double startY = 8.0;
    final double endY = size.height - 8.0;

    while (startY < endY) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, (startY + dashHeight).clamp(0, endY)),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
