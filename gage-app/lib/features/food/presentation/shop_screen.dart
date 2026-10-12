import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/features/food/presentation/shop_store_detail_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  String _activeQuickFilter = '';
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteStoreIds = {'shop-berkah-fajar'};
  bool _showFavoritesOnly = false;

  final TextEditingController _searchController = TextEditingController();

  String _formatShortAddress(String addr) {
    if (addr.isEmpty) return 'Pilih Lokasi';
    if (addr.contains('(')) {
      return addr.split('(').last.replaceAll(')', '').trim();
    }
    final parts = addr.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    return addr.trim();
  }

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initDeliveryLocation() async {
    final gps = await LocationService.getCurrentLocation();
    final addr = await OsmGeocodingService.reverseGeocode(gps);
    if (mounted) {
      setState(() {
        _deliveryLocation = addr;
      });
    }
  }

  void _showDeliveryLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran Belanja',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _deliveryLocation = '$title - $fullAddress';
        });
      },
    );
  }

  void _toggleFavorite(String storeId) {
    setState(() {
      if (_favoriteStoreIds.contains(storeId)) {
        _favoriteStoreIds.remove(storeId);
      } else {
        _favoriteStoreIds.add(storeId);
      }
    });
  }

  // ===========================================================================
  // DATA KATEGORI BELANJA (Persis Sesuai Spesifikasi GAGE Shop)
  // ===========================================================================
  final List<String> _categories = [
    'Semua',
    'Sembako & Beras',
    'Minyak & Bumbu',
    'Makanan Ringan',
    'Sabun & Kebersihan',
  ];

  // Quick Action Buttons (Setara Arsitektur GAGE Food)
  final List<Map<String, dynamic>> _quickButtons = [
    {
      'title': 'Toko\nTerdekat',
      'icon': Icons.near_me_rounded,
      'color': Color(0xFF00880C),
      'badge': null,
      'action': 'nearest',
    },
    {
      'title': 'Ongkir\nMURAAAH',
      'icon': Icons.delivery_dining_rounded,
      'color': Color(0xFFE65100),
      'badge': null,
      'action': 'cheap_ongkir',
    },
    {
      'title': 'Sembako\nHEMAT',
      'icon': Icons.shopping_basket_rounded,
      'color': Color(0xFFE52320),
      'badge': 'Pasar',
      'action': 'sembako',
    },
    {
      'title': 'Belanja\nMulti-Toko',
      'icon': Icons.storefront_rounded,
      'color': Color(0xFF1565C0),
      'badge': 'Max 3',
      'action': 'multi_store',
    },
  ];

  // ===========================================================================
  // DAFTAR MERCHANT RESMI GAGE SHOP (Daftar Toko Mitra Pracimantoro)
  // ===========================================================================
  final List<Map<String, dynamic>> _retailStores = [
    {
      'id': 'shop-berkah-fajar',
      'name': 'Toko Sembako Berkah Fajar',
      'category': 'Sembako & Beras, Minyak & Bumbu',
      'address': 'Jl. Raya Pracimantoro No. 12, Wonogiri',
      'distance': '0.5 km',
      'eta': '10-15 min',
      'rating': 4.9,
      'ratingCount': '140+',
      'openHours': '06:30 - 21:00',
      'isOpen': true,
      'diskonBadge': 'Harga Pasar Murah',
      'ongkirBadge': 'Diskon Ongkir Rp 4rb',
      'image': 'assets/images/hero_banner_1.png',
      'phone_wa': '081234567801',
      'description': 'Sedia aneka beras C4 pulen Wonogiri, minyak Bimoli, gula kristal, telur ayam segar, dan terigu segitiga biru.',
    },
    {
      'id': 'shop-kelontong-bu-sri',
      'name': 'Toko Kelontong Bu Sri',
      'category': 'Sembako & Beras, Makanan Ringan, Sabun & Kebersihan',
      'address': 'Simpang Empat Pasar Pracimantoro Blok A',
      'distance': '0.8 km',
      'eta': '15-20 min',
      'rating': 4.9,
      'ratingCount': '185+',
      'openHours': '06:00 - 20:30',
      'isOpen': true,
      'diskonBadge': 'Langganan Warga',
      'ongkirBadge': 'Diskon Ongkir Rp 4rb',
      'image': 'assets/images/hero_promo_2.png',
      'phone_wa': '081234567802',
      'description': 'Toko kelontong komplit kebutuhan harian rumah tangga, camilan rengginang, kerupuk, kopi sachet, dan detergen.',
    },
    {
      'id': 'shop-minimarket-losari',
      'name': 'Minimarket Warga Losari',
      'category': 'Makanan Ringan, Sabun & Kebersihan, Minyak & Bumbu',
      'address': 'Jl. Sedayu - Losari KM 1, Pracimantoro',
      'distance': '1.1 km',
      'eta': '15-25 min',
      'rating': 4.8,
      'ratingCount': '210+',
      'openHours': '07:00 - 22:00',
      'isOpen': true,
      'diskonBadge': 'Super Hemat',
      'ongkirBadge': 'Diskon Ongkir Rp 5rb',
      'image': 'assets/images/hero_banner_2.png',
      'phone_wa': '081234567803',
      'description': 'Minimarket serba ada, aneka snack biskuit, susu UHT, minuman dingin, sabun mandi, shampo, dan perlengkapan dapur.',
    },
    {
      'id': 'shop-grosir-sentosa',
      'name': 'Grosir Pangan Sentosa',
      'category': 'Sembako & Beras, Minyak & Bumbu, Makanan Ringan',
      'address': 'Kawasan Terminal Pracimantoro No. 45',
      'distance': '1.4 km',
      'eta': '20-25 min',
      'rating': 4.9,
      'ratingCount': '95+',
      'openHours': '07:00 - 18:00',
      'isOpen': true,
      'diskonBadge': 'Harga Grosir Dus-dusan',
      'ongkirBadge': 'Diskon Ongkir Rp 5rb',
      'image': 'assets/images/promo_banner_2.png',
      'phone_wa': '081234567804',
      'description': 'Pusat grosir pangan, sembako karungan, mie instan per dus karton, minyak jerigen/karton, dan aneka bumbu dapur.',
    },
    {
      'id': 'shop-sayur-bu-marti',
      'name': 'Pasar Sayur Segar Bu Marti',
      'category': 'Sembako & Beras, Minyak & Bumbu',
      'address': 'Pasar Tradisional Pracimantoro Los Sayur No. 8',
      'distance': '0.7 km',
      'eta': '10-20 min',
      'rating': 4.9,
      'ratingCount': '110+',
      'openHours': '05:30 - 13:00',
      'isOpen': true,
      'diskonBadge': 'Petik Segar Tiap Pagi',
      'ongkirBadge': 'Diskon Ongkir Rp 4rb',
      'image': 'assets/images/promo_banner_3.png',
      'phone_wa': '081234567805',
      'description': 'Sayur mayur hijau segar langsung panen, cabai rawit merah pedas, bawang merah brebes, tomat, dan bumbu racik.',
    },
    {
      'id': 'shop-sumber-lancar',
      'name': 'Depot Galon & Gas LPG Sumber Lancar',
      'category': 'Sabun & Kebersihan, Sembako & Beras',
      'address': 'Jl. Ahmad Yani No. 8, Pracimantoro',
      'distance': '1.2 km',
      'eta': '15-20 min',
      'rating': 4.7,
      'ratingCount': '75+',
      'openHours': '06:00 - 21:00',
      'isOpen': true,
      'diskonBadge': 'Antar Sampai Dapur',
      'ongkirBadge': 'Diskon Ongkir Rp 3rb',
      'image': 'assets/images/hero_promo_1.png',
      'phone_wa': '081234567806',
      'description': 'Isi ulang galon Aqua 19L, gas melon LPG 3kg bersubsidi, dan sabun cuci piring Sunlight.',
    },
  ];

  // ===========================================================================
  // KATALOG PRODUK POPULER PILIHAN (Terhubung ke MultiMerchantCartService)
  // ===========================================================================
  final List<Map<String, dynamic>> _quickProducts = [
    {
      'id': 'prod-beras-c4',
      'name': 'Beras C4 Super Raja 5 Kg',
      'category': 'Sembako & Beras',
      'price': 72000,
      'unit': '5 kg',
      'storeId': 'shop-berkah-fajar',
      'storeName': 'Toko Sembako Berkah Fajar',
      'image': 'assets/images/prod_beras.png',
      'desc': 'Beras pulen alami tanpa pemutih asli petani Wonogiri.',
    },
    {
      'id': 'prod-minyak-bimoli',
      'name': 'Minyak Goreng Bimoli 2 Liter',
      'category': 'Minyak & Bumbu',
      'price': 38500,
      'unit': 'Pouch 2L',
      'storeId': 'shop-berkah-fajar',
      'storeName': 'Toko Sembako Berkah Fajar',
      'image': 'assets/images/prod_minyak.png',
      'desc': 'Minyak kelapa sawit murni jernih dua kali penyaringan.',
    },
    {
      'id': 'prod-gula-pasir',
      'name': 'Gula Pasir Gulaku 1 Kg',
      'category': 'Sembako & Beras',
      'price': 18000,
      'unit': '1 kg',
      'storeId': 'shop-kelontong-bu-sri',
      'storeName': 'Toko Kelontong Bu Sri',
      'image': 'assets/images/prod_gula.png',
      'desc': 'Gula tebu kristal premium manis alami higienis.',
    },
    {
      'id': 'prod-telur-ayam',
      'name': 'Telur Ayam Segar Kandang 1 Kg',
      'category': 'Sembako & Beras',
      'price': 28000,
      'unit': '1 kg (~16 butir)',
      'storeId': 'shop-berkah-fajar',
      'storeName': 'Toko Sembako Berkah Fajar',
      'image': 'assets/images/prod_telur.png',
      'desc': 'Telur ayam fresh baru panen pagi peternak lokal.',
    },
    {
      'id': 'prod-indomie-dus',
      'name': 'Indomie Goreng Spesial 1 Dus',
      'category': 'Makanan Ringan',
      'price': 118000,
      'unit': 'Dus (40 pcs)',
      'storeId': 'shop-grosir-sentosa',
      'storeName': 'Grosir Pangan Sentosa',
      'image': 'assets/images/prod_indomie.png',
      'desc': 'Mi instan goreng favorit Indonesia harga grosir hemat.',
    },
    {
      'id': 'prod-roma-kelapa',
      'name': 'Biskuit Roma Kelapa 300 Gram',
      'category': 'Makanan Ringan',
      'price': 11500,
      'unit': 'Pack 300g',
      'storeId': 'shop-minimarket-losari',
      'storeName': 'Minimarket Warga Losari',
      'image': 'assets/images/hero_promo_2.png',
      'desc': 'Biskuit kelapa renyah gurih teman ngeteh keluarga.',
    },
    {
      'id': 'prod-sunlight-700',
      'name': 'Sunlight Jeruk Nipis 700ml',
      'category': 'Sabun & Kebersihan',
      'price': 14000,
      'unit': 'Pouch 700ml',
      'storeId': 'shop-minimarket-losari',
      'storeName': 'Minimarket Warga Losari',
      'image': 'assets/images/hero_banner_1.png',
      'desc': 'Pembersih lemak bandel wangi segar jeruk nipis.',
    },
    {
      'id': 'prod-sabun-lifebuoy',
      'name': 'Sabun Lifebuoy Total 10 (Pack 4)',
      'category': 'Sabun & Kebersihan',
      'price': 16500,
      'unit': 'Pack 4 Bar',
      'storeId': 'shop-minimarket-losari',
      'storeName': 'Minimarket Warga Losari',
      'image': 'assets/images/hero_promo_1.png',
      'desc': 'Perlindungan kuman antibakteri alami untuk keluarga.',
    },
    {
      'id': 'prod-cabai-rawit',
      'name': 'Cabai Rawit Merah Pedas 250g',
      'category': 'Minyak & Bumbu',
      'price': 14000,
      'unit': '250 gram',
      'storeId': 'shop-sayur-bu-marti',
      'storeName': 'Pasar Sayur Segar Bu Marti',
      'image': 'assets/images/prod_cabai.png',
      'desc': 'Cabai rawit merah petik segar pedas mantap pasar pagi.',
    },
    {
      'id': 'prod-bawang-merah',
      'name': 'Bawang Merah Brebes 500g',
      'category': 'Minyak & Bumbu',
      'price': 19000,
      'unit': '500 gram',
      'storeId': 'shop-sayur-bu-marti',
      'storeName': 'Pasar Sayur Segar Bu Marti',
      'image': 'assets/images/prod_cabai.png',
      'desc': 'Bawang merah kering bersih wangi tajam masakan nusantara.',
    },
  ];

  // Filter Merchant
  List<Map<String, dynamic>> get _filteredStores {
    return _retailStores.where((s) {
      final name = s['name'].toString().toLowerCase();
      final cat = s['category'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty || name.contains(q) || cat.contains(q);

      if (!matchesQuery) return false;

      final matchesFav = !_showFavoritesOnly || _favoriteStoreIds.contains(s['id'] as String);
      if (!matchesFav) return false;

      // Quick filter
      if (_activeQuickFilter == 'nearest') {
        final dist = double.tryParse((s['distance'] as String).replaceAll(' km', '')) ?? 99.0;
        if (dist > 1.0) return false;
      } else if (_activeQuickFilter == 'cheap_ongkir') {
        if (s['ongkirBadge'] == null) return false;
      }

      if (_selectedCategory == 'Semua') return true;
      if (_selectedCategory == 'Sembako & Beras') {
        return cat.contains('sembako') || cat.contains('beras');
      }
      if (_selectedCategory == 'Minyak & Bumbu') {
        return cat.contains('minyak') || cat.contains('bumbu');
      }
      if (_selectedCategory == 'Makanan Ringan') {
        return cat.contains('makanan') || cat.contains('ringan') || cat.contains('snack');
      }
      if (_selectedCategory == 'Sabun & Kebersihan') {
        return cat.contains('sabun') || cat.contains('kebersihan');
      }
      return true;
    }).toList();
  }

  // Filter Produk Pilihan
  List<Map<String, dynamic>> get _filteredQuickProducts {
    return _quickProducts.where((p) {
      final name = p['name'].toString().toLowerCase();
      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty || name.contains(q);
      if (!matchesQuery) return false;

      if (_selectedCategory == 'Semua') return true;
      return p['category'] == _selectedCategory;
    }).toList();
  }

  // Tambah item ke keranjang belanja (sinkron dengan MultiMerchantCartService & CartProvider)
  void _addToCart(BuildContext context, Map<String, dynamic> prod) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();

    final cartItem = CartItem(
      id: prod['id'] as String,
      name: prod['name'] as String,
      price: prod['price'] as int,
      quantity: 1,
      storeId: prod['storeId'] as String,
      storeName: prod['storeName'] as String,
      category: prod['category'] as String? ?? 'Sembako',
      image: prod['image'] as String? ?? '',
      menuOrigin: 'shop',
    );

    final cartItemModel = CartItemModel(
      menuId: prod['id'] as String,
      merchantId: prod['storeId'] as String,
      merchantName: prod['storeName'] as String,
      name: prod['name'] as String,
      price: prod['price'] as int,
      quantity: 1,
      category: prod['category'] as String? ?? 'Sembako',
      imageUrl: prod['image'] as String?,
      serviceType: 'shop',
    );

    final success = multiCart.addItem(cartItem);
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(multiCart.lastErrorMessage ?? 'Maksimal 3 toko berbeda dalam satu keranjang belanja.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final addedToProvider = cart.addItem(cartItemModel);
    if (!addedToProvider) {
      multiCart.removeItem(prod['storeId'] as String, prod['id'] as String);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 3 toko berbeda dalam satu keranjang.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${prod['name']} ditambahkan ke keranjang'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'LIHAT',
          textColor: Colors.white,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
            );
          },
        ),
      ),
    );
  }

  void _updateProductQuantity(BuildContext context, Map<String, dynamic> prod, int delta) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();
    final prodId = prod['id'] as String;
    final storeId = prod['storeId'] as String;

    cart.updateQuantity(prodId, delta);
    final currentQty = cart.getItemQuantity(prodId);
    multiCart.updateQuantity(storeId, prodId, currentQty);
  }

  void _showMultiStoreInfoDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.storefront_rounded, color: GageTheme.primary, size: 26),
            SizedBox(width: 8),
            Text('Belanja Multi-Toko', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GAGE Shop mendukung belanja dari hingga 3 toko mitra resmi sekaligus dalam 1 kali pemesanan!',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Kurir mengambil pesanan berurutan ke tiap toko', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Ongkir terpadu hemat & langsung diantar ke pintu rumah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text('Bisa gabung sembako, sayur, minimarket, dan rempah', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET KARTU MERCHANT RESMI
  // ===========================================================================
  Widget _buildStoreCard(Map<String, dynamic> store) {
    final storeId = store['id'] as String;
    final isFav = _favoriteStoreIds.contains(storeId);
    final openHours = store['openHours'] ?? '07:00 - 21:00';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => ShopStoreDetailScreen(store: store),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
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
            // Foto Thumbnail Toko
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 84,
                height: 84,
                color: Colors.grey.shade100,
                child: Image.asset(
                  store['image'] ?? 'assets/images/hero_banner_1.png',
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const Icon(Icons.storefront_rounded, color: Colors.grey, size: 36),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Info Toko
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          store['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: GageTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () => _toggleFavorite(storeId),
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            size: 18,
                            color: isFav ? Colors.red : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                      const SizedBox(width: 3),
                      Text(
                        '${store['rating'] ?? 4.9} (${store['ratingCount'] ?? '50+'})',
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '• ${store['category'] ?? ''}',
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
                      const Icon(Icons.near_me_rounded, color: GageTheme.primary, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        store['distance'] ?? '1.0 km',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '• ${store['eta'] ?? '15-20 min'}',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 6),
                      // Jam Operasional Toko
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.green.shade200, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time_filled_rounded, size: 9.5, color: Colors.green.shade700),
                            const SizedBox(width: 2.5),
                            Text(
                              'Buka $openHours',
                              style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (store['diskonBadge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF0F0),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFFCDD2)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.local_offer_rounded, color: GageTheme.primary, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                store['diskonBadge'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.primary),
                              ),
                            ],
                          ),
                        ),
                      if (store['ongkirBadge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.delivery_dining_rounded, color: GageTheme.accentGreen, size: 10),
                              const SizedBox(width: 3),
                              Text(
                                store['ongkirBadge'],
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.accentGreen),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGET KARTU PRODUK PILIHAN CEPAT (Terhubung ke MultiMerchantCartService)
  // ===========================================================================
  Widget _buildQuickProductCard(BuildContext context, Map<String, dynamic> prod, CartProvider cart, NumberFormat currencyFormatter) {
    final prodId = prod['id'] as String;
    final itemQty = cart.getItemQuantity(prodId);
    final price = prod['price'] as int;

    return Container(
      width: 155,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gambar Produk
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Image.asset(
                prod['image'] ?? 'assets/images/prod_beras.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: GageTheme.primaryLight,
                  child: const Icon(Icons.shopping_bag_rounded, color: GageTheme.primary),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nama Toko Tag
                Row(
                  children: [
                    const Icon(Icons.storefront_rounded, size: 11, color: GageTheme.primary),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        prod['storeName'] ?? '',
                        style: const TextStyle(fontSize: 9.5, color: GageTheme.textSecondary, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  prod['name'] ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  prod['unit'] ?? '',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 6),
                Text(
                  currencyFormatter.format(price),
                  style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 13),
                ),
                const SizedBox(height: 8),
                // Stepper atau Tombol Tambah
                itemQty > 0
                    ? Container(
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: GageTheme.primary, width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => _updateProductQuantity(context, prod, -1),
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Icon(Icons.remove, size: 14, color: GageTheme.primary),
                              ),
                            ),
                            Text(
                              '$itemQty',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: GageTheme.primary),
                            ),
                            InkWell(
                              onTap: () => _updateProductQuantity(context, prod, 1),
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(7)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Icon(Icons.add, size: 14, color: GageTheme.primary),
                              ),
                            ),
                          ],
                        ),
                      )
                    : SizedBox(
                        width: double.infinity,
                        height: 28,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: () => _addToCart(context, prod),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add, size: 14),
                              SizedBox(width: 2),
                              Text('+ Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD METHOD UTAMA
  // ===========================================================================
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final bannerManager = context.watch<BannerManagerService>();
    final shopBanner = bannerManager.getBanner('shop');
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    // Menghitung tinggi banner 16:9 yang proporsional dan bersih
    final rawBannerHeight = screenWidth * 9 / 16;
    final bannerHeight = isTablet ? 260.0 : rawBannerHeight.clamp(200.0, 260.0);
    final topPadding = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Padding atas efektif agar tidak pernah kecrop oleh status bar / poni HP
    final effectiveTopPadding = math.max(topPadding, 24.0);
    final totalHeaderHeight = bannerHeight + effectiveTopPadding + 24.0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: GageTheme.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===============================================================
              // HEADER HERO BANNER 16:9 BERSIH & FLOATING CONTROLS (ANTI-KECROP)
              // ===============================================================
              SizedBox(
                height: totalHeaderHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // LAYER 1: Full-Width Hero Banner 16:9 Murni Bersih (Bebas vignette & bebas overlay teks kaku)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: bannerHeight + effectiveTopPadding,
                      child: Image.asset(
                        shopBanner.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF00880C), Color(0xFF0F5132)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.shopping_bag_rounded, size: 64, color: Colors.white24),
                          ),
                        ),
                      ),
                    ),

                    // LAYER 2: Floating Action Controls di Atas Banner
                    // DILINDUNGI SafeArea(top: true) + ekstra padding agar 100% BEBAS KECROP di semua HP!
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: true,
                        bottom: false,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(14, topPadding > 0 ? 8.0 : 16.0, 14, 0),
                          child: Row(
                            children: [
                              // Tombol Back (X)
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.close_rounded, color: Colors.black87, size: 22),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Pill Alamat Dropdown
                              Flexible(
                                child: GestureDetector(
                                  onTap: _showDeliveryLocationPicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: const [
                                        BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.location_on, color: Color(0xFF00880C), size: 16),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            '${_formatShortAddress(_deliveryLocation)} ▾',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: Colors.black87,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Pill Favorit Mandiri
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _showFavoritesOnly = !_showFavoritesOnly;
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _showFavoritesOnly
                                            ? 'Menampilkan toko favorit Anda (${_favoriteStoreIds.length})'
                                            : 'Menampilkan semua toko mitra resmi',
                                      ),
                                      duration: const Duration(seconds: 1),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    _showFavoritesOnly ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                    color: _showFavoritesOnly ? Colors.red : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // Pill Riwayat Belanja
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF00880C), size: 20),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // LAYER 3: Floating Search Bar Overlapping 50% di Perbatasan Banner & Body
                    Positioned(
                      bottom: 0,
                      left: 16,
                      right: 16,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
                          child: Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 3)),
                              ],
                            ),
                            child: TextField(
                              controller: _searchController,
                              textAlignVertical: TextAlignVertical.center,
                              onChanged: (val) => setState(() => _searchQuery = val),
                              style: const TextStyle(fontSize: 13),
                              decoration: InputDecoration(
                                hintText: 'Cari sembako & kebutuhan di toko mitra...',
                                hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade500),
                                prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF00880C), size: 22),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ===============================================================
              // BODY KONTEN RESPONSIF (Setara Arsitektur GAGE Food)
              // ===============================================================
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. 4 Tombol Cepat (Setara GAGE Food Quick Buttons)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: _quickButtons.map((btn) {
                            final action = btn['action'] as String;
                            final isSelected = _activeQuickFilter == action;

                            return GestureDetector(
                              onTap: () {
                                if (action == 'multi_store') {
                                  _showMultiStoreInfoDialog();
                                } else if (action == 'sembako') {
                                  setState(() {
                                    _selectedCategory = 'Sembako & Beras';
                                    _activeQuickFilter = '';
                                  });
                                } else {
                                  setState(() {
                                    _activeQuickFilter = isSelected ? '' : action;
                                  });
                                }
                              },
                              child: Column(
                                children: [
                                  Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Container(
                                        width: isTablet ? 64 : 52,
                                        height: isTablet ? 64 : 52,
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? (btn['color'] as Color).withValues(alpha: 0.15)
                                              : Colors.grey.shade100,
                                          shape: BoxShape.circle,
                                          border: isSelected
                                              ? Border.all(color: btn['color'] as Color, width: 2)
                                              : null,
                                        ),
                                        child: Icon(
                                          btn['icon'] as IconData,
                                          color: btn['color'] as Color,
                                          size: isTablet ? 28 : 24,
                                        ),
                                      ),
                                      if (btn['badge'] != null)
                                        Positioned(
                                          top: -4,
                                          right: -6,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: GageTheme.primary,
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              btn['badge'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8.5,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    btn['title'] as String,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                      color: isSelected ? GageTheme.primary : GageTheme.textPrimary,
                                      height: 1.15,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 2. Tab Filter Kategori Belanja (5 Kategori Resmi)
                      SizedBox(
                        height: 38,
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          scrollDirection: Axis.horizontal,
                          itemCount: _categories.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (ctx, idx) {
                            final cat = _categories[idx];
                            final isSel = _selectedCategory == cat;
                            return ChoiceChip(
                              label: Text(cat),
                              selected: isSel,
                              onSelected: (_) => setState(() => _selectedCategory = cat),
                              selectedColor: GageTheme.primaryLight,
                              labelStyle: TextStyle(
                                color: isSel ? GageTheme.primary : GageTheme.textPrimary,
                                fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 3. Section Produk Pilihan / Populer (Direct Add via MultiMerchantCartService)
                      if (_filteredQuickProducts.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kebutuhan Sembako & Harian Populer 🛒',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              Text(
                                '${_filteredQuickProducts.length} Produk',
                                style: const TextStyle(fontSize: 11.5, color: GageTheme.accentGreen, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 236,
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: _filteredQuickProducts.length,
                            itemBuilder: (ctx, idx) => _buildQuickProductCard(
                              context,
                              _filteredQuickProducts[idx],
                              cart,
                              currencyFormatter,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // 4. Banner Multi-Merchant Info Card
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBBF7D0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Colors.green.shade100, blurRadius: 4),
                                  ],
                                ),
                                child: const Icon(Icons.storefront_rounded, color: Color(0xFF00880C), size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Belanja Bebas Hingga 3 Toko Sekaligus',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF0F5132)),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Gabungkan pesanan sembako, sayur, dan minimarket dalam 1 order pengantaran hemat.',
                                      style: TextStyle(fontSize: 11, color: Color(0xFF166534)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // 5. Header Daftar Toko Merchant Resmi
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Daftar Toko & Minimarket Mitra Resmi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              '${_filteredStores.length} Toko Buka',
                              style: const TextStyle(fontSize: 12, color: GageTheme.accentGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),

                      // 6. List of Store Cards (Responsive Grid saat Tablet)
                      if (_filteredStores.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.store_mall_directory_outlined, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  _showFavoritesOnly
                                      ? 'Belum ada toko yang ditandai favorit.'
                                      : 'Toko tidak ditemukan untuk kata kunci "$_searchQuery"',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        )
                      else if (isTablet)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: screenWidth > 900 ? 3 : 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              mainAxisExtent: 136,
                            ),
                            itemCount: _filteredStores.length,
                            itemBuilder: (ctx, idx) => _buildStoreCard(_filteredStores[idx]),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filteredStores.length,
                          itemBuilder: (ctx, idx) => _buildStoreCard(_filteredStores[idx]),
                        ),

                      const SizedBox(height: 90),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // =====================================================================
        // FLOATING CART SUMMARY BAR (Responsive Multi-Merchant Checkout)
        // =====================================================================
        bottomNavigationBar: cart.totalItemCount > 0
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -3)),
                  ],
                ),
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
                      child: Row(
                        children: [
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${cart.totalItemCount} Barang',
                                    style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                  if (cart.merchantCount > 1) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E9),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '${cart.merchantCount} Toko (Multi-Merchant)',
                                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF00880C)),
                                      ),
                                    ),
                                  ] else ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      '(${cart.merchantCount} Toko)',
                                      style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                currencyFormatter.format(cart.subtotal),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                              ),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
                              );
                            },
                            child: const Row(
                              children: [
                                Text('Lihat Belanjaan', style: TextStyle(fontWeight: FontWeight.bold)),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }
}
