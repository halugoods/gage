import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';

class ShopFavoriteScreen extends StatefulWidget {
  const ShopFavoriteScreen({super.key});

  @override
  State<ShopFavoriteScreen> createState() => _ShopFavoriteScreenState();
}

class _ShopFavoriteScreenState extends State<ShopFavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _favoriteStores = [
    {
      'id': 'shop-berkah-fajar',
      'name': 'Toko Kelontong Berkah Fajar',
      'category': 'Sembako, Beras, Minyak & Telur',
      'rating': 4.9,
      'ratingCount': '110+',
      'distance': '0.8 km',
      'eta': '10-15 min',
      'ongkir': 'Rp 6.000',
      'image': 'assets/images/hero_banner_1.png',
      'address': 'Jl. Taruna HS, Simpang Bangjo Pracimantoro',
    },
    {
      'id': 'shop-pasar-wage',
      'name': 'Lapak Bumbu & Sayur Pasar Wage',
      'category': 'Bumbu Dapur, Sayur Segar, Kelapa',
      'rating': 4.8,
      'ratingCount': '78',
      'distance': '1.1 km',
      'eta': '12-18 min',
      'ongkir': 'Rp 6.000',
      'image': 'assets/images/hero_promo_1.png',
      'address': 'Los Tengah Pasar Wage Pracimantoro',
    },
  ];

  final List<Map<String, dynamic>> _favoriteProducts = [
    {
      'name': 'Beras C4 Super Raja Polos 5 Kg',
      'store': 'Toko Kelontong Berkah Fajar',
      'storeId': 'shop-berkah-fajar',
      'price': 'Rp 72.000',
      'image': 'assets/images/prod_beras.png',
    },
    {
      'name': 'Minyak Goreng Kita Pouch 2 Liter',
      'store': 'Toko Kelontong Berkah Fajar',
      'storeId': 'shop-berkah-fajar',
      'price': 'Rp 34.000',
      'image': 'assets/images/prod_minyak.png',
    },
    {
      'name': 'Indomie Goreng Spesial (Karton 40 pcs)',
      'store': 'Lapak Bumbu Pasar Wage',
      'storeId': 'shop-pasar-wage',
      'price': 'Rp 118.000',
      'image': 'assets/images/prod_indomie.png',
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
          'Toko & Sembako Favorit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelColor: GageTheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Toko Favorit'),
            Tab(text: 'Barang Sembako Favorit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Toko Favorit
          _favoriteStores.isEmpty
              ? _buildEmptyState('Belum Ada Toko Favorit', 'Toko sembako yang Anda sukai akan muncul di sini.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteStores.length,
                  itemBuilder: (ctx, idx) {
                    final store = _favoriteStores[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => ShopStoreDetailScreen(store: store),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  width: 72,
                                  height: 72,
                                  color: Colors.grey.shade200,
                                  child: Image.asset(
                                    store['image'],
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.storefront, color: Colors.grey),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      store['name'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      store['category'],
                                      style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                        const SizedBox(width: 2),
                                        Text(
                                          '${store['rating']}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '• ${store['distance']}',
                                          style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // Tab 2: Barang Sembako Favorit
          _favoriteProducts.isEmpty
              ? _buildEmptyState('Belum Ada Sembako Favorit', 'Barang belanjaan yang sering Anda pesan akan tersimpan di sini.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteProducts.length,
                  itemBuilder: (ctx, idx) {
                    final item = _favoriteProducts[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                width: 64,
                                height: 64,
                                color: Colors.grey.shade200,
                                child: Image.asset(
                                  item['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.shopping_basket, color: Colors.grey),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    item['store'],
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: GageTheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.favorite_rounded, color: Colors.red, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String desc) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text(desc, style: TextStyle(fontSize: 12, color: Colors.grey.shade600), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
