import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/data/food_categories_data.dart';
import 'package:gage_app/features/food/presentation/category_merchant_list_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class CategoryItem {
  final String id;
  final String name;
  final String image;
  final String description;
  final IconData? icon;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.image,
    this.description = '',
    this.icon,
  });
}

class AllCategoriesScreen extends StatefulWidget {
  final String title;
  final String searchHint;
  final String countLabel;
  final String subtitleAction;
  final List<CategoryItem>? customCategories;
  final void Function(String categoryName)? onSelectCategory;

  const AllCategoriesScreen({
    super.key,
    this.title = 'Semua Kategori Kuliner',
    this.searchHint = 'Cari kategori masakan (cth: Nasi, Mie, Kopi)...',
    this.countLabel = 'Kategori Kuliner Mitra',
    this.subtitleAction = 'Pilih untuk lihat resto',
    this.customCategories,
    this.onSelectCategory,
  });

  @override
  State<AllCategoriesScreen> createState() => _AllCategoriesScreenState();
}

class _AllCategoriesScreenState extends State<AllCategoriesScreen> {
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) setState(() => _isLoading = false);
  }

  List<CategoryItem> get _baseCategories {
    if (widget.customCategories != null && widget.customCategories!.isNotEmpty) {
      return widget.customCategories!;
    }
    return FoodCategoriesData.allCategories
        .map((c) => CategoryItem(
              id: c.id,
              name: c.name,
              image: c.image,
              description: c.description,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allList = _baseCategories;
    final categories = allList.where((c) {
      final q = _searchQuery.toLowerCase();
      return c.name.toLowerCase().contains(q) || c.description.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search input untuk filter kategori (Full Rounded modern)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.white38 : Colors.grey,
                ),
                prefixIcon: const Icon(Icons.search_rounded, color: GageTheme.primary, size: 22),
                filled: true,
                fillColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GageSkeletonBox(width: 140, height: 14),
                      GageSkeletonBox(width: 100, height: 12),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        ' ',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : GageTheme.textSecondary,
                        ),
                      ),
                      Text(
                        widget.subtitleAction,
                        style: const TextStyle(
                          fontSize: 11,
                          color: GageTheme.accentGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // Grid Kategori Full Screen (Persis Gambar 2 Food)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadCategories,
              color: GageTheme.primary,
              child: _isLoading
                  ? const SingleChildScrollView(
                      physics: AlwaysScrollableScrollPhysics(),
                      child: GageSkeletonCategoryGrid(itemCount: 16),
                    )
                  : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            if (widget.onSelectCategory != null) {
                              widget.onSelectCategory!(cat.name);
                              Navigator.pop(context, cat.name);
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => CategoryMerchantListScreen(
                                    categoryName: cat.name,
                                  ),
                                ),
                              );
                            }
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  border: Border.all(
                                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    cat.image,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => Container(
                                      color: isDark ? const Color(0xFF1E293B) : GageTheme.primaryLight,
                                      child: Center(
                                        child: Icon(
                                          cat.icon ?? Icons.category_rounded,
                                          color: GageTheme.primary,
                                          size: 26,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : GageTheme.textPrimary,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
