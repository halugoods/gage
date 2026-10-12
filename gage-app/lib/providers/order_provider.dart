import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/data/models/order_model.dart';

class OrderProvider extends ChangeNotifier {
  List<OrderModel> _allOrders = [];
  OrderModel? _currentTrackedOrder;
  bool _isLoading = false;
  Timer? _pollingTimer;

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
      _allOrders = res.map((json) => OrderModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching user orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
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
      debugPrint('Error placing order: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
    return null;
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
