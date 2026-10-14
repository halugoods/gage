import 'package:flutter/material.dart';
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
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';

class FoodExploreScreen extends StatefulWidget {
  const FoodExploreScreen({super.key});

@override
  State<FoodExploreScreen> createState() => _FoodExploreScreenState();
}

class _FoodExploreScreenState extends State<FoodExploreScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();

  String _selectedLocation = 'Mendeteksi lokasi...';
  final String _selectedCategory = 'Semua';
  String _searchQuery = '';
  List<Map<String, dynamic>> _merchants = [];
  bool _isLoading = true;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }


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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      body: Stack(
        children: [
          // 1. Scrollable Content
          RefreshIndicator(
            onRefresh: _loadMerchants,
            color: GageTheme.primary,
            child: SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full-bleed Banner 16:9 ke batas atas status bar dengan smooth fade-out
                  GageServiceHeroBanner(
                    imageAsset: 'assets/images/food_hero_banner.png',
                    fallbackTitle: 'GAGE FOOD',
                    scrollController: _scrollController,
                  ),

                  const SizedBox(height: 38),

                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Kategori Kuliner Bulat ("Kuliner sesuai seleramu")
                          _buildCulinaryCategoriesSection(),

                          const SizedBox(height: 20),

                          // Horizontal Filter Chips
                          _buildFilterChips(),

                          const SizedBox(height: 16),

                          // Section Headline & Daftar Resto Mitra Terdaftar
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Makan enak buat kamu di Pracimantoro 🍜',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : GageTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Pilihan resto mitra resmi dengan rating terbaik',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                  ),
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
                                'assets/images/food_hero_banner.png',
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (c, e, s) => const SizedBox(),
                              ),
                            ),
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
              locationText: _formatShortAddress(_selectedLocation),
              onLocationTap: _showAddressPicker,
              onBackTap: () => Navigator.pop(context),
              onFavoriteTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const FavoriteRestoScreen()),
                );
              },
              onHistoryTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                );
              },
              searchHint: 'Lagi mau mamam apa?',
              searchController: _searchCtrl,
              onSearchChanged: (val) {
                setState(() => _searchQuery = val);
              },
              serviceIcon: Icons.restaurant_rounded,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                  const SizedBox(height: 3),
                  Text(
                    '${m['eta'] ?? '20-30 min'} (${m['distance'] ?? '1.2 km'})',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (m['diskonBadge'] != null)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
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
                          const Icon(Icons.touch_app_rounded, size: 15, color: GageTheme.primary),
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
                    foregroundColor: GageTheme.primary,
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
                        backgroundColor: GageTheme.primary,
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
