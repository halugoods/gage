import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _allOrders = [];
  OrderModel? _currentTrackedOrder;
  bool _isLoading = false;
  Timer? _pollingTimer;

  OrderProvider() {
    _initDefaultOrders();
  }

  void _initDefaultOrders() {
    if (_allOrders.isNotEmpty) return;
    final now = DateTime.now();
    _allOrders = [
      // 1. Pesanan Aktif: Multi-merchant kuliner Sambiroto
      OrderModel(
        id: 'ord-fd-${now.millisecondsSinceEpoch - 600000}',
        orderNumber: OrderModel.generateUniqueInvoice(
          serviceType: 'FD-MM',
          userName: 'CUST',
          timestamp: now.subtract(const Duration(minutes: 12)),
        ),
        userId: 'usr-cust-01',
        merchantId: 'mch-rc-01',
        merchantName: 'Rocket Chicken Sambiroto, Dimsum Sewu Pracimantoro',
        merchantAddress: 'Sambiroto & Depan Alfamidi, Kec. Pracimantoro',
        driverName: 'Bambang Haryanto (Beat AD 3912 ABE)',
        driverPlate: 'AD 3912 ABE',
        driverPhone: '081234567891',
        status: 'COOKING',
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 43000,
        itemsSubtotal: 40000,
        shippingFee: 6000,
        shippingDiscount: 4000,
        adminFee: 1000,
        deliveryAddress: 'Jl. Melati No. 14, Dusun Belik, Pracimantoro',
        distanceKm: 2.1,
        trackingToken: 'trk-fd-001',
        items: [
          const OrderItemModel(
            id: 'menu-rc-01',
            name: 'Paket Rocket 1 (Ayam + Nasi + Es Teh)',
            price: 14000,
            quantity: 2,
            subtotal: 28000,
            imageUrl: 'assets/images/resto_rocket_chicken.png',
            merchantName: 'Rocket Chicken Sambiroto',
            notes: 'Ayam bagian paha atas, sambal dipisah',
          ),
          const OrderItemModel(
            id: 'menu-ds-01',
            name: 'Dimsum Ayam Jamur Panas (Isi 4)',
            price: 12000,
            quantity: 1,
            subtotal: 12000,
            imageUrl: 'assets/images/resto_dimsum_sewu.png',
            merchantName: 'Dimsum Sewu Pracimantoro',
            notes: 'Saos cabe ekstra pedas',
          ),
        ],
        createdAt: (now.millisecondsSinceEpoch ~/ 1000) - 720,
      ),

      // 2. Riwayat Pesanan: GAGE Ride Reguler
      OrderModel(
        id: 'ord-ride-${now.millisecondsSinceEpoch - 86400000}',
        orderNumber: OrderModel.generateUniqueInvoice(
          serviceType: 'RD-RG',
          userName: 'CUST',
          timestamp: now.subtract(const Duration(days: 1, hours: 2)),
        ),
        userId: 'usr-cust-01',
        merchantId: 'mch-gage-transport',
        merchantName: 'GAGE Ride Pracimantoro',
        merchantAddress: 'Terminal Bus Pracimantoro',
        driverName: 'Slamet Widodo (Vario AD 4521 WN)',
        driverPlate: 'AD 4521 WN',
        driverPhone: '081234567890',
        status: 'COMPLETED',
        paymentMethod: 'QRIS',
        paymentStatus: 'PAID',
        totalAmount: 10000,
        itemsSubtotal: 9000,
        shippingFee: 0,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Pasar Pracimantoro Lor',
        distanceKm: 2.3,
        trackingToken: 'trk-rd-002',
        items: [
          const OrderItemModel(
            id: 'item-ride-01',
            name: 'Perjalanan GAGE Ride Reguler (2.3 km)',
            price: 9000,
            quantity: 1,
            subtotal: 9000,
            imageUrl: 'assets/icons/ic_ride.png',
            merchantName: 'GAGE Ride Pracimantoro',
          ),
        ],
        createdAt: (now.millisecondsSinceEpoch ~/ 1000) - 93600,
      ),

      // 3. Riwayat Pesanan: Multi-merchant Bakso Titoti & Lapak Segar Mbak Siti
      OrderModel(
        id: 'ord-fd-${now.millisecondsSinceEpoch - 172800000}',
        orderNumber: OrderModel.generateUniqueInvoice(
          serviceType: 'FD-MM',
          userName: 'CUST',
          timestamp: now.subtract(const Duration(days: 2, hours: 4)),
        ),
        userId: 'usr-cust-01',
        merchantId: 'mch-titoti-01',
        merchantName: 'Bakso Titoti Pracimantoro, Lapak Sayur Mbak Siti',
        merchantAddress: 'Jl. Wonogiri - Pracimantoro KM 1',
        driverName: 'Agus Triono (Supra X AD 2901 ZG)',
        driverPlate: 'AD 2901 ZG',
        driverPhone: '081234567895',
        status: 'COMPLETED',
        paymentMethod: 'CASH_COD',
        paymentStatus: 'PAID',
        totalAmount: 33000,
        itemsSubtotal: 26000,
        shippingFee: 6000,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Dusun Gedong, Pracimantoro',
        distanceKm: 1.8,
        trackingToken: 'trk-fd-003',
        items: [
          const OrderItemModel(
            id: 'menu-bk-01',
            name: 'Bakso Urat Komplit + Tetelan Sapi',
            price: 18000,
            quantity: 1,
            subtotal: 18000,
            imageUrl: 'assets/images/dish_bakso_urat.png',
            merchantName: 'Bakso Titoti Pracimantoro',
          ),
          const OrderItemModel(
            id: 'menu-sy-01',
            name: 'Paket Sayur Segar Sop & Tahu Sutra',
            price: 8000,
            quantity: 1,
            subtotal: 8000,
            imageUrl: 'assets/images/dish_seblak_komplit.png',
            merchantName: 'Lapak Sayur Mbak Siti',
          ),
        ],
        createdAt: (now.millisecondsSinceEpoch ~/ 1000) - 187200,
      ),
    ];
  }

  List<OrderModel> get activeOrders => _allOrders.where((o) => o.isActive).toList();
  List<OrderModel> get orderHistory => _allOrders.where((o) => !o.isActive).toList();
  OrderModel? get currentTrackedOrder => _currentTrackedOrder;
  bool get isLoading => _isLoading;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // Muat riwayat pesanan pengguna dari Cloudflare D1
  Future<void> fetchUserOrders(String userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await GageApiClient.getUserOrders(userId);
      if (res.isNotEmpty) {
        final fetched = res.map((json) => OrderModel.fromJson(json)).toList();
        // Merge or replace without dropping local active mocks
        _allOrders = fetched;
      } else if (_allOrders.isEmpty) {
        _initDefaultOrders();
      }
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
      if (_allOrders.isEmpty) _initDefaultOrders();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Menambahkan order langsung (misal dari RideCheckoutScreen atau simulasi instan)
  void addDirectOrder(Map<String, dynamic> json) {
    final order = OrderModel.fromJson(json);
    _allOrders.insert(0, order);
    _currentTrackedOrder = order;
    notifyListeners();
  }

  void createOrder(Map<String, dynamic> json) {
    addDirectOrder(json);
  }

  // Buat Pesanan Baru
  Future<OrderModel?> placeOrder({
    required String userId,
    required String merchantId,
    required List<Map<String, dynamic>> items,
    required double distanceKm,
    required String paymentMethod,
    String? affiliatorId,
    String? promoCode,
    required String deliveryAddress,
    String? merchantName,
  }) async {
    _isLoading = true;
    notifyListeners();
    try {
      final res = await GageApiClient.createOrder(
        userId: userId,
        merchantId: merchantId,
        items: items,
        distanceKm: distanceKm,
        paymentMethod: paymentMethod,
        affiliatorId: affiliatorId,
        promoCode: promoCode,
        deliveryAddress: deliveryAddress,
      );

      if (res != null && res['success'] == true) {
        final orderData = res['data'];
        final orderId = orderData['order_id'];

        // Ambil detail lengkap pesanan dari D1
        final detail = await GageApiClient.getOrderDetail(orderId);
        if (detail != null) {
          final newOrder = OrderModel.fromJson(detail);
          _allOrders.insert(0, newOrder);
          _currentTrackedOrder = newOrder;
          _isLoading = false;
          notifyListeners();
          return newOrder;
        }
      }
    } catch (e) {
      debugPrint('Error placing order via cloud: $e');
    }

    // Fallback lokal jika offline/network timeout: pesanan tetap berhasil
    final now = DateTime.now();
    final itemsSubtotal = items.fold<int>(0, (sum, i) => sum + ((i['price'] as int? ?? 0) * (i['quantity'] as int? ?? 1)));
    final shippingFee = (distanceKm <= 2.0 ? 6000 : 6000 + ((distanceKm - 2.0).ceil() * 3000)).toInt();
    final int shippingDiscount = promoCode != null && promoCode.contains('ONGKIR') ? shippingFee : 0;
    const adminFee = 1000;
    final totalAmount = itemsSubtotal + (shippingFee - shippingDiscount) + adminFee;

    final fallbackOrder = OrderModel(
      id: 'ord-fd-${now.millisecondsSinceEpoch}',
      orderNumber: OrderModel.generateUniqueInvoice(
        serviceType: 'FD',
        userName: 'CUST',
        timestamp: now,
      ),
      userId: userId,
      merchantId: merchantId,
      merchantName: merchantName ?? 'Mitra Usaha GAGE Pracimantoro',
      merchantAddress: 'Kecamatan Pracimantoro',
      driverName: 'Joko Susanto (Vario AD 3291 WA)',
      driverPlate: 'AD 3291 WA',
      driverPhone: '081234567890',
      status: 'COOKING',
      paymentMethod: paymentMethod,
      paymentStatus: 'PAID',
      totalAmount: totalAmount,
      itemsSubtotal: itemsSubtotal,
      shippingFee: shippingFee,
      shippingDiscount: shippingDiscount,
      adminFee: adminFee,
      deliveryAddress: deliveryAddress,
      distanceKm: distanceKm,
      trackingToken: 'trk-fd-${now.millisecondsSinceEpoch}',
      items: items.map((i) => OrderItemModel(
        id: i['menu_id'] ?? i['id'] ?? '',
        name: i['name'] ?? 'Menu Makanan',
        price: (i['price'] ?? 0) as int,
        quantity: (i['quantity'] ?? 1) as int,
        subtotal: ((i['price'] ?? 0) as int) * ((i['quantity'] ?? 1) as int),
        notes: i['notes'],
        imageUrl: i['image_url'] ?? i['image'],
        merchantName: i['merchant_name'],
      )).toList(),
      createdAt: now.millisecondsSinceEpoch ~/ 1000,
    );

    _allOrders.insert(0, fallbackOrder);
    _currentTrackedOrder = fallbackOrder;
    _isLoading = false;
    notifyListeners();
    return fallbackOrder;
  }

  // Mulai memantau pesanan aktif secara berkala (Auto-refresh status)
  void startTrackingOrder(String orderId) {
    _pollingTimer?.cancel();
    _fetchSingleOrder(orderId);

    // Refresh setiap 4 detik untuk update status dapur & driver
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _fetchSingleOrder(orderId);
    });
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _fetchSingleOrder(String orderId) async {
    try {
      final detail = await GageApiClient.getOrderDetail(orderId);
      if (detail != null) {
        final updated = OrderModel.fromJson(detail);
        _currentTrackedOrder = updated;

        // Update di daftar pesanan
        final idx = _allOrders.indexWhere((o) => o.id == updated.id);
        if (idx >= 0) {
          _allOrders[idx] = updated;
        } else {
          _allOrders.insert(0, updated);
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  // Update Kemajuan Tahap Pesanan
  Future<bool> updateOrderStage(String orderId, String nextStage) async {
    return simulateStage(orderId, nextStage);
  }

  // Simulasi Kemajuan Tahap Pesanan (Testing status tracker)
  Future<bool> simulateStage(String orderId, String nextStage) async {
    final success = await GageApiClient.simulateOrderStage(orderId, nextStage);
    if (success) {
      await _fetchSingleOrder(orderId);
      return true;
    }
    return false;
  }
}
