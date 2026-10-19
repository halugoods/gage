import 'package:flutter/material.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class TernakFavoriteScreen extends StatefulWidget {
  const TernakFavoriteScreen({super.key});

  @override
  State<TernakFavoriteScreen> createState() => _TernakFavoriteScreenState();
}

class _TernakFavoriteScreenState extends State<TernakFavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  final List<Map<String, dynamic>> _favoriteShops = [
    {
      'name': 'Poultry Shop Barokah Ternak Praci',
      'category': 'Pakan Konsentrat Sapi, Katul & Polar',
      'rating': 4.9,
      'distance': '1.0 km',
      'location': 'Dekat Pasar Hewan Pracimantoro',
    },
    {
      'name': 'Lapak Peternak Kambing Tubokarto',
      'category': 'Kambing Jawa Randu, Domba & Pakan Fermentasi',
      'rating': 4.8,
      'distance': '2.3 km',
      'location': 'Dusun Tubokarto, Pracimantoro',
    },
  ];

  final List<Map<String, dynamic>> _favoriteItems = [
    {
      'name': 'Pakan Konsentrat Penggemuk Sapi 50 Kg',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'price': 'Rp 195.000',
      'category': 'Pakan Sapi',
    },
    {
      'name': 'Dedak / Katul Padi Super Halus (Karung 40 Kg)',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'price': 'Rp 140.000',
      'category': 'Pakan Alami',
    },
    {
      'name': 'Premix Vitamin & Mineral Sapi/Kambing (1 Kg)',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'price': 'Rp 28.000',
      'category': 'Suplemen & Obat',
    },
    {
      'name': 'Telur Ayam Kampung Segar (Tray 30 Butir)',
      'shop': 'Lapak Peternak Tubokarto',
      'price': 'Rp 65.000',
      'category': 'Hasil Ternak',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
          'Poultry Shop & Pakan Favorit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFFD97706),
          indicatorWeight: 3,
          labelColor: const Color(0xFFD97706),
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Poultry Shop Favorit'),
            Tab(text: 'Pakan & Vitamin Favorit'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadFavorites,
        color: const Color(0xFFD97706),
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Toko Favorit
            _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (ctx, idx) => const GageSkeletonStoreCard(),
                  )
                : _favoriteShops.isEmpty
                    ? _buildEmptyState('Belum Ada Toko Favorit', 'Poultry shop langganan Anda akan tersimpan di sini.')
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _favoriteShops.length,
                        itemBuilder: (ctx, idx) {
                          final shop = _favoriteShops[idx];
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
                                width: 72,
                                height: 72,
                                color: const Color(0xFFFEF3C7),
                                child: const Icon(Icons.pets_rounded, color: Color(0xFFD97706), size: 36),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    shop['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(shop['category'], style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 2),
                                      Text('${shop['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Text('• ${shop['distance']}', style: const TextStyle(fontSize: 11.5)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.favorite_rounded, color: Colors.red, size: 22),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // Tab 2: Pakan Favorit
          _isLoading
              ? ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: 4,
                  itemBuilder: (ctx, idx) => const GageSkeletonTaniItem(),
                )
              : _favoriteItems.isEmpty
                  ? _buildEmptyState('Belum Ada Pakan Favorit', 'Pakan konsentrat & suplemen yang sering Anda pesan akan tersimpan di sini.')
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _favoriteItems.length,
                      itemBuilder: (ctx, idx) {
                        final item = _favoriteItems[idx];
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
                                color: const Color(0xFFFEF3C7),
                                child: const Icon(Icons.egg_alt_rounded, color: Color(0xFFD97706), size: 30),
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
                                  Text(item['shop'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: Color(0xFFD97706),
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
