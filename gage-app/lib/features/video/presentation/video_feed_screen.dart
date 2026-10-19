import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';

class VideoFeedScreen extends StatefulWidget {
  const VideoFeedScreen({super.key});

  @override
  State<VideoFeedScreen> createState() => _VideoFeedScreenState();
}

class _VideoFeedScreenState extends State<VideoFeedScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _videos = [
    {
      'author': '@ratih_kuliner',
      'title': 'Rekomendasi Dimsum Mentai 6 pcs dari Dimsum Sewu. Porsi pas dan sausnya gurih.',
      'audio': 'Dimsum Sewu by Halu Goods',
      'tag': '[GAGE#HGDS-M01]',
      'product_name': 'Combo Mentai 6 Pcs',
      'price': 15000,
      'merchant_id': 'm-dimsum-sewu',
      'merchant': 'Dimsum Sewu by Halu Goods',
      'likes': '1.2k',
      'comments': '48',
      'shares': '32',
      'gradient': [Color(0xFF831843), Color(0xFF500724)],
    },
    {
      'author': '@budi_makan',
      'title': 'Mie ayam porsi komplit dengan pangsit rebus hangat di Pogung.',
      'audio': 'Mie Ayam Pak Kumis',
      'tag': '[GAGE#PKM-MIE02]',
      'product_name': 'Mie Ayam Komplit Jumbo',
      'price': 12000,
      'merchant_id': 'm-mie-kumis',
      'merchant': 'Mie Ayam Pak Kumis',
      'likes': '3.4k',
      'comments': '112',
      'shares': '95',
      'gradient': [Color(0xFF1E3A8A), Color(0xFF0F172A)],
    },
  ];

  void _showOrderBottomSheet(Map<String, dynamic> video) {
    final cart = context.read<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final price = video['price'] as int;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        video['product_name'],
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
                      ),
                      Text(
                        'Resto: ${video['merchant']}',
                        style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary),
                      ),
                    ],
                  ),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: GageTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: GageTheme.accentGreen, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Dipromosikan oleh ${video['author']} (Mitra Kreator Resmi)',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GageTheme.accentGreen),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Harga Menu', style: TextStyle(color: GageTheme.textSecondary)),
                  Text(currencyFormatter.format(price), style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Diskon Ongkir Kreator (GAGERATIH)', style: TextStyle(color: GageTheme.accentGreen, fontWeight: FontWeight.bold)),
                  Text('- Rp 2.000', style: TextStyle(color: GageTheme.accentGreen, fontWeight: FontWeight.bold)),
                ],
              ),
              const Divider(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  cart.addItem(
                    CartItemModel(
                      menuId: 'menu-vt-${video['product_name']}',
                      merchantId: video['merchant_id'] ?? 'm-dimsum-sewu',
                      merchantName: video['merchant'] ?? 'Resto Mitra',
                      name: video['product_name'] ?? 'Menu Pilihan',
                      price: price,
                      quantity: 1,
                    ),
                    forceReplace: true,
                  );
                  cart.setPromoCode('GAGERATIH');

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (c) => const CheckoutScreen()),
                  );
                },
                child: const Text('Beli Sekarang via Keranjang Kuning', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: Colors.black,
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _videos.length,
        itemBuilder: (context, index) {
          final video = _videos[index];
          final gradientColors = video['gradient'] as List<Color>;

          return Stack(
            fit: StackFit.expand,
            children: [
              // Background Gradient Video Simulator
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: gradientColors,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 2),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, size: 64, color: Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'TikTok Review Video Embed',
                        style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        video['tag'],
                        style: const TextStyle(color: GageTheme.accentYellow, fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),

              // Gradient Overlay Bawah
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 320,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black87, Colors.transparent],
                    ),
                  ),
                ),
              ),

              // Sisi Kanan: Interaksi (Like, Comment, Share)
              Positioned(
                right: 16,
                bottom: 90,
                child: Column(
                  children: [
                    _buildActionButton(Icons.favorite_rounded, video['likes'], Colors.red),
                    const SizedBox(height: 18),
                    _buildActionButton(Icons.chat_bubble_rounded, video['comments'], Colors.white),
                    const SizedBox(height: 18),
                    _buildActionButton(Icons.share_rounded, video['shares'], Colors.white),
                  ],
                ),
              ),

              // Sisi Bawah Kiri: Informasi Video & Tombol Keranjang Kuning
              Positioned(
                left: 16,
                bottom: 24,
                right: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TOMBOL KERANJANG KUNING (CTA DI ATAS USERNAME PERSIS SEPERTI TIKTOK SHOP)
                    InkWell(
                      onTap: () => _showOrderBottomSheet(video),
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: GageTheme.accentYellow,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: const [
                            BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.shopping_bag_rounded, color: Colors.black, size: 18),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Pesan ${video['product_name']} (Rp ${video['price'].toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')})',
                                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Username Kreator
                    Text(
                      video['author'],
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    const SizedBox(height: 4),

                    // Deskripsi Video
                    Text(
                      video['title'],
                      style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.3),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: const GageBottomNavBar(currentIndex: 3),
    ),
  );
  }

  Widget _buildActionButton(IconData icon, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 32),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
