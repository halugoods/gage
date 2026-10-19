import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Metadata untuk slot aset dinamis
class AssetSlotInfo {
  final String key;
  final String label;
  final String category;
  final String defaultPath;
  final String currentPath;

  const AssetSlotInfo({
    required this.key,
    required this.label,
    required this.category,
    required this.defaultPath,
    required this.currentPath,
  });

  bool get isCustomized => currentPath != defaultPath;
}

/// Service Singleton & ChangeNotifier untuk mengelola icon & aset dinamis tanpa build ulang
class DynamicAssetService extends ChangeNotifier {
  static final DynamicAssetService _instance = DynamicAssetService._internal();
  factory DynamicAssetService() => _instance;
  DynamicAssetService._internal() {
    _initDefaults();
    loadFromPrefs();
  }

  static DynamicAssetService get instance => _instance;

  static const String _prefKey = 'gage_dynamic_asset_slots_v1';

  final Map<String, String> _defaults = {};
  final Map<String, String> _overrides = {};
  final Map<String, Map<String, String>> _slotMetadata = {};

  void _initDefaults() {
    _registerSlot(
      key: 'vehicle_ride',
      label: 'GAGE Ride (Motor)',
      category: 'Mobilitas & Armada',
      defaultPath: 'assets/images/gage_ride_3d.png',
    );
    _registerSlot(
      key: 'vehicle_car',
      label: 'GAGE Car (Mobil)',
      category: 'Mobilitas & Armada',
      defaultPath: 'assets/images/gage_car_3d.png',
    );

    // GAGE Cuan & Keuangan
    _registerSlot(
      key: 'cuan_hero_coin',
      label: 'Koin Emas Saldo Cuan',
      category: 'Cuan & Finansial',
      defaultPath: 'assets/icons/clay/ic_clay_coin.png',
    );
    _registerSlot(
      key: 'cuan_withdraw',
      label: 'Dompet Tarik Cuan ke GagePay',
      category: 'Cuan & Finansial',
      defaultPath: 'assets/icons/clay/ic_clay_wallet_withdraw.png',
    );
    _registerSlot(
      key: 'cuan_megaphone',
      label: 'Megafon / Terompet Referral',
      category: 'Cuan & Finansial',
      defaultPath: 'assets/icons/clay/ic_clay_megaphone.png',
    );
    _registerSlot(
      key: 'cuan_share',
      label: 'Tombol Bagikan / Share Link',
      category: 'Sosial & Bagikan',
      defaultPath: 'assets/icons/clay/ic_clay_share.png',
    );

    // Metrik Statistik
    _registerSlot(
      key: 'cuan_metric_clicks',
      label: 'Metrik: Total Klik Tautan',
      category: 'Metrik & Statistik',
      defaultPath: 'assets/icons/clay/ic_clay_clicks.png',
    );
    _registerSlot(
      key: 'cuan_metric_conversion',
      label: 'Metrik: Rasio Konversi',
      category: 'Metrik & Statistik',
      defaultPath: 'assets/icons/clay/ic_clay_conversion.png',
    );
    _registerSlot(
      key: 'cuan_metric_orders',
      label: 'Metrik: Pesanan Berhasil',
      category: 'Metrik & Statistik',
      defaultPath: 'assets/icons/clay/ic_clay_order_success.png',
    );
    _registerSlot(
      key: 'cuan_metric_referrals',
      label: 'Metrik: Referral Aktif',
      category: 'Metrik & Statistik',
      defaultPath: 'assets/icons/clay/ic_clay_referral_users.png',
    );

    // Menu Grid Beranda (8 Layanan Utama)
    _registerSlot(
      key: 'grid_menu_ride_car',
      label: 'Menu: Ride & Car',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_ride.png',
    );
    _registerSlot(
      key: 'grid_menu_food',
      label: 'Menu: GAGE Food',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_food.png',
    );
    _registerSlot(
      key: 'grid_menu_shop',
      label: 'Menu: GAGE Shop',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_mart.png',
    );
    _registerSlot(
      key: 'grid_menu_send',
      label: 'Menu: GAGE Send',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_send.png',
    );
    _registerSlot(
      key: 'grid_menu_tani',
      label: 'Menu: GAGE Tani',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_tani.png',
    );
    _registerSlot(
      key: 'grid_menu_ternak',
      label: 'Menu: GAGE Ternak',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_ternak.png',
    );
    _registerSlot(
      key: 'grid_menu_babe',
      label: 'Menu: GAGE BaBe',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_babe.png',
    );
    _registerSlot(
      key: 'grid_menu_cuan',
      label: 'Menu: GAGE Cuan',
      category: 'Menu Grid Beranda',
      defaultPath: 'assets/icons/ic_bonus.png',
    );
  }

  void _registerSlot({
    required String key,
    required String label,
    required String category,
    required String defaultPath,
  }) {
    _defaults[key] = defaultPath;
    _slotMetadata[key] = {
      'label': label,
      'category': category,
      'defaultPath': defaultPath,
    };
  }

  /// Mendapatkan path gambar aktif untuk slot tertentu (override atau fallback default)
  String getAsset(String slotKey) {
    return _overrides[slotKey] ?? _defaults[slotKey] ?? '';
  }

  /// Memeriksa apakah path merupakan berkas lokal dari galeri atau aset Flutter
  bool isLocalFile(String path) {
    return !path.startsWith('assets/');
  }

  /// Mengubah path aset untuk slot tertentu dan menyimpannya secara persisten
  Future<void> setAsset(String slotKey, String newPath) async {
    _overrides[slotKey] = newPath;
    notifyListeners();
    await _saveToPrefs();
  }

  /// Mereset slot tertentu kembali ke gambar bawaan (default)
  Future<void> resetSlot(String slotKey) async {
    if (_overrides.containsKey(slotKey)) {
      _overrides.remove(slotKey);
      notifyListeners();
      await _saveToPrefs();
    }
  }

  /// Mereset semua kustomisasi kembali ke awal
  Future<void> resetAll() async {
    _overrides.clear();
    notifyListeners();
    await _saveToPrefs();
  }

  /// Mendapatkan daftar semua slot yang terdaftar beserta status kustomisasinya
  List<AssetSlotInfo> get allSlots {
    return _defaults.keys.map((k) {
      final meta = _slotMetadata[k]!;
      return AssetSlotInfo(
        key: k,
        label: meta['label']!,
        category: meta['category']!,
        defaultPath: meta['defaultPath']!,
        currentPath: getAsset(k),
      );
    }).toList();
  }

  /// Daftar aset library bawaan per kategori untuk dipilih di portal admin
  List<String> getLibraryPresetsForCategory(String category) {
    final List<String> presets = [];
    if (category == 'Mobilitas & Armada') {
      presets.addAll([
        'assets/images/gage_ride_3d.png',
        'assets/images/gage_car_3d.png',
        'assets/icons/ic_ride.png',
        'assets/icons/ic_car.png',
        'assets/icons/ic_ride_car.png',
      ]);
    } else if (category == 'Menu Grid Beranda') {
      presets.addAll([
        'assets/icons/ic_ride.png',
        'assets/icons/ic_food.png',
        'assets/icons/ic_mart.png',
        'assets/icons/ic_send.png',
        'assets/icons/ic_tani.png',
        'assets/icons/ic_ternak.png',
        'assets/icons/ic_babe.png',
        'assets/icons/ic_bonus.png',
        'assets/icons/ic_ride_car.png',
        'assets/icons/ic_clean.png',
        'assets/icons/ic_car.png',
      ]);
    } else if (category == 'Cuan & Finansial') {
      presets.addAll([
        'assets/icons/clay/ic_clay_coin.png',
        'assets/icons/clay/ic_clay_wallet_withdraw.png',
        'assets/icons/clay/ic_clay_megaphone.png',
        'assets/icons/ic_bonus.png',
      ]);
    } else if (category == 'Metrik & Statistik') {
      presets.addAll([
        'assets/icons/clay/ic_clay_clicks.png',
        'assets/icons/clay/ic_clay_conversion.png',
        'assets/icons/clay/ic_clay_order_success.png',
        'assets/icons/clay/ic_clay_referral_users.png',
      ]);
    } else if (category == 'Sosial & Bagikan') {
      presets.addAll([
        'assets/icons/clay/ic_clay_share.png',
        'assets/icons/clay/ic_clay_megaphone.png',
      ]);
    } else {
      presets.addAll(_defaults.values);
    }
    return presets.toSet().toList();
  }

  Future<void> loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null) {
        final Map<String, dynamic> decoded = json.decode(raw);
        _overrides.clear();
        decoded.forEach((k, v) {
          if (v is String && v.isNotEmpty) {
            _overrides[k] = v;
          }
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[DynamicAssetService] Gagal memuat prefs: $e');
    }
  }

  Future<void> _saveToPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, json.encode(_overrides));
    } catch (e) {
      debugPrint('[DynamicAssetService] Gagal menyimpan prefs: $e');
    }
  }
}

/// Widget Consumer Aset Dinamis
/// Menampilkan aset Flutter atau File lokal secara otomatis dengan fallback aman.
class DynamicAssetIcon extends StatelessWidget {
  final String slotKey;
  final String? defaultAsset;
  final double? width;
  final double? height;
  final BoxFit fit;

  const DynamicAssetIcon({
    super.key,
    required this.slotKey,
    this.defaultAsset,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: DynamicAssetService.instance,
      builder: (context, _) {
        final path = DynamicAssetService.instance.getAsset(slotKey);
        final finalPath = path.isNotEmpty ? path : (defaultAsset ?? '');

        if (finalPath.isEmpty) {
          return SizedBox(width: width, height: height);
        }

        if (finalPath.startsWith('assets/')) {
          return Image.asset(
            finalPath,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (ctx, err, stack) => _buildFallbackIcon(),
          );
        } else {
          final file = File(finalPath);
          if (file.existsSync()) {
            return Image.file(
              file,
              width: width,
              height: height,
              fit: fit,
              errorBuilder: (ctx, err, stack) => _buildFallbackIcon(),
            );
          } else {
            // Jika file lokal terhapus, fallback ke default asset
            final fallback = defaultAsset ?? '';
            if (fallback.isNotEmpty) {
              return Image.asset(
                fallback,
                width: width,
                height: height,
                fit: fit,
                errorBuilder: (ctx, err, stack) => _buildFallbackIcon(),
              );
            }
            return _buildFallbackIcon();
          }
        }
      },
    );
  }

  Widget _buildFallbackIcon() {
    return SizedBox(
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.broken_image_rounded, size: 20, color: Colors.grey),
      ),
    );
  }
}
