import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/data/food_categories_data.dart';
import 'package:gage_app/features/food/presentation/category_merchant_list_screen.dart';

class AllCategoriesScreen extends StatefulWidget {
  const AllCategoriesScreen({super.key});

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final categories = FoodCategoriesData.allCategories.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Semua Kategori Kuliner',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search input untuk filter kategori
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari kategori masakan (cth: Nasi, Mie, Kopi)...',
                hintStyle: const TextStyle(fontSize: 12.5, color: Colors.grey),
                prefixIcon: const Icon(Icons.search_rounded, color: GageTheme.primary, size: 22),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${categories.length} Kategori Kuliner Mitra',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: GageTheme.textSecondary),
                ),
                const Text(
                  'Pilih untuk lihat resto',
                  style: TextStyle(fontSize: 11, color: GageTheme.accentGreen, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Grid Kategori Full Screen
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 18,
                crossAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
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
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200, width: 1.2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
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
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
