import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GageNotification {
  final String id;
  final String title;
  final String body;
  final String category; // 'transaksi' | 'promo' | 'sistem'
  final DateTime timestamp;
  bool isRead;

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
  List<GageNotification> _items = [];

  List<GageNotification> get items => List.unmodifiable(_items);

  int get unreadCount => _items.where((n) => !n.isRead).length;
  bool get hasUnread => unreadCount > 0;

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> markAllAsRead() async {
    for (final item in _items) {
      item.isRead = true;
    }
    notifyListeners();
    _saveToStorage();
  }

  Future<void> markAsRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx != -1 && !_items[idx].isRead) {
      _items[idx].isRead = true;
      notifyListeners();
      _saveToStorage();
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonEncode(_items.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, data);
    } catch (_) {}
  }
}
