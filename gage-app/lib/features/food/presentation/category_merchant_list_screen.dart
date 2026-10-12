import 'package:flutter/material.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

class CategoryMerchantListScreen extends StatefulWidget {
  final String categoryName;
  final String? filterMode; // 'nearest', 'cheap_ongkir', 'budget', etc.

  const CategoryMerchantListScreen({
    super.key,
    required this.categoryName,
    this.filterMode,
  });

  @override
  State<CategoryMerchantListScreen> createState() => _CategoryMerchantListScreenState();
}

class _CategoryMerchantListScreenState extends State<CategoryMerchantListScreen> {
  String _searchQuery = '';
  String _activeChip = 'Semua';
  List<Map<String, dynamic>> _allMerchants = [];
  bool _isLoading = true;

  final List<String> _chips = [
    'Semua',
    'Terdekat (< 2 km)',
    'Rating 4.8+',
    'Diskon Makanan',
    'Ongkir Hemat',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.filterMode == 'nearest') {
      _activeChip = 'Terdekat (< 2 km)';
    } else if (widget.filterMode == 'cheap_ongkir') {
      _activeChip = 'Ongkir Hemat';
    } else if (widget.filterMode == 'budget') {
      _activeChip = 'Diskon Makanan';
    }
    _loadMerchants();
  }

  Future<void> _loadMerchants() async {
    final list = await GageApiClient.getMerchants();

    // Default fallback directory merchant Pracimantoro
    final fallback = [
      {
        'id': 'mch-rc-01',
        'name': 'Rocket Chicken Sambiroto, Pracimantoro',
        'category': 'Cepat saji, Ayam & Bebek, Aneka Nasi',
        'rating': 5.0,
        'ratingCount': '120+',
        'distance': '1.2 km',
        'distanceKm': 1.2,
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon s.d. 10rb',
        'image': 'assets/images/resto_rocket_chicken.png',
      },
      {
        'id': 'mch-dimsum-01',
        'name': 'Dimsum Sewu, Alfamidi Pracimantoro',
        'category': 'Jajanan & Dimsum, Camilan & Oleh-Oleh',
        'rating': 4.9,
        'ratingCount': '85',
        'distance': '1.8 km',
        'distanceKm': 1.8,
        'eta': '20-25 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 50% Pengguna Baru',
        'image': 'assets/images/resto_dimsum_sewu.png',
      },
      {
        'id': 'mch-mie-01',
        'name': 'Mie Ayam Pak Kumis, Pracimantoro',
        'category': 'Mie & Bakso, Soto & Sop',
        'rating': 4.8,
        'ratingCount': '64',
        'distance': '2.1 km',
        'distanceKm': 2.1,
        'eta': '20-30 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Voucher Subsidi Ongkir',
        'image': 'assets/images/resto_mie_ayam.png',
      },
      {
        'id': 'mch-seblak-01',
        'name': 'Seblak Prasmanan Nyentrik Pracimantoro',
        'category': 'Seblak & Pedas, Jajanan & Dimsum',
        'rating': 4.9,
        'ratingCount': '95',
        'distance': '1.5 km',
        'distanceKm': 1.5,
        'eta': '20-25 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon Makanan 5rb',
        'image': 'assets/images/resto_seblak.png',
      },
      {
        'id': 'mch-roti-01',
        'name': 'Roti Gembong Gedhe, Pracimantoro',
        'category': 'Roti & Bakery, Kopi & Teh, Dessert & Es Krim',
        'rating': 4.9,
        'ratingCount': '42',
        'distance': '2.5 km',
        'distanceKm': 2.5,
        'eta': '25-35 min',
        'ongkir': 'Rp 5.000',
        'diskonBadge': 'Diskon Makanan 5rb',
        'image': 'assets/images/resto_roti_gembong.png',
      },
      {
        'id': 'mch-sate-01',
        'name': 'Warung Sate Kambing & Ayam Pak Narto',
        'category': 'Sate & Bakaran, Aneka Nasi, Soto & Sop',
        'rating': 4.8,
        'ratingCount': '58',
        'distance': '1.4 km',
        'distanceKm': 1.4,
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 8rb Min. 40rb',
        'image': 'assets/images/cat_sate.png',
      },
      {
        'id': 'mch-martabak-01',
        'name': 'Martabak Bangka 99 Alun-Alun Pracimantoro',
        'category': 'Martabak, Dessert & Es Krim, Camilan & Oleh-Oleh',
        'rating': 4.9,
        'ratingCount': '77',
        'distance': '1.9 km',
        'distanceKm': 1.9,
        'eta': '20-30 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon 5rb',
        'image': 'assets/images/cat_martabak.png',
      },
      {
        'id': 'mch-kopi-01',
        'name': 'Kopi Janji Warga & Minuman Segar',
        'category': 'Kopi & Teh, Minuman Segar, Roti & Bakery',
        'rating': 4.8,
        'ratingCount': '39',
        'distance': '1.1 km',
        'distanceKm': 1.1,
        'eta': '15-20 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Diskon s.d. 6rb',
        'image': 'assets/images/cat_kopi.png',
      },
      {
        'id': 'mch-soto-01',
        'name': 'Soto Seger Mbok Giyem Tubokarto',
        'category': 'Soto & Sop, Aneka Nasi, Sarapan Pagi',
        'rating': 4.9,
        'ratingCount': '88',
        'distance': '0.9 km',
        'distanceKm': 0.9,
        'eta': '15-25 min',
        'ongkir': 'Rp 4.000',
        'diskonBadge': 'Gratis Ongkir GAGE Plus',
        'image': 'assets/images/cat_nasi.png',
      },
      {
        'id': 'mch-seafood-01',
        'name': 'Pondok Ikan Bakar & Seafood Sadeng',
        'category': 'Seafood & Ikan, Aneka Nasi, Sate & Bakaran',
        'rating': 4.7,
        'ratingCount': '51',
        'distance': '2.8 km',
        'distanceKm': 2.8,
        'eta': '30-40 min',
        'ongkir': 'Rp 6.000',
        'diskonBadge': 'Diskon 10rb Min. 60rb',
        'image': 'assets/images/dish_bakso_urat.png',
      },
    ];

    if (!mounted) return;
    setState(() {
      _allMerchants = list.isNotEmpty ? list : fallback;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredList() {
    final catName = widget.categoryName.toLowerCase();
    final isSpecialFilter = widget.filterMode != null;

    var list = _allMerchants.where((m) {
      final name = (m['name'] ?? '').toString().toLowerCase();
      final cat = (m['category'] ?? '').toString().toLowerCase();
      final q = _searchQuery.toLowerCase();

      final matchesSearch = q.isEmpty || name.contains(q) || cat.contains(q);

      // Kategori check
      bool matchesCategory = true;
      if (!isSpecialFilter) {
        // Normal category filter
        matchesCategory = name.contains(catName) || cat.contains(catName);
        // Fallback loose keyword matching jika e.g. "mie & bakso" -> "mie" atau "bakso"
        if (!matchesCategory) {
          final words = catName.split(RegExp(r'[ &,/]+')).where((w) => w.length > 2);
          for (var w in words) {
            if (name.contains(w) || cat.contains(w)) {
              matchesCategory = true;
              break;
            }
          }
        }
      }

      return matchesSearch && matchesCategory;
    }).toList();

    // Terapkan chip filter
    if (_activeChip == 'Terdekat (< 2 km)') {
      list = list.where((m) {
        final dist = (m['distanceKm'] ?? 1.8) as num;
        return dist <= 2.0;
      }).toList();
      list.sort((a, b) => ((a['distanceKm'] ?? 1.8) as num).compareTo((b['distanceKm'] ?? 1.8) as num));
    } else if (_activeChip == 'Rating 4.8+') {
      list = list.where((m) => ((m['rating'] ?? 5.0) as num) >= 4.8).toList();
      list.sort((a, b) => ((b['rating'] ?? 5.0) as num).compareTo((a['rating'] ?? 5.0) as num));
    } else if (_activeChip == 'Diskon Makanan') {
      list = list.where((m) => (m['diskonBadge'] ?? '').toString().toLowerCase().contains('diskon')).toList();
    } else if (_activeChip == 'Ongkir Hemat') {
      list.sort((a, b) => (a['ongkir'] ?? '').toString().compareTo((b['ongkir'] ?? '').toString()));
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _getFilteredList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.categoryName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const Text(
              'Pracimantoro, Wonogiri',
              style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Search Bar dalam Kategori
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Cari resto atau menu di ${widget.categoryName}...',
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

          // Horizontal Filter Chips
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            height: 46,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _chips.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 8),
              itemBuilder: (ctx, i) {
                final chip = _chips[i];
                final isSel = _activeChip == chip;
                return ChoiceChip(
                  label: Text(chip),
                  selected: isSel,
                  onSelected: (_) => setState(() => _activeChip = chip),
                  selectedColor: GageTheme.primaryLight,
                  backgroundColor: Colors.grey.shade50,
                  side: BorderSide(color: isSel ? GageTheme.primary : Colors.grey.shade300),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                    color: isSel ? GageTheme.primary : GageTheme.textPrimary,
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // Merchant List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: GageTheme.primary))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.storefront_outlined, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Belum ada resto untuk kategori "${widget.categoryName}"',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Coba ganti filter atau cari kata kunci lain.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filtered.length,
                        itemBuilder: (ctx, idx) {
                          final m = filtered[idx];
                          return InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => RestoDetailScreen(merchant: m),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 12),
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
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 76,
                                      height: 76,
                                      child: Image.asset(
                                        m['image'] ?? 'assets/images/resto_dimsum_sewu.png',
                                        fit: BoxFit.cover,
                                        errorBuilder: (c, e, s) => Container(
                                          color: GageTheme.primaryLight,
                                          child: const Icon(Icons.restaurant, color: GageTheme.primary),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          m['name'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
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
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.motorcycle_rounded, color: GageTheme.accentGreen, size: 14),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Ongkir ${m['ongkir'] ?? 'Rp 4.000'}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                color: GageTheme.accentGreen,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '• ${m['distance'] ?? '1.8 km'}',
                                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                            ),
                                          ],
                                        ),
                                        if (m['diskonBadge'] != null) ...[
                                          const SizedBox(height: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red.shade50,
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              m['diskonBadge'],
                                              style: TextStyle(
                                                color: Colors.red.shade700,
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
