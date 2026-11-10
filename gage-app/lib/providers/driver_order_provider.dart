import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Model Tawaran Pesanan Driver (Incoming Order Offer)
class DriverOrderOffer {
  final String id;
  final String serviceType; // 'food', 'ride', 'send', 'car', 'shop'
  final String serviceName;
  final String storeName; // Nama toko / resto mitra
  final String customerName;
  final String customerPhone;
  final String pickupAddress; // Alamat jemput / toko
  final LatLng pickupLocation;
  final String dropoffAddress; // Alamat antar pembeli
  final LatLng dropoffLocation;
  final int driverEarnings; // Upah bersih driver (Eksak 80% dari tarif murni OSRM)
  final int totalFare; // Tarif murni delivery OSRM (100%)
  final double distanceKm; // Jarak riil jalan OSRM
  final String paymentMethod; // 'CASH' (COD) or 'GAGEPAY'
  final List<String> orderItems;
  final String notes;

  const DriverOrderOffer({
    required this.id,
    required this.serviceType,
    required this.serviceName,
    required this.storeName,
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

  /// Bagi hasil platform (20% dari tarif murni delivery)
  int get platformFee => totalFare - driverEarnings;

  /// Apakah metode pembayaran ini COD / Tunai
  bool get isCashCod =>
      paymentMethod.toUpperCase().contains('CASH') ||
      paymentMethod.toUpperCase().contains('COD');
}

/// Provider State Order & Workstation Operasional Mitra Pengemudi GAGE Driver
class DriverOrderProvider extends ChangeNotifier {
  // Saklar Siap Narik (Online / Offline Toggle)
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  // Fitur Autobid / Alokasi Otomatis (GoPartner Style)
  bool _isAutoBid = false;
  bool get isAutoBid => _isAutoBid;

  void toggleAutoBid(bool val) {
    _isAutoBid = val;
    notifyListeners();
  }

  // Preferensi tipe order yang diaktifkan driver (All-in-One: ride, car, food, send, shop)
  final Set<String> _activeServices = {'ride', 'car', 'food', 'send', 'shop'};
  Set<String> get activeServices => Set.unmodifiable(_activeServices);

  // Koordinat default driver di pusat Pracimantoro
  LatLng _currentLocation = const LatLng(-8.0967, 110.8406);
  LatLng get currentLocation => _currentLocation;

  // Radar tawaran pesanan masuk saat ini (Incoming Offer Sheet)
  DriverOrderOffer? _incomingOffer;
  DriverOrderOffer? get incomingOffer => _incomingOffer;

  // Timer countdown terima tawaran: Eksak 30 detik
  int _offerCountdown = 30;
  int get offerCountdown => _offerCountdown;
  Timer? _countdownTimer;
  Timer? _autoBidTimer;

  // Pesanan yang sedang aktif dijalankan (Active Trip)
  DriverOrderOffer? _activeTrip;
  DriverOrderOffer? get activeTrip => _activeTrip;

  // Tahap Layar Perjalanan Aktif:
  // 0: Tahap 1 - Menuju Toko (Tombol: "Tiba di Toko")
  // 1: Tahap 2 - Menunggu Makanan / Verifikasi Barang (Tombol: "Mulai Antar ke Pembeli")
  // 2: Tahap 3 - Menuju Pembeli (Tombol: "Pesanan Selesai / Konfirmasi Terima Tunai (COD)")
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

  /// Menghitung upah bersih eksak 80% dari tarif murni OSRM
  static int calculateDriverCleanEarning(int totalFare) {
    return (totalFare * 0.80).round();
  }

  /// Mengambil pesanan riil dari Cloudflare D1 Backend
  Future<void> fetchAvailableOrdersFromCloud() async {
    if (!_isOnline || _activeTrip != null || _incomingOffer != null) return;

    try {
      final list = await GageApiClient.getDriverAvailableOrders();
      if (list.isNotEmpty && _activeTrip == null && _incomingOffer == null && _isOnline) {
        final raw = list.first;
        final rawId = raw['id'] ?? 'ord-${DateTime.now().millisecondsSinceEpoch}';

        final pickupLat = (raw['merchant_lat'] as num?)?.toDouble() ?? -8.0975;
        final pickupLng = (raw['merchant_lng'] as num?)?.toDouble() ?? 110.8415;
        final dropLat = (raw['delivery_lat'] as num?)?.toDouble() ?? -8.1020;
        final dropLng = (raw['delivery_lng'] as num?)?.toDouble() ?? 110.8490;

        final rawItems = raw['items'] as List? ?? [];
        final itemNames = rawItems.map((i) => '${i['quantity']}x ${i['name']}').toList();

        final totalFare = (raw['total_amount'] as num?)?.toInt() ?? 10000;
        // Eksak 80% dari tarif murni
        final driverCleanCut = (raw['driver_cut'] as num?)?.toInt() ?? calculateDriverCleanEarning(totalFare);
        final storeName = raw['merchant_name'] ?? 'Resto Mitra Pracimantoro';
        final pickupAddr = raw['merchant_address'] ?? storeName;

        final offer = DriverOrderOffer(
          id: rawId,
          serviceType: 'food',
          serviceName: 'GAGE Food',
          storeName: storeName,
          customerName: raw['customer_name'] ?? 'Pelanggan GAGE',
          customerPhone: raw['customer_phone'] ?? '081226001000',
          pickupAddress: pickupAddr,
          pickupLocation: LatLng(pickupLat, pickupLng),
          dropoffAddress: raw['delivery_address'] ?? 'Pracimantoro',
          dropoffLocation: LatLng(dropLat, dropLng),
          driverEarnings: driverCleanCut,
          totalFare: totalFare,
          distanceKm: (raw['distance_km'] as num?)?.toDouble() ?? 2.0,
          paymentMethod: raw['payment_method'] ?? 'GAGEPAY',
          orderItems: itemNames.cast<String>(),
          notes: raw['notes'] ?? '',
        );

        showIncomingOffer(offer);
      }
    } catch (_) {}
  }

  /// Saklar Siap Narik (Online / Offline Toggle)
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

  /// Menerima tawaran pesanan masuk (Accept incoming offer)
  Future<bool> acceptIncomingOffer() async {
    if (_incomingOffer == null) return false;

    final offer = _incomingOffer!;
    _countdownTimer?.cancel();
    _incomingOffer = null;

    _activeTrip = offer;
    _tripStep = 0; // Mulai di Tahap 1: Menuju Toko
    notifyListeners();

    // Sinkronisasi status ke backend
    try {
      await GageApiClient.acceptDriverOrder(offer.id, 'drv-syamsul-01');
    } catch (_) {}

    return true;
  }

  /// Menolak tawaran pesanan masuk
  void declineIncomingOffer() {
    _dismissIncomingOffer();
  }

  void _dismissIncomingOffer() {
    _countdownTimer?.cancel();
    _autoBidTimer?.cancel();
    _incomingOffer = null;
    _offerCountdown = 30; // Reset ke 30 detik
    notifyListeners();
  }

  /// Memajukan tahap perjalanan aktif kurir:
  /// - Step 0 (Menuju Toko) -> Step 1 (Tiba di Toko / Verifikasi Barang)
  /// - Step 1 (Verifikasi Barang) -> Step 2 (Mulai Antar ke Pembeli)
  /// - Step 2 (Menuju Pembeli) -> Step 3 (Pesanan Selesai / COD)
  Future<bool> advanceTripStep() async {
    if (_activeTrip == null) return false;

    if (_tripStep < 2) {
      _tripStep += 1;
      notifyListeners();

      final statusMap = ['AT_MERCHANT', 'PICKED_UP'];
      try {
        await GageApiClient.updateDriverOrderStatus(_activeTrip!.id, statusMap[_tripStep - 1]);
      } catch (_) {}
      return false; // Perjalanan belum selesai
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
      'store': trip.storeName,
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

  /// Menampilkan Radar Tawaran Pesanan Masuk dengan Timer Countdown 30 Detik
  void showIncomingOffer(DriverOrderOffer offer) {
    if (!_isOnline || _activeTrip != null) return;
    if (!_activeServices.contains(offer.serviceType)) return;

    _countdownTimer?.cancel();
    _autoBidTimer?.cancel();
    _incomingOffer = offer;
    _offerCountdown = 30; // Eksak 30 detik
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
  void triggerMockIncomingOrder({
    String serviceType = 'food',
    bool isCash = false,
  }) {
    // Tarif murni OSRM: Rp 10.000 untuk jarak 2.5 km
    const totalFare = 10000;
    // Eksak 80% dari tarif murni OSRM = Rp 8.000
    final driverCleanEarnings = calculateDriverCleanEarning(totalFare);

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
      storeName: serviceType == 'food'
          ? 'Mie Ayam & Bakso Pak Man (Pracimantoro)'
          : serviceType == 'ride'
              ? 'Pangkalan Ojek Terminal Pracimantoro'
              : serviceType == 'shop'
                  ? 'Toko Sembako Berkah Pracimantoro'
                  : 'Kios Pupuk Sumber Rejeki',
      customerName: 'Budi Santoso',
      customerPhone: '081226001000',
      pickupAddress: 'Jl. Raya Pracimantoro-Wonogiri KM 1, Pracimantoro',
      pickupLocation: const LatLng(-8.0975, 110.8415),
      dropoffAddress: 'Dusun Sambiroto RT 02/03, Pracimantoro',
      dropoffLocation: const LatLng(-8.1020, 110.8490),
      driverEarnings: driverCleanEarnings,
      totalFare: totalFare,
      distanceKm: 2.5,
      paymentMethod: isCash ? 'CASH' : 'GAGEPAY',
      orderItems: const ['1x Mie Ayam Jumbo Komplit', '1x Es Teh Manis'],
      notes: 'Rumah cat hijau dekat gapura masuk dusun',
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
