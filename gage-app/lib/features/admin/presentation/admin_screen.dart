import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_map_fullscreen_dialog.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_map_pin_detail_sheet.dart';

/// Screen Utama GAGE Admin - Tab 0: GAGE Heatmap & Operasional
/// Dirancang sesuai standar profesional software modern (Gojek / Apple Maps):
/// - Peta Google Maps Retina kawasan Pracimantoro
/// - GAGE Heatmap interaktif tanpa label badge kaku
/// - Mode fullscreen 1 layar penuh untuk observasi teritorial & dokumentasi
/// - Kartu ringkasan operasional bersih bergaya iOS Inset Grouped
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final MapController _mapController = MapController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _selectedFleetFilter = 'Semua';
  String _mapFilter = 'Semua'; // 'Semua', 'Pesanan Aktif', 'Pengguna', 'Driver Online', 'Merchant'

  // Titik Pusat Operasional Pracimantoro
  final LatLng _centerPracimantoro = const LatLng(-8.0963, 110.8427);

  // Titik Area Konsentrasi Pesanan
  final List<Map<String, dynamic>> _activeOrderAreas = [
    {
      'name': 'Pasar Pracimantoro',
      'location': const LatLng(-8.0975, 110.8415),
      'orders': 14,
      'gmv': 'Rp 320.000',
      'radius': 420.0,
      'color': const Color(0xFFE11D48),
      'detail': 'Area belanja sembako, sayur & kuliner pagi',
    },
    {
      'name': 'Terminal & Pertokoan Stasiun',
      'location': const LatLng(-8.0950, 110.8390),
      'orders': 8,
      'gmv': 'Rp 195.000',
      'radius': 300.0,
      'color': const Color(0xFFF97316),
      'detail': 'Area transit penumpang & pengiriman ekspres paket',
    },
    {
      'name': 'Kawasan Simpang Giribelah',
      'location': const LatLng(-8.1180, 110.8550),
      'orders': 6,
      'gmv': 'Rp 125.000',
      'radius': 340.0,
      'color': const Color(0xFFF59E0B),
      'detail': 'Kawasan permukiman & rute driver selatan',
    },
  ];

  // Data Pengguna Terdaftar & Pengguna Baru di Pracimantoro
  final List<Map<String, dynamic>> _registeredUsers = [
    {
      'id': 'usr-01',
      'name': 'Siti Rahmawati',
      'phone': '6281234567891',
      'location': const LatLng(-8.0945, 110.8410),
      'address': 'Dusun Krajan, Pracimantoro',
      'hasOrdered': true,
      'isOrdering': true,
      'currentOrder': 'Dimsum Sewu (2x Porsi)',
      'orderId': 'ORD-9021',
      'joinDate': '12 Okt 2026',
    },
    {
      'id': 'usr-02',
      'name': 'Bagus Prasetyo',
      'phone': '6285799881122',
      'location': const LatLng(-8.0990, 110.8445),
      'address': 'Dekat Lapangan Pracimantoro',
      'hasOrdered': true,
      'isOrdering': false,
      'joinDate': '14 Okt 2026',
    },
    {
      'id': 'usr-03',
      'name': 'Dewi Anggraini',
      'phone': '6281311223344',
      'location': const LatLng(-8.1020, 110.8385),
      'address': 'Jl. Ronggowarsito No. 12',
      'hasOrdered': false,
      'isOrdering': false,
      'joinDate': 'Hari Ini',
    },
    {
      'id': 'usr-04',
      'name': 'Rahmat Hidayat',
      'phone': '6282244556677',
      'location': const LatLng(-8.0920, 110.8460),
      'address': 'Kompleks Pasar Lama',
      'hasOrdered': false,
      'isOrdering': false,
      'joinDate': 'Kemarin',
    },
    {
      'id': 'usr-05',
      'name': 'Nurul Khotimah',
      'phone': '6287811992233',
      'location': const LatLng(-8.1150, 110.8520),
      'address': 'Kawasan Giribelah',
      'hasOrdered': true,
      'isOrdering': true,
      'currentOrder': 'GageRide ke Terminal',
      'orderId': 'RIDE-8812',
      'joinDate': '08 Okt 2026',
    },
  ];

  // Titik Merchant Kuliner & Toko Utama
  final List<Map<String, dynamic>> _merchantLocations = [
    {
      'name': 'Dimsum Sewu Mas Agus',
      'location': const LatLng(-8.0968, 110.8432),
      'category': 'Kuliner',
      'isOpen': true,
      'phone': '6281234567888',
      'address': 'Jl. Wonogiri - Pracimantoro No. 45',
      'ordersToday': 9,
    },
    {
      'name': 'Kios Sayur Segar Bu Slamet',
      'location': const LatLng(-8.0982, 110.8410),
      'category': 'Sembako',
      'isOpen': true,
      'phone': '6285788990011',
      'address': 'Blok B Pasar Pracimantoro',
      'ordersToday': 7,
    },
    {
      'name': 'Apotek Kimia Farma Praci',
      'location': const LatLng(-8.0958, 110.8440),
      'category': 'Kesehatan',
      'isOpen': true,
      'phone': '6281355667788',
      'address': 'Sebelah Barat SPBU Pracimantoro',
      'ordersToday': 5,
    },
  ];

  // Daftar Driver Online
  final List<Map<String, dynamic>> _activeDrivers = [
    {
      'id': 'DRV-001',
      'name': 'Mas Budi Santoso',
      'phone': '6281234567890',
      'vehicle': 'Honda Vario 160 • AB 4521 WZ',
      'plate': 'AB 4521 WZ',
      'vehicleType': 'motor',
      'type': 'Motor',
      'status': 'Mengantar',
      'currentOrder': 'ORD-9021 (Dimsum Sewu)',
      'location': 'Jl. Raya Pracimantoro (Dekat Pasar)',
      'locationCoord': const LatLng(-8.0970, 110.8420),
      'rating': 4.96,
    },
    {
      'id': 'DRV-002',
      'name': 'Pak Joko Purnomo',
      'phone': '6285712345678',
      'vehicle': 'Toyota Avanza • AD 8912 TX',
      'plate': 'AD 8912 TX',
      'vehicleType': 'car',
      'type': 'Mobil',
      'status': 'Standby',
      'currentOrder': '-',
      'location': 'Pangkalan Terminal Pracimantoro',
      'locationCoord': const LatLng(-8.0952, 110.8385),
      'rating': 4.92,
    },
    {
      'id': 'DRV-003',
      'name': 'Mas Agus Setiawan',
      'phone': '6281399887766',
      'vehicle': 'Yamaha NMAX • AD 3310 QR',
      'plate': 'AD 3310 QR',
      'vehicleType': 'motor',
      'type': 'Motor',
      'status': 'Mengantar',
      'currentOrder': 'ORD-9019 (Apotek Kimia Farma)',
      'location': 'Menuju Desa Gedong',
      'locationCoord': const LatLng(-8.0940, 110.8450),
      'rating': 4.98,
    },
    {
      'id': 'DRV-004',
      'name': 'Mas Hendra Pratama',
      'phone': '6289876543210',
      'vehicle': 'Honda Beat Deluxe • AD 2244 BB',
      'plate': 'AD 2244 BB',
      'vehicleType': 'motor',
      'type': 'Motor',
      'status': 'Standby',
      'currentOrder': '-',
      'location': 'Pusat Kuliner Pracimantoro',
      'locationCoord': const LatLng(-8.0965, 110.8435),
      'rating': 4.89,
    },
    {
      'id': 'DRV-005',
      'name': 'Pak Bambang Triyono',
      'phone': '6281244556677',
      'vehicle': 'Daihatsu Sigra • AD 9011 ZX',
      'plate': 'AD 9011 ZX',
      'vehicleType': 'car',
      'type': 'Mobil',
      'status': 'Mengantar',
      'currentOrder': 'RIDE-8812 (Giribelah ke Praci Kota)',
      'location': 'Jl. Giribelah KM 2',
      'locationCoord': const LatLng(-8.1160, 110.8535),
      'rating': 4.95,
    },
  ];

  String _getFormattedToday() {
    try {
      return DateFormat('EEEE, d MMM yyyy', 'id_ID').format(DateTime.now());
    } catch (_) {
      try {
        return DateFormat('EEEE, d MMM yyyy').format(DateTime.now());
      } catch (_) {
        final now = DateTime.now();
        return '${now.day}/${now.month}/${now.year}';
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredDrivers = _activeDrivers.where((d) {
      if (_selectedFleetFilter == 'Semua') return true;
      if (_selectedFleetFilter == 'Mengantar') return d['status'] == 'Mengantar';
      if (_selectedFleetFilter == 'Standby') return d['status'] == 'Standby';
      if (_selectedFleetFilter == 'Motor') return d['type'] == 'Motor';
      if (_selectedFleetFilter == 'Mobil') return d['type'] == 'Mobil';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'GAGE Heatmap',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Data',
            onPressed: () {
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data operasional diperbarui.'), duration: Duration(seconds: 1)),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. KARTU RINGKASAN METRIK OPERASIONAL (iOS Inset Grouped)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'RINGKASAN OPERASIONAL HARI INI',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.8, color: GageTheme.primary),
                      ),
                      Text(
                        _getFormattedToday(),
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Pesanan Hari Ini',
                          value: '28 Order',
                          subtitle: '24 Selesai • 4 Berjalan',
                          icon: Icons.receipt_long_rounded,
                          color: GageTheme.primary,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 46, color: isDark ? Colors.white12 : Colors.grey.shade200),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Estimasi GMV',
                          value: 'Rp 640.000',
                          subtitle: 'Komisi: Rp 64.000',
                          icon: Icons.payments_rounded,
                          color: Colors.green.shade700,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Driver Online',
                          value: '${_activeDrivers.length} Driver',
                          subtitle: '3 Motor • 2 Mobil',
                          icon: Icons.two_wheeler_rounded,
                          color: Colors.blue.shade700,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 46, color: isDark ? Colors.white12 : Colors.grey.shade200),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Merchant Terdaftar',
                          value: '${_merchantLocations.length} Mitra',
                          subtitle: 'Semua Buka',
                          icon: Icons.storefront_rounded,
                          color: Colors.orange.shade800,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. GAGE HEATMAP DENGAN GOOGLE MAPS RETINA
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.local_fire_department_rounded, size: 18, color: Color(0xFFE11D48)),
                            SizedBox(width: 8),
                            Text(
                              'GAGE Heatmap',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // Tombol Perbesar Peta (Fullscreen)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                AdminMapFullscreenDialog.show(
                                  context: context,
                                  initialCenter: _centerPracimantoro,
                                  initialZoom: 14.5,
                                  activeOrderAreas: _activeOrderAreas,
                                  usersList: _registeredUsers,
                                  driversList: _activeDrivers,
                                  merchantsList: _merchantLocations,
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.fullscreen_rounded, size: 13, color: GageTheme.primary),
                                    SizedBox(width: 3),
                                    Text('Perbesar', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // Tombol Reset Center
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: () {
                                HapticFeedback.lightImpact();
                                _mapController.move(_centerPracimantoro, 14.5);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.white12 : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(Icons.my_location_rounded, size: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Filter Chips Heatmap (Standard Profesional)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', 'Pesanan Aktif', 'Pengguna', 'Driver Online', 'Merchant'].map((filter) {
                          final isSel = _mapFilter == filter;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _mapFilter = filter);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? GageTheme.primary
                                      : (isDark ? Colors.white10 : Colors.grey.shade100),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                                    color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  // FlutterMap dengan Google Maps Retina TileLayer & Marker Clean
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                    child: SizedBox(
                      height: 240,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _centerPracimantoro,
                          initialZoom: 14.3,
                          minZoom: 11.0,
                          maxZoom: 18.5,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                            subdomains: const ['0', '1', '2', '3'],
                            userAgentPackageName: 'com.gage.admin',
                            maxZoom: 20,
                          ),
                          // Lapisan Circle Heatmap Area Pesanan
                          if (_mapFilter == 'Semua' || _mapFilter == 'Pesanan Aktif')
                            CircleLayer(
                              circles: _activeOrderAreas.map((h) {
                                final color = h['color'] as Color;
                                return CircleMarker(
                                  point: h['location'] as LatLng,
                                  color: color.withValues(alpha: 0.20),
                                  borderColor: color.withValues(alpha: 0.8),
                                  borderStrokeWidth: 1.5,
                                  useRadiusInMeter: true,
                                  radius: h['radius'] as double,
                                );
                              }).toList(),
                            ),
                          // Lapisan Marker Entitas Bersih (Tanpa Badge Teks Mengambang)
                          MarkerLayer(
                            markers: _buildCleanMarkers(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. DAFTAR DRIVER ONLINE & PESANAN AKTIF
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'DRIVER ONLINE & PESANAN AKTIF',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5, color: Colors.grey),
                ),
                Text(
                  '${filteredDrivers.length} Driver',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Filter Tabs Armada
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Mengantar', 'Standby', 'Motor', 'Mobil'].map((f) {
                  final isSel = _selectedFleetFilter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(f, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.w500)),
                      selected: isSel,
                      selectedColor: GageTheme.primary,
                      labelStyle: TextStyle(color: isSel ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                      side: BorderSide(color: isSel ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300)),
                      onSelected: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFleetFilter = f);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // Driver Cards
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDrivers.length,
              separatorBuilder: (_, index) => const SizedBox(height: 10),
              itemBuilder: (ctx, idx) {
                final d = filteredDrivers[idx];
                final isDelivering = d['status'] == 'Mengantar';
                final isCar = d['vehicleType'] == 'car';

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                            ),
                            child: Image.asset(
                              isCar ? 'assets/images/gage_car_3d.png' : 'assets/images/gage_ride_3d.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  d['name'] as String,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d['vehicle'] as String,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDelivering
                                  ? GageTheme.primary.withValues(alpha: 0.12)
                                  : const Color(0xFF00AA13).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              d['status'] as String,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: isDelivering ? GageTheme.primary : const Color(0xFF00AA13),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.my_location_rounded, size: 12, color: GageTheme.primary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                d['location'] as String,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
                            const SizedBox(width: 2),
                            Text('${d['rating']}', style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      if (isDelivering) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining_rounded, size: 13, color: GageTheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Pesanan: ${d['currentOrder']}',
                                style: const TextStyle(fontSize: 11, color: GageTheme.primary, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () async {
                              final uri = Uri.parse('https://wa.me/${d['phone']}');
                              if (await canLaunchUrl(uri)) launchUrl(uri, mode: LaunchMode.externalApplication);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.chat_rounded, size: 12, color: Colors.green),
                                  SizedBox(width: 4),
                                  Text('WhatsApp Driver', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
      bottomNavigationBar: const AdminBottomNavBar(currentIndex: 0),
    );
  }

  List<Marker> _buildCleanMarkers(BuildContext context) {
    final List<Marker> list = [];

    // 1. Pesanan Aktif (Clean Red Circular Pin)
    if (_mapFilter == 'Semua' || _mapFilter == 'Pesanan Aktif') {
      for (final spot in _activeOrderAreas) {
        final loc = spot['location'] as LatLng;
        final color = spot['color'] as Color? ?? GageTheme.primary;

        list.add(
          Marker(
            point: loc,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': 'order',
                'name': spot['name'] ?? 'Area Pesanan',
                'status': 'Aktif',
                'subtitle': '${spot['orders']} Pesanan • GMV ${spot['gmv']}',
                'address': spot['detail'] ?? 'Pracimantoro',
                'extraInfo': 'Konsentrasi pesanan aktif saat ini di wilayah ini.',
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 2),
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 6),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.shopping_bag_rounded, color: color, size: 18),
                ),
              ),
            ),
          ),
        );
      }
    }

    // 2. Pengguna Terdaftar & Pengguna Baru (Clean Avatar Pin)
    if (_mapFilter == 'Semua' || _mapFilter == 'Pengguna') {
      for (final u in _registeredUsers) {
        final loc = u['location'] as LatLng;
        final isOrdering = u['isOrdering'] == true;
        final hasOrdered = u['hasOrdered'] == true;

        list.add(
          Marker(
            point: loc,
            width: isOrdering ? 38 : 28,
            height: isOrdering ? 38 : 28,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': isOrdering ? 'order' : 'user',
                'name': u['name'] ?? 'Pengguna',
                'phone': u['phone'] ?? '',
                'hasOrdered': hasOrdered,
                'status': isOrdering ? 'Sedang Memesan' : (hasOrdered ? 'Pengguna Aktif' : 'Pengguna Baru Terdaftar'),
                'subtitle': isOrdering ? 'Pesanan: ${u['currentOrder']}' : 'Terdaftar ${u['joinDate']}',
                'address': u['address'] ?? 'Pracimantoro',
                'orderId': isOrdering ? u['orderId'] : null,
                'extraInfo': isOrdering ? 'Sedang menunggu pengantaran pesanan.' : 'Pengguna terdaftar di aplikasi GAGE.',
              }),
              child: isOrdering
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: GageTheme.primary, width: 2),
                        boxShadow: [
                          BoxShadow(color: GageTheme.primary.withValues(alpha: 0.4), blurRadius: 8),
                        ],
                      ),
                      child: const Center(
                        child: Icon(Icons.delivery_dining_rounded, color: GageTheme.primary, size: 20),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        color: hasOrdered ? Colors.blue.shade50 : const Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasOrdered ? Colors.blue.shade700 : const Color(0xFF16A34A),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
                        ],
                      ),
                      child: Center(
                        child: Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: hasOrdered ? Colors.blue.shade800 : const Color(0xFF15803D),
                        ),
                      ),
                    ),
            ),
          ),
        );
      }
    }

    // 3. Driver Online
    if (_mapFilter == 'Semua' || _mapFilter == 'Driver Online') {
      for (final d in _activeDrivers) {
        final loc = d['locationCoord'] as LatLng;
        final isCar = d['vehicleType'] == 'car';

        list.add(
          Marker(
            point: loc,
            width: 36,
            height: 36,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': 'driver',
                'name': d['name'] ?? 'Mitra Pengemudi',
                'phone': d['phone'] ?? '',
                'status': 'Driver Online',
                'subtitle': '${d['plate']} • Rating ${d['rating']}',
                'address': d['location'] ?? 'Pracimantoro',
                'extraInfo': 'Driver online siap menerima order.',
              }),
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00AA13), width: 1.8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 5),
                  ],
                ),
                child: Image.asset(
                  isCar ? 'assets/images/gage_car_3d.png' : 'assets/images/gage_ride_3d.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        );
      }
    }

    // 4. Merchant
    if (_mapFilter == 'Semua' || _mapFilter == 'Merchant') {
      for (final m in _merchantLocations) {
        final loc = m['location'] as LatLng;
        list.add(
          Marker(
            point: loc,
            width: 34,
            height: 34,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': 'merchant',
                'name': m['name'] ?? 'Merchant',
                'phone': m['phone'] ?? '',
                'status': m['isOpen'] == true ? 'Buka' : 'Tutup',
                'subtitle': '${m['category']} • ${m['ordersToday']} Order Hari Ini',
                'address': m['address'] ?? 'Pracimantoro',
                'extraInfo': 'Mitra merchant terdaftar di GAGE.',
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade800, width: 1.8),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.storefront_rounded, size: 16, color: Colors.orange.shade800),
                ),
              ),
            ),
          ),
        );
      }
    }

    return list;
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45),
          ),
        ],
      ),
    );
  }
}
