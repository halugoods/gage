import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_cart_sheet.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_merchant_card.dart';

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
  String _rankingSwitch = 'Rekomendasi'; // 'Rekomendasi', 'Terlaris', 'Kios Terdekat'
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

  List<Map<String, dynamic>> get _categoriesData {
    if (_activeTab == 'pertanian') {
      return [
        {'name': 'Pupuk & Nutrisi', 'image': 'assets/images/prod_pupuk.png', 'icon': Icons.grain_rounded},
        {'name': 'Benih & Bibit', 'image': 'assets/images/prod_benih.png', 'icon': Icons.spa_rounded},
        {'name': 'Obat & Pestisida', 'image': 'assets/images/hero_promo_1.png', 'icon': Icons.medical_services_rounded},
        {'name': 'Alat Pertanian', 'image': 'assets/images/prod_traktor.png', 'icon': Icons.agriculture_rounded},
        {'name': 'Padi & Palawija', 'image': 'assets/images/prod_beras.png', 'icon': Icons.rice_bowl_rounded},
        {'name': 'Cabai & Sayuran', 'image': 'assets/images/prod_cabai.png', 'icon': Icons.eco_rounded},
        {'name': 'Pipa Irigasi', 'image': 'assets/images/hero_promo_2.png', 'icon': Icons.water_drop_rounded},
      ];
    } else {
      return [
        {'name': 'Pakan Unggas', 'image': 'assets/images/prod_pakan.png', 'icon': Icons.pets_rounded},
        {'name': 'Pakan Sapi', 'image': 'assets/images/prod_pakan.png', 'icon': Icons.cruelty_free_rounded},
        {'name': 'Konsentrat Pakan', 'image': 'assets/images/prod_beras.png', 'icon': Icons.grain_rounded},
        {'name': 'Vitamin & Obat Hewan', 'image': 'assets/images/hero_promo_1.png', 'icon': Icons.medication_rounded},
        {'name': 'Telur & DOC', 'image': 'assets/images/prod_telur.png', 'icon': Icons.egg_rounded},
        {'name': 'Peralatan Kandang', 'image': 'assets/images/prod_traktor.png', 'icon': Icons.fence_rounded},
        {'name': 'Desinfektan', 'image': 'assets/images/hero_promo_2.png', 'icon': Icons.sanitizer_rounded},
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
    final filtered = list.where((s) {
      final name = s['name'].toString().toLowerCase();
      final cat = s['category'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty || name.contains(q) || cat.contains(q);

      if (!matchesQuery) return false;

      if (_selectedCategory == 'Semua') return true;
      return cat.toLowerCase().contains(_selectedCategory.toLowerCase());
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
      case 'Kios Terdekat':
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

  @override
  Widget build(BuildContext context) {
    final bannerManager = context.watch<BannerManagerService>();
    final cart = context.watch<CartProvider>();
    final farmBanner = bannerManager.getBanner('farm');
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
                          // Horizontal Categories Filter Chips
                          _buildCategoriesBar(isDark),

                          const SizedBox(height: 14),

                          // Dual Segment Switcher (Pertanian vs Peternakan - Full Rounded Capsule)
                          _buildTabSegmentSwitcher(isDark),

                          const SizedBox(height: 10),

                          // Switcher Ranking (Rekomendasi / Terlaris / Kios Terdekat)
                          _buildRankingSwitch(isDark),

                          const SizedBox(height: 14),

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
                GageCartSheet.show(context);
              },
              actionIcon: Icons.shopping_bag_outlined,
              actionBadgeCount: cart.items.length,
              searchHint: _activeTab == 'pertanian' ? 'Cari pupuk, benih, pestisida...' : 'Cari pakan ayam, konsentrat...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.eco_rounded,
            ),
          ),

          // Floating Bottom Cart Bar (Melayang presisi di dasar layar)
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

  Widget _buildTabSegmentSwitcher(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(30),
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
                HapticFeedback.lightImpact();
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
                HapticFeedback.lightImpact();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? (isDark ? GageTheme.darkSurface : Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
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
    final cats = _categoriesData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
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
            itemCount: cats.length,
            itemBuilder: (ctx, idx) {
              final cat = cats[idx];
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
                              cat['icon'] as IconData? ?? Icons.agriculture_rounded,
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
      ],
    );
  }

  Widget _buildRankingSwitch(bool isDark) {
    final options = ['Rekomendasi', 'Terlaris', 'Kios Terdekat'];

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

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeId = store['id'] as String;
    String? tier;
    if (storeId == 'farm-kios-subur') {
      tier = 'exclusive';
    } else if (storeId == 'farm-sentra-mandiri') {
      tier = 'star';
    }

    final rating = (store['rating'] is num)
        ? (store['rating'] as num).toDouble()
        : double.tryParse(store['rating']?.toString() ?? '') ?? 4.9;

    return GageMerchantCard(
      id: storeId,
      name: store['name'] ?? '',
      category: store['category'] ?? 'Pertanian & Peternakan',
      rating: rating,
      ratingCount: (store['ratingCount'] ?? '50+').toString(),
      distance: (store['distance'] ?? '1.0 km').toString(),
      eta: (store['eta'] ?? '15-20 min').toString(),
      image: (store['image'] ?? 'assets/images/prod_pupuk.png').toString(),
      tier: tier,
      campaignBadge: tier == 'exclusive' ? 'SUBSIDI TANI' : null,
      promoBadges: const ['Diskon 15%', 'Diskon Ongkir'],
      isFavorite: _favoriteStoreIds.contains(storeId),
      onFavoriteTap: () => _toggleFavorite(storeId, store['name']),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ShopStoreDetailScreen(store: store),
          ),
        );
      },
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
