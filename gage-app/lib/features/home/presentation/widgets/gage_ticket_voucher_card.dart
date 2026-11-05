import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:intl/intl.dart';

/// GageTicketVoucherCard
/// Komponen Kartu Voucher berkonsep Tiket Horizontal (Ticket-Style Card):
/// - Sesuai pedoman visual iOS: bersih, modern, proporsional, dan compact
/// - Background kartu putih dengan rounded corner halus (18 px) dan shadow sangat lembut
/// - Bagian kiri (Stub):
///   - Menyatukan background kategori (Diskon, Gratis Ongkir, GAGE Ride, GAGE Car)
///   - Efek ticket cutout berupa setengah lingkaran di sisi kiri & takik perforasi atas/bawah
///   - Garis perforasi vertikal (dashed divider) pemisah visual stub dan konten
///   - HANYA berisi 2 elemen: Icon kategori & Nama kategori tersusun vertikal tepat di tengah
/// - Bagian kanan (Content):
///   - Baris 1: Judul voucher sebagai fokus dominan & badge kuantitas
///   - Baris 2: Informasi minimum pembelian
///   - Baris 3: Badge / label ketentuan voucher subtle & rapi
///   - Baris 4: Informasi masa berlaku dengan icon jam + tautan S&K
/// - Tombol "Pakai" compact di sisi kanan dengan bentuk rounded rectangle (8 px)
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

  List<Color> _getStubGradient(String service, String type) {
    if (type == 'delivery') {
      return const [Color(0xFF0D9488), Color(0xFF0F766E)]; // Hijau Teal Gratis Ongkir
    }
    switch (service) {
      case 'GAGE Food':
        return const [Color(0xFFF52D3D), Color(0xFFE11D48)]; // Merah Diskon GAGE Food
      case 'GAGE Ride':
        return const [Color(0xFF2563EB), Color(0xFF1D4ED8)]; // Biru GAGE Ride
      case 'GAGE Car':
        return const [Color(0xFF1E3A8A), Color(0xFF172554)]; // Biru Tua GAGE Car
      case 'GAGE Mart':
        return const [Color(0xFF16A34A), Color(0xFF15803D)]; // Emerald GAGE Mart
      case 'GAGE Send':
        return const [Color(0xFFEA580C), Color(0xFFC2410C)]; // Oranye GAGE Send
      case 'GAGE Pay':
        return const [Color(0xFFD97706), Color(0xFFB45309)]; // Amber GAGE Pay
      default:
        return const [Color(0xFFF52D3D), Color(0xFFDC2626)]; // Merah Utama Diskon
    }
  }

  IconData _getCategoryIcon(String service, String type) {
    if (type == 'delivery') {
      return Icons.local_shipping_rounded;
    }
    switch (service) {
      case 'GAGE Food':
        return Icons.percent_rounded;
      case 'GAGE Ride':
        return Icons.two_wheeler_rounded;
      case 'GAGE Car':
        return Icons.directions_car_rounded;
      case 'GAGE Mart':
        return Icons.storefront_rounded;
      case 'GAGE Send':
        return Icons.inventory_2_rounded;
      case 'GAGE Pay':
        return Icons.account_balance_wallet_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  String _getCategoryLabel(String service, String type) {
    if (type == 'delivery') return 'Gratis\nOngkir';
    switch (service) {
      case 'GAGE Food':
        return 'Diskon';
      case 'GAGE Ride':
        return 'GAGE\nRide';
      case 'GAGE Car':
        return 'GAGE\nCar';
      case 'GAGE Mart':
        return 'GAGE\nMart';
      case 'GAGE Send':
        return 'GAGE\nSend';
      case 'GAGE Pay':
        return 'GAGE\nPay';
      default:
        return 'Diskon';
    }
  }

  Widget _buildBadge(String text, bool isDark, {required bool isPrimary}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: isPrimary
              ? (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0369A1))
              : (isDark ? const Color(0xFF34D399) : const Color(0xFF047857)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GageTheme.darkSurface : Colors.white;
    final screenBgColor = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final borderColor = isDark ? GageTheme.darkBorder : Colors.grey.shade200;

    final service = voucher['service'] as String? ?? 'GAGE Food';
    final type = voucher['type'] as String? ?? 'order';
    final stubGradient = _getStubGradient(service, type);
    final icon = _getCategoryIcon(service, type);
    final label = _getCategoryLabel(service, type);

    final title = voucher['discountText'] as String? ?? voucher['title'] as String? ?? 'Diskon Spesial';
    final minOrder = voucher['minOrder'] as int? ?? 0;
    final expiry = voucher['expiry'] as String? ?? '31 Des 2026';
    final quantity = voucher['quantity'] as int? ?? 1;

    // Badges filter admin yang rapi
    final tag = voucher['tag'] as String? ?? (service == 'GAGE Food' ? 'Diskon Terus' : 'Pengguna Baru');
    final secondaryBadge = voucher['badge'] as String? ?? (type == 'delivery' ? 'Semua Resto' : null);

    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final minOrderText = minOrder > 0 ? 'Min. belanja ${currencyFmt.format(minOrder)}' : 'Tanpa min. belanja';

    const double stubWidth = 80.0;
    const double cardHeight = 106.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      height: cardHeight,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: Stack(
          children: [
            Row(
              children: [
                // ==========================================
                // A. BAGIAN KIRI (VOUCHER STUB)
                // ==========================================
                Container(
                  width: stubWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: stubGradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // 1. Icon Kategori Voucher
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.35),
                            width: 1.2,
                          ),
                        ),
                        child: Icon(icon, color: Colors.white, size: 20),
                      ),
                      const SizedBox(height: 5),
                      // 2. Nama Kategori Voucher
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // Garis Perforasi Vertikal (Dashed Divider)
                SizedBox(
                  width: 1,
                  child: CustomPaint(
                    painter: _DashedLinePainter(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                ),

                // ==========================================
                // B. BAGIAN KANAN (VOUCHER CONTENT)
                // ==========================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Konten 4 Baris
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // BARIS 1: Judul Voucher Dominan + Badge Kuantitas
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
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
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ),
                                  if (quantity > 1) ...[
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: GageTheme.primaryLight,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: GageTheme.primary.withValues(alpha: 0.25)),
                                      ),
                                      child: Text(
                                        'x$quantity',
                                        style: const TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: GageTheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              // BARIS 2: Informasi Minimum Pembelian
                              Text(
                                minOrderText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),

                              // BARIS 3: Badge Ketentuan Voucher
                              ClipRect(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  physics: const BouncingScrollPhysics(),
                                  child: Row(
                                    children: [
                                      _buildBadge(tag, isDark, isPrimary: true),
                                      if (secondaryBadge != null) ...[
                                        const SizedBox(width: 4),
                                        _buildBadge(secondaryBadge, isDark, isPrimary: false),
                                      ],
                                    ],
                                  ),
                                ),
                              ),

                              // BARIS 4: Masa Berlaku dengan Icon Jam + Tautan S&K
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 11,
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      'Berlaku hingga $expiry',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? Colors.white54 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Text(
                                      '•',
                                      style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white38 : Colors.grey.shade400),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: onTermsTap,
                                    child: const Text(
                                      'S&K',
                                      style: TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        color: GageTheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ==========================================
                        // C. TOMBOL AKSI ("Pakai")
                        // ==========================================
                        SizedBox(
                          height: 32,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8), // Rounded rectangle sesuai instruksi
                              ),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: onApply,
                            child: const Text(
                              'Pakai',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Takik Setengah Lingkaran (Ticket Cutout) Pada Sisi Kiri Kartu
            Positioned(
              left: -8,
              top: (cardHeight - 16) / 2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: screenBgColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderColor, width: 1),
                ),
              ),
            ),

            // Takik Setengah Lingkaran Atas & Bawah Pada Garis Perforasi
            Positioned(
              left: stubWidth - 7,
              top: -8,
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
              bottom: -8,
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

/// Painter garis putus-putus (perforasi vertikal tiket)
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double dashHeight = 4.0;
    const double dashSpace = 3.0;
    double startY = 8.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    while (startY < size.height - 8.0) {
      canvas.drawLine(Offset(0, startY), Offset(0, startY + dashHeight), paint);
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) => oldDelegate.color != color;
}
