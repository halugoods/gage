// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/services/location_service.dart';

/// Layar Pelacakan Pesanan Realtime (Live Order Tracking & Delivery Lifecycle)
/// Didesain dengan standar industri terdepan (Clean-Room Flutter Code & $0 Infra)
class OrderTrackingScreen extends StatefulWidget {
  final String orderId;
  final OrderModel? initialOrder;

  const OrderTrackingScreen({
    super.key,
    required this.orderId,
    this.initialOrder,
  });

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen>
    with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  final NumberFormat _currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // Koordinat Rute Pengantaran (Pracimantoro, Wonogiri)
  LatLng _storeLocation = const LatLng(-8.05580, 110.80950); // Pasar Pracimantoro / Dimsum Sewu
  LatLng _customerLocation = const LatLng(-8.05120, 110.80620); // Titik Antar / Rumah Pemesan
  LatLng _driverLocation = const LatLng(-8.05450, 110.80820); // Posisi Driver

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  double _routeDistanceKm = 1.8;
  int _estimatedMinutes = 12;

  // Driver Realtime Movement & OSRM Road Snapping
  late AnimationController _driverPulseAnim;
  Timer? _driverMovementTimer;
  int _manualStep = 0; // 0 = auto dari status API, 1..5 = override testing
  int _currentRouteIndex = 0;
  double _driverBearing = 0.0;
  String? _manualVehicleType; // null = auto detect, 'MOTOR', 'CAR'
  bool _isStepperExpanded = false; // Accordion Expand Card State

  @override
  void initState() {
    super.initState();
    _driverPulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.orderId.isNotEmpty && !widget.orderId.startsWith('#SAMPLE')) {
        context.read<OrderProvider>().startTrackingOrder(widget.orderId);
      }
      _initCoordinatesAndRoute();
    });
  }

  @override
  void dispose() {
    _driverPulseAnim.dispose();
    _driverMovementTimer?.cancel();
    context.read<OrderProvider>().stopTracking();
    super.dispose();
  }

  /// Inisialisasi Koordinat Toko, Tujuan, Driver & OSRM Realtime Polyline
  Future<void> _initCoordinatesAndRoute() async {
    setState(() => _isLoadingRoute = true);
    try {
      final realUserGps = await LocationService.getCurrentLocation();
      if (mounted) {
        setState(() {
          _customerLocation = realUserGps;
          // Toko default: Pusat kuliner / Pasar Pracimantoro
          _storeLocation = const LatLng(-8.05580, 110.80950);
          // Driver ditempatkan antara toko dan pemesan
          _driverLocation = LatLng(
            (_storeLocation.latitude + _customerLocation.latitude) / 2 + 0.001,
            (_storeLocation.longitude + _customerLocation.longitude) / 2 - 0.001,
          );
        });
      }
    } catch (_) {
      // Fallback ke titik default Pracimantoro jika GPS offline
      _storeLocation = const LatLng(-8.05580, 110.80950);
      _customerLocation = const LatLng(-8.05120, 110.80620);
      _driverLocation = const LatLng(-8.05450, 110.80820);
    }

    // Ambil rute jalan raya OSRM presisi
    try {
      final routeRes = await OsrmRoutingService.getRoute(_storeLocation, _customerLocation);
      if (mounted) {
        setState(() {
          _routePoints = routeRes.points;
          _routeDistanceKm = routeRes.distanceKm > 0.1 ? routeRes.distanceKm : 1.8;
          _estimatedMinutes = routeRes.durationMinutes > 0 ? routeRes.durationMinutes : 12;
          _isLoadingRoute = false;
        });
        _fitRouteInCamera();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _routePoints = [
            _storeLocation,
            _driverLocation,
            _customerLocation,
          ];
          _isLoadingRoute = false;
        });
        _fitRouteInCamera();
      }
    }

    _startDriverRouteMovement();
  }

  /// Menyesuaikan kamera peta agar seluruh rute terlihat jelas di layar
  void _fitRouteInCamera() {
    if (_routePoints.isEmpty) {
      _mapController.move(_driverLocation, 15.5);
      return;
    }

    double minLat = _driverLocation.latitude;
    double maxLat = _driverLocation.latitude;
    double minLng = _driverLocation.longitude;
    double maxLng = _driverLocation.longitude;

    for (final p in _routePoints) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final bounds = LatLngBounds(
      LatLng(minLat - 0.002, minLng - 0.002),
      LatLng(maxLat + 0.002, maxLng + 0.002),
    );

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.only(top: 130, bottom: 260, left: 24, right: 24),
      ),
    );
  }

  /// Menghitung sudut rotasi hadap jalan (bearing derajat 0-360) menggunakan formula atan2
  /// sehingga kendaraan selalu menghadap lurus ke arah jalan raya OSRM
  double _calculateBearing(LatLng start, LatLng end) {
    final startLat = start.latitude * (math.pi / 180.0);
    final startLng = start.longitude * (math.pi / 180.0);
    final endLat = end.latitude * (math.pi / 180.0);
    final endLng = end.longitude * (math.pi / 180.0);

    final dLng = endLng - startLng;
    final y = math.sin(dLng) * math.cos(endLat);
    final x = math.cos(startLat) * math.sin(endLat) -
        math.sin(startLat) * math.cos(endLat) * math.cos(dLng);

    final initialBearing = math.atan2(y, x);
    final bearingInDegrees = (initialBearing * (180.0 / math.pi) + 360.0) % 360.0;
    return bearingInDegrees;
  }

  /// Gerakan marker driver menelusuri array titik jalan raya OSRM _routePoints secara berurutan
  /// Snapping 100% pada jalan raya, menghitung sudut rotasi hadap jalan (bearing) secara dinamis
  void _startDriverRouteMovement() {
    _driverMovementTimer?.cancel();
    if (_routePoints.length < 2) return;

    if (_currentRouteIndex >= _routePoints.length - 1) {
      _currentRouteIndex = 0;
    }

    _driverLocation = _routePoints[_currentRouteIndex];
    _driverBearing = _calculateBearing(
      _routePoints[_currentRouteIndex],
      _routePoints[_currentRouteIndex + 1],
    );

    _driverMovementTimer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
      if (!mounted || _routePoints.length < 2) return;

      setState(() {
        _currentRouteIndex++;
        if (_currentRouteIndex >= _routePoints.length - 1) {
          _currentRouteIndex = 0; // Loop kembali ke awal rute agar pergerakan terus aktif di layar
        }

        final currentPt = _routePoints[_currentRouteIndex];
        final nextPt = _routePoints[_currentRouteIndex + 1];

        _driverLocation = currentPt;
        _driverBearing = _calculateBearing(currentPt, nextPt);
      });
    });
  }

  /// Deteksi tipe kendaraan: Mobil (GageCar) vs Sepeda Motor (GageRide/Food/Send)
  bool _isCarVehicle(OrderModel order) {
    if (_manualVehicleType != null) {
      return _manualVehicleType == 'CAR';
    }
    final plate = (order.driverPlate ?? '').toLowerCase();
    final name = (order.driverName ?? '').toLowerCase();
    final orderNum = order.orderNumber.toLowerCase();
    return plate.contains('mobil') ||
        plate.contains('car') ||
        plate.contains('avanza') ||
        plate.contains('brio') ||
        name.contains('mobil') ||
        name.contains('car') ||
        orderNum.contains('car');
  }

  /// Menentukan tahap lifecycle pesanan (1 sampai 5)
  int _determineLifecycleStage(OrderModel order) {
    if (_manualStep > 0) return _manualStep;

    switch (order.status) {
      case 'PAYMENT_PENDING':
      case 'SEARCHING_DRIVER':
        return 1;
      case 'PAID':
      case 'DRIVER_ASSIGNED':
      case 'HEADING_TO_STORE':
        return 2;
      case 'COOKING':
      case 'READY_FOR_PICKUP':
      case 'AT_STORE':
        return 3;
      case 'ON_DELIVERY':
        return 4;
      case 'COMPLETED':
        return 5;
      default:
        return 4;
    }
  }

  /// Launch WhatsApp Driver / Merchant
  Future<void> _launchWhatsApp(String phone, String name, String orderNumber) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final waPhone = cleanPhone.startsWith('0') ? '62${cleanPhone.substring(1)}' : cleanPhone;
    final message = Uri.encodeComponent(
      'Halo $name, saya pemesan GAGE untuk order $orderNumber. Mau konfirmasi pesanan saya.',
    );
    final url = 'https://wa.me/$waPhone?text=$message';

    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: phone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nomor WA disalin: $phone')),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor WA disalin: $phone')),
        );
      }
    }
  }

  /// Launch Direct Phone Call
  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: phone));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nomor telepon disalin: $phone')),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor telepon disalin: $phone')),
        );
      }
    }
  }

  /// Buat fallback sample order jika order tidak ditemukan di cloud/D1 saat testing
  OrderModel _createFallbackOrder() {
    return OrderModel(
      id: widget.orderId.isEmpty ? 'ord-gage-8821' : widget.orderId,
      orderNumber: widget.orderId.startsWith('#')
          ? widget.orderId
          : (widget.orderId.isNotEmpty ? '#${widget.orderId}' : '#GAGE-8821'),
      userId: 'usr-cust-01',
      merchantId: 'mch-dimsum-01',
      merchantName: 'Dimsum Sewu by Halu Goods',
      merchantAddress: 'Kompleks Ruko Pasar Pracimantoro No. 8',
      merchantPhone: '081234567890',
      driverName: 'Mas Agus Pratama • Driver GAGE',
      driverPlate: 'AD 3142 WN • Honda Vario 125',
      driverPhone: '081234567892',
      status: 'ON_DELIVERY',
      paymentMethod: 'GAGEPAY',
      paymentStatus: 'PAID',
      totalAmount: 38000,
      itemsSubtotal: 32000,
      shippingFee: 5000,
      shippingDiscount: 0,
      adminFee: 1000,
      deliveryAddress: 'Jl. Raya Pracimantoro - Bedoyo, Dusun Sambiroto RT 02 / RW 01',
      distanceKm: 2.1,
      trackingToken: 'TRK-GAGE-8821',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      items: const [
        OrderItemModel(
          id: 'item-1',
          name: 'Dimsum Ayam Mix Jamur & Udang (Isi 6)',
          price: 18000,
          quantity: 1,
          subtotal: 18000,
          notes: 'Kukus hangat, saus sambal ekstra pedas',
        ),
        OrderItemModel(
          id: 'item-2',
          name: 'Dimsum Mozzarella Lumer (Isi 4)',
          price: 14000,
          quantity: 1,
          subtotal: 14000,
          notes: 'Keju lumer meleleh',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final order = orderProvider.currentTrackedOrder ??
        widget.initialOrder ??
        _createFallbackOrder();

    final currentStage = _determineLifecycleStage(order);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: _buildAppBar(order, currentStage),
      body: Stack(
        children: [
          // 1. PETA LAYAR PENUH (FULL-BLEED MAP)
          Positioned.fill(
            child: _buildFullBleedMap(order, currentStage),
          ),

          if (_isLoadingRoute)
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                minHeight: 2.5,
                backgroundColor: Colors.transparent,
                color: GageTheme.primary,
              ),
            ),

          // 2. TOMBOL KONTROL PETA (ZOOM OUT RUTE & RECENTER) MELAYANG DI ATAS PETA
          Positioned(
            right: 16,
            bottom: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'track_fit_route',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 3,
                  onPressed: _fitRouteInCamera,
                  child: const Icon(Icons.zoom_out_map_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'track_recenter',
                  backgroundColor: Colors.white,
                  foregroundColor: GageTheme.primary,
                  elevation: 3,
                  onPressed: () {
                    _mapController.move(_driverLocation, 16.0);
                  },
                  child: const Icon(Icons.my_location_rounded, size: 20),
                ),
              ],
            ),
          ),

          // 3. ACCORDION EXPAND CARD STEPPER TAHAPAN PENGIRIMAN MELAYANG DI ATAS PETA
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _buildAccordionStepperCard(order, currentStage),
          ),

          // 4. BOTTOM SHEET DRAGGABLE: DRIVER CARD, RINCIAN ORDER, POD & KONTROL TAHAP
          _buildDraggableBottomPanel(order, currentStage),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. APPBAR DENGAN STATUS BADGE
  // ──────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(OrderModel order, int stage) {
    String stageBadgeText;
    Color stageBadgeBg;
    Color stageBadgeTextCol;

    switch (stage) {
      case 1:
        stageBadgeText = 'Mencari Driver';
        stageBadgeBg = const Color(0xFFFEF3C7);
        stageBadgeTextCol = const Color(0xFFB45309);
        break;
      case 2:
        stageBadgeText = 'Driver Menuju Lokasi';
        stageBadgeBg = const Color(0xFFDBEAFE);
        stageBadgeTextCol = const Color(0xFF1D4ED8);
        break;
      case 3:
        stageBadgeText = 'Sedang Disiapkan';
        stageBadgeBg = const Color(0xFFFFEDD5);
        stageBadgeTextCol = const Color(0xFFC2410C);
        break;
      case 4:
        stageBadgeText = 'Sedang Diantar';
        stageBadgeBg = const Color(0xFFFEE2E2);
        stageBadgeTextCol = const Color(0xFFB91C1C);
        break;
      case 5:
        stageBadgeText = 'Pesanan Selesai';
        stageBadgeBg = const Color(0xFFDCFCE7);
        stageBadgeTextCol = const Color(0xFF15803D);
        break;
      default:
        stageBadgeText = 'Memproses';
        stageBadgeBg = Colors.grey.shade100;
        stageBadgeTextCol = Colors.grey.shade800;
    }

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.orderNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: stageBadgeBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: stageBadgeTextCol.withValues(alpha: 0.3), width: 0.8),
                ),
                child: Text(
                  stageBadgeText,
                  style: TextStyle(
                    color: stageBadgeTextCol,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            'Live Tracking • Pracimantoro',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.black87),
          tooltip: 'Segarkan Status',
          onPressed: () {
            if (widget.orderId.isNotEmpty && !widget.orderId.startsWith('#SAMPLE')) {
              context.read<OrderProvider>().startTrackingOrder(widget.orderId);
            }
            _initCoordinatesAndRoute();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status pesanan & posisi driver diperbarui'),
                duration: Duration(milliseconds: 900),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.help_outline_rounded, color: Colors.black87),
          tooltip: 'Bantuan CS',
          onPressed: () => _launchWhatsApp('081234567890', 'CS GAGE Pracimantoro', order.orderNumber),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 2. PETA LAYAR PENUH (FULL-BLEED MAP FLUTTER MAP GOOGLE RETINA)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildFullBleedMap(OrderModel order, int stage) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _driverLocation,
        initialZoom: 15.2,
        minZoom: 10.0,
        maxZoom: 21.0,
      ),
      children: [
        // Peta Google Roadmap Retina TileLayer
        TileLayer(
          urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&scale=2&hl=id&x={x}&y={y}&z={z}',
          subdomains: const ['0', '1', '2', '3'],
          tileDimension: 256,
          userAgentPackageName: 'com.gage.customer',
          maxZoom: 21.0,
          fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
        ),

        // Polyline Rute Jalan Raya
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              // Bayangan Polyline
              Polyline(
                points: _routePoints,
                strokeWidth: 8.0,
                color: Colors.black.withValues(alpha: 0.12),
              ),
              // Garis Rute Utama
              Polyline(
                points: _routePoints,
                strokeWidth: 5.0,
                color: stage >= 4 ? const Color(0xFFE52320) : const Color(0xFF16A34A),
              ),
            ],
          ),

        // Marker Lapisan
        MarkerLayer(
          markers: [
            // 1. Marker Toko / Titik Jemput
            Marker(
              point: _storeLocation,
              width: 50,
              height: 50,
              child: _buildStoreMarker(order.merchantName),
            ),

            // 2. Marker Rumah Pemesan / Titik Antar
            Marker(
              point: _customerLocation,
              width: 50,
              height: 50,
              child: _buildCustomerMarker(),
            ),

            // 3. Marker Driver 3D Bird's-Eye View (Rotasi Bearing & Berlatar Transparan Menyatu dengan Jalan)
            Marker(
              point: _driverLocation,
              width: 80,
              height: 80,
              child: _buildDriverMarker(order),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStoreMarker(String storeName) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: Color(0xFFF97316),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.storefront_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: const Text('Resto', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildCustomerMarker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          decoration: const BoxDecoration(
            color: GageTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.home_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: const Text('Rumah', style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  /// Marker Kendaraan 3D Bird's-Eye View (Tampak Atas) Berlatar Transparan Menyatu dengan Rute Jalan Raya
  Widget _buildDriverMarker(OrderModel order) {
    final isCar = _isCarVehicle(order);

    return Center(
      child: Transform.rotate(
        angle: _driverBearing * (math.pi / 180.0),
        child: isCar
            ? const GageCarBirdEyeWidget()
            : Image.asset(
                'assets/images/motor_3d_topdown.png',
                width: 34,
                height: 60,
                fit: BoxFit.contain,
                errorBuilder: (ctx, err, st) => Image.asset(
                  'assets/images/motor_3d_topdown.jpg',
                  width: 34,
                  height: 60,
                  fit: BoxFit.contain,
                  errorBuilder: (ctx2, err2, st2) => const GageMotorcycleBirdEyeWidget(),
                ),
              ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ACCORDION EXPAND CARD STEPPER TAHAPAN PENGIRIMAN (MELAYANG DI ATAS PETA)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAccordionStepperCard(OrderModel order, int currentStage) {
    final stages = [
      {
        'step': 1,
        'title': 'Mencari Driver Terdekat',
        'desc': 'Sistem mencocokkan mitra driver aktif di area Pracimantoro',
        'icon': Icons.radar_rounded,
      },
      {
        'step': 2,
        'title': 'Driver Menuju Lokasi Toko',
        'desc': '${order.driverName ?? "Driver"} meluncur menjemput pesanan Anda',
        'icon': Icons.two_wheeler_rounded,
      },
      {
        'step': 3,
        'title': 'Driver Membeli / Menyiapkan di Toko',
        'desc': 'Pesanan sedang dipersiapkan hangat & dicek kelengkapannya',
        'icon': Icons.outdoor_grill_rounded,
      },
      {
        'step': 4,
        'title': 'Driver Mengantar ke Rumah Anda',
        'desc': 'Paket dibawa rapi dalam box pengantar menuju alamat Anda',
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'step': 5,
        'title': 'Pesanan Tiba & Selesai',
        'desc': 'Pesanan telah diterima. Silakan nikmati dan berikan ulasan',
        'icon': Icons.check_circle_rounded,
      },
    ];

    final stageTitle = _getStageTitle(currentStage);
    final stageSubtitle = _getStageSubtitle(currentStage, order);
    final stageColor = _getStageColor(currentStage);
    final stageIcon = _getStageIcon(currentStage);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _isStepperExpanded = !_isStepperExpanded;
          });
        },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.97),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200, width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x19000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Status Tahap Saat Ini (Default Tampil)
              Row(
                children: [
                  // Icon Status Berdenyut
                  AnimatedBuilder(
                    animation: _driverPulseAnim,
                    builder: (context, child) {
                      final scale = 1.0 + (_driverPulseAnim.value * 0.08);
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: stageColor.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(stageIcon, color: stageColor, size: 20),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  // Teks Status Tahap
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tahap $currentStage/5: $stageTitle',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStage == 5
                              ? 'Pesanan tiba di tujuan • Selesai'
                              : 'ETA ~$_estimatedMinutes Menit • $stageSubtitle',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Chip Toggle Accordion
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _isStepperExpanded ? 'Tutup' : 'Rincian',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: GageTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Icon(
                          _isStepperExpanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: GageTheme.primary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Bagian Accordion Mengembang (Expand: 5 Tahapan Rute)
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                child: _isStepperExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 20),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'Rincian 5 Tahapan Pengantaran:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ),
                          ...stages.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final item = entry.value;
                            final stepNum = item['step'] as int;
                            final isCompleted = currentStage > stepNum;
                            final isCurrent = currentStage == stepNum;
                            final isLast = idx == stages.length - 1;

                            Widget stepIndicator = Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF16A34A)
                                    : (isCurrent ? GageTheme.primary : Colors.grey.shade200),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : Icon(
                                        item['icon'] as IconData,
                                        color: isCurrent ? Colors.white : Colors.grey.shade500,
                                        size: 15,
                                      ),
                              ),
                            );

                            return Column(
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    stepIndicator,
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  item['title'] as String,
                                                  style: TextStyle(
                                                    fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w600,
                                                    fontSize: 12.5,
                                                    color: isCurrent
                                                        ? const Color(0xFF0F172A)
                                                        : (isCompleted ? Colors.black87 : Colors.grey.shade500),
                                                  ),
                                                ),
                                              ),
                                              if (isCurrent)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                                  decoration: BoxDecoration(
                                                    color: GageTheme.primary.withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text(
                                                    'Aktif',
                                                    style: TextStyle(
                                                      color: GageTheme.primary,
                                                      fontSize: 9.5,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['desc'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isCurrent
                                                  ? Colors.grey.shade700
                                                  : (isCompleted ? Colors.grey.shade600 : Colors.grey.shade400),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (!isLast)
                                  Container(
                                    margin: const EdgeInsets.only(left: 13, top: 3, bottom: 3),
                                    width: 2.0,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: isCompleted ? const Color(0xFF16A34A) : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Ketuk kartu untuk menutup tahapan',
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                            ),
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getStageTitle(int stage) {
    switch (stage) {
      case 1:
        return 'Mencari Driver Terdekat';
      case 2:
        return 'Driver Menuju Toko';
      case 3:
        return 'Pesanan Sedang Disiapkan';
      case 4:
        return 'Pesanan Sedang Diantar';
      case 5:
        return 'Pesanan Tiba & Selesai';
      default:
        return 'Pesanan Diproses';
    }
  }

  String _getStageSubtitle(int stage, OrderModel order) {
    switch (stage) {
      case 1:
        return 'Mencocokkan driver di Pracimantoro';
      case 2:
        return '${order.driverName ?? "Driver"} menuju toko';
      case 3:
        return 'Pesanan dimasak hangat & rapi';
      case 4:
        return 'Menuju alamat Anda (${_routeDistanceKm.toStringAsFixed(1)} km)';
      case 5:
        return 'Paket diterima di alamat tujuan';
      default:
        return 'Memproses rute';
    }
  }

  Color _getStageColor(int stage) {
    switch (stage) {
      case 1:
        return const Color(0xFFD97706);
      case 2:
        return const Color(0xFF1D4ED8);
      case 3:
        return const Color(0xFFC2410C);
      case 4:
        return const Color(0xFFE52320);
      case 5:
        return const Color(0xFF16A34A);
      default:
        return GageTheme.primary;
    }
  }

  IconData _getStageIcon(int stage) {
    switch (stage) {
      case 1:
        return Icons.radar_rounded;
      case 2:
        return Icons.two_wheeler_rounded;
      case 3:
        return Icons.outdoor_grill_rounded;
      case 4:
        return Icons.delivery_dining_rounded;
      case 5:
        return Icons.check_circle_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. BOTTOM SHEET DRAGGABLE (DRIVER CARD, RINCIAN ORDER, POD & KONTROL TAHAP)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDraggableBottomPanel(OrderModel order, int currentStage) {
    return DraggableScrollableSheet(
      initialChildSize: 0.32,
      minChildSize: 0.20,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F000000),
                blurRadius: 18,
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Handle Bar drag indicator
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                // Driver Card Lengkap
                _buildDriverCard(order),

                const SizedBox(height: 12),

                // Rincian Multi-Merchant & Pesanan
                _buildMerchantAndOrderDetails(order),

                const SizedBox(height: 16),

                // Tombol Konfirmasi Terima Pesanan (PoD)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildPoDActionButton(order, currentStage),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPoDActionButton(OrderModel order, int currentStage) {
    final isDeliveredOrArrived = currentStage >= 4;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDeliveredOrArrived
            ? const Color(0xFF16A34A)
            : Colors.grey.shade400,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.verified_rounded, size: 20),
      label: Text(
        currentStage == 5 ? 'Pesanan Telah Selesai (Lihat Bukti PoD)' : 'Konfirmasi Pesanan Diterima',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
      onPressed: () {
        _showProofOfDeliveryDialog(order);
      },
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. DRIVER CARD LENGKAP
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDriverCard(OrderModel order) {
    final driverName = order.driverName ?? 'Mas Agus Pratama • Driver GAGE';
    final driverPlate = order.driverPlate ?? 'AD 3142 WN • Honda Vario 125';
    final driverPhone = order.driverPhone ?? '081234567892';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar Driver
              Stack(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.two_wheeler_rounded, color: Color(0xFF1E88E5), size: 30),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Color(0xFF16A34A),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),

              // Detail Identitas Driver
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.verified_rounded, color: Color(0xFF1E88E5), size: 16),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driverPlate,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                        SizedBox(width: 2),
                        Text(
                          '4.95 (450+ trip sukses)',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD97706),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Tombol Hubungi: WhatsApp & Telepon
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                  label: const Text(
                    'Chat WhatsApp',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () => _launchWhatsApp(driverPhone, driverName, order.orderNumber),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0F172A),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 17),
                  label: const Text(
                    'Telepon Driver',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () => _launchCall(driverPhone),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 5. RINCIAN MULTI-MERCHANT & RINGKASAN PESANAN
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildMerchantAndOrderDetails(OrderModel order) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Toko / Resto Mitra
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.merchantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.merchantAddress,
                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chat_outlined, color: Color(0xFF16A34A), size: 20),
                tooltip: 'Chat Resto',
                onPressed: () => _launchWhatsApp(
                  order.merchantPhone ?? '081234567890',
                  order.merchantName,
                  order.orderNumber,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Daftar Item Makanan / Barang
          const Text(
            'Daftar Belanjaan',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
          ),
          const SizedBox(height: 10),

          ...order.items.map((item) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        color: GageTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Text(
                            'Catatan: ${item.notes}',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _currencyFormatter.format(item.subtotal),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Rincian Biaya Transparan
          _buildCostRow('Total Belanja (Barang)', _currencyFormatter.format(order.itemsSubtotal)),
          const SizedBox(height: 6),
          _buildCostRow('Biaya Admin Aplikasi', _currencyFormatter.format(order.adminFee)),
          const SizedBox(height: 6),
          _buildCostRow('Ongkir Transparan (Gage Delivery)', _currencyFormatter.format(order.shippingFee)),
          if (order.shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildCostRow(
              'Diskon Ongkir Promo',
              '- ${_currencyFormatter.format(order.shippingDiscount)}',
              isGreen: true,
            ),
          ],

          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // Total Pembayaran Akhir
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F172A)),
                  ),
                  Text(
                    'Metode: ${order.paymentMethod} (${order.paymentStatus})',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ],
              ),
              Text(
                _currencyFormatter.format(order.totalAmount),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                  color: GageTheme.primary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Alamat Pengantaran
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded, color: GageTheme.primary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Alamat Pengantaran Anda',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostRow(String title, String value, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isGreen ? const Color(0xFF16A34A) : Colors.grey.shade600,
            fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGreen ? const Color(0xFF16A34A) : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }



  /// Dialog Proof of Delivery (PoD) Interaktif
  void _showProofOfDeliveryDialog(OrderModel order) {
    int selectedRating = 5;
    final recipientCtrl = TextEditingController(text: 'Diri Sendiri (Pemesan)');
    final feedbackCtrl = TextEditingController();
    final List<String> selectedTags = ['Pengiriman Cepat ⚡', 'Makanan Hangat & Rapi 🍲'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalContext, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header PoD
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Bukti Penerimaan (PoD)',
                                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF0F172A)),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Konfirmasi bahwa pesanan tiba dengan selamat',
                                style: TextStyle(fontSize: 11.5, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Foto Preview Bukti Terima (Watermark Digital GAGE)
                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.camera_alt_rounded, color: Colors.white70, size: 36),
                                const SizedBox(height: 6),
                                const Text(
                                  'Foto Paket Diserahkan ke Pemesan',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GAGE PoD Digital • Pracimantoro Verified',
                                  style: TextStyle(color: Colors.green.shade400, fontSize: 10, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Waktu: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} WIB',
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Input Nama Penerima
                    const Text(
                      'Nama Penerima',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: recipientCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),

                    const SizedBox(height: 14),

                    // Rating Bintang Driver
                    Center(
                      child: Column(
                        children: [
                          const Text(
                            'Bagaimana pelayanan Mas Agus?',
                            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF0F172A)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(5, (index) {
                              final star = index + 1;
                              return IconButton(
                                icon: Icon(
                                  star <= selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                                  color: const Color(0xFFF59E0B),
                                  size: 32,
                                ),
                                onPressed: () {
                                  setModalState(() => selectedRating = star);
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Quick Feedback Tags
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Pengiriman Cepat ⚡',
                        'Makanan Hangat & Rapi 🍲',
                        'Driver Ramah & Sopan 😊',
                        'Tepat Sesuai Alamat 📍',
                      ].map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          label: Text(tag, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : Colors.black87)),
                          selected: isSelected,
                          selectedColor: const Color(0xFF16A34A),
                          backgroundColor: const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            setModalState(() {
                              if (val) {
                                selectedTags.add(tag);
                              } else {
                                selectedTags.remove(tag);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 14),

                    // Catatan Ulasan Tambahan (Opsional)
                    const Text(
                      'Catatan / Pesan untuk Driver (Opsional)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: feedbackCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Terima kasih mas, makanan masih hangat!',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      style: const TextStyle(fontSize: 12),
                    ),

                    const SizedBox(height: 18),

                    // Tombol Submit PoD
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        setState(() => _manualStep = 5);
                        context.read<OrderProvider>().updateOrderStage(order.id, 'COMPLETED');

                        showDialog(
                          context: context,
                          builder: (successCtx) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            title: const Center(
                              child: Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 54),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Pesanan Dikonfirmasi!',
                                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Bukti penerimaan (PoD) telah berhasil disimpan. Terima kasih telah mempercayai GAGE Pracimantoro!',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            actions: [
                              Center(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: GageTheme.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () => Navigator.pop(successCtx),
                                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text(
                        'Kirim Bukti & Selesaikan Pesanan',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────
// 8. WIDGET & CUSTOM PAINTER KENDARAAN 3D BIRD'S-EYE VIEW (TAMPAK ATAS)
// ──────────────────────────────────────────────────────────────────────────

/// Widget Representasi 3D Bird's-Eye View Sepeda Motor GAGE (GageRide / GageSend / GageFood)
class GageMotorcycleBirdEyeWidget extends StatelessWidget {
  const GageMotorcycleBirdEyeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 32,
      height: 58,
      child: CustomPaint(
        painter: _GageMotorcyclePainter(),
      ),
    );
  }
}

class _GageMotorcyclePainter extends CustomPainter {
  const _GageMotorcyclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;

    // 1. Roda Depan (Front Tire)
    final tirePaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.fill;
    final frontTireRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.12), width: 5.5, height: 11),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(frontTireRect, tirePaint);

    // 2. Roda Belakang (Rear Tire)
    final rearTireRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.88), width: 6.0, height: 10),
      const Radius.circular(2.5),
    );
    canvas.drawRRect(rearTireRect, tirePaint);

    // 3. Spakbor & Bodi Depan (Fairing & Front Mudguard)
    final fairingPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;
    final fairingPath = Path()
      ..moveTo(cx, size.height * 0.08)
      ..lineTo(cx + 6, size.height * 0.22)
      ..lineTo(cx - 6, size.height * 0.22)
      ..close();
    canvas.drawPath(fairingPath, fairingPaint);

    // Lampu Depan LED (Headlight)
    final lightPaint = Paint()..color = const Color(0xFFFEF08A);
    canvas.drawCircle(Offset(cx, size.height * 0.10), 2.2, lightPaint);

    // 4. Stang Kemudi & Kaca Spion (Handlebars & Mirrors)
    final barPaint = Paint()
      ..color = const Color(0xFF334155)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 12, size.height * 0.24),
      Offset(cx + 12, size.height * 0.24),
      barPaint,
    );

    // Spion Kiri & Kanan
    final mirrorStalkPaint = Paint()
      ..color = const Color(0xFF64748B)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 10, size.height * 0.24),
      Offset(cx - 13, size.height * 0.17),
      mirrorStalkPaint,
    );
    canvas.drawLine(
      Offset(cx + 10, size.height * 0.24),
      Offset(cx + 13, size.height * 0.17),
      mirrorStalkPaint,
    );

    final mirrorHeadPaint = Paint()..color = const Color(0xFFE2E8F0);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx - 13.5, size.height * 0.16), width: 4, height: 3),
      mirrorHeadPaint,
    );
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx + 13.5, size.height * 0.16), width: 4, height: 3),
      mirrorHeadPaint,
    );

    // 5. Pengendara (Rider: Jaket Hijau GAGE & Bahu)
    final jacketPaint = Paint()
      ..color = const Color(0xFF15803D)
      ..style = PaintingStyle.fill;
    final shouldersRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.38), width: 22, height: 13),
      const Radius.circular(6),
    );
    canvas.drawRRect(shouldersRect, jacketPaint);

    // Helm Pengendara (Helmet Tampak Atas)
    final helmetPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawCircle(Offset(cx, size.height * 0.36), 7.5, helmetPaint);

    // Visor Kaca Helm (Menghadap ke Depan)
    final visorPaint = Paint()
      ..color = const Color(0xFF38BDF8)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, size.height * 0.36), radius: 6.5),
      math.pi * 1.15,
      math.pi * 0.70,
      false,
      visorPaint,
    );

    // Highlight Kilau Helm (Gloss reflection)
    final glossPaint = Paint()..color = Colors.white.withValues(alpha: 0.5);
    canvas.drawCircle(Offset(cx - 2.5, size.height * 0.33), 1.6, glossPaint);

    // 6. Jok Motor (Seat)
    final seatPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.fill;
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.56), width: 11, height: 14),
      const Radius.circular(4),
    );
    canvas.drawRRect(seatRect, seatPaint);

    // 7. Boks Pengiriman GAGE (Delivery Box Tampak Atas)
    final boxPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;
    final boxBorderPaint = Paint()
      ..color = const Color(0xFF14532D)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final boxRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.75), width: 19, height: 14),
      const Radius.circular(3.5),
    );
    canvas.drawRRect(boxRect, boxPaint);
    canvas.drawRRect(boxRect, boxBorderPaint);

    // Teks / Logo "G" di atas Boks
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - (textPainter.width / 2), size.height * 0.75 - (textPainter.height / 2)),
    );

    // Lampu Belakang Merah (Taillight Strip)
    final tailPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 6, size.height * 0.83),
      Offset(cx + 6, size.height * 0.83),
      tailPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Widget Representasi 3D Bird's-Eye View Mobil GAGE (GageCar)
class GageCarBirdEyeWidget extends StatelessWidget {
  const GageCarBirdEyeWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 40,
      height: 68,
      child: CustomPaint(
        painter: _GageCarPainter(),
      ),
    );
  }
}

class _GageCarPainter extends CustomPainter {
  const _GageCarPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2.0;

    // 1. Spion Samping Mobil (Side Mirrors)
    final mirrorPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.fill;
    final mirrorBorder = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final leftMirror = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 18, size.height * 0.32), width: 5.5, height: 4),
      const Radius.circular(1.5),
    );
    final rightMirror = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 18, size.height * 0.32), width: 5.5, height: 4),
      const Radius.circular(1.5),
    );
    canvas.drawRRect(leftMirror, mirrorPaint);
    canvas.drawRRect(leftMirror, mirrorBorder);
    canvas.drawRRect(rightMirror, mirrorPaint);
    canvas.drawRRect(rightMirror, mirrorBorder);

    // 2. Siluet Bodi Mobil Aerodinamis (Car Chassis)
    final bodyPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final bodyBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    final bodyPath = Path()
      // Titik depan kap mesin (Bumper Depan)
      ..moveTo(cx - 10, size.height * 0.05)
      ..quadraticBezierTo(cx, size.height * 0.03, cx + 10, size.height * 0.05)
      // Sudut kanan depan
      ..quadraticBezierTo(cx + 16, size.height * 0.07, cx + 16.5, size.height * 0.22)
      // Lekukan bodi samping kanan
      ..lineTo(cx + 17, size.height * 0.72)
      // Sudut kanan belakang
      ..quadraticBezierTo(cx + 16.5, size.height * 0.94, cx + 11, size.height * 0.96)
      // Bumper belakang
      ..quadraticBezierTo(cx, size.height * 0.97, cx - 11, size.height * 0.96)
      // Sudut kiri belakang
      ..quadraticBezierTo(cx - 16.5, size.height * 0.94, cx - 17, size.height * 0.72)
      // Lekukan bodi samping kiri
      ..lineTo(cx - 16.5, size.height * 0.22)
      // Sudut kiri depan
      ..quadraticBezierTo(cx - 16, size.height * 0.07, cx - 10, size.height * 0.05)
      ..close();

    canvas.drawPath(bodyPath, bodyPaint);
    canvas.drawPath(bodyPath, bodyBorderPaint);

    // 3. Garis Kontur Kap Mesin Depan (Hood lines)
    final hoodLinePaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 8, size.height * 0.12),
      Offset(cx - 6, size.height * 0.25),
      hoodLinePaint,
    );
    canvas.drawLine(
      Offset(cx + 8, size.height * 0.12),
      Offset(cx + 6, size.height * 0.25),
      hoodLinePaint,
    );

    // 4. Kaca Depan (Front Windshield)
    final glassPaint = Paint()
      ..color = const Color(0xFF0F172A)
      ..style = PaintingStyle.fill;

    final windshieldPath = Path()
      ..moveTo(cx - 12, size.height * 0.27)
      ..lineTo(cx + 12, size.height * 0.27)
      ..lineTo(cx + 14, size.height * 0.40)
      ..lineTo(cx - 14, size.height * 0.40)
      ..close();
    canvas.drawPath(windshieldPath, glassPaint);

    // Kilau Kaca Depan (Glass Glare Reflection)
    final glarePaint = Paint()
      ..color = const Color(0xFF38BDF8).withValues(alpha: 0.4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(cx - 6, size.height * 0.29),
      Offset(cx - 1, size.height * 0.38),
      glarePaint,
    );

    // 5. Atap Mobil (Roof Panel dengan Aksen GAGE Green)
    final roofPaint = Paint()
      ..color = const Color(0xFF16A34A)
      ..style = PaintingStyle.fill;
    final roofRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, size.height * 0.54), width: 24, height: 21),
      const Radius.circular(4.5),
    );
    canvas.drawRRect(roofRect, roofPaint);

    // Sunroof / Emblem Atap
    final sunroofPaint = Paint()
      ..color = const Color(0xFF14532D)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, size.height * 0.54), width: 14, height: 11),
        const Radius.circular(2.5),
      ),
      sunroofPaint,
    );

    // Teks Mini "GAGE" di Atap
    final gageTextPainter = TextPainter(
      text: const TextSpan(
        text: 'GAGE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 5.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    gageTextPainter.paint(
      canvas,
      Offset(cx - (gageTextPainter.width / 2), size.height * 0.54 - (gageTextPainter.height / 2)),
    );

    // 6. Kaca Belakang (Rear Windshield)
    final rearGlassPath = Path()
      ..moveTo(cx - 13, size.height * 0.67)
      ..lineTo(cx + 13, size.height * 0.67)
      ..lineTo(cx + 11.5, size.height * 0.77)
      ..lineTo(cx - 11.5, size.height * 0.77)
      ..close();
    canvas.drawPath(rearGlassPath, glassPaint);

    // 7. Lampu Depan LED (Front Headlights)
    final headlightPaint = Paint()
      ..color = const Color(0xFFFEF08A)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 15, size.height * 0.06, 5, 3),
        const Radius.circular(1),
      ),
      headlightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 10, size.height * 0.06, 5, 3),
        const Radius.circular(1),
      ),
      headlightPaint,
    );

    // 8. Lampu Belakang LED Merah (Taillights)
    final taillightPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 15, size.height * 0.93, 6, 2.5),
        const Radius.circular(1),
      ),
      taillightPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 9, size.height * 0.93, 6, 2.5),
        const Radius.circular(1),
      ),
      taillightPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
