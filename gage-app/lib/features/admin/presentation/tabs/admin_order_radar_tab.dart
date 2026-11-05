import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/emergency_driver_reassign_sheet.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_map_fullscreen_dialog.dart';

/// Tab 1: Live Order Radar se-Pracimantoro
/// Monitoring pesanan aktif multi-kanal (Aplikasi, WhatsApp, Web Toko)
/// Dengan kemampuan Intervensi Darurat (Manual Driver Re-assign)
class AdminOrderRadarTab extends StatefulWidget {
  const AdminOrderRadarTab({super.key});

  @override
  State<AdminOrderRadarTab> createState() => _AdminOrderRadarTabState();
}

class _AdminOrderRadarTabState extends State<AdminOrderRadarTab> {
  final MapController _mapController = MapController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Filter Status: 'Semua', 'Masuk', 'Disiapkan', 'Diantar', 'Selesai'
  String _selectedStatusFilter = 'Semua';
  String _selectedChannelFilter = 'Semua'; // 'Semua', 'APP', 'WA', 'WEB'
  bool _showMapMini = true;

  // Titik Pusat Operasional Pracimantoro
  final LatLng _centerPracimantoro = const LatLng(-8.0963, 110.8427);

  // Data Titik Konsentrasi Pesanan
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
  ];

  // Daftar Driver Online Pracimantoro
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
      'location': 'Pangkalan Terminal Pracimantoro',
      'locationCoord': const LatLng(-8.0952, 110.8385),
      'rating': 4.92,
    },
  ];

  // Titik Merchant Utama
  final List<Map<String, dynamic>> _merchantsList = [
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
      'name': 'Kios Sayur Bu Slamet',
      'location': const LatLng(-8.0982, 110.8410),
      'category': 'Sembako',
      'isOpen': true,
      'phone': '6285788990011',
      'address': 'Blok B Pasar Pracimantoro',
      'ordersToday': 7,
    },
  ];

  // Pelanggan Aktif
  final List<Map<String, dynamic>> _usersList = [
    {
      'id': 'usr-01',
      'name': 'Mba Siti Rahayu',
      'phone': '6281987654321',
      'location': const LatLng(-8.0945, 110.8410),
      'address': 'Dusun Gebang Kulon',
      'hasOrdered': true,
      'isOrdering': true,
    },
  ];

  // State Pesanan Aktif Teritorial Pracimantoro
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ORD-9021',
      'channel': 'APP',
      'service': 'GageFood',
      'status': 'Diantar',
      'statusRaw': 'ON_DELIVERY',
      'customer': 'Mba Siti Rahayu',
      'phone': '6281987654321',
      'merchant': 'Dimsum Sewu Mas Agus',
      'pickup': 'Jl. Raya Pracimantoro No. 14',
      'dropoff': 'Dusun Gebang Kulon RT 02/04',
      'items': '2x Dimsum Siomay, 1x Es Teh Jumbo',
      'total': 35000,
      'shippingFee': 6000,
      'driver': 'Mas Budi Santoso',
      'driverPhone': '6281234567890',
      'driverVehicle': 'Honda Vario 160 • AB 4521 WZ',
      'time': '12:45 WIB',
      'paymentMethod': 'GAGEPAY',
      'location': const LatLng(-8.0970, 110.8420),
      'hasIntervention': false,
    },
    {
      'id': 'WA-8804',
      'channel': 'WA',
      'service': 'GageSend',
      'status': 'Masuk',
      'statusRaw': 'PENDING_DRIVER',
      'customer': 'Pak Haji Marwan',
      'phone': '6281233445566',
      'merchant': 'Toko Bangunan Berkah Jaya',
      'pickup': 'Depan Koramil Pracimantoro',
      'dropoff': 'Desa Tubokarto RT 01',
      'items': 'Titip Antar 1 Sak Semen Gresik + Paku 5cm',
      'total': 68000,
      'shippingFee': 10000,
      'driver': 'Belum Ditugaskan',
      'driverPhone': '',
      'driverVehicle': '-',
      'time': '12:38 WIB',
      'paymentMethod': 'CASH_COD',
      'location': const LatLng(-8.0945, 110.8410),
      'hasIntervention': false,
    },
    {
      'id': 'ORD-9020',
      'channel': 'APP',
      'service': 'GageFood',
      'status': 'Disiapkan',
      'statusRaw': 'PREPARING',
      'customer': 'Mas Bagus Prasetyo',
      'phone': '6285799881122',
      'merchant': 'Ayam Geprek Sambal Korek Bu Sri',
      'pickup': 'Jl. Lintas Selatan KM 1',
      'dropoff': 'Dekat Lapangan Pracimantoro',
      'items': '2x Paket Geprek Paha Atas Level 3',
      'total': 32000,
      'shippingFee': 6000,
      'driver': 'Mas Hendra Pratama',
      'driverPhone': '6289876543210',
      'driverVehicle': 'Honda Beat Deluxe • AD 2244 BB',
      'time': '12:35 WIB',
      'paymentMethod': 'QRIS',
      'location': const LatLng(-8.0990, 110.8445),
      'hasIntervention': false,
    },
    {
      'id': 'WEB-1049',
      'channel': 'WEB',
      'service': 'GageShop',
      'status': 'Diantar',
      'statusRaw': 'ON_DELIVERY',
      'customer': 'Ibu Nurhayati',
      'phone': '6285788990011',
      'merchant': 'Kios Sayur Segar Bu Slamet',
      'pickup': 'Pasar Pracimantoro Los A',
      'dropoff': 'Perumahan Griya Praci Indah Blok B4',
      'items': '1kg Bawang Merah, 2 Ikat Bayam, 1kg Telur',
      'total': 48000,
      'shippingFee': 7500,
      'driver': 'Mas Agus Setiawan',
      'driverPhone': '6281399887766',
      'driverVehicle': 'Yamaha NMAX • AD 3310 QR',
      'time': '12:20 WIB',
      'paymentMethod': 'GAGEPAY',
      'location': const LatLng(-8.0982, 110.8410),
      'hasIntervention': false,
    },
    {
      'id': 'WA-8803',
      'channel': 'WA',
      'service': 'GageRide',
      'status': 'Disiapkan',
      'statusRaw': 'DRIVER_STANDBY',
      'customer': 'Mas Wahyu Hidayat',
      'phone': '6289988776655',
      'merchant': 'Pangkalan Stasiun/Terminal',
      'pickup': 'Terminal Bus Pracimantoro',
      'dropoff': 'Pracimantoro Kota (Pulang Kampung)',
      'items': 'Carter Mobil Avanza 4 Penumpang + Koper',
      'total': 45000,
      'shippingFee': 45000,
      'driver': 'Pak Joko Purnomo',
      'driverPhone': '6285712345678',
      'driverVehicle': 'Toyota Avanza • AD 8912 TX',
      'time': '11:55 WIB',
      'paymentMethod': 'CASH_COD',
      'location': const LatLng(-8.0952, 110.8385),
      'hasIntervention': false,
    },
    {
      'id': 'ORD-9018',
      'channel': 'APP',
      'service': 'GageFood',
      'status': 'Selesai',
      'statusRaw': 'COMPLETED',
      'customer': 'Ibu Dewi Anggraini',
      'phone': '6281311223344',
      'merchant': 'Apotek Kimia Farma Praci',
      'pickup': 'Jl. Ronggowarsito',
      'dropoff': 'Dusun Krajan Lor',
      'items': '1x Tolak Angin Box, 1x Minyak Kayu Putih 60ml',
      'total': 42500,
      'shippingFee': 6000,
      'driver': 'Pak Bambang Triyono',
      'driverPhone': '6281244556677',
      'driverVehicle': 'Daihatsu Sigra • AD 9011 ZX',
      'time': '11:15 WIB',
      'paymentMethod': 'QRIS',
      'location': const LatLng(-8.0958, 110.8440),
      'hasIntervention': false,
    },
  ];

  // Helper filter pesanan
  List<Map<String, dynamic>> get _filteredOrders {
    return _orders.where((o) {
      if (_selectedStatusFilter != 'Semua' && o['status'] != _selectedStatusFilter) {
        return false;
      }
      if (_selectedChannelFilter != 'Semua' && o['channel'] != _selectedChannelFilter) {
        return false;
      }
      return true;
    }).toList();
  }

  int _countByStatus(String status) {
    return _orders.where((o) => o['status'] == status).length;
  }

  void _openEmergencyReassign(Map<String, dynamic> order) {
    EmergencyDriverReassignSheet.show(
      context: context,
      order: order,
      onReassigned: (newDriver, reason) {
        setState(() {
          order['driver'] = newDriver;
          order['hasIntervention'] = true;
          order['interventionNote'] = 'Dialihkan ke $newDriver ($reason)';
        });
      },
    );
  }

  void _openManualOrderDialog() {
    HapticFeedback.lightImpact();
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final merchantCtrl = TextEditingController(text: 'Pasar Pracimantoro');
    final itemsCtrl = TextEditingController();
    final totalCtrl = TextEditingController();
    String service = 'GageFood';
    String assignedDriver = 'Mas Budi Santoso (Motor)';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            left: 20,
            right: 20,
            top: 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Icon(Icons.add_shopping_cart_rounded, color: GageTheme.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Input Pesanan Manual (WA / Telepon)',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Pelanggan', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Nomor WhatsApp / HP', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: merchantCtrl,
                  decoration: const InputDecoration(labelText: 'Toko / Lokasi Jemput', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: itemsCtrl,
                  decoration: const InputDecoration(labelText: 'Daftar Barang / Pesanan', isDense: true),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: totalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Estimasi Total (Rp)', isDense: true),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (nameCtrl.text.isEmpty) return;
                      final newId = 'MAN-${DateTime.now().millisecondsSinceEpoch % 10000}';
                      setState(() {
                        _orders.insert(0, {
                          'id': newId,
                          'channel': 'WA',
                          'service': service,
                          'status': 'Masuk',
                          'statusRaw': 'PENDING_DRIVER',
                          'customer': nameCtrl.text,
                          'phone': phoneCtrl.text,
                          'merchant': merchantCtrl.text,
                          'pickup': 'Pracimantoro',
                          'dropoff': 'Dusun Sekitar',
                          'items': itemsCtrl.text.isEmpty ? 'Pesanan Telepon/WA' : itemsCtrl.text,
                          'total': int.tryParse(totalCtrl.text) ?? 25000,
                          'shippingFee': 6000,
                          'driver': assignedDriver.split(' (')[0],
                          'driverPhone': '6281234567890',
                          'driverVehicle': 'Motor',
                          'time': 'Baru Saja',
                          'paymentMethod': 'CASH_COD',
                          'location': _centerPracimantoro,
                          'hasIntervention': true,
                          'interventionNote': 'Input Manual Petugas Admin',
                        });
                      });
                      Navigator.pop(ctx);
                      HapticFeedback.mediumImpact();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Simpan & Terbitkan ke Radar', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _filteredOrders;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
      children: [
        // Top Metric Strip (Status Counters)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusPill(label: 'Semua', count: _orders.length, color: Colors.blueGrey, isDark: isDark),
              const SizedBox(width: 8),
              _buildStatusPill(label: 'Masuk', count: _countByStatus('Masuk'), color: const Color(0xFFE11D48), isDark: isDark),
              const SizedBox(width: 8),
              _buildStatusPill(label: 'Disiapkan', count: _countByStatus('Disiapkan'), color: const Color(0xFFF59E0B), isDark: isDark),
              const SizedBox(width: 8),
              _buildStatusPill(label: 'Diantar', count: _countByStatus('Diantar'), color: const Color(0xFF00AA13), isDark: isDark),
              const SizedBox(width: 8),
              _buildStatusPill(label: 'Selesai', count: _countByStatus('Selesai'), color: const Color(0xFF64748B), isDark: isDark),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Radar Map Card (Glassmorphic Mini Preview)
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 10, 8),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00AA13),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Radar Satelit Teritorial Pracimantoro',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      icon: Icon(_showMapMini ? Icons.unfold_less_rounded : Icons.unfold_more_rounded, size: 20),
                      tooltip: 'Toggle Peta',
                      onPressed: () => setState(() => _showMapMini = !_showMapMini),
                    ),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, size: 20, color: GageTheme.primary),
                      tooltip: 'Layar Penuh',
                      onPressed: () => AdminMapFullscreenDialog.show(
                        context: context,
                        initialCenter: _centerPracimantoro,
                        initialZoom: 14.5,
                        activeOrderAreas: _activeOrderAreas,
                        usersList: _usersList,
                        driversList: _activeDrivers,
                        merchantsList: _merchantsList,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showMapMini)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                  child: SizedBox(
                    height: 160,
                    child: FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _centerPracimantoro,
                        initialZoom: 14.2,
                        minZoom: 11,
                        maxZoom: 18,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'id.halugoods.gage.admin',
                        ),
                        MarkerLayer(
                          markers: _orders.map((o) {
                            final loc = o['location'] as LatLng? ?? _centerPracimantoro;
                            final isDelivery = o['status'] == 'Diantar';
                            return Marker(
                              point: loc,
                              width: 32,
                              height: 32,
                              child: GestureDetector(
                                onTap: () => _openEmergencyReassign(o),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: isDelivery ? const Color(0xFF00AA13) : Colors.red.shade600,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                                    ],
                                  ),
                                  child: Icon(
                                    isDelivery ? Icons.directions_bike_rounded : Icons.local_mall_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Header Antrean & Tombol Input Manual
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.radar_rounded, size: 18, color: GageTheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Antrean Pesanan (${filtered.length})',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            InkWell(
              onTap: _openManualOrderDialog,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_rounded, size: 16, color: GageTheme.primary),
                    SizedBox(width: 4),
                    Text(
                      'Input Manual',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: GageTheme.primary),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Channel Quick Filters
        Row(
          children: [
            _buildChannelChip('Semua', isDark),
            const SizedBox(width: 6),
            _buildChannelChip('APP', isDark),
            const SizedBox(width: 6),
            _buildChannelChip('WA', isDark),
            const SizedBox(width: 6),
            _buildChannelChip('WEB', isDark),
          ],
        ),
        const SizedBox(height: 12),

        // List Orders
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text(
                  'Tidak ada pesanan aktif pada filter ini',
                  style: TextStyle(color: isDark ? Colors.white60 : Colors.black45, fontSize: 13),
                ),
              ],
            ),
          )
        else
          ...filtered.map((order) => _buildOrderCard(order, isDark)),
      ],
    );
  }

  Widget _buildStatusPill({
    required String label,
    required int count,
    required Color color,
    required bool isDark,
  }) {
    final isSelected = _selectedStatusFilter == label;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedStatusFilter = label);
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.25) : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelChip(String channel, bool isDark) {
    final isSelected = _selectedChannelFilter == channel;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedChannelFilter = channel);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary.withValues(alpha: 0.15)
              : (isDark ? const Color(0xFF1E293B) : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          channel,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black54),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, bool isDark) {
    final status = order['status'] ?? 'Masuk';
    Color statusColor = const Color(0xFFE11D48);
    if (status == 'Disiapkan') statusColor = const Color(0xFFF59E0B);
    if (status == 'Diantar') statusColor = const Color(0xFF00AA13);
    if (status == 'Selesai') statusColor = const Color(0xFF64748B);

    final isIntervened = order['hasIntervention'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isIntervened
              ? Colors.amber.shade700
              : (isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          width: isIntervened ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              border: Border(
                bottom: BorderSide(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
            ),
            child: Row(
              children: [
                // Order ID & Service
                Text(
                  order['id'],
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['service'],
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: GageTheme.primary),
                  ),
                ),
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    order['channel'],
                    style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, color: Colors.blueGrey),
                  ),
                ),
                const Spacer(),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor),
                  ),
                ),
              ],
            ),
          ),

          // Intervention Alert Strip if any
          if (isIntervened)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              color: Colors.amber.withValues(alpha: 0.15),
              child: Row(
                children: [
                  Icon(Icons.shield_rounded, size: 14, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      order['interventionNote'] ?? 'Diintervensi oleh Admin',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Order Details
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Merchant & Customer
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.storefront_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['merchant'],
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            order['pickup'],
                            style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black45),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_rounded, size: 16, color: GageTheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${order['customer']} (${order['dropoff']})',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          Text(
                            'Item: ${order['items']}',
                            style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Driver & Total Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.two_wheeler_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order['driver'],
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                            ),
                            Text(
                              order['driverVehicle'],
                              style: TextStyle(fontSize: 9, color: isDark ? Colors.white54 : Colors.black45),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          currencyFormatter.format(order['total']),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          '${order['paymentMethod']} • ${order['time']}',
                          style: TextStyle(fontSize: 9.5, color: isDark ? Colors.white54 : Colors.black45),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Emergency Intervention Button Bar
                Row(
                  children: [
                    // Chat Customer WA
                    OutlinedButton.icon(
                      onPressed: () {
                        final phone = order['phone'] ?? '';
                        if (phone.isNotEmpty) {
                          launchUrl(Uri.parse('https://wa.me/$phone?text=Halo%20Admin%20GAGE%20Pracimantoro'));
                        }
                      },
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                      label: const Text('WA Cust', style: TextStyle(fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Tombol Intervensi Darurat Re-assign Driver
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openEmergencyReassign(order),
                        icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                        label: const Text(
                          'Re-assign Driver (Darurat)',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
