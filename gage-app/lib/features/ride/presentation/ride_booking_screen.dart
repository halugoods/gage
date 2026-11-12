import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/core/services/user_address_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/ride/presentation/ride_checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/core/services/dynamic_asset_service.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

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

  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _dropoffController = TextEditingController();
  bool _hasExplicitPickup = false;
  String? _pickupFavoriteId;
  String? _pickupFavoriteName;
  String? _dropoffFavoriteId;
  String? _dropoffFavoriteName;


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

    _initRealGpsAndRoute();
  }

  Future<void> _initRealGpsAndRoute() async {
    final realGps = await LocationService.getCurrentLocation();
    if (mounted && !_hasExplicitPickup) {
      setState(() {
        _pickupLocation = realGps;
        _driverLocation = LatLng(realGps.latitude - 0.004, realGps.longitude - 0.003);
      });
      // Titik jemput sengaja dibiarkan kosong saat awal buka sesuai instruksi user
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
      _hasExplicitPickup = true;
      _pickupLocation = realGps;
      _pickupFavoriteId = null;
      _pickupFavoriteName = null;
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
    final service = _selectedTab == 'car'
        ? (_selectedOption == 'hemat' ? 'car_hemat' : 'car_reguler')
        : (_selectedOption == 'hemat' ? 'hemat' : 'reguler');
    return GagePricingService.calculateCustomerRideFare(
      serviceType: service,
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
    UserSavedAddress? pickedFavorite;
    LocationPickerSheet.show(
      context,
      title: isPickup ? 'Pilih Titik Jemput' : 'Pilih Titik Tujuan',
      initialLocation: (isPickup ? _pickupLocation : _dropoffLocation) ?? _pickupLocation,
      initialLocationTitle: isPickup ? _pickupFavoriteName : _dropoffFavoriteName,
      selectedFavoriteId: isPickup ? _pickupFavoriteId : _dropoffFavoriteId,
      onFavoriteSelected: (fav) {
        pickedFavorite = fav;
      },
      showMiniMap: false,
      autoFocusSearch: true,
      onSelected: (title, fullAddress, latLng) async {
        final matched = pickedFavorite ??
            await UserAddressService.findMatchingFavorite(
              location: latLng,
              preferredName: title,
            );
        if (!mounted) return;
        setState(() {
          if (isPickup) {
            _hasExplicitPickup = true;
            _pickupLocation = latLng;
            _pickupController.text = title;
            _pickupFavoriteId = matched?.id;
            _pickupFavoriteName = matched?.name;
          } else {
            _dropoffLocation = latLng;
            _dropoffController.text = title;
            _dropoffFavoriteId = matched?.id;
            _dropoffFavoriteName = matched?.name;
          }
        });
        _initRoute();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final fare = _calculateFare();

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
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
                        decoration: BoxDecoration(
                          color: isDark ? GageTheme.darkSurface : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: IconButton(
                          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isDark ? GageTheme.darkSurface : Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            children: [
                              DynamicAssetIcon(
                                slotKey: _selectedTab == 'ride' ? 'vehicle_ride' : 'vehicle_car',
                                defaultAsset: _selectedTab == 'ride'
                                    ? 'assets/images/gage_ride_3d.png'
                                    : 'assets/images/gage_car_3d.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _selectedTab == 'ride' ? 'Pesan GAGE Ride' : 'Pesan GAGE Car',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: isDark ? Colors.white : GageTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (_isLoadingRoute)
                                const GageSkeletonBox(
                                  width: 48,
                                  height: 18,
                                  borderRadius: BorderRadius.all(Radius.circular(999)),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? GageTheme.primary.withValues(alpha: 0.16)
                                        : const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(999),
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
                      color: isDark ? GageTheme.darkSurface : Colors.white,
                      borderRadius: BorderRadius.circular(24),
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
                                  _pickupController.text.trim().isEmpty ? 'Pilih lokasi jemput Anda' : _pickupController.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: _pickupController.text.trim().isEmpty ? FontWeight.normal : FontWeight.w600,
                                    color: _pickupController.text.trim().isEmpty
                                        ? (isDark ? Colors.white38 : Colors.black45)
                                        : (isDark ? Colors.white : GageTheme.textPrimary),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.edit_location_alt_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8),
                          child: Row(
                            children: [
                              Container(width: 2, height: 16, color: isDark ? Colors.white12 : Colors.grey.shade300),
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
                                    color: _dropoffLocation == null ? (isDark ? Colors.white38 : Colors.black45) : (isDark ? Colors.white : Colors.black87),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Icon(Icons.edit_location_alt_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 3 & 4. Bottom Booking / Driver Panel with Floating Map Controls dynamically docked on top
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16, bottom: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FloatingActionButton.small(
                          heroTag: 'btnFit',
                          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          elevation: 3,
                          onPressed: _fitRouteInCamera,
                          child: const Icon(Icons.zoom_out_map_rounded, size: 20),
                        ),
                        const SizedBox(height: 10),
                        FloatingActionButton.small(
                          heroTag: 'btnRecenter',
                          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                          foregroundColor: GageTheme.primary,
                          elevation: 3,
                          onPressed: _recenterToCurrentGps,
                          child: const Icon(Icons.my_location_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),
                  _driverAccepted
                      ? _buildDriverTrackingPanel()
                      : _buildBookingOptionsPanel(wallet, currencyFormatter, fare),
                ],
              ),
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
              // Garis rute utama merah
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: GageTheme.primary,
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
            if (_driverAccepted)
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
                        child: DynamicAssetIcon(
                          slotKey: _selectedTab == 'ride' ? 'vehicle_ride' : 'vehicle_car',
                          defaultAsset: _selectedTab == 'ride'
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Switcher Tab: GAGE Ride vs GAGE Car (Full-Rounded Capsule per AGENTS.md)
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                _buildVehicleTabPill(tabId: 'ride', label: 'GAGE Ride', isDark: isDark),
                _buildVehicleTabPill(tabId: 'car', label: 'GAGE Car', isDark: isDark),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Pilihan Layanan (Standard vs Hemat)
          if (_selectedTab == 'ride')
            Row(
              children: [
                _buildServiceOptionCard(
                  optionId: 'standard',
                  title: 'Ride Reguler',
                  slotKey: 'vehicle_ride',
                  defaultAsset: 'assets/images/gage_ride_3d.png',
                  fareText: currencyFormatter.format(
                    GagePricingService.calculateCustomerRideFare(serviceType: 'reguler', distanceKm: _distanceKm),
                  ),
                  subtitle: '${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins}m',
                  accentColor: GageTheme.primary,
                  selectedLightBg: const Color(0xFFFFF1F0),
                  selectedDarkBg: const Color(0xFF2C1E1E),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildServiceOptionCard(
                  optionId: 'hemat',
                  title: 'Ride Hemat',
                  slotKey: 'vehicle_ride',
                  defaultAsset: 'assets/images/gage_ride_3d.png',
                  fareText: currencyFormatter.format(
                    GagePricingService.calculateCustomerRideFare(serviceType: 'hemat', distanceKm: _distanceKm),
                  ),
                  subtitle: '${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins + 2}m',
                  accentColor: const Color(0xFFEA580C),
                  selectedLightBg: const Color(0xFFFFF7ED),
                  selectedDarkBg: const Color(0xFF2C231E),
                  isDark: isDark,
                ),
              ],
            )
          else
            Row(
              children: [
                _buildServiceOptionCard(
                  optionId: 'standard',
                  title: 'Car Reguler',
                  slotKey: 'vehicle_car',
                  defaultAsset: 'assets/images/gage_car_3d.png',
                  fareText: currencyFormatter.format(
                    GagePricingService.calculateCustomerRideFare(serviceType: 'car_reguler', distanceKm: _distanceKm),
                  ),
                  subtitle: _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins}m' : '0-3 km • AC 1-4 Org',
                  accentColor: const Color(0xFF0284C7),
                  selectedLightBg: const Color(0xFFF0F9FF),
                  selectedDarkBg: const Color(0xFF1E2638),
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildServiceOptionCard(
                  optionId: 'hemat',
                  title: 'Car Hemat',
                  slotKey: 'vehicle_car',
                  defaultAsset: 'assets/images/gage_car_3d.png',
                  fareText: currencyFormatter.format(
                    GagePricingService.calculateCustomerRideFare(serviceType: 'car_hemat', distanceKm: _distanceKm),
                  ),
                  subtitle: _distanceKm > 0 ? '${_distanceKm.toStringAsFixed(1)} km • ~${_realisticTripMins + 2}m' : '0-3 km • Ekonomis',
                  accentColor: const Color(0xFF0D9488),
                  selectedLightBg: const Color(0xFFF0FDFA),
                  selectedDarkBg: const Color(0xFF162E2B),
                  isDark: isDark,
                ),
              ],
            ),

          const SizedBox(height: 14),

          // Tombol Pesan Utama -> Masuk ke Screen Checkout (2-Step Lokasi & Full Rounded)
          SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSearchingDriver
                    ? null
                    : (_pickupController.text.trim().isEmpty
                        ? () => _showAddressSearchSheet(true)
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
                                );
                              })),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
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
                    : (_pickupController.text.trim().isEmpty
                        ? const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Pilih Titik Jemput',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          )
                        : (_dropoffLocation == null
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_rounded, size: 20, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Pilih Titik Antar',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _selectedTab == 'ride' ? 'Pesan GAGE Ride' : 'Pesan GAGE Car',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  Text(
                                    '${currencyFormatter.format(fare)} \u2192',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleTabPill({
    required String tabId,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedTab == tabId;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          if (_selectedTab != tabId) {
            setState(() => _selectedTab = tabId);
            _initRoute();
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServiceOptionCard({
    required String optionId,
    required String title,
    required String slotKey,
    required String defaultAsset,
    required String fareText,
    required String subtitle,
    required Color accentColor,
    required Color selectedLightBg,
    required Color selectedDarkBg,
    required bool isDark,
  }) {
    final isSelected = _selectedOption == optionId;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedOption = optionId);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? selectedDarkBg : selectedLightBg)
                : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? accentColor
                  : (isDark ? Colors.white12 : Colors.grey.shade300),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              DynamicAssetIcon(
                slotKey: slotKey,
                defaultAsset: defaultAsset,
                width: 38,
                height: 38,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (_isLoadingRoute) ...[
                      const SizedBox(height: 4),
                      const GageSkeletonBox(width: 65, height: 14),
                      const SizedBox(height: 4),
                      const GageSkeletonBox(width: 50, height: 10),
                    ] else ...[
                      Text(
                        fareText,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: accentColor,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 9.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _callDriver(String phone) async {
    HapticFeedback.lightImpact();
    final trimmed = phone.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      if (mounted) {
        GageToast.show(context, 'Nomor telepon driver belum tersedia, gunakan fitur Chat.', type: GageToastType.info);
      }
      return;
    }
    final uri = Uri.parse('tel:$trimmed');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    } catch (_) {}
    await Clipboard.setData(ClipboardData(text: trimmed));
    if (mounted) {
      GageToast.show(context, 'Nomor driver disalin: $trimmed', type: GageToastType.info);
    }
  }

  Widget _buildDriverTrackingPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCar = _selectedTab == 'car';
    final useSeed = GageApiClient.useDevSeedData;
    final driverName = useSeed
        ? (isCar ? 'Budi Santoso' : 'Slamet Widodo')
        : 'Mitra Driver GAGE';
    final driverVehicle = useSeed
        ? (isCar ? 'Toyota Avanza Silver • AD 1842 PK' : 'Honda Vario Merah • AD 4518 JK')
        : (isCar ? 'Armada GAGE Car Terdekat' : 'Armada GAGE Ride Terdekat');
    final driverPhone = useSeed ? '081226001000' : '';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: isDark
            ? []
            : const [
                BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, -4)),
              ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(color: Color(0xFFE8F5E9), shape: BoxShape.circle),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Driver Sedang Menuju ke Anda',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Estimasi tiba dalam ~${isCar ? '4-6' : '2-3'} menit',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCar ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                      size: 13,
                      color: const Color(0xFFE65100),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'OTW',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE65100)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: GageTheme.primary,
                  child: Icon(Icons.person_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driverVehicle,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 3),
                          Text(
                            useSeed ? '4.9 (1.240 pesanan)' : 'Mitra Terverifikasi GAGE',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InAppChatScreen(
                              orderId: 'RIDE-LIVE-01',
                              recipientName: driverName,
                              recipientRole: 'driver',
                              recipientPhone: driverPhone,
                              currentRole: 'customer',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? GageTheme.primary.withValues(alpha: 0.2) : const Color(0xFFFFEBEE),
                        foregroundColor: GageTheme.primary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton.filledTonal(
                      onPressed: () => _callDriver(driverPhone),
                      icon: const Icon(Icons.phone_rounded, size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF0284C7).withValues(alpha: 0.2) : const Color(0xFFE3F2FD),
                        foregroundColor: const Color(0xFF1E88E5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
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
