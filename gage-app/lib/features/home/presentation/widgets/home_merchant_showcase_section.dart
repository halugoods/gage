import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_merchant_slider_card.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/features/food/presentation/farm_screen.dart';
import 'package:gage_app/features/food/presentation/build_screen.dart';

/// 4 Section Layanan Utama Beranda GAGE:
/// 1. Resto Kuliner Pilihan
/// 2. Toko Sembako & Kelontong Pilihan
/// 3. Kios Tani & Ternak Pilihan
/// 4. Toko Bahan Bangunan Pilihan
///
/// Format penamaan bersih tanpa embel-embel brand, mendukung level merchant:
/// - 👑 Exclusive Merchant (Tier berbayar / Ads)
/// - ⭐ Star Merchant (Tier performa penjualan)
/// - Basic (Tanpa badge level)
class HomeMerchantShowcaseSection extends StatelessWidget {
  final List<Map<String, dynamic>> foodMerchants;
  final bool isLoading;

  const HomeMerchantShowcaseSection({
    super.key,
    required this.foodMerchants,
    this.isLoading = false,
  });

  // Data mitra Shop terverifikasi
  static final List<Map<String, dynamic>> _shopStores = [
    {
      'id': 'shop-berkah-fajar',
      'name': 'Toko Sembako Berkah Fajar',
      'category': 'Sembako, Beras & Minyak Goreng',
      'rating': 4.9,
      'ratingCount': '110+',
      'distance': '0.7 km',
      'eta': '15-20 min',
      'image': 'assets/images/hero_banner_1.png',
      'tier': 'star',
      'campaignBadge': 'PROMO SEMBAKO',
      'promoBadges': ['Diskon 25%', 'Diskon Ongkir'],
    },
    {
      'id': 'shop-lapak-siti',
      'name': 'Lapak Segar Sayur Mbak Siti',
      'category': 'Sayur Mayur & Bumbu Dapur Segar',
      'rating': 4.8,
      'ratingCount': '85+',
      'distance': '1.1 km',
      'eta': '15-25 min',
      'image': 'assets/images/hero_promo_1.png',
      'tier': null, // Basic tanpa badge
      'promoBadges': ['Diskon 10%', 'Diskon Ongkir'],
    },
    {
      'id': 'shop-telur-jaya',
      'name': 'Agen Telur & Sembako Jaya',
      'category': 'Telur Ayam Ras, Gula Pasir & Tepung',
      'rating': 4.9,
      'ratingCount': '95+',
      'distance': '1.3 km',
      'eta': '20-30 min',
      'image': 'assets/images/prod_telur.png',
      'tier': 'star',
      'promoBadges': ['Diskon 15%', 'Diskon Ongkir'],
    },
  ];

  // Data mitra Farm (Pertanian & Peternakan)
  static final List<Map<String, dynamic>> _farmStores = [
    {
      'id': 'farm-kios-subur',
      'name': 'Kios Tani Subur Makmur',
      'category': 'Pupuk NPK & Urea, Benih Padi & Sayur',
      'rating': 4.9,
      'ratingCount': '140+',
      'distance': '0.8 km',
      'eta': '15-20 min',
      'image': 'assets/images/prod_pupuk.png',
      'tier': 'exclusive',
      'campaignBadge': 'SUBSIDI TANI',
      'promoBadges': ['Diskon 20%', 'Diskon Ongkir'],
    },
    {
      'id': 'farm-sentra-mandiri',
      'name': 'Sentra Konsentrat Ternak Mandiri',
      'category': 'Pakan Sapi, Kambing & Vitamin Hewan',
      'rating': 4.9,
      'ratingCount': '92+',
      'distance': '0.9 km',
      'eta': '15-20 min',
      'image': 'assets/images/prod_pakan.png',
      'tier': 'star',
      'promoBadges': ['Diskon 15%', 'Diskon Ongkir'],
    },
    {
      'id': 'farm-tani-lestari',
      'name': 'Kios Pupuk & Benih Tani Lestari',
      'category': 'Pupuk Organik, Obat Hama & Tangki Sprayer',
      'rating': 4.8,
      'ratingCount': '78+',
      'distance': '1.4 km',
      'eta': '20-25 min',
      'image': 'assets/images/prod_benih.png',
      'tier': null, // Basic tanpa badge
      'promoBadges': ['Diskon 10%', 'Diskon Ongkir'],
    },
  ];

  // Data mitra Build (Material & Pertukangan)
  static final List<Map<String, dynamic>> _buildStores = [
    {
      'id': 'build-tb-bangkit',
      'name': 'TB Pracimantoro Bangkit',
      'category': 'Semen Tiga Roda, Besi Beton & Pasir',
      'rating': 4.9,
      'ratingCount': '125+',
      'distance': '1.0 km',
      'eta': '20-30 min',
      'image': 'assets/icons/ic_build.png',
      'tier': 'exclusive',
      'isSponsored': true,
      'campaignBadge': 'PROMO PROYEK',
      'promoBadges': ['Diskon 15%', 'Diskon Ongkir'],
    },
    {
      'id': 'build-cat-indah',
      'name': 'Toko Cat Indah Bangunan',
      'category': 'Cat Tembok Dulux/Avian, Kuas & Plamir',
      'rating': 4.8,
      'ratingCount': '88+',
      'distance': '0.6 km',
      'eta': '10-15 min',
      'image': 'assets/icons/ic_build.png',
      'tier': 'star',
      'promoBadges': ['Diskon 20%', 'Diskon Ongkir'],
    },
    {
      'id': 'build-ud-besi',
      'name': 'UD Besi & Alat Pertukangan Jaya',
      'category': 'Baja Ringan, Seng Gelombang & Paku',
      'rating': 4.8,
      'ratingCount': '64+',
      'distance': '1.8 km',
      'eta': '20-30 min',
      'image': 'assets/icons/ic_build.png',
      'tier': null, // Basic tanpa badge
      'promoBadges': ['Diskon 10%', 'Diskon Ongkir'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildSkeletonLoader(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. SECTION 1: Resto Kuliner Pilihan
        _buildSectionHeader(
          context: context,
          icon: Icons.restaurant_rounded,
          iconColor: const Color(0xFFE52320),
          title: 'Resto Kuliner Pilihan',
          subtitle: 'Aneka menu lezat siap antar dari resto favorit',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
            );
          },
        ),
        _buildFoodList(context),

        const SizedBox(height: 16),

        // 2. SECTION 2: Toko Sembako & Kelontong Pilihan
        _buildSectionHeader(
          context: context,
          icon: Icons.shopping_basket_rounded,
          iconColor: const Color(0xFF0284C7),
          title: 'Toko Sembako & Kelontong Pilihan',
          subtitle: 'Kebutuhan harian, beras, minyak & bumbu dapur',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const ShopScreen()),
            );
          },
        ),
        _buildShopList(context),

        const SizedBox(height: 16),

        // 3. SECTION 3: Kios Tani & Ternak Pilihan
        _buildSectionHeader(
          context: context,
          icon: Icons.eco_rounded,
          iconColor: const Color(0xFF16A34A),
          title: 'Kios Tani & Ternak Pilihan',
          subtitle: 'Pupuk, benih unggul, pakan sapi & konsentrat',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const FarmScreen()),
            );
          },
        ),
        _buildFarmList(context),

        const SizedBox(height: 16),

        // 4. SECTION 4: Toko Bahan Bangunan Pilihan
        _buildSectionHeader(
          context: context,
          icon: Icons.construction_rounded,
          iconColor: const Color(0xFFD97706),
          title: 'Toko Bahan Bangunan Pilihan',
          subtitle: 'Semen, cat, besi beton & alat pertukangan',
          onSeeAll: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const BuildScreen()),
            );
          },
        ),
        _buildBuildList(context),
      ],
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onSeeAll,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : GageTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
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
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSeeAll,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Lihat Semua',
                  style: TextStyle(
                    color: GageTheme.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                SizedBox(width: 2),
                Icon(Icons.arrow_forward_ios_rounded, size: 10, color: GageTheme.primary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. Food Horizontal Slider (Kanan-Kiri)
  Widget _buildFoodList(BuildContext context) {
    final items = foodMerchants.take(4).toList();
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final m = items[idx];
          final id = (m['id'] ?? '').toString();
          String? tier;
          if (id.contains('rc')) {
            tier = 'exclusive';
          } else if (id.contains('dimsum') || id.contains('seblak')) {
            tier = 'star';
          }

          final rating = (m['rating'] is num)
              ? (m['rating'] as num).toDouble()
              : double.tryParse(m['rating']?.toString() ?? '') ?? 4.9;

          return GageMerchantSliderCard(
            id: id,
            name: (m['name'] ?? 'Resto Mitra').toString(),
            category: (m['category'] ?? 'Kuliner').toString(),
            rating: rating,
            ratingCount: (m['ratingCount'] ?? '50+').toString(),
            distance: (m['distance'] ?? '1.2 km').toString(),
            eta: (m['eta'] ?? '20-30 min').toString(),
            image: (m['image'] ?? 'assets/images/resto_dimsum_sewu.png').toString(),
            tier: tier,
            isSponsored: tier == 'exclusive',
            campaignBadge: tier == 'exclusive' ? '11.11 RAME RAME' : null,
            promoBadges: const ['Diskon 50%', 'Diskon Ongkir'],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => RestoDetailScreen(merchant: m),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 2. Shop Horizontal Slider (Kanan-Kiri)
  Widget _buildShopList(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _shopStores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final s = _shopStores[idx];
          final id = s['id'] as String;
          return GageMerchantSliderCard(
            id: id,
            name: s['name'] as String,
            category: s['category'] as String,
            rating: (s['rating'] as num).toDouble(),
            ratingCount: s['ratingCount'] as String,
            distance: s['distance'] as String,
            eta: s['eta'] as String,
            image: s['image'] as String,
            tier: s['tier'] as String?,
            campaignBadge: s['campaignBadge'] as String?,
            promoBadges: (s['promoBadges'] as List).cast<String>(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ShopStoreDetailScreen(store: s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 3. Farm Horizontal Slider (Kanan-Kiri)
  Widget _buildFarmList(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _farmStores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final s = _farmStores[idx];
          final id = s['id'] as String;
          return GageMerchantSliderCard(
            id: id,
            name: s['name'] as String,
            category: s['category'] as String,
            rating: (s['rating'] as num).toDouble(),
            ratingCount: s['ratingCount'] as String,
            distance: s['distance'] as String,
            eta: s['eta'] as String,
            image: s['image'] as String,
            tier: s['tier'] as String?,
            campaignBadge: s['campaignBadge'] as String?,
            promoBadges: (s['promoBadges'] as List).cast<String>(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ShopStoreDetailScreen(store: s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // 4. Build Horizontal Slider (Kanan-Kiri)
  Widget _buildBuildList(BuildContext context) {
    return SizedBox(
      height: 236,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: _buildStores.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (ctx, idx) {
          final s = _buildStores[idx];
          final id = s['id'] as String;
          return GageMerchantSliderCard(
            id: id,
            name: s['name'] as String,
            category: s['category'] as String,
            rating: (s['rating'] as num).toDouble(),
            ratingCount: s['ratingCount'] as String,
            distance: s['distance'] as String,
            eta: s['eta'] as String,
            image: s['image'] as String,
            tier: s['tier'] as String?,
            isSponsored: s['isSponsored'] == true,
            campaignBadge: s['campaignBadge'] as String?,
            promoBadges: (s['promoBadges'] as List).cast<String>(),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (c) => ShopStoreDetailScreen(store: s),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSkeletonLoader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: List.generate(
          3,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GageShimmer(
              child: Container(
                height: 110,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
