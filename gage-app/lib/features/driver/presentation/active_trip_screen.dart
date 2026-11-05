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
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/providers/driver_order_provider.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';

/// Layar Perjalanan Aktif Pengemudi (Active Trip Screen)
/// Dirancang dengan arsitektur 3 Tahap Eksekusi Ergonomis:
/// - Tahap 1: Menuju Toko -> Tombol "Tiba di Toko"
/// - Tahap 2: Menunggu Makanan / Verifikasi Barang -> Tombol "Mulai Antar ke Pembeli"
/// - Tahap 3: Menuju Pembeli -> Tombol "Pesanan Selesai / Konfirmasi Terima Tunai (COD)"
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

  /// Mengambil rute OSRM riil sesuai tahap aktif
  Future<void> _fetchOsrmRoute() async {
    final orderProv = context.read<DriverOrderProvider>();
    final target = orderProv.tripStep == 2
        ? widget.trip.dropoffLocation
        : widget.trip.pickupLocation;

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
    HapticFeedback.lightImpact();
    final uri = Uri.parse('google.navigation:q=${dest.latitude},${dest.longitude}&mode=d');
    final fallbackUri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${dest.latitude},${dest.longitude}');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (await canLaunchUrl(fallbackUri)) {
      await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openWhatsApp(String phone, String name) async {
    HapticFeedback.lightImpact();
    var cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (cleanPhone.startsWith('0')) {
      cleanPhone = '62${cleanPhone.substring(1)}';
    }
    final text = Uri.encodeComponent('Halo $name, saya kurir GAGE sedang memproses pesanan Anda.');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=$text');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    HapticFeedback.lightImpact();
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Memajukan Tahap Perjalanan dengan Rekonsiliasi Plafon COD & Upah Bersih
  void _handleAdvanceStep() async {
    HapticFeedback.heavyImpact();
    final orderProv = context.read<DriverOrderProvider>();
    final walletProv = context.read<DriverWalletProvider>();

    final isDone = await orderProv.advanceTripStep();
    if (!mounted) return;

    if (!isDone) {
      // Masih berlanjut ke tahap berikutnya, segarkan rute OSRM
      _fetchOsrmRoute();
    } else {
      // Tahap 3 Selesai -> Rekonsiliasi dompet & plafon COD
      walletProv.recordTripCompletion(
        tripId: widget.trip.id,
        serviceName: widget.trip.serviceName,
        serviceType: widget.trip.serviceType,
        storeName: widget.trip.storeName,
        pickupAddress: widget.trip.pickupAddress,
        dropoffAddress: widget.trip.dropoffAddress,
        distanceKm: widget.trip.distanceKm,
        driverEarnings: widget.trip.driverEarnings,
        totalDeliveryFare: widget.trip.totalFare,
        paymentMethod: widget.trip.paymentMethod,
      );

      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isCash = widget.trip.isCashCod;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(22),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: GageTheme.accentGreen.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 60),
            ),
            const SizedBox(height: 18),
            const Text(
              'Pesanan Selesai!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),

            // Rincian Keuangan Bersih
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Upah Bersih Driver (80%):',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.accentGreen),
                      ),
                      Text(
                        currency.format(widget.trip.driverEarnings),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.accentGreen),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (isCash) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tunai COD Diterima:',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        Text(
                          currency.format(widget.trip.totalFare),
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Bagi Hasil Platform (20%):',
                          style: TextStyle(fontSize: 11, color: Colors.red),
                        ),
                        Text(
                          '-${currency.format(widget.trip.platformFee)}',
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Plafon COD Fleksibel: Sisa komisi otomatis terpotong dari saldo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Metode Pembayaran:',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                        const Text(
                          'Non-Tunai (GagePay)',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2563EB)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Upah bersih langsung masuk ke saldo dompet Anda.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              height: 52, // Tombol besar mudah di-tap
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.pop(context); // Kembali ke root workstation kurir
                },
                child: const Text(
                  'KEMBALI KE RADAR SIAGA',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Judul Tahap Perjalanan Aktif
  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Tahap 1: Menuju Toko';
      case 1:
        return 'Tahap 2: Menunggu Makanan / Verifikasi Barang';
      case 2:
        return 'Tahap 3: Menuju Pembeli';
      default:
        return 'Pesanan Selesai';
    }
  }

  /// Label Tombol Aksi Utama Sesuai Spesifikasi Instruksi
  String _getActionButtonLabel(int step, bool isCash) {
    switch (step) {
      case 0:
        return 'Tiba di Toko';
      case 1:
        return 'Mulai Antar ke Pembeli';
      case 2:
        return isCash
            ? 'Pesanan Selesai / Konfirmasi Terima Tunai (COD)'
            : 'Pesanan Selesai';
      default:
        return 'Pesanan Selesai';
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderProv = context.watch<DriverOrderProvider>();
    final currentStep = orderProv.tripStep;
    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCash = widget.trip.isCashCod;

    final targetLocation = currentStep == 2
        ? widget.trip.dropoffLocation
        : widget.trip.pickupLocation;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.trip.serviceName, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            Text(
              'Toko: ${widget.trip.storeName}',
              style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Petunjuk Google Maps',
            icon: const Icon(Icons.directions_outlined, color: GageTheme.primary, size: 26),
            onPressed: () => _openGoogleMapsNavigation(targetLocation),
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. PETA NAVIGASI RUTE OSRM RIIL
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

                    // Polylines Rute OSRM Riil Jalan Raya
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: _routePoints.isNotEmpty
                              ? _routePoints
                              : [
                                  _driverLocation,
                                  currentStep == 2
                                      ? widget.trip.dropoffLocation
                                      : widget.trip.pickupLocation,
                                ],
                          strokeWidth: 5.5,
                          color: GageTheme.primary,
                        ),
                      ],
                    ),

                    // Marker Lapisan Peta
                    MarkerLayer(
                      markers: [
                        // Marker GPS Driver Aktual (Bergerak Realtime)
                        Marker(
                          point: _driverLocation,
                          width: 46,
                          height: 46,
                          child: Container(
                            decoration: BoxDecoration(
                              color: GageTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8)],
                            ),
                            child: const Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 24),
                          ),
                        ),
                        // Marker Toko / Titik Jemput
                        Marker(
                          point: widget.trip.pickupLocation,
                          width: 42,
                          height: 42,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFFEA580C), width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.storefront_rounded, color: Color(0xFFEA580C), size: 20),
                          ),
                        ),
                        // Marker Pembeli / Titik Antar
                        Marker(
                          point: widget.trip.dropoffLocation,
                          width: 42,
                          height: 42,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: GageTheme.accentGreen, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
                            ),
                            child: const Icon(Icons.flag_rounded, color: GageTheme.accentGreen, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Step Banner Melayang di Atas Peta
                Positioned(
                  top: 12,
                  left: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                      ],
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: GageTheme.primary,
                          child: Text(
                            '${currentStep + 1}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getStepTitle(currentStep),
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                              ),
                              Text(
                                _isLoadingRoute
                                    ? (currentStep == 2 ? widget.trip.dropoffAddress : widget.trip.storeName)
                                    : '$_routeDistanceKm km (~$_routeDurationMin mnt) • ${currentStep == 2 ? widget.trip.dropoffAddress : widget.trip.storeName}',
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
                        IconButton(
                          tooltip: 'Navigasi Peta',
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

          // 2. PANEL KONTROL TAHAP & EKSEKUSI JEMPOL DRIVER
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Profil Pelanggan & Kontak WhatsApp/Telp
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: GageTheme.primary.withValues(alpha: 0.12),
                        child: Text(
                          widget.trip.customerName.isNotEmpty ? widget.trip.customerName[0] : 'P',
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
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Pelanggan GAGE • ${widget.trip.distanceKm.toStringAsFixed(1)} KM',
                              style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : GageTheme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      // Tombol WhatsApp
                      IconButton(
                        tooltip: 'Chat WhatsApp',
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366).withValues(alpha: 0.14),
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
                          backgroundColor: Colors.blue.withValues(alpha: 0.14),
                          foregroundColor: Colors.blue,
                        ),
                        icon: const Icon(Icons.phone_rounded, size: 20),
                        onPressed: () => _callPhone(widget.trip.customerPhone),
                      ),
                    ],
                  ),

                  // Detail Barang di Tahap 2 (Verifikasi Barang)
                  if (currentStep == 1) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory_2_rounded, size: 14, color: Colors.amber.shade900),
                              const SizedBox(width: 6),
                              Text(
                                'Daftar Barang Pesanan (${widget.trip.storeName}):',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.amber.shade900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.trip.orderItems.isNotEmpty
                                ? widget.trip.orderItems.join('\n')
                                : 'Pesanan reguler sesuai struk resto.',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.brown.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const Divider(height: 18),

                  // Status Pembayaran & Tagihan
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isCash ? Colors.orange.shade50 : Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isCash
                              ? 'Tagih Tunai ke Pembeli:'
                              : 'Status Pembayaran:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isCash ? Colors.orange.shade900 : Colors.blue.shade900,
                          ),
                        ),
                        Text(
                          isCash
                              ? currency.format(widget.trip.totalFare)
                              : 'LUNAS (GagePay)',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: isCash ? Colors.orange.shade900 : Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // TOMBOL AKSI UTAMA BESAR (TACTILE ZERO-SLOP JEMPOL MOTOR)
                  SizedBox(
                    height: 56, // Tombol besar 56px ergonomis jempol motor
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: currentStep == 2
                            ? (isCash ? const Color(0xFFEA580C) : GageTheme.accentGreen)
                            : GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _handleAdvanceStep,
                      child: Text(
                        _getActionButtonLabel(currentStep, isCash),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 0.3,
                        ),
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
