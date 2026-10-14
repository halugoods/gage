import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/adaptive_speech_bubble.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/food/presentation/tani_favorite_screen.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

class TaniScreen extends StatefulWidget {
  const TaniScreen({super.key});

  @override
  State<TaniScreen> createState() => _TaniScreenState();
}

class _TaniScreenState extends State<TaniScreen> {
  // Switch Utama: 'toko_pertanian' vs 'hasil_bumi'
  String _selectedSection = 'toko_pertanian';
  String _activeCategoryFilter = 'Semua';

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _deliveryLocation = 'Kecamatan Pracimantoro, Wonogiri';
  final Set<String> _favoriteItemIds = {};
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initDeliveryLocation() async {
    try {
      final gps = await LocationService.getCurrentLocation();
      final addr = await OsmGeocodingService.reverseGeocode(gps);
      if (mounted && addr.isNotEmpty) {
        setState(() {
          _deliveryLocation = addr;
        });
      }
    } catch (_) {}
  }

  Future<void> _openWhatsApp({
    required String phone,
    required String message,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        _showContactFallback(phone, message);
      }
    } catch (_) {
      if (mounted) {
        _showContactFallback(phone, message);
      }
    }
  }

  void _showContactFallback(String phone, String message) {
    GageFloatingSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hubungi Kontak WhatsApp',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F4F6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text('Nomor WhatsApp:'),
          const SizedBox(height: 4),
          SelectableText(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF16A34A))),
          const SizedBox(height: 10),
          const Text('Pesan:'),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
            child: SelectableText(message, style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _openConsultationWhatsApp() {
    const msg = 'Halo Dokter Tanaman & Tim Agronomi GAGE Pracimantoro,\n\n'
        'Saya ingin mengajukan *Konsultasi Gratis GAGE Tani*:\n'
        '- Topik: Perlindungan Tanaman / Kesuburan Lahan / Hama\n'
        '- Nama Petani:\n'
        '- Dusun / Desa Lahan:\n'
        '- Kendala Tanaman:\n\n'
        'Mohon bantuan dan rekomendasi penanganannya. Terima kasih!';

    _openWhatsApp(phone: '6281234567891', message: msg);
  }

  void _showLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran GAGE Tani',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _deliveryLocation = title.isNotEmpty ? title : fullAddress;
        });
      },
    );
  }

  void _toggleFavorite(String itemId) {
    setState(() {
      if (_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.remove(itemId);
      } else {
        _favoriteItemIds.add(itemId);
      }
    });
  }

  String _formatShortAddress(String addr) {
    if (addr.isEmpty) return 'Pilih Lokasi';
    if (addr.contains('(')) {
      return addr.split('(').last.replaceAll(')', '').trim();
    }
    final parts = addr.split(',');
    if (parts.length >= 2) {
      return '${parts[0].trim()}, ${parts[1].trim()}';
    }
    if (addr.length > 20) {
      return '${addr.substring(0, 18)}...';
    }
    return addr.trim();
  }

  // ===========================================================================
  // MANAJEMEN KERANJANG BERSAMA (CartProvider & MultiMerchantCartService)
  // ===========================================================================
  void _addToCart(BuildContext context, Map<String, dynamic> item) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();

    final storeId = item['kiosId'] as String? ?? 'mch-gage-tani';
    final storeName = item['kios'] as String? ?? 'Lapak Resmi Agro GAGE Tani';

    final cartItem = CartItem(
      id: item['id'] as String,
      name: item['name'] as String,
      price: item['price'] as int,
      quantity: 1,
      storeId: storeId,
      storeName: storeName,
      category: item['category'] as String? ?? 'Tani',
      image: item['image'] as String? ?? '',
      menuOrigin: 'tani',
    );

    final cartItemModel = CartItemModel(
      menuId: item['id'] as String,
      merchantId: storeId,
      merchantName: storeName,
      name: item['name'] as String,
      price: item['price'] as int,
      quantity: 1,
      category: item['category'] as String? ?? 'Tani',
      imageUrl: item['image'] as String?,
      serviceType: 'tani',
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
      multiCart.removeItem(storeId, item['id'] as String);
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
        content: Text('${item['name']} ditambahkan ke keranjang belanja'),
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

  void _updateProductQuantity(BuildContext context, Map<String, dynamic> item, int delta) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();
    final prodId = item['id'] as String;
    final storeId = item['kiosId'] as String? ?? 'mch-gage-tani';

    cart.updateQuantity(prodId, delta);
    final currentQty = cart.getItemQuantity(prodId);
    multiCart.updateQuantity(storeId, prodId, currentQty);
  }

  // ===========================================================================
  // DATA KATALOG RESMI GAGE TANI (Saprotan & Hasil Bumi)
  // ===========================================================================
  final List<Map<String, dynamic>> _tokoPertanianItems = [
    {
      'id': 'agr-pupuk-01',
      'name': 'Pupuk NPK Phonska Plus 25 Kg',
      'category': 'Pupuk Makro',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 165000,
      'unit': 'Karung 25kg',
      'desc': 'Pupuk majemuk NPK 15-15-15 + Zinc untuk pertumbuhan optimal padi & jagung.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.grass_rounded,
    },
    {
      'id': 'agr-benih-01',
      'name': 'Bibit Padi Inpari 32 Unggul Bersertifikat 5 Kg',
      'category': 'Benih Unggul',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 65000,
      'unit': 'Pack 5kg',
      'desc': 'Tahan wereng coklat tipe 1, 2, anakan produktif melimpah dan malai padi lebat.',
      'image': 'assets/images/prod_benih.png',
      'icon': Icons.eco_rounded,
    },
    {
      'id': 'agr-benih-02',
      'name': 'Bibit Jagung Hibrida NK 212 Sumo 1 Kg',
      'category': 'Benih Unggul',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 105000,
      'unit': 'Pack 1kg',
      'desc': 'Tongkol besar rapat, tahan kekeringan lahan tegalan, rendemen pipil kering tinggi.',
      'image': 'assets/images/prod_benih.png',
      'icon': Icons.eco_rounded,
    },
    {
      'id': 'agr-obat-01',
      'name': 'Insektisida Alika 247 ZC Pembasmi Hama 250ml',
      'category': 'Obat Hama & Gulma',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 85000,
      'unit': 'Botol 250ml',
      'desc': 'Ampuh tuntaskan ulat grayak, wereng coklat, dan kutu daun dengan knock-down cepat.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.science_rounded,
    },
    {
      'id': 'agr-obat-02',
      'name': 'Fungisida Sistemik Skor 250 EC 250ml',
      'category': 'Obat Hama & Gulma',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 125000,
      'unit': 'Botol 250ml',
      'desc': 'Perlindungan total jamur bercak daun cercospora dan hawar pelepah pada padi & cabai.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.healing_rounded,
    },
    {
      'id': 'agr-poc-01',
      'name': 'Pupuk Organik Cair Hayati GDM 1 Liter',
      'category': 'Pupuk Organik',
      'kios': 'Lapak Resmi Agro GAGE',
      'kiosId': 'mch-agro-praci',
      'price': 48000,
      'unit': 'Botol 1 Liter',
      'desc': 'Bakteri premium pembenah tanah tandus, tingkatkan kesuburan tanah gamping Wonogiri.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.compost_rounded,
    },
  ];

  final List<Map<String, dynamic>> _hasilBumiItems = [
    {
      'id': 'hbm-beras-01',
      'name': 'Beras Mentik Wangi Fresh Giling Sawah 5 Kg',
      'category': 'Beras Premium',
      'kios': 'Gapoktan Binaan GAGE Tubokarto',
      'kiosId': 'mch-gapoktan-tubokarto',
      'price': 75000,
      'unit': 'Pack 5kg',
      'desc': 'Gilingan baru minggu ini, pulen alami, putih bersih tanpa pemutih & wangi pandan alami.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.rice_bowl_rounded,
    },
    {
      'id': 'hbm-jagung-01',
      'name': 'Jagung Pipil Kering Kadar Air 14% 50 Kg',
      'category': 'Pangan Pokok',
      'kios': 'Petani Binaan Gambirmanis',
      'kiosId': 'mch-tani-gambirmanis',
      'price': 260000,
      'unit': 'Karung 50kg',
      'desc': 'Kadar air standar pabrik 14%, biji bersih pipil rapat tanpa bonggol untuk pakan/konsumsi.',
      'image': 'assets/images/prod_benih.png',
      'icon': Icons.grain_rounded,
    },
    {
      'id': 'hbm-cabai-01',
      'name': 'Cabai Rawit Merah Petik Pagi Segar 1 Kg',
      'category': 'Hortikultura',
      'kios': 'Kebun Petani Watangrejo',
      'kiosId': 'mch-tani-watangrejo',
      'price': 35000,
      'unit': 'per Kg',
      'desc': 'Segar petik langsung pagi hari dari kebun Pracimantoro, pedas maksimal tahan simpan.',
      'image': 'assets/images/prod_cabai.png',
      'icon': Icons.local_florist_rounded,
    },
    {
      'id': 'hbm-bawang-01',
      'name': 'Bawang Merah Super Wonogiri Lokal 1 Kg',
      'category': 'Bumbu Dapur',
      'kios': 'Lapak Petani Binaan GAGE',
      'kiosId': 'mch-tani-praci',
      'price': 28000,
      'unit': 'per Kg',
      'desc': 'Umbi bulat padat kering jemur matahari, aroma tajam sedap khas tanah perbukitan kapur.',
      'image': 'assets/images/prod_cabai.png',
      'icon': Icons.spa_rounded,
    },
    {
      'id': 'hbm-singkong-01',
      'name': 'Singkong Gajah Segar Panen Lahan Kering 5 Kg',
      'category': 'Palawija',
      'kios': 'Petani Binaan Suci Pracimantoro',
      'kiosId': 'mch-tani-suci',
      'price': 20000,
      'unit': 'Pack 5kg',
      'desc': 'Daging umbi pulen empuk saat dikukus atau digoreng, tidak pait, panen segar hari ini.',
      'image': 'assets/images/prod_benih.png',
      'icon': Icons.grass_rounded,
    },
  ];

  List<String> get _currentFilterCategories {
    if (_selectedSection == 'toko_pertanian') {
      return ['Semua', 'Pupuk Makro', 'Benih Unggul', 'Obat Hama & Gulma', 'Pupuk Organik'];
    } else {
      return ['Semua', 'Beras Premium', 'Pangan Pokok', 'Hortikultura', 'Bumbu Dapur', 'Palawija'];
    }
  }

  List<Map<String, dynamic>> get _currentCategoryItems {
    final rawList = _selectedSection == 'toko_pertanian' ? _tokoPertanianItems : _hasilBumiItems;
    if (_activeCategoryFilter == 'Semua') return rawList;
    return rawList.where((i) => (i['category'] as String) == _activeCategoryFilter).toList();
  }



  // ===========================================================================
  // KARTU PRODUK KATALOG
  // ===========================================================================
  Widget _buildProductCard(Map<String, dynamic> item, CartProvider cart) {
    final prodId = item['id'] as String;
    final price = item['price'] as int;
    final itemQty = cart.getItemQuantity(prodId);
    final isFav = _favoriteItemIds.contains(prodId);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? GageTheme.darkBorder : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Kolom Kiri: Detail Informasi Produk
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item['category'] as String,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF166534)),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['unit'] as String,
                        style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey.shade400 : Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item['desc'] as String,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.black54,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Text(
                  currencyFormatter.format(price),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16A34A),
                    fontSize: 14.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Kolom Kanan: Foto Thumbnail (88x88) + Heart Badge + Stepper / '+ Tambah'
          Column(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 88,
                      height: 88,
                      child: Image.asset(
                        item['image'] as String? ?? 'assets/images/prod_pupuk.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          color: const Color(0xFFDCFCE7),
                          child: Icon(item['icon'] as IconData? ?? Icons.grass_rounded, color: const Color(0xFF15803D), size: 36),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: InkWell(
                      onTap: () => _toggleFavorite(prodId),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: Icon(
                          isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 14,
                          color: isFav ? Colors.red : Colors.black45,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Stepper or Tambah button (10px Rounded)
              if (itemQty > 0)
                Container(
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () => _updateProductQuantity(context, item, -1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(Icons.remove, color: Color(0xFF16A34A), size: 16),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '$itemQty',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => _updateProductQuantity(context, item, 1),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: Icon(Icons.add, color: Color(0xFF16A34A), size: 16),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    onPressed: () => _addToCart(context, item),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 15),
                        SizedBox(width: 2),
                        Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
            ],
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
    final taniBanner = bannerManager.getBanner('tani');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allItems = _currentCategoryItems;
    final activeItems = allItems.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final name = (item['name'] as String).toLowerCase();
      final cat = (item['category'] as String).toLowerCase();
      final desc = (item['desc'] as String).toLowerCase();
      return q.isEmpty || name.contains(q) || cat.contains(q) || desc.contains(q);
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : GageTheme.background,
      body: Stack(
        children: [
          // 1. Scrollable Content
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Full-bleed Banner 16:9 ke batas atas status bar dengan Typing Bubble di atas search bar
                GageServiceHeroBanner(
                  imageAsset: taniBanner.imagePath,
                  fallbackTitle: 'GAGE TANI',
                  scrollController: _scrollController,
                  overlayChild: AdaptiveSpeechBubble(
                    fullText: 'Konsultasi gratis dokter tanaman, klik di sini',
                    backgroundColor: const Color(0xFF16A34A),
                    icon: Icons.eco_rounded,
                    onTap: _openConsultationWhatsApp,
                  ),
                ),

                const SizedBox(height: 38),

                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [

                          // 3. Switch Kategori Utama: Toko Pertanian vs Hasil Bumi
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSection = 'toko_pertanian';
                                        _activeCategoryFilter = 'Semua';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedSection == 'toko_pertanian'
                                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _selectedSection == 'toko_pertanian'
                                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.storefront_rounded,
                                            size: 16,
                                            color: _selectedSection == 'toko_pertanian' ? const Color(0xFF16A34A) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Toko Pertanian',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: _selectedSection == 'toko_pertanian'
                                                  ? const Color(0xFF16A34A)
                                                  : (isDark ? Colors.white60 : Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _selectedSection = 'hasil_bumi';
                                        _activeCategoryFilter = 'Semua';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedSection == 'hasil_bumi'
                                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _selectedSection == 'hasil_bumi'
                                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.rice_bowl_rounded,
                                            size: 16,
                                            color: _selectedSection == 'hasil_bumi' ? const Color(0xFF16A34A) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Hasil Bumi',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12.5,
                                              color: _selectedSection == 'hasil_bumi'
                                                  ? const Color(0xFF16A34A)
                                                  : (isDark ? Colors.white60 : Colors.black54),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 4. Filter Kategori Chips
                          SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _currentFilterCategories.length,
                              separatorBuilder: (context, index) => const SizedBox(width: 8),
                              itemBuilder: (ctx, idx) {
                                final cat = _currentFilterCategories[idx];
                                final isSel = _activeCategoryFilter == cat;
                                return ChoiceChip(
                                  label: Text(cat),
                                  selected: isSel,
                                  selectedColor: const Color(0xFFDCFCE7),
                                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                                    color: isSel ? const Color(0xFF166534) : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: BorderSide(
                                      color: isSel ? const Color(0xFF86EFAC) : (isDark ? Colors.white12 : Colors.grey.shade300),
                                    ),
                                  ),
                                  onSelected: (_) => setState(() => _activeCategoryFilter = cat),
                                );
                              },
                            ),
                          ),

                          const SizedBox(height: 16),

                          // 5. Section Headline
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Daftar Produk (${activeItems.length})',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13.5,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const Text(
                                  'Diantar Langsung via GAGE',
                                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),

                          // 6. Daftar Produk
                          if (activeItems.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Produk tidak ditemukan untuk pencarian "$_searchQuery"',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (isTablet)
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: screenWidth > 900 ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                mainAxisExtent: 140,
                              ),
                              itemCount: activeItems.length,
                              itemBuilder: (ctx, idx) => _buildProductCard(activeItems[idx], cart),
                            )
                          else
                            ListView.builder(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: activeItems.length,
                              itemBuilder: (ctx, idx) => _buildProductCard(activeItems[idx], cart),
                            ),

                          const SizedBox(height: 90),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Sticky Header: Action Buttons & Seamless Docking Search Bar
          Positioned.fill(
            child: GageServiceStickyHeader(
              scrollController: _scrollController,
              locationText: _formatShortAddress(_deliveryLocation),
              onLocationTap: _showLocationPicker,
              onBackTap: () => Navigator.pop(context),
              onFavoriteTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const TaniFavoriteScreen()),
                );
              },
              onHistoryTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                );
              },
              searchHint: 'Cari benih, pupuk, obat hama, atau hasil panen...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.grass_rounded,
            ),
          ),

          // 3. Floating Cart Overlay Melayang Murni
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SeamlessFloatingCartBar(),
          ),
        ],
      ),
    );
  }
}
