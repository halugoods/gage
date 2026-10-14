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
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/features/order/presentation/order_tracking_screen.dart';

class SendBookingScreen extends StatefulWidget {
  const SendBookingScreen({super.key});

  @override
  State<SendBookingScreen> createState() => _SendBookingScreenState();
}

class _SendBookingScreenState extends State<SendBookingScreen> {
  final MapController _mapController = MapController();

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
  LatLng? _recipientLatLng = const LatLng(-8.0845, 110.8540);
  List<LatLng> _routePoints = [];
  double _distanceKm = 2.4;
  bool _isLoadingRoute = false;

  String _selectedPackageType = 'Barang Dagangan';
  String _selectedWeight = '1 - 5 kg';
  String _serviceType = 'instant'; // 'instant' (Rp 5.000) or 'sameday' (Rp 4.000)
  String _paymentMethod = 'gagepay';
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
        _updateRoute();
      }
    } catch (_) {}
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
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _senderLatLng = latLng;
          _senderAddressCtrl.text = title.isNotEmpty ? title : fullAddress;
        });
        _updateRoute();
      },
    );
  }

  void _pickRecipientAddress() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Titik Antar (Penerima)',
      initialLocation: _recipientLatLng ?? _senderLatLng,
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _recipientLatLng = latLng;
          _recipientAddressCtrl.text = title.isNotEmpty ? title : fullAddress;
        });
        _updateRoute();
      },
    );
  }

  int _calculateFare() {
    return _serviceType == 'instant' ? 5000 : 4000;
  }

  void _bookCourier() {
    final fare = _calculateFare();
    if (_paymentMethod == 'gagepay') {
      final wallet = context.read<WalletProvider>();
      if (wallet.balance < fare) {
        final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
        GageToast.show(
          context,
          'Saldo GAGEPay (${currencyFormatter.format(wallet.balance)}) tidak mencukupi ongkir!',
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
        'total_amount': fare,
        'items_subtotal': fare,
        'shipping_fee': 0,
        'shipping_discount': 0,
        'admin_fee': 0,
        'delivery_address': '${_recipientAddressCtrl.text} (${_recipientNameCtrl.text} - ${_recipientPhoneCtrl.text})',
        'distance_km': _distanceKm,
        'tracking_token': 'trk-send-${now.millisecondsSinceEpoch}',
        'items': [
          {
            'id': 'item-send-01',
            'name': 'Kirim $_selectedPackageType ($_selectedWeight)',
            'price': fare,
            'quantity': 1,
            'subtotal': fare,
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
    final fare = _calculateFare();

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      body: Stack(
        children: [
          // 1. Retina HD Map Layer
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _senderLatLng,
              initialZoom: 14.5,
              minZoom: 11.0,
              maxZoom: 21.0,
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
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 6.0,
                      color: GageTheme.primary,
                    ),
                  ],
                ),
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

                  // Marker 3D Courier Scooter on Route
                  if (_routePoints.length >= 2)
                    Marker(
                      point: _routePoints[_routePoints.length ~/ 2],
                      width: 46,
                      height: 46,
                      child: Image.asset(
                        'assets/images/gage_ride_3d.png',
                        fit: BoxFit.contain,
                        errorBuilder: (c, e, s) => Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                          ),
                          child: const Icon(Icons.two_wheeler_rounded, color: GageTheme.primary, size: 20),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),

          // 2. Floating Header: Back Button & Title Badge
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.pop(context),
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
                        child: const Icon(Icons.local_shipping_rounded, color: GageTheme.primary, size: 16),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'GAGE Send',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _isLoadingRoute ? 'Memuat...' : '${_distanceKm.toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF15803D)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Recenter FAB
          Positioned(
            right: 16,
            bottom: 350,
            child: InkWell(
              onTap: _fitRoute,
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

          // 4. Floating iOS Inset Grouped Booking Sheet
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
                    const SizedBox(height: 12),

                    // Inset Group 1: Rute Titik Jemput & Antar
                    _buildSectionHeader('RUTE PENGIRIMAN', isDark),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: _pickSenderAddress,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Titik Jemput (Pengirim)',
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          _senderAddressCtrl.text,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit_location_alt_rounded, size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, thickness: 0.8, color: isDark ? Colors.white10 : Colors.grey.shade200),
                          InkWell(
                            onTap: _pickRecipientAddress,
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFE52320),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Titik Antar (Penerima)',
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.w600),
                                        ),
                                        Text(
                                          _recipientAddressCtrl.text,
                                          style: TextStyle(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.edit_location_alt_rounded, size: 18, color: Colors.grey),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Inset Group 2: Detail Penerima & Paket
                    _buildSectionHeader('INFORMASI PENERIMA & BARANG', isDark),
                    Container(
                      padding: const EdgeInsets.all(12),
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
                                child: TextField(
                                  controller: _recipientNameCtrl,
                                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'Nama Penerima',
                                    labelStyle: const TextStyle(fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextField(
                                  controller: _recipientPhoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : Colors.black87),
                                  decoration: InputDecoration(
                                    labelText: 'No. WhatsApp',
                                    labelStyle: const TextStyle(fontSize: 11),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
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
                          const SizedBox(height: 8),
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
                          const SizedBox(height: 10),
                          TextField(
                            controller: _packageDescCtrl,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Deskripsi barang / catatan pengantaran kurir...',
                              hintStyle: const TextStyle(fontSize: 11.5, color: Colors.grey),
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Inset Group 3: Pilihan Layanan (Instant vs Sameday)
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
                                  const Text(
                                    'Rp 5.000',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: GageTheme.primary),
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
                                  const Text(
                                    'Rp 4.000',
                                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Inset Group 4: Metode Pembayaran
                    _buildSectionHeader('METODE PEMBAYARAN', isDark),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark ? Colors.white10 : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => setState(() => _paymentMethod = 'gagepay'),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFF0284C7), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'GAGEPay Saldo',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    currencyFormatter.format(wallet.balance),
                                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _paymentMethod == 'gagepay'
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: _paymentMethod == 'gagepay' ? GageTheme.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Divider(height: 1, thickness: 0.8, color: isDark ? Colors.white10 : Colors.grey.shade200),
                          InkWell(
                            onTap: () => setState(() => _paymentMethod = 'cash'),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_rounded, color: Color(0xFF16A34A), size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Tunai ke Kurir (COD)',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    _paymentMethod == 'cash'
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_off_rounded,
                                    size: 18,
                                    color: _paymentMethod == 'cash' ? GageTheme.primary : Colors.grey,
                                  ),
                                ],
                              ),
                            ),
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
                                  const Icon(Icons.local_shipping_rounded, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Panggil Kurir GAGE • ${currencyFormatter.format(fare)}',
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
