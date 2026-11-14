import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:latlong2/latlong.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

class UserSavedAddress {
  final String id;
  final String name;
  final String address;
  final String category; // 'personal' or 'business'
  final double latitude;
  final double longitude;
  final String? notes; // Patokan / catatan khusus
  final int? iconCodePoint;
  final String? recipientName; // Nama penerima / kontak
  final String? recipientPhone; // Nomor WhatsApp / kontak yang dapat dihubungi

  const UserSavedAddress({
    required this.id,
    required this.name,
    required this.address,
    required this.category,
    required this.latitude,
    required this.longitude,
    this.notes,
    this.iconCodePoint,
    this.recipientName,
    this.recipientPhone,
  });

  LatLng get location => LatLng(latitude, longitude);

  IconData get icon {
    if (category == 'business') {
      return Icons.storefront_rounded;
    }
    return Icons.home_rounded;
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'category': category,
    'latitude': latitude,
    'longitude': longitude,
    'notes': notes,
    'iconCodePoint': iconCodePoint,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
  };

  factory UserSavedAddress.fromJson(Map<String, dynamic> map) {
    return UserSavedAddress(
      id: map['id'] as String? ?? 'id_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Alamat Tersimpan',
      address: map['address'] as String? ?? '',
      category: map['category'] as String? ?? 'personal',
      latitude: (map['latitude'] as num?)?.toDouble() ?? -8.05517,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 110.80889,
      notes: map['notes'] as String?,
      iconCodePoint: map['iconCodePoint'] as int?,
      recipientName: map['recipientName'] as String?,
      recipientPhone: map['recipientPhone'] as String?,
    );
  }
}

class UserAddressService {
  static const String _keyFavorites = 'gage_saved_favorites_v1';
  static const String _keyRecents = 'gage_recent_addresses_v1';
  static const String _keyLastRecipientName = 'gage_last_recipient_name_v1';
  static const String _keyLastRecipientPhone = 'gage_last_recipient_phone_v1';

  static String _cachedLastRecipientName = '';
  static String _cachedLastRecipientPhone = '';

  static String getLastRecipientNameSync() => _cachedLastRecipientName;
  static String getLastRecipientPhoneSync() => _cachedLastRecipientPhone;

  /// Mengambil nama penerima / kontak yang terakhir kali digunakan
  static Future<String> getLastRecipientName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedLastRecipientName = prefs.getString(_keyLastRecipientName) ?? '';
      return _cachedLastRecipientName;
    } catch (_) {
      return _cachedLastRecipientName;
    }
  }

  /// Mengambil nomor WhatsApp / HP yang terakhir kali digunakan
  static Future<String> getLastRecipientPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedLastRecipientPhone = prefs.getString(_keyLastRecipientPhone) ?? '';
      return _cachedLastRecipientPhone;
    } catch (_) {
      return _cachedLastRecipientPhone;
    }
  }

  /// Menyimpan nama penerima dan nomor WhatsApp terakhir untuk auto-fill cerdas
  static Future<void> saveLastRecipient({
    required String name,
    required String phone,
  }) async {
    try {
      _cachedLastRecipientName = name.trim();
      _cachedLastRecipientPhone = phone.trim();
      final prefs = await SharedPreferences.getInstance();
      if (name.trim().isNotEmpty) {
        await prefs.setString(_keyLastRecipientName, name.trim());
      }
      if (phone.trim().isNotEmpty) {
        await prefs.setString(_keyLastRecipientPhone, phone.trim());
      }
    } catch (_) {}
  }

  /// Mengambil daftar alamat favorit tersimpan (dapat difilter: 'personal' atau 'business')
  static Future<List<UserSavedAddress>> getFavorites({String? category}) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFavorites);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final List decoded = json.decode(raw);
      final list = decoded
          .map((item) => UserSavedAddress.fromJson(item as Map<String, dynamic>))
          .toList();

      if (category != null && category.isNotEmpty) {
        return list.where((a) => a.category == category).toList();
      }
      return list;
    } catch (_) {
      return [];
    }
  }

  /// Menyimpan atau memperbarui alamat favorit
  static Future<void> saveFavorite(UserSavedAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getFavorites();
    final index = currentList.indexWhere((a) => a.id == address.id);

    if (index >= 0) {
      currentList[index] = address;
    } else {
      currentList.insert(0, address);
    }

    final encoded = json.encode(currentList.map((a) => a.toJson()).toList());
    await prefs.setString(_keyFavorites, encoded);

    // Asinkron simpan ke akun cloud user (Cloudflare D1)
    try {
      final sessionStr = prefs.getString('gage_user_session');
      String userId = GageApiClient.useDevSeedData ? 'usr-cust-01' : '';
      if (sessionStr != null) {
        final decoded = json.decode(sessionStr);
        if (decoded is Map && decoded['id'] != null) {
          userId = decoded['id'].toString();
        }
      }
      if (userId.isNotEmpty) {
        GageApiClient.saveUserAddress(userId, address.toJson());
      }
    } catch (_) {}
  }

  /// Menghapus alamat favorit berdasarkan ID
  static Future<void> deleteFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getFavorites();
    currentList.removeWhere((a) => a.id == id);
    final encoded = json.encode(currentList.map((a) => a.toJson()).toList());
    await prefs.setString(_keyFavorites, encoded);
  }

  /// Mengambil riwayat alamat terakhir yang pernah dipilih
  static Future<List<UserSavedAddress>> getRecents() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRecents);
    if (raw == null || raw.isEmpty) return [];

    try {
      final List decoded = json.decode(raw);
      return decoded
          .map((item) => UserSavedAddress.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menambahkan alamat ke riwayat terakhir (maksimal 6 item unik)
  static Future<void> addRecent(UserSavedAddress address) async {
    final prefs = await SharedPreferences.getInstance();
    final currentList = await getRecents();

    // Hapus duplikat berdasarkan koordinat/nama
    currentList.removeWhere((a) =>
        a.name.toLowerCase() == address.name.toLowerCase() ||
        (a.latitude == address.latitude && a.longitude == address.longitude));

    currentList.insert(0, address);
    if (currentList.length > 6) {
      currentList.removeRange(6, currentList.length);
    }

    final encoded = json.encode(currentList.map((a) => a.toJson()).toList());
    await prefs.setString(_keyRecents, encoded);
  }

  /// Mencari alamat favorit yang cocok berdasarkan ID, nama, atau presisi koordinat ketat (<= 5 meter).
  /// Menghindari false-positive atau pembajakan titik kustom di sekitar lokasi favorit.
  static UserSavedAddress? matchFavoriteInList(
    List<UserSavedAddress> favorites, {
    LatLng? location,
    String? preferredId,
    String? preferredName,
    double maxDistanceMeters = 5.0,
  }) {
    if (favorites.isEmpty) return null;

    final cleanId = preferredId?.trim() ?? '';
    const distCalc = Distance();

    // Jika location diberikan, kita HARUS memverifikasi bahwa titik tersebut
    // benar-benar berada di dekat alamat favorit (<= maxDistanceMeters).
    // Jangan pernah mengembalikan favorit yang jaraknya ratusan meter/kilometer
    // hanya karena preferredId masih tersimpan dari state sebelumnya!
    if (location != null) {
      if (cleanId.isNotEmpty) {
        for (final fav in favorites) {
          if (fav.id == cleanId) {
            final meters = distCalc.as(LengthUnit.Meter, fav.location, location);
            if (meters <= maxDistanceMeters) {
              return fav;
            }
          }
        }
      }

      final cleanName = (preferredName ?? '')
          .replaceFirst(RegExp(r'^Favorit:\s*', caseSensitive: false), '')
          .trim()
          .toLowerCase();

      UserSavedAddress? exactCoordMatch;
      for (final fav in favorites) {
        final meters = distCalc.as(LengthUnit.Meter, fav.location, location);
        if (meters <= maxDistanceMeters) {
          if (cleanName.isNotEmpty && fav.name.trim().toLowerCase() == cleanName) {
            return fav;
          }
          exactCoordMatch ??= fav;
        }
      }
      return exactCoordMatch;
    }

    // Hanya jika location == null, cari murni berdasarkan preferredId
    if (cleanId.isNotEmpty) {
      for (final fav in favorites) {
        if (fav.id == cleanId) return fav;
      }
    }

    return null;
  }

  /// Mengambil dan mencocokkan alamat favorit dari penyimpanan lokal.
  static Future<UserSavedAddress?> findMatchingFavorite({
    LatLng? location,
    String? preferredId,
    String? preferredName,
    double maxDistanceMeters = 5.0,
  }) async {
    final favs = await getFavorites();
    return matchFavoriteInList(
      favs,
      location: location,
      preferredId: preferredId,
      preferredName: preferredName,
      maxDistanceMeters: maxDistanceMeters,
    );
  }
}
