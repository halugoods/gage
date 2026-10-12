import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/data/food_categories_data.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/category_merchant_list_screen.dart';
import 'package:gage_app/features/food/presentation/all_categories_screen.dart';
import 'package:gage_app/features/food/presentation/favorite_resto_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:async';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/features/home/presentation/promo_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';

class FoodExploreScreen extends StatefulWidget {
  const FoodExploreScreen({super.key});

@override
  State<FoodExploreScreen> createState() => _FoodExploreScreenState();
}

class _FoodExploreScreenState extends State<FoodExploreScreen> {
  String _selectedLocation = 'Mendeteksi lokasi...';
  final String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoading = true;


  void _showAddressPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran',
      onSelected: (title, fullAddress, latLng) {
        setState(() => _selectedLocation = title);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lokasi diatur ke: $title'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  String _activeFilter = 'Semua';
  final bool _showFavoritesOnly = false;
  final Set<String> _favoriteRestoIds = {'mch-dimsum-01'};

  final List<Map<String, dynamic>> _quickButtons = [
    {
      'title': 'Resto\nTerdekat',
      'icon': Icons.near_me_rounded,
      'color': Color(0xFF00880C),
      'badge': null,
      'action': 'nearest',
    },
    {
      'title': 'Ongkir\nMURAAAH',
      'icon': Icons.delivery_dining_rounded,
      'color': Color(0xFFE65100),
      'badge': null,
      'action': 'cheap_ongkir',
    },
    {
      'title': 'Group\nOrder',
      'icon': Icons.group_rounded,
      'color': Color(0xFFE52320),
      'badge': '-50%',
      'action': 'group',
    },
    {
      'title': 'GAGE Food\nHEMAT',
      'icon': Icons.thumb_up_alt_rounded,
      'color': Color(0xFFC62828),
      'badge': '30rb',
      'action': 'budget',
    },
  ];

  final List<String> _filterChips = [
    'Semua',
    'GAGE Plus',
    'Di Bawah 10rb',
    'Terlaris',
    'Terdekat',
    'Rating 4.5+',
  ];

  @override
  void initState() {
    super.initState();
    _initUserGpsLocation();
    _loadMerchants();
  }

  Future<void> _initUserGpsLocation() async {
    final realGps = await LocationService.getCurrentLocation();
    final addr = await OsmGeocodingService.reverseGeocode(realGps);
    if (!mounted) return;
    setState(() {
      _selectedLocation = addr;
    });
  }

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

  Future<void> _loadMerchants() async {
    final list = await GageApiClient.getMerchants();
    if (!mounted) return;

    // Direktori mitra resmi resto kecamatan Pracimantoro dengan ongkir realistis
    final fallback = [
      {
        'id': 'mch-rc-01',
        'name': 'Rocket Chicken Sambiroto, Pracimantoro',
        'category': 'Cepat saji, Ayam & Aneka nasi',
        'rating': 5.0,
        'ratingCount': '120+',
        'distance': '1.2 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 35%',
        'ongkirBadge': 'Diskon Ongkir Rp 4rb',
        'image': 'assets/images/resto_rocket_chicken.png',
      },
      {
        'id': 'mch-dimsum-01',
        'name': 'Dimsum Sewu, Alfamidi Pracimantoro',
        'category': 'Jajanan & Dimsum hangat',
        'rating': 4.9,
        'ratingCount': '85',
        'distance': '1.8 km',
        'eta': '25-35 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 50%',
        'ongkirBadge': 'Diskon Ongkir Rp 4rb',
        'image': 'assets/images/resto_dimsum_sewu.png',
      },
      {
        'id': 'mch-mie-01',
        'name': 'Mie Ayam Pak Kumis, Pracimantoro',
        'category': 'Mie & Bakso Urat Komplit',
        'rating': 4.8,
        'ratingCount': '64',
        'distance': '2.1 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Diskon 20%',
        'ongkirBadge': 'Diskon Ongkir Rp 5rb',
        'image': 'assets/images/resto_mie_ayam.png',
      },
      {
        'id': 'mch-seblak-01',
        'name': 'Seblak Prasmanan Nyentrik Pracimantoro',
        'category': 'Seblak & Pedas Prasmanan',
        'rating': 4.9,
        'ratingCount': '95',
        'distance': '1.5 km',
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon Rp 5rb',
        'ongkirBadge': 'Diskon Ongkir Rp 4rb',
        'image': 'assets/images/resto_seblak.png',
      },
      {
        'id': 'mch-roti-01',
        'name': 'Roti Gembong Gedhe, Pracimantoro',
        'category': 'Roti & Bakery, Jajanan Manis',
        'rating': 4.9,
        'ratingCount': '42',
        'distance': '2.5 km',
        'eta': '25-35 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Diskon 25%',
        'ongkirBadge': 'Diskon Ongkir Rp 5rb',
        'image': 'assets/images/resto_roti_gembong.png',
      },
    ];

    setState(() {
      _merchants = list.isNotEmpty ? list : fallback;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: Colors.white,
      body: RefreshIndicator(
        onRefresh: _loadMerchants,
        color: GageTheme.primary,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Unified GoFood Hero Header (Drawer + Full Banner + Floating Actions & Search)
              _buildGoFoodHeroHeader(context),

              const SizedBox(height: 18),

              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 3. 4 Quick Filter Buttons (Resto Terdekat, Ongkir Murah, Group Order, Hemat)
                      _buildQuickButtons(),

                      const SizedBox(height: 24),

                      // 4. Kategori Kuliner Bulat ("Kuliner sesuai seleramu")
                      _buildCulinaryCategoriesSection(),

                      const SizedBox(height: 20),

                      // 5. Horizontal Filter Chips
                      _buildFilterChips(),

                      const SizedBox(height: 16),

                      // 6. Section Headline & Daftar Resto Mitra Terdaftar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Makan enak buat kamu di Pracimantoro 🍜',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: GageTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pilihan resto mitra resmi dengan rating terbaik',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // List Kartu Resto
                      _buildMerchantList(),

                      const SizedBox(height: 16),

                      // Banner Iklan Sponsor Kuliner di Tengah List
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            'assets/images/promo_banner_1.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (c, e, s) => const SizedBox(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoFoodHeroHeader(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final iconBrightness = isDark ? Brightness.light : Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: barColor,
        statusBarIconBrightness: iconBrightness,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Drawer Android Atas (Sesuai tema HP: putih di light mode)
          Container(
            height: topPadding,
            color: barColor,
          ),

          // 2. Full-Width Banner Hero (Edge-to-Edge) dengan Floating Actions & Floating Search
          SizedBox(
            height: 224, // Tinggi total: banner (200dp) + overlap search bar (24dp)
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Full Width Banner Photo (Murni Bersih Bebas Vignette & Teks Overlay)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 200,
                  child: Image.asset(
                    'assets/images/food_hero_banner.png',
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: GageTheme.primary),
                  ),
                ),

                // Floating Actions di Atas Banner (Persis Layout GoFood Gojek)
                Positioned(
                  top: 10,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      // Tombol X (Lingkaran Card Putih)
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.close_rounded, color: Colors.black87, size: 22),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Card Alamat (HANYA membungkus teks alamat, tidak memanjang!)
                      Flexible(
                        child: GestureDetector(
                          onTap: _showAddressPicker,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on, color: GageTheme.primary, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${_formatShortAddress(_selectedLocation)} ▾',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const Spacer(),

                      // Tombol Favorit (Lingkaran Card Putih)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const FavoriteRestoScreen()),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Tombol Riwayat Pesanan (Lingkaran Card Putih)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Colors.black87, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // Floating Search Bar ("Lagi mau mamam apa?") Overlap 50% di Batas Bawah Banner
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width >= 600 ? 680 : double.infinity,
                      ),
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                      textAlignVertical: TextAlignVertical.center,
                      onChanged: (val) {
                        setState(() => _searchQuery = val);
                      },
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Lagi mau mamam apa?',
                        hintStyle: TextStyle(fontSize: 13.5, color: Colors.grey),
                        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey, size: 21),
                        prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 48),
                        suffixIcon: Icon(Icons.restaurant_rounded, color: GageTheme.primary, size: 20),
                        suffixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 48),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _quickButtons.map((btn) {
          final badge = btn['badge'] as String?;
          final title = btn['title'] as String;
          final action = btn['action'] as String?;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: InkWell(
                onTap: () {
                  if (action == 'nearest' || title.contains('Terdekat')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const CategoryMerchantListScreen(
                          categoryName: 'Resto Terdekat',
                          filterMode: 'nearest',
                        ),
                      ),
                    );
                  } else if (action == 'cheap_ongkir' || title.contains('MURAAAH') || title.contains('Ongkir')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const CategoryMerchantListScreen(
                          categoryName: 'Promo Ongkir Hemat',
                          filterMode: 'cheap_ongkir',
                        ),
                      ),
                    );
                  } else if (action == 'group' || title.contains('Group')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const PromoScreen(),
                      ),
                    );
                  } else if (action == 'budget' || title.contains('HEMAT')) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (ctx) => const CategoryMerchantListScreen(
                          categoryName: 'GAGE Food Hemat',
                          filterMode: 'budget',
                        ),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade200),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Icon(btn['icon'] as IconData, color: btn['color'] as Color, size: 26),
                          if (badge != null)
                            Positioned(
                              top: -8,
                              right: -12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.black87,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCulinaryCategoriesSection() {
    final categories = FoodCategoriesData.allCategories;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Kuliner sesuai seleramu',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: GageTheme.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => const AllCategoriesScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(8),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    'Lihat Semua',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: GageTheme.accentGreen,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 98,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 14),
            itemBuilder: (ctx, idx) {
              final cat = categories[idx];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (c) => CategoryMerchantListScreen(
                        categoryName: cat.name,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Column(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1.2,
                        ),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          cat.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: GageTheme.primaryLight,
                            child: const Icon(Icons.restaurant, color: GageTheme.primary),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      cat.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GageTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _filterChips.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final label = _filterChips[idx];
          final isSelected = _activeFilter == label;

          return InkWell(
            onTap: () {
              setState(() {
                _activeFilter = label;
              });
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? GageTheme.primary : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? GageTheme.primary : Colors.grey.shade300,
                  width: 1,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? Colors.white : GageTheme.textPrimary,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMerchantList() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: CircularProgressIndicator(color: GageTheme.primary),
        ),
      );
    }

    final filtered = _merchants.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final cat = (m['category'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesSearch = name.contains(q) || cat.contains(q);

      final matchesCat = _selectedCategory == 'Semua' ||
          name.contains(_selectedCategory.toLowerCase()) ||
          cat.contains(_selectedCategory.toLowerCase());

      final matchesFavorite = !_showFavoritesOnly || _favoriteRestoIds.contains(m['id']);

      return matchesSearch && matchesCat && matchesFavorite;
    }).toList();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filtered.length,
      itemBuilder: (ctx, idx) {
        return _buildRestoCard(filtered[idx]);
      },
    );
  }

  Widget _buildRestoCard(Map<String, dynamic> m) {
    return InkWell(
      onTap: () {
        // KLIK OUTLET RESTO -> BARU MEMBUKA MENU RESTO
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => RestoDetailScreen(merchant: m),
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
            // Foto Thumbnail Outlet Resto
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 80,
                height: 80,
                color: Colors.grey.shade100,
                child: Image.asset(
                  m['image'] ?? 'assets/images/resto_dimsum_sewu.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info Resto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GageTheme.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        '${m['rating'] ?? 5.0} (${m['ratingCount'] ?? '50+'})',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${m['category'] ?? ''}',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.near_me_rounded, color: GageTheme.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        '📍 ${m['distance'] ?? '1.2 km'} • ${m['eta'] ?? '15-20 min'}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      // Badge Informasi Jarak Riil (Gantikan estimasi ongkir)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0xFFBBF7D0)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 11),
                            const SizedBox(width: 3),
                            Text(
                              '📍 ${m['distance'] ?? '1.2 km'} • ${m['eta'] ?? '15 mnt'}',
                              style: const TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (m['diskonBadge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_rounded, color: GageTheme.primary, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                m['diskonBadge'],
                                style: const TextStyle(
                                  color: GageTheme.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// Interactive Map Location Picker Sheet & Custom Map Painter
// -------------------------------------------------------------
class _MapPickerSheet extends StatefulWidget {
  final String initialLocation;
  final Function(String selectedName, String selectedAddress) onLocationSelected;

  const _MapPickerSheet({
    required this.initialLocation,
    required this.onLocationSelected,
  });

  @override
  State<_MapPickerSheet> createState() => _MapPickerSheetState();
}

class _MapPickerSheetState extends State<_MapPickerSheet> {
  final MapController _mapController = MapController();
  LatLng _center = const LatLng(-8.0834, 110.8454);
  String _currentTitle = 'Titik Peta: Sambiroto, Pracimantoro';
  String _currentAddress = 'Sumberjo, Sambiroto, Kec. Pracimantoro, Wonogiri';
  bool _isReverseGeocoding = false;


  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (hasGesture) {
      _center = camera.center;
      _reverseGeocodeDebounced();
    }
  }

  Timer? _debounceTimer;
  void _reverseGeocodeDebounced() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      if (!mounted) return;
      setState(() => _isReverseGeocoding = true);
      final addr = await OsmGeocodingService.reverseGeocode(_center);
      if (!mounted) return;
      setState(() {
        _currentAddress = addr;
        _currentTitle = addr.split(',').first;
        _isReverseGeocoding = false;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _initRealGps();
  }

  Future<void> _initRealGps() async {
    final realGps = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() {
      _center = realGps;
    });
    _mapController.move(realGps, 16.0);
    final addr = await OsmGeocodingService.reverseGeocode(realGps);
    if (!mounted) return;
    setState(() {
      _currentAddress = addr;
      _currentTitle = addr.split(',').first;
    });
  }

  Future<void> _resetToGPS() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mencari posisi GPS Anda saat ini...'),
        duration: Duration(milliseconds: 900),
        behavior: SnackBarBehavior.floating,
      ),
    );
    final realGps = await LocationService.getCurrentLocation();
    if (!mounted) return;
    _mapController.move(realGps, 16.0);
    setState(() {
      _center = realGps;
    });
    final addr = await OsmGeocodingService.reverseGeocode(realGps);
    if (!mounted) return;
    setState(() {
      _currentAddress = addr;
      _currentTitle = addr.split(',').first;
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          // Drag handle & Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Column(
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4.5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Titik Pengantaran',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Geser peta untuk menentukan titik tujuan yang pas',
                          style: TextStyle(fontSize: 11.5, color: Colors.black54),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Real OpenStreetMap Interactive Area
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 15.5,
                    minZoom: 11.0,
                    maxZoom: 18.0,
                    onPositionChanged: _onPositionChanged,
                  ),
                  children: [
                    // Google Maps Roadmap Tiles (100% Free, Zero API Key, Zero Watermark, Akurat & Lengkap di Indonesia)
                    TileLayer(
                      urlTemplate: 'https://mt{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                      subdomains: const ['0', '1', '2', '3'],
                      userAgentPackageName: 'com.gage.customer',
                      maxZoom: 20.0,
                      fallbackUrl: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    ),
                  ],
                ),

                // Top Instruction Pill
                Positioned(
                  top: 14,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.touch_app_rounded, size: 15, color: Color(0xFF00880C)),
                          const SizedBox(width: 6),
                          Text(
                            _isReverseGeocoding ? 'Mendeteksi alamat...' : 'Geser peta untuk menentukan titik',
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Fixed Center Location Pin Marker (Gojek / Grab Style)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 38),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: const [
                              BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                            ],
                          ),
                          child: const Text(
                            'Lokasi Antar Pas di Sini',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Icon(
                          Icons.location_on_rounded,
                          size: 44,
                          color: Color(0xFFE52320),
                        ),
                        Container(
                          width: 10,
                          height: 5,
                          decoration: BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Floating "GPS Saya" Button
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'gps_map_picker',
                    onPressed: _resetToGPS,
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF00880C),
                    elevation: 3,
                    child: const Icon(Icons.my_location_rounded, size: 22),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.location_on_rounded, color: Color(0xFFE52320), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentTitle,
                              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _currentAddress,
                              style: const TextStyle(fontSize: 11.5, color: Colors.black54, height: 1.3),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onLocationSelected(_currentTitle, _currentAddress);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00880C),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
                      ),
                      child: const Text(
                        'Gunakan Lokasi Ini',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
