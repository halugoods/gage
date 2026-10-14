import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/babe/presentation/babe_detail_screen.dart';

class BabeFavoriteScreen extends StatefulWidget {
  const BabeFavoriteScreen({super.key});

  @override
  State<BabeFavoriteScreen> createState() => _BabeFavoriteScreenState();
}

class _BabeFavoriteScreenState extends State<BabeFavoriteScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<Map<String, dynamic>> _favoriteItems = [
    {
      'id': 'babe-elektronik-01',
      'title': 'Mesin Cuci Sharp 2 Tabung 8 Kg Mulus',
      'category': 'Elektronik Rumah Tangga',
      'price': 850000,
      'originalPrice': 2100000,
      'condition': 'Bekas Mulus 90%',
      'location': 'Dusun Gebangharjo, Pracimantoro',
      'seller': 'Pak Wandi (Terverifikasi GAGE)',
      'status': 'Tersedia',
      'rating': 4.9,
    },
    {
      'id': 'babe-motor-02',
      'title': 'Honda Beat ESP 2018 Surat Lengkap Pajak On',
      'category': 'Kendaraan & Motor Bekas',
      'price': 9800000,
      'originalPrice': 15000000,
      'condition': 'Mesin Segel Halus',
      'location': 'Simpang Bangjo Pracimantoro',
      'seller': 'Mas Doni Praci',
      'status': 'Tersedia',
      'rating': 5.0,
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
          'Barang Bekas & Lapak Favorit',
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
            Tab(text: 'Barang BaBe Favorit'),
            Tab(text: 'Lapak Penjual Favorit'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Barang BaBe Favorit
          _favoriteItems.isEmpty
              ? _buildEmptyState('Belum Ada Barang Favorit', 'Barang bekas terkurasi yang Anda sukai akan muncul di sini.')
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _favoriteItems.length,
                  itemBuilder: (ctx, idx) {
                    final item = _favoriteItems[idx];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => BabeDetailScreen(item: item),
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
                                  child: const Icon(Icons.recycling_rounded, color: GageTheme.primary, size: 36),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['title'],
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      '${item['condition']} • ${item['location']}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      'Rp ${item['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
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
                      ),
                    );
                  },
                ),

          // Tab 2: Lapak Favorit
          _buildEmptyState('Lapak Penjual Favorit', 'Penjual terverifikasi di Pracimantoro yang Anda ikuti akan muncul di sini.'),
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
