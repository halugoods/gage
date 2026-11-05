import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_order_provider.dart';

/// Modal Pop-up Radar Tawaran Pesanan Masuk (GAGE Driver Incoming Offer Sheet)
/// Dirancang ergonomis untuk kurir motor dengan tombol jempol besar & zero-slop UI
class IncomingOfferSheet extends StatelessWidget {
  final DriverOrderOffer offer;
  final int countdown;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingOfferSheet({
    super.key,
    required this.offer,
    required this.countdown,
    required this.onAccept,
    required this.onDecline,
  });

  Color _getServiceColor() {
    switch (offer.serviceType) {
      case 'food':
        return const Color(0xFFEA580C); // Warm orange
      case 'ride':
        return GageTheme.primary; // Red
      case 'car':
        return const Color(0xFF1E88E5); // Blue
      case 'send':
        return const Color(0xFF16A34A); // Emerald green
      case 'shop':
        return const Color(0xFFD97706); // Amber
      default:
        return GageTheme.primary;
    }
  }

  IconData _getServiceIcon() {
    switch (offer.serviceType) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'ride':
        return Icons.two_wheeler_rounded;
      case 'car':
        return Icons.directions_car_rounded;
      case 'send':
        return Icons.local_shipping_rounded;
      case 'shop':
        return Icons.shopping_basket_rounded;
      default:
        return Icons.delivery_dining_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final serviceColor = _getServiceColor();
    // Countdown progress basis 30 detik
    final progressVal = (countdown / 30.0).clamp(0.0, 1.0);
    final isUrgent = countdown <= 7;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 28, offset: Offset(0, -6)),
        ],
        border: Border(
          top: BorderSide(
            color: isUrgent ? Colors.red : serviceColor.withValues(alpha: 0.5),
            width: 2.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. COUNTDOWN PROGRESS BAR (30 DETIK)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 7,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isUrgent ? Colors.red : serviceColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. HEADER: BADGE LAYANAN & TIMER COUNTDOWN 30 DETIK
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: serviceColor.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getServiceIcon(), size: 16, color: serviceColor),
                        const SizedBox(width: 6),
                        Text(
                          offer.serviceName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: serviceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isUrgent ? Colors.red.withValues(alpha: 0.15) : (isDark ? Colors.white10 : Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isUrgent ? Colors.red : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          size: 16,
                          color: isUrgent ? Colors.red : (isDark ? Colors.white70 : Colors.grey.shade700),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '$countdown detik',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isUrgent ? Colors.red : (isDark ? Colors.white : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 3. HIGHLIGHT UPAH BERSIH DRIVER (EKSAK 80% DARI TARIF MURNI OSRM)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: GageTheme.accentGreen.withValues(alpha: isDark ? 0.4 : 0.6),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Upah Bersih Driver',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: GageTheme.accentGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'EKSAK 80%',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          currency.format(offer.driverEarnings),
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF14532D),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          'Tarif Murni OSRM: ${currency.format(offer.totalFare)} (Bagi hasil 80/20)',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: isDark ? Colors.white60 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                          decoration: BoxDecoration(
                            color: offer.isCashCod ? const Color(0xFFEA580C) : const Color(0xFF2563EB),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            offer.isCashCod ? 'TUNAI (COD)' : 'GAGEPAY',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          offer.isCashCod ? 'Tagih di pembeli' : 'Lunas non-tunai',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // 4. DETAIL LOKASI TOKO JEMPUT & ALAMAT ANTAR PEMBELI (OSRM ROUTE)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    // Toko / Titik Jemput
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: serviceColor.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.storefront_rounded, size: 16, color: serviceColor),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.storeName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                offer.pickupAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : GageTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Garis Jarak OSRM
                    Padding(
                      padding: const EdgeInsets.only(left: 14, top: 2, bottom: 2),
                      child: Row(
                        children: [
                          Container(width: 1.5, height: 20, color: Colors.grey.shade400),
                          const SizedBox(width: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.route_rounded, size: 12, color: GageTheme.primary),
                                const SizedBox(width: 4),
                                Text(
                                  '${offer.distanceKm.toStringAsFixed(1)} KM via OSRM',
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Alamat Antar Pembeli
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: GageTheme.accentGreen.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.person_pin_circle_rounded, size: 16, color: GageTheme.accentGreen),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                offer.customerName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                offer.dropoffAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : GageTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Catatan / Barang Pesanan
              if (offer.orderItems.isNotEmpty || offer.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.notes_rounded, size: 14, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          offer.orderItems.isNotEmpty
                              ? 'Item: ${offer.orderItems.join(", ")}'
                              : 'Catatan: ${offer.notes}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // 5. TOMBOL AKSI TACTILE (ERGONOMIS JEMPOL MOTOR)
              Row(
                children: [
                  // Tombol Tolak
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 54, // Ukuran tombol jempol tinggi & mudah di-tap
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          onDecline();
                        },
                        child: const Text(
                          'Tolak',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Tombol Terima Order (Tombol Utama Besar)
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 54, // Tinggi 54px tactile jempol
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.accentGreen,
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          onAccept();
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 24),
                        label: const Text(
                          'TERIMA ORDER',
                          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 0.5),
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
    );
  }
}
