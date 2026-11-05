import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_cart_sheet.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_merchant_card.dart';

typedef ShopExploreScreen = ShopScreen;

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Semua';
  String _rankingSwitch = 'Rekomendasi'; // 'Rekomendasi', 'Terlaris', 'Toko Terdekat'
  String _searchQuery = '';
  bool _isLoading = true;
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteStoreIds = {'shop-berkah-fajar'};
  final bool _showFavoritesOnly = false;

  final TextEditingController _searchController = TextEditingController();

  String _formatShortAddress(String addr) {
    if (addr.isEmpty) return 'Pilih Lokasi';
    if (addr.contains('(')) {
      return addr.split('(').last.replaceAll(')', '').trim();
    }
    final parts = addr.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return addr.trim();
  }

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initDeliveryLocation() async {
    final gps = await LocationService.getCurrentLocation();
    final addr = await OsmGeocodingService.reverseGeocode(gps);
    if (mounted) {
      setState(() {
        _deliveryLocation = addr;
      });
    }
  }

  void _showDeliveryLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran Belanja',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _deliveryLocation = '$title - $fullAddress';
        });
      },
    );
  }

  void _toggleFavorite(String storeId, [String? storeName]) {
    final isFav = _favoriteStoreIds.contains(storeId);
    setState(() {
      if (isFav) {
        _favoriteStoreIds.remove(storeId);
      } else {
        _favoriteStoreIds.add(storeId);
      }
    });
    GageToast.show(
      context,
      !isFav
          ? '${storeName ?? "Toko"} ditambahkan ke favorit!'
          : '${storeName ?? "Toko"} dihapus dari favorit',
      type: !isFav ? GageToastType.success : GageToastType.info,
    );
  }

  // ===========================================================================
  // DATA KATEGORI BELANJA (Persis Sesuai Spesifikasi GAGE Shop)
  // ===========================================================================
  final List<Map<String, dynamic>> _categories = [
    {
      'name': 'Sembako & Beras',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.rice_bowl_rounded,
    },
    {
      'name': 'Minyak & Bumbu',
      'image': 'assets/images/prod_minyak.png',
      'icon': Icons.liquor_rounded,
    },
    {
      'name': 'Telur Segar',
      'image': 'assets/images/prod_telur.png',
      'icon': Icons.egg_rounded,
    },
    {
      'name': 'Gula & Terigu',
      'image': 'assets/images/prod_gula.png',
      'icon': Icons.bakery_dining_rounded,
    },
    {
      'name': 'Mie & Makanan Instan',
      'image': 'assets/images/prod_indomie.png',
      'icon': Icons.ramen_dining_rounded,
    },
    {
      'name': 'Sayur & Cabai',
      'image': 'assets/images/prod_cabai.png',
      'icon': Icons.eco_rounded,
    },
    {
      'name': 'Sabun & Kebersihan',
      'image': 'assets/images/hero_promo_1.png',
      'icon': Icons.cleaning_services_rounded,
    },
    {
      'name': 'Makanan Ringan',
      'image': 'assets/images/hero_promo_2.png',
      'icon': Icons.fastfood_rounded,
    },
    {
      'name': 'Minuman Dingin',
      'image': 'assets/images/banner_gagepay_promo.png',
      'icon': Icons.local_drink_rounded,
    },
  ];



  // ===========================================================================
  // DAFTAR MERCHANT RESMI GAGE SHOP (Daftar Toko Mitra Pracimantoro)
  // ===========================================================================
  final List<Map<String, dynamic>> _retailStores = [
    {
      'id': 'shop-berkah-fajar',
      'name': 'Toko Sembako Berkah Fajar',
      'category': 'Sembako & Beras, Minyak & Bumbu',
      'address': 'Jl. Raya Pracimantoro No. 12, Wonogiri',
      'distance': '0.5 km',
      'eta': '10-15 min',
      'rating': 4.9,
      'ratingCount': '140+',
      'openHours': '06:30 - 21:00',
      'isOpen': true,
      'image': 'assets/images/shop_hero_banner.png',
      'phone_wa': '081234567801',
      'description': 'Sedia aneka beras C4 pulen Wonogiri, minyak Bimoli, gula kristal, telur ayam segar, dan terigu segitiga biru.',
    },
    {
      'id': 'shop-kelontong-bu-sri',
      'name': 'Toko Kelontong Bu Sri',
      'category': 'Sembako & Beras, Makanan Ringan, Sabun & Kebersihan',
      'address': 'Simpang Empat Pasar Pracimantoro Blok A',
      'distance': '0.8 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '185+',
      'openHours': '06:00 - 20:30',
      'isOpen': true,
      'image': 'assets/images/shop_hero_banner.png',
      'phone_wa': '081234567802',
      'description': 'Toko kelontong komplit kebutuhan harian rumah tangga, camilan rengginang, kerupuk, kopi sachet, dan detergen.',
    },
    {
      'id': 'shop-minimarket-losari',
      'name': 'Minimarket Warga Losari',
      'category': 'Makanan Ringan, Sabun & Kebersihan, Minyak & Bumbu',
      'address': 'Jl. Sedayu - Losari KM 1, Pracimantoro',
      'distance': '1.1 km',
      'eta': '15-25 min',
      'rating': 4.8,
      'ratingCount': '210+',
      'openHours': '07:00 - 22:00',
      'isOpen': true,
      'image': 'assets/images/shop_hero_banner.png',
      'phone_wa': '081234567803',
      'description': 'Minimarket serba ada, aneka snack biskuit, susu UHT, minuman dingin, sabun mandi, shampo, dan perlengkapan dapur.',
    },
    {
      'id': 'shop-grosir-sentosa',
      'name': 'Grosir Pangan Sentosa',
      'category': 'Sembako & Beras, Minyak & Bumbu, Makanan Ringan',
      'address': 'Kawasan Terminal Pracimantoro No. 45',
      'distance': '1.4 km',
      'eta': '20-25 min',
      'rating': 4.9,
      'ratingCount': '95+',
      'openHours': '07:00 - 18:00',
      'isOpen': true,
      'image': 'assets/images/shop_hero_banner.png',
      'phone_wa': '081234567804',
      'description': 'Pusat grosir pangan, sembako karungan, mie instan per dus karton, minyak jerigen/karton, dan aneka bumbu dapur.',
    },
    {
      'id': 'shop-sayur-bu-marti',
      'name': 'Pasar Sayur Segar Bu Marti',
      'category': 'Sembako & Beras, Minyak & Bumbu',
      'address': 'Pasar Tradisional Pracimantoro Los Sayur No. 8',
      'distance': '0.7 km',
      'eta': '10-20 min',
      'rating': 4.9,
      'ratingCount': '110+',
      'openHours': '05:30 - 13:00',
      'isOpen': true,
      'image': 'assets/images/promo_banner_3.png',
      'phone_wa': '081234567805',
      'description': 'Sayur mayur hijau segar langsung panen, cabai rawit merah pedas, bawang merah brebes, tomat, dan bumbu racik.',
    },
    {
      'id': 'shop-sumber-lancar',
      'name': 'Depot Galon & Gas LPG Sumber Lancar',
      'category': 'Sabun & Kebersihan, Sembako & Beras',
      'address': 'Jl. Ahmad Yani No. 8, Pracimantoro',
      'distance': '1.2 km',
      'eta': '15-20 min',
      'rating': 4.7,
      'ratingCount': '75+',
      'openHours': '06:00 - 21:00',
      'isOpen': true,
      'image': 'assets/images/hero_promo_1.png',
      'phone_wa': '081234567806',
      'description': 'Isi ulang galon Aqua 19L, gas melon LPG 3kg bersubsidi, dan sabun cuci piring Sunlight.',
    },
  ];


  // Filter Merchant
  List<Map<String, dynamic>> get _filteredStores {
    final filtered = _retailStores.where((s) {
      final name = s['name'].toString().toLowerCase();
      final cat = s['category'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty || name.contains(q) || cat.contains(q);

      if (!matchesQuery) return false;

      final matchesFav = !_showFavoritesOnly || _favoriteStoreIds.contains(s['id'] as String);
      if (!matchesFav) return false;

      if (_selectedCategory == 'Semua') return true;
      if (_selectedCategory == 'Sembako & Beras') {
        return cat.contains('sembako') || cat.contains('beras');
      }
      if (_selectedCategory == 'Minyak & Bumbu') {
        return cat.contains('minyak') || cat.contains('bumbu');
      }
      if (_selectedCategory == 'Makanan Ringan') {
        return cat.contains('makanan') || cat.contains('ringan') || cat.contains('snack');
      }
      if (_selectedCategory == 'Sabun & Kebersihan') {
        return cat.contains('sabun') || cat.contains('kebersihan');
      }
      if (_selectedCategory == 'Telur Segar') {
        return cat.contains('telur') || name.contains('telur');
      }
      if (_selectedCategory == 'Gula & Terigu') {
        return cat.contains('gula') || cat.contains('terigu');
      }
      if (_selectedCategory == 'Mie & Makanan Instan') {
        return cat.contains('mie') || cat.contains('pangan');
      }
      if (_selectedCategory == 'Sayur & Cabai') {
        return cat.contains('sayur') || cat.contains('cabai');
      }
      if (_selectedCategory == 'Minuman Dingin') {
        return cat.contains('galon') || cat.contains('minuman');
      }
      return true;
    }).toList();

    // Terapkan Ranking Switch
    switch (_rankingSwitch) {
      case 'Terlaris':
        filtered.sort((a, b) {
          final countA = int.tryParse((a['ratingCount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          final countB = int.tryParse((b['ratingCount'] ?? '').toString().replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
          return countB.compareTo(countA);
        });
        break;
      case 'Toko Terdekat':
        filtered.sort((a, b) {
          final distA = double.tryParse((a['distance'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99.0;
          final distB = double.tryParse((b['distance'] ?? '').toString().replaceAll(RegExp(r'[^0-9.]'), '')) ?? 99.0;
          return distA.compareTo(distB);
        });
        break;
      case 'Rekomendasi':
      default:
        break;
    }

    return filtered;
  }

  Widget _buildRankingSwitch(bool isDark) {
    final options = ['Rekomendasi', 'Terlaris', 'Toko Terdekat'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: options.map((opt) {
            final isSelected = _rankingSwitch == opt;
            return Expanded(
              child: InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _rankingSwitch = opt);
                },
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? GageTheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: GageTheme.primary.withValues(alpha: 0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      opt,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }





  // ===========================================================================
  // WIDGET KARTU MERCHANT RESMI
  // ===========================================================================
  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeId = store['id'] as String;
    String? tier;
    if (storeId == 'shop-berkah-fajar' || storeId.contains('telur')) {
      tier = 'star';
    }

    final rating = (store['rating'] is num)
        ? (store['rating'] as num).toDouble()
        : double.tryParse(store['rating']?.toString() ?? '') ?? 4.9;

    return GageMerchantCard(
      id: storeId,
      name: store['name'] ?? '',
      category: store['category'] ?? 'Sembako',
      rating: rating,
      ratingCount: (store['ratingCount'] ?? '50+').toString(),
      distance: (store['distance'] ?? '1.0 km').toString(),
      eta: (store['eta'] ?? '15-20 min').toString(),
      image: (store['image'] ?? 'assets/images/hero_banner_1.png').toString(),
      tier: tier,
      promoBadges: const ['Diskon 20%', 'Diskon Ongkir'],
      isFavorite: _favoriteStoreIds.contains(storeId),
      onFavoriteTap: () => _toggleFavorite(storeId, store['name']),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => RestoDetailScreen(merchant: store),
          ),
        );
      },
    );
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final bannerManager = context.watch<BannerManagerService>();
    final cart = context.watch<CartProvider>();
    final shopBanner = bannerManager.getBanner('shop');

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Scrollable Content
          RefreshIndicator(
            onRefresh: _loadStores,
            color: GageTheme.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-bleed Banner 16:9 ke batas atas status bar
                  GageServiceHeroBanner(
                    screenTarget: 'customer_shop',
                    imageAsset: shopBanner.imagePath,
                    fallbackTitle: 'GAGE SHOP',
                    scrollController: _scrollController,
                  ),

                  const SizedBox(height: 38),

                // ===============================================================
                // BODY KONTEN RESPONSIF (Setara Arsitektur GAGE Food)
                // ===============================================================
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [


                        // 2. Kategori Belanja Sembako (Circular Avatar Matching GAGE Food)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    GageSkeletonBox(width: 170, height: 16),
                                    GageSkeletonBox(width: 50, height: 14),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Kategori',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                                    ),
                                    if (_selectedCategory != 'Semua')
                                      GestureDetector(
                                        onTap: () => setState(() => _selectedCategory = 'Semua'),
                                        child: const Text(
                                          'Reset',
                                          style: TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (_isLoading)
                          const GageSkeletonCircularCategoriesRow(count: 6)
                        else
                          SizedBox(
                            height: 196,
                            child: GridView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              scrollDirection: Axis.horizontal,
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 12,
                                childAspectRatio: 1.25,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (ctx, idx) {
                                final cat = _categories[idx];
                                final name = cat['name'] as String;
                                final isSel = _selectedCategory == name;

                                return InkWell(
                                  onTap: () {
                                    HapticFeedback.selectionClick();
                                    setState(() {
                                      _selectedCategory = (_selectedCategory == name && name != 'Semua') ? 'Semua' : name;
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: isSel ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                            width: isSel ? 2.5 : 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isSel ? GageTheme.primary.withValues(alpha: 0.25) : Colors.black12,
                                              blurRadius: isSel ? 8 : 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: ClipOval(
                                          child: Image.asset(
                                            cat['image'] as String,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => Container(
                                              color: GageTheme.primaryLight,
                                              child: Icon(
                                                cat['icon'] as IconData? ?? Icons.shopping_basket_rounded,
                                                color: GageTheme.primary,
                                                size: 26,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        name,
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                          color: isSel ? GageTheme.primary : (isDark ? Colors.white : GageTheme.textPrimary),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 16),
                        _buildRankingSwitch(isDark),

                        const SizedBox(height: 14),

                        // 5. List of Store Cards (Responsive Grid saat Tablet)
                        if (_isLoading)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: 4,
                            itemBuilder: (ctx, idx) => const GageSkeletonStoreCard(),
                          )
                        else if (_filteredStores.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey.shade400),
                                  const SizedBox(height: 10),
                                  Text(
                                    _showFavoritesOnly
                                        ? 'Belum ada toko yang ditandai favorit.'
                                        : 'Toko tidak ditemukan untuk kata kunci "$_searchQuery"',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else if (isTablet)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth > 900 ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 136,
                              ),
                              itemCount: _filteredStores.length,
                              itemBuilder: (ctx, idx) => _buildStoreCard(_filteredStores[idx]),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredStores.length,
                            itemBuilder: (ctx, idx) => _buildStoreCard(_filteredStores[idx]),
                          ),

                        const SizedBox(height: 90),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Sticky Header: Action Buttons & Seamless Docking Search Bar
        Positioned.fill(
          child: GageServiceStickyHeader(
            scrollController: _scrollController,
            locationText: _formatShortAddress(_deliveryLocation),
            onLocationTap: _showDeliveryLocationPicker,
            onBackTap: () => Navigator.pop(context),
            onFavoriteTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const ShopFavoriteScreen()),
              );
            },
            onHistoryTap: () {
              GageCartSheet.show(context);
            },
            actionIcon: Icons.shopping_bag_outlined,
            actionBadgeCount: cart.items.length,
            searchHint: 'Cari sembako & kebutuhan harian...',
            searchController: _searchController,
            onSearchChanged: (val) => setState(() => _searchQuery = val),
            serviceIcon: Icons.storefront_rounded,
          ),
        ),

        // 3. Floating Cart Overlay Melayang Murni (Bebas blok bar)
        const Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SeamlessFloatingCartBar(),
        ),
      ],
    ),
  );
  }
}
