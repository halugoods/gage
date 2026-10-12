import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

class FavoriteRestoScreen extends StatefulWidget {
  const FavoriteRestoScreen({super.key});

  @override
  State<FavoriteRestoScreen> createState() => _FavoriteRestoScreenState();
}

class _FavoriteRestoScreenState extends State<FavoriteRestoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _favoriteRestos = [
    {
      'id': 'mch-dimsum-01',
      'name': 'Dimsum Sewu, Alfamidi Pracimantoro',
      'category': 'Jajanan & Dimsum, Mentai',
      'rating': 4.9,
      'ratingCount': '85',
      'distance': '1.8 km',
      'eta': '20-25 min',
      'ongkir': 'Rp 4.000',
      'diskonBadge': 'Diskon 50% Pengguna Baru',
      'image': 'assets/images/resto_dimsum_sewu.png',
      'address': 'Depan Alfamidi, Jl. Raya Pracimantoro',
    },
    {
      'id': 'mch-rc-01',
      'name': 'Rocket Chicken Sambiroto, Pracimantoro',
      'category': 'Cepat saji, Fried Chicken & Nasi',
      'rating': 5.0,
      'ratingCount': '120+',
      'distance': '1.2 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 4.000',
      'diskonBadge': 'Diskon s.d. 10rb',
      'image': 'assets/images/resto_rocket_chicken.png',
      'address': 'Sambiroto, Pracimantoro, Wonogiri',
    },
    {
      'id': 'mch-mie-01',
      'name': 'Mie Ayam Pak Kumis, Pracimantoro',
      'category': 'Mie & Bakso Urat Komplit',
      'rating': 4.8,
      'ratingCount': '64',
      'distance': '2.1 km',
      'eta': '20-30 min',
      'ongkir': 'Rp 5.000',
      'diskonBadge': 'Promo Ongkir Hemat',
      'image': 'assets/images/resto_mie_ayam.png',
      'address': 'Jl. Gununggajah, Pracimantoro',
    },
  ];

  final List<Map<String, dynamic>> _favoriteDishes = [
    {
      'name': 'Dimsum Mozzarella Mentai Bakar',
      'resto': 'Dimsum Sewu Pracimantoro',
      'restoId': 'mch-dimsum-01',
      'price': 'Rp 14.000',
      'image': 'assets/images/dish_dimsum_mentai.png',
    },
    {
      'name': 'Paket Rocket 1 (Ayam + Nasi + Es Teh)',
      'resto': 'Rocket Chicken Sambiroto',
      'restoId': 'mch-rc-01',
      'price': 'Rp 15.000',
      'image': 'assets/images/dish_rocket_1.png',
    },
    {
      'name': 'Mie Ayam Pangsit Komplit Bakso Urat',
      'resto': 'Mie Ayam Pak Kumis',
      'restoId': 'mch-mie-01',
      'price': 'Rp 13.000',
      'image': 'assets/images/dish_mie_ayam.png',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          'Resto & Menu Favorit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Resto (${_favoriteRestos.length})'),
            Tab(text: 'Menu Disukai (${_favoriteDishes.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Resto Favorit
          _buildRestoList(),

          // Tab 2: Menu Favorit
          _buildDishesList(),
        ],
      ),
    );
  }

  Widget _buildRestoList() {
    if (_favoriteRestos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text('Belum ada resto favorit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            const SizedBox(height: 4),
            const Text('Tandai ikon hati pada resto kesukaan Anda.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteRestos.length,
      itemBuilder: (ctx, idx) {
        final m = _favoriteRestos[idx];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (c) => RestoDetailScreen(merchant: m)),
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
                      errorBuilder: (c, e, s) => Container(color: GageTheme.primaryLight),
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
                              m['name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          const SizedBox(width: 3),
                          Text('${m['rating']} (${m['ratingCount']})', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              '• ${m['category']}',
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
                          Text('Ongkir ${m['ongkir']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                          const SizedBox(width: 6),
                          Text('• ${m['distance']}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDishesList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteDishes.length,
      itemBuilder: (ctx, idx) {
        final dish = _favoriteDishes[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Image.asset(
                      dish['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: GageTheme.primaryLight,
                        child: const Icon(Icons.fastfood, color: GageTheme.primary),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(dish['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      const SizedBox(height: 2),
                      Text(dish['resto'], style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(dish['price'], style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 13.5)),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: () {
                    // Temukan resto dan buka
                    final resto = _favoriteRestos.firstWhere(
                      (r) => r['id'] == dish['restoId'],
                      orElse: () => _favoriteRestos.first,
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (c) => RestoDetailScreen(merchant: resto)),
                    );
                  },
                  child: const Text('Beli', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
