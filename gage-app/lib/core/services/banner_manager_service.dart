import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'GAGE Pracimantoro SuperApp',
      subtitle: 'Pesan kuliner, sembako, dan kirim barang se-kecamatan',
      badge: 'PROMO UTAMA',
      imagePath: 'assets/images/home_hero_banner.png',
      ctaText: 'Eksplor Layanan',
    );

    _banners['food'] = const BannerConfig(
      menuKey: 'food',
      menuName: 'GAGE Food',
      title: 'Laper? GAGE Food-in\ndari resto terenak!',
      subtitle: 'Diskon s/d 50% & ongkir flat bersahabat mitra lokal',
      badge: 'PROMO KULINER HARI INI',
      imagePath: 'assets/images/food_hero_banner.png',
      ctaText: 'Pesan Sekarang',
    );

    _banners['shop'] = const BannerConfig(
      menuKey: 'shop',
      menuName: 'GAGE Shop',
      title: 'Belanja Sembako Multi-Merchant',
      subtitle: 'Bisa gabung hingga 3 toko mitra resmi Pracimantoro!',
      badge: 'SEMBAKO HEMAT',
      imagePath: 'assets/images/shop_hero_banner.png',
      ctaText: 'Mulai Belanja',
    );

    _banners['send'] = const BannerConfig(
      menuKey: 'send',
      menuName: 'GAGE Send',
      title: 'Kirim Kilat Se-Kecamatan',
      subtitle: 'Tarif flat mulai Rp 4.000 • Dijemput & diantar langsung sampai pintu',
      badge: 'KIRIM INSTAN',
      imagePath: 'assets/images/send_hero_banner.png',
      ctaText: 'Panggil Kurir',
    );

    _banners['babe'] = const BannerConfig(
      menuKey: 'babe',
      menuName: 'GAGE BaBe (Barang Bekas)',
      title: 'GAGE BaBe - Lapak Barang Bekas Resmi GAGE',
      subtitle: 'Barang terverifikasi tim kurir • Bebas transaksi gelap • Jaminan garansi 48 jam',
      badge: 'LAPAK RESMI GAGE',
      imagePath: 'assets/images/babe_hero_banner.png',
      ctaText: 'Titip Jual Sekarang',
    );

    _banners['ride'] = const BannerConfig(
      menuKey: 'ride',
      menuName: 'GAGE Ride & Car',
      title: 'Antar Jemput Cepat & Nyaman',
      subtitle: 'Driver lokal ramah Pracimantoro, tarif jujur tanpa argo siluman',
      badge: 'TARIF FLAT KECAMATAN',
      imagePath: 'assets/images/ride_hero_banner.png',
      ctaText: 'Pesan Perjalanan',
    );

    _banners['tani'] = const BannerConfig(
      menuKey: 'tani',
      menuName: 'GAGE Tani',
      title: 'Lapak Agro Pertanian Resmi GAGE',
      subtitle: 'Saprotan, pupuk, benih, hasil bumi & konsultasi gratis ahli',
      badge: 'AGRO TANI RESMI',
      imagePath: 'assets/images/tani_hero_banner.png',
      ctaText: 'Belanja Tani',
    );

    _banners['ternak'] = const BannerConfig(
      menuKey: 'ternak',
      menuName: 'GAGE Ternak',
      title: 'Lapak Peternakan & Pasar Hewan Resmi GAGE',
      subtitle: 'Pakan ternak, vitamin, kambing, sapi & konsultasi dokter hewan',
      badge: 'PETERNAKAN RESMI',
      imagePath: 'assets/images/ternak_hero_banner.png',
      ctaText: 'Belanja Ternak',
    );
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
            _banners[key] = BannerConfig.fromMap(val);
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading banner configs: $e');
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

  /// Mengambil konfigurasi banner berdasarkan menu key
  BannerConfig getBanner(String menuKey) {
    if (_banners.containsKey(menuKey)) {
      return _banners[menuKey]!;
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
