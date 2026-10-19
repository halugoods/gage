import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Model Tawaran Order Driver (Incoming Order Offer)
class DriverOrderOffer {
  final String id;
  final String serviceType; // 'ride', 'car', 'food', 'send', 'shop'
  final String serviceName;
  final String customerName;
  final String customerPhone;
  final String pickupAddress;
  final LatLng pickupLocation;
  final String dropoffAddress;
  final LatLng dropoffLocation;
  final int driverEarnings; // Ongkir bersih driver
  final int totalFare;
  final double distanceKm;
  final String paymentMethod; // 'CASH' or 'GAGEPAY'
  final List<String> orderItems;
  final String notes;

  const DriverOrderOffer({
    required this.id,
    required this.serviceType,
    required this.serviceName,
    required this.customerName,
    required this.customerPhone,
    required this.pickupAddress,
    required this.pickupLocation,
    required this.dropoffAddress,
    required this.dropoffLocation,
    required this.driverEarnings,
    required this.totalFare,
    required this.distanceKm,
    required this.paymentMethod,
    this.orderItems = const [],
    this.notes = '',
  });
}

/// Provider State Order & Operasional Mitra Pengemudi GAGE Driver
class DriverOrderProvider extends ChangeNotifier {
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Fitur Autobid / Alokasi Otomatis (GoPartner Style)
  bool _isAutoBid = false;
  bool get isAutoBid => _isAutoBid;

  void toggleAutoBid(bool val) {
    _isAutoBid = val;
    notifyListeners();
  }

  // Preferensi tipe order yang diaktifkan driver (All-in-One)
  final Set<String> _activeServices = {'ride', 'car', 'food', 'send', 'shop'};
  Set<String> get activeServices => Set.unmodifiable(_activeServices);

  // Koordinat default driver di pusat Pracimantoro
  LatLng _currentLocation = const LatLng(-8.0967, 110.8406);
  LatLng get currentLocation => _currentLocation;

  // Tawaran orderan masuk saat ini (Pop-up Gojek/Grab style)
  DriverOrderOffer? _incomingOffer;
  DriverOrderOffer? get incomingOffer => _incomingOffer;

  int _offerCountdown = 20; // 20 detik countdown
  int get offerCountdown => _offerCountdown;
  Timer? _countdownTimer;
  Timer? _autoBidTimer;

  // Pesanan yang sedang aktif dijalankan
  DriverOrderOffer? _activeTrip;
  DriverOrderOffer? get activeTrip => _activeTrip;

  // Tahap order aktif:
  // 0: Menuju Titik Jemput / Resto
  // 1: Tiba di Titik / Resto
  // 2: Pesanan Diambil / Sedang Antar ke Tujuan
  // 3: Selesai
  int _tripStep = 0;
  int get tripStep => _tripStep;

  // Riwayat order selesai dalam sesi hari ini
  final List<Map<String, dynamic>> _completedTrips = [];
  List<Map<String, dynamic>> get completedTrips => List.unmodifiable(_completedTrips);

  Timer? _cloudPollTimer;

  DriverOrderProvider() {
    _startCloudOrderPolling();
  }

  void _startCloudOrderPolling() {
    _cloudPollTimer?.cancel();
    _cloudPollTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      if (!_isOnline || _activeTrip != null || _incomingOffer != null) return;
      await fetchAvailableOrdersFromCloud();
    });
  }

  /// Mengambil pesanan riil dari Cloudflare D1 Backend
  Future<void> fetchAvailableOrdersFromCloud() async {
    if (!_isOnline || _activeTrip != null || _incomingOffer != null) return;

    try {
      final list = await GageApiClient.getDriverAvailableOrders();
      if (list.isNotEmpty && _activeTrip == null && _incomingOffer == null && _isOnline) {
        final raw = list.first;
        final rawId = raw['id'] ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';

        // Parse koordinat jemput & antar
        final pickupLat = (raw['merchant_lat'] as num?)?.toDouble() ?? -8.0975;
        final pickupLng = (raw['merchant_lng'] as num?)?.toDouble() ?? 110.8415;
        final dropLat = (raw['delivery_lat'] as num?)?.toDouble() ?? -8.1020;
        final dropLng = (raw['delivery_lng'] as num?)?.toDouble() ?? 110.8490;

        final rawItems = raw['items'] as List? ?? [];
        final itemNames = rawItems.map((i) => '${i['quantity']}x ${i['name']}').toList();

        final offer = DriverOrderOffer(
          id: rawId,
          serviceType: 'food',
          serviceName: 'GAGE Food',
          customerName: raw['customer_name'] ?? 'Pelanggan GAGE',
          customerPhone: raw['customer_phone'] ?? '081234567890',
          pickupAddress: raw['merchant_name'] ?? raw['merchant_address'] ?? 'Resto Mitra Pracimantoro',
          pickupLocation: LatLng(pickupLat, pickupLng),
          dropoffAddress: raw['delivery_address'] ?? 'Pracimantoro',
          dropoffLocation: LatLng(dropLat, dropLng),
          driverEarnings: (raw['driver_cut'] as num?)?.toInt() ?? 8000,
          totalFare: (raw['total_amount'] as num?)?.toInt() ?? 15000,
          distanceKm: (raw['distance_km'] as num?)?.toDouble() ?? 2.0,
          paymentMethod: raw['payment_method'] ?? 'GAGEPAY',
          orderItems: itemNames.cast<String>(),
          notes: raw['notes'] ?? '',
        );

        showIncomingOffer(offer);
      }
    } catch (_) {}
  }

  void toggleOnline(bool val) {
    _isOnline = val;
    if (!_isOnline) {
      _dismissIncomingOffer();
    } else {
      fetchAvailableOrdersFromCloud();
    }
    notifyListeners();
  }

  void toggleService(String serviceType) {
    if (_activeServices.contains(serviceType)) {
      if (_activeServices.length > 1) {
        _activeServices.remove(serviceType);
      }
    } else {
      _activeServices.add(serviceType);
    }
    notifyListeners();
  }

  void updateLocation(LatLng newLoc) {
    _currentLocation = newLoc;
    notifyListeners();
  }

  /// Menerima orderan pop-up
  Future<bool> acceptIncomingOffer() async {
    if (_incomingOffer == null) return false;

    final offer = _incomingOffer!;
    _countdownTimer?.cancel();
    _incomingOffer = null;

    _activeTrip = offer;
    _tripStep = 0;
    notifyListeners();

    // Sync status ke cloud jika terkoneksi
    try {
      await GageApiClient.acceptDriverOrder(offer.id, 'drv-syamsul-01');
    } catch (_) {}

    return true;
  }

  /// Menolak orderan pop-up atau timeout
  void declineIncomingOffer() {
    _dismissIncomingOffer();
  }

  void _dismissIncomingOffer() {
    _countdownTimer?.cancel();
    _autoBidTimer?.cancel();
    _incomingOffer = null;
    _offerCountdown = 20;
    notifyListeners();
  }

  /// Memajukan tahap orderan aktif
  Future<bool> advanceTripStep() async {
    if (_activeTrip == null) return false;

    if (_tripStep < 2) {
      _tripStep += 1;
      notifyListeners();

      // Sync ke backend
      final statusMap = ['AT_MERCHANT', 'PICKED_UP'];
      try {
        await GageApiClient.updateDriverOrderStatus(_activeTrip!.id, statusMap[_tripStep - 1]);
      } catch (_) {}
      return false; // Belum selesai
    } else {
      // Step 2 -> Step 3 (Selesai Trip)
      _completeCurrentTrip();
      return true; // Selesai
    }
  }

  void _completeCurrentTrip() {
    if (_activeTrip == null) return;

    final trip = _activeTrip!;
    final now = DateTime.now();
    _completedTrips.insert(0, {
      'id': trip.id,
      'service': trip.serviceName,
      'serviceType': trip.serviceType,
      'customer': trip.customerName,
      'earnings': trip.driverEarnings,
      'distance': trip.distanceKm,
      'time': '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
      'paymentMethod': trip.paymentMethod,
    });

    try {
      GageApiClient.updateDriverOrderStatus(trip.id, 'COMPLETED');
    } catch (_) {}

    _activeTrip = null;
    _tripStep = 0;
    notifyListeners();
  }

  /// Menampilkan tawaran order masuk dengan countdown timer
  void showIncomingOffer(DriverOrderOffer offer) {
    if (!_isOnline || _activeTrip != null) return;
    if (!_activeServices.contains(offer.serviceType)) return;

    _countdownTimer?.cancel();
    _autoBidTimer?.cancel();
    _incomingOffer = offer;
    _offerCountdown = 20;
    notifyListeners();

    // Jika Autobid aktif, otomatis terima orderan dalam 1.2 detik (GoPartner Style)
    if (_isAutoBid) {
      _autoBidTimer = Timer(const Duration(milliseconds: 1200), () {
        if (_incomingOffer?.id == offer.id) {
          acceptIncomingOffer();
        }
      });
    }

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_offerCountdown > 1) {
        _offerCountdown -= 1;
        notifyListeners();
      } else {
        _dismissIncomingOffer();
      }
    });
  }

  /// Simulasi orderan masuk untuk testing unit test & demo offline
  void triggerMockIncomingOrder({String serviceType = 'food'}) {
    final offer = DriverOrderOffer(
      id: 'mock-${DateTime.now().millisecondsSinceEpoch}',
      serviceType: serviceType,
      serviceName: serviceType == 'food'
          ? 'GAGE Food'
          : serviceType == 'ride'
              ? 'GAGE Ride'
              : serviceType == 'car'
                  ? 'GAGE Car'
                  : serviceType == 'shop'
                      ? 'GAGE Shop'
                      : 'GAGE Send',
      customerName: 'Budi Santoso',
      customerPhone: '081234567890',
      pickupAddress: 'Resto Mitra Pracimantoro',
      pickupLocation: const LatLng(-8.0975, 110.8415),
      dropoffAddress: 'Pasar Pracimantoro',
      dropoffLocation: const LatLng(-8.1020, 110.8490),
      driverEarnings: 8000,
      totalFare: 10000,
      distanceKm: 2.0,
      paymentMethod: 'GAGEPAY',
      orderItems: const ['1x Nasi Goreng Spesial'],
      notes: 'Dekat gapura masuk',
    );
    showIncomingOffer(offer);
  }

  @override
  void dispose() {
    _cloudPollTimer?.cancel();
    _countdownTimer?.cancel();
    _autoBidTimer?.cancel();
    super.dispose();
  }
}
