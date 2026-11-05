import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_cart_sheet.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_merchant_card.dart';

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
  String _rankingSwitch = 'Rekomendasi'; // 'Rekomendasi', 'Terlaris', 'Toko Terdekat'
  String _searchQuery = '';
  bool _isLoading = true;
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteStoreIds = {'build-sumber-bangunan'};

  final List<Map<String, dynamic>> _categoriesData = [
    {'name': 'Semen & Pasir', 'image': 'assets/images/prod_beras.png', 'icon': Icons.foundation_rounded},
    {'name': 'Cat & Thinner', 'image': 'assets/images/hero_promo_1.png', 'icon': Icons.format_paint_rounded},
    {'name': 'Besi & Baja', 'image': 'assets/images/prod_traktor.png', 'icon': Icons.hardware_rounded},
    {'name': 'Pipa & Keran', 'image': 'assets/images/hero_promo_2.png', 'icon': Icons.plumbing_rounded},
    {'name': 'Alat Tukang', 'image': 'assets/images/prod_traktor.png', 'icon': Icons.construction_rounded},
    {'name': 'Keramik Lantai', 'image': 'assets/images/hero_promo_1.png', 'icon': Icons.grid_view_rounded},
    {'name': 'Kayu & Triplek', 'image': 'assets/images/hero_header_clean_16x9.png', 'icon': Icons.carpenter_rounded},
    {'name': 'Kelistrikan', 'image': 'assets/images/banner_gagepay_promo.png', 'icon': Icons.electrical_services_rounded},
    {'name': 'Atap & Genteng', 'image': 'assets/images/babe_hero_banner.png', 'icon': Icons.roofing_rounded},
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
    final filtered = _buildStores.where((s) {
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

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

                          const SizedBox(height: 14),

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
                GageCartSheet.show(context);
              },
              actionIcon: Icons.shopping_bag_outlined,
              actionBadgeCount: cart.items.length,
              searchHint: 'Cari semen, cat, besi, alat bangunan...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.construction_rounded,
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
                              cat['icon'] as IconData? ?? Icons.construction_rounded,
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
      ],
    );
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

  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeId = store['id'] as String;
    String? tier;
    if (storeId == 'build-sumber-bangunan') {
      tier = 'exclusive';
    } else if (storeId == 'build-mega-jaya' || storeId == 'build-griya-indah') {
      tier = 'star';
    }

    final rating = (store['rating'] is num)
        ? (store['rating'] as num).toDouble()
        : double.tryParse(store['rating']?.toString() ?? '') ?? 4.9;

    return GageMerchantCard(
      id: storeId,
      name: store['name'] ?? '',
      category: store['category'] ?? 'Bahan Bangunan & Material',
      rating: rating,
      ratingCount: (store['ratingCount'] ?? '50+').toString(),
      distance: (store['distance'] ?? '1.0 km').toString(),
      eta: (store['eta'] ?? '15-20 min').toString(),
      image: (store['image'] ?? 'assets/icons/ic_build.png').toString(),
      tier: tier,
      campaignBadge: tier == 'exclusive' ? 'PROMO PROYEK' : null,
      promoBadges: const ['Diskon 10%', 'Diskon Ongkir'],
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
