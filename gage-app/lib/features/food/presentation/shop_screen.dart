import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/features/food/presentation/shop_favorite_screen.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
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
      'name': 'Semua',
      'image': 'assets/images/hero_header_clean_16x9.png',
      'icon': Icons.all_inclusive_rounded,
    },
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
      'name': 'Makanan Ringan',
      'image': 'assets/images/prod_indomie.png',
      'icon': Icons.fastfood_rounded,
    },
    {
      'name': 'Sabun & Kebersihan',
      'image': 'assets/images/hero_promo_1.png',
      'icon': Icons.cleaning_services_rounded,
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
      'image': 'assets/images/hero_banner_1.png',
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
      'image': 'assets/images/hero_promo_2.png',
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
      'image': 'assets/images/hero_banner_2.png',
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
      'image': 'assets/images/promo_banner_2.png',
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
    return _retailStores.where((s) {
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
      return true;
    }).toList();
  }





  // ===========================================================================
  // WIDGET KARTU MERCHANT RESMI
  // ===========================================================================
  Widget _buildStoreCard(Map<String, dynamic> store) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final storeId = store['id'] as String;
    final isFav = _favoriteStoreIds.contains(storeId);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ShopStoreDetailScreen(store: store),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Thumbnail Toko
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                height: 84,
                color: Colors.grey.shade100,
                child: Image.asset(
                  store['image'] ?? 'assets/images/hero_banner_1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: Colors.grey, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info Toko
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: GageTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _toggleFavorite(storeId, store['name']),
                        borderRadius: BorderRadius.circular(10),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        '${store['rating'] ?? 4.9} (${store['ratingCount'] ?? '50+'})',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${store['category'] ?? ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${store['eta'] ?? '15-20 min'} (${store['distance'] ?? '1.0 km'})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final bannerManager = context.watch<BannerManagerService>();
    final shopBanner = bannerManager.getBanner('shop');

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      body: Stack(
        children: [
          // 1. Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-bleed Banner 16:9 ke batas atas status bar
                GageServiceHeroBanner(
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kategori Belanja Sembako',
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
                      SizedBox(
                        height: 94,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 14),
                          itemBuilder: (ctx, idx) {
                            final cat = _categories[idx];
                            final name = cat['name'] as String;
                            final isSel = _selectedCategory == name;

                            return InkWell(
                              onTap: () => setState(() => _selectedCategory = name),
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: 62,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 58,
                                      height: 58,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSel ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                                          width: isSel ? 2.0 : 1.2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isSel ? GageTheme.primary.withValues(alpha: 0.2) : Colors.black12,
                                            blurRadius: 6,
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
                                    const SizedBox(height: 6),
                                    Text(
                                      name,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSel ? FontWeight.bold : FontWeight.w600,
                                        color: isSel ? GageTheme.primary : (isDark ? Colors.white : GageTheme.textPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 18),

                      // 5. Header Daftar Toko Merchant Resmi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Toko & Minimarket Mitra Resmi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${_filteredStores.length} Toko Buka',
                              style: const TextStyle(fontSize: 12, color: GageTheme.accentGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 6. List of Store Cards (Responsive Grid saat Tablet)
                      if (_filteredStores.isEmpty)
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
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
              );
            },
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
