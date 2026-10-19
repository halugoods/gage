import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/admin/presentation/widgets/admin_map_pin_detail_sheet.dart';

/// Fullscreen Dialog untuk GAGE Heatmap (1 Layar Penuh)
/// Memberikan keleluasaan bagi Admin untuk memantau sebaran teritorial Pracimantoro
/// dan dokumentasi/story materi publikasi tanpa distraksi UI lain.
class AdminMapFullscreenDialog extends StatefulWidget {
  final LatLng initialCenter;
  final double initialZoom;
  final List<Map<String, dynamic>> activeOrderAreas;
  final List<Map<String, dynamic>> usersList;
  final List<Map<String, dynamic>> driversList;
  final List<Map<String, dynamic>> merchantsList;

  const AdminMapFullscreenDialog({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.5,
    required this.activeOrderAreas,
    required this.usersList,
    required this.driversList,
    required this.merchantsList,
  });

  static Future<void> show({
    required BuildContext context,
    required LatLng initialCenter,
    double initialZoom = 14.5,
    required List<Map<String, dynamic>> activeOrderAreas,
    required List<Map<String, dynamic>> usersList,
    required List<Map<String, dynamic>> driversList,
    required List<Map<String, dynamic>> merchantsList,
  }) {
    HapticFeedback.mediumImpact();
    return Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => AdminMapFullscreenDialog(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          activeOrderAreas: activeOrderAreas,
          usersList: usersList,
          driversList: driversList,
          merchantsList: merchantsList,
        ),
      ),
    );
  }

  @override
  State<AdminMapFullscreenDialog> createState() => _AdminMapFullscreenDialogState();
}

class _AdminMapFullscreenDialogState extends State<AdminMapFullscreenDialog> {
  final MapController _mapController = MapController();
  String _selectedFilter = 'Semua'; // 'Semua', 'Pesanan Aktif', 'Pengguna', 'Driver Online', 'Merchant'

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Filter Markers
    final List<Marker> markers = [];
    final List<CircleMarker> circles = [];

    // 1. Pesanan Aktif
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Pesanan Aktif') {
      for (final spot in widget.activeOrderAreas) {
        final loc = spot['location'] as LatLng;
        final color = spot['color'] as Color? ?? GageTheme.primary;
        final radius = (spot['radius'] as num?)?.toDouble() ?? 300.0;

        circles.add(
          CircleMarker(
            point: loc,
            radius: radius,
            useRadiusInMeter: true,
            color: color.withValues(alpha: 0.16),
            borderColor: color.withValues(alpha: 0.8),
            borderStrokeWidth: 1.5,
          ),
        );

        markers.add(
          Marker(
            point: loc,
            width: 44,
            height: 44,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': 'order',
                'name': spot['name'] ?? 'Area Pesanan',
                'status': 'Aktif',
                'subtitle': '${spot['orders'] ?? 0} Pesanan Berjalan • GMV ${spot['gmv'] ?? "Rp 0"}',
                'address': spot['detail'] ?? 'Kawasan Pracimantoro',
                'extraInfo': 'Area konsentrasi pesanan aktif saat ini di Pracimantoro.',
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1),
                  ],
                  border: Border.all(color: color, width: 2),
                ),
                child: Center(
                  child: Icon(Icons.shopping_bag_rounded, color: color, size: 20),
                ),
              ),
            ),
          ),
        );
      }
    }

    // 2. Pengguna Terdaftar & Pengguna Baru
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Pengguna') {
      for (final u in widget.usersList) {
        final loc = u['location'] as LatLng;
        final bool isOrdering = u['isOrdering'] == true;
        final bool hasOrdered = u['hasOrdered'] == true;

        markers.add(
          Marker(
            point: loc,
            width: isOrdering ? 44 : 34,
            height: isOrdering ? 44 : 34,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': isOrdering ? 'order' : 'user',
                'name': u['name'] ?? 'Pengguna GAGE',
                'phone': u['phone'] ?? '',
                'hasOrdered': hasOrdered,
                'status': isOrdering ? 'Sedang Memesan' : (hasOrdered ? 'Pengguna Aktif' : 'Pengguna Baru Terdaftar'),
                'subtitle': isOrdering ? 'Pesanan: ${u['currentOrder'] ?? "Belanja"}' : 'Bergabung sejak ${u['joinDate'] ?? "2026"}',
                'address': u['address'] ?? 'Pracimantoro',
                'extraInfo': isOrdering
                    ? 'Pengguna saat ini sedang menunggu pengantaran pesanan.'
                    : 'Pengguna terdaftar di aplikasi GAGE kawasan Pracimantoro.',
                'orderId': isOrdering ? (u['orderId'] ?? 'ORD-ACTIVE') : null,
              }),
              child: isOrdering
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: GageTheme.primary.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2),
                        ],
                        border: Border.all(color: GageTheme.primary, width: 2.5),
                      ),
                      child: const Center(
                        child: Icon(Icons.delivery_dining_rounded, color: GageTheme.primary, size: 22),
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
                          size: 16,
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
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Driver Online') {
      for (final d in widget.driversList) {
        final loc = d['locationCoord'] as LatLng;
        final isCar = d['vehicleType'] == 'car';

        markers.add(
          Marker(
            point: loc,
            width: 42,
            height: 42,
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
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00AA13), width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6),
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
    if (_selectedFilter == 'Semua' || _selectedFilter == 'Merchant') {
      for (final m in widget.merchantsList) {
        final loc = m['location'] as LatLng;
        markers.add(
          Marker(
            point: loc,
            width: 38,
            height: 38,
            child: GestureDetector(
              onTap: () => AdminMapPinDetailSheet.show(context, {
                'type': 'merchant',
                'name': m['name'] ?? 'Merchant Mitra',
                'phone': m['phone'] ?? '',
                'status': m['isOpen'] == true ? 'Buka' : 'Tutup',
                'subtitle': m['category'] ?? 'Kuliner',
                'address': m['address'] ?? 'Pracimantoro',
                'extraInfo': 'Toko/Resto mitra terdaftar di GAGE.',
              }),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.orange.shade700, width: 2),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 4),
                  ],
                ),
                child: Center(
                  child: Icon(Icons.storefront_rounded, size: 18, color: Colors.orange.shade800),
                ),
              ),
            ),
          ),
        );
      }
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      body: Stack(
        children: [
          // FlutterMap Fullscreen dengan Google Maps Retina TileLayer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: widget.initialCenter,
              initialZoom: widget.initialZoom,
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
              CircleLayer(circles: circles),
              MarkerLayer(markers: markers),
            ],
          ),

          // Header Overlay: Judul & Tombol Tutup
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
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
                        const Text(
                          'GAGE Heatmap',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Tombol Reset Center
                  FloatingActionButton.small(
                    heroTag: 'fs_recenter',
                    elevation: 2,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    child: const Icon(Icons.my_location_rounded, size: 18),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _mapController.move(widget.initialCenter, widget.initialZoom);
                    },
                  ),
                  const SizedBox(width: 8),
                  // Tombol Tutup Fullscreen
                  FloatingActionButton.small(
                    heroTag: 'fs_close',
                    elevation: 2,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    child: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),

          // Bottom Filter Chips & Counter
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildFilterChip('Semua', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pesanan Aktif', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pengguna', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Driver Online', isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip('Merchant', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Ringkasan Counter Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildCounterItem('Pengguna', '${widget.usersList.length}', Colors.blue.shade700),
                        _buildDivider(),
                        _buildCounterItem('Pesanan', '${widget.activeOrderAreas.fold(0, (sum, item) => sum + ((item['orders'] as int?) ?? 0))}', GageTheme.primary),
                        _buildDivider(),
                        _buildCounterItem('Driver', '${widget.driversList.length}', const Color(0xFF00AA13)),
                        _buildDivider(),
                        _buildCounterItem('Merchant', '${widget.merchantsList.length}', Colors.orange.shade700),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isDark) {
    final isSelected = _selectedFilter == label;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedFilter = label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary
              : (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.92) : Colors.white.withValues(alpha: 0.92)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 4),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }

  Widget _buildCounterItem(String label, String count, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(count, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: color)),
        const SizedBox(height: 1),
        Text(label, style: const TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 24, color: Colors.grey.shade300);
  }
}
