import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/gage_audio_service.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/data/models/order_model.dart';
export 'package:gage_app/data/models/order_model.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';

/// Provider Utama GAGE Merchant
/// Mengelola alur pesanan (GoBiz Aloha Style), status Buka/Tutup, SPP Thermal Printer, dan Out-of-Stock (OOS)
class MerchantOrderProvider extends ChangeNotifier {
  bool _isOpen = true;
  bool _isBusy = false;
  DateTime? _busyUntil;
  String? _busyReason;
  bool _autoAccept = true;
  bool _printerConnected = true;
  bool _isLoading = false;
  int _cookingTime = 15; // Estimasi waktu masak (menit)
  double _acceptanceScore = 98.0; // Poin Performa Penerimaan Mitra (%)
  int _dailyAcceptedCount = 42;
  int _dailyRejectedCount = 1;
  String _selectedStageFilter = 'SEMUA'; // 'SEMUA' | 'NEW' | 'COOKING' | 'READY_FOR_PICKUP'

  // Pengaturan Audio Alarm Dapur Bising & Thermal Multi-Rangkap
  bool _soundAlarmEnabled = true;
  bool _autoPrintOnAccept = true;
  int _receiptCopies = 2; // Default 2 rangkap: 1x Dapur, 1x Kurir/Pelanggan
  String _preferredPaperSize = '58mm';
  String _printerDeviceName = 'RPP02N-Thermal-58mm';

  List<OrderModel> _orders = [];
  Timer? _countdownTimer;
  Timer? _pollingTimer;

  bool get isOpen => _isOpen;
  bool get isBusy => _isBusy;
  DateTime? get busyUntil => _busyUntil;
  String? get busyReason => _busyReason;
  bool get autoAccept => _autoAccept;
  bool get printerConnected => _printerConnected;
  String get printerDeviceName => _printerDeviceName;
  String get printerPaperSize => _preferredPaperSize;
  String get preferredPaperSize => _preferredPaperSize;
  bool get autoPrintOnAccept => _autoPrintOnAccept;
  int get receiptCopies => _receiptCopies;
  bool get soundAlarmEnabled => _soundAlarmEnabled;
  bool get isLoading => _isLoading;
  int get cookingTime => _cookingTime;
  double get acceptanceScore => _acceptanceScore;
  int get dailyAcceptedCount => _dailyAcceptedCount;
  int get dailyRejectedCount => _dailyRejectedCount;
  String get selectedStageFilter => _selectedStageFilter;


  int get busyRemainingMinutes {
    if (_busyUntil == null) return 0;
    final diff = _busyUntil!.difference(DateTime.now()).inMinutes;
    return diff > 0 ? diff : 1;
  }

  List<OrderModel> get allOrders => List.unmodifiable(_orders);
  List<OrderModel> get orders => allOrders;

  List<OrderModel> get activeOrders {
    final ongoing = _orders.where((o) =>
      o.status == 'NEW' ||
      o.status == 'PAID' ||
      o.status == 'COOKING' ||
      o.status == 'READY_FOR_PICKUP' ||
      o.status == 'DRIVER_ASSIGNED' ||
      o.status == 'AT_MERCHANT' ||
      o.status == 'PICKED_UP' ||
      o.status == 'ON_DELIVERY'
    ).toList();
    if (_selectedStageFilter == 'NEW') {
      return ongoing.where((o) => o.status == 'NEW' || o.status == 'PAID').toList();
    }
    if (_selectedStageFilter == 'COOKING') {
      return ongoing.where((o) => o.status == 'COOKING').toList();
    }
    if (_selectedStageFilter == 'READY_FOR_PICKUP') {
      return ongoing.where((o) => o.status == 'READY_FOR_PICKUP' || o.status == 'AT_MERCHANT').toList();
    }
    return ongoing;
  }

  List<OrderModel> get completedOrders {
    return _orders.where((o) => o.status == 'COMPLETED').toList();
  }

  List<OrderModel> get cancelledOrders {
    return _orders.where((o) => o.status == 'CANCELLED').toList();
  }

  int get activeOrderCount => activeOrders.length;
  int get newOrderCount => _orders.where((o) => o.status == 'NEW' || o.status == 'PAID').length;
  int get cookingOrderCount => _orders.where((o) => o.status == 'COOKING').length;
  int get readyOrderCount => _orders.where((o) => o.status == 'READY_FOR_PICKUP' || o.status == 'AT_MERCHANT').length;

  int get escrowBalance => activeOrders.fold(0, (sum, o) => sum + o.merchantNetPayout);
  int get todayGrossRevenue => completedOrders.fold(0, (sum, o) => sum + o.merchantGrossOmset);
  int get todayNetRevenue => completedOrders.fold(0, (sum, o) => sum + o.merchantNetPayout);
  int get todayPlatformFee => completedOrders.fold(0, (sum, o) => sum + o.platformCommissionAmount);
  int get availableBalance => 485000 + todayNetRevenue;

  MerchantOrderProvider() {
    _initDefaultOrders();
    _startCountdownTicker();
    startPolling();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollingTimer?.cancel();
    GageAudioService.instance.stopOrderAlertLoop();
    super.dispose();
  }

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (_isOpen && !_isLoading) {
        fetchOrders(silent: true);
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void pauseOrders(Duration duration, {String reason = 'Dapur sedang ramai'}) {
    HapticFeedback.heavyImpact();
    _isBusy = true;
    _busyUntil = DateTime.now().add(duration);
    _busyReason = reason;
    notifyListeners();
  }

  void resumeOrders() {
    HapticFeedback.mediumImpact();
    _isBusy = false;
    _busyUntil = null;
    _busyReason = null;
    notifyListeners();
  }

  void _startCountdownTicker() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      bool changed = false;

      // Cek apakah jeda Mode Sibuk telah usai
      if (_isBusy && _busyUntil != null && DateTime.now().isAfter(_busyUntil!)) {
        _isBusy = false;
        _busyUntil = null;
        _busyReason = null;
        changed = true;
      }

      for (int i = 0; i < _orders.length; i++) {
        if ((_orders[i].status == 'NEW' || _orders[i].status == 'PAID') && _orders[i].autoAcceptSecondsRemaining > 0) {
          final nextSec = _orders[i].autoAcceptSecondsRemaining - 1;
          _orders[i] = _orders[i].copyWith(autoAcceptSecondsRemaining: nextSec);
          changed = true;
          if (nextSec == 0) {
            if (_autoAccept && _isOpen && !_isBusy) {
              // Auto accept trigger ke status COOKING
              _orders[i] = _orders[i].copyWith(status: 'COOKING');
              _dailyAcceptedCount++;
              _recalculateAcceptanceScore();
              _checkAndManageOrderAlert();
              if (_autoPrintOnAccept && _printerConnected) {
                printOrderReceipt(_orders[i].id, paperSize: _preferredPaperSize, copies: _receiptCopies);
              }
              GageApiClient.updateMerchantOrderStage(_orders[i].id, 'COOKING');
            } else if (!_autoAccept) {
              // Timeout konfirmasi habis: auto-cancel agar tidak menggantung
              _orders[i] = _orders[i].copyWith(
                status: 'CANCELLED',
                cancellationReason: 'Waktu konfirmasi merchant habis (180 detik)',
              );
              _dailyRejectedCount++;
              _recalculateAcceptanceScore();
              _checkAndManageOrderAlert();
              GageApiClient.updateMerchantOrderStage(_orders[i].id, 'CANCELLED');
            }
          }
        }
      }
      if (changed) {
        notifyListeners();
      }
    });
  }

  void _recalculateAcceptanceScore() {
    final total = _dailyAcceptedCount + _dailyRejectedCount;
    if (total > 0) {
      _acceptanceScore = double.parse(((_dailyAcceptedCount / total) * 100).toStringAsFixed(1));
    }
  }

  void _initDefaultOrders() {
    if (!GageApiClient.useDevSeedData) return;
    final now = DateTime.now();
    _orders = [
      // 1. Pesanan Baru (Perlu Dikonfirmasi)
      OrderModel(
        id: 'ord-8822',
        orderNumber: 'INV-20261103-8822',
        userId: 'usr-cust-02',
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        merchantName: 'Dimsum Sewu Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 14, Depan Pasar',
        customerName: 'Galih Pambudi',
        customerPhone: '081876543210',
        status: 'NEW',
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 48000,
        itemsSubtotal: 42000,
        shippingFee: 5000,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Dusun Gedangan, Pracimantoro',
        distanceKm: 1.8,
        trackingToken: 'trk-fd-8822',
        createdAt: now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch ~/ 1000,
        notes: 'Tambahkan saus sambal ekstra banyak ya.',
        autoAcceptSecondsRemaining: 180,
        channel: 'food',
        items: const [
          OrderItemModel(
            id: 'item-8822-1',
            name: 'Fried Chicken Spicy Komplit',
            price: 18000,
            quantity: 2,
            subtotal: 36000,
            notes: 'Nasi + Es Teh Manis',
          ),
          OrderItemModel(
            id: 'item-8822-2',
            name: 'Medium French Fries',
            price: 6000,
            quantity: 1,
            subtotal: 6000,
            notes: 'Bumbu Barbeque',
          ),
        ],
      ),

      // 2. Pesanan Sedang Disiapkan
      OrderModel(
        id: 'ord-8821',
        orderNumber: 'INV-20261103-8821',
        userId: 'usr-cust-01',
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        merchantName: 'Dimsum Sewu Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 14, Depan Pasar',
        customerName: 'Budi Santoso',
        customerPhone: '081987654321',
        driverName: 'Mas Joko (Kurir GAGE)',
        driverPlate: 'AD 4120 U',
        driverPhone: '081226001000',
        status: 'COOKING',
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 35000,
        itemsSubtotal: 29000,
        shippingFee: 5000,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Jl. Raya Pracimantoro No. 45',
        distanceKm: 1.2,
        trackingToken: 'trk-fd-8821',
        createdAt: now.subtract(const Duration(minutes: 12)).millisecondsSinceEpoch ~/ 1000,
        notes: 'Sambal dipisah ya mas, jangan terlalu pedas.',
        channel: 'food',
        items: const [
          OrderItemModel(
            id: 'item-8821-1',
            name: 'Siomay Dimsum Ayam Udang (4 pcs)',
            price: 14000,
            quantity: 2,
            subtotal: 28000,
            notes: 'Pedas Sedang',
          ),
          OrderItemModel(
            id: 'item-8821-2',
            name: 'Lumpia Kulit Tahu Goreng',
            price: 1000,
            quantity: 1,
            subtotal: 1000,
            notes: 'Ekstra Saus Sambal',
          ),
        ],
      ),

      // 3. Pesanan Siap Dijemput
      OrderModel(
        id: 'ord-3304',
        orderNumber: 'INV-20261103-3304',
        userId: 'usr-cust-03',
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        merchantName: 'Toko Berkah Mart Pracimantoro',
        merchantAddress: 'Pasar Pracimantoro Kios No. 12',
        customerName: 'Ibu Ratna',
        customerPhone: '081765432109',
        driverName: 'Mas Agus (Kurir GAGE)',
        driverPlate: 'AD 5532 WZ',
        driverPhone: '081345678901',
        status: 'READY_FOR_PICKUP',
        paymentMethod: 'CASH_COD',
        paymentStatus: 'PENDING',
        totalAmount: 95000,
        itemsSubtotal: 89000,
        shippingFee: 5000,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Dusun Trukan, Pracimantoro',
        distanceKm: 2.4,
        trackingToken: 'trk-sh-3304',
        createdAt: now.subtract(const Duration(minutes: 25)).millisecondsSinceEpoch ~/ 1000,
        channel: 'shop',
        items: const [
          OrderItemModel(
            id: 'item-3304-1',
            name: 'Beras Sania Premium 5kg',
            price: 68000,
            quantity: 1,
            subtotal: 68000,
            isPicked: true,
          ),
          OrderItemModel(
            id: 'item-3304-2',
            name: 'Minyak Goreng Bimoli 2L',
            price: 21000,
            quantity: 1,
            subtotal: 21000,
            isPicked: true,
          ),
        ],
      ),

      // 4. Riwayat Selesai
      OrderModel(
        id: 'ord-8799',
        orderNumber: 'INV-20261102-8799',
        userId: 'usr-cust-04',
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        merchantName: 'Dimsum Sewu Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 14, Depan Pasar',
        customerName: 'Siti Aminah',
        customerPhone: '081654321098',
        driverName: 'Mas Bambang',
        driverPlate: 'AD 9911 QA',
        driverPhone: '081226002000',
        status: 'COMPLETED',
        paymentMethod: 'GAGEPAY',
        paymentStatus: 'PAID',
        totalAmount: 24000,
        itemsSubtotal: 18000,
        shippingFee: 5000,
        shippingDiscount: 0,
        adminFee: 1000,
        deliveryAddress: 'Jl. Wonogiri - Pracimantoro KM 2',
        distanceKm: 1.0,
        trackingToken: 'trk-fd-8799',
        createdAt: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch ~/ 1000,
        channel: 'food',
        items: const [
          OrderItemModel(
            id: 'item-8799-1',
            name: 'Dimsum Mozzarella Lumer (4 pcs)',
            price: 18000,
            quantity: 1,
            subtotal: 18000,
          ),
        ],
      ),

      // 5. Pesanan Ambil Sendiri (Pickup) Siap di Counter Kasir
      OrderModel(
        id: 'ord-5511',
        orderNumber: 'INV-20261103-5511',
        userId: 'usr-cust-05',
        merchantId: MerchantStorefrontService.defaultPortalMerchantId,
        merchantName: 'Dimsum Sewu Pracimantoro',
        merchantAddress: 'Jl. Raya Pracimantoro No. 14, Depan Pasar',
        customerName: 'Hendra Wijaya',
        customerPhone: '081555666777',
        status: 'READY_FOR_PICKUP',
        paymentMethod: 'CASH_COD',
        paymentStatus: 'PENDING',
        totalAmount: 28000,
        itemsSubtotal: 28000,
        shippingFee: 0,
        shippingDiscount: 0,
        adminFee: 0,
        isPickup: true,
        deliveryOption: 'PICKUP',
        deliveryAddress: 'Ambil Sendiri di Lapak (Kasir)',
        distanceKm: 0.0,
        trackingToken: 'trk-fd-5511',
        createdAt: now.subtract(const Duration(minutes: 8)).millisecondsSinceEpoch ~/ 1000,
        notes: 'Nanti saya ambil sendiri naik motor beat merah',
        channel: 'food',
        items: const [
          OrderItemModel(
            id: 'item-5511-1',
            name: 'Pangsit Goreng Mayonais (5 pcs)',
            price: 14000,
            quantity: 2,
            subtotal: 28000,
            notes: 'Garing ekstra renyah',
          ),
        ],
      ),
    ];
  }

  Future<void> fetchOrders({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final remote = await GageApiClient.getMerchantOrders(MerchantStorefrontService.defaultPortalMerchantId);
      if (remote.isNotEmpty) {
        final parsed = remote.map((m) => OrderModel.fromJson(m)).toList();
        bool hasNewIncoming = false;

        for (final p in parsed) {
          final idx = _orders.indexWhere((o) => o.id == p.id || o.orderNumber == p.orderNumber);
          if (idx >= 0) {
            _orders[idx] = p;
          } else {
            _orders.insert(0, p);
            if (p.status == 'NEW' || p.status == 'PAID') {
              hasNewIncoming = true;
            }
          }
        }

        if (hasNewIncoming) {
          _checkAndManageOrderAlert();
          HapticFeedback.heavyImpact();
        }
      }
    } catch (_) {}

    if (!silent) {
      _isLoading = false;
    }
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
    _checkAndManageOrderAlert();
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

  void toggleSoundAlarm(bool val) {
    HapticFeedback.lightImpact();
    _soundAlarmEnabled = val;
    _checkAndManageOrderAlert();
    notifyListeners();
  }

  void toggleAutoPrintOnAccept(bool val) {
    HapticFeedback.lightImpact();
    _autoPrintOnAccept = val;
    notifyListeners();
  }

  void setReceiptCopies(int copies) {
    HapticFeedback.selectionClick();
    _receiptCopies = copies.clamp(1, 3);
    notifyListeners();
  }

  void setPreferredPaperSize(String size) {
    HapticFeedback.selectionClick();
    _preferredPaperSize = size;
    notifyListeners();
  }

  void setPrinterConnected(bool val) => togglePrinter(val);
  void setPrinterDeviceName(String name) {
    _printerDeviceName = name;
    notifyListeners();
  }
  void setPrinterPaperSize(String size) => setPreferredPaperSize(size);
  void toggleAutoPrint(bool val) => toggleAutoPrintOnAccept(val);

  void _checkAndManageOrderAlert() {
    if (!_isOpen || !_soundAlarmEnabled) {
      if (GageAudioService.instance.isOrderAlertRunning) {
        GageAudioService.instance.stopOrderAlertLoop();
      }
      return;
    }
    final hasNew = _orders.any((o) => o.status == 'NEW' || o.status == 'PAID');
    if (hasNew && !GageAudioService.instance.isOrderAlertRunning) {
      GageAudioService.instance.startOrderAlertLoop();
    } else if (!hasNew && GageAudioService.instance.isOrderAlertRunning) {
      GageAudioService.instance.stopOrderAlertLoop();
    }
  }

  void setCookingTime(int minutes) {
    _cookingTime = minutes;
    notifyListeners();
  }

  /// 1. TERIMA PESANAN (Ubah status ke COOKING / Sedang Disiapkan)
  Future<void> acceptOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: 'COOKING');
      _dailyAcceptedCount++;
      _recalculateAcceptanceScore();
      _checkAndManageOrderAlert();

      if (_autoPrintOnAccept && _printerConnected) {
        printOrderReceipt(orderId, paperSize: _preferredPaperSize, copies: _receiptCopies);
      }

      notifyListeners();

      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'COOKING');
      } catch (_) {}
    }
  }

  /// 2. TOLAK PESANAN (Dengan alasan & penalti poin penerimaan)
  Future<void> rejectOrder(String orderId, String reason) async {
    HapticFeedback.heavyImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final ord = _orders[idx];
      // Catat pembatalan & penalti penerimaan
      _dailyRejectedCount++;
      _recalculateAcceptanceScore();

      _orders[idx] = ord.copyWith(
        status: 'CANCELLED',
        cancellationReason: reason,
        refundAmount: ord.totalAmount, // Refund 100% jika sudah dibayar
      );
      _checkAndManageOrderAlert();
      notifyListeners();

      try {
        await GageApiClient.updateMerchantOrderStage(ord.id, 'CANCELLED');
      } catch (_) {}
    }
  }

  /// 3. PESANAN SIAP (Siap Diambil Kurir)
  Future<void> markReadyForPickup(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: 'READY_FOR_PICKUP');
      notifyListeners();

      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'READY_FOR_PICKUP');
      } catch (_) {}
    }
  }

  /// Mengambil atau memperbarui PIN penyerahan kurir secara otomatis (4 digit interval 5 menit)
  String regenerateHandoverPin(String orderId) {
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      final pin = _orders[idx].courierVerificationPin;
      notifyListeners();
      return pin;
    }
    return '';
  }

  /// Trigger cetak struk thermal SPP Bluetooth (58mm / 80mm) dengan dukungan multi-rangkap
  Future<bool> printOrderReceipt(String orderId, {String paperSize = '58mm', int copies = 1}) async {
    HapticFeedback.mediumImpact();
    if (!_printerConnected) {
      return false;
    }
    await Future.delayed(Duration(milliseconds: 250 * copies));
    return true;
  }

  /// 4. SERAHKAN KE KURIR (Handoff PIN -> Transisi ke PICKED_UP, bukan COMPLETED)
  /// PIN dibuat oleh merchant dan diverifikasi dari input driver
  Future<bool> handoverToCourier(String orderId, {String? verificationPin}) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx < 0) return false;

    final order = _orders[idx];
    if (verificationPin != null && verificationPin.trim().isNotEmpty) {
      final expectedPin = order.courierVerificationPin;
      if (expectedPin.isNotEmpty && verificationPin.trim() != expectedPin) {
        return false; // Validasi PIN gagal
      }
    }

    _orders[idx] = _orders[idx].copyWith(status: 'PICKED_UP');
    notifyListeners();

    try {
      await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'PICKED_UP');
    } catch (_) {}
    return true;
  }

  /// 5. SELESAIKAN PESANAN (Khusus Ambil Sendiri / Pickup langsung oleh pembeli di kasir)
  Future<void> completeOrder(String orderId) async {
    HapticFeedback.mediumImpact();
    final idx = _orders.indexWhere((o) => o.id == orderId);
    if (idx >= 0) {
      _orders[idx] = _orders[idx].copyWith(status: 'COMPLETED');
      notifyListeners();

      try {
        await GageApiClient.updateMerchantOrderStage(_orders[idx].id, 'COMPLETED');
      } catch (_) {}
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // 3 ALUR CERDAS UBAH PESANAN (STOK HABIS)
  // ─────────────────────────────────────────────────────────────────────────

  /// ALUR 1: GANTI ITEM
  /// Non-Tunai: Selisih lebih murah refund instan ke GagePay
  /// Tunai (COD): Selisih lebih murah mengurangi tagihan tunai kurir / kasir toko (Bukan refund saldo)
  Future<void> substituteOrderItem({
    required String orderId,
    required int itemIndex,
    required String newItemName,
    required int newItemPrice,
    InAppChatProvider? chatProvider,
  }) async {
    HapticFeedback.mediumImpact();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx < 0) return;

    final order = _orders[orderIdx];
    final items = List<OrderItemModel>.from(order.items);
    if (itemIndex < 0 || itemIndex >= items.length) return;

    final origItem = items[itemIndex];
    final origTotal = origItem.price * origItem.quantity;
    final newTotal = newItemPrice * origItem.quantity;
    final diff = newTotal - origTotal;

    final isCash = order.paymentMethod.toUpperCase().contains('CASH') ||
        order.paymentMethod.toUpperCase().contains('COD') ||
        order.paymentMethod.toUpperCase() == 'TUNAI';

    // Ganti item di list
    items[itemIndex] = origItem.copyWith(
      name: newItemName,
      price: newItemPrice,
      subtotal: newTotal,
      notes: '${origItem.notes != null ? '${origItem.notes} • ' : ''}(Ganti dari ${origItem.name})',
    );

    int newSubtotal = order.itemsSubtotal + diff;
    int newTotalAmount = order.totalAmount + diff;
    int newRefund = order.refundAmount;
    int newCod = order.codAdjustment;

    String chatNotice = '';

    if (diff < 0) {
      final refundValue = -diff;
      if (isCash) {
        // Tunai: jangan refund ke GagePay! Kurangi tagihan COD kurir / kasir
        newRefund = 0;
        newCod -= refundValue;
        if (order.isPickupOrder) {
          chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName". Total tagihan tunai di kasir toko dikurangi Rp$refundValue menjadi Rp$newTotalAmount.';
        } else {
          chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName". Tagihan tunai COD ke kurir otomatis dikurangi Rp$refundValue menjadi Rp$newTotalAmount.';
        }
      } else {
        // Non-tunai: Refund selisih instan ke GagePay
        newRefund += refundValue;
        chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName". Selisih harga Rp$refundValue sudah kami refund instan ke saldo GagePay kakak.';
      }
    } else if (diff > 0) {
      newCod += diff;
      if (order.isPickupOrder) {
        chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName". Terdapat selisih harga Rp$diff yang dapat dibayarkan tunai saat ambil pesanan di kasir toko ya kak.';
      } else {
        chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName". Terdapat selisih harga Rp$diff yang otomatis menjadi tagihan COD tambahan oleh kurir saat pengantaran ya kak.';
      }
    } else {
      chatNotice = 'Halo kak, untuk "${origItem.name}" stoknya habis dan kami gantikan dengan "$newItemName" dengan harga yang sama.';
    }

    _orders[orderIdx] = order.copyWith(
      items: items,
      itemsSubtotal: newSubtotal,
      totalAmount: newTotalAmount,
      refundAmount: newRefund,
      codAdjustment: newCod,
    );

    if (chatProvider != null && chatNotice.isNotEmpty) {
      chatProvider.sendMessage(
        orderId: order.id,
        senderId: order.merchantId,
        senderRole: 'merchant',
        senderName: order.merchantName,
        text: chatNotice,
      );
    }

    notifyListeners();
  }

  /// ALUR 2: KIRIM YANG READY SAJA
  /// Non-Tunai: Nilai barang kosong refund instan ke GagePay
  /// Tunai (COD): Nilai barang kosong otomatis memotong tagihan tunai kurir / kasir
  Future<void> fulfillPartialOrder({
    required String orderId,
    required List<int> outOfStockItemIndices,
    InAppChatProvider? chatProvider,
  }) async {
    HapticFeedback.mediumImpact();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx < 0) return;

    final order = _orders[orderIdx];
    final items = List<OrderItemModel>.from(order.items);

    int outOfStockSum = 0;
    final List<String> oosNames = [];
    final List<OrderItemModel> keptItems = [];

    for (int i = 0; i < items.length; i++) {
      if (outOfStockItemIndices.contains(i)) {
        final oos = items[i];
        outOfStockSum += oos.subtotal;
        oosNames.add(oos.name);
      } else {
        keptItems.add(items[i]);
      }
    }

    if (keptItems.isEmpty) {
      // Jika semua kosong, otomatis alihkan ke batal penuh
      await cancelOrderWithFullRefund(
        orderId: orderId,
        reason: 'Seluruh menu yang dipesan kebetulan sedang kosong',
        chatProvider: chatProvider,
      );
      return;
    }

    final isCash = order.paymentMethod.toUpperCase().contains('CASH') ||
        order.paymentMethod.toUpperCase().contains('COD') ||
        order.paymentMethod.toUpperCase() == 'TUNAI';

    final newSubtotal = order.itemsSubtotal - outOfStockSum;
    final newTotalAmount = order.totalAmount - outOfStockSum;
    final newRefund = isCash ? 0 : (order.refundAmount + outOfStockSum);
    final newCod = isCash ? (order.codAdjustment - outOfStockSum) : order.codAdjustment;

    _orders[orderIdx] = order.copyWith(
      items: keptItems,
      itemsSubtotal: newSubtotal,
      totalAmount: newTotalAmount,
      refundAmount: newRefund,
      codAdjustment: newCod,
    );

    if (chatProvider != null) {
      final msg = isCash
          ? (order.isPickupOrder
              ? 'Mohon maaf kak, item [${oosNames.join(", ")}] sedang kosong. Kami siapkan sisa item yang ready. Tagihan tunai kasir toko dikurangi Rp$outOfStockSum menjadi Rp$newTotalAmount.'
              : 'Mohon maaf kak, item [${oosNames.join(", ")}] sedang kosong. Kami siapkan sisa item yang ready. Tagihan tunai COD kurir dikurangi Rp$outOfStockSum menjadi Rp$newTotalAmount.')
          : 'Mohon maaf kak, item [${oosNames.join(", ")}] sedang kosong. Kami proses kirim sisa item yang siap ya kak. Pengembalian dana Rp$outOfStockSum telah langsung di-refund ke GagePay kakak.';
      chatProvider.sendMessage(
        orderId: order.id,
        senderId: order.merchantId,
        senderRole: 'merchant',
        senderName: order.merchantName,
        text: msg,
      );
    }

    notifyListeners();
  }

  /// ALUR 3: BATALKAN SELURUH PESANAN
  /// Non-Tunai: Refund 100% ke GagePay
  /// Tunai (COD): Batal tanpa tagihan (Refund = 0)
  Future<void> cancelOrderWithFullRefund({
    required String orderId,
    String reason = 'Stok Seluruh Pesanan Habis',
    InAppChatProvider? chatProvider,
  }) async {
    HapticFeedback.heavyImpact();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx < 0) return;

    final order = _orders[orderIdx];
    final isCash = order.paymentMethod.toUpperCase().contains('CASH') ||
        order.paymentMethod.toUpperCase().contains('COD') ||
        order.paymentMethod.toUpperCase() == 'TUNAI';

    final fullRefund = isCash ? 0 : order.totalAmount;

    _dailyRejectedCount++;
    _recalculateAcceptanceScore();

    _orders[orderIdx] = order.copyWith(
      status: 'CANCELLED',
      cancellationReason: reason,
      refundAmount: fullRefund,
    );

    if (chatProvider != null) {
      final msg = isCash
          ? 'Mohon maaf kak, pesanan terpaksa kami batalkan karena stok bahan baku habis: "$reason". Karena pesanan menggunakan metode Tunai (COD), tidak ada pembayaran yang ditagihkan kepada kakak.'
          : 'Mohon maaf kak, pesanan terpaksa kami batalkan karena stok bahan baku habis: "$reason". Dana 100% sejumlah Rp${order.totalAmount} telah kami kembalikan instan ke saldo GagePay kakak.';
      chatProvider.sendMessage(
        orderId: order.id,
        senderId: order.merchantId,
        senderRole: 'merchant',
        senderName: order.merchantName,
        text: msg,
      );
    }

    notifyListeners();

    try {
      await GageApiClient.updateMerchantOrderStage(order.id, 'CANCELLED');
    } catch (_) {}
  }

  /// Picking item toggle (untuk flow mart/shop)
  void togglePickingItem(String orderId, int itemIndex) {
    HapticFeedback.lightImpact();
    final orderIdx = _orders.indexWhere((o) => o.id == orderId);
    if (orderIdx >= 0) {
      final items = List<OrderItemModel>.from(_orders[orderIdx].items);
      if (itemIndex >= 0 && itemIndex < items.length) {
        items[itemIndex] = items[itemIndex].copyWith(isPicked: !items[itemIndex].isPicked);
        _orders[orderIdx] = _orders[orderIdx].copyWith(items: items);
        notifyListeners();
      }
    }
  }

  /// Simulasi pesanan baru masuk dari pelanggan
  void triggerMockIncomingOrder() {
    HapticFeedback.vibrate();
    final newId = 'ord-${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newOrder = OrderModel(
      id: newId,
      orderNumber: 'INV/GG/20261103/FD/NEW-${DateTime.now().millisecondsSinceEpoch % 9000 + 1000}',
      userId: 'usr-cust-99',
      merchantId: MerchantStorefrontService.defaultPortalMerchantId,
      merchantName: 'Dimsum Sewu Pracimantoro',
      merchantAddress: 'Jl. Raya Pracimantoro No. 14, Depan Pasar',
      customerName: 'Pelanggan Baru Pracimantoro',
      customerPhone: '081234567899',
      status: 'NEW',
      paymentMethod: 'GAGEPAY',
      paymentStatus: 'PAID',
      totalAmount: 28000,
      itemsSubtotal: 22000,
      shippingFee: 5000,
      shippingDiscount: 0,
      adminFee: 1000,
      deliveryAddress: 'Jl. Lintas Selatan Pracimantoro',
      distanceKm: 1.5,
      trackingToken: 'trk-new-$newId',
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notes: 'Mohon dibungkus plastik rangkap ya mas.',
      autoAcceptSecondsRemaining: 180,
      channel: 'food',
      items: const [
        OrderItemModel(
          id: 'item-new-1',
          name: 'Dimsum Sewu Spesial Campur (6 pcs)',
          price: 11000,
          quantity: 2,
          subtotal: 22000,
          notes: 'Ekstra Pedas',
        ),
      ],
    );
    _orders.insert(0, newOrder);
    notifyListeners();
  }

  /// FORMULA RESMI KALKULATOR MARKUP KOMISI (Default 10% Reguler/Star, 8% Exclusive):
  /// CEIL((Harga Asli / (1 - rate/100)) / 500) * 500
  static int calculateMarkupPrice(int originalPrice, {double commissionRate = 10.0}) {
    if (originalPrice <= 0) return 0;
    final divisor = 1.0 - (commissionRate / 100.0);
    if (divisor <= 0) return originalPrice;
    return ((originalPrice / divisor) / 500).ceil() * 500;
  }
}
