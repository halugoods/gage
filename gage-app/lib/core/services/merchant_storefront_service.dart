import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Single day open/close operating hours entry.
class DayOperatingHours {
  final bool isOpen;
  final String openTime;
  final String closeTime;

  const DayOperatingHours({
    this.isOpen = true,
    this.openTime = '09:00',
    this.closeTime = '21:00',
  });

  DayOperatingHours copyWith({
    bool? isOpen,
    String? openTime,
    String? closeTime,
  }) {
    return DayOperatingHours(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  Map<String, dynamic> toJson() => {
        'isOpen': isOpen,
        'openTime': openTime,
        'closeTime': closeTime,
      };

  factory DayOperatingHours.fromJson(Map<String, dynamic> json) {
    return DayOperatingHours(
      isOpen: json['isOpen'] != false,
      openTime: (json['openTime'] ?? '09:00').toString(),
      closeTime: (json['closeTime'] ?? '21:00').toString(),
    );
  }
}

/// Weekly (Senin-Minggu) or unified everyday operating schedule for a merchant.
class MerchantOperatingSchedule {
  final bool everydaySame;
  final String everydayOpen;
  final String everydayClose;
  final Map<int, DayOperatingHours> days;

  const MerchantOperatingSchedule({
    required this.everydaySame,
    required this.everydayOpen,
    required this.everydayClose,
    required this.days,
  });

  static const List<int> orderedWeekdays = [
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
    DateTime.sunday,
  ];

  static String weekdayLabel(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Senin';
      case DateTime.tuesday:
        return 'Selasa';
      case DateTime.wednesday:
        return 'Rabu';
      case DateTime.thursday:
        return 'Kamis';
      case DateTime.friday:
        return 'Jumat';
      case DateTime.saturday:
        return 'Sabtu';
      case DateTime.sunday:
        return 'Minggu';
      default:
        return 'Senin';
    }
  }

  factory MerchantOperatingSchedule.defaults({
    String open = '09:00',
    String close = '21:00',
  }) {
    return MerchantOperatingSchedule(
      everydaySame: true,
      everydayOpen: open,
      everydayClose: close,
      days: {
        for (final day in orderedWeekdays)
          day: DayOperatingHours(isOpen: true, openTime: open, closeTime: close),
      },
    );
  }

  /// Parses simple `"HH:mm - HH:mm"` strings into a default schedule.
  factory MerchantOperatingSchedule.fromFallbackOpenHours(String? rawOpenHours) {
    final raw = (rawOpenHours ?? '').trim();
    final match = RegExp(r'^(\d{1,2}[:.]\d{2})\s*[-–]\s*(\d{1,2}[:.]\d{2})').firstMatch(raw);
    if (match != null) {
      final open = match.group(1)!.replaceAll('.', ':');
      final close = match.group(2)!.replaceAll('.', ':');
      return MerchantOperatingSchedule.defaults(open: open, close: close);
    }
    return MerchantOperatingSchedule.defaults();
  }

  MerchantOperatingSchedule copyWith({
    bool? everydaySame,
    String? everydayOpen,
    String? everydayClose,
    Map<int, DayOperatingHours>? days,
  }) {
    return MerchantOperatingSchedule(
      everydaySame: everydaySame ?? this.everydaySame,
      everydayOpen: everydayOpen ?? this.everydayOpen,
      everydayClose: everydayClose ?? this.everydayClose,
      days: days ?? Map<int, DayOperatingHours>.from(this.days),
    );
  }

  DayOperatingHours forWeekday(int weekday) {
    if (everydaySame) {
      return DayOperatingHours(
        isOpen: true,
        openTime: everydayOpen,
        closeTime: everydayClose,
      );
    }
    return days[weekday] ?? DayOperatingHours(openTime: everydayOpen, closeTime: everydayClose);
  }

  String infoSummary({DateTime? now}) {
    final targetDay = (now ?? DateTime.now()).weekday;
    if (everydaySame) {
      return 'Buka setiap hari • $everydayOpen - $everydayClose WIB';
    }
    final today = forWeekday(targetDay);
    final label = weekdayLabel(targetDay);
    if (!today.isOpen) {
      return 'Tutup hari ini ($label)';
    }
    return 'Hari ini ($label) • ${today.openTime} - ${today.closeTime} WIB';
  }

  String portalSubtitle() {
    if (everydaySame) {
      return 'Setiap Hari: $everydayOpen - $everydayClose WIB';
    }
    final openDays = orderedWeekdays.where((d) => forWeekday(d).isOpen).length;
    return 'Jadwal Senin - Minggu ($openDays hari buka)';
  }

  Map<String, dynamic> toJson() => {
        'everydaySame': everydaySame,
        'everydayOpen': everydayOpen,
        'everydayClose': everydayClose,
        'days': {
          for (final entry in days.entries) entry.key.toString(): entry.value.toJson(),
        },
      };

  factory MerchantOperatingSchedule.fromJson(Map<String, dynamic> json) {
    final open = (json['everydayOpen'] ?? '09:00').toString();
    final close = (json['everydayClose'] ?? '21:00').toString();
    final parsedDays = <int, DayOperatingHours>{
      for (final d in orderedWeekdays) d: DayOperatingHours(openTime: open, closeTime: close),
    };
    final rawDays = json['days'];
    if (rawDays is Map) {
      for (final entry in rawDays.entries) {
        final dayInt = int.tryParse(entry.key.toString());
        if (dayInt != null && entry.value is Map) {
          parsedDays[dayInt] = DayOperatingHours.fromJson(
            Map<String, dynamic>.from(entry.value as Map),
          );
        }
      }
    }
    return MerchantOperatingSchedule(
      everydaySame: json['everydaySame'] != false,
      everydayOpen: open,
      everydayClose: close,
      days: parsedDays,
    );
  }
}

/// Persisted storefront overrides & metadata editable in Merchant Portal and read by Customer & Driver.
class MerchantStorefrontData {
  final String merchantId;
  final String? name;
  final String? address;
  final String? bio;
  final String? bannerPhoto;
  final String? logoPhoto;
  final String? locationPhoto;
  final double? latitude;
  final double? longitude;
  final bool? isOpen;
  final MerchantOperatingSchedule? schedule;
  final List<String>? categoryOrder;
  final Map<String, int>? itemPromoPrices;

  const MerchantStorefrontData({
    required this.merchantId,
    this.name,
    this.address,
    this.bio,
    this.bannerPhoto,
    this.logoPhoto,
    this.locationPhoto,
    this.latitude,
    this.longitude,
    this.isOpen,
    this.schedule,
    this.categoryOrder,
    this.itemPromoPrices,
  });

  MerchantStorefrontData copyWith({
    String? merchantId,
    String? name,
    String? address,
    String? bio,
    String? bannerPhoto,
    String? logoPhoto,
    String? locationPhoto,
    double? latitude,
    double? longitude,
    bool? isOpen,
    MerchantOperatingSchedule? schedule,
    List<String>? categoryOrder,
    Map<String, int>? itemPromoPrices,
  }) {
    return MerchantStorefrontData(
      merchantId: merchantId ?? this.merchantId,
      name: name ?? this.name,
      address: address ?? this.address,
      bio: bio ?? this.bio,
      bannerPhoto: bannerPhoto ?? this.bannerPhoto,
      logoPhoto: logoPhoto ?? this.logoPhoto,
      locationPhoto: locationPhoto ?? this.locationPhoto,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isOpen: isOpen ?? this.isOpen,
      schedule: schedule ?? this.schedule,
      categoryOrder: categoryOrder ?? this.categoryOrder,
      itemPromoPrices: itemPromoPrices ?? this.itemPromoPrices,
    );
  }

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        if (name != null) 'name': name,
        if (address != null) 'address': address,
        if (bio != null) 'bio': bio,
        if (bannerPhoto != null) 'bannerPhoto': bannerPhoto,
        if (logoPhoto != null) 'logoPhoto': logoPhoto,
        if (locationPhoto != null) 'locationPhoto': locationPhoto,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (isOpen != null) 'isOpen': isOpen,
        if (schedule != null) 'schedule': schedule!.toJson(),
        if (categoryOrder != null) 'categoryOrder': categoryOrder,
        if (itemPromoPrices != null) 'itemPromoPrices': itemPromoPrices,
      };

  factory MerchantStorefrontData.fromJson(String id, Map<String, dynamic> json) {
    final rawSchedule = json['schedule'];
    final rawCategories = json['categoryOrder'];
    List<String>? parsedCategoryOrder;
    if (rawCategories is List) {
      parsedCategoryOrder = rawCategories
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    final rawPromos = json['itemPromoPrices'];
    Map<String, int>? parsedPromoPrices;
    if (rawPromos is Map) {
      parsedPromoPrices = {};
      for (final entry in rawPromos.entries) {
        final v = entry.value is num
            ? (entry.value as num).toInt()
            : int.tryParse(entry.value.toString());
        if (v != null && v >= 0) {
          parsedPromoPrices[entry.key.toString()] = v;
        }
      }
    }
    return MerchantStorefrontData(
      merchantId: id,
      name: json['name']?.toString(),
      address: json['address']?.toString(),
      bio: json['bio']?.toString(),
      bannerPhoto: json['bannerPhoto']?.toString(),
      logoPhoto: json['logoPhoto']?.toString(),
      locationPhoto: json['locationPhoto']?.toString(),
      latitude: (json['latitude'] is num) ? (json['latitude'] as num).toDouble() : double.tryParse('${json['latitude']}'),
      longitude: (json['longitude'] is num) ? (json['longitude'] as num).toDouble() : double.tryParse('${json['longitude']}'),
      isOpen: json['isOpen'] is bool ? json['isOpen'] as bool : null,
      schedule: rawSchedule is Map ? MerchantOperatingSchedule.fromJson(Map<String, dynamic>.from(rawSchedule)) : null,
      categoryOrder: parsedCategoryOrder,
      itemPromoPrices: parsedPromoPrices,
    );
  }
}

class MerchantRatingSummary {
  final double averageRating;
  final int totalReviews;
  final List<Map<String, dynamic>> reviews;

  const MerchantRatingSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.reviews,
  });

  String get formattedCount => '$totalReviews';
}

/// Shared service synchronizing merchant operating hours, storefront/location photos,
/// map pin coordinates, and actual buyer reviews across Merchant, Customer, and Driver portals.
class MerchantStorefrontService {
  static const String defaultPortalMerchantId = 'mch-dimsum-01';
  static const LatLng defaultPracimantoroCenter = LatLng(-8.0892, 110.8374);

  static const String _storefrontKeyPrefix = 'gage_merchant_storefront_';
  static const String _reviewsKeyPrefix = 'gage_merchant_reviews_';
  static const String _nameToIdIndexKey = 'gage_merchant_name_id_index';

  static const Map<String, LatLng> _seedCoordinates = {
    'mch-dimsum-01': LatLng(-8.0892, 110.8374),
    'm-dimsum-sewu': LatLng(-8.0892, 110.8374),
    'mch-rc-01': LatLng(-8.0872, 110.8354),
    'mch-mie-01': LatLng(-8.0901, 110.8382),
    'mch-seblak-01': LatLng(-8.0890, 110.8365),
    'mch-roti-01': LatLng(-8.0885, 110.8370),
    'shop-berkah-fajar': LatLng(-8.0895, 110.8390),
    'shop-kelontong-bu-sri': LatLng(-8.0888, 110.8381),
    'shop-minimarket-losari': LatLng(-8.0842, 110.8435),
    'shop-grosir-sentosa': LatLng(-8.0914, 110.8368),
    'shop-sayur-bu-marti': LatLng(-8.0898, 110.8378),
    'shop-sumber-lancar': LatLng(-8.0879, 110.8392),
    'farm-kios-subur': LatLng(-8.0860, 110.8340),
    'farm-sumber-rejeki': LatLng(-8.0893, 110.8386),
    'farm-tani-lestari': LatLng(-8.0920, 110.8420),
    'farm-ud-berkah-joho': LatLng(-8.0825, 110.8315),
    'farm-poultry-berkah': LatLng(-8.0882, 110.8360),
    'farm-depot-harapan': LatLng(-8.0868, 110.8348),
    'farm-kios-sedayu': LatLng(-8.0835, 110.8442),
    'farm-sentra-mandiri': LatLng(-8.0850, 110.8330),
    'build-sumber-bangunan': LatLng(-8.0886, 110.8376),
    'build-griya-indah': LatLng(-8.0896, 110.8388),
    'build-sinar-mandiri': LatLng(-8.0871, 110.8356),
    'build-sumber-abadi': LatLng(-8.0875, 110.8350),
    'build-sinar-mulia': LatLng(-8.0880, 110.8360),
    'build-berkah-jaya': LatLng(-8.0930, 110.8430),
  };

  static LatLng? seedCoordinateFor(String? merchantId) {
    final id = (merchantId ?? '').trim();
    if (id.isEmpty) return null;
    return _seedCoordinates[id];
  }

  static LatLng resolveCoordinate({
    String? merchantId,
    double? overrideLat,
    double? overrideLng,
    double? merchantLat,
    double? merchantLng,
  }) {
    if (overrideLat != null && overrideLng != null && overrideLat != 0 && overrideLng != 0) {
      return LatLng(overrideLat, overrideLng);
    }
    if (merchantLat != null && merchantLng != null && merchantLat != 0 && merchantLng != 0) {
      return LatLng(merchantLat, merchantLng);
    }
    return seedCoordinateFor(merchantId) ?? defaultPracimantoroCenter;
  }

  static Future<String> resolveMerchantId({
    String? merchantId,
    String? merchantName,
  }) async {
    final direct = (merchantId ?? '').trim();
    if (direct.isNotEmpty) return direct;

    final cleanName = (merchantName ?? '').trim().toLowerCase();
    if (cleanName.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final rawMap = prefs.getString(_nameToIdIndexKey);
      if (rawMap != null && rawMap.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawMap);
          if (decoded is Map) {
            final exact = decoded[cleanName];
            if (exact != null && exact.toString().isNotEmpty) {
              return exact.toString();
            }
            for (final entry in decoded.entries) {
              final k = entry.key.toString();
              if (cleanName.contains(k) || k.contains(cleanName)) {
                return entry.value.toString();
              }
            }
          }
        } catch (_) {}
      }
      if (cleanName.contains('dimsum sewu')) return defaultPortalMerchantId;
    }
    return defaultPortalMerchantId;
  }

  static Future<MerchantStorefrontData?> loadStorefront(
    String? merchantId, {
    String? merchantName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final targetId = (merchantId != null && merchantId.trim().isNotEmpty)
        ? merchantId.trim()
        : await resolveMerchantId(merchantName: merchantName);

    String? raw = prefs.getString('$_storefrontKeyPrefix$targetId');
    if ((raw == null || raw.isEmpty) && targetId == 'm-dimsum-sewu') {
      raw = prefs.getString('$_storefrontKeyPrefix$defaultPortalMerchantId');
    }
    if ((raw == null || raw.isEmpty) && targetId == defaultPortalMerchantId) {
      raw = prefs.getString('${_storefrontKeyPrefix}m-dimsum-sewu');
    }
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return MerchantStorefrontData.fromJson(
          targetId,
          Map<String, dynamic>.from(decoded),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<void> saveStorefront(MerchantStorefrontData data) async {
    final prefs = await SharedPreferences.getInstance();
    final targetId = data.merchantId.trim().isNotEmpty
        ? data.merchantId.trim()
        : defaultPortalMerchantId;

    await prefs.setString('$_storefrontKeyPrefix$targetId', jsonEncode(data.toJson()));

    if (data.name != null && data.name!.trim().isNotEmpty) {
      Map<String, dynamic> nameIndex = {};
      final rawIndex = prefs.getString(_nameToIdIndexKey);
      if (rawIndex != null && rawIndex.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawIndex);
          if (decoded is Map) nameIndex = Map<String, dynamic>.from(decoded);
        } catch (_) {}
      }
      nameIndex[data.name!.trim().toLowerCase()] = targetId;
      await prefs.setString(_nameToIdIndexKey, jsonEncode(nameIndex));
    }
  }

  static Future<void> submitBuyerReview({
    String? merchantId,
    required String merchantName,
    required String domain,
    required int stars,
    required String comment,
    List<String> orderedItems = const [],
    String userName = 'Pelanggan GAGE',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final targetId = await resolveMerchantId(
      merchantId: merchantId,
      merchantName: merchantName,
    );
    final key = '$_reviewsKeyPrefix$targetId';
    final List<dynamic> current = [];
    final existingRaw = prefs.getString(key);
    if (existingRaw != null && existingRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(existingRaw);
        if (decoded is List) current.addAll(decoded);
      } catch (_) {}
    }

    final safeUser = userName.trim().isNotEmpty ? userName.trim() : 'Pelanggan GAGE';
    final initial = safeUser.substring(0, 1).toUpperCase();
    final cleanComment = comment.trim().isNotEmpty
        ? comment.trim()
        : 'Pesanan sesuai, pelayanan ramah dan cepat.';

    current.insert(0, {
      'userName': safeUser,
      'userAvatar': initial,
      'avatarColorValue': Colors.red.shade600.toARGB32(),
      'date': 'Baru saja',
      'stars': stars.clamp(1, 5),
      'comment': cleanComment,
      'orderedItems': orderedItems,
      'reply': null,
      'domain': domain,
      'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    });

    await prefs.setString(key, jsonEncode(current));
  }

  static Future<MerchantRatingSummary> loadRatingSummary({
    String? merchantId,
    String? merchantName,
    required String domain,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final targetId = (merchantId != null && merchantId.trim().isNotEmpty)
        ? merchantId.trim()
        : await resolveMerchantId(merchantName: merchantName);

    final userReviews = <Map<String, dynamic>>[];
    final raw = prefs.getString('$_reviewsKeyPrefix$targetId');
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final map = Map<String, dynamic>.from(item);
              final colorVal = map['avatarColorValue'];
              userReviews.add({
                'userName': (map['userName'] ?? 'Pelanggan GAGE').toString(),
                'userAvatar': (map['userAvatar'] ?? 'P').toString(),
                'avatarColor': colorVal is int ? Color(colorVal) : Colors.indigo,
                'date': (map['date'] ?? 'Baru saja').toString(),
                'stars': (map['stars'] is num) ? (map['stars'] as num).toInt().clamp(1, 5) : 5,
                'comment': (map['comment'] ?? '').toString(),
                'orderedItems': map['orderedItems'] is List
                    ? (map['orderedItems'] as List).map((e) => e.toString()).toList()
                    : null,
                'reply': map['reply'],
              });
            }
          }
        }
      } catch (_) {}
    }

    final seeds = seedReviewsForDomain(domain);
    final combined = <Map<String, dynamic>>[...userReviews, ...seeds];

    if (combined.isEmpty) {
      return const MerchantRatingSummary(
        averageRating: 0.0,
        totalReviews: 0,
        reviews: [],
      );
    }

    final sum = combined.fold<int>(
      0,
      (acc, r) => acc + ((r['stars'] is num) ? (r['stars'] as num).toInt() : 5),
    );
    final avg = double.parse((sum / combined.length).toStringAsFixed(1));
    return MerchantRatingSummary(
      averageRating: avg,
      totalReviews: combined.length,
      reviews: combined,
    );
  }

  static List<Map<String, dynamic>> seedReviewsForDomain(String domain) {
    if (!GageApiClient.useDevSeedData) return const [];
    switch (domain.trim().toLowerCase()) {
      case 'shop':
        return _shopSeedReviews;
      case 'farm':
        return _farmSeedReviews;
      case 'build':
        return _buildSeedReviews;
      default:
        return _foodSeedReviews;
    }
  }

  static final List<Map<String, dynamic>> _shopSeedReviews = [
    {
      'userName': 'Rina Wulandari',
      'userAvatar': 'R',
      'avatarColor': Colors.teal,
      'date': 'Kemarin',
      'stars': 5,
      'comment': 'Beras pulen asli sesuai timbangan dan minyak goreng masih tersegel rapi. Antar cepat!',
      'orderedItems': ['Beras C4 Super Raja 5 Kg', 'Minyak Goreng 2 Liter'],
      'reply': 'Terima kasih kak Rina sudah belanja sembako di toko kami!',
    },
    {
      'userName': 'Agus Prasetyo',
      'userAvatar': 'A',
      'avatarColor': Colors.indigo,
      'date': '3 hari lalu',
      'stars': 5,
      'comment': 'Barang lengkap, harga bersaing dengan pasar, dan kurir ramah mengantar sampai rumah.',
      'orderedItems': ['Telur Ayam Segar 1 Kg', 'Gula Pasir 1 Kg'],
      'reply': null,
    },
    {
      'userName': 'Yuni Kartika',
      'userAvatar': 'Y',
      'avatarColor': Colors.deepOrange,
      'date': '1 minggu lalu',
      'stars': 4,
      'comment': 'Pengemasan kardus rapi sehingga mie dan telur tidak pecah saat perjalanan.',
      'orderedItems': ['Mie Instan 1 Dus', 'Kecap Manis'],
      'reply': 'Siap kak Yuni, kualitas pengemasan selalu kami jaga.',
    },
  ];

  static final List<Map<String, dynamic>> _farmSeedReviews = [
    {
      'userName': 'Slamet Widodo',
      'userAvatar': 'S',
      'avatarColor': Colors.green,
      'date': 'Kemarin',
      'stars': 5,
      'comment': 'Pupuk NPK masih segel pabrikan dan langsung dikirim ke lahan tanpa repot ambil sendiri.',
      'orderedItems': ['Pupuk NPK Mutiara 16-16-16 (1 Kg)'],
      'reply': 'Terima kasih Pak Slamet, semoga panennya melimpah!',
    },
    {
      'userName': 'Heri Purnomo',
      'userAvatar': 'H',
      'avatarColor': Colors.brown,
      'date': '5 hari lalu',
      'stars': 5,
      'comment': 'Pakan ayam broiler baru dan tidak apek, tanggal produksinya masih fresh.',
      'orderedItems': ['Pakan Ayam Broiler BR-1 5 Kg', 'Vitamin Ternak'],
      'reply': null,
    },
  ];

  static final List<Map<String, dynamic>> _buildSeedReviews = [
    {
      'userName': 'Mandor Yanto',
      'userAvatar': 'Y',
      'avatarColor': Colors.blueGrey,
      'date': 'Kemarin',
      'stars': 5,
      'comment': 'Semen kering tidak menggumpal dan cat sesuai kode warna pesanan. Sangat membantu proyek!',
      'orderedItems': ['Semen Gresik PCC 40 Kg', 'Cat Tembok Putih 5 Kg'],
      'reply': 'Terima kasih Pak Yanto sudah berlangganan material di toko kami.',
    },
    {
      'userName': 'Hendrik Saputra',
      'userAvatar': 'H',
      'avatarColor': Colors.orange,
      'date': '4 hari lalu',
      'stars': 4,
      'comment': 'Pengiriman material cepat, harga transparan sesuai aplikasi.',
      'orderedItems': ['Paku Baja 1 Kg', 'Kuas Cat 3 Inch'],
      'reply': null,
    },
  ];

  static final List<Map<String, dynamic>> _foodSeedReviews = [
    {
      'userName': 'Dimas Prasetyo',
      'userAvatar': 'D',
      'avatarColor': Colors.indigo,
      'date': 'Kemarin',
      'stars': 5,
      'comment': 'Porsi mantap, sambalnya nendang pol! Pengemasan rapi dan masih hangat saat sampai. Recommended!',
      'orderedItems': ['Paket Nasi Ayam Geprek', 'Es Teh Jumbo'],
      'reply': 'Terima kasih banyak kak Dimas sudah berlangganan! Ditunggu orderan selanjutnya ya',
    },
    {
      'userName': 'Siti Nurhaliza',
      'userAvatar': 'S',
      'avatarColor': Colors.teal,
      'date': '2 hari lalu',
      'stars': 5,
      'comment': 'Rasanya enak konsisten dari dulu. Pilihan level pedasnya pas sesuai request catatan.',
      'orderedItems': ['Nasi Goreng Spesial Telur Ceplok'],
      'reply': null,
    },
    {
      'userName': 'Budi Santoso',
      'userAvatar': 'B',
      'avatarColor': Colors.deepOrange,
      'date': '4 hari lalu',
      'stars': 4,
      'comment': 'Enak dan porsi cukup kenyang. Cuma waktu penyiapan agak sedikit lama mungkin karena jam makan siang ramai.',
      'orderedItems': ['Mie Goreng Jawa Mas Bro', 'Kerupuk Kaleng'],
      'reply': 'Mohon maaf atas waktu tunggunya kak Budi saat jam sibuk. Tim dapur kami terus tingkatkan kecepatannya',
    },
    {
      'userName': 'Anisa Rahmawati',
      'userAvatar': 'A',
      'avatarColor': Colors.purple,
      'date': '1 minggu lalu',
      'stars': 5,
      'comment': 'Packaging ramah lingkungan, ada segel higienisnya. Makanan bersih dan fresh!',
      'orderedItems': ['Ayam Bakar Madu', 'Nasi Uduk Gurih'],
      'reply': null,
    },
    {
      'userName': 'Rendra Kurnia',
      'userAvatar': 'R',
      'avatarColor': Colors.blueGrey,
      'date': '2 minggu lalu',
      'stars': 3,
      'comment': 'Rasa oke standar, cuma sambalnya kurang banyak menurut saya. Semoga bisa ditambah opsi extra sambal.',
      'orderedItems': ['Bebek Goreng Crispy'],
      'reply': 'Siap kak Rendra, saran sudah kami catat untuk sediakan opsi extra sambal di menu. Terima kasih masukkannya!',
    },
    {
      'userName': 'Fitri Handayani',
      'userAvatar': 'F',
      'avatarColor': Colors.pink,
      'date': '3 minggu lalu',
      'stars': 5,
      'comment': 'Langganan keluarga kalau lagi mager masak. Semua menu enak gak ada yang gagal!',
      'orderedItems': ['Paket Family 4 Orang', 'Tahu Tempe Goreng'],
      'reply': null,
    },
  ];
}
