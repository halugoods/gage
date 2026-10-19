import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';
import 'package:gage_app/features/driver/presentation/active_trip_screen.dart';

class DriverActivityScreen extends StatefulWidget {
  const DriverActivityScreen({super.key});

  @override
  State<DriverActivityScreen> createState() => _DriverActivityScreenState();
}

class _DriverActivityScreenState extends State<DriverActivityScreen> {
  int _selectedSegment = 0; // 0: Berjalan, 1: Riwayat
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _historyTrips = [
    {
      'id': 'ORD-88210',
      'service': 'GageFood',
      'serviceType': 'food',
      'merchant': 'Mie Ayam Bakso Pak Man',
      'destination': 'Dusun Sambiroto, Pracimantoro',
      'distance': '1.8 KM',
      'earnings': 9500,
      'payment': 'GagePay',
      'time': 'Hari ini, 09:15',
      'status': 'Selesai',
    },
    {
      'id': 'ORD-88194',
      'service': 'GageRide',
      'serviceType': 'ride',
      'merchant': 'Terminal Pracimantoro',
      'destination': 'SMK PGRI 8 Pracimantoro',
      'distance': '2.4 KM',
      'earnings': 12000,
      'payment': 'Tunai COD',
      'time': 'Hari ini, 08:30',
      'status': 'Selesai',
    },
    {
      'id': 'ORD-88182',
      'service': 'GageSend',
      'serviceType': 'send',
      'merchant': 'Kios Pupuk Sumber Rejeki',
      'destination': 'Gedong RT 02/04, Pracimantoro',
      'distance': '3.2 KM',
      'earnings': 15000,
      'payment': 'GagePay',
      'time': 'Hari ini, 07:45',
      'status': 'Selesai',
    },
    {
      'id': 'ORD-87990',
      'service': 'GageFood',
      'serviceType': 'food',
      'merchant': 'Rocket Chicken Pracimantoro',
      'destination': 'Kantor Kecamatan Pracimantoro',
      'distance': '1.2 KM',
      'earnings': 8000,
      'payment': 'Tunai COD',
      'time': 'Kemarin, 19:20',
      'status': 'Selesai',
    },
  ];

  Color _getServiceColor(String serviceType) {
    switch (serviceType) {
      case 'food':
        return const Color(0xFFEA580C);
      case 'ride':
        return GageTheme.primary;
      case 'send':
        return const Color(0xFF16A34A);
      default:
        return const Color(0xFF2563EB);
    }
  }

  IconData _getServiceIcon(String serviceType) {
    switch (serviceType) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'ride':
        return Icons.two_wheeler_rounded;
      case 'send':
        return Icons.local_shipping_rounded;
      default:
        return Icons.directions_car_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final orderProv = context.watch<DriverOrderProvider>();
    final activeTrip = orderProv.activeTrip;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        title: const Text(
          'Aktivitas Pesanan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Segmented Bar iOS Style
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSegmentButton(0, 'Sedang Berjalan', activeTrip != null),
                  ),
                  Expanded(
                    child: _buildSegmentButton(1, 'Riwayat Selesai'),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: _selectedSegment == 0
                  ? _buildActiveSection(activeTrip, isDark)
                  : _buildHistorySection(isDark),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const DriverBottomNavBar(currentIndex: 1),
    );
  }

  Widget _buildSegmentButton(int index, String label, [bool hasBadge = false]) {
    final isSelected = _selectedSegment == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedSegment = index);
      },
      borderRadius: BorderRadius.circular(9),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF334155) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 1))]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? (isDark ? Colors.white : const Color(0xFF0F172A))
                    : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
            if (hasBadge) ...[
              const SizedBox(width: 6),
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: GageTheme.accentGreen,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActiveSection(DriverOrderOffer? activeTrip, bool isDark) {
    if (activeTrip == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.two_wheeler_rounded, size: 36, color: GageTheme.primary),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tidak Ada Trip Aktif',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Nyalakan switch Siaga di Beranda untuk mulai menerima tawaran pesanan otomatis.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
              ),
            ],
          ),
        ),
      );
    }

    final serviceColor = _getServiceColor(activeTrip.serviceType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: GageTheme.primary.withValues(alpha: 0.35), width: 1.5),
          boxShadow: [
            BoxShadow(color: GageTheme.primary.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: serviceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(_getServiceIcon(activeTrip.serviceType), size: 20, color: serviceColor),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activeTrip.serviceType.toUpperCase(),
                          style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: serviceColor),
                        ),
                        Text(
                          '#${activeTrip.id}',
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GageTheme.accentGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Sedang Diantar',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: GageTheme.accentGreen),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.radio_button_checked_rounded, color: GageTheme.accentGreen, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activeTrip.pickupAddress,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: SizedBox(height: 14, child: VerticalDivider(width: 2, thickness: 1.5, color: Colors.grey)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    activeTrip.dropoffAddress,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pendapatan Bersih:',
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
                ),
                Text(
                  currencyFormatter.format(activeTrip.driverEarnings),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => ActiveTripScreen(trip: activeTrip),
                    ),
                  );
                },
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Buka Navigasi Perjalanan', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _historyTrips.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, idx) {
        final trip = _historyTrips[idx];
        final serviceColor = _getServiceColor(trip['serviceType']);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: serviceColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_getServiceIcon(trip['serviceType']), size: 16, color: serviceColor),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        trip['service'],
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: serviceColor),
                      ),
                    ],
                  ),
                  Text(
                    trip['time'],
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${trip['merchant']} → ${trip['destination']}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF334155) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          trip['payment'],
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        trip['distance'],
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                  Text(
                    '+${currencyFormatter.format(trip['earnings'])}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.accentGreen,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
