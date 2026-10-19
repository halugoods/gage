import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class HematRestoList extends StatelessWidget {
  final List<Map<String, dynamic>> merchants;
  final bool isLoading;

  const HematRestoList({
    super.key,
    required this.merchants,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Paket Hemat 20 Ribuan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Resto pilihan terdekat & hemat ongkir',
                      style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (ctx) => const FoodExploreScreen(),
                    ),
                  );
                },
                child: const Text('Lihat Semua', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (isLoading)
          SizedBox(
            height: 248,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 3,
              itemBuilder: (ctx, idx) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return Container(
                  width: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: GageShimmer(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GageSkeletonBox(width: double.infinity, height: 110, borderRadius: BorderRadius.all(Radius.circular(12))),
                          SizedBox(height: 10),
                          GageSkeletonBox(width: 120, height: 14),
                          SizedBox(height: 6),
                          GageSkeletonBox(width: 80, height: 10),
                          SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GageSkeletonBox(width: 45, height: 14),
                              GageSkeletonBox(width: 50, height: 14),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          )
        else
          SizedBox(
            height: 248,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: merchants.length,
              itemBuilder: (ctx, idx) {
                final m = merchants[idx];
                final id = m['id'] ?? '';
                final name = m['name'] ?? 'Resto Mitra';
                final category = m['category'] ?? 'Kuliner';
                final address = m['address'] ?? 'Kecamatan';
                String imageAsset = 'assets/images/resto_dimsum_sewu.png';
                if (id == 'm-mie-kumis') imageAsset = 'assets/images/resto_mie_ayam.png';

                return Container(
                  width: 180,
                  margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => RestoDetailScreen(merchant: m),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Resto Image
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Image.asset(
                              imageAsset,
                              height: 100,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 100,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.restaurant, color: Colors.grey),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '$category • $address',
                                  style: const TextStyle(color: GageTheme.textSecondary, fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: GageTheme.accentYellow, size: 14),
                                    const SizedBox(width: 2),
                                    const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    const SizedBox(width: 4),
                                    const Text('•', style: TextStyle(color: Colors.grey, fontSize: 10)),
                                    const SizedBox(width: 4),
                                    const Icon(Icons.location_on, color: GageTheme.primary, size: 12),
                                    const Flexible(
                                      child: Text(
                                        '1.8 km',
                                        style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: GageTheme.primaryLight,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'TERDEKAT • 1.8 KM',
                                    style: TextStyle(
                                      color: GageTheme.primary,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
