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
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

typedef FarmExploreScreen = FarmScreen;

/// Screen Utama GAGE Farm (Pertanian & Peternakan)
/// Mengikuti arsitektur standar GAGE Food dengan 2 tab switch terpadu:
/// Tab 1: Pertanian (Pupuk, Benih, Pestisida & Alat Tani)
/// Tab 2: Peternakan (Pakan Unggas, Konsentrat Sapi/Kambing & Vitamin)
class FarmScreen extends StatefulWidget {
  final String initialTab; // 'pertanian' | 'peternakan'

  const FarmScreen({
    super.key,
    this.initialTab = 'pertanian',
  });

  @override
  State<FarmScreen> createState() => _FarmScreenState();
}

class _FarmScreenState extends State<FarmScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  late String _activeTab; // 'pertanian' | 'peternakan'
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isLoading = true;
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteStoreIds = {'farm-kios-subur'};

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
    _activeTab = widget.initialTab;
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
      title: 'Pilih Lokasi Pengantaran Kebutuhan Tani & Ternak',
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

  List<String> get _categories {
    if (_activeTab == 'pertanian') {
      return [
        'Semua',
        'Pupuk & Nutrisi',
        'Benih & Bibit',
        'Obat Hama & Pestisida',
        'Alat Pertanian',
      ];
    } else {
      return [
        'Semua',
        'Pakan Unggas',
        'Pakan Sapi & Kambing',
        'Konsentrat Pakan',
        'Vitamin & Obat Hewan',
      ];
    }
  }

  final List<Map<String, dynamic>> _pertanianStores = [
    {
      'id': 'farm-kios-subur',
      'tab': 'pertanian',
      'name': 'Kios Tani Subur Makmur',
      'category': 'Pupuk & Nutrisi, Benih & Bibit',
      'address': 'Jl. Raya Pracimantoro KM 1, Wonogiri',
      'distance': '0.8 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '140+',
      'openHours': '06:30 - 17:30',
      'isOpen': true,
      'image': 'assets/images/prod_pupuk.png',
      'description': 'Sedia pupuk Urea, NPK Mutiara 16-16-16, benih padi Inpari & Ciherang, dan fungisida tanaman.',
    },
    {
      'id': 'farm-sumber-rejeki',
      'tab': 'pertanian',
      'name': 'Toko Pertanian Sumber Rejeki',
      'category': 'Benih & Bibit, Alat Pertanian',
      'address': 'Simpang Empat Pasar Pracimantoro Blok B',
      'distance': '0.5 km',
      'eta': '10-15 min',
      'rating': 4.8,
      'ratingCount': '95+',
      'openHours': '07:00 - 16:30',
      'isOpen': true,
      'image': 'assets/images/prod_benih.png',
      'description': 'Benih cabai rawit ori 212, tomat servo, terong ungu, sprayer tangki elektrik 16L, dan mulsa plastik.',
    },
    {
      'id': 'farm-tani-lestari',
      'tab': 'pertanian',
      'name': 'Kios Pupuk & Benih Tani Lestari',
      'category': 'Pupuk & Nutrisi, Obat Hama & Pestisida',
      'address': 'Tubokarto, Pracimantoro',
      'distance': '1.4 km',
      'eta': '20-25 min',
      'rating': 4.9,
      'ratingCount': '68+',
      'openHours': '07:00 - 17:00',
      'isOpen': true,
      'image': 'assets/images/prod_pupuk.png',
      'description': 'Distributor pupuk organik cair, dolomit kalsium pertanian, insektisida ulat & wereng tanaman pangan.',
    },
    {
      'id': 'farm-ud-berkah-joho',
      'tab': 'pertanian',
      'name': 'UD Tani Berkah Joho',
      'category': 'Alat Pertanian, Pupuk & Nutrisi',
      'address': 'Joho, Pracimantoro',
      'distance': '2.1 km',
      'eta': '25-30 min',
      'rating': 4.7,
      'ratingCount': '54+',
      'openHours': '06:00 - 18:00',
      'isOpen': true,
      'image': 'assets/images/prod_traktor.png',
      'description': 'Cangkul baja, arit rumput, pupuk kandang sapi matang fermentasi karungan, dan paranet peneduh.',
    },
  ];

  final List<Map<String, dynamic>> _peternakanStores = [
    {
      'id': 'farm-poultry-berkah',
      'tab': 'peternakan',
      'name': 'Poultry Shop Berkah Ternak',
      'category': 'Pakan Unggas, Vitamin & Obat Hewan',
      'address': 'Jl. Raya Pracimantoro No. 45, Wonogiri',
      'distance': '0.6 km',
      'eta': '10-15 min',
      'rating': 4.9,
      'ratingCount': '160+',
      'openHours': '06:30 - 18:00',
      'isOpen': true,
      'image': 'assets/images/prod_pakan.png',
      'description': 'Pakan BR-1 crumble ayam pedaging, pakan layer petelur, dedak bekatul halus, Vitachick & tempat minum unggas.',
    },
    {
      'id': 'farm-depot-harapan',
      'tab': 'peternakan',
      'name': 'Depot Pakan Ternak Harapan Jaya',
      'category': 'Pakan Sapi & Kambing, Konsentrat Pakan',
      'address': 'Sambiroto, Pracimantoro',
      'distance': '1.2 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '110+',
      'openHours': '06:00 - 17:30',
      'isOpen': true,
      'image': 'assets/images/prod_pakan.png',
      'description': 'Konsentrat penggemukan sapi potong 50kg, ampas bir kering, mineral premix blok jilat sapi & molasses tetes tebu.',
    },
    {
      'id': 'farm-kios-sedayu',
      'tab': 'peternakan',
      'name': 'Kios Pakan & Vitamin Hewan Sedayu',
      'category': 'Pakan Unggas, Konsentrat Pakan',
      'address': 'Sedayu, Pracimantoro',
      'distance': '1.7 km',
      'eta': '20-25 min',
      'rating': 4.8,
      'ratingCount': '85+',
      'openHours': '07:00 - 17:00',
      'isOpen': true,
      'image': 'assets/images/prod_telur.png',
      'description': 'Jagung giling pecah murni, konsentrat bebek petelur, probiotik EM4 peternakan, dan desinfektan kandang Rodalon.',
    },
    {
      'id': 'farm-sentra-mandiri',
      'tab': 'peternakan',
      'name': 'Sentra Konsentrat Ternak Mandiri',
      'category': 'Pakan Sapi & Kambing, Vitamin & Obat Hewan',
      'address': 'Pracimantoro Kota',
      'distance': '0.9 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '92+',
      'openHours': '07:00 - 17:00',
      'isOpen': true,
      'image': 'assets/images/prod_pakan.png',
      'description': 'Polar gandum curah, bungkil kedelai (SBM), antibiotik ternak Medoxy, vitamin B-kompleks & tali tampar sapi.',
    },
  ];

  List<Map<String, dynamic>> get _currentStores {
    final list = _activeTab == 'pertanian' ? _pertanianStores : _peternakanStores;
    return list.where((s) {
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
    final bannerManager = context.watch<BannerManagerService>();
    final farmBanner = bannerManager.getBanner('farm');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  // Full-bleed Banner 16:9 ke batas atas status bar
                  GageServiceHeroBanner(
                    screenTarget: 'farm',
                    imageAsset: farmBanner.imagePath.isNotEmpty ? farmBanner.imagePath : 'assets/icons/ic_farm.png',
                    fallbackTitle: 'GAGE FARM',
                    scrollController: _scrollController,
                  ),

                  const SizedBox(height: 38),

                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Dual Segment Switcher (Pertanian vs Peternakan)
                          _buildTabSegmentSwitcher(isDark),

                          const SizedBox(height: 10),

                          // Horizontal Categories Filter Chips
                          _buildCategoriesBar(isDark),

                          const SizedBox(height: 18),

                          // Header Toko
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _activeTab == 'pertanian' ? 'Daftar Kios Pertanian Mitra' : 'Daftar Depot Pakan & Peternakan',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  '${_currentStores.length} Kios Buka',
                                  style: const TextStyle(fontSize: 12, color: GageTheme.accentGreen, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // Daftar Toko
                          if (_isLoading)
                            _buildShimmerLoading()
                          else if (_currentStores.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
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
                              itemCount: _currentStores.length,
                              itemBuilder: (ctx, idx) => _buildStoreCard(_currentStores[idx]),
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
              searchHint: _activeTab == 'pertanian' ? 'Cari pupuk, benih, pestisida...' : 'Cari pakan ayam, konsentrat...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.eco_rounded,
            ),
          ),

          // Floating Bottom Cart Bar
          const SeamlessFloatingCartBar(),
        ],
      ),
    );
  }

  Widget _buildTabSegmentSwitcher(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSegmentItem(
              title: 'Pertanian',
              icon: Icons.eco_rounded,
              isSelected: _activeTab == 'pertanian',
              activeColor: const Color(0xFF16A34A),
              onTap: () {
                if (_activeTab != 'pertanian') {
                  setState(() {
                    _activeTab = 'pertanian';
                    _selectedCategory = 'Semua';
                  });
                }
              },
            ),
          ),
          Expanded(
            child: _buildSegmentItem(
              title: 'Peternakan',
              icon: Icons.pets_rounded,
              isSelected: _activeTab == 'peternakan',
              activeColor: const Color(0xFFD97706),
              onTap: () {
                if (_activeTab != 'peternakan') {
                  setState(() {
                    _activeTab = 'peternakan';
                    _selectedCategory = 'Semua';
                  });
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentItem({
    required String title,
    required IconData icon,
    required bool isSelected,
    required Color activeColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected ? activeColor : Colors.grey.shade600,
            ),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? Colors.black87 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesBar(bool isDark) {
    final cats = _categories;
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cats.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) {
          final cat = cats[idx];
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
                  store['image'] ?? 'assets/images/prod_pupuk.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Icon(
                    _activeTab == 'pertanian' ? Icons.eco_rounded : Icons.pets_rounded,
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
