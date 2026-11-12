import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';

/// Helper terpadu untuk pencarian, pemfilteran kategori, pengurutan ranking,
/// dan sinkronisasi favorit across layanan (Food, Shop, Farm, Build).
class ServiceDirectoryHelper {
  /// Memecah query pencarian menjadi token lowercase untuk pencarian multi-kata.
  static List<String> tokenizeQuery(String query) {
    return query
        .trim()
        .toLowerCase()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static String _merchantSearchableText(Map<String, dynamic> merchant) {
    return [
      merchant['name'],
      merchant['category'],
      merchant['description'],
      merchant['address'],
    ].where((v) => v != null).map((v) => v.toString().toLowerCase()).join(' ');
  }

  static String _catalogItemSearchableText(Map<String, dynamic> item) {
    return [
      item['name'],
      item['category'],
      item['description'],
    ].where((v) => v != null).map((v) => v.toString().toLowerCase()).join(' ');
  }

  /// Mengambil nama produk/menu pada katalog merchant yang cocok dengan query.
  static List<String> matchingProductNames(
    Map<String, dynamic> merchant,
    String query, {
    int limit = 3,
  }) {
    final tokens = tokenizeQuery(query);
    if (tokens.isEmpty) return const [];

    final catalog = GageApiClient.getCatalogForMerchantSync(merchant);
    final matches = <String>[];
    for (final item in catalog) {
      final haystack = _catalogItemSearchableText(item);
      if (tokens.every(haystack.contains)) {
        final itemName = (item['name'] ?? '').toString().trim();
        if (itemName.isNotEmpty && !matches.contains(itemName)) {
          matches.add(itemName);
          if (matches.length >= limit) break;
        }
      }
    }
    return matches;
  }

  /// Ringkasan produk cocok untuk ditampilkan di kartu merchant saat mode cari aktif.
  static String? matchedProductsLabel(
    Map<String, dynamic> merchant,
    String query,
  ) {
    final matched = matchingProductNames(merchant, query, limit: 2);
    if (matched.isEmpty) return null;
    return 'Cocok: ${matched.join(' • ')}';
  }

  /// Menguji kecocokan merchant terhadap query di metadata toko MAUPUN katalog produknya.
  static bool matchesMerchantSearch(
    Map<String, dynamic> merchant,
    String query,
  ) {
    final tokens = tokenizeQuery(query);
    if (tokens.isEmpty) return true;

    final storeText = _merchantSearchableText(merchant);
    if (tokens.every(storeText.contains)) {
      return true;
    }

    final catalog = GageApiClient.getCatalogForMerchantSync(merchant);
    for (final item in catalog) {
      final itemText = _catalogItemSearchableText(item);
      if (tokens.every(itemText.contains)) {
        return true;
      }
      final combined = '$storeText $itemText';
      if (tokens.every(combined.contains)) {
        return true;
      }
    }
    return false;
  }

  /// Menguji kecocokan merchant terhadap kategori terpilih dengan kamus keyword.
  static bool matchesCategoryKeywords(
    Map<String, dynamic> merchant,
    String selectedCategory,
    Map<String, List<String>> categoryKeywords,
  ) {
    if (selectedCategory == 'Semua' || selectedCategory.trim().isEmpty) {
      return true;
    }

    final keywords = categoryKeywords[selectedCategory] ??
        [
          selectedCategory.toLowerCase(),
          ...selectedCategory
              .toLowerCase()
              .split(RegExp(r'[\s&,/]+'))
              .where((w) => w.length >= 3 && w != 'dan'),
        ];

    final storeText = _merchantSearchableText(merchant);
    if (keywords.any(storeText.contains)) {
      return true;
    }

    final catalog = GageApiClient.getCatalogForMerchantSync(merchant);
    for (final item in catalog) {
      final itemText = _catalogItemSearchableText(item);
      if (keywords.any(itemText.contains)) {
        return true;
      }
    }
    return false;
  }

  /// Mengurutkan daftar merchant sesuai RankingSwitch aktif.
  static List<Map<String, dynamic>> sortMerchants(
    List<Map<String, dynamic>> input,
    String rankingSwitch,
  ) {
    final list = List<Map<String, dynamic>>.from(input);
    switch (rankingSwitch) {
      case 'Terlaris':
        list.sort((a, b) {
          final countA = int.tryParse(
                (a['ratingCount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
          final countB = int.tryParse(
                (b['ratingCount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), ''),
              ) ??
              0;
          return countB.compareTo(countA);
        });
        break;
      case 'Top Rating':
        list.sort((a, b) {
          final rA = (a['rating'] is num)
              ? (a['rating'] as num).toDouble()
              : (double.tryParse(a['rating']?.toString() ?? '') ?? 0.0);
          final rB = (b['rating'] is num)
              ? (b['rating'] as num).toDouble()
              : (double.tryParse(b['rating']?.toString() ?? '') ?? 0.0);
          return rB.compareTo(rA);
        });
        break;
      case 'Terdekat':
      case 'Toko Terdekat':
      case 'Kios Terdekat':
        list.sort((a, b) {
          final distA = double.tryParse(
                (a['distance'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              99.0;
          final distB = double.tryParse(
                (b['distance'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), ''),
              ) ??
              99.0;
          return distA.compareTo(distB);
        });
        break;
      case 'Rekomendasi':
      default:
        list.sort((a, b) {
          final spA = (a['isSponsored'] == true || a['tier'] == 'exclusive') ? 1 : 0;
          final spB = (b['isSponsored'] == true || b['tier'] == 'exclusive') ? 1 : 0;
          if (spB != spA) return spB.compareTo(spA);
          final rA = (a['rating'] is num)
              ? (a['rating'] as num).toDouble()
              : (double.tryParse(a['rating']?.toString() ?? '') ?? 0.0);
          final rB = (b['rating'] is num)
              ? (b['rating'] as num).toDouble()
              : (double.tryParse(b['rating']?.toString() ?? '') ?? 0.0);
          return rB.compareTo(rA);
        });
        break;
    }
    return list;
  }

  /// Membaca ID merchant favorit dari SharedPreferences.
  static Future<Set<String>> loadFavoriteIds(
    List<Map<String, dynamic>> stores, {
    Set<String> defaultSeedIds = const {},
  }) async {
    final nextFavs = <String>{};
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final s in stores) {
        final id = (s['id'] ?? '').toString();
        if (id.isEmpty) continue;
        final saved = prefs.containsKey('fav_resto_$id')
            ? (prefs.getBool('fav_resto_$id') ?? false)
            : defaultSeedIds.contains(id);
        if (saved) nextFavs.add(id);
      }
    } catch (_) {
      nextFavs.addAll(defaultSeedIds);
    }
    return nextFavs;
  }

  /// Menyimpan toggle status favorit merchant ke SharedPreferences.
  static Future<void> persistFavoriteStatus(String storeId, bool isFavorite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('fav_resto_$storeId', isFavorite);
    } catch (_) {}
  }
}
