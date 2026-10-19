import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/features/driver/presentation/widgets/incoming_offer_sheet.dart';
import 'package:gage_app/features/driver/presentation/active_trip_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_activity_screen.dart';
import 'package:gage_app/features/driver/presentation/driver_earnings_screen.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';
import 'package:gage_app/shared/widgets/gage_standalone_banner.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';

/// Halaman Utama Portal Pengemudi GAGE Driver (com.gage.driver)
/// Mengadopsi arsitektur full-bleed map dan UI Gojek (GoPartner) modern:
/// - Peta bersih tanpa billboard teks yang menutupi jalanan
/// - Top bar minimalis dengan profil, switch Siaga, dan sheet modal pengaturan layanan
/// - Bottom sheet dashboard dengan tombol Autobid tactile, metrik pendapatan, dan tombol aksi
class DriverScreen extends StatefulWidget {
  const DriverScreen({super.key});

  @override
  State<DriverScreen> createState() => _DriverScreenState();
}

class _DriverScreenState extends State<DriverScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  late AnimationController _pulseController;
  String? _lastAcceptedTripId;
  bool _isLoadingStats = true;
  StreamSubscription<Position>? _gpsSub;

  // Titik hotspot order di Pracimantoro untuk radar siaga
  final List<Map<String, dynamic>> _hotspots = [
    {
      'name': 'Pasar Pracimantoro',
      'label': 'Kuliner & Sembako',
      'location': const LatLng(-8.0975, 110.8415),
      'type': 'food',
      'surge': '+Rp 2.000',
    },
    {
      'name': 'Terminal Bus Pracimantoro',
      'label': 'Penumpang Padat',
      'location': const LatLng(-8.0950, 110.8390),
      'type': 'ride',
      'surge': '+Rp 1.500',
    },
    {
      'name': 'Lapak BaBe & Kios Sedayu',
      'label': 'Paket & Pertanian',
      'location': const LatLng(-8.1020, 110.8490),
      'type': 'shop',
      'surge': '+Rp 1.000',
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _loadDriverStats();
    _initGps();
  }

  Future<void> _initGps() async {
    try {
      final loc = await LocationService.getCurrentLocation();
      if (!mounted) return;
      final orderProv = context.read<DriverOrderProvider>();
      orderProv.updateLocation(loc);
      _mapController.move(loc, 15.5);
    } catch (_) {}

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      final newLoc = LatLng(pos.latitude, pos.longitude);
      final orderProv = context.read<DriverOrderProvider>();
      orderProv.updateLocation(newLoc);
    });
  }

  Future<void> _loadDriverStats() async {
    setState(() => _isLoadingStats = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (!mounted) return;
    setState(() => _isLoadingStats = false);
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _recenterMap(LatLng target) {
    HapticFeedback.lightImpact();
    _mapController.move(target, 15.5);
  }

  Future<void> _handleAcceptOffer(DriverOrderProvider orderProv) async {
    HapticFeedback.heavyImpact();
    final accepted = await orderProv.acceptIncomingOffer();
    if (!mounted) return;
    if (accepted && orderProv.activeTrip != null) {
      _lastAcceptedTripId = orderProv.activeTrip!.id;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ActiveTripScreen(trip: orderProv.activeTrip!),
        ),
      );
    }
  }

  /// Membuka Sheet Modal Pengaturan Layanan Aktif (Ride, Car, Food, Send, Shop)
  void _showServiceSettingsSheet(BuildContext context, DriverOrderProvider orderProv) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allServices = [
      {'id': 'ride', 'title': 'GAGE Ride', 'subtitle': 'Antar jemput penumpang motor', 'icon': Icons.two_wheeler_rounded, 'color': GageTheme.primary},
      {'id': 'car', 'title': 'GAGE Car', 'subtitle': 'Perjalanan mobil & rombongan', 'icon': Icons.directions_car_rounded, 'color': const Color(0xFF1E88E5)},
      {'id': 'food', 'title': 'GAGE Food', 'subtitle': 'Antar makanan & kuliner resto', 'icon': Icons.restaurant_rounded, 'color': const Color(0xFFEA580C)},
      {'id': 'send', 'title': 'GAGE Send', 'subtitle': 'Pengantaran paket & dokumen kilat', 'icon': Icons.local_shipping_rounded, 'color': const Color(0xFF16A34A)},
      {'id': 'shop', 'title': 'GAGE Shop', 'subtitle': 'Belanja sembako & perlengkapan tani', 'icon': Icons.shopping_basket_rounded, 'color': const Color(0xFFD97706)},
    ];

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Layanan Aktif Pengemudi',
                        style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pilih jenis orderan yang ingin Anda terima saat siaga',
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : GageTheme.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${orderProv.activeServices.length}/5 Aktif',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              for (var s in allServices) ...[
                Builder(
                  builder: (_) {
                    final id = s['id'] as String;
                    final isChecked = orderProv.activeServices.contains(id);
                    final color = s['color'] as Color;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isChecked ? color.withValues(alpha: 0.4) : (isDark ? Colors.white10 : Colors.grey.shade200),
                          width: isChecked ? 1.4 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                        leading: Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(s['icon'] as IconData, color: color, size: 22),
                        ),
                        title: Text(
                          s['title'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: Text(
                          s['subtitle'] as String,
                          style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                        trailing: Switch(
                          value: isChecked,
                          activeThumbColor: color,
                          onChanged: (val) {
                            if (!val && orderProv.activeServices.length <= 1) {
                              GageToast.show(context, 'Minimal 1 layanan harus tetap aktif!', type: GageToastType.warning);
                              return;
                            }
                            HapticFeedback.selectionClick();
                            orderProv.toggleService(id);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    );
                  },
                ),
              ],

              const SizedBox(height: 12),
              SizedBox(
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Simpan Pengaturan Layanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openHelpWhatsApp() async {
    final msg = Uri.encodeComponent('Halo Admin Dukungan Mitra GAGE Pracimantoro, saya butuh bantuan saat bertugas.');
    final url = Uri.parse('https://wa.me/6281234567891?text=$msg');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<DriverOrderProvider>();
    final walletProv = context.watch<DriverWalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Deteksi jika pesanan diterima via Autobid di latar belakang
    if (orderProv.activeTrip != null && orderProv.activeTrip!.id != _lastAcceptedTripId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _lastAcceptedTripId = orderProv.activeTrip!.id;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => ActiveTripScreen(trip: orderProv.activeTrip!),
          ),
        );
      });
    }

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          // ────────────────────────────────────────────────────────────────
          // 1. FULL-BLEED RETINA HD GOOGLE MAP (Layar Penuh Edge-to-Edge)
          // ────────────────────────────────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: orderProv.currentLocation,
                initialZoom: 15.2,
                minZoom: 11.0,
                maxZoom: 21.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                  subdomains: const ['0', '1', '2', '3'],
                  tileDimension: 256,
                  userAgentPackageName: 'com.gage.driver',
                  maxZoom: 21.0,
                  fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                ),

                // Area Hotspot Transparan (Tanpa Billboard Teks yang Menutupi Jalan)
                CircleLayer(
                  circles: [
                    // Radar Siaga Driver
                    if (orderProv.isOnline)
                      CircleMarker(
                        point: orderProv.currentLocation,
                        radius: 80,
                        useRadiusInMeter: false,
                        color: GageTheme.accentGreen.withValues(alpha: 0.12),
                        borderColor: GageTheme.accentGreen.withValues(alpha: 0.45),
                        borderStrokeWidth: 1.5,
                      ),
                    // Zona Hotspot Ramai Sekitar (Heatmap Halus)
                    for (var spot in _hotspots)
                      CircleMarker(
                        point: spot['location'] as LatLng,
                        radius: 60,
                        useRadiusInMeter: false,
                        color: Colors.deepOrange.withValues(alpha: 0.14),
                        borderColor: Colors.deepOrange.withValues(alpha: 0.35),
                        borderStrokeWidth: 1.2,
                      ),
                  ],
                ),

                // Marker Lapisan Peta
                MarkerLayer(
                  markers: [
                    // Marker Posisi Driver Sendiri (Gojek / GoPartner Style)
                    Marker(
                      point: orderProv.currentLocation,
                      width: 50,
                      height: 50,
                      child: Container(
                        decoration: BoxDecoration(
                          color: orderProv.isOnline ? const Color(0xFF16A34A) : Colors.grey.shade600,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                          boxShadow: [
                            BoxShadow(
                              color: (orderProv.isOnline ? const Color(0xFF16A34A) : Colors.black)
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.navigation_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),

                    // Marker Titik Hotspot Minimalis (Pin Ikon Api Halus)
                    for (var spot in _hotspots)
                      Marker(
                        point: spot['location'] as LatLng,
                        width: 38,
                        height: 38,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.deepOrange.shade400, width: 1.5),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.local_fire_department_rounded, color: Colors.deepOrange, size: 18),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // ────────────────────────────────────────────────────────────────
          // 2. TOP FLOATING PROFILE & STATUS HEADER (GoPartner Style)
          // ────────────────────────────────────────────────────────────────
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: _buildTopFloatingHeader(orderProv, walletProv, isDark),
              ),
            ),
          ),

          // ────────────────────────────────────────────────────────────────
          // 3. FLOATING ACTION CONTROLS (Recenter GPS)
          // ────────────────────────────────────────────────────────────────
          // Tombol Recenter GPS (Pusatkan Peta ke Lokasi Driver)
          Positioned(
            right: 14,
            bottom: 300,
            child: GageTapScale(
              onTap: () => _recenterMap(orderProv.currentLocation),
              scaleDown: 0.90,
              child: Material(
                elevation: 4,
                shape: const CircleBorder(),
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(Icons.my_location_rounded, color: GageTheme.primary, size: 22),
                ),
              ),
            ),
          ),

          // ────────────────────────────────────────────────────────────────
          // 4. BOTTOM DOCKED DRAGGABLE DASHBOARD SHEET (Gojek GoPartner Style)
          // ────────────────────────────────────────────────────────────────
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.22,
            maxChildSize: 0.88,
            snap: true,
            snapSizes: const [0.22, 0.35, 0.88],
            builder: (context, scrollController) {
              return _buildDraggableDashboard(orderProv, walletProv, scrollController, isDark);
            },
          ),

          // ────────────────────────────────────────────────────────────────
          // 5. POP-UP TAWARAN ORDER MASUK (Modal Gojek / Grab 20 Detik)
          // ────────────────────────────────────────────────────────────────
          if (orderProv.incomingOffer != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IncomingOfferSheet(
                offer: orderProv.incomingOffer!,
                countdown: orderProv.offerCountdown,
                onAccept: () => _handleAcceptOffer(orderProv),
                onDecline: () => orderProv.declineIncomingOffer(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: const DriverBottomNavBar(currentIndex: 0),
    );
  }

  /// Kartu Profil Driver Melayang di Bagian Atas (GoPartner Style)
  Widget _buildTopFloatingHeader(
    DriverOrderProvider orderProv,
    DriverWalletProvider walletProv,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.96) : Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, 4)),
        ],
        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Profil Avatar & Detail Pengemudi
          Expanded(
            child: Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                      child: const Text(
                        'S',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: GageTheme.primary),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: orderProv.isOnline ? const Color(0xFF16A34A) : Colors.grey,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _isLoadingStats
                      ? const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GageSkeletonBox(width: 110, height: 14),
                            SizedBox(height: 6),
                            Row(
                              children: [
                                GageSkeletonBox(width: 58, height: 12),
                                SizedBox(width: 6),
                                GageSkeletonBox(width: 44, height: 12),
                              ],
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    'Syamsul Maarif',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF1E88E5)),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'AD 4521 WN',
                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                const Icon(Icons.star_rounded, size: 13, color: Colors.amber),
                                Text(
                                  ' ${walletProv.rating}',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '• 100%',
                                  style: TextStyle(fontSize: 10, color: Colors.green.shade700, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Tombol Bantuan WA + Pengaturan Layanan + Switch Siaga
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Tombol Bantuan WA Mitra
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: _openHelpWhatsApp,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.headset_mic_rounded, size: 15, color: Color(0xFF16A34A)),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Tombol Discrete Layanan Aktif Modal Sheet
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _showServiceSettingsSheet(context, orderProv),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.tune_rounded, size: 15, color: GageTheme.primary),
                        const SizedBox(width: 4),
                        Text(
                          '${orderProv.activeServices.length}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Switch Siaga / Offline Beranimasi (Gojek GoPartner Style)
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  orderProv.toggleOnline(!orderProv.isOnline);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                  decoration: BoxDecoration(
                    color: orderProv.isOnline ? const Color(0xFF16A34A) : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      if (orderProv.isOnline)
                        BoxShadow(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (orderProv.isOnline)
                              const BoxShadow(color: Colors.white, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        orderProv.isOnline ? 'ONLINE' : 'OFFLINE',
                        style: TextStyle(
                          color: orderProv.isOnline ? Colors.white : Colors.black87,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom Docked Draggable Dashboard Sheet (Gojek GoPartner 10/10 Standard)
  Widget _buildDraggableDashboard(
    DriverOrderProvider orderProv,
    DriverWalletProvider walletProv,
    ScrollController scrollController,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -4)),
        ],
        border: Border(top: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200)),
      ),
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
        children: [
          // ── Handle Bar ──
          Center(
            child: Container(
              width: 40,
              height: 4.5,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),

          // ── 1. TACTILE AUTOBID CARD (GoPartner Modern Switch) ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: orderProv.isAutoBid
                  ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFECFDF5))
                  : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: orderProv.isAutoBid
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white10 : Colors.grey.shade300),
                width: orderProv.isAutoBid ? 1.4 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: orderProv.isAutoBid ? const Color(0xFF10B981) : Colors.grey.shade400,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Alokasi Otomatis (Autobid)',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'GOPARTNER',
                              style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orderProv.isAutoBid
                            ? 'Order masuk langsung diterima otomatis tanpa perlu sentuh layar.'
                            : 'Terima pesanan secara manual saat ada tawaran masuk.',
                        style: TextStyle(
                          fontSize: 11,
                          color: orderProv.isAutoBid
                              ? (isDark ? Colors.green.shade200 : Colors.green.shade900)
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: orderProv.isAutoBid,
                  activeThumbColor: const Color(0xFF10B981),
                  onChanged: (val) {
                    HapticFeedback.heavyImpact();
                    orderProv.toggleAutoBid(val);
                    GageToast.show(
                      context,
                      val ? 'Autobid Aktif: Order akan diterima otomatis!' : 'Autobid Nonaktif: Terima pesanan manual.',
                      type: val ? GageToastType.success : GageToastType.info,
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 2. STANDALONE DRIVER INFO BANNER (3:1 via Cloudflare D1) ──
          const GageStandaloneBanner(
            screenTarget: 'driver_home_info',
            aspectRatio: 3.0,
            margin: EdgeInsets.only(bottom: 12),
          ),

          // ── 3. RADAR SIAGA STATUS CARD ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(
                  orderProv.isOnline ? Icons.radar_rounded : Icons.pause_circle_outline_rounded,
                  color: orderProv.isOnline ? GageTheme.accentGreen : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        orderProv.isOnline
                            ? 'Radar Siaga Aktif • Mencari Pesanan'
                            : 'Status Driver Offline',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: orderProv.isOnline
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        orderProv.isOnline
                            ? 'GPS & Cloud polling aktif realtime. Standby di Pracimantoro untuk terima trip.'
                            : 'Aktifkan switch Online di pojok kanan atas untuk mulai terima order.',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ── 4. QUICK PORTAL TELEPORT: PENDAPATAN & AKTIVITAS TABS ──
          Row(
            children: [
              // Card Tab Pendapatan
              Expanded(
                child: GageTapScale(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const DriverEarningsScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance_wallet_rounded, size: 15, color: GageTheme.primary),
                            const SizedBox(width: 5),
                            const Text(
                              'Pendapatan',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          currencyFormatter.format(walletProv.todayEarnings),
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: GageTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Saldo: ${currencyFormatter.format(walletProv.balance)}',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Card Tab Aktivitas
              Expanded(
                child: GageTapScale(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (_, _, _) => const DriverActivityScreen(),
                        transitionDuration: Duration.zero,
                        reverseTransitionDuration: Duration.zero,
                      ),
                    );
                  },
                  scaleDown: 0.95,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.receipt_long_rounded, size: 15, color: Color(0xFF1E88E5)),
                            const SizedBox(width: 5),
                            const Text(
                              'Aktivitas',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                            const Spacer(),
                            Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${walletProv.todayTrips} Trip Selesai',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E88E5),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Performa 100%',
                          style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ── 5. HOTSPOTS AREA RAMAI PRACIMANTORO ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 17, color: Colors.deepOrange),
                  SizedBox(width: 6),
                  Text(
                    'Hotspot Ramai Pracimantoro',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Text(
                '${_hotspots.length} Titik',
                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._hotspots.map((spot) {
            final loc = spot['location'] as LatLng;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.place_rounded, color: Colors.deepOrange, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          spot['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                        ),
                        Text(
                          spot['label'] as String,
                          style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange.shade50,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      spot['surge'] as String,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.deepOrange.shade800),
                    ),
                  ),
                  GageTapScale(
                    onTap: () => _recenterMap(loc),
                    scaleDown: 0.90,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.navigation_rounded, color: GageTheme.primary, size: 15),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
