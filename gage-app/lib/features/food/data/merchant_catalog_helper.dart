import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/data/models/order_model.dart';

/// Sort and filter modes for merchant product catalogs across Food, Shop, Farm, and Build.
enum MerchantProductSortMode {
  recommended('Rekomendasi', 'Urut sesuai kategori toko'),
  bestSelling('Terlaris', 'Produk dengan penjualan terbanyak'),
  newest('Baru ditambahkan', 'Produk terbaru di etalase'),
  promoOnly('Lagi Promo', 'Produk dengan harga coret & diskon'),
  lowestPrice('Harga Termurah', 'Urut dari harga paling hemat'),
  highestPrice('Harga Termahal', 'Urut dari harga tertinggi');

  final String label;
  final String subtitle;
  const MerchantProductSortMode(this.label, this.subtitle);

  bool get usesCategorySections => this == MerchantProductSortMode.recommended;
}

/// Resolved pricing pair supporting Merchant Portal product promo overrides (Harga Coret).
class ResolvedProductPrice {
  final int effectivePrice;
  final int? originalPrice;

  const ResolvedProductPrice({
    required this.effectivePrice,
    this.originalPrice,
  });

  bool get hasDiscount => originalPrice != null && originalPrice! > effectivePrice && effectivePrice > 0;

  int? get discountPercent {
    if (!hasDiscount) return null;
    final pct = (((originalPrice! - effectivePrice) * 100) / originalPrice!).round();
    return pct > 0 ? pct : null;
  }
}

/// Shared pure helpers for product card metrics, sorting, promo pricing, and category sections.
abstract final class MerchantCatalogHelper {
  static const Map<String, int> _seedSoldCounts = {
    'menu-rc-01': 148,
    'menu-ds-01': 215,
    'prod-besi-10': 84,
    'prod-bajaringan-c75': 112,
    'prod-spandek': 67,
    'prod-pipa-pvc': 49,
    'prod-kran-onda': 35,
  };

  static const Map<String, double> _seedPromoDiscountRatios = {
    'menu-rc-01': 0.15,
    'menu-ds-01': 0.20,
    'prod-besi-10': 0.10,
    'prod-bajaringan-c75': 0.12,
  };

  static int parseInt(dynamic val, [int fallback = 0]) {
    if (val == null) return fallback;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) {
      final cleaned = val.replaceAll(RegExp(r'[^0-9\-]'), '');
      return int.tryParse(cleaned) ?? fallback;
    }
    return fallback;
  }

  /// Resolves normal vs promo price from MerchantStorefrontData overrides or item payload fields.
  static ResolvedProductPrice resolvePrice(
    Map<String, dynamic> item, {
    MerchantStorefrontData? storefront,
    bool? devSeedOverride,
  }) {
    final menuId = (item['id'] ?? '').toString().trim();
    final normalPrice = parseInt(item['gage_price'] ?? item['price'] ?? item['offline_price'], 0);
    final explicitOriginal = parseInt(item['original_price'] ?? item['originalPrice'], 0);

    // Check explicit Merchant storefront override first (0 means explicitly turned off)
    final hasStorefrontOverride = storefront?.itemPromoPrices?.containsKey(menuId) ?? false;
    final merchantPromoOverride = hasStorefrontOverride ? storefront!.itemPromoPrices![menuId]! : -1;
    if (hasStorefrontOverride) {
      if (merchantPromoOverride > 0 && (normalPrice <= 0 || merchantPromoOverride < normalPrice)) {
        return ResolvedProductPrice(
          effectivePrice: merchantPromoOverride,
          originalPrice: normalPrice > merchantPromoOverride ? normalPrice : null,
        );
      }
      return ResolvedProductPrice(effectivePrice: normalPrice);
    }

    // Honor explicit promo_active flag when supplied by D1/API (0 or false disables promo)
    final rawPromoActive = item['promo_active'] ?? item['promoActive'];
    final isPromoExplicitlyOff = rawPromoActive == false ||
        rawPromoActive == 0 ||
        rawPromoActive?.toString().toLowerCase() == '0' ||
        rawPromoActive?.toString().toLowerCase() == 'false';
    if (isPromoExplicitlyOff) {
      return ResolvedProductPrice(effectivePrice: normalPrice);
    }

    final hasExplicitPromoKey = item.containsKey('promo_price') || item.containsKey('promoPrice');
    final explicitPromo = parseInt(item['promo_price'] ?? item['promoPrice'], 0);
    if (hasExplicitPromoKey) {
      if (explicitPromo > 0 && (normalPrice <= 0 || explicitPromo < normalPrice)) {
        return ResolvedProductPrice(
          effectivePrice: explicitPromo,
          originalPrice: normalPrice > explicitPromo
              ? normalPrice
              : (explicitOriginal > explicitPromo ? explicitOriginal : null),
        );
      }
      // Reject invalid or disabled explicit promoPrice without falling through to dev seed discounts
      return ResolvedProductPrice(effectivePrice: normalPrice);
    }

    if (explicitOriginal > normalPrice && normalPrice > 0) {
      return ResolvedProductPrice(
        effectivePrice: normalPrice,
        originalPrice: explicitOriginal,
      );
    }

    final useSeed = (devSeedOverride ?? GageApiClient.useDevSeedData) && item['isDevSeed'] != false;
    if (useSeed && normalPrice > 0) {
      final ratio = _seedPromoDiscountRatios[menuId];
      if (ratio != null && ratio > 0 && ratio < 0.8) {
        final promo = ((normalPrice * (1 - ratio)) / 500).floor() * 500;
        if (promo > 0 && promo < normalPrice) {
          return ResolvedProductPrice(
            effectivePrice: promo,
            originalPrice: normalPrice,
          );
        }
      }
    }

    return ResolvedProductPrice(effectivePrice: normalPrice);
  }

  /// Returns item map normalized with active discounted price so cart & variant sheets honor Harga Coret.
  static Map<String, dynamic> withResolvedPrice(
    Map<String, dynamic> item, {
    MerchantStorefrontData? storefront,
    bool? devSeedOverride,
  }) {
    final resolved = resolvePrice(item, storefront: storefront, devSeedOverride: devSeedOverride);
    if (!resolved.hasDiscount) return item;
    return <String, dynamic>{
      ...item,
      'gage_price': resolved.effectivePrice,
      'price': resolved.effectivePrice,
      'original_price': resolved.originalPrice,
    };
  }

  /// Aggregates completed order item quantities keyed by item ID and lowercased item name.
  static Map<String, int> buildCompletedOrderCounts(List<OrderModel> orders, {String? merchantId}) {
    final counts = <String, int>{};
    final targetMId = (merchantId ?? '').trim().toLowerCase();
    for (final order in orders) {
      if (order.status.toUpperCase() != 'COMPLETED') continue;
      if (targetMId.isNotEmpty && order.merchantId.trim().toLowerCase() != targetMId) {
        // Multi-merchant orders carry merchantId per-order or matching substring
        if (!order.merchantId.trim().toLowerCase().contains(targetMId)) continue;
      }
      for (final item in order.items) {
        if (item.id.trim().isNotEmpty) {
          counts['id:${item.id.trim()}'] = (counts['id:${item.id.trim()}'] ?? 0) + item.quantity;
        }
        if (item.name.trim().isNotEmpty) {
          final normName = item.name.trim().toLowerCase();
          counts['name:$normName'] = (counts['name:$normName'] ?? 0) + item.quantity;
        }
      }
    }
    return counts;
  }

  /// Resolves sold count from API payload, live completed orders, and dev seed fallback when enabled.
  static int resolveSoldCount(
    Map<String, dynamic> item, {
    Map<String, int> completedOrderQtyByKey = const {},
    bool? devSeedOverride,
  }) {
    final apiSold = parseInt(item['sold_count'] ?? item['soldCount'], 0);
    final menuId = (item['id'] ?? '').toString().trim();
    final normName = (item['name'] ?? '').toString().trim().toLowerCase();
    final idCount = menuId.isNotEmpty ? (completedOrderQtyByKey['id:$menuId'] ?? 0) : 0;
    final nameCount = (idCount == 0 && normName.isNotEmpty) ? (completedOrderQtyByKey['name:$normName'] ?? 0) : 0;
    final realSold = apiSold + idCount + nameCount;
    if (realSold > 0) return realSold;

    final useSeed = (devSeedOverride ?? GageApiClient.useDevSeedData) && item['isDevSeed'] != false;
    if (!useSeed) return 0;

    if (_seedSoldCounts.containsKey(menuId)) {
      return _seedSoldCounts[menuId]!;
    }
    if (menuId.isNotEmpty) {
      var hash = 0;
      for (var i = 0; i < menuId.length; i++) {
        hash = (hash * 31 + menuId.codeUnitAt(i)) & 0x7fffffff;
      }
      return 12 + (hash % 85);
    }
    return 0;
  }

  /// Formats compact Indonesian sales count string; returns empty string when zero or less.
  static String formatSoldLabel(int soldCount) {
    if (soldCount <= 0) return '';
    if (soldCount >= 1000) {
      final thousands = (soldCount / 1000).toStringAsFixed(1).replaceAll('.0', '').replaceAll('.', ',');
      return '${thousands}rb terjual';
    }
    return '$soldCount terjual';
  }

  static int _parseCreatedTimestamp(Map<String, dynamic> item) {
    final raw = item['created_at'] ?? item['createdAt'];
    if (raw == null) return 0;
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    final str = raw.toString().trim();
    final asInt = int.tryParse(str);
    if (asInt != null) return asInt;
    final parsedDate = DateTime.tryParse(str);
    if (parsedDate != null) return parsedDate.millisecondsSinceEpoch ~/ 1000;
    return 0;
  }

  /// Filters catalog items by search query and applies selected global sort or promo filter.
  static List<Map<String, dynamic>> applySearchAndSort(
    List<Map<String, dynamic>> items, {
    required String searchQuery,
    required MerchantProductSortMode sortMode,
    MerchantStorefrontData? storefront,
    Map<String, int> completedOrderQtyByKey = const {},
    bool? devSeedOverride,
  }) {
    final query = searchQuery.toLowerCase().trim();
    var filtered = items.where((m) {
      if (query.isEmpty) return true;
      final name = (m['name'] ?? '').toString().toLowerCase();
      final desc = (m['description'] ?? '').toString().toLowerCase();
      final cat = (m['category'] ?? '').toString().toLowerCase();
      return name.contains(query) || desc.contains(query) || cat.contains(query);
    }).toList();

    if (sortMode == MerchantProductSortMode.promoOnly) {
      filtered = filtered
          .where((m) => resolvePrice(m, storefront: storefront, devSeedOverride: devSeedOverride).hasDiscount)
          .toList();
      filtered.sort((a, b) {
        final pa = resolvePrice(a, storefront: storefront, devSeedOverride: devSeedOverride);
        final pb = resolvePrice(b, storefront: storefront, devSeedOverride: devSeedOverride);
        final pctCmp = (pb.discountPercent ?? 0).compareTo(pa.discountPercent ?? 0);
        if (pctCmp != 0) return pctCmp;
        return pa.effectivePrice.compareTo(pb.effectivePrice);
      });
      return filtered;
    }

    if (sortMode == MerchantProductSortMode.recommended) {
      return filtered;
    }

    final indexed = filtered.asMap().entries.toList();
    indexed.sort((entryA, entryB) {
      final a = entryA.value;
      final b = entryB.value;
      switch (sortMode) {
        case MerchantProductSortMode.bestSelling:
          final sa = resolveSoldCount(a, completedOrderQtyByKey: completedOrderQtyByKey, devSeedOverride: devSeedOverride);
          final sb = resolveSoldCount(b, completedOrderQtyByKey: completedOrderQtyByKey, devSeedOverride: devSeedOverride);
          final cmp = sb.compareTo(sa);
          return cmp != 0 ? cmp : entryA.key.compareTo(entryB.key);
        case MerchantProductSortMode.newest:
          final ta = _parseCreatedTimestamp(a);
          final tb = _parseCreatedTimestamp(b);
          final cmp = tb.compareTo(ta);
          // Fallback to reverse insertion order when timestamps are missing or identical
          return cmp != 0 ? cmp : entryB.key.compareTo(entryA.key);
        case MerchantProductSortMode.lowestPrice:
          final pa = resolvePrice(a, storefront: storefront, devSeedOverride: devSeedOverride).effectivePrice;
          final pb = resolvePrice(b, storefront: storefront, devSeedOverride: devSeedOverride).effectivePrice;
          final cmp = pa.compareTo(pb);
          return cmp != 0 ? cmp : entryA.key.compareTo(entryB.key);
        case MerchantProductSortMode.highestPrice:
          final pa = resolvePrice(a, storefront: storefront, devSeedOverride: devSeedOverride).effectivePrice;
          final pb = resolvePrice(b, storefront: storefront, devSeedOverride: devSeedOverride).effectivePrice;
          final cmp = pb.compareTo(pa);
          return cmp != 0 ? cmp : entryA.key.compareTo(entryB.key);
        case MerchantProductSortMode.recommended:
        case MerchantProductSortMode.promoOnly:
          return entryA.key.compareTo(entryB.key);
      }
    });
    return indexed.map((e) => e.value).toList();
  }

  /// Groups catalog items under category headings ordered by Merchant Portal configuration.
  static List<MapEntry<String, List<Map<String, dynamic>>>> groupByOrderedCategories(
    List<Map<String, dynamic>> items, {
    List<String>? customOrder,
  }) {
    final grouped = <String, List<Map<String, dynamic>>>{};
    final naturalOrder = <String>[];

    for (final item in items) {
      final rawCat = (item['category'] ?? '').toString().trim();
      final catName = rawCat.isEmpty ? 'Lainnya' : rawCat;
      if (!grouped.containsKey(catName)) {
        grouped[catName] = [];
        naturalOrder.add(catName);
      }
      grouped[catName]!.add(item);
    }

    if (customOrder == null || customOrder.isEmpty) {
      return naturalOrder.map((k) => MapEntry(k, grouped[k]!)).toList();
    }

    final lowerToKey = <String, String>{
      for (final k in naturalOrder) k.toLowerCase(): k,
    };
    final orderedKeys = <String>[];
    final seen = <String>{};

    for (final configured in customOrder) {
      final matchedKey = lowerToKey[configured.trim().toLowerCase()];
      if (matchedKey != null && !seen.contains(matchedKey)) {
        orderedKeys.add(matchedKey);
        seen.add(matchedKey);
      }
    }
    for (final k in naturalOrder) {
      if (!seen.contains(k)) {
        orderedKeys.add(k);
        seen.add(k);
      }
    }

    return orderedKeys.map((k) => MapEntry(k, grouped[k]!)).toList();
  }
}
