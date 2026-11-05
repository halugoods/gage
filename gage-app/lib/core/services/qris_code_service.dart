import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Layanan Pengelola Kode Unik QRIS Dinamis Harian (1 - 499)
/// - Menghasilkan kode verifikasi transfer unik antara 1 s.d. 499 per hari.
/// - Tidak boleh ada 2 transaksi aktif yang memakai kode unik yang sama di hari yang sama.
/// - Jika pesanan selesai (COMPLETED) atau dibatalkan (CANCELLED), kode unik tersebut
///   otomatis dilepaskan (daur ulang) dan dapat digunakan kembali di hari itu agar
///   nilai tagihan pelanggan tetap minimal (hemat & mudah ditransfer).
class QrisCodeService {
  static final QrisCodeService instance = QrisCodeService._();
  QrisCodeService._();

  static const int minCode = 1;
  static const int maxCode = 499;

  String _getTodayKey() {
    final now = DateTime.now();
    return 'qris_codes_${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
  }

  /// Mengalokasikan kode unik terkecil yang tersedia (1 - 499) untuk orderId
  Future<int> allocateCode(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    
    // Format JSON di storage: { orderId: codeNumber }
    Map<String, dynamic> activeMap = {};
    final raw = prefs.getString(key);
    if (raw != null && raw.isNotEmpty) {
      try {
        activeMap = Map<String, dynamic>.from(jsonDecode(raw));
      } catch (_) {
        activeMap = {};
      }
    }

    // Jika orderId ini sudah punya kode teralokasi hari ini, gunakan kembali
    if (activeMap.containsKey(orderId)) {
      return (activeMap[orderId] as num).toInt();
    }

    final Set<int> usedCodes = activeMap.values.map((v) => (v as num).toInt()).toSet();

    // Cari kode terkecil antara 1 s.d. 499 yang belum aktif dipakai
    int assigned = 1;
    for (int i = minCode; i <= maxCode; i++) {
      if (!usedCodes.contains(i)) {
        assigned = i;
        break;
      }
    }

    activeMap[orderId] = assigned;
    await prefs.setString(key, jsonEncode(activeMap));
    debugPrint('[QrisCodeService] Allocated unique code $assigned for order $orderId on $key');
    return assigned;
  }

  /// Mengambil kode unik yang sedang aktif untuk orderId
  Future<int?> getCodeForOrder(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = Map<String, dynamic>.from(jsonDecode(raw));
      return (map[orderId] as num?)?.toInt();
    } catch (_) {
      return null;
    }
  }

  /// Melepaskan kode unik saat order selesai / batal sehingga bisa digunakan order lain
  Future<void> releaseCode(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _getTodayKey();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return;

    try {
      final activeMap = Map<String, dynamic>.from(jsonDecode(raw));
      if (activeMap.containsKey(orderId)) {
        final code = activeMap.remove(orderId);
        await prefs.setString(key, jsonEncode(activeMap));
        debugPrint('[QrisCodeService] Released unique code $code from order $orderId on $key');
      }
    } catch (_) {}
  }
}
