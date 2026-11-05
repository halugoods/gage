import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/features/orders/presentation/order_tracking_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

enum SendBookingStep {
  pickPickup,       // Tahap 1: Fullscreen map dengan center pin untuk menentukan titik penjemputan
  pickDestination,  // Tahap 2: Fullscreen map dengan center pin untuk menentukan titik tujuan pengantaran
  bookingDetails,   // Tahap 3: Rute digambar di peta, card rute 2 lokasi, floating sheet rincian paket
}

class SendBookingScreen extends StatefulWidget {
  const SendBookingScreen({super.key});

  @override
  State<SendBookingScreen> createState() => _SendBookingScreenState();
}

class _SendBookingScreenState extends State<SendBookingScreen> {
  final MapController _mapController = MapController();

  SendBookingStep _step = SendBookingStep.pickPickup;

  final TextEditingController _senderAddressCtrl = TextEditingController(
    text: 'Mendeteksi titik GPS Anda...',
  );
  final TextEditingController _recipientNameCtrl = TextEditingController(
    text: 'Pak Joko (Toko Berkah)',
  );
  final TextEditingController _recipientPhoneCtrl = TextEditingController(
    text: '081398765432',
  );
  final TextEditingController _recipientAddressCtrl = TextEditingController(
    text: 'Komplek Ruko Pasar Baru Pracimantoro No. 12',
  );
  final TextEditingController _packageDescCtrl = TextEditingController(
    text: 'Dokumen berkas & pesanan dagangan',
  );

  LatLng _senderLatLng = const LatLng(-8.0895, 110.8492);
  LatLng? _recipientLatLng;
  List<LatLng> _routePoints = [];
  double _distanceKm = 2.4;
  bool _isLoadingRoute = false;
  bool _isGeocoding = false;
  Timer? _geocodeDebounce;

  String _selectedPackageType = 'Barang Dagangan';
  String _selectedWeight = '1 - 5 kg';
  String _serviceType = 'instant'; // 'instant' (Reguler) or 'sameday' (Hemat)
  String _paymentMethod = 'gagepay'; // 'gagepay', 'qris', 'cash'
  bool _isSearchingCourier = false;

  final List<String> _packageTypes = [
    'Barang Dagangan',
    'Dokumen',
    'Makanan / Minuman',
    'Pakaian & Tekstil',
    'Elektronik',
  ];

  final List<String> _weightOptions = [
    '< 1 kg',
    '1 - 5 kg',
    '5 - 10 kg',
    '10 - 20 kg',
  ];

  @override
  void initState() {
    super.initState();
    _initSenderGps();
  }

  @override
  void dispose() {
    _geocodeDebounce?.cancel();
    _senderAddressCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _recipientAddressCtrl.dispose();
    _packageDescCtrl.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initSenderGps() async {
    try {
      final gps = await LocationService.getCurrentLocation();
      final addr = await OsmGeocodingService.reverseGeocode(gps);
      if (mounted) {
        setState(() {
          _senderLatLng = gps;
          _senderAddressCtrl.text = addr;
        });
        _mapController.move(gps, 16.0);
      }
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    if (_step == SendBookingStep.bookingDetails) return;

    final center = camera.center;
    _geocodeDebounce?.cancel();
    setState(() => _isGeocoding = true);

    _geocodeDebounce = Timer(const Duration(milliseconds: 400), () async {
      final addr = await OsmGeocodingService.reverseGeocode(center);
      if (!mounted) return;
      setState(() {
        _isGeocoding = false;
        if (_step == SendBookingStep.pickPickup) {
          _senderLatLng = center;
          _senderAddressCtrl.text = addr;
        } else if (_step == SendBookingStep.pickDestination) {
          _recipientLatLng = center;
          _recipientAddressCtrl.text = addr;
        }
      });
    });
  }

  Future<void> _reverseGeocodeCenter(LatLng point, bool isPickup) async {
    setState(() => _isGeocoding = true);
    final addr = await OsmGeocodingService.reverseGeocode(point);
    if (!mounted) return;
    setState(() {
      _isGeocoding = false;
      if (isPickup) {
        _senderLatLng = point;
        _senderAddressCtrl.text = addr;
      } else {
        _recipientLatLng = point;
        _recipientAddressCtrl.text = addr;
      }
    });
  }

  Future<void> _updateRoute() async {
    if (_recipientLatLng == null) return;
    setState(() => _isLoadingRoute = true);

    try {
      final res = await OsrmRoutingService.getRoute(_senderLatLng, _recipientLatLng!);
      if (mounted) {
        setState(() {
          _routePoints = res.points;
          _distanceKm = res.distanceKm > 0 ? res.distanceKm : 2.4;
          _isLoadingRoute = false;
        });
        _fitRoute();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingRoute = false);
      }
    }
  }

  void _fitRoute() {
    if (_routePoints.isEmpty || _recipientLatLng == null) {
      _mapController.move(_senderLatLng, 15.0);
      return;
    }
    double minLat = _senderLatLng.latitude;
    double maxLat = _senderLatLng.latitude;
    double minLng = _senderLatLng.longitude;
    double maxLng = _senderLatLng.longitude;

    for (final p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 14.5);
  }

  void _pickSenderAddress() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Titik Jemput (Pengirim)',
      initialLocation: _senderLatLng,
      showMiniMap: false,
      autoFocusSearch: true,
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _senderLatLng = latLng;
          _senderAddressCtrl.text = title.isNotEmpty ? title : fullAddress;
        });
        _mapController.move(latLng, 16.5);
      },
    );
  }

  void _pickRecipientAddress() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Titik Antar (Penerima)',
      initialLocation: _recipientLatLng ?? _senderLatLng,
      showMiniMap: false,
      autoFocusSearch: true,
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _recipientLatLng = latLng;
          _recipientAddressCtrl.text = title.isNotEmpty ? title : fullAddress;
        });
        _mapController.move(latLng, 16.5);
      },
    );
  }

  int _calculateShippingFee([String? service]) {
    final opt = (service ?? _serviceType) == 'instant' ? 'REGULER' : 'HEMAT';
    final dist = _distanceKm > 0 ? _distanceKm : 2.4;
    return GagePricingService.calculateCustomerShippingFee(
      distanceKm: dist,
      deliveryOption: opt,
    );
  }

  int _calculateAdminFee() {
    return GagePricingService.calculateAdminFee(paymentMethod: _paymentMethod);
  }

  int _calculateTotalFare([String? service]) {
    return _calculateShippingFee(service) + _calculateAdminFee();
  }

  void _bookCourier() {
    final shippingFee = _calculateShippingFee();
    final adminFee = _calculateAdminFee();
    final totalFare = _calculateTotalFare();

    if (_paymentMethod == 'gagepay') {
      final wallet = context.read<WalletProvider>();
      if (wallet.balance < totalFare) {
        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        GageToast.show(
          context,
          'Saldo GAGEPay (${currencyFormatter.format(wallet.balance)}) tidak mencukupi total ongkir!',
          type: GageToastType.warning,
        );
        return;
      }
    }

    setState(() => _isSearchingCourier = true);
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() => _isSearchingCourier = false);

      final auth = context.read<AuthProvider>();
      final orderProvider = context.read<OrderProvider>();
      final user = auth.currentUser;
      final userId = user?.id ?? 'usr-cust-01';

      final now = DateTime.now();
      final dateStr = DateFormat('yyyyMMdd').format(now);
      final userSuffix = (user?.name ?? 'USER').toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final shortUser = userSuffix.length >= 4 ? userSuffix.substring(0, 4) : userSuffix.padRight(4, 'X');
      final hashSuffix = now.millisecondsSinceEpoch.toString().substring(8);
      final invoiceNumber = 'INV/GG/$dateStr/SD/$shortUser-$hashSuffix';

      final orderData = {
        'id': 'ord-send-${now.millisecondsSinceEpoch}',
        'order_number': invoiceNumber,
        'user_id': userId,
        'merchant_id': 'mch-gage-send',
        'merchant_name': 'GAGE Send ${_serviceType == "instant" ? "Instant" : "Sameday"}',
        'merchant_address': _senderAddressCtrl.text,
        'driver_name': 'Budi Santoso (Honda Beat AD 6721 WB)',
        'driver_plate': 'AD 6721 WB',
        'driver_phone': '081398765432',
        'status': 'ON_DELIVERY',
        'payment_method': _paymentMethod.toUpperCase(),
        'payment_status': 'PAID',
        'total_amount': totalFare,
        'items_subtotal': shippingFee,
        'shipping_fee': shippingFee,
        'shipping_discount': 0,
        'admin_fee': adminFee,
        'delivery_address': '${_recipientAddressCtrl.text} (${_recipientNameCtrl.text} - ${_recipientPhoneCtrl.text})',
        'distance_km': _distanceKm,
        'tracking_token': 'trk-send-${now.millisecondsSinceEpoch}',
        'items': [
          {
            'id': 'item-send-01',
            'name': 'Kirim $_selectedPackageType ($_selectedWeight)',
            'price': shippingFee,
            'quantity': 1,
            'subtotal': shippingFee,
            'notes': _packageDescCtrl.text.isNotEmpty ? _packageDescCtrl.text : 'Kirim paket aman',
          }
        ],
        'created_at': now.millisecondsSinceEpoch ~/ 1000,
      };

      orderProvider.createOrder(orderData);

      GageToast.show(
        context,
        'Kurir GAGE Send ditemukan! Paket siap dijemput.',
        type: GageToastType.success,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (ctx) => OrderTrackingScreen(
            orderId: orderData['id'] as String,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final shippingFee = _calculateShippingFee();
    final adminFee = _calculateAdminFee();
    final totalFare = _calculateTotalFare();

    final isPickingPin = _step == SendBookingStep.pickPickup || _step == SendBookingStep.pickDestination;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      body: Stack(
        children: [
          // 1. Retina HD Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _senderLatLng,
              initialZoom: 16.0,
              minZoom: 11.0,
              maxZoom: 21.0,
              onPositionChanged: _onPositionChanged,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
                subdomains: const ['0', '1', '2', '3'],
                tileDimension: 256,
                userAgentPackageName: 'com.gage.customer',
                maxZoom: 21.0,
                fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              ),
              if (_step == SendBookingStep.bookingDetails && _routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: GageTheme.primary,
                    ),
                  ],
                ),
              if (_step == SendBookingStep.bookingDetails)
                MarkerLayer(
                  markers: [
                    // Marker Jemput (Green)
                    Marker(
                      point: _senderLatLng,
                      width: 44,
                      height: 44,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: const Icon(Icons.outbox_rounded, color: Colors.white, size: 22),
                      ),
                    ),

                    // Marker Antar (Red)
                    if (_recipientLatLng != null)
                      Marker(
                        point: _recipientLatLng!,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFE52320),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.move_to_inbox_rounded, color: Colors.white, size: 22),
                        ),
                      ),
                  ],
                ),
            ],
          ),

          // 2. Interactive Center Pin (Hanya saat mode Pick Pin Jemput / Antar)
          if (isPickingPin)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 38),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Floating Tooltip Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 2)),
                        ],
                        border: Border.all(
                          color: _step == SendBookingStep.pickPickup
                              ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                              : const Color(0xFFE52320).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _step == SendBookingStep.pickPickup
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE52320),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _step == SendBookingStep.pickPickup
                                ? 'Geser untuk pilih titik jemput'
                                : 'Geser untuk pilih titik tujuan',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Center Pin Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _step == SendBookingStep.pickPickup
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFE52320),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_step == SendBookingStep.pickPickup
                                    ? const Color(0xFF16A34A)
                                    : const Color(0xFFE52320))
                                .withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _step == SendBookingStep.pickPickup
                            ? Icons.outbox_rounded
                            : Icons.move_to_inbox_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    // Ground Shadow Dot
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 8,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black38,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 3. Floating Header & Top Cards
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Bar (Back button + Title Badge)
                Row(
                  children: [
                    InkWell(
                      onTap: () {
                        if (_step == SendBookingStep.bookingDetails) {
                          setState(() => _step = SendBookingStep.pickDestination);
                        } else if (_step == SendBookingStep.pickDestination) {
                          setState(() => _step = SendBookingStep.pickPickup);
                          _mapController.move(_senderLatLng, 16.0);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                          border: Border.all(
                            color: isDark ? Colors.white12 : Colors.grey.shade200,
                          ),
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 20,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              'assets/images/gage_send_3d.png',
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                              errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_rounded, color: GageTheme.primary, size: 16),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _step == SendBookingStep.pickPickup
                                ? 'GAGE Send • Titik Jemput'
                                : (_step == SendBookingStep.pickDestination
                                    ? 'GAGE Send • Titik Antar'
                                    : 'GAGE Send'),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (_step == SendBookingStep.bookingDetails && _recipientLatLng != null) ...[
                            const SizedBox(width: 6),
                            if (_isLoadingRoute)
                              const GageSkeletonBox(width: 48, height: 18)
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${_distanceKm.toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),

                // Large Floating Search Bar pada mode Jemput & Antar
                if (_step == SendBookingStep.pickPickup || _step == SendBookingStep.pickDestination) ...[
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: _step == SendBookingStep.pickPickup ? _pickSenderAddress : _pickRecipientAddress,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 3)),
                        ],
                        border: Border.all(
                          color: _step == SendBookingStep.pickPickup
                              ? const Color(0xFF16A34A).withValues(alpha: 0.3)
                              : const Color(0xFFE52320).withValues(alpha: 0.3),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: (_step == SendBookingStep.pickPickup
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFE52320))
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _step == SendBookingStep.pickPickup
                                  ? Icons.outbox_rounded
                                  : Icons.move_to_inbox_rounded,
                              size: 16,
                              color: _step == SendBookingStep.pickPickup
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFFE52320),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _step == SendBookingStep.pickPickup
                                  ? (_senderAddressCtrl.text.isNotEmpty && _senderAddressCtrl.text != 'Mendeteksi titik GPS Anda...'
                                      ? _senderAddressCtrl.text
                                      : 'Cari jalan, desa, atau tempat jemput...')
                                  : (_recipientAddressCtrl.text.isNotEmpty
                                      ? _recipientAddressCtrl.text
                                      : 'Cari jalan, desa, atau tempat tujuan...'),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.search_rounded, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                                const SizedBox(width: 4),
                                Text(
                                  'Cari',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Top Card Konteks Jemput saat Memilih Tujuan (Tahap 2)
                if (_step == SendBookingStep.pickDestination) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.radio_button_checked, color: Color(0xFF16A34A), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Jemput dari:',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              Text(
                                _senderAddressCtrl.text,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() => _step = SendBookingStep.pickPickup);
                            _mapController.move(_senderLatLng, 16.0);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text('Ubah', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                  ),
                ],

                // Top Card 2 Lokasi Jemput & Antar 1-to-1 Ala Ride/Car (Tahap 3)
                if (_step == SendBookingStep.bookingDetails) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Titik Jemput
                        InkWell(
                          onTap: () {
                            setState(() => _step = SendBookingStep.pickPickup);
                            _mapController.move(_senderLatLng, 16.5);
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.radio_button_checked, color: Color(0xFF16A34A), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Titik Jemput (Pengirim)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(
                                      _senderAddressCtrl.text,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_location_alt_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                        Divider(height: 14, thickness: 0.8, color: isDark ? Colors.white10 : Colors.grey.shade200),
                        // Titik Antar
                        InkWell(
                          onTap: () {
                            setState(() => _step = SendBookingStep.pickDestination);
                            if (_recipientLatLng != null) {
                              _mapController.move(_recipientLatLng!, 16.5);
                            }
                          },
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Color(0xFFE52320), size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Titik Antar (Penerima)', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                    Text(
                                      _recipientAddressCtrl.text,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.edit_location_alt_rounded, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 4. Floating Recenter FAB
          Positioned(
            right: 16,
            bottom: isPickingPin ? 180 : 350,
            child: InkWell(
              onTap: () {
                if (_step == SendBookingStep.pickPickup) {
                  _initSenderGps();
                } else if (_step == SendBookingStep.pickDestination && _recipientLatLng != null) {
                  _mapController.move(_recipientLatLng!, 16.0);
                } else {
                  _fitRoute();
                }
              },
              borderRadius: BorderRadius.circular(22),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                  ],
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                ),
                child: Icon(
                  Icons.my_location_rounded,
                  color: isDark ? Colors.white : GageTheme.primary,
                  size: 22,
                ),
              ),
            ),
          ),

          // 5. Floating Bottom Sheet Sesuai Step
          if (_step == SendBookingStep.bookingDetails) ...[
            DraggableScrollableSheet(
              initialChildSize: 0.44,
              minChildSize: 0.28,
              maxChildSize: 0.85,
              builder: (context, scrollController) {
                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -2)),
                    ],
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                    ),
                  ),
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    children: [
                      // Grabber Pill
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Inset Group 1: Detail Penerima & Paket Modern
                      _buildSectionHeader('INFORMASI PENERIMA & BARANG', isDark),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.white10 : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: _recipientNameCtrl,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                      decoration: const InputDecoration(
                                        icon: Icon(Icons.person_outline_rounded, size: 18, color: Colors.grey),
                                        hintText: 'Nama Penerima',
                                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                                    ),
                                    child: TextField(
                                      controller: _recipientPhoneCtrl,
                                      keyboardType: TextInputType.phone,
                                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                                      decoration: const InputDecoration(
                                        icon: Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                                        hintText: 'No. WhatsApp',
                                        hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey),
                                        border: InputBorder.none,
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(vertical: 8),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('Kategori Paket', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: _packageTypes.map((type) {
                                  final isSelected = _selectedPackageType == type;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: ChoiceChip(
                                      label: Text(type),
                                      selected: isSelected,
                                      onSelected: (_) => setState(() => _selectedPackageType = type),
                                      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                                      labelStyle: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        side: BorderSide(
                                          color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text('Estimasi Berat', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 6),
                            Row(
                              children: _weightOptions.map((w) {
                                final isSelected = _selectedWeight == w;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 3),
                                    child: InkWell(
                                      onTap: () => setState(() => _selectedWeight = w),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(vertical: 7),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? GageTheme.primary.withValues(alpha: 0.12)
                                              : (isDark ? const Color(0xFF0F172A) : Colors.white),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            w,
                                            style: TextStyle(
                                              fontSize: 10.5,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade300),
                              ),
                              child: TextField(
                                controller: _packageDescCtrl,
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
                                decoration: const InputDecoration(
                                  icon: Icon(Icons.notes_rounded, size: 18, color: Colors.grey),
                                  hintText: 'Deskripsi barang / instruksi kurir...',
                                  hintStyle: TextStyle(fontSize: 11.5, color: Colors.grey),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Inset Group 2: Pilihan Layanan (Instant vs Sameday)
                      _buildSectionHeader('PILIHAN LAYANAN', isDark),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _serviceType = 'instant'),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _serviceType == 'instant'
                                      ? GageTheme.primary.withValues(alpha: 0.08)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _serviceType == 'instant'
                                        ? GageTheme.primary
                                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                                    width: _serviceType == 'instant' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.flash_on_rounded, size: 16, color: Colors.orange),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Instant',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Langsung antar (1-2 jam)', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    if (_isLoadingRoute)
                                      const GageSkeletonBox(width: 60, height: 16)
                                    else
                                      Text(
                                        currencyFormatter.format(_calculateShippingFee('instant')),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: GageTheme.primary),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () => setState(() => _serviceType = 'sameday'),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _serviceType == 'sameday'
                                      ? GageTheme.primary.withValues(alpha: 0.08)
                                      : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: _serviceType == 'sameday'
                                        ? GageTheme.primary
                                        : (isDark ? Colors.white10 : Colors.grey.shade200),
                                    width: _serviceType == 'sameday' ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.schedule_rounded, size: 16, color: Colors.blue),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Sameday',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    const Text('Tiba hari ini (4-6 jam)', style: TextStyle(fontSize: 10.5, color: Colors.grey)),
                                    const SizedBox(height: 6),
                                    if (_isLoadingRoute)
                                      const GageSkeletonBox(width: 60, height: 16)
                                    else
                                      Text(
                                        currencyFormatter.format(_calculateShippingFee('sameday')),
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF16A34A)),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),
                      const SizedBox(height: 14),

                      // Rincian Pembayaran
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Ongkir Pengiriman (${_serviceType == "instant" ? "Instant" : "Sameday"} ${_distanceKm.toStringAsFixed(1)} km)', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                                Text(currencyFormatter.format(shippingFee), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Biaya Layanan ${_paymentMethod == "cash" ? "(COD)" : "(Cashless)"}', style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade700)),
                                Text(currencyFormatter.format(adminFee), style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                            Divider(height: 12, thickness: 0.8, color: isDark ? Colors.white10 : Colors.grey.shade300),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Pembayaran', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                                Text(currencyFormatter.format(totalFare), style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: GageTheme.primary)),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // Tombol Aksi: Panggil Kurir GAGE (10px Rounded)
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isSearchingCourier ? null : _bookCourier,
                          child: _isSearchingCourier
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset(
                                      'assets/images/gage_send_3d.png',
                                      width: 22,
                                      height: 22,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const Icon(Icons.inventory_2_rounded, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Panggil Kurir GAGE • ${currencyFormatter.format(totalFare)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ] else if (_step == SendBookingStep.pickPickup) ...[
            // Sheet Bawah: Konfirmasi Titik Jemput
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.outbox_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Titik Penjemputan Paket',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (_isGeocoding)
                                const GageSkeletonBox(width: 180, height: 16)
                              else
                                Text(
                                  _senderAddressCtrl.text.isEmpty ? 'Mendeteksi lokasi jemput...' : _senderAddressCtrl.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickSenderAddress,
                          icon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF16A34A)),
                          label: const Text('Cari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _step = SendBookingStep.pickDestination;
                            _recipientLatLng ??= LatLng(_senderLatLng.latitude - 0.006, _senderLatLng.longitude + 0.004);
                          });
                          _mapController.move(_recipientLatLng!, 16.0);
                          _reverseGeocodeCenter(_recipientLatLng!, false);
                        },
                        icon: const Icon(Icons.near_me_rounded, size: 18),
                        label: const Text(
                          'Pilih Lokasi Tujuan',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else if (_step == SendBookingStep.pickDestination) ...[
            // Sheet Bawah: Konfirmasi Titik Tujuan
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: const [
                    BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE52320).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.move_to_inbox_rounded, color: Color(0xFFE52320), size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Titik Tujuan Pengantaran',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.grey.shade400 : Colors.black54,
                                ),
                              ),
                              const SizedBox(height: 2),
                              if (_isGeocoding)
                                const GageSkeletonBox(width: 180, height: 16)
                              else
                                Text(
                                  _recipientAddressCtrl.text.isEmpty ? 'Mendeteksi lokasi tujuan...' : _recipientAddressCtrl.text,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickRecipientAddress,
                          icon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFFE52320)),
                          label: const Text('Cari', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFFE52320))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          setState(() {
                            _step = SendBookingStep.bookingDetails;
                          });
                          _updateRoute();
                        },
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          'Konfirmasi & Atur Paket',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
    );
  }
}
