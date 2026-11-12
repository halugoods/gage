import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Model konfigurasi banner per menu customer
class BannerConfig {
  final String menuKey;
  final String menuName;
  final String title;
  final String subtitle;
  final String badge;
  final String imagePath;
  final String ctaText;
  final bool isActive;

  const BannerConfig({
    required this.menuKey,
    required this.menuName,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.imagePath,
    this.ctaText = 'Lihat Promo',
    this.isActive = true,
  });

  BannerConfig copyWith({
    String? menuKey,
    String? menuName,
    String? title,
    String? subtitle,
    String? badge,
    String? imagePath,
    String? ctaText,
    bool? isActive,
  }) {
    return BannerConfig(
      menuKey: menuKey ?? this.menuKey,
      menuName: menuName ?? this.menuName,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      badge: badge ?? this.badge,
      imagePath: imagePath ?? this.imagePath,
      ctaText: ctaText ?? this.ctaText,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuKey': menuKey,
      'menuName': menuName,
      'title': title,
      'subtitle': subtitle,
      'badge': badge,
      'imagePath': imagePath,
      'ctaText': ctaText,
      'isActive': isActive,
    };
  }

  factory BannerConfig.fromMap(Map<String, dynamic> map) {
    return BannerConfig(
      menuKey: map['menuKey'] as String? ?? 'beranda',
      menuName: map['menuName'] as String? ?? 'Menu',
      title: map['title'] as String? ?? '',
      subtitle: map['subtitle'] as String? ?? '',
      badge: map['badge'] as String? ?? 'PROMO',
      imagePath: map['imagePath'] as String? ?? 'assets/images/home_hero_banner.png',
      ctaText: map['ctaText'] as String? ?? 'Lihat Promo',
      isActive: map['isActive'] as bool? ?? true,
    );
  }

  String toJson() => json.encode(toMap());

  factory BannerConfig.fromJson(String source) =>
      BannerConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

/// Service Singleton & ChangeNotifier untuk mengelola banner per menu di GAGE Pracimantoro
class BannerManagerService extends ChangeNotifier {
  static final BannerManagerService _instance = BannerManagerService._internal();
  factory BannerManagerService() => _instance;
  BannerManagerService._internal() {
    _initDefaults();
    loadFromPrefs();
  }

  static BannerManagerService get instance => _instance;

  static const String _prefKey = 'gage_banner_manager_configs';

  final Map<String, BannerConfig> _banners = {};

  Map<String, BannerConfig> get allBanners => Map.unmodifiable(_banners);

  void _initDefaults() {
    _banners['beranda'] = const BannerConfig(
      menuKey: 'beranda',
      menuName: 'Beranda Utama',
      title: 'GAGE Pracimantoro',
      subtitle: 'Pesan kuliner, belanja, dan kirim barang se-Pracimantoro',
      badge: '',
      imagePath: 'assets/images/home_hero_banner.png',
      ctaText: 'Eksplor Layanan',
    );

    _banners['food'] = const BannerConfig(
      menuKey: 'food',
      menuName: 'GAGE Food',
      title: 'Laper? GAGE Food-in\ndari resto terenak!',
      subtitle: 'Diskon s/d 50% & ongkir hemat mitra lokal',
      badge: '',
      imagePath: 'assets/images/food_hero_banner.png',
      ctaText: 'Pesan Sekarang',
    );

    _banners['shop'] = const BannerConfig(
      menuKey: 'shop',
      menuName: 'GAGE Shop',
      title: 'Belanja Sembako & Kebutuhan Harian',
      subtitle: 'Mitra toko kelontong & sembako terpercaya Pracimantoro',
      badge: '',
      imagePath: 'assets/images/shop_hero_banner.png',
      ctaText: 'Mulai Belanja',
    );

    _banners['send'] = const BannerConfig(
      menuKey: 'send',
      menuName: 'GAGE Send',
      title: 'Kirim Kilat Se-Pracimantoro',
      subtitle: 'Kirim paket & barang dagangan kilat, dijemput langsung sampai pintu',
      badge: '',
      imagePath: 'assets/images/send_hero_banner.png',
      ctaText: 'Panggil Kurir',
    );

    _banners['ride'] = const BannerConfig(
      menuKey: 'ride',
      menuName: 'GAGE Ride & Car',
      title: 'Antar Jemput Cepat & Nyaman',
      subtitle: 'Driver lokal ramah Pracimantoro, tarif jujur sesuai jarak tempuh',
      badge: '',
      imagePath: 'assets/images/ride_hero_banner.png',
      ctaText: 'Pesan Perjalanan',
    );

    _banners['tani'] = const BannerConfig(
      menuKey: 'tani',
      menuName: 'GAGE Tani',
      title: 'Lapak Agro Pertanian Resmi GAGE',
      subtitle: 'Saprotan, pupuk, benih, hasil bumi & konsultasi gratis ahli',
      badge: '',
      imagePath: 'assets/images/tani_hero_banner.png',
      ctaText: 'Belanja Tani',
    );

    _banners['ternak'] = const BannerConfig(
      menuKey: 'ternak',
      menuName: 'GAGE Ternak',
      title: 'Lapak Peternakan & Pasar Hewan Resmi GAGE',
      subtitle: 'Pakan ternak, vitamin, kambing, sapi & konsultasi dokter hewan',
      badge: '',
      imagePath: 'assets/images/ternak_hero_banner.png',
      ctaText: 'Belanja Ternak',
    );

    // Standalone screen targets (Cloudflare D1 Standalone Banners)
    _banners['customer_home_hero'] = const BannerConfig(
      menuKey: 'customer_home_hero',
      menuName: 'Beranda Pelanggan',
      title: 'GAGE Pracimantoro',
      subtitle: 'Pesan kuliner, belanja, dan kirim barang se-Pracimantoro',
      badge: '',
      imagePath: 'assets/images/home_hero_banner.png',
      ctaText: 'Eksplor Layanan',
    );

    _banners['customer_food_explore'] = const BannerConfig(
      menuKey: 'customer_food_explore',
      menuName: 'GAGE Food Kuliner',
      title: 'Laper? GAGE Food-in\ndari resto terenak!',
      subtitle: 'Diskon s/d 50% & ongkir hemat mitra lokal',
      badge: '',
      imagePath: 'assets/images/food_hero_banner.png',
      ctaText: 'Pesan Sekarang',
    );

    _banners['customer_tani'] = const BannerConfig(
      menuKey: 'customer_tani',
      menuName: 'GAGE Tani & Ternak',
      title: 'Lapak Agro Pertanian Resmi GAGE',
      subtitle: 'Saprotan, pupuk, benih, hasil bumi & konsultasi gratis ahli',
      badge: '',
      imagePath: 'assets/images/tani_hero_banner.png',
      ctaText: 'Belanja Tani',
    );

    _banners['customer_shop'] = const BannerConfig(
      menuKey: 'customer_shop',
      menuName: 'GAGE Shop Sembako',
      title: 'Belanja Sembako & Kebutuhan Harian',
      subtitle: 'Mitra toko kelontong & sembako terpercaya Pracimantoro',
      badge: '',
      imagePath: 'assets/images/shop_hero_banner.png',
      ctaText: 'Mulai Belanja',
    );

    _banners['customer_build'] = const BannerConfig(
      menuKey: 'customer_build',
      menuName: 'GAGE Build Material',
      title: 'Material Bangunan & Tukang Lengkap',
      subtitle: 'Semen, cat, besi SNI & perkakas antar langsung ke lokasi proyek',
      badge: '',
      imagePath: 'assets/images/prod_semen.png',
      ctaText: 'Belanja Material',
    );

    _banners['build'] = _banners['customer_build']!;

    _banners['driver_home_info'] = const BannerConfig(
      menuKey: 'driver_home_info',
      menuName: 'GAGE Driver Info',
      title: 'Tips Aman & Ramai Order Pracimantoro',
      subtitle: 'Standby di Terminal & Pasar saat jam sibuk pagi untuk order maksimal',
      badge: '',
      imagePath: 'assets/images/home_hero_banner.png',
      ctaText: 'Pelajari',
    );

    _banners['merchant_home_info'] = const BannerConfig(
      menuKey: 'merchant_home_info',
      menuName: 'GAGE Merchant Info',
      title: 'Tingkatkan Penjualan Toko Anda',
      subtitle: 'Perbarui stok menu andalan & aktifkan promo diskon jam makan siang',
      badge: '',
      imagePath: 'assets/images/food_hero_banner.png',
      ctaText: 'Kelola Menu',
    );

    _banners['admin_promo'] = const BannerConfig(
      menuKey: 'admin_promo',
      menuName: 'GAGE Admin Info',
      title: 'Pusat Manajemen Ekosistem GAGE',
      subtitle: 'Pantau transaksi realtime, validasi mitra, dan kelola banner promosi',
      badge: '',
      imagePath: 'assets/images/home_hero_banner.png',
      ctaText: 'Kelola Banner',
    );

    // Slide Promo Carousel
    _banners['customer_promo_carousel_slide_1'] = const BannerConfig(
      menuKey: 'customer_promo_carousel_slide_1',
      menuName: 'Promo Slide 1',
      title: 'Pesta Kuliner Spesial',
      subtitle: 'Diskon 50% & Gratis Ongkir Pesanan',
      badge: '',
      imagePath: 'assets/images/food_hero_banner.png',
      ctaText: 'Pesan Sekarang',
    );
    _banners['customer_promo_carousel_slide_2'] = const BannerConfig(
      menuKey: 'customer_promo_carousel_slide_2',
      menuName: 'Promo Slide 2',
      title: 'Kirim Kilat GAGE Send',
      subtitle: 'Tarif Hemat Kirim Paket Instan',
      badge: '',
      imagePath: 'assets/images/send_hero_banner.png',
      ctaText: 'Panggil Kurir',
    );
    _banners['customer_promo_carousel_slide_3'] = const BannerConfig(
      menuKey: 'customer_promo_carousel_slide_3',
      menuName: 'Promo Slide 3',
      title: 'GAGE Ride & Car',
      subtitle: 'Perjalanan Nyaman dengan Tarif Hemat',
      badge: '',
      imagePath: 'assets/images/ride_hero_banner.png',
      ctaText: 'Pesan Perjalanan',
    );
    _banners['customer_promo_carousel_slide_4'] = const BannerConfig(
      menuKey: 'customer_promo_carousel_slide_4',
      menuName: 'Promo Slide 4',
      title: 'Belanja Sembako Lengkap',
      subtitle: 'Grosir & Eceran Pasar Pracimantoro',
      badge: '',
      imagePath: 'assets/images/shop_hero_banner.png',
      ctaText: 'Mulai Belanja',
    );
  }

  String _sanitizeImagePath(String target, String imagePath) {
    final normalizedTarget = target.trim().toLowerCase();
    final trimmed = imagePath.trim();
    if ((normalizedTarget == 'customer_shop' || normalizedTarget == 'shop') &&
        (trimmed.isEmpty || trimmed == 'assets/images/send_hero_banner.png')) {
      return 'assets/images/shop_hero_banner.png';
    }
    if ((normalizedTarget == 'customer_build' || normalizedTarget == 'build') &&
        (trimmed.isEmpty || trimmed.contains('ic_build'))) {
      return 'assets/images/prod_semen.png';
    }
    return trimmed;
  }

  /// Memuat konfigurasi banner dari SharedPreferences
  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedString = prefs.getString(_prefKey);
      if (savedString != null && savedString.isNotEmpty) {
        final Map<String, dynamic> decoded = json.decode(savedString) as Map<String, dynamic>;
        decoded.forEach((key, val) {
          if (val is Map<String, dynamic>) {
            final parsed = BannerConfig.fromMap(val);
            _banners[key] = parsed.copyWith(
              imagePath: _sanitizeImagePath(key, parsed.imagePath),
            );
          }
        });
        notifyListeners();
      }
      // D1 Quota Shield: Fetch dari Cloudflare Edge Cache
      fetchFromCloud();
    } catch (e) {
      debugPrint('Error loading banner configs: $e');
    }
  }

  /// Sinkronisasi banner aktif dari Cloudflare D1 / Edge Cache
  Future<void> fetchFromCloud() async {
    try {
      final list = await GageApiClient.getBanners('');
      if (list.isNotEmpty) {
        for (final item in list) {
          final target = item['screen_target'] as String? ?? '';
          if (target.isNotEmpty) {
            final rawImg = item['image_url'] as String? ?? 'assets/images/home_hero_banner.png';
            _banners[target] = BannerConfig(
              menuKey: target,
              menuName: target,
              title: item['title'] as String? ?? '',
              subtitle: item['subtitle'] as String? ?? '',
              badge: 'PROMO GAGE',
              imagePath: _sanitizeImagePath(target, rawImg),
              ctaText: 'Lihat Promo',
              isActive: (item['is_active'] == 1 || item['is_active'] == true),
            );
          }
        }
        notifyListeners();
        await saveToPrefs();
      }
    } catch (e) {
      debugPrint('Error fetching cloud banners: $e');
    }
  }

  /// Menyimpan konfigurasi banner ke SharedPreferences
  Future<void> saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> rawMap = {};
      _banners.forEach((key, config) {
        rawMap[key] = config.toMap();
      });
      await prefs.setString(_prefKey, json.encode(rawMap));
    } catch (e) {
      debugPrint('Error saving banner configs: $e');
    }
  }

  /// Mengambil konfigurasi banner berdasarkan menu key (dengan mapping screen_target standalone)
  BannerConfig getBanner(String menuKey) {
    // 1. Cek direct match
    if (_banners.containsKey(menuKey)) {
      return _banners[menuKey]!;
    }

    // 2. Mapping alias ke target standalone
    final aliasMap = {
      'beranda': 'customer_home_hero',
      'food': 'customer_food_explore',
      'tani': 'customer_tani',
      'farm': 'customer_tani',
      'shop': 'customer_shop',
      'build': 'customer_build',
      'driver': 'driver_home_info',
      'merchant': 'merchant_home_info',
      'admin': 'admin_promo',
    };

    final mappedKey = aliasMap[menuKey];
    if (mappedKey != null && _banners.containsKey(mappedKey)) {
      return _banners[mappedKey]!;
    }

    return BannerConfig(
      menuKey: menuKey,
      menuName: menuKey,
      title: 'Promo Spesial GAGE',
      subtitle: 'Nikmati kemudahan layanan lokal Pracimantoro',
      badge: 'PROMO GAGE',
      imagePath: 'assets/images/home_hero_banner.png',
    );
  }

  /// Mengupdate konfigurasi banner untuk menu tertentu
  Future<void> updateBanner(String menuKey, BannerConfig newConfig) async {
    _banners[menuKey] = newConfig;
    notifyListeners();
    await saveToPrefs();
  }

  /// Reset semua banner kembali ke konfigurasi bawaan
  Future<void> resetToDefaults() async {
    _initDefaults();
    notifyListeners();
    await saveToPrefs();
  }
}
