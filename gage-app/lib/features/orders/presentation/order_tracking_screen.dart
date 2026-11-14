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
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/core/services/osrm_routing_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/orders/presentation/order_success_review_screen.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_receipt_share_dialog.dart';
import 'package:gage_app/shared/widgets/mini_location_preview_map.dart';

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

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
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
  Timer? _driverMovementTimer;
  OrderProvider? _orderProvider;
  int _manualStep = 0; // Override testing hanya saat GageApiClient.useDevSeedData aktif
  int _currentRouteIndex = 0;
  double _driverBearing = 0.0;
  String? _manualVehicleType; // null = auto detect, 'MOTOR', 'CAR'
  bool _isStepperExpanded = false; // Accordion Expand Card State

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        _orderProvider = context.read<OrderProvider>();
      } on ProviderNotFoundException {
        _orderProvider = null;
      }
      if (widget.orderId.isNotEmpty && !widget.orderId.startsWith('#SAMPLE')) {
        _orderProvider?.startTrackingOrder(widget.orderId);
      }
      final currentOrder = _orderProvider?.currentTrackedOrder ?? widget.initialOrder;
      _initCoordinatesAndRoute(currentOrder);
    });
  }

  @override
  void dispose() {
    _driverMovementTimer?.cancel();
    _orderProvider?.stopTracking();
    super.dispose();
  }

  /// Inisialisasi Koordinat Toko/Jemput, Tujuan, Driver & OSRM Realtime Polyline
  Future<void> _initCoordinatesAndRoute([OrderModel? order]) async {
    setState(() => _isLoadingRoute = true);
    try {
      final hasPickup = order?.pickupLat != null && order?.pickupLng != null;
      final hasDropoff = order?.deliveryLat != null && order?.deliveryLng != null;
      final fallbackGps = (hasPickup && hasDropoff)
          ? LatLng(order!.deliveryLat!, order.deliveryLng!)
          : await LocationService.getCurrentLocation();

      if (mounted) {
        setState(() {
          _storeLocation = hasPickup
              ? LatLng(order!.pickupLat!, order.pickupLng!)
              : const LatLng(-8.05580, 110.80950);
          _customerLocation = hasDropoff
              ? LatLng(order!.deliveryLat!, order.deliveryLng!)
              : fallbackGps;
          _driverLocation = LatLng(
            (_storeLocation.latitude + _customerLocation.latitude) / 2 + 0.001,
            (_storeLocation.longitude + _customerLocation.longitude) / 2 - 0.001,
          );
        });
      }
    } catch (_) {
      // Fallback koordinat Pracimantoro jika GPS offline
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
          _routeDistanceKm = routeRes.distanceKm > 0.1
              ? routeRes.distanceKm
              : (order != null && order.distanceKm > 0 ? order.distanceKm : 1.8);
          _estimatedMinutes = routeRes.durationMinutes > 0
              ? routeRes.durationMinutes
              : (_routeDistanceKm * 4).ceil().clamp(5, 45);
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
    if (_manualVehicleType != null && GageApiClient.useDevSeedData) {
      return _manualVehicleType == 'CAR';
    }
    if (order.serviceType.toLowerCase() == 'car') return true;
    final vehicle = (order.driverVehicle ?? '').toLowerCase();
    final plate = (order.driverPlate ?? '').toLowerCase();
    final name = (order.driverName ?? '').toLowerCase();
    final orderNum = order.orderNumber.toLowerCase();
    return vehicle.contains('mobil') ||
        vehicle.contains('car') ||
        vehicle.contains('avanza') ||
        vehicle.contains('brio') ||
        plate.contains('mobil') ||
        plate.contains('car') ||
        plate.contains('avanza') ||
        plate.contains('brio') ||
        name.contains('mobil') ||
        name.contains('car') ||
        orderNum.contains('car');
  }

  /// Menentukan tahap lifecycle pesanan berurutan (1..5), 0 jika dibatalkan:
  /// 1: Menunggu Konfirmasi / Cari Driver -> 2: Disiapkan / Driver Menuju Jemput -> 3: Siap / Tiba di Titik Jemput -> 4: Dalam Pengantaran/Perjalanan -> 5: Selesai
  int _determineLifecycleStage(OrderModel order) {
    if (GageApiClient.useDevSeedData && _manualStep > 0) return _manualStep;

    final s = order.status.toUpperCase();
    if (s == 'CANCELLED') return 0;

    switch (s) {
      case 'ORDER_RECEIVED':
      case 'PAYMENT_PENDING':
      case 'PENDING':
      case 'NEW':
      case 'PAID':
      case 'SEARCHING_DRIVER':
        return 1;
      case 'COOKING':
      case 'PROCESSING':
      case 'PREPARING':
      case 'HEADING_TO_STORE':
      case 'AT_STORE':
      case 'DRIVER_ASSIGNED':
        return 2;
      case 'AT_MERCHANT':
        return order.isTransportService ? 3 : 2;
      case 'READY_FOR_PICKUP':
      case 'READY':
        return 3;
      case 'PICKED_UP':
      case 'ON_DELIVERY':
      case 'DELIVERING':
        return 4;
      case 'COMPLETED':
        return 5;
      default:
        return 1;
    }
  }

  void _openSupportChat(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => InAppChatScreen(
          orderId: order.id,
          recipientName: 'Pusat Bantuan GAGE',
          recipientRole: 'ai',
          recipientPhone: '',
          currentRole: 'customer',
        ),
      ),
    );
  }

  /// Launch Direct Phone Call (aman tanpa nomor fiktif)
  Future<void> _launchCall(String phone) async {
    final trimmed = phone.trim();
    if (trimmed.isEmpty || trimmed == '-') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nomor telepon belum tersedia.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    final uri = Uri.parse('tel:$trimmed');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await Clipboard.setData(ClipboardData(text: trimmed));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nomor telepon disalin: $trimmed')),
          );
        }
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: trimmed));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Nomor telepon disalin: $trimmed')),
        );
      }
    }
  }

  /// Fallback sample order hanya aktif jika GageApiClient.useDevSeedData = true
  OrderModel? _createFallbackOrder() {
    if (!GageApiClient.useDevSeedData) return null;
    return OrderModel(
      id: widget.orderId.isEmpty ? 'ord-gage-8821' : widget.orderId,
      orderNumber: widget.orderId.startsWith('#')
          ? widget.orderId
          : (widget.orderId.isNotEmpty ? '#${widget.orderId}' : '#GAGE-8821'),
      userId: 'usr-cust-01',
      merchantId: 'mch-dimsum-01',
      merchantName: 'Dimsum Sewu by Halu Goods',
      merchantAddress: 'Kompleks Ruko Pasar Pracimantoro No. 8',
      merchantPhone: '081226001000',
      driverName: 'Agus Pratama',
      driverPlate: 'AD 3142 WN',
      driverVehicle: 'Honda Vario 125',
      driverRating: 4.9,
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
          imageUrl: 'assets/images/dish_dimsum_original.png',
        ),
        OrderItemModel(
          id: 'item-2',
          name: 'Dimsum Mozzarella Lumer (Isi 4)',
          price: 14000,
          quantity: 1,
          subtotal: 14000,
          notes: 'Keju lumer meleleh',
          imageUrl: 'assets/images/dish_dimsum_mentai.png',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    OrderProvider? orderProvider;
    try {
      orderProvider = context.watch<OrderProvider>();
    } on ProviderNotFoundException {
      orderProvider = null;
    }

    final resolvedOrder = orderProvider?.currentTrackedOrder ??
        (widget.orderId.isNotEmpty ? orderProvider?.getOrderById(widget.orderId) : null) ??
        widget.initialOrder ??
        _createFallbackOrder();

    if (resolvedOrder == null) {
      return Scaffold(
        backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
        appBar: AppBar(
          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          title: const Text('Pelacakan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          elevation: 0.5,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.map_outlined, size: 52, color: isDark ? Colors.white38 : Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Data pelacakan pesanan belum tersedia.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Periksa kembali rincian pesanan di menu Pesanan Saya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kembali', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final order = resolvedOrder;
    final currentStage = _determineLifecycleStage(order);

    if (currentStage >= 4 &&
        order.hasAssignedDriver &&
        !order.isPickup &&
        _driverMovementTimer == null) {
      _startDriverRouteMovement();
    } else if ((currentStage < 4 || !order.hasAssignedDriver || order.isPickup) &&
        _driverMovementTimer != null) {
      _driverMovementTimer?.cancel();
      _driverMovementTimer = null;
    }

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: _buildAppBar(order, isDark),
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

          // 2. TOMBOL KONTROL PETA (ZOOM OUT RUTE, RECENTER & QUICK CHAT) MELAYANG DI ATAS PETA
          Positioned(
            right: 16,
            bottom: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'track_quick_chat',
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 3,
                  tooltip: order.hasAssignedDriver ? 'Chat Driver' : 'Chat Bantuan / Toko',
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => InAppChatScreen(
                          orderId: order.id,
                          recipientName: order.hasAssignedDriver
                              ? (order.driverName ?? 'Driver GAGE')
                              : (order.isTransportService ? 'Pusat Bantuan GAGE' : order.merchantName),
                          recipientRole: order.hasAssignedDriver
                              ? 'driver'
                              : (order.isTransportService ? 'ai' : 'merchant'),
                          recipientPhone: order.hasAssignedDriver
                              ? (order.driverPhone ?? '').trim()
                              : (order.merchantPhone ?? '').trim(),
                          currentRole: 'customer',
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.chat_bubble_rounded, size: 18),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'track_fit_route',
                  backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                  foregroundColor: isDark ? Colors.white : Colors.black87,
                  elevation: 3,
                  onPressed: _fitRouteInCamera,
                  child: const Icon(Icons.zoom_out_map_rounded, size: 20),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'track_recenter',
                  backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                  foregroundColor: GageTheme.primary,
                  elevation: 3,
                  onPressed: () {
                    final target = (order.hasAssignedDriver && currentStage >= 2)
                        ? _driverLocation
                        : _storeLocation;
                    _mapController.move(target, 16.0);
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
            child: _buildAccordionStepperCard(order, currentStage, isDark),
          ),

          // 4. BOTTOM SHEET DRAGGABLE: DRIVER CARD / STATUS TUNGGU, RINCIAN ORDER & POD
          _buildDraggableBottomPanel(order, currentStage, isDark),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 1. APPBAR (BERSIH TANPA DUPLIKASI STATUS PILL)
  // ──────────────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(OrderModel order, bool isDark) {
    final fg = isDark ? Colors.white : Colors.black87;
    return AppBar(
      backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
      elevation: 0.5,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: fg),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.orderNumber,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fg,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Pelacakan Langsung',
            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 11),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.share_outlined, color: fg),
          tooltip: 'Bagikan Struk',
          onPressed: () => GageReceiptShareDialog.show(context, order),
        ),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: fg),
          tooltip: 'Segarkan Status',
          onPressed: () {
            if (widget.orderId.isNotEmpty && !widget.orderId.startsWith('#SAMPLE')) {
              _orderProvider?.startTrackingOrder(widget.orderId);
            }
            _initCoordinatesAndRoute(order);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Status pesanan & posisi diperbarui'),
                duration: Duration(milliseconds: 900),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
        IconButton(
          icon: Icon(Icons.help_outline_rounded, color: fg),
          tooltip: 'Pusat Bantuan GAGE',
          onPressed: () => _openSupportChat(order),
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
                color: const Color(0xFFE52320),
              ),
            ],
          ),

        // Marker Lapisan
        MarkerLayer(
          markers: [
            // 1. Marker Toko / Titik Jemput
            Marker(
              point: _storeLocation,
              width: 56,
              height: 54,
              child: _buildStoreMarker(order),
            ),

            // 2. Marker Pemesan / Titik Antar
            Marker(
              point: _customerLocation,
              width: 56,
              height: 54,
              child: _buildCustomerMarker(order),
            ),

            // 3. Marker Driver 3D (hanya tampil bila driver sudah terassign & bukan pickup)
            if (order.hasAssignedDriver && !order.isPickup && stage >= 2 && stage < 5)
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

  Widget _buildStoreMarker(OrderModel order) {
    final markerLabel = order.isTransportService ? 'Jemput' : order.merchantName;
    final resolvedAvatar = order.resolveMerchantAvatarAsset();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!order.isTransportService)
          MerchantLocationPin(
            imagePath: resolvedAvatar,
            size: 36,
          )
        else
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF16A34A),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
            child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 18),
          ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Text(
            markerLabel.isNotEmpty ? markerLabel : 'Toko',
            style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerMarker(OrderModel order) {
    AuthProvider? authProvider;
    try {
      authProvider = context.read<AuthProvider>();
    } on ProviderNotFoundException {
      authProvider = null;
    }
    final user = authProvider?.currentUser;
    final avatarUrl = (order.customerAvatar != null && order.customerAvatar!.trim().isNotEmpty)
        ? order.customerAvatar
        : user?.avatarUrl;
    final fallbackName = (order.customerName != null && order.customerName!.trim().isNotEmpty)
        ? order.customerName!
        : (user?.name ?? 'Saya');
    final label = order.isTransportService ? 'Tujuan' : 'Antar';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(2),
          decoration: const BoxDecoration(
            color: GageTheme.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: GageAvatar(
            imageUrl: avatarUrl,
            fallbackName: fallbackName,
            radius: 15,
            backgroundColor: Colors.white,
            foregroundColor: GageTheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.red.shade200),
          ),
          child: Text(label, style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.black87)),
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

  List<Map<String, dynamic>> _buildStagesForOrder(OrderModel order) {
    final svc = order.serviceType.toLowerCase();
    final driverLabel = order.hasAssignedDriver ? order.driverName! : 'Driver GAGE';

    if (svc == 'ride' || svc == 'car') {
      return [
        {
          'step': 1,
          'title': 'Mencari Driver',
          'desc': 'Mencari driver terdekat di sekitar titik jemput Anda',
          'icon': Icons.search_rounded,
        },
        {
          'step': 2,
          'title': 'Driver Menuju Jemput',
          'desc': '$driverLabel sedang meluncur menuju lokasi jemput',
          'icon': svc == 'car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
        },
        {
          'step': 3,
          'title': 'Tiba di Titik Jemput',
          'desc': '$driverLabel menunggu di titik penjemputan',
          'icon': Icons.pin_drop_rounded,
        },
        {
          'step': 4,
          'title': 'Dalam Perjalanan',
          'desc': 'Menuju tujuan Anda di ${order.deliveryAddress}',
          'icon': Icons.navigation_rounded,
        },
        {
          'step': 5,
          'title': 'Tiba di Tujuan',
          'desc': 'Perjalanan selesai dengan aman',
          'icon': Icons.check_circle_rounded,
        },
      ];
    }

    if (svc == 'send') {
      return [
        {
          'step': 1,
          'title': 'Mencari Kurir',
          'desc': 'Mencari kurir GAGE Send untuk penjemputan paket',
          'icon': Icons.search_rounded,
        },
        {
          'step': 2,
          'title': 'Kurir Menuju Pengirim',
          'desc': '$driverLabel menuju lokasi penjemputan paket',
          'icon': Icons.two_wheeler_rounded,
        },
        {
          'step': 3,
          'title': 'Paket Dijemput',
          'desc': 'Kurir sedang mengambil paket di lokasi pengirim',
          'icon': Icons.inventory_2_rounded,
        },
        {
          'step': 4,
          'title': 'Paket Dikirim',
          'desc': '$driverLabel mengantar paket menuju penerima',
          'icon': Icons.local_shipping_rounded,
        },
        {
          'step': 5,
          'title': 'Paket Diterima',
          'desc': 'Paket telah sampai ke penerima',
          'icon': Icons.check_circle_rounded,
        },
      ];
    }

    final isFood = svc == 'food';
    return [
      {
        'step': 1,
        'title': 'Menunggu Konfirmasi',
        'desc': 'Pesanan menunggu konfirmasi dari ${order.merchantName}',
        'icon': Icons.receipt_long_rounded,
      },
      {
        'step': 2,
        'title': isFood ? 'Sedang Disiapkan Dapur' : 'Sedang Dikemas Toko',
        'desc': '${order.merchantName} sedang menyiapkan pesanan Anda',
        'icon': isFood ? Icons.outdoor_grill_rounded : Icons.storefront_rounded,
      },
      {
        'step': 3,
        'title': order.isPickup ? 'Siap Diambil' : 'Siap Dipickup Kurir',
        'desc': order.isPickup
            ? 'Pesanan siap diambil langsung di ${order.merchantName}'
            : 'Pesanan selesai dikemas dan menunggu pengambilan kurir',
        'icon': Icons.inventory_2_rounded,
      },
      {
        'step': 4,
        'title': 'Dalam Pengantaran',
        'desc': '$driverLabel mengantar pesanan menuju alamat Anda',
        'icon': Icons.delivery_dining_rounded,
      },
      {
        'step': 5,
        'title': 'Pesanan Selesai',
        'desc': 'Pesanan telah diterima di tujuan',
        'icon': Icons.check_circle_rounded,
      },
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 3. ACCORDION EXPAND CARD STEPPER TAHAPAN PENGIRIMAN (MELAYANG DI ATAS PETA)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildAccordionStepperCard(OrderModel order, int currentStage, bool isDark) {
    final stages = _buildStagesForOrder(order);
    final stageTitle = _getStageTitle(currentStage, order);
    final stageSubtitle = _getStageSubtitle(currentStage, order);
    final stageColor = _getStageColor(currentStage);
    final stageIcon = _getStageIcon(currentStage, order);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
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
            color: (isDark ? GageTheme.darkSurface : Colors.white).withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200, width: 1.2),
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
              // Header Status Tahap Saat Ini
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: stageColor.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(stageIcon, color: stageColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stageTitle,
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14.0,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentStage == 5 || currentStage == 0
                              ? stageSubtitle
                              : 'ETA ~$_estimatedMinutes Menit | $stageSubtitle',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GageTheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
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

              // Bagian Accordion Mengembang
              AnimatedSize(
                duration: const Duration(milliseconds: 320),
                curve: Curves.easeInOutCubic,
                child: _isStepperExpanded
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Divider(height: 20, color: isDark ? GageTheme.darkBorder : null),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Text(
                              'Tahapan Proses Pesanan:',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                                color: isDark ? Colors.white : const Color(0xFF334155),
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

                            final Widget stepIndicator = Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF16A34A)
                                    : (isCurrent
                                        ? GageTheme.primary
                                        : (isDark ? Colors.white12 : Colors.grey.shade200)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                                    : Icon(
                                        item['icon'] as IconData,
                                        color: isCurrent
                                            ? Colors.white
                                            : (isDark ? Colors.white38 : Colors.grey.shade500),
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
                                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                                        : (isCompleted
                                                            ? (isDark ? Colors.white70 : Colors.black87)
                                                            : (isDark ? Colors.white38 : Colors.grey.shade500)),
                                                  ),
                                                ),
                                              ),
                                              if (isCurrent)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: GageTheme.primary.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(999),
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
                                                  ? (isDark ? Colors.white70 : Colors.grey.shade700)
                                                  : (isCompleted
                                                      ? (isDark ? Colors.white60 : Colors.grey.shade600)
                                                      : (isDark ? Colors.white30 : Colors.grey.shade400)),
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
                                      color: isCompleted
                                          ? const Color(0xFF16A34A)
                                          : (isDark ? Colors.white12 : Colors.grey.shade200),
                                      borderRadius: BorderRadius.circular(1),
                                    ),
                                  ),
                              ],
                            );
                          }),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              'Ketuk kartu untuk menutup rincian',
                              style: TextStyle(fontSize: 10, color: isDark ? Colors.white38 : Colors.grey.shade500),
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

  String _getStageTitle(int stage, OrderModel order) {
    if (stage == 0) return 'Pesanan Dibatalkan';
    return order.statusLabel;
  }

  String _getStageSubtitle(int stage, OrderModel order) {
    if (stage == 0) {
      return order.cancellationReason?.trim().isNotEmpty == true
          ? order.cancellationReason!.trim()
          : 'Pesanan dibatalkan';
    }
    final svc = order.serviceType.toLowerCase();
    switch (stage) {
      case 1:
        if (svc == 'ride' || svc == 'car') return 'Mencari driver terdekat';
        if (svc == 'send') return 'Mencari kurir penjemputan';
        return 'Menunggu konfirmasi ${order.merchantName}';
      case 2:
        if (order.isTransportService) {
          return '${order.driverName ?? "Driver"} menuju titik jemput';
        }
        return '${order.merchantName} sedang menyiapkan pesanan';
      case 3:
        if (order.isTransportService) return 'Driver tiba di lokasi jemput';
        return order.isPickup ? 'Siap diambil di toko' : 'Menunggu kurir pickup pesanan';
      case 4:
        return '${order.driverName ?? "Driver"} menuju tujuan (${_routeDistanceKm.toStringAsFixed(1)} km)';
      case 5:
        return 'Pesanan tiba di alamat tujuan';
      default:
        return 'Memproses pesanan';
    }
  }

  Color _getStageColor(int stage) {
    switch (stage) {
      case 0:
        return const Color(0xFFDC2626);
      case 1:
        return const Color(0xFF2563EB);
      case 2:
        return const Color(0xFFD97706);
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

  IconData _getStageIcon(int stage, OrderModel order) {
    if (stage == 0) return Icons.cancel_rounded;
    final svc = order.serviceType.toLowerCase();
    switch (stage) {
      case 1:
        return order.isTransportService ? Icons.search_rounded : Icons.receipt_long_rounded;
      case 2:
        if (svc == 'car') return Icons.directions_car_rounded;
        if (svc == 'ride' || svc == 'send') return Icons.two_wheeler_rounded;
        return Icons.outdoor_grill_rounded;
      case 3:
        return order.isTransportService ? Icons.pin_drop_rounded : Icons.inventory_2_rounded;
      case 4:
        return svc == 'car' ? Icons.directions_car_rounded : Icons.delivery_dining_rounded;
      case 5:
        return Icons.check_circle_rounded;
      default:
        return Icons.local_shipping_rounded;
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. BOTTOM SHEET DRAGGABLE (DRIVER CARD, RINCIAN ORDER, POD & KONTROL TAHAP)
  // ──────────────────────────────────────────────────────────────────────────
  // ──────────────────────────────────────────────────────────────────────────
  // 4. BOTTOM SHEET DRAGGABLE (DRIVER CARD / STATUS TUNGGU, RINCIAN ORDER, POD)
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDraggableBottomPanel(OrderModel order, int currentStage, bool isDark) {
    return DraggableScrollableSheet(
      initialChildSize: 0.34,
      minChildSize: 0.22,
      maxChildSize: 0.88,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkBackground : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: const [
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
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 8),
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),

                if (order.hasAssignedDriver && !order.isPickup)
                  _buildDriverCard(order, isDark)
                else
                  _buildWaitingStatusCard(order, currentStage, isDark),

                const SizedBox(height: 12),

                _buildMerchantAndOrderDetails(order, isDark),

                if (!order.isPickup && currentStage > 0) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildPoDActionButton(order, currentStage, isDark),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildWaitingStatusCard(OrderModel order, int currentStage, bool isDark) {
    final svc = order.serviceType.toLowerCase();
    final String heading;
    final String sub;
    if (currentStage == 0) {
      heading = 'Pesanan Dibatalkan';
      sub = order.cancellationReason?.trim().isNotEmpty == true
          ? order.cancellationReason!.trim()
          : 'Pesanan tidak dapat dilanjutkan.';
    } else if (order.isPickup) {
      heading = 'Ambil Sendiri di Lokasi Merchant';
      sub = 'Tunjukkan nomor invoice ${order.orderNumber} saat mengambil pesanan.';
    } else if (svc == 'ride' || svc == 'car' || svc == 'send') {
      heading = 'Mencari Mitra Driver Terdekat...';
      sub = 'Identitas dan posisi driver akan muncul segera setelah driver menerima order.';
    } else {
      heading = currentStage == 1
          ? 'Menunggu Konfirmasi ${order.merchantName}'
          : 'Pesanan Diproses, Mencari Kurir...';
      sub = currentStage == 1
          ? 'Merchant sedang meninjau pesanan Anda sebelum disiapkan.'
          : 'Informasi kurir pengantar akan tampil setelah kurir ditugaskan.';
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (currentStage == 0 ? Colors.red : GageTheme.primary).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  currentStage == 0
                      ? Icons.cancel_rounded
                      : (order.isPickup ? Icons.store_mall_directory_rounded : Icons.radar_rounded),
                  color: currentStage == 0 ? Colors.red : GageTheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heading,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (order.canBeCancelledByCustomer) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                backgroundColor: isDark ? Colors.red.withValues(alpha: 0.12) : const Color(0xFFFEF2F2),
                foregroundColor: const Color(0xFFDC2626),
                side: BorderSide(color: isDark ? Colors.red.shade800 : const Color(0xFFFECACA), width: 1.2),
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 9),
              ),
              onPressed: () => _confirmCancelOrder(order),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmCancelOrder(OrderModel order) async {
    HapticFeedback.mediumImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: isDark ? GageTheme.darkBackground : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.warning_amber_rounded, size: 36, color: Color(0xFFDC2626)),
            ),
            const SizedBox(height: 12),
            Text(
              'Batalkan Pesanan Ini?',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order.isTransportService
                  ? 'Mitra driver belum ditugaskan. Apakah Anda yakin ingin membatalkan perjalanan/pengiriman ini?'
                  : 'Merchant belum mengonfirmasi pesanan. Apakah Anda yakin ingin membatalkan pesanan ini?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                    ),
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text('Kembali', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Ya, Batalkan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final ok = await _orderProvider?.updateOrderStage(
        order.id,
        'CANCELLED',
        reason: 'Dibatalkan oleh pelanggan',
      );
      if (!mounted) return;
      if (ok == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibatalkan'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Widget _buildPoDActionButton(OrderModel order, int currentStage, bool isDark) {
    final isDeliveredOrArrived = currentStage >= 4;

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDeliveredOrArrived
            ? const Color(0xFF16A34A)
            : (isDark ? Colors.white12 : Colors.grey.shade400),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.verified_rounded, size: 20),
      label: Text(
        currentStage == 5 ? 'Pesanan Telah Selesai (Lihat Bukti PoD)' : 'Konfirmasi Pesanan Diterima',
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
      ),
      onPressed: isDeliveredOrArrived
          ? () {
              _showProofOfDeliveryDialog(order, isDark);
            }
          : null,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // 4. DRIVER CARD LENGKAP
  // ──────────────────────────────────────────────────────────────────────────
  Widget _buildDriverCard(OrderModel order, bool isDark) {
    final driverName = (order.driverName != null && order.driverName!.trim().isNotEmpty)
        ? order.driverName!.trim()
        : 'Mitra Driver GAGE';
    final vehicleParts = [
      if (order.driverVehicle != null && order.driverVehicle!.trim().isNotEmpty)
        order.driverVehicle!.trim(),
      if (order.driverPlate != null && order.driverPlate!.trim().isNotEmpty)
        order.driverPlate!.trim(),
    ];
    final driverPlate = vehicleParts.isNotEmpty ? vehicleParts.join(' | ') : 'Kendaraan Terverifikasi';
    final driverPhone = (order.driverPhone ?? '').trim();
    final hasPhone = driverPhone.isNotEmpty && driverPhone != '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        boxShadow: isDark
            ? null
            : const [
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
              Stack(
                children: [
                  GageAvatar(
                    imageUrl: order.driverAvatar,
                    fallbackName: driverName,
                    radius: 26,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? GageTheme.darkSurface : Colors.white,
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

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            driverName,
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 14,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                        color: isDark ? Colors.white70 : Colors.grey.shade700,
                      ),
                    ),
                    if (order.driverRating != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                          const SizedBox(width: 3),
                          Text(
                            order.driverRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          Divider(height: 1, color: isDark ? GageTheme.darkBorder : null),
          const SizedBox(height: 12),

          // Tombol Hubungi Driver: Chat In-App & Telepon Langsung (Tanpa WhatsApp)
          Row(
            children: [
              Expanded(
                flex: 5,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text(
                    'Chat Driver',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => InAppChatScreen(
                          orderId: order.id,
                          recipientName: driverName,
                          recipientRole: 'driver',
                          recipientPhone: driverPhone,
                          currentRole: 'customer',
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 4,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: hasPhone
                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                        : (isDark ? Colors.white38 : Colors.grey.shade500),
                    side: BorderSide(
                      color: isDark ? GageTheme.darkBorder : Colors.grey.shade300,
                    ),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                  label: const Text(
                    'Telepon',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _launchCall(driverPhone);
                  },
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
  Widget _buildMerchantAndOrderDetails(OrderModel order, bool isDark) {
    final merchantPhone = (order.merchantPhone ?? '').trim();
    final hasMerchantPhone = merchantPhone.isNotEmpty && merchantPhone != '-';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
        boxShadow: isDark
            ? null
            : const [
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
              GageAvatar(
                imageUrl: order.merchantAvatar,
                fallbackName: order.merchantName,
                radius: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.merchantName,
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.merchantAddress,
                      style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (!order.isTransportService)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chat_bubble_rounded, color: GageTheme.primary, size: 20),
                      tooltip: 'Chat Toko (In-App)',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => InAppChatScreen(
                              orderId: order.id,
                              recipientName: order.merchantName,
                              recipientRole: 'merchant',
                              recipientPhone: merchantPhone,
                              currentRole: 'customer',
                            ),
                          ),
                        );
                      },
                    ),
                    if (hasMerchantPhone)
                      IconButton(
                        icon: Icon(Icons.phone_in_talk_rounded, color: isDark ? Colors.white70 : Colors.black87, size: 19),
                        tooltip: 'Telepon Toko',
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _launchCall(merchantPhone);
                        },
                      ),
                  ],
                ),
            ],
          ),

          if (order.items.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: isDark ? GageTheme.darkBorder : null),
            const SizedBox(height: 14),
            Text(
              'Daftar Pesanan',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 13,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
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
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Text(
                              'Catatan: ${item.notes}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.white60 : Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _currencyFormatter.format(item.subtotal),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],

          const SizedBox(height: 8),
          Divider(height: 1, color: isDark ? GageTheme.darkBorder : null),
          const SizedBox(height: 12),

          _buildCostRow(
            order.isTransportService ? 'Tarif Dasar' : 'Subtotal Belanja',
            _currencyFormatter.format(order.itemsSubtotal),
            isDark: isDark,
          ),
          const SizedBox(height: 6),
          _buildCostRow('Biaya Admin Aplikasi', _currencyFormatter.format(order.adminFee), isDark: isDark),
          const SizedBox(height: 6),
          _buildCostRow(
            order.isTransportService ? 'Biaya Jarak & Opsi' : 'Ongkos Kirim',
            _currencyFormatter.format(order.shippingFee),
            isDark: isDark,
          ),
          if (order.shippingDiscount > 0) ...[
            const SizedBox(height: 6),
            _buildCostRow(
              'Diskon Voucher',
              '- ${_currencyFormatter.format(order.shippingDiscount)}',
              isGreen: true,
              isDark: isDark,
            ),
          ],

          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? GageTheme.darkBorder : null),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Metode: ${order.paymentMethod} (${order.paymentStatus})',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
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

          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkElevated : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
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
                      Text(
                        order.isTransportService ? 'Titik Tujuan' : 'Alamat Pengantaran Anda',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.deliveryAddress,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : Colors.grey.shade700),
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

  Widget _buildCostRow(String title, String value, {bool isGreen = false, bool isDark = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isGreen
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                : (isDark ? Colors.white60 : Colors.grey.shade600),
            fontWeight: isGreen ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isGreen
                ? (isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A))
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }

  /// Dialog Proof of Delivery (PoD) Interaktif
  void _showProofOfDeliveryDialog(OrderModel order, bool isDark) {
    int selectedRating = 5;
    final driverLabel = (order.driverName != null && order.driverName!.trim().isNotEmpty)
        ? order.driverName!.trim()
        : 'Driver GAGE';
    final driverVehicleLabel = [
      if (order.driverVehicle != null && order.driverVehicle!.trim().isNotEmpty)
        order.driverVehicle!.trim(),
      if (order.driverPlate != null && order.driverPlate!.trim().isNotEmpty)
        order.driverPlate!.trim(),
    ].join(' | ');
    final recipientCtrl = TextEditingController(text: 'Diri Sendiri (Pemesan)');
    final feedbackCtrl = TextEditingController();
    final List<String> selectedTags = ['Pengiriman Cepat', 'Pesanan Lengkap & Rapi'];

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
              decoration: BoxDecoration(
                color: isDark ? GageTheme.darkSurface : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.green.withValues(alpha: 0.2) : const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.verified_user_rounded, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Bukti Penerimaan (PoD)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Konfirmasi bahwa pesanan tiba dengan selamat',
                                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Container(
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
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
                                  'Pesanan Diserahkan ke Penerima',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GAGE Digital PoD | Terverifikasi',
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

                    Text(
                      'Nama Penerima',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: recipientCtrl,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? GageTheme.darkElevated : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                        ),
                      ),
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black87),
                    ),

                    const SizedBox(height: 14),

                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Bagaimana pelayanan $driverLabel?',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
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

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Pengiriman Cepat',
                        'Pesanan Lengkap & Rapi',
                        'Kurir Ramah & Sopan',
                        'Tepat Sesuai Alamat',
                      ].map((tag) {
                        final isSelected = selectedTags.contains(tag);
                        return FilterChip(
                          shape: const StadiumBorder(),
                          label: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFF16A34A),
                          backgroundColor: isDark ? GageTheme.darkElevated : const Color(0xFFF1F5F9),
                          onSelected: (val) {
                            HapticFeedback.selectionClick();
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

                    Text(
                      'Catatan / Pesan Tambahan (Opsional)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: feedbackCtrl,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Pengiriman aman dan tepat waktu',
                        hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 12),
                        filled: true,
                        fillColor: isDark ? GageTheme.darkElevated : const Color(0xFFF8FAFC),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                        ),
                      ),
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                    ),

                    const SizedBox(height: 18),

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        if (GageApiClient.useDevSeedData) {
                          setState(() => _manualStep = 5);
                        }
                        _orderProvider?.updateOrderStage(order.id, 'COMPLETED');

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => OrderSuccessReviewScreen(
                              order: order,
                              driverName: driverLabel,
                              driverVehicle: driverVehicleLabel,
                            ),
                          ),
                        );
                      },
                      child: const Text(
                        'Konfirmasi Penerimaan & Beri Penilaian',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
