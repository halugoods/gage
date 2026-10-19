import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_order_provider.dart';

/// Modal Pop-up Tawaran Orderan Masuk (Gojek / Grab Style)
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
    final progressVal = (countdown / 20.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Countdown Bar di Bagian Atas
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progressVal,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    countdown <= 5 ? Colors.red : serviceColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 2. Header: Badge Layanan + Timer Countdown
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: serviceColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: serviceColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(_getServiceIcon(), size: 16, color: serviceColor),
                        const SizedBox(width: 6),
                        Text(
                          offer.serviceName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                            color: serviceColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 16, color: countdown <= 5 ? Colors.red : Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '$countdown detik',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: countdown <= 5 ? Colors.red : (isDark ? Colors.white70 : Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3. Highlight Ongkir Bersih Driver
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pendapatan Bersih Driver',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : GageTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currency.format(offer.driverEarnings),
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: serviceColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: offer.paymentMethod == 'GAGEPAY' ? Colors.blue.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        offer.paymentMethod == 'GAGEPAY' ? 'Non-Tunai (GagePay)' : 'Tunai (Cash)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: offer.paymentMethod == 'GAGEPAY' ? Colors.blue.shade800 : Colors.green.shade800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 4. Detail Rute: Jemput -> Antar
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(Icons.circle, color: GageTheme.primary, size: 12),
                      Container(width: 1.5, height: 32, color: Colors.grey.shade300),
                      const Icon(Icons.location_on, color: GageTheme.accentGreen, size: 14),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titik Jemput
                        Text(
                          offer.pickupAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Lokasi Penjemputan',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : GageTheme.textMuted),
                        ),
                        const SizedBox(height: 10),

                        // Titik Tujuan
                        Text(
                          offer.dropoffAddress,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          'Lokasi Pengantaran • Jarak ${offer.distanceKm} km',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : GageTheme.textMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Catatan / Item Pesanan jika ada
              if (offer.orderItems.isNotEmpty || offer.notes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    offer.orderItems.isNotEmpty
                        ? 'Pesanan: ${offer.orderItems.join(", ")}'
                        : 'Catatan: ${offer.notes}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11.5, color: Colors.amber.shade900, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const SizedBox(height: 18),

              // 5. Tombol Aksi: Tolak vs Terima Order
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white70 : Colors.black87,
                          side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: onDecline,
                        child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_circle_rounded, size: 20),
                        label: const Text('Terima Order', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
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
