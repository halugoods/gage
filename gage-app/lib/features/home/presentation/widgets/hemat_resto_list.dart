import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

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
              Column(
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
                  ),
                ],
              ),
              TextButton(
                onPressed: () {},
                child: const Text('Lihat Semua', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 8),

        if (isLoading)
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Center(child: CircularProgressIndicator(color: GageTheme.primary)),
          )
        else
          SizedBox(
            height: 230,
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
                  width: 175,
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
                              height: 105,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                height: 105,
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.restaurant, color: Colors.grey),
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.all(10.0),
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
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: GageTheme.accentYellow, size: 15),
                                    const SizedBox(width: 2),
                                    const Text('4.9', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    const SizedBox(width: 6),
                                    const Text('•', style: TextStyle(color: Colors.grey, fontSize: 11)),
                                    const SizedBox(width: 6),
                                    const Icon(Icons.location_on, color: GageTheme.primary, size: 12),
                                    const Text('1.8 km', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
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
