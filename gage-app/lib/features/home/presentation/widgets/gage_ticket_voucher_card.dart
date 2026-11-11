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
  final bool isApplied;
  final bool isEligible;
  final String? ineligibilityReason;
  final bool compact;

  const GageTicketVoucherCard({
    super.key,
    required this.voucher,
    required this.onApply,
    required this.onTermsTap,
    this.isApplied = false,
    this.isEligible = true,
    this.ineligibilityReason,
    this.compact = false,
  });

  Color _getStubBgColor(String service, String type, bool isDark) {
    if (type == 'delivery') {
      return isDark ? const Color(0xFF063B37) : const Color(0xFFCCFBF1);
    }
    switch (service) {
      case 'GAGE Food':
        return isDark ? const Color(0xFF3B1D0E) : const Color(0xFFFFEDD5);
      case 'GAGE Ride':
        return isDark ? const Color(0xFF172554) : const Color(0xFFDBEAFE);
      case 'GAGE Car':
        return isDark ? const Color(0xFF1E1B4B) : const Color(0xFFE0E7FF);
      case 'GAGE Mart':
        return isDark ? const Color(0xFF052E16) : const Color(0xFFDCFCE7);
      case 'GAGE Send':
        return isDark ? const Color(0xFF451A03) : const Color(0xFFFFEDD5);
      case 'GAGE Pay':
        return isDark ? const Color(0xFF422006) : const Color(0xFFFEF3C7);
      default:
        return isDark ? const Color(0xFF3B1D0E) : const Color(0xFFFFEDD5);
    }
  }

  Color _getActiveColor(String service, String type) {
    if (type == 'delivery') return const Color(0xFF0D9488);
    const map = {
      'GAGE Food': Color(0xFFEA580C),
      'GAGE Ride': Color(0xFF2563EB),
      'GAGE Car': Color(0xFF4F46E5),
      'GAGE Mart': Color(0xFF16A34A),
      'GAGE Send': Color(0xFFEA580C),
      'GAGE Pay': Color(0xFFD97706),
    };
    return map[service] ?? GageTheme.primary;
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
        borderRadius: BorderRadius.circular(20),
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

  int _parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? GageTheme.darkSurface : Colors.white;
    final screenBgColor = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final borderColor = isDark ? GageTheme.darkBorder : Colors.grey.shade200;

    final service = voucher['service'] as String? ?? 'GAGE Food';
    final type = voucher['type'] as String? ?? 'order';
    final stubBgColor = _getStubBgColor(service, type, isDark);
    final activeColor = _getActiveColor(service, type);
    final icon = _getCategoryIcon(service, type);
    final label = _getCategoryLabel(service, type);

    final title = voucher['title'] as String? ?? voucher['discountText'] as String? ?? 'Diskon Spesial';
    final code = voucher['code'] as String? ?? '';
    final minOrder = _parseInt(voucher['minOrder'] ?? voucher['minSpend'], 0);
    final expiry = voucher['expiry'] as String? ?? '31 Des 2026';
    final quantity = _parseInt(voucher['quantity'], 1);

    // Badges filter admin yang rapi (tidak berlebihan)
    final tag = voucher['tag'] as String?;
    final secondaryBadge = voucher['badge'] as String?;

    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final minOrderText = minOrder > 0 ? 'Min. belanja ${currencyFmt.format(minOrder)}' : 'Tanpa min. belanja';

    final double stubWidth = compact ? 62.0 : 78.0;
    final double cardHeight = compact ? 82.0 : 102.0;

    return Opacity(
      opacity: isEligible ? 1.0 : 0.62,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: cardHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isApplied ? activeColor : borderColor,
            width: isApplied ? 1.8 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black38 : Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
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
                // ==========================================
                // A. BAGIAN KIRI (STUB VOUCHER 1:1 Image 4)
                // ==========================================
                Container(
                  width: stubWidth,
                  height: double.infinity,
                  color: stubBgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(icon, color: activeColor, size: 22),
                      const SizedBox(height: 4),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: activeColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.3,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // B. BAGIAN KANAN (VOUCHER CONTENT)
                // ==========================================
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // BARIS 1: Judul Voucher Dominan Lebih Tebal (Beri ruang untuk badge di kanan atas)
                        Padding(
                          padding: EdgeInsets.only(right: quantity > 1 ? 34.0 : 0.0),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : const Color(0xFF1E293B),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),

                        // BARIS 2: Informasi Minimum Pembelian
                        Text(
                          minOrderText,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
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
                                if (code.isNotEmpty) ...[
                                  _buildBadge(code, isDark, isPrimary: true),
                                ],
                                if (tag != null && tag.isNotEmpty && tag != code) ...[
                                  const SizedBox(width: 4),
                                  _buildBadge(tag, isDark, isPrimary: false),
                                ],
                                if (secondaryBadge != null && secondaryBadge.isNotEmpty && secondaryBadge != tag) ...[
                                  const SizedBox(width: 4),
                                  _buildBadge(secondaryBadge, isDark, isPrimary: false),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // BARIS 4: Masa Berlaku dengan Icon Jam + Tautan S&K (Beri ruang tombol 'Pakai' di kanan bawah)
                        Padding(
                          padding: const EdgeInsets.only(right: 68.0),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 10.5,
                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  'Berlaku hingga $expiry',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white54 : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: Text(
                                  '•',
                                  style: TextStyle(fontSize: 9.0, color: isDark ? Colors.white38 : Colors.grey.shade400),
                                ),
                              ),
                              InkWell(
                                onTap: onTermsTap,
                                child: const Text(
                                  'S&K',
                                  style: TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: GageTheme.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ==========================================
            // C. BADGE KUANTITAS DI POJOK KANAN ATAS
            // ==========================================
            if (quantity > 1)
              Positioned(
                top: 8,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: GageTheme.primaryLight,
                    borderRadius: BorderRadius.circular(20),
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
              ),

            // ==========================================
            // D. TOMBOL AKSI ("Pakai") DI POJOK KANAN BAWAH
            // ==========================================
            Positioned(
              bottom: 8,
              right: 10,
              child: SizedBox(
                height: 28,
                child: isApplied
                    ? ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: onApply,
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_rounded, size: 13, color: Colors.white),
                            SizedBox(width: 3),
                            Text(
                              'Terpasang',
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isEligible
                              ? GageTheme.primary
                              : (isDark ? Colors.white12 : Colors.grey.shade300),
                          foregroundColor: isEligible
                              ? Colors.white
                              : (isDark ? Colors.white38 : Colors.grey.shade600),
                          shape: const StadiumBorder(),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: isEligible ? onApply : null,
                        child: const Text(
                          'Pakai',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
              ),
            ),

            // Garis Perforasi Vertikal Putus-putus Tepat di Tengah Seam (x = stubWidth)
            Positioned(
              left: stubWidth - 0.75,
              top: 8,
              bottom: 8,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(7, (i) => Container(
                  width: 1.5,
                  height: 5,
                  color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                )),
              ),
            ),

            // Takik Setengah Lingkaran Atas & Bawah Pada Garis Perforasi (Symmetric Center at x = stubWidth)
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
    ),
    );
  }
}
