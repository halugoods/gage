import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Model Pesanan Dapur & Picking Toko untuk Mitra GAGE Merchant
class MerchantOrder {
  final String id;
  final String orderNumber;
  final String customerName;
  final String customerPhone;
  final String channel; // 'food' (Resto/Dimsum Sewu) | 'shop' (Toko Kelontong/Mart)
  final String stage; // 'NEW' | 'COOKING' | 'READY_FOR_PICKUP' | 'COMPLETED' | 'CANCELLED'
  final DateTime createdAt;
  final List<MerchantOrderItem> items;
  final String? kitchenNote;
  final int totalAmount;
  final MerchantDriverInfo? driver;
  final String deliveryAddress;
  final int autoAcceptSecondsRemaining;

  MerchantOrder({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.channel,
    required this.stage,
    required this.createdAt,
    required this.items,
    this.kitchenNote,
    required this.totalAmount,
    this.driver,
    required this.deliveryAddress,
    this.autoAcceptSecondsRemaining = 180,
  });

  MerchantOrder copyWith({
    String? stage,
    MerchantDriverInfo? driver,
    List<MerchantOrderItem>? items,
    int? autoAcceptSecondsRemaining,
  }) {
    return MerchantOrder(
      id: id,
      orderNumber: orderNumber,
      customerName: customerName,
      customerPhone: customerPhone,
      channel: channel,
      stage: stage ?? this.stage,
      createdAt: createdAt,
      items: items ?? this.items,
      kitchenNote: kitchenNote,
      totalAmount: totalAmount,
      driver: driver ?? this.driver,
      deliveryAddress: deliveryAddress,
      autoAcceptSecondsRemaining: autoAcceptSecondsRemaining ?? this.autoAcceptSecondsRemaining,
    );
  }

  factory MerchantOrder.fromMap(Map<String, dynamic> map) {
    final rawItems = (map['items'] as List?) ?? [];
    final itemsList = rawItems.map((it) => MerchantOrderItem.fromMap(it as Map<String, dynamic>)).toList();

    MerchantDriverInfo? driverInfo;
    if (map['driver'] != null && map['driver'] is Map) {
      driverInfo = MerchantDriverInfo.fromMap(map['driver'] as Map<String, dynamic>);
    } else if (map['driver_name'] != null) {
      driverInfo = MerchantDriverInfo(
        name: map['driver_name'].toString(),
        phone: map['driver_phone']?.toString() ?? '081234567890',
        plateNumber: map['driver_plate']?.toString() ?? 'AD 4120 U',
        pin: map['pickup_pin']?.toString() ?? '1234',
      );
    }

    final rawStage = (map['status'] ?? map['stage'] ?? 'PAID').toString().toUpperCase();
    String normalizedStage = 'NEW';
    if (rawStage == 'PAID' || rawStage == 'NEW' || rawStage == 'PENDING') {
      normalizedStage = 'NEW';
    } else if (rawStage == 'COOKING' || rawStage == 'PREPARING') {
      normalizedStage = 'COOKING';
    } else if (rawStage == 'READY_FOR_PICKUP' || rawStage == 'READY') {
      normalizedStage = 'READY_FOR_PICKUP';
    } else if (rawStage == 'COMPLETED' || rawStage == 'DELIVERED') {
      normalizedStage = 'COMPLETED';
    } else if (rawStage == 'CANCELLED' || rawStage == 'REJECTED') {
      normalizedStage = 'CANCELLED';
    }

    final channel = (map['service_type'] ?? map['channel'] ?? 'food').toString().toLowerCase();

    return MerchantOrder(
      id: map['id']?.toString() ?? 'ord-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: map['order_number']?.toString() ?? map['id']?.toString() ?? 'ORD-9021',
      customerName: map['customer_name']?.toString() ?? 'Pelanggan GAGE',
      customerPhone: map['customer_phone']?.toString() ?? '081987654321',
      channel: channel.contains('shop') || channel.contains('mart') ? 'shop' : 'food',
      stage: normalizedStage,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      items: itemsList,
      kitchenNote: map['notes']?.toString() ?? map['kitchen_note']?.toString(),
      totalAmount: (map['total_amount'] ?? map['subtotal'] ?? 0) is num
          ? (map['total_amount'] ?? map['subtotal'] ?? 0).toInt()
          : int.tryParse((map['total_amount'] ?? map['subtotal'] ?? 0).toString()) ?? 0,
      driver: driverInfo,
      deliveryAddress: map['delivery_address']?.toString() ?? 'Pracimantoro, Wonogiri',
    );
  }
}

class MerchantOrderItem {
  final String name;
  final int quantity;
  final int price;
  final String? variant;
  final bool isPicked; // Untuk flow GAGE SHOP / Mart picking

  MerchantOrderItem({
    required this.name,
    required this.quantity,
    required this.price,
    this.variant,
    this.isPicked = true,
  });

  MerchantOrderItem copyWith({bool? isPicked}) {
    return MerchantOrderItem(
      name: name,
      quantity: quantity,
      price: price,
      variant: variant,
      isPicked: isPicked ?? this.isPicked,
    );
  }

  factory MerchantOrderItem.fromMap(Map<String, dynamic> map) {
    return MerchantOrderItem(
      name: map['name']?.toString() ?? 'Item Pesanan',
      quantity: (map['quantity'] ?? 1) is num ? (map['quantity'] ?? 1).toInt() : int.tryParse(map['quantity'].toString()) ?? 1,
      price: (map['price'] ?? 0) is num ? (map['price'] ?? 0).toInt() : int.tryParse(map['price'].toString()) ?? 0,
      variant: map['variant']?.toString() ?? map['options']?.toString(),
      isPicked: map['is_picked'] == true || map['is_picked'] == 1 || map['is_picked'] == null,
    );
  }
}

class MerchantDriverInfo {
  final String name;
  final String phone;
  final String plateNumber;
  final String pin;
  final String? avatarUrl;

  MerchantDriverInfo({
    required this.name,
    required this.phone,
    required this.plateNumber,
    required this.pin,
    this.avatarUrl,
  });

  factory MerchantDriverInfo.fromMap(Map<String, dynamic> map) {
    return MerchantDriverInfo(
      name: map['name']?.toString() ?? 'Driver GAGE',
      phone: map['phone']?.toString() ?? '081234567890',
      plateNumber: map['plate']?.toString() ?? map['plate_number']?.toString() ?? 'AD 4120 U',
      pin: map['pin']?.toString() ?? '1234',
      avatarUrl: map['avatar_url']?.toString(),
    );
  }
}

/// Provider Utama GAGE Merchant
/// Mengelola alur pesanan (GoBiz Aloha Style), status Buka/Tutup, SPP Thermal Printer, dan Out-of-Stock (OOS)
class MerchantOrderProvider extends ChangeNotifier {
  bool _isOpen = true;
  bool _autoAccept = true;
  bool _printerConnected = true;
  bool _isLoading = false;
  String _selectedStageFilter = 'SEMUA'; // 'SEMUA' | 'PERLU_DISIAPKAN' | 'SIAP_DIAMBIL'

  List<MerchantOrder> _orders = [];
  Timer? _countdownTimer;

  bool get isOpen => _isOpen;
  bool get autoAccept => _autoAccept;
  bool get printerConnected => _printerConnected;
  bool get isLoading => _isLoading;
  String get selectedStageFilter => _selectedStageFilter;

  List<MerchantOrder> get activeOrders {
    final ongoing = _orders.where((o) => o.stage == 'NEW' || o.stage == 'COOKING' || o.stage == 'READY_FOR_PICKUP').toList();
    if (_selectedStageFilter == 'PERLU_DISIAPKAN') {
      return ongoing.where((o) => o.stage == 'NEW' || o.stage == 'COOKING').toList();
    }
    if (_selectedStageFilter == 'SIAP_DIAMBIL') {
      return ongoing.where((o) => o.stage == 'READY_FOR_PICKUP').toList();
    }
    return ongoing;
  }

  List<MerchantOrder> get completedOrders {
    return _orders.where((o) => o.stage == 'COMPLETED').toList();
  }

  List<MerchantOrder> get cancelledOrders {
    return _orders.where((o) => o.stage == 'CANCELLED').toList();
  }

  int get activeOrderCount => _orders.where((o) => o.stage == 'NEW' || o.stage == 'COOKING' || o.stage == 'READY_FOR_PICKUP').length;
  int get newOrderCount => _orders.where((o) => o.stage == 'NEW').length;

  MerchantOrderProvider() {
    _initDefaultMockOrders();
    _startCountdownTicker();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;
      for (int i = 0; i < _orders.length; i++) {
        if (_orders[i].stage == 'NEW' && _orders[i].autoAcceptSecondsRemaining > 0) {
          final nextSec = _orders[i].autoAcceptSecondsRemaining - 1;
          _orders[i] = _orders[i].copyWith(autoAcceptSecondsRemaining: nextSec);
          changed = true;
          if (nextSec == 0 && _autoAccept) {
            // Auto accept trigger
            _orders[i] = _orders[i].copyWith(stage: 'COOKING');
          }
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  void _initDefaultMockOrders() {
    _orders = [
      MerchantOrder(
        id: 'ord-8821',
        orderNumber: '#GF-8821',
        customerName: 'Budi Santoso',
        customerPhone: '081987654321',
        channel: 'food',
        stage: 'COOKING',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
        kitchenNote: 'Sambal dipisah ya mas, jangan terlalu pedas.',
        totalAmount: 35000,
        deliveryAddress: 'Jl. Raya Pracimantoro No. 45',
        driver: MerchantDriverInfo(
          name: 'Mas Budi (Kurir GAGE)',
          phone: '081234567890',
          plateNumber: 'AD 4120 U',
          pin: '8821',
        ),
        items: [
          MerchantOrderItem(name: 'Siomay Dimsum Ayam Udang (4 pcs)', quantity: 2, price: 12000, variant: 'Pedas Sedang'),
          MerchantOrderItem(name: 'Lumpia Kulit Tahu Goreng', quantity: 1, price: 11000, variant: 'Ekstra Saus Sambal'),
        ],
      ),
      MerchantOrder(
        id: 'ord-8822',
        orderNumber: '#GF-8822',
        customerName: 'Galih Pambudi',
        customerPhone: '081876543210',
        channel: 'food',
        stage: 'NEW',
        createdAt: DateTime.now().subtract(const Duration(minutes: 1)),
        kitchenNote: 'Tambahkan saus sambal ekstra banyak ya.',
        totalAmount: 48000,
        deliveryAddress: 'Dusun Gedangan, Pracimantoro',
        autoAcceptSecondsRemaining: 180,
        items: [
          MerchantOrderItem(name: 'Fried Chicken Spicy Komplit', quantity: 2, price: 18000, variant: 'Nasi + Es Teh Manis'),
          MerchantOrderItem(name: 'Medium French Fries', quantity: 1, price: 12000),
        ],
      ),
      MerchantOrder(
        id: 'ord-3304',
        orderNumber: '#GS-3304',
        customerName: 'Ibu Ratna',
        customerPhone: '081765432109',
        channel: 'shop',
        stage: 'COOKING',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        totalAmount: 95000,
        deliveryAddress: 'Pasar Pracimantoro Kios No. 12',
        driver: MerchantDriverInfo(
          name: 'Mas Joko (Kurir GAGE)',
          phone: '081345678901',
          plateNumber: 'AD 5532 WZ',
          pin: '3304',
        ),
        items: [
          MerchantOrderItem(name: 'Beras Sania Premium 5kg', quantity: 1, price: 68000, isPicked: true),
          MerchantOrderItem(name: 'Minyak Goreng Bimoli 2L', quantity: 1, price: 27000, isPicked: false),
        ],
      ),
      MerchantOrder(
        id: 'ord-8799',
        orderNumber: '#GF-8799',
        customerName: 'Siti Aminah',
        customerPhone: '081654321098',
        channel: 'food',
        stage: 'COMPLETED',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        totalAmount: 24000,
        deliveryAddress: 'Jl. Wonogiri - Pracimantoro KM 2',
        driver: MerchantDriverInfo(
          name: 'Mas Agus',
          phone: '081223344556',
          plateNumber: 'AD 9911 QA',
          pin: '8799',
        ),
        items: [
          MerchantOrderItem(name: 'Dimsum Mozzarella Lumer (4 pcs)', quantity: 2, price: 12000),
        ],
      ),
    ];
  }

  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      final remote = await GageApiClient.getMerchantOrders('m-dimsum-sewu');
      if (remote.isNotEmpty) {
        final parsed = remote.map((m) => MerchantOrder.fromMap(m)).toList();
        // Pertahankan mock order jika remote kosong / mock blend
        for (final p in parsed) {
          final idx = _orders.indexWhere((o) => o.id == p.id || o.orderNumber == p.orderNumber);
          if (idx >= 0) {
            _orders[idx] = p;
          } else {
            _orders.insert(0, p);
          }
        }
      }
    } catch (_) {}

    _isLoading = false;
    notifyListeners();
  }

  void setStageFilter(String filter) {
    HapticFeedback.selectionClick();
    _selectedStageFilter = filter;
    notifyListeners();
  }

  void toggleStoreOpen(bool val) {
    HapticFeedback.mediumImpact();
    _isOpen = val;
    notifyListeners();
  }

  void toggleAutoAccept(bool val) {
    HapticFeedback.lightImpact();
    _autoAccept = val;
    notifyListeners();
  }

  void togglePrinter(bool val) {
    HapticFeedback.lightImpact();
    _printerConnected = val;
    notifyListeners();
  }

  Future<void> acceptOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(stage: 'COOKING');
      notifyListeners();
      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'COOKING');
      } catch (_) {}
    }
  }

  Future<void> rejectOrder(String orderId, String reason) async {
    HapticFeedback.lightImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(stage: 'CANCELLED');
      notifyListeners();
      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'CANCELLED');
      } catch (_) {}
    }
  }

  Future<void> markReadyForPickup(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(stage: 'READY_FOR_PICKUP');
      notifyListeners();
      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'READY_FOR_PICKUP');
      } catch (_) {}
    }
  }

  Future<void> completeOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(stage: 'COMPLETED');
      notifyListeners();
      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'COMPLETED');
      } catch (_) {}
    }
  }

  void togglePickingItem(String orderId, int itemIndex) {
    HapticFeedback.lightImpact();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx >= 0) {
      final items = List<MerchantOrderItem>.from(_orders[orderIdx].items);
      if (itemIndex >= 0 && itemIndex < items.length) {
        items[itemIndex] = items[itemIndex].copyWith(isPicked: !items[itemIndex].isPicked);
        _orders[orderIdx] = _orders[orderIdx].copyWith(items: items);
        notifyListeners();
      }
    }
  }

  void triggerMockIncomingOrder() {
    HapticFeedback.vibrate();
    final newId = 'ord-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newOrder = MerchantOrder(
      id: newId,
      orderNumber: '#GF-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      customerName: 'Pelanggan Baru Pracimantoro',
      customerPhone: '081234567899',
      channel: 'food',
      stage: 'NEW',
      createdAt: DateTime.now(),
      kitchenNote: 'Mohon dibungkus plastik rangkap ya mas.',
      totalAmount: 28000,
      deliveryAddress: 'Jl. Lintas Selatan Pracimantoro',
      autoAcceptSecondsRemaining: 180,
      items: [
        MerchantOrderItem(name: 'Dimsum Sewu Spesial Campur (6 pcs)', quantity: 2, price: 14000, variant: 'Ekstra Pedas'),
      ],
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }
}
