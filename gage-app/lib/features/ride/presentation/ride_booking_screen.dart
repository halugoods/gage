import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class RideBookingScreen extends StatefulWidget {
  final String initialTab; // 'ride' or 'car'

  const RideBookingScreen({
    super.key,
    this.initialTab = 'ride',
  });

  @override
  State<RideBookingScreen> createState() => _RideBookingScreenState();
}

class _RideBookingScreenState extends State<RideBookingScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  late String _selectedTab;
  String _selectedOption = 'standard'; // 'hemat' or 'standard'
  bool _isSearchingDriver = false;
  bool _driverAccepted = false;
  bool _isLoadingRoute = false;

  LatLng _pickupLocation = const LatLng(-8.0895, 110.8492);
  LatLng? _dropoffLocation;
  List<LatLng> _routePoints = [];
  double _distanceKm = 0.0;

  // Realtime Driver Tracking State
  late LatLng _driverLocation;
  double _driverBearing = 45.0; // Derajat rotasi kendaraan
  AnimationController? _driverAnimController;
  Animation<double>? _driverAnimation;
  List<LatLng> _driverPath = [];

  final TextEditingController _pickupController = TextEditingController(
    text: 'Mendeteksi titik GPS Anda...',
  );
  final TextEditingController _dropoffController = TextEditingController(
    text: '',
  );

  String? _savedPaymentMethod;

  int get _realisticTripMins {
    if (_distanceKm <= 0) return 5;
    final perKm = _selectedTab == 'car' ? 4.5 : 3.5;
    return (_distanceKm * perKm).round().clamp(4, 60);
  }

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
    _driverLocation = LatLng(_pickupLocation.latitude - 0.006, _pickupLocation.longitude - 0.004);

    _loadSavedPaymentMethod();
    _initRealGpsAndRoute();
  }

  Future<void> _loadSavedPaymentMethod() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _savedPaymentMethod = prefs.getString('last_ride_payment_method');
      });
    }
  }

  Future<void> _initRealGpsAndRoute() async {
    final realGps = await LocationService.getCurrentLocation();
    if (mounted) {
      setState(() {
        _pickupLocation = realGps;
        _driverLocation = LatLng(realGps.latitude - 0.004, realGps.longitude - 0.003);
      });
      OsmGeocodingService.reverseGeocode(realGps).then((addr) {
        if (mounted) {
          setState(() => _pickupController.text = addr);
        }
      });
    }
    _initRoute();
  }

  Future<void> _recenterToCurrentGps() async {
    GageToast.show(
      context,
      'Mencari posisi GPS Anda saat ini...',
      type: GageToastType.info,
    );
    final realGps = await LocationService.getCurrentLocation();
    if (!mounted) return;
    _mapController.move(realGps, 16.0);
    setState(() {
      _pickupLocation = realGps;
    });
    final addr = await OsmGeocodingService.reverseGeocode(realGps);
    if (!mounted) return;
    setState(() {
      _pickupController.text = addr;
    });
    _initRoute();
  }

  @override
  void dispose() {
    _driverAnimController?.dispose();
    _pickupController.dispose();
    _dropoffController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initRoute() async {
    if (_dropoffLocation == null) {
      setState(() {
        _routePoints = [];
        _distanceKm = 0.0;
        _isLoadingRoute = false;
      });
      return;
    }

    setState(() => _isLoadingRoute = true);

    final res = await OsrmRoutingService.getRoute(_pickupLocation, _dropoffLocation!);
    if (!mounted) return;

    setState(() {
      _routePoints = res.points;
      _distanceKm = res.distanceKm;
      _isLoadingRoute = false;
    });

    // Auto-fit camera to show entire route
    _fitRouteInCamera();
  }

  void _fitRouteInCamera() {
    if (_dropoffLocation == null || _routePoints.isEmpty) {
      _mapController.move(_pickupLocation, 16.0);
      return;
    }

    double minLat = _pickupLocation.latitude;
    double maxLat = _pickupLocation.latitude;
    double minLng = _pickupLocation.longitude;
    double maxLng = _pickupLocation.longitude;

    for (final p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat - 0.003, minLng - 0.003),
      LatLng(maxLat + 0.005, maxLng + 0.003),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 140, bottom: 260, left: 30, right: 30),
      ),
    );
  }

  int _calculateFare() {
    if (_dropoffLocation == null || _distanceKm <= 0) return 0;
    return GagePricingService.calculateCustomerRideFare(
      serviceType: _selectedTab == 'car' ? 'car' : _selectedOption,
      distanceKm: _distanceKm,
    );
  }

  // ignore: unused_element
  void _startOrder() {
    setState(() {
      _isSearchingDriver = true;
      _driverAccepted = false;
    });

    // Simulasi pencarian driver di server
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // Ambil jalur OSRM dari posisi driver ke titik jemput
      final driverToPickupRoute = await OsrmRoutingService.getRoute(
        _driverLocation,
        _pickupLocation,
      );

      if (!mounted) return;

      setState(() {
        _isSearchingDriver = false;
        _driverAccepted = true;
        _driverPath = driverToPickupRoute.points.isNotEmpty
            ? driverToPickupRoute.points
            : [_driverLocation, _pickupLocation];
      });

      _startDriverMovementSimulation();
    });
  }

  void _startDriverMovementSimulation() {
    if (_driverPath.length < 2) return;

    _driverAnimController?.dispose();
    _driverAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );

    _driverAnimation = Tween<double>(begin: 0.0, end: (_driverPath.length - 1).toDouble()).animate(
      CurvedAnimation(parent: _driverAnimController!, curve: Curves.linear),
    )..addListener(() {
        final val = _driverAnimation!.value;
        final index = val.floor();
        final fraction = val - index;

        if (index < _driverPath.length - 1) {
          final p1 = _driverPath[index];
          final p2 = _driverPath[index + 1];

          final lat = p1.latitude + (p2.latitude - p1.latitude) * fraction;
          final lng = p1.longitude + (p2.longitude - p1.longitude) * fraction;

          // Hitung bearing/arah hadap kendaraan (azimuth)
          final dLng = (p2.longitude - p1.longitude) * (math.pi / 180.0);
          final lat1 = p1.latitude * (math.pi / 180.0);
          final lat2 = p2.latitude * (math.pi / 180.0);
          final y = math.sin(dLng) * math.cos(lat2);
          final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
          final bearingRad = math.atan2(y, x);
          final bearingDeg = (bearingRad * 180.0 / math.pi + 360.0) % 360.0;

          setState(() {
            _driverLocation = LatLng(lat, lng);
            _driverBearing = bearingDeg;
          });
        }
      });

    _driverAnimController!.forward();
  }

  void _cancelOrder() {
    _driverAnimController?.stop();
    setState(() {
      _isSearchingDriver = false;
      _driverAccepted = false;
      _driverLocation = LatLng(_pickupLocation.latitude - 0.006, _pickupLocation.longitude - 0.004);
    });
  }

  void _showAddressSearchSheet(bool isPickup) {
    LocationPickerSheet.show(
      context,
      title: isPickup ? 'Pilih Titik Jemput' : 'Pilih Titik Tujuan',
      initialLocation: (isPickup ? _pickupLocation : _dropoffLocation) ?? _pickupLocation,
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          if (isPickup) {
            _pickupLocation = latLng;
            _pickupController.text = title;
          } else {
            _dropoffLocation = latLng;
            _dropoffController.text = title;
          }
        });
        _initRoute();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final fare = _calculateFare();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Tampilan Peta OpenStreetMap Interaktif
            _buildOpenStreetMap(),

            // 2. Floating Header: Back Button, Title & Card Alamat
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                _selectedTab == 'ride'
                                    ? 'assets/images/gage_ride_3d.png'
                                    : 'assets/images/gage_car_3d.png',
                                width: 22,
                                height: 22,
                                fit: BoxFit.contain,
                                errorBuilder: (c, e, s) => Icon(
                                  _selectedTab == 'ride'
                                      ? Icons.two_wheeler_rounded
                                      : Icons.directions_car_rounded,
                                  color: GageTheme.primary,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTab == 'ride' ? 'Pesan GAGE Ride' : 'Pesan GAGE Car',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.textPrimary),
                                ),
                              ),
                              if (_isLoadingRoute)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${_distanceKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.primary),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Card Titik Jemput & Tujuan Interaktif
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Titik Jemput
                        InkWell(
                          onTap: () => _showAddressSearchSheet(true),
                          child: Row(
                            children: [
                              const Icon(Icons.radio_button_checked, color: Color(0xFF16A34A), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _pickupController.text,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.edit_location_alt_rounded, size: 16, color: Colors.black38),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                          child: Row(
                            children: [
                              Container(width: 2, height: 16, color: Colors.grey.shade300),
                            ],
                          ),
                        ),
                        // Titik Tujuan
                        InkWell(
                          onTap: () => _showAddressSearchSheet(false),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFFE52320), size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _dropoffLocation == null ? 'Mau ke mana? Ketuk untuk cari tujuan' : _dropoffController.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _dropoffLocation == null ? FontWeight.normal : FontWeight.w600,
                                    color: _dropoffLocation == null ? Colors.black45 : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const Icon(Icons.edit_location_alt_rounded, size: 16, color: Colors.black38),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3. Floating Map Controls (Fit Route & Recenter)
            Positioned(
              right: 16,
              bottom: _driverAccepted ? 210 : 325,
              child: Column(
                children: [
                  FloatingActionButton.small(
                    heroTag: 'btnFit',
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 3,
                    onPressed: _fitRouteInCamera,
                    child: const Icon(Icons.zoom_out_map_rounded, size: 20),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(
                    heroTag: 'btnRecenter',
                    backgroundColor: Colors.white,
                    foregroundColor: GageTheme.primary,
                    elevation: 3,
                    onPressed: _recenterToCurrentGps,
                    child: const Icon(Icons.my_location_rounded, size: 20),
                  ),
                ],
              ),
            ),

            // 4. Bottom Booking / Driver Panel
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _driverAccepted
                  ? _buildDriverTrackingPanel()
                  : _buildBookingOptionsPanel(wallet, currencyFormatter, fare),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOpenStreetMap() {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _pickupLocation,
        initialZoom: 14.5,
        minZoom: 10.0,
        maxZoom: 21.0,
      ),
      children: [
        // Google Maps Roadmap Tiles Retina HD (scale=2, hl=id, maxZoom=21.0, super tajam tingkat gang/rumah)
        TileLayer(
          urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
          subdomains: const ['0', '1', '2', '3'],
          tileDimension: 256,
          userAgentPackageName: 'com.gage.customer',
          maxZoom: 21.0,
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Garis Rute Jalan Raya (OSRM Real Polyline)
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Shadow rute
              Polyline(
                points: _routePoints,
                strokeWidth: 7.0,
                color: Colors.black.withValues(alpha: 0.15),
              ),
              // Garis rute utama hijau/merah
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: _selectedTab == 'ride' ? GageTheme.primary : const Color(0xFF1E88E5),
              ),
            ],
          ),

        // Marker Titik Jemput, Tujuan & Driver
        MarkerLayer(
          markers: [
            // Marker Titik Jemput (Lingkaran Hijau + Denyut)
            Marker(
              point: _pickupLocation,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFF16A34A),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.person_pin_circle_rounded, color: Colors.white, size: 22),
                  ),
                ],
              ),
            ),

            // Marker Titik Tujuan (Pin Merah)
            if (_dropoffLocation != null)
              Marker(
                point: _dropoffLocation!,
              width: 50,
              height: 50,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE52320),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                      ],
                    ),
                    child: const Icon(Icons.flag_rounded, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),

            // Marker Driver Bergerak (Rotasi mengikuti arah jalan)
            if (_driverAccepted || _isSearchingDriver)
              Marker(
                point: _driverLocation,
                width: 48,
                height: 48,
                child: Transform.rotate(
                  angle: _driverBearing * (math.pi / 180.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 2)),
                      ],
                      border: Border.all(
                        color: _selectedTab == 'ride' ? GageTheme.primary : const Color(0xFF1E88E5),
                        width: 2.5,
                      ),
                    ),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(
                          _selectedTab == 'ride'
                              ? 'assets/images/gage_ride_3d.png'
                              : 'assets/images/gage_car_3d.png',
                          width: 24,
                          height: 24,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildBookingOptionsPanel(WalletProvider wallet, NumberFormat currencyFormatter, int fare) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switcher Tab: GAGE Ride vs GAGE Car
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = 'ride');
                      _initRoute();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'ride' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 'ride'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'GAGE Ride',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 'ride' ? GageTheme.primary : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTab = 'car');
                      _initRoute();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: _selectedTab == 'car' ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: _selectedTab == 'car'
                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          'GAGE Car',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _selectedTab == 'car' ? const Color(0xFF1E88E5) : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pilihan Layanan (Standard vs Hemat)
          if (_selectedTab == 'ride')
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedOption = 'standard'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedOption == 'standard' ? const Color(0xFFFFF1F0) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedOption == 'standard' ? GageTheme.primary : Colors.grey.shade300,
                          width: _selectedOption == 'standard' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/gage_ride_3d.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.two_wheeler_rounded, size: 28, color: GageTheme.primary),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ride Reguler', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormatter.format(GagePricingService.calculateCustomerRideFare(serviceType: 'reguler', distanceKm: _distanceKm)),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: GageTheme.primary),
                                ),
                                Text('${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins}m', style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _selectedOption = 'hemat'),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _selectedOption == 'hemat' ? const Color(0xFFFFF7ED) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedOption == 'hemat' ? const Color(0xFFEA580C) : Colors.grey.shade300,
                          width: _selectedOption == 'hemat' ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/images/gage_ride_3d.png',
                            width: 38,
                            height: 38,
                            fit: BoxFit.contain,
                            errorBuilder: (c, e, s) => const Icon(Icons.two_wheeler_rounded, size: 28, color: Color(0xFFEA580C)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Ride Hemat', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                const SizedBox(height: 2),
                                Text(
                                  currencyFormatter.format(GagePricingService.calculateCustomerRideFare(serviceType: 'hemat', distanceKm: _distanceKm)),
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFFEA580C)),
                                ),
                                Text('${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins + 2}m', style: const TextStyle(fontSize: 9.5, color: Colors.black54)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E88E5)),
              ),
              child: Row(
                children: [
                  Image.asset(
                    'assets/images/gage_car_3d.png',
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                    errorBuilder: (c, e, s) => const Icon(Icons.directions_car_filled_rounded, color: Color(0xFF1E88E5), size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('GAGE Car (1-4 Penumpang)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('Kabin AC • ${_distanceKm.toStringAsFixed(1)} km • Tiba ~${_realisticTripMins}m', style: const TextStyle(fontSize: 11, color: Colors.black54)),
                      ],
                    ),
                  ),
                  Text(
                    currencyFormatter.format(fare),
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF1E88E5)),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 12),

          // Ringkasan Status Metode Pembayaran
          InkWell(
            onTap: () {
              if (_dropoffLocation != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (ctx) => RideCheckoutScreen(
                      serviceType: _selectedTab,
                      rideOption: _selectedOption,
                      pickupLocation: _pickupLocation,
                      dropoffLocation: _dropoffLocation!,
                      pickupAddress: _pickupController.text,
                      dropoffAddress: _dropoffController.text,
                      distanceKm: _distanceKm,
                      baseFare: fare,
                    ),
                  ),
                ).then((_) => _loadSavedPaymentMethod());
              } else {
                _showAddressSearchSheet(false);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    _savedPaymentMethod == 'qris'
                        ? Icons.qr_code_2_rounded
                        : (_savedPaymentMethod == 'gagepay'
                            ? Icons.account_balance_wallet_rounded
                            : (_savedPaymentMethod == 'cash'
                                ? Icons.payments_rounded
                                : Icons.payment_rounded)),
                    color: _savedPaymentMethod == null ? Colors.orange.shade800 : GageTheme.primary,
                    size: 17,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _savedPaymentMethod == 'gagepay'
                          ? 'GAGEPay (${currencyFormatter.format(wallet.balance)})'
                          : (_savedPaymentMethod == 'qris'
                              ? 'QRIS Dinamis GAGE Pay'
                              : (_savedPaymentMethod == 'cash'
                                  ? 'Tunai ke Driver'
                                  : 'Metode Pembayaran: Belum Dipilih')),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: _savedPaymentMethod == null ? Colors.orange.shade900 : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    'Pilih di Checkout →',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Pesan Utama -> Masuk ke Screen Checkout
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearchingDriver
                    ? null
                    : (_dropoffLocation == null
                        ? () => _showAddressSearchSheet(false)
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (ctx) => RideCheckoutScreen(
                                  serviceType: _selectedTab,
                                  rideOption: _selectedOption,
                                  pickupLocation: _pickupLocation,
                                  dropoffLocation: _dropoffLocation!,
                                  pickupAddress: _pickupController.text,
                                  dropoffAddress: _dropoffController.text,
                                  distanceKm: _distanceKm,
                                  baseFare: fare,
                                ),
                              ),
                            ).then((_) => _loadSavedPaymentMethod());
                          }),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                child: _isSearchingDriver
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Mencari driver terdekat...', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : (_dropoffLocation == null
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Pilih Tujuan Perjalanan',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Lanjut ke Checkout',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                '${currencyFormatter.format(fare)} →',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          )),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDriverTrackingPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle bar
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 12),

          // Header Status Driver
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Driver Sedang Menuju ke Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Estimasi tiba dalam ~2-3 menit', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFFFFF3E0), borderRadius: BorderRadius.circular(8)),
                child: const Text('OTW 🛵', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Card Info Driver & Kendaraan
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: GageTheme.primary,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Slamet Widodo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      SizedBox(height: 2),
                      Text('Honda Vario Merah • AD 4518 JK', style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600)),
                      Text('⭐ 4.9 (1.240 pesanan)', style: TextStyle(fontSize: 11, color: Colors.black54)),
                    ],
                  ),
                ),
                // Action Buttons: Chat & Call
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Membuka chat dengan Driver Slamet...'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFFFEBEE), foregroundColor: GageTheme.primary),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Menghubungi Driver Slamet via Telepon...'), duration: Duration(seconds: 1)),
                        );
                      },
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFE3F2FD), foregroundColor: const Color(0xFF1E88E5)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Action: Batalkan Pesanan
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: _cancelOrder,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red.shade700,
                  side: BorderSide(color: Colors.red.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Modal Pencarian Alamat & Lokasi OpenStreetMap Nominatim
// ---------------------------------------------------------------------------
class _AddressSearchModal extends StatefulWidget {
  final bool isPickup;
  final LatLng currentLocation;
  final Function(String title, String fullAddress, LatLng latLng) onSelected;

  const _AddressSearchModal({
    required this.isPickup,
    required this.currentLocation,
    required this.onSelected,
  });

  @override
  State<_AddressSearchModal> createState() => _AddressSearchModalState();
}

class _AddressSearchModalState extends State<_AddressSearchModal> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<OsmPlace> _searchResults = [];
  bool _isSearching = false;
  Timer? _searchDebounce;

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    final clean = val.trim();
    if (clean.length < 2) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _searchDebounce = Timer(const Duration(milliseconds: 350), () async {
      final list = await OsmGeocodingService.searchPlaces(
        clean,
        proximityLocation: widget.currentLocation,
      );
      if (!mounted) return;
      setState(() {
        _searchResults = list;
        _isSearching = false;
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 16,
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.isPickup ? 'Pilih Titik Jemput' : 'Pilih Titik Tujuan',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Search Field
          TextField(
            controller: _searchCtrl,
            onChanged: _onSearchChanged,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Ketik nama jalan, toko, gedung, atau tujuan...',
              hintStyle: const TextStyle(fontSize: 13, color: Colors.black38),
              prefixIcon: const Icon(Icons.search_rounded, color: GageTheme.primary),
              suffixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: GageTheme.primary)),
                    )
                  : (_searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.black45),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchResults = []);
                          },
                        )
                      : null),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),

          // Search Results
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: _searchResults.isNotEmpty
                ? ListView.separated(
                    shrinkWrap: true,
                    itemCount: _searchResults.length,
                    separatorBuilder: (ctx, i) => Divider(height: 1, color: Colors.grey.shade100),
                    itemBuilder: (ctx, i) {
                      final p = _searchResults[i];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFFFEBEE),
                          child: const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 20),
                        ),
                        title: Text(p.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          p.displayName,
                          style: const TextStyle(fontSize: 11.5, color: Colors.black54),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: p.distanceText.isNotEmpty
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEBEE),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  p.distanceText,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              )
                            : null,
                        onTap: () => widget.onSelected(p.title, p.displayName, p.location),
                      );
                    },
                  )
                : (_isSearching
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: GageTheme.primary)),
                              SizedBox(height: 10),
                              Text('Mencari lokasi di sekitar Anda...', style: TextStyle(fontSize: 12.5, color: Colors.black54)),
                            ],
                          ),
                        ),
                      )
                    : (_searchCtrl.text.trim().isNotEmpty
                        ? const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.location_off_rounded, size: 36, color: Colors.black26),
                                  SizedBox(height: 8),
                                  Text('Tempat tidak ditemukan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  SizedBox(height: 4),
                                  Text('Coba gunakan nama jalan atau kata kunci lain', style: TextStyle(fontSize: 11.5, color: Colors.black38)),
                                ],
                              ),
                            ),
                          )
                        : const Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(vertical: 28),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.near_me_rounded, size: 36, color: Colors.black26),
                                  SizedBox(height: 8),
                                  Text('Cari Alamat atau Tujuan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
                                  SizedBox(height: 4),
                                  Text('Pencarian otomatis diprioritaskan di sekitar radius GPS Anda', style: TextStyle(fontSize: 11.5, color: Colors.black38)),
                                ],
                              ),
                            ),
                          ))),
          ),
        ],
      ),
    );
  }
}
