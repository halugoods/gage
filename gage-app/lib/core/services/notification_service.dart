import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/data/mock/gage_voucher_data.dart';

class GageNotification {
  final String id;
  final String title;
  final String body;
  final String category; // 'transaksi' | 'promo' | 'sistem'
  final DateTime timestamp;
  bool isRead;

  String get type => category;

  GageNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'body': body,
    'category': category,
    'timestamp': timestamp.toIso8601String(),
    'isRead': isRead,
  };

  factory GageNotification.fromJson(Map<String, dynamic> json) => GageNotification(
    id: json['id'] ?? '',
    title: json['title'] ?? '',
    body: json['body'] ?? '',
    category: json['category'] ?? 'sistem',
    timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp']) : DateTime.now(),
    isRead: json['isRead'] ?? false,
  );
}

class NotificationService extends ChangeNotifier {
  static final NotificationService instance = NotificationService._();
  NotificationService._() {
    _loadFromStorage();
  }

  static const String _storageKey = 'gage_notifications_data';
  static const String _seenVouchersKey = 'gage_seen_vouchers_v1';
  static const String _customerChatsKey = 'gage_unread_customer_chats_v1';
  static const String _driverChatsKey = 'gage_unread_driver_chats_v1';
  static const String _merchantChatsKey = 'gage_unread_merchant_chats_v1';

  static const Map<String, int> _defaultCustomerChatUnreads = {
    'chat-ai-01': 1,
    'chat-driver-01': 1,
  };
  static const Map<String, int> _defaultDriverChatUnreads = {
    'drv-ORD-88219-customer': 1,
  };
  static const Map<String, int> _defaultMerchantChatUnreads = {
    'mch-ORD-9021-driver': 1,
  };

  List<GageNotification> _items = [];
  final Set<String> _seenVoucherCodes = {};
  bool _hasInitializedSeenVouchers = false;
  Map<String, int> _customerChatUnreads = Map<String, int>.from(_defaultCustomerChatUnreads);
  Map<String, int> _driverChatUnreads = Map<String, int>.from(_defaultDriverChatUnreads);
  Map<String, int> _merchantChatUnreads = Map<String, int>.from(_defaultMerchantChatUnreads);

  List<GageNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;
  int? _customUnreadPromoCount;
  int get unreadPromoCount {
    if (_customUnreadPromoCount != null) return _customUnreadPromoCount!;
    final unreadPromoNotifs = _items.where((n) => !n.isRead && n.category == 'promo').length;
    if (_hasInitializedSeenVouchers) {
      final newUnseenVouchers = GageVoucherData.allVouchers
          .where((v) => !_seenVoucherCodes.contains((v['code'] ?? '').toString().trim().toUpperCase()))
          .length;
      if (newUnseenVouchers > unreadPromoNotifs) {
        return newUnseenVouchers;
      }
    }
    return unreadPromoNotifs;
  }

  set unreadPromoCount(int val) {
    _customUnreadPromoCount = val;
    notifyListeners();
  }

  int? _customUnreadChatCount;
  int get unreadChatCount =>
      _customUnreadChatCount ??
      _customerChatUnreads.values.fold<int>(0, (sum, count) => sum + (count > 0 ? count : 0));

  set unreadChatCount(int val) {
    _customUnreadChatCount = val;
    notifyListeners();
  }

  int get unreadDriverChatCount =>
      _driverChatUnreads.values.fold<int>(0, (sum, count) => sum + (count > 0 ? count : 0));

  int get unreadMerchantChatCount =>
      _merchantChatUnreads.values.fold<int>(0, (sum, count) => sum + (count > 0 ? count : 0));

  int unreadCountForChat(String chatId) => _customerChatUnreads[chatId] ?? 0;
  int unreadCountForDriverChat(String chatId) => _driverChatUnreads[chatId] ?? 0;
  int unreadCountForMerchantChat(String chatId) => _merchantChatUnreads[chatId] ?? 0;

  bool get hasUnread => unreadCount > 0;

  Map<String, int> _decodeChatMap(String? raw, Map<String, int> fallback) {
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, (v as num?)?.toInt() ?? 0));
      } catch (_) {}
    }
    return Map<String, int>.from(fallback);
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final seenList = prefs.getStringList(_seenVouchersKey);
    if (seenList != null) {
      _seenVoucherCodes
        ..clear()
        ..addAll(seenList.map((e) => e.trim().toUpperCase()));
      _hasInitializedSeenVouchers = true;
    } else {
      _seenVoucherCodes.clear();
      _hasInitializedSeenVouchers = false;
    }

    _customerChatUnreads = _decodeChatMap(
      prefs.getString(_customerChatsKey),
      _defaultCustomerChatUnreads,
    );
    _driverChatUnreads = _decodeChatMap(
      prefs.getString(_driverChatsKey),
      _defaultDriverChatUnreads,
    );
    _merchantChatUnreads = _decodeChatMap(
      prefs.getString(_merchantChatsKey),
      _defaultMerchantChatUnreads,
    );

    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List).map((i) => GageNotification.fromJson(i)).toList();
        _items = list;
        notifyListeners();
        return;
      } catch (_) {}
    }

    // Default notifications jika belum ada di storage
    final now = DateTime.now();
    _items = [
      GageNotification(
        id: 'notif-trx-01',
        title: 'Pesanan Selesai!',
        body: 'Pesanan Dimsum Sewu Pracimantoro telah berhasil diantar oleh Driver Joko. Selamat menikmati!',
        category: 'transaksi',
        timestamp: now.subtract(const Duration(minutes: 15)),
        isRead: false,
      ),
      GageNotification(
        id: 'notif-prm-01',
        title: 'Voucher Diskon Ongkir [-10RB]',
        body: 'Diskon ongkos kirim Rp 10.000 aktif untuk seluruh merchant resto dan toko sembako di Pracimantoro.',
        category: 'promo',
        timestamp: now.subtract(const Duration(hours: 2)),
        isRead: false,
      ),
      GageNotification(
        id: 'notif-sys-01',
        title: 'Layanan Baru: GAGE Send Flat Rate',
        body: 'Kirim dokumen dan barang belanja kini makin hemat dengan tarif flat 0-3 km hanya Rp 15.000 (Instan) & Rp 12.000 (Sameday).',
        category: 'sistem',
        timestamp: now.subtract(const Duration(hours: 5)),
        isRead: false,
      ),
      GageNotification(
        id: 'notif-trx-02',
        title: 'Pembayaran QRIS Berhasil',
        body: 'Verifikasi transfer QRIS pesanan belanja Kios Tani Subur Makmur telah sukses dikonfirmasi sistem.',
        category: 'transaksi',
        timestamp: now.subtract(const Duration(days: 1)),
        isRead: true,
      ),
      GageNotification(
        id: 'notif-prm-02',
        title: 'Promo Kilat Kuliner Malam',
        body: 'Dapatkan potongan harga langsung hingga Rp 20.000 untuk pesanan makan malam di atas jam 18:00 WIB.',
        category: 'promo',
        timestamp: now.subtract(const Duration(days: 2)),
        isRead: true,
      ),
    ];
    notifyListeners();
  }

  Future<void> addNotification({
    required String title,
    required String body,
    String category = 'sistem',
    String type = 'sistem',
  }) async {
    final cat = category != 'sistem' ? category : type;
    if (cat == 'promo') {
      _customUnreadPromoCount = null;
    }
    final newNotif = GageNotification(
      id: 'notif-${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      body: body,
      category: cat,
      timestamp: DateTime.now(),
      isRead: false,
    );
    _items.insert(0, newNotif);
    notifyListeners();
    await _saveToStorage();
  }

  /// Triggers an unread promo badge whenever a new voucher arrives or is published.
  Future<void> notifyNewVoucher({
    required String code,
    required String title,
    String? body,
  }) async {
    _customUnreadPromoCount = null;
    final normalized = code.trim().toUpperCase();
    if (_hasInitializedSeenVouchers) {
      _seenVoucherCodes.remove(normalized);
      await _saveSeenVouchers();
    }
    await addNotification(
      title: 'Voucher Baru: $normalized ($title)',
      body: body ?? 'Pakai kode $normalized sekarang sebelum masa berlaku habis.',
      category: 'promo',
    );
  }

  Future<void> markPromosAsRead() async {
    bool changed = false;
    if (_customUnreadPromoCount != null && _customUnreadPromoCount != 0) {
      changed = true;
    }
    _customUnreadPromoCount = null;
    for (final item in _items) {
      if (item.category == 'promo' && !item.isRead) {
        item.isRead = true;
        changed = true;
      }
    }
    final currentCodes = GageVoucherData.allVouchers
        .map((v) => (v['code'] ?? '').toString().trim().toUpperCase())
        .where((c) => c.isNotEmpty);
    for (final code in currentCodes) {
      if (_seenVoucherCodes.add(code)) {
        changed = true;
      }
    }
    if (!_hasInitializedSeenVouchers) {
      _hasInitializedSeenVouchers = true;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
    await _saveToStorage();
    await _saveSeenVouchers();
  }

  Future<void> markChatAsRead(String chatId) async {
    _customUnreadChatCount = null;
    final prev = _customerChatUnreads[chatId] ?? 0;
    if (prev > 0) {
      _customerChatUnreads[chatId] = 0;
      notifyListeners();
      await _saveChatMap(_customerChatsKey, _customerChatUnreads);
    }
  }

  Future<void> markAllChatsAsRead() async {
    _customUnreadChatCount = null;
    bool changed = false;
    for (final key in _customerChatUnreads.keys.toList()) {
      if ((_customerChatUnreads[key] ?? 0) > 0) {
        _customerChatUnreads[key] = 0;
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      await _saveChatMap(_customerChatsKey, _customerChatUnreads);
    }
  }

  Future<void> receiveCustomerChatMessage(String chatId, {int increment = 1}) async {
    _customUnreadChatCount = null;
    _customerChatUnreads[chatId] = (_customerChatUnreads[chatId] ?? 0) + increment;
    notifyListeners();
    await _saveChatMap(_customerChatsKey, _customerChatUnreads);
  }

  Future<void> markDriverChatAsRead(String chatId) async {
    if ((_driverChatUnreads[chatId] ?? 0) > 0) {
      _driverChatUnreads[chatId] = 0;
      notifyListeners();
      await _saveChatMap(_driverChatsKey, _driverChatUnreads);
    }
  }

  Future<void> markMerchantChatAsRead(String chatId) async {
    if ((_merchantChatUnreads[chatId] ?? 0) > 0) {
      _merchantChatUnreads[chatId] = 0;
      notifyListeners();
      await _saveChatMap(_merchantChatsKey, _merchantChatUnreads);
    }
  }

  @visibleForTesting
  Future<void> resetForTest() async {
    _customUnreadPromoCount = null;
    _customUnreadChatCount = null;
    _seenVoucherCodes.clear();
    _hasInitializedSeenVouchers = false;
    _customerChatUnreads = Map<String, int>.from(_defaultCustomerChatUnreads);
    _driverChatUnreads = Map<String, int>.from(_defaultDriverChatUnreads);
    _merchantChatUnreads = Map<String, int>.from(_defaultMerchantChatUnreads);
    await _loadFromStorage();
  }

  Future<void> markAllAsRead() async {
    bool changed = false;
    for (final item in _items) {
      if (!item.isRead) {
        item.isRead = true;
        changed = true;
      }
    }
    if (changed || _customUnreadPromoCount != null) {
      _customUnreadPromoCount = null;
      await _recordCurrentVouchersSeen();
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> _recordCurrentVouchersSeen() async {
    _hasInitializedSeenVouchers = true;
    for (final v in GageVoucherData.allVouchers) {
      final code = (v['code'] ?? '').toString().trim().toUpperCase();
      if (code.isNotEmpty) _seenVoucherCodes.add(code);
    }
    await _saveSeenVouchers();
  }

  Future<void> markAsRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1 && !_items[idx].isRead) {
      _items[idx].isRead = true;
      if (_items[idx].category == 'promo') {
        _customUnreadPromoCount = null;
      }
      notifyListeners();
      await _saveToStorage();
    }
  }

  Future<void> delete(String id) async {
    _items.removeWhere((n) => n.id == id);
    notifyListeners();
    _saveToStorage();
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_items.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }

  Future<void> _saveSeenVouchers() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_seenVouchersKey, _seenVoucherCodes.toList());
    } catch (_) {}
  }

  Future<void> _saveChatMap(String key, Map<String, int> map) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, jsonEncode(map));
    } catch (_) {}
  }
}
