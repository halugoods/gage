import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';

/// Layar Navigasi & Eksekusi Pesanan Aktif Pengemudi (Active Trip Execution)
class ActiveTripScreen extends StatefulWidget {
  final DriverOrderOffer trip;

  const ActiveTripScreen({
    super.key,
    required this.trip,
  });

  @override
  State<ActiveTripScreen> createState() => _ActiveTripScreenState();
}

class _ActiveTripScreenState extends State<ActiveTripScreen> {
  final MapController _mapController = MapController();
  List<LatLng> _routePoints = [];
  double _routeDistanceKm = 0.0;
  int _routeDurationMin = 0;
  bool _isLoadingRoute = true;
  StreamSubscription<Position>? _gpsSub;
  late LatLng _driverLocation;

  @override
  void initState() {
    super.initState();
    _driverLocation = LocationService.cachedOrFallback;
    _initGpsAndRoute();
  }

  Future<void> _initGpsAndRoute() async {
    final cur = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _driverLocation = cur;
      });
      _fetchOsrmRoute();
    }

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen((pos) {
      if (!mounted) return;
      setState(() {
        _driverLocation = LatLng(pos.latitude, pos.longitude);
      });
      context.read<DriverOrderProvider>().updateLocation(_driverLocation);
    });
  }

  Future<void> _fetchOsrmRoute() async {
    final orderProv = context.read<DriverOrderProvider>();
    final target = orderProv.tripStep == 2 ? widget.trip.dropoffLocation : widget.trip.pickupLocation;

    setState(() => _isLoadingRoute = true);
    final res = await OsrmRoutingService.getRoute(_driverLocation, target);
    if (!mounted) return;

    setState(() {
      _routePoints = res.points;
      _routeDistanceKm = res.distanceKm;
      _routeDurationMin = res.durationMinutes;
      _isLoadingRoute = false;
    });

    if (_routePoints.isNotEmpty) {
      _mapController.move(_driverLocation, 15.5);
    }
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  Future<void> _openGoogleMapsNavigation(LatLng dest) async {
    final uri = Uri.parse('google.navigation:q=${dest.latitude},${dest.longitude}&mode=d');
    final fallbackUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final text = Uri.encodeComponent('Halo $name, saya driver GAGE sedang menuju lokasi Anda.');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _handleAdvanceStep() async {
    final orderProv = context.read<DriverOrderProvider>();
    final walletProv = context.read<DriverWalletProvider>();
    final isDone = await orderProv.advanceTripStep();

    if (!mounted) return;

    if (!isDone) {
      _fetchOsrmRoute();
    } else {
      // Tambahkan saldo komisi bersih ke dompet driver
      walletProv.addEarnings(widget.trip.driverEarnings);

      // Tampilkan dialog selamat
      final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 56),
              ),
              const SizedBox(height: 16),
              const Text('Pesanan Selesai!', style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
              const SizedBox(height: 6),
              Text(
                'Komisi bersih ${currency.format(widget.trip.driverEarnings)} telah otomatis masuk ke saldo dompet GAGE Driver Anda.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: GageTheme.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx); // Close dialog
                    Navigator.pop(context); // Back to Driver Screen
                  },
                  child: const Text('Kembali ke Radar Siaga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return '1. Menuju Lokasi Penjemputan';
      case 1:
        return '2. Tiba di Lokasi (Ambil Pesanan)';
      case 2:
        return '3. Mengantar ke Alamat Pembeli';
      default:
        return 'Pesanan Selesai';
    }
  }

  String _getActionButtonLabel(int step) {
    switch (step) {
      case 0:
        return 'Konfirmasi: Tiba di Titik Jemput';
      case 1:
        return 'Konfirmasi: Pesanan Sudah Diterima';
      case 2:
        return 'Selesaikan Pesanan & Terima Ongkir';
      default:
        return 'Selesai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<DriverOrderProvider>();
    final currentStep = orderProv.tripStep;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final targetLocation = currentStep == 2 ? widget.trip.dropoffLocation : widget.trip.pickupLocation;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.serviceName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(
              'ID: ${widget.trip.id}',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Petunjuk Google Maps',
            icon: const Icon(Icons.directions_outlined, color: GageTheme.primary),
            onPressed: () => _openGoogleMapsNavigation(targetLocation),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Peta Rute Navigasi (Interactive FlutterMap)
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: widget.trip.pickupLocation,
                    initialZoom: 15.0,
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
                    // Polyline rute jalan riil OSRM
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints.isNotEmpty
                              ? _routePoints
                              : [
                                  _driverLocation,
                                  currentStep == 2 ? widget.trip.dropoffLocation : widget.trip.pickupLocation,
                                ],
                          strokeWidth: 5.0,
                          color: GageTheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        // Marker GPS Driver Aktual (Bergerak Realtime)
                        Marker(
                          point: _driverLocation,
                          width: 44,
                          height: 44,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GageTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 22),
                          ),
                        ),
                        // Titik Jemput
                        Marker(
                          point: widget.trip.pickupLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.location_on, color: GageTheme.primary, size: 36),
                        ),
                        // Titik Tujuan
                        Marker(
                          point: widget.trip.dropoffLocation,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.flag_circle_rounded, color: GageTheme.accentGreen, size: 36),
                        ),
                      ],
                    ),
                  ],
                ),

                // Floating Step Banner di atas Peta
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: GageTheme.primary,
                          child: Text(
                            '${currentStep + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStepTitle(currentStep),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                _isLoadingRoute
                                    ? (currentStep == 2 ? widget.trip.dropoffAddress : widget.trip.pickupAddress)
                                    : '$_routeDistanceKm km (~$_routeDurationMin mnt) • ${currentStep == 2 ? widget.trip.dropoffAddress : widget.trip.pickupAddress}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.navigation_rounded, color: GageTheme.primary),
                          onPressed: () => _openGoogleMapsNavigation(targetLocation),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Panel Kontrol Navigasi & Info Customer
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 14, offset: Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profil Customer & Tombol Kontak Cepat
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          widget.trip.customerName.isNotEmpty ? widget.trip.customerName[0] : 'C',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.trip.customerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Pemesan • ${widget.trip.distanceKm} km',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : GageTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // Tombol WhatsApp
                      IconButton(
                        tooltip: 'Chat WhatsApp',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.12),
                          foregroundColor: const Color(0xFF25D366),
                        ),
                        icon: const Icon(Icons.chat_bubble_rounded, size: 20),
                        onPressed: () => _openWhatsApp(widget.trip.customerPhone, widget.trip.customerName),
                      ),
                      const SizedBox(width: 6),
                      // Tombol Telepon
                      IconButton(
                        tooltip: 'Telepon Seluler',
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue.withValues(alpha: 0.12),
                          foregroundColor: Colors.blue,
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 20),
                        onPressed: () => _callPhone(widget.trip.customerPhone),
                      ),
                    ],
                  ),

                  const Divider(height: 20),

                  // Status Pembayaran & Tagihan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: widget.trip.paymentMethod == 'CASH' ? Colors.orange.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.trip.paymentMethod == 'CASH'
                              ? 'Tagih Tunai ke Pembeli:'
                              : 'Sudah Bayar via GagePay:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: widget.trip.paymentMethod == 'CASH' ? Colors.orange.shade900 : Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          widget.trip.paymentMethod == 'CASH'
                              ? currency.format(widget.trip.totalFare)
                              : 'LUNAS (Non-Tunai)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: widget.trip.paymentMethod == 'CASH' ? Colors.orange.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Tombol Konfirmasi Aksi Per Step
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStep == 2 ? GageTheme.accentGreen : GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: _handleAdvanceStep,
                      child: Text(
                        _getActionButtonLabel(currentStep),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
                      ),
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
}
