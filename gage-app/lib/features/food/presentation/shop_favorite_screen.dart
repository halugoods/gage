import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class ShopFavoriteScreen extends StatefulWidget {
  final String domain; // 'food', 'shop', 'farm', 'build'
  final int initialTabIndex;
  final String? filterMerchantId;
  final String? filterMerchantName;

  const ShopFavoriteScreen({
    super.key,
    this.domain = 'shop',
    this.initialTabIndex = 0,
    this.filterMerchantId,
    this.filterMerchantName,
  });

  @override
  State<ShopFavoriteScreen> createState() => _ShopFavoriteScreenState();
}

class _ShopFavoriteScreenState extends State<ShopFavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allStores = [];
  List<Map<String, dynamic>> _favoriteStores = [];
  List<Map<String, dynamic>> _favoriteItems = [];

  String get _normalizedDomain => widget.domain.trim().toLowerCase();

  bool get _isScopedToMerchant =>
      (widget.filterMerchantId ?? '').trim().isNotEmpty ||
      (widget.filterMerchantName ?? '').trim().isNotEmpty;

  String get _screenTitle {
    switch (_normalizedDomain) {
      case 'food':
        return 'Resto & Menu Favorit';
      case 'farm':
        return 'Kios Tani & Ternak Favorit';
      case 'build':
        return 'Toko Bangunan Favorit';
      default:
        return 'Toko & Sembako Favorit';
    }
  }

  String get _storeTabLabel => 'Merchant Favorit';

  String get _itemTabLabel => 'Produk Favorit';

  String get _emptyStoreTitle {
    switch (_normalizedDomain) {
      case 'food':
        return 'Belum Ada Resto Favorit';
      case 'farm':
        return 'Belum Ada Kios Favorit';
      default:
        return 'Belum Ada Toko Favorit';
    }
  }

  String get _emptyStoreDesc {
    switch (_normalizedDomain) {
      case 'food':
        return 'Ketuk ikon hati pada halaman resto untuk menyimpannya di sini.';
      case 'farm':
        return 'Kios tani & ternak yang Anda tandai favorit akan muncul di sini.';
      default:
        return 'Toko mitra yang Anda tandai favorit akan muncul di sini.';
    }
  }

  String get _emptyItemTitle =>
      _isScopedToMerchant ? 'Belum Ada Produk Favorit di Merchant Ini' : 'Belum Ada Produk Favorit';

  String get _emptyItemDesc => _isScopedToMerchant
      ? 'Ketuk ikon hati pada produk di ${widget.filterMerchantName ?? 'merchant ini'} untuk menyimpannya di sini.'
      : 'Produk yang Anda tandai favorit akan tersimpan di sini.';

  IconData get _fallbackStoreIcon {
    switch (_normalizedDomain) {
      case 'food':
        return Icons.restaurant_rounded;
      case 'farm':
        return Icons.agriculture_rounded;
      case 'build':
        return Icons.construction_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  IconData get _fallbackItemIcon {
    switch (_normalizedDomain) {
      case 'food':
        return Icons.fastfood_rounded;
      case 'farm':
        return Icons.eco_rounded;
      case 'build':
        return Icons.hardware_rounded;
      default:
        return Icons.shopping_basket_rounded;
    }
  }

  List<Map<String, dynamic>> get _seedProducts {
    if (!GageApiClient.useDevSeedData) return const [];
    switch (_normalizedDomain) {
      case 'food':
        return const [
          {
            'id': 'seed-food-fav-1',
            'name': 'Dimsum Ayam Udang (8 pcs)',
            'store': 'Dimsum Sewu, Alfamidi Pracimantoro',
            'storeId': 'mch-dimsum-01',
            'price': 'Rp 22.000',
            'image': 'assets/images/resto_dimsum_sewu.png',
          },
          {
            'id': 'seed-food-fav-2',
            'name': 'Paket Geprek Sambal Bawang',
            'store': 'Rocket Chicken Sambiroto, Pracimantoro',
            'storeId': 'mch-rc-01',
            'price': 'Rp 18.000',
            'image': 'assets/images/resto_rocket_chicken.png',
          },
        ];
      case 'farm':
        return const [
          {
            'id': 'seed-farm-fav-1',
            'name': 'Pupuk NPK Mutiara 16-16-16 (1 Kg)',
            'store': 'Kios Tani Subur Makmur',
            'storeId': 'farm-kios-subur',
            'price': 'Rp 19.500',
            'image': 'assets/images/prod_pupuk.png',
          },
          {
            'id': 'seed-farm-fav-2',
            'name': 'Pakan Ayam Broiler BR-1 Starter 5 Kg',
            'store': 'Poultry Shop Berkah Ternak',
            'storeId': 'farm-poultry-berkah',
            'price': 'Rp 55.000',
            'image': 'assets/images/prod_pakan.png',
          },
        ];
      case 'build':
        return const [
          {
            'id': 'seed-build-fav-1',
            'name': 'Semen Gresik Portland PCC 40 Kg',
            'store': 'TB Sumber Bangunan Pracimantoro',
            'storeId': 'build-sumber-bangunan',
            'price': 'Rp 55.000',
            'image': 'assets/images/prod_semen.png',
          },
          {
            'id': 'seed-build-fav-2',
            'name': 'Cat Tembok Dulux Catylac Putih 5 Kg',
            'store': 'Toko Cat & Finishing Griya Indah',
            'storeId': 'build-griya-indah',
            'price': 'Rp 142.000',
            'image': 'assets/images/prod_cat.png',
          },
        ];
      default:
        return const [
          {
            'id': 'seed-shop-fav-1',
            'name': 'Beras C4 Super Raja Polos 5 Kg',
            'store': 'Toko Sembako Berkah Fajar',
            'storeId': 'shop-berkah-fajar',
            'price': 'Rp 72.000',
            'image': 'assets/images/prod_beras.png',
          },
          {
            'id': 'seed-shop-fav-2',
            'name': 'Minyak Goreng Bimoli Klasik 2 Liter',
            'store': 'Toko Sembako Berkah Fajar',
            'storeId': 'shop-berkah-fajar',
            'price': 'Rp 38.500',
            'image': 'assets/images/prod_minyak.png',
          },
          {
            'id': 'seed-shop-fav-3',
            'name': 'Paket Sayur Sop Komplit + Bumbu Racik',
            'store': 'Pasar Sayur Segar Bu Marti',
            'storeId': 'shop-sayur-bu-marti',
            'price': 'Rp 8.000',
            'image': 'assets/images/prod_cabai.png',
          },
        ];
    }
  }

  Set<String> get _defaultSeedFavorites {
    if (!GageApiClient.useDevSeedData) return const {};
    switch (_normalizedDomain) {
      case 'food':
        return const {'mch-dimsum-01', 'mch-rc-01', 'mch-mie-01'};
      case 'farm':
        return const {'farm-kios-subur'};
      case 'build':
        return const {'build-sumber-bangunan', 'build-sumber-abadi'};
      default:
        return const {'shop-berkah-fajar', 'shop-sayur-bu-marti'};
    }
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
    _tabController.addListener(() {
      if (mounted && !_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _loadFavorites();
  }

  bool _matchesScopedMerchant(Map<String, dynamic> item) {
    if (!_isScopedToMerchant) return true;
    final filterId = (widget.filterMerchantId ?? '').trim().toLowerCase();
    final filterName = (widget.filterMerchantName ?? '').trim().toLowerCase();
    final itemStoreId = (item['storeId'] ?? item['merchantId'] ?? item['merchant_id'] ?? '')
        .toString()
        .trim()
        .toLowerCase();
    final itemStoreName = (item['store'] ?? item['merchantName'] ?? '').toString().trim().toLowerCase();
    if (filterId.isNotEmpty && itemStoreId.isNotEmpty) {
      return itemStoreId == filterId;
    }
    if (filterName.isNotEmpty && itemStoreName.isNotEmpty) {
      return itemStoreName == filterName || itemStoreName.contains(filterName) || filterName.contains(itemStoreName);
    }
    return false;
  }

  Future<void> _loadFavorites() async {
    if (mounted) setState(() => _isLoading = true);
    final List<Map<String, dynamic>> stores;
    switch (_normalizedDomain) {
      case 'food':
        stores = await GageApiClient.getFoodMerchants();
        break;
      case 'farm':
        stores = await GageApiClient.getFarmMerchants();
        break;
      case 'build':
        stores = await GageApiClient.getBuildMerchants();
        break;
      default:
        stores = await GageApiClient.getShopMerchants();
        break;
    }

    final prefs = await SharedPreferences.getInstance();
    final seedFavs = _defaultSeedFavorites;
    final favStores = stores.where((s) {
      final id = (s['id'] ?? '').toString();
      if (prefs.containsKey('fav_resto_$id')) {
        return prefs.getBool('fav_resto_$id') ?? false;
      }
      return seedFavs.contains(id);
    }).toList();

    final persistedItems = <Map<String, dynamic>>[];
    final seenItemIds = <String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith('fav_item_meta_')) continue;
      final itemId = key.substring('fav_item_meta_'.length);
      if (prefs.getBool('fav_item_$itemId') == false) continue;
      final raw = prefs.getString(key);
      if (raw == null || raw.isEmpty) continue;
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          final itemDomain = (decoded['domain'] ?? 'food').toString().toLowerCase();
          if (itemDomain == _normalizedDomain) {
            persistedItems.add(decoded);
            seenItemIds.add(itemId);
          }
        }
      } catch (_) {}
    }

    final mergedItems = <Map<String, dynamic>>[...persistedItems];
    for (final seed in _seedProducts) {
      final seedId = (seed['id'] ?? '').toString();
      if (seedId.isNotEmpty && seenItemIds.contains(seedId)) continue;
      if (seedId.isNotEmpty && prefs.getBool('fav_item_$seedId') == false) continue;
      mergedItems.add(seed);
    }

    final filteredItems = _isScopedToMerchant
        ? mergedItems.where(_matchesScopedMerchant).toList()
        : mergedItems;

    if (mounted) {
      setState(() {
        _allStores = stores;
        _favoriteStores = favStores;
        _favoriteItems = filteredItems;
        _isLoading = false;
      });
    }
  }

  Future<void> _openStore(
    Map<String, dynamic> store, {
    Map<String, dynamic>? initialProduct,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MerchantDetailScreen(
          merchant: {
            'domain': _normalizedDomain,
            'serviceType': _normalizedDomain,
            ...store,
          },
          initialProductItem: initialProduct,
          initialProductId: initialProduct?['id']?.toString(),
        ),
      ),
    );
    await _loadFavorites();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildThumbImage(dynamic src, double size, IconData fallbackIcon, bool isDark) {
    final path = (src ?? '').toString().trim();
    Widget fallback() => Icon(fallbackIcon, color: Colors.grey);

    Widget child;
    if (path.isEmpty) {
      child = fallback();
    } else if (path.startsWith('http://') || path.startsWith('https://')) {
      child = Image.network(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => fallback());
    } else {
      child = Image.asset(path, fit: BoxFit.cover, errorBuilder: (c, e, s) => fallback());
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: size,
        height: size,
        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        child: child,
      ),
    );
  }

  Widget _buildSegmentedTabSwitch(bool isDark, Color mutedTextColor) {
    final activeIdx = _tabController.index;
    final labels = [_storeTabLabel, _itemTabLabel];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: List.generate(labels.length, (idx) {
          final isSelected = activeIdx == idx;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticFeedback.selectionClick();
                if (_tabController.index != idx) {
                  _tabController.animateTo(idx);
                }
                setState(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 10),
                decoration: BoxDecoration(
                  color: isSelected ? GageTheme.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: GageTheme.primary.withValues(alpha: 0.25),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  labels[idx],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isSelected ? Colors.white : mutedTextColor,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFavoriteItemsList(
    bool isDark,
    Color primaryTextColor,
    Color mutedTextColor,
  ) {
    if (_isLoading) {
      return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        itemBuilder: (ctx, idx) => const GageSkeletonMenuItem(),
      );
    }
    if (_favoriteItems.isEmpty) {
      return _buildEmptyState(_emptyItemTitle, _emptyItemDesc, mutedTextColor);
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteItems.length,
      itemBuilder: (ctx, idx) {
        final item = _favoriteItems[idx];
        final storeId = (item['storeId'] ?? '').toString();
        final matchedStore = _allStores.firstWhere(
          (s) => s['id']?.toString() == storeId,
          orElse: () => {
            'id': storeId,
            'name': item['store'] ?? _screenTitle,
            'category': _screenTitle,
            'image': item['image'],
            'domain': _normalizedDomain,
            'serviceType': _normalizedDomain,
          },
        );
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () {
              if (_isScopedToMerchant) {
                Navigator.pop(context, item);
              } else {
                _openStore(matchedStore, initialProduct: item);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _buildThumbImage(item['image'], 64, _fallbackItemIcon, isDark),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          (item['name'] ?? '').toString(),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          (item['store'] ?? '').toString(),
                          style: TextStyle(fontSize: 11, color: mutedTextColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          (item['price'] ?? '').toString(),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 13.5,
                            color: GageTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : Colors.black87;
    final mutedTextColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          _isScopedToMerchant ? _itemTabLabel : _screenTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: primaryTextColor,
        elevation: 0.5,
        bottom: _isScopedToMerchant
            ? null
            : PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: AnimatedBuilder(
                    animation: _tabController.animation ?? _tabController,
                    builder: (ctx, _) => _buildSegmentedTabSwitch(isDark, mutedTextColor),
                  ),
                ),
              ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: GageTheme.primary,
        child: _isScopedToMerchant
            ? _buildFavoriteItemsList(isDark, primaryTextColor, mutedTextColor)
            : TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Merchant Favorit
                  _isLoading
                      ? ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: 3,
                          itemBuilder: (ctx, idx) => const GageSkeletonStoreCard(),
                        )
                      : _favoriteStores.isEmpty
                          ? _buildEmptyState(_emptyStoreTitle, _emptyStoreDesc, mutedTextColor)
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _favoriteStores.length,
                              itemBuilder: (ctx, idx) {
                                final store = _favoriteStores[idx];
                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  child: InkWell(
                                    onTap: () => _openStore(store),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Row(
                                        children: [
                                          _buildThumbImage(store['image'] ?? store['image_url'], 72, _fallbackStoreIcon, isDark),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  (store['name'] ?? '').toString(),
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 3),
                                                Text(
                                                  (store['category'] ?? '').toString(),
                                                  style: TextStyle(fontSize: 11.5, color: mutedTextColor),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                                    const SizedBox(width: 2),
                                                    Text(
                                                      '${store['rating'] ?? 4.8}',
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      '• ${store['distance'] ?? '1.0 km'}',
                                                      style: TextStyle(fontSize: 11.5, color: primaryTextColor),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),

                  // Tab 2: Produk Favorit
                  _buildFavoriteItemsList(isDark, primaryTextColor, mutedTextColor),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String desc, Color mutedTextColor) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 96),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(desc, style: TextStyle(fontSize: 12, color: mutedTextColor), textAlign: TextAlign.center),
            ],
          ),
        ),
      ],
    );
  }
}
