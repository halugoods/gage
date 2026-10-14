import 'package:flutter/material.dart';

class TaniFavoriteScreen extends StatefulWidget {
  const TaniFavoriteScreen({super.key});

  @override
  State<TaniFavoriteScreen> createState() => _TaniFavoriteScreenState();
}

class _TaniFavoriteScreenState extends State<TaniFavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _favoriteKios = [
    {
      'name': 'Kios Pertanian Agro Tani Sejahtera',
      'category': 'Pupuk Subsidi, Bibit Jagung & Padi Hibrida',
      'rating': 4.9,
      'distance': '1.2 km',
      'location': 'Jl. Gununggajah, Pracimantoro',
      'image': 'assets/images/prod_pupuk.png',
    },
    {
      'name': 'Sentra Bibit & Alsintan Tani Makmur',
      'category': 'Bibit Buah, Benih Sayuran, Alat Semprot',
      'rating': 4.8,
      'distance': '0.9 km',
      'location': 'Depan Koramil Pracimantoro',
      'image': 'assets/images/prod_beras.png',
    },
  ];

  final List<Map<String, dynamic>> _favoriteItems = [
    {
      'name': 'Pupuk NPK Phonska Plus 25 Kg',
      'kios': 'Kios Agro Tani Sejahtera',
      'price': 'Rp 165.000',
      'category': 'Pupuk Makro',
      'image': 'assets/images/prod_pupuk.png',
    },
    {
      'name': 'Benih Jagung Hibrida Pioneer P27 (5 Kg)',
      'kios': 'Kios Agro Tani Sejahtera',
      'price': 'Rp 480.000',
      'category': 'Bibit Unggul',
      'image': 'assets/images/prod_beras.png',
    },
    {
      'name': 'Insektisida Regent 50 SC (250 ml)',
      'kios': 'Sentra Bibit Tani Makmur',
      'price': 'Rp 55.000',
      'category': 'Obat Hama & Wereng',
      'image': 'assets/images/prod_minyak.png',
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
          'Kios & Sarana Tani Favorit',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF16A34A),
          indicatorWeight: 3,
          labelColor: const Color(0xFF16A34A),
          unselectedLabelColor: Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Kios Tani Favorit'),
            Tab(text: 'Bibit & Pupuk Favorit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Kios Favorit
          _favoriteKios.isEmpty
              ? _buildEmptyState('Belum Ada Kios Favorit', 'Kios saprotan langganan Anda akan tersimpan di sini.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteKios.length,
                  itemBuilder: (ctx, idx) {
                    final kios = _favoriteKios[idx];
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
                                color: const Color(0xFFF0FDF4),
                                child: const Icon(Icons.agriculture_rounded, color: Color(0xFF16A34A), size: 36),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    kios['name'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    kios['category'],
                                    style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                      const SizedBox(width: 2),
                                      Text('${kios['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                      const SizedBox(width: 8),
                                      Text('• ${kios['distance']}', style: const TextStyle(fontSize: 11.5)),
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

          // Tab 2: Bibit & Pupuk Favorit
          _favoriteItems.isEmpty
              ? _buildEmptyState('Belum Ada Pupuk/Bibit Favorit', 'Sarana tani yang sering Anda pesan akan tersimpan di sini.')
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
                                color: const Color(0xFFF0FDF4),
                                child: Image.asset(
                                  item['image'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (c, e, s) => const Icon(Icons.grass_rounded, color: Color(0xFF16A34A)),
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
                                  Text(item['kios'], style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['price'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: Color(0xFF16A34A),
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
