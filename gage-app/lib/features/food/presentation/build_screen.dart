import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

typedef BuildExploreScreen = BuildScreen;

/// Screen Utama GAGE Build (Toko Bangunan, Material, Cat & Pertukangan)
/// Mengikuti arsitektur standar GAGE Food dengan direktori mitra toko bangunan terverifikasi.
class BuildScreen extends StatefulWidget {
  const BuildScreen({super.key});

  @override
  State<BuildScreen> createState() => _BuildScreenState();
}

class _BuildScreenState extends State<BuildScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteStoreIds = {'build-sumber-bangunan'};

  final List<String> _categories = [
    'Semua',
    'Semen & Pasir',
    'Cat & Thinner',
    'Besi & Baja Ringan',
    'Pipa & Sanitasi',
    'Alat Pertukangan & Listrik',
  ];

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

  final List<Map<String, dynamic>> _buildStores = [
    {
      'id': 'build-sumber-bangunan',
      'name': 'TB Sumber Bangunan Pracimantoro',
      'category': 'Semen & Pasir, Besi & Baja Ringan',
      'address': 'Jl. Raya Pracimantoro No. 88, Wonogiri',
      'distance': '0.6 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '130+',
      'openHours': '07:00 - 17:00',
      'isOpen': true,
      'image': 'assets/icons/ic_build.png',
      'description': 'Pusat semen Gresik & Tiga Roda 40kg, pasir muntilan, bata merah, besi beton SNI 8mm/10mm/12mm & kawat bendrat.',
    },
    {
      'id': 'build-mega-jaya',
      'name': 'Toko Besi & Bangunan Mega Jaya',
      'category': 'Besi & Baja Ringan, Pipa & Sanitasi',
      'address': 'Kawasan Terminal Pracimantoro, Wonogiri',
      'distance': '1.0 km',
      'eta': '15-25 min',
      'rating': 4.8,
      'ratingCount': '85+',
      'openHours': '07:30 - 17:00',
      'isOpen': true,
      'image': 'assets/icons/ic_build.png',
      'description': 'Baja ringan canal C75, reng, spandek atap seng, pipa PVC Wavin/Rucika D 3/4 & 1/2 inch, kran air, fitting sambungan.',
    },
    {
      'id': 'build-griya-indah',
      'name': 'Toko Cat & Finishing Griya Indah',
      'category': 'Cat & Thinner, Alat Pertukangan & Listrik',
      'address': 'Simpang Tiga Pasar Pracimantoro No. 15',
      'distance': '0.4 km',
      'eta': '10-15 min',
      'rating': 4.9,
      'ratingCount': '115+',
      'openHours': '07:00 - 17:30',
      'isOpen': true,
      'image': 'assets/icons/ic_build.png',
      'description': 'Cat tembok Dulux & Avian, cat besi/kayu anti karat, Nippon Paint, thinner A super, kuas, roll cat, amplas.',
    },
    {
      'id': 'build-sinar-mandiri',
      'name': 'TB Sinar Mandiri Material',
      'category': 'Alat Pertukangan & Listrik, Semen & Pasir',
      'address': 'Sambiroto, Pracimantoro',
      'distance': '1.3 km',
      'eta': '20-25 min',
      'rating': 4.8,
      'ratingCount': '62+',
      'openHours': '06:30 - 17:00',
      'isOpen': true,
      'image': 'assets/icons/ic_build.png',
      'description': 'Meteran, palu baja, gergaji, bor listrik, kabel tembaga Eterna, saklar stop kontak Panasonic & paku kayu/beton.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
    _loadStores();
  }

  Future<void> _loadStores() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 280));
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
    try {
      final gps = await LocationService.getCurrentLocation();
      final addr = await OsmGeocodingService.reverseGeocode(gps);
      if (mounted && addr.isNotEmpty) {
        setState(() {
          _deliveryLocation = addr;
        });
      }
    } catch (_) {}
  }

  void _showDeliveryLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran Bahan Bangunan',
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

  List<Map<String, dynamic>> get _filteredStores {
    return _buildStores.where((s) {
      final name = s['name'].toString().toLowerCase();
      final cat = s['category'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty || name.contains(q) || cat.contains(q);

      if (!matchesQuery) return false;

      if (_selectedCategory == 'Semua') return true;
      return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      body: Stack(
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
                  // Full-bleed Banner 16:9
                  GageServiceHeroBanner(
                    screenTarget: 'build',
                    imageAsset: 'assets/icons/ic_build.png',
                    fallbackTitle: 'GAGE BUILD',
                    scrollController: _scrollController,
                  ),

                  const SizedBox(height: 38),

                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Categories Horizontal Bar
                          _buildCategoriesBar(isDark),

                          const SizedBox(height: 18),

                          // Header Toko Bangunan
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Daftar Toko Material & Bangunan Mitra',
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

                          if (_isLoading)
                            _buildShimmerLoading()
                          else if (_filteredStores.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 8),
                                    Text('Tidak ada toko yang cocok', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
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
              onFavoriteTap: () {},
              onHistoryTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                );
              },
              searchHint: 'Cari semen, cat, besi, alat bangunan...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.construction_rounded,
            ),
          ),

          // Floating Bottom Cart Bar
          const SeamlessFloatingCartBar(),
        ],
      ),
    );
  }

  Widget _buildCategoriesBar(bool isDark) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final cat = _categories[idx];
          final isSel = _selectedCategory == cat;
          return ChoiceChip(
            label: Text(cat),
            selected: isSel,
            onSelected: (selected) {
              if (selected) {
                setState(() => _selectedCategory = cat);
              }
            },
            labelStyle: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
              color: isSel ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.black87),
            ),
            selectedColor: GageTheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: isSel ? GageTheme.primary : (isDark ? Colors.transparent : Colors.grey.shade300),
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
          );
        },
      ),
    );
  }

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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 82,
                height: 82,
                color: isDark ? const Color(0xFF0F172A) : Colors.grey.shade100,
                child: Image.asset(
                  store['image'] ?? 'assets/icons/ic_build.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(
                    Icons.construction_rounded,
                    color: Colors.grey,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store['name'] ?? '',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : GageTheme.textPrimary,
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
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${store['category'] ?? ''}',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${store['eta'] ?? '15-20 min'} (${store['distance'] ?? '1.0 km'}) • ${store['address'] ?? ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 3,
      itemBuilder: (ctx, idx) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            GageSkeletonBox(width: 82, height: 82, borderRadius: BorderRadius.circular(12)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GageSkeletonBox(width: 160, height: 16, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 8),
                  GageSkeletonBox(width: 110, height: 12, borderRadius: BorderRadius.circular(4)),
                  const SizedBox(height: 6),
                  GageSkeletonBox(width: 80, height: 12, borderRadius: BorderRadius.circular(4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
