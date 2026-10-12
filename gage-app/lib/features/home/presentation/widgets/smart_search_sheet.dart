import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/food/presentation/tani_screen.dart';
import 'package:gage_app/features/babe/presentation/babe_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_hub_screen.dart';

enum SearchDomainCategory {
  all,
  service,
  food,
  shop,
  tani,
  babe,
}

class SearchSuggestionItem {
  final String id;
  final String title;
  final String subtitle;
  final SearchDomainCategory category;
  final String categoryLabel;
  final IconData icon;
  final Color themeColor;
  final List<String> keywords;
  final VoidCallback onSelect;

  const SearchSuggestionItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.categoryLabel,
    required this.icon,
    required this.themeColor,
    required this.keywords,
    required this.onSelect,
  });
}

class SmartSearchSheet extends StatefulWidget {
  const SmartSearchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const SmartSearchSheet(),
    );
  }

  @override
  State<SmartSearchSheet> createState() => _SmartSearchSheetState();
}

class _SmartSearchSheetState extends State<SmartSearchSheet> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  SearchDomainCategory _selectedCategory = SearchDomainCategory.all;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      setState(() {
        _query = _controller.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<SearchSuggestionItem> _getAllCatalog(BuildContext context) {
    return [
      // ── LAYANAN GAGE ──
      SearchSuggestionItem(
        id: 'svc-food',
        title: 'GAGE Food',
        subtitle: 'Pesan kuliner lezat, aneka dimsum & resto lokal Pracimantoro',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.restaurant_rounded,
        themeColor: GageTheme.primary,
        keywords: ['food', 'makan', 'kuliner', 'resto', 'jajan', 'lapar', 'dimsum', 'mie', 'seblak'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodExploreScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-ride',
        title: 'GAGE Ride',
        subtitle: 'Antar jemput motor cepat, aman & hemat untuk harian',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.two_wheeler_rounded,
        themeColor: const Color(0xFF0284C7),
        keywords: ['ride', 'ojek', 'motor', 'antar', 'jemput', 'stasiun', 'pasar', 'sekolah'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBookingScreen(initialTab: 'ride')));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-car',
        title: 'GAGE Car',
        subtitle: 'Pesan mobil nyaman untuk keluarga, rombongan & jarak jauh',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.directions_car_rounded,
        themeColor: const Color(0xFF2563EB),
        keywords: ['car', 'mobil', 'taksi', 'keluarga', 'rombongan', 'travel', 'sewa'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBookingScreen(initialTab: 'car')));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-shop',
        title: 'GAGE Shop',
        subtitle: 'Belanja sembako, minyak, sabun & kebutuhan toko harian',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.storefront_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['shop', 'sembako', 'toko', 'beras', 'minyak', 'gula', 'belanja', 'kelontong', 'mart'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-send',
        title: 'GAGE Send',
        subtitle: 'Kirim dokumen, paket & barang dagangan kilat langsung sampai',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.local_shipping_rounded,
        themeColor: const Color(0xFFD97706),
        keywords: ['send', 'kirim', 'paket', 'kurir', 'ekspedisi', 'antar barang', 'titip'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const SendBookingScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-tani',
        title: 'GAGE Tani',
        subtitle: 'Pupuk, bibit unggul, pakan ternak & hasil bumi petani lokal',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.agriculture_rounded,
        themeColor: const Color(0xFF16A34A),
        keywords: ['tani', 'pupuk', 'bibit', 'pakan', 'ternak', 'ayam', 'jagung', 'gabah', 'panen'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TaniScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-babe',
        title: 'GAGE BaBe',
        subtitle: 'Lapak terkurasi jual-beli barang bekas berkualitas di Wonogiri',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.recycling_rounded,
        themeColor: const Color(0xFF7C3AED),
        keywords: ['babe', 'barang bekas', 'preloved', 'second', 'seken', 'bekas', 'lapak', 'jual beli'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BabeScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'svc-cuan',
        title: 'GAGE Cuan',
        subtitle: 'Program kemitraan affiliate TikTok komisi 10% & bonus referral',
        category: SearchDomainCategory.service,
        categoryLabel: 'Layanan',
        icon: Icons.monetization_on_rounded,
        themeColor: const Color(0xFFE11D48),
        keywords: ['cuan', 'affiliate', 'komisi', 'referral', 'tiktok', 'bonus', 'penghasilan'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AffiliateHubScreen()));
        },
      ),

      // ── MAKANAN / KULINER (FOOD) ──
      SearchSuggestionItem(
        id: 'fd-dimsum-sewu',
        title: 'Dimsum Sewu Mas Dimsum',
        subtitle: 'Rp 1.000 • Aneka dimsum kukus & goreng topping udang, kepiting, keju',
        category: SearchDomainCategory.food,
        categoryLabel: 'GAGE Food',
        icon: Icons.restaurant_menu_rounded,
        themeColor: GageTheme.primary,
        keywords: ['dimsum', 'kukus', 'goreng', 'siomay', 'dimsum sewu', 'cemilan', 'sewu'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RestoDetailScreen(merchant: {
                'id': 'm-dimsum-sewu',
                'name': 'Dimsum Sewu Mas Dimsum, Pracimantoro',
                'category': 'Dimsum & Aneka Frozen Food Kukus/Goreng',
                'address': 'Jl. Raya Pracimantoro No. 12',
                'rating': 4.9,
              }),
            ),
          );
        },
      ),
      SearchSuggestionItem(
        id: 'fd-mie-ayam',
        title: 'Mie Ayam Pak Kumis',
        subtitle: 'Rp 10.000 • Mie ayam kuah kental gurih & bakso urat Pasar Pracimantoro',
        category: SearchDomainCategory.food,
        categoryLabel: 'GAGE Food',
        icon: Icons.ramen_dining_rounded,
        themeColor: GageTheme.primary,
        keywords: ['mie', 'mie ayam', 'bakso', 'urat', 'pak kumis', 'pasar', 'kuah'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RestoDetailScreen(merchant: {
                'id': 'mch-mie-01',
                'name': 'Mie Ayam Pak Kumis, Pracimantoro',
                'category': 'Mie & Bakso Urat Komplit',
                'address': 'Pasar Pracimantoro Kios No. 4',
                'rating': 4.8,
              }),
            ),
          );
        },
      ),
      SearchSuggestionItem(
        id: 'fd-seblak',
        title: 'Seblak Prasmanan Nyentrik',
        subtitle: 'Rp 12.000 • Seblak prasmanan bebas ambil topping level 1-5 pedas mantap',
        category: SearchDomainCategory.food,
        categoryLabel: 'GAGE Food',
        icon: Icons.soup_kitchen_rounded,
        themeColor: GageTheme.primary,
        keywords: ['seblak', 'prasmanan', 'pedas', 'nyentrik', 'level', 'kerupuk', 'cuanki'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RestoDetailScreen(merchant: {
                'id': 'mch-seblak-01',
                'name': 'Seblak Prasmanan Nyentrik Pracimantoro',
                'category': 'Seblak & Pedas Prasmanan',
                'address': 'Jl. Raya Pracimantoro - Giritontro',
                'rating': 4.9,
              }),
            ),
          );
        },
      ),
      SearchSuggestionItem(
        id: 'fd-roti-gembong',
        title: 'Roti Gembong Gedhe',
        subtitle: 'Rp 15.000 • Roti gembong lembut aneka isian cokelat, keju, tiramisu',
        category: SearchDomainCategory.food,
        categoryLabel: 'GAGE Food',
        icon: Icons.bakery_dining_rounded,
        themeColor: GageTheme.primary,
        keywords: ['roti', 'gembong', 'gedhe', 'manis', 'bakery', 'kue', 'cokelat', 'keju'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RestoDetailScreen(merchant: {
                'id': 'mch-roti-01',
                'name': 'Roti Gembong Gedhe, Pracimantoro',
                'category': 'Roti & Bakery, Jajanan Manis',
                'address': 'Kompleks Ruko Barat Pasar Pracimantoro',
                'rating': 4.9,
              }),
            ),
          );
        },
      ),
      SearchSuggestionItem(
        id: 'fd-ayam-geprek',
        title: 'Ayam Geprek Sambal Bawang Hot',
        subtitle: 'Rp 13.000 • Paket nasi + ayam krispi pedas cabai rawit asli',
        category: SearchDomainCategory.food,
        categoryLabel: 'GAGE Food',
        icon: Icons.lunch_dining_rounded,
        themeColor: GageTheme.primary,
        keywords: ['ayam', 'geprek', 'sambal bawang', 'pedas', 'krispi', 'nasi ayam'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodExploreScreen()));
        },
      ),

      // ── TOKO SEMBAKO (SHOP) ──
      SearchSuggestionItem(
        id: 'sp-beras-c4',
        title: 'Beras C4 Super Raja Delanggu (5 kg)',
        subtitle: 'Rp 68.000 • Beras putih pulen wangi pilihan keluarga • Toko Berkah Fajar',
        category: SearchDomainCategory.shop,
        categoryLabel: 'GAGE Shop',
        icon: Icons.shopping_bag_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['beras', 'c4', 'delanggu', 'sembako', 'nasi', 'pulen', '5kg'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'sp-minyak-goreng',
        title: 'Minyak Goreng Kita Pouch 1 Liter',
        subtitle: 'Rp 15.500 • Minyak goreng jernih hemat kemasan bantal • Toko Makmur Jaya',
        category: SearchDomainCategory.shop,
        categoryLabel: 'GAGE Shop',
        icon: Icons.water_drop_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['minyak', 'goreng', 'minyakita', '1 liter', 'sembako', 'dapur'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'sp-gula-pasir',
        title: 'Gula Pasir Gulaku Tebu Alami 1 kg',
        subtitle: 'Rp 17.500 • Gula murni kristal putih manis higienis • Toko Berkah Fajar',
        category: SearchDomainCategory.shop,
        categoryLabel: 'GAGE Shop',
        icon: Icons.kitchen_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['gula', 'gulaku', 'pasir', 'manis', 'tebu', '1kg', 'sembako'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'sp-telur-ayam',
        title: 'Telur Ayam Ras Segar Peternak 1 kg',
        subtitle: 'Rp 27.000 • Telur utuh segar baru datang tiap pagi • Toko Sumber Rejeki',
        category: SearchDomainCategory.shop,
        categoryLabel: 'GAGE Shop',
        icon: Icons.egg_rounded,
        themeColor: const Color(0xFF0D9488),
        keywords: ['telur', 'ayam', 'ras', 'kiloan', 'fresh', 'sarapan', 'sembako'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        },
      ),

      // ── PERTANIAN & HEWAN (TANI) ──
      SearchSuggestionItem(
        id: 'tn-pupuk-npk',
        title: 'Pupuk NPK Mutiara 16-16-16 (1 kg)',
        subtitle: 'Rp 18.000 • Nutrisi tanaman lengkap daun, bunga & buah • Kios Tani Makmur',
        category: SearchDomainCategory.tani,
        categoryLabel: 'GAGE Tani',
        icon: Icons.grass_rounded,
        themeColor: const Color(0xFF16A34A),
        keywords: ['pupuk', 'npk', 'mutiara', 'pertanian', 'kebun', 'tani', 'tanaman', '16-16-16'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TaniScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'tn-pakan-ayam',
        title: 'Pakan Ayam Pedaging Broiler BR1 (5 kg)',
        subtitle: 'Rp 49.000 • Pelet pakan bergizi tinggi starter pembesaran • Toko Pakan Subur',
        category: SearchDomainCategory.tani,
        categoryLabel: 'GAGE Tani',
        icon: Icons.pets_rounded,
        themeColor: const Color(0xFF16A34A),
        keywords: ['pakan', 'ayam', 'broiler', 'br1', 'ternak', 'pelet', 'unggas'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TaniScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'tn-bibit-jagung',
        title: 'Bibit Jagung Hibrida Pioneer P35 (1 kg)',
        subtitle: 'Rp 115.000 • Tahan kering, tongkol rapat dan bobot berat • Kios Tani Makmur',
        category: SearchDomainCategory.tani,
        categoryLabel: 'GAGE Tani',
        icon: Icons.eco_rounded,
        themeColor: const Color(0xFF16A34A),
        keywords: ['bibit', 'jagung', 'pioneer', 'hibrida', 'benih', 'panen', 'ladang'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const TaniScreen()));
        },
      ),

      // ── BARANG BEKAS (BABE) ──
      SearchSuggestionItem(
        id: 'bb-sepeda-gunung',
        title: 'Sepeda Gunung Polygon Bekas Mulus',
        subtitle: 'Rp 850.000 • Ban tebal, rem cakram aktif siap pakai • Pracimantoro',
        category: SearchDomainCategory.babe,
        categoryLabel: 'GAGE BaBe',
        icon: Icons.pedal_bike_rounded,
        themeColor: const Color(0xFF7C3AED),
        keywords: ['sepeda', 'polygon', 'gunung', 'babe', 'barang bekas', 'gowes', 'bekas', 'second'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BabeScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'bb-helm-bogo',
        title: 'Helm Bogo Retro Klasik Seken',
        subtitle: 'Rp 75.000 • Busa tebal wangi, kaca bogo cembung bening • Giritontro',
        category: SearchDomainCategory.babe,
        categoryLabel: 'GAGE BaBe',
        icon: Icons.sports_motorsports_rounded,
        themeColor: const Color(0xFF7C3AED),
        keywords: ['helm', 'bogo', 'retro', 'klasik', 'seken', 'bekas', 'motor'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BabeScreen()));
        },
      ),
      SearchSuggestionItem(
        id: 'bb-hp-second',
        title: 'HP Android Redmi 9A 3/32 Bekas Normal',
        subtitle: 'Rp 550.000 • Baterai awet, segel utuh kelengkapan fullset • Pracimantoro',
        category: SearchDomainCategory.babe,
        categoryLabel: 'GAGE BaBe',
        icon: Icons.smartphone_rounded,
        themeColor: const Color(0xFF7C3AED),
        keywords: ['hp', 'android', 'redmi', 'handphone', 'smartphone', 'bekas', 'second'],
        onSelect: () {
          Navigator.pop(context);
          Navigator.push(context, MaterialPageRoute(builder: (_) => const BabeScreen()));
        },
      ),
    ];
  }

  List<SearchSuggestionItem> _filterSuggestions(List<SearchSuggestionItem> all) {
    return all.where((item) {
      // 1. Cek Kategori Filter
      if (_selectedCategory != SearchDomainCategory.all && item.category != _selectedCategory) {
        return false;
      }
      // 2. Cek Query Kata Kunci
      if (_query.isEmpty) return true;

      final titleMatch = item.title.toLowerCase().contains(_query);
      final subtitleMatch = item.subtitle.toLowerCase().contains(_query);
      final keywordMatch = item.keywords.any((k) => k.toLowerCase().contains(_query) || _query.contains(k));
      return titleMatch || subtitleMatch || keywordMatch;
    }).toList();
  }

  void _applyQuickQuery(String text) {
    _controller.text = text;
    _controller.selection = TextSelection.fromPosition(TextPosition(offset: text.length));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allItems = _getAllCatalog(context);
    final filtered = _filterSuggestions(allItems);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // 1. Handle Drag Atas
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // 2. Smart Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isDark ? GageTheme.darkSurface : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.search_rounded,
                          color: GageTheme.primary,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            autofocus: true,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari makanan, toko, sembako, tani, ojek...',
                              hintStyle: TextStyle(
                                fontSize: 13,
                                color: isDark ? Colors.white38 : Colors.grey.shade500,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            color: isDark ? Colors.white54 : Colors.grey.shade600,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => _controller.clear(),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: GageTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          // 3. Tab Kategori Cepat (Filter Chips)
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildCategoryChip('Semua', SearchDomainCategory.all, isDark),
                _buildCategoryChip('Layanan', SearchDomainCategory.service, isDark),
                _buildCategoryChip('Kuliner (Food)', SearchDomainCategory.food, isDark),
                _buildCategoryChip('Sembako (Shop)', SearchDomainCategory.shop, isDark),
                _buildCategoryChip('Tani & Ternak', SearchDomainCategory.tani, isDark),
                _buildCategoryChip('BaBe (Bekas)', SearchDomainCategory.babe, isDark),
              ],
            ),
          ),

          const Divider(height: 16, thickness: 1),

          // 4. Konten Hasil / Saran Algoritma
          Expanded(
            child: _query.isEmpty
                ? _buildEmptyStateDiscovery(isDark)
                : _buildSearchResultsList(filtered, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, SearchDomainCategory cat, bool isDark) {
    final isSelected = _selectedCategory == cat;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
        ),
        selectedColor: GageTheme.primary,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.grey.shade100,
        side: BorderSide(
          color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onSelected: (val) {
          if (val) setState(() => _selectedCategory = cat);
        },
      ),
    );
  }

  Widget _buildEmptyStateDiscovery(bool isDark) {
    final trendingTags = [
      'Dimsum Sewu',
      'Beras C4 5kg',
      'Mie Ayam Pak Kumis',
      'Pupuk NPK Mutiara',
      'GAGE Ride Ojek',
      'Seblak Prasmanan',
      'Minyak Goreng',
      'Pakan Ayam BR1',
      'Helm Bogo Seken',
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up_rounded, color: GageTheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Paling Sering Dicari di Pracimantoro',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: trendingTags.map((tag) {
            return ActionChip(
              avatar: const Icon(Icons.search_rounded, size: 14, color: GageTheme.primary),
              label: Text(tag),
              labelStyle: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              backgroundColor: isDark ? GageTheme.darkSurface : Colors.grey.shade100,
              side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => _applyQuickQuery(tag),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.explore_rounded, color: Color(0xFF0284C7), size: 20),
            const SizedBox(width: 8),
            Text(
              'Pintasan Kategori Cepat',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildQuickShortcutTile(
          icon: Icons.restaurant_rounded,
          color: GageTheme.primary,
          title: 'Kuliner & Warung Makan (GAGE Food)',
          subtitle: 'Pesan antar aneka makanan & jajanan favorit',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodExploreScreen()));
          },
          isDark: isDark,
        ),
        _buildQuickShortcutTile(
          icon: Icons.storefront_rounded,
          color: const Color(0xFF0D9488),
          title: 'Toko Sembako & Kelontong (GAGE Shop)',
          subtitle: 'Beras, minyak, sabun & belanja bulanan',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
          },
          isDark: isDark,
        ),
        _buildQuickShortcutTile(
          icon: Icons.agriculture_rounded,
          color: const Color(0xFF16A34A),
          title: 'Kebutuhan Tani & Pakan (GAGE Tani)',
          subtitle: 'Pupuk resmi, bibit tanaman & pakan ternak warga',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const TaniScreen()));
          },
          isDark: isDark,
        ),
        _buildQuickShortcutTile(
          icon: Icons.recycling_rounded,
          color: const Color(0xFF7C3AED),
          title: 'Jual Beli Barang Bekas (GAGE BaBe)',
          subtitle: 'Lapak terverifikasi second berkualitas lokal',
          onTap: () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const BabeScreen()));
          },
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildQuickShortcutTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: ListTile(
        dense: true,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : Colors.black87),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded, size: 14, color: isDark ? Colors.white38 : Colors.grey.shade400),
        onTap: onTap,
      ),
    );
  }

  Widget _buildSearchResultsList(List<SearchSuggestionItem> items, bool isDark) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.search_off_rounded, size: 48, color: isDark ? Colors.white30 : Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                'Hasil tidak ditemukan untuk "$_query"',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white70 : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Coba gunakan kata kunci lain seperti "dimsum", "beras", "ojek", "pupuk", atau "helm".',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (ctx, index) {
        final item = items[index];
        return InkWell(
          onTap: item.onSelect,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? GageTheme.darkSurface : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Icon Avatar
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: item.themeColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(item.icon, color: item.themeColor, size: 22),
                ),
                const SizedBox(width: 12),

                // Title + Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: item.themeColor.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.categoryLabel,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: item.themeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: isDark ? Colors.white38 : Colors.grey.shade400,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
