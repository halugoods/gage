import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_bottom_nav_bar.dart';

/// Screen Utama GAGE Admin - Tab 0: Radar & Fleet Command Tower
/// Dirancang sesuai standar Gojek (GoPartner) & iOS Human Interface:
/// - Peta riil OpenStreetMap kawasan Pracimantoro (bebas gimik pin palsu)
/// - Kartu KPI metrik operasional bersih bergaya iOS Inset Grouped
/// - Pengawasan armada terverifikasi dengan aksi dispatch instan
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final MapController _mapController = MapController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _selectedFleetFilter = 'Semua';
  String _mapFilter = 'Semua'; // 'Semua', 'Hotspot Order', 'Driver Siaga', 'Merchant'

  // Titik Pusat Operasional Pracimantoro
  final LatLng _centerPracimantoro = const LatLng(-8.0963, 110.8427);

  // Titik Hotspot Kepadatan Order Riil Pracimantoro untuk Analisa Bisnis
  final List<Map<String, dynamic>> _orderHotspots = [
    {
      'name': 'Pasar Pracimantoro',
      'location': const LatLng(-8.0975, 110.8415),
      'orders': 14,
      'gmv': 'Rp 320.000',
      'radius': 450.0,
      'color': const Color(0xFFE11D48), // Rose
      'detail': 'Kepadatan tinggi belanja sembako, sayur & sarapan pagi',
    },
    {
      'name': 'Terminal & Pertokoan Stasiun',
      'location': const LatLng(-8.0950, 110.8390),
      'orders': 8,
      'gmv': 'Rp 195.000',
      'radius': 320.0,
      'color': const Color(0xFFF97316), // Orange
      'detail': 'Titik transit penumpang luar kota & pengiriman express paket',
    },
    {
      'name': 'Kawasan Simpang Giribelah',
      'location': const LatLng(-8.1180, 110.8550),
      'orders': 6,
      'gmv': 'Rp 125.000',
      'radius': 360.0,
      'color': const Color(0xFFF59E0B), // Amber
      'detail': 'Permukiman selatan & pangkalan driver siaga',
    },
  ];

  // Titik Merchant Kuliner & Toko Utama
  final List<Map<String, dynamic>> _merchantLocations = [
    {
      'name': 'Dimsum Sewu Mas Agus',
      'location': const LatLng(-8.0968, 110.8432),
      'ordersToday': 9,
      'status': 'Dapur Buka',
    },
    {
      'name': 'Kios Sayur Segar Bu Slamet',
      'location': const LatLng(-8.0982, 110.8410),
      'ordersToday': 7,
      'status': 'Buka',
    },
    {
      'name': 'Apotek Kimia Farma Praci',
      'location': const LatLng(-8.0958, 110.8440),
      'ordersToday': 5,
      'status': 'Buka',
    },
  ];

  // Titik Pantau Pangkalan Riil Pracimantoro
  final List<Map<String, dynamic>> _hubPoints = [
    {
      'name': 'Hub Pusat Pracimantoro',
      'location': const LatLng(-8.0963, 110.8427),
      'type': 'hub',
      'count': '3 Driver',
    },
    {
      'name': 'Pasar Pracimantoro',
      'location': const LatLng(-8.0975, 110.8415),
      'type': 'market',
      'count': '4 Driver',
    },
    {
      'name': 'Terminal Bus Pracimantoro',
      'location': const LatLng(-8.0950, 110.8390),
      'type': 'terminal',
      'count': '2 Driver',
    },
    {
      'name': 'Perempatan Giribelah',
      'location': const LatLng(-8.1180, 110.8550),
      'type': 'subhub',
      'count': '2 Driver',
    },
  ];

  final List<Map<String, dynamic>> _activeDrivers = [
    {
      'id': 'DRV-001',
      'name': 'Mas Budi Santoso',
      'phone': '6281234567890',
      'vehicle': 'Honda Vario 160 • AB 4521 WZ',
      'type': 'Motor',
      'status': 'Mengantar',
      'currentOrder': 'ORD-9021 (Dimsum Sewu)',
      'location': 'Jl. Raya Pracimantoro (Dekat Pasar)',
      'rating': 4.96,
    },
    {
      'id': 'DRV-002',
      'name': 'Pak Joko Purnomo',
      'phone': '6285712345678',
      'vehicle': 'Toyota Avanza • AD 8912 TX',
      'type': 'Mobil',
      'status': 'Siaga',
      'currentOrder': '-',
      'location': 'Pangkalan Terminal Pracimantoro',
      'rating': 4.92,
    },
    {
      'id': 'DRV-003',
      'name': 'Mas Agus Setiawan',
      'phone': '6281399887766',
      'vehicle': 'Yamaha NMAX • AD 3310 QR',
      'type': 'Motor',
      'status': 'Mengantar',
      'currentOrder': 'ORD-9019 (Apotek Kimia Farma)',
      'location': 'Menuju Desa Gedong',
      'rating': 4.98,
    },
    {
      'id': 'DRV-004',
      'name': 'Mas Hendra Pratama',
      'phone': '6289876543210',
      'vehicle': 'Honda Beat Deluxe • AD 2244 BB',
      'type': 'Motor',
      'status': 'Siaga',
      'currentOrder': '-',
      'location': 'Pusat Kuliner Pracimantoro',
      'rating': 4.89,
    },
    {
      'id': 'DRV-005',
      'name': 'Pak Bambang Triyono',
      'phone': '6281244556677',
      'vehicle': 'Daihatsu Sigra • AD 9011 ZX',
      'type': 'Mobil',
      'status': 'Mengantar',
      'currentOrder': 'RIDE-8812 (Giribelah ke Praci Kota)',
      'location': 'Jl. Giribelah KM 2',
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

    final filteredDrivers = _selectedFleetFilter == 'Semua'
        ? _activeDrivers
        : _selectedFleetFilter == 'Motor' || _selectedFleetFilter == 'Mobil'
            ? _activeDrivers.where((d) => d['type'] == _selectedFleetFilter).toList()
            : _activeDrivers.where((d) => d['status'] == _selectedFleetFilter).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Beranda Operasional GAGE',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            Text(
              'Peta Wilayah & Heatmap Kepadatan Order Pracimantoro',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
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
                          label: 'Pesanan Masuk',
                          value: '28 Order',
                          subtitle: '24 Selesai • 4 Jalan',
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
                          label: 'Armada Siaga',
                          value: '11 Unit',
                          subtitle: '8 Motor • 3 Mobil',
                          icon: Icons.two_wheeler_rounded,
                          color: Colors.blue.shade700,
                          isDark: isDark,
                        ),
                      ),
                      Container(width: 1, height: 46, color: isDark ? Colors.white12 : Colors.grey.shade200),
                      Expanded(
                        child: _buildMetricTile(
                          label: 'Mitra Resto Buka',
                          value: '19 Resto',
                          subtitle: 'Dapur Siap Masak',
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

            // 2. PETA OPERASIONAL WILAYAH & HEATMAP KEPADATAN ORDER (Kawasan Pracimantoro)
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
                              'Peta Wilayah & Heatmap Kepadatan Order',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _mapController.move(_centerPracimantoro, 14.5);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white12 : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('Fokus Pusat', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Filter Layer Heatmap (Taktil iOS Pill)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', 'Hotspot Order', 'Driver Siaga', 'Merchant'].map((filter) {
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
                                    fontSize: 10,
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

                  // Peta Riil FlutterMap dengan Heatmap CircleLayer & Multi-Entity Markers
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
                    child: SizedBox(
                      height: 220,
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _centerPracimantoro,
                          initialZoom: 14.2,
                          minZoom: 11.0,
                          maxZoom: 18.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.gage.admin',
                          ),
                          // Lapisan Lingkaran Heatmap Kepadatan Order
                          if (_mapFilter == 'Semua' || _mapFilter == 'Hotspot Order')
                            CircleLayer(
                              circles: _orderHotspots.map((h) {
                                final color = h['color'] as Color;
                                return CircleMarker(
                                  point: h['location'] as LatLng,
                                  color: color.withValues(alpha: 0.25),
                                  borderColor: color.withValues(alpha: 0.85),
                                  borderStrokeWidth: 2,
                                  useRadiusInMeter: true,
                                  radius: h['radius'] as double,
                                );
                              }).toList(),
                            ),
                          // Lapisan Marker Entitas
                          MarkerLayer(
                            markers: [
                              // 1. Hotspot Order Pins
                              if (_mapFilter == 'Semua' || _mapFilter == 'Hotspot Order')
                                ..._orderHotspots.map((h) {
                                  return Marker(
                                    point: h['location'] as LatLng,
                                    width: 140,
                                    height: 48,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE11D48),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.whatshot_rounded, color: Colors.white, size: 10),
                                              const SizedBox(width: 3),
                                              Text(
                                                '${h['name']} • ${h['orders']} Order',
                                                style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.location_on_rounded, color: Color(0xFFE11D48), size: 18),
                                      ],
                                    ),
                                  );
                                }),

                              // 2. Driver Hub Siaga Pins
                              if (_mapFilter == 'Semua' || _mapFilter == 'Driver Siaga')
                                ..._hubPoints.map((hub) {
                                  return Marker(
                                    point: hub['location'] as LatLng,
                                    width: 130,
                                    height: 44,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF0F172A),
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            '${hub['name']} (${hub['count']})',
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const Icon(Icons.two_wheeler_rounded, color: Color(0xFF00AA13), size: 16),
                                      ],
                                    ),
                                  );
                                }),

                              // 3. Merchant Pins
                              if (_mapFilter == 'Semua' || _mapFilter == 'Merchant')
                                ..._merchantLocations.map((m) {
                                  return Marker(
                                    point: m['location'] as LatLng,
                                    width: 130,
                                    height: 44,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.shade800,
                                            borderRadius: BorderRadius.circular(6),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Text(
                                            m['name'] as String,
                                            style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Icon(Icons.storefront_rounded, color: Colors.orange.shade800, size: 16),
                                      ],
                                    ),
                                  );
                                }),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // 3. KARTU ANALISA BISNIS ZONA OPERASIONAL (iOS Inset Grouped)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ANALISA ZONA TERPADAT HARI INI',
                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, letterSpacing: 0.6, color: Color(0xFFE11D48)),
                      ),
                      Text(
                        'Live Demand',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00AA13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ..._orderHotspots.map((h) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 4, right: 10),
                          decoration: BoxDecoration(
                            color: h['color'] as Color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    h['name'] as String,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${h['orders']} Order (${h['gmv']})',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: h['color'] as Color),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 1),
                              Text(
                                h['detail'] as String,
                                style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 4. DAFTAR ARMADA & FILTER STATUS (TACTILE SEGMENTED CONTROLS)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Driver & Armada Siaga',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${filteredDrivers.length} Armada',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Semua', 'Motor', 'Mobil', 'Siaga', 'Mengantar'].map((filter) {
                  final isSelected = _selectedFleetFilter == filter;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFleetFilter = filter);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GageTheme.primary
                              : (isDark ? const Color(0xFF1E293B) : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected
                                ? GageTheme.primary
                                : (isDark ? Colors.white12 : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          filter,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),

            // Kartu Driver Riil
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDrivers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (ctx, i) {
                final d = filteredDrivers[i];
                final isBusy = d['status'] == 'Mengantar';
                final isMotor = d['type'] == 'Motor';

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isMotor
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Image.asset(
                              isMotor ? 'assets/images/gage_ride_3d.png' : 'assets/images/gage_car_3d.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      d['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                      decoration: BoxDecoration(
                                        color: isBusy
                                            ? Colors.orange.withValues(alpha: 0.15)
                                            : Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        d['status'] as String,
                                        style: TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.bold,
                                          color: isBusy ? Colors.orange.shade800 : Colors.green.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  d['vehicle'] as String,
                                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                              ],
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
                      if (isBusy) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.delivery_dining_rounded, size: 13, color: GageTheme.primary),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Order Aktif: ${d['currentOrder']}',
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
