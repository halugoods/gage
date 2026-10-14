import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/adaptive_speech_bubble.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/features/food/presentation/ternak_favorite_screen.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class TernakScreen extends StatefulWidget {
  const TernakScreen({super.key});

  @override
  State<TernakScreen> createState() => _TernakScreenState();
}

class _TernakScreenState extends State<TernakScreen> {
  // Main Switch: 'toko_peternakan' vs 'pasar_ternak'
  String _selectedSection = 'toko_peternakan';
  String _activeCategoryFilter = 'Semua';
  final Set<String> _favoriteItemIds = {};

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _deliveryLocation = 'Kecamatan Pracimantoro, Wonogiri';
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
        setState(() => _deliveryLocation = addr);
      }
    } catch (_) {}
  }

  void _showLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran GAGE Ternak',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _deliveryLocation = title.isNotEmpty ? title : fullAddress;
        });
      },
    );
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
    return addr.trim();
  }

  Future<void> _openWhatsAppConsultation() async {
    final msg = 'Halo Dokter Hewan & Ahli Ternak GAGE Pracimantoro,\n\n'
        'Saya ingin konsultasi peternakan gratis:\n'
        '- Jenis Ternak: Sapi / Kambing / Ayam\n'
        '- Gejala / Kebutuhan Nutrisi:\n'
        '- Lokasi Dusun:\n\n'
        'Mohon bantuan rekomendasi pakan atau obatnya. Terima kasih!';

    final uri = Uri.parse('https://wa.me/6281234567891?text=${Uri.encodeComponent(msg)}');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  // Data Produk: Toko Peternakan
  final List<Map<String, dynamic>> _tokoPeternakanProducts = [
    {
      'id': 'trn-pakan-01',
      'name': 'Pakan Konsentrat Sapi Penggemuk 50 Kg',
      'category': 'Pakan Sapi',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'shopId': 'mch-ternak-barokah',
      'price': 195000,
      'unit': 'Karung 50kg',
      'desc': 'Konsentrat protein tinggi 14% untuk percepatan bobot sapi potong.',
      'icon': Icons.pets_rounded,
    },
    {
      'id': 'trn-katul-02',
      'name': 'Katul Padi / Dedak Halus Super (Karung 40 Kg)',
      'category': 'Katul & Polar',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'shopId': 'mch-ternak-barokah',
      'price': 140000,
      'unit': 'Karung 40kg',
      'desc': 'Katul gilingan pertama tanpa sekam, sangat disukai sapi dan kambing.',
      'icon': Icons.grain_rounded,
    },
    {
      'id': 'trn-ayam-03',
      'name': 'Pakan Ayam Petelur KLK 50 Kg',
      'category': 'Pakan Unggas',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'shopId': 'mch-ternak-barokah',
      'price': 380000,
      'unit': 'Karung 50kg',
      'desc': 'Pakan lengkap bernutrisi seimbang untuk produksi telur maksimal.',
      'icon': Icons.egg_rounded,
    },
    {
      'id': 'trn-vit-04',
      'name': 'Mineral & Premix Vitamin Sapi/Kambing (1 Kg)',
      'category': 'Vitamin & Suplemen',
      'shop': 'Poultry Shop Barokah Ternak Praci',
      'shopId': 'mch-ternak-barokah',
      'price': 28000,
      'unit': 'Bungkus 1kg',
      'desc': 'Cegah lumpuh, kalsium tinggi, memperkuat tulang ternak.',
      'icon': Icons.medication_rounded,
    },
  ];

  // Data Produk: Pasar Ternak (Sentra Pasar Hewan Pracimantoro)
  final List<Map<String, dynamic>> _pasarTernakProducts = [
    {
      'id': 'trn-kambing-01',
      'name': 'Kambing Jawa Randu Jantan Siap Qurban/Aqiqah',
      'category': 'Kambing & Domba',
      'shop': 'Peternak Tubokarto Mandiri',
      'shopId': 'mch-ternak-tubokarto',
      'price': 2400000,
      'unit': 'Ekor (Bobot ~30kg)',
      'desc': 'Sehat, cukup umur, bersertifikat sehat dari dokter hewan.',
      'icon': Icons.pets_rounded,
    },
    {
      'id': 'trn-telur-02',
      'name': 'Telur Ayam Kampung Segar (Tray 30 Butir)',
      'category': 'Hasil Ternak',
      'shop': 'Lapak Telur Sentra Pasar Wage',
      'shopId': 'mch-pasar-wage',
      'price': 65000,
      'unit': 'Tray 30 Butir',
      'desc': 'Telur ayam kampung murni kualitas terbaik segar langsung dari kandang.',
      'icon': Icons.egg_alt_rounded,
    },
    {
      'id': 'trn-susu-03',
      'name': 'Susu Kambing Etawa Segar Murni 1 Liter',
      'category': 'Hasil Ternak',
      'shop': 'Peternak Tubokarto Mandiri',
      'shopId': 'mch-ternak-tubokarto',
      'price': 35000,
      'unit': 'Botol 1 Liter',
      'desc': 'Tanpa bahan pengawet, tinggi nutrisi untuk kesehatan pernapasan.',
      'icon': Icons.local_drink_rounded,
    },
  ];

  List<Map<String, dynamic>> get _currentProducts {
    final list = _selectedSection == 'toko_peternakan' ? _tokoPeternakanProducts : _pasarTernakProducts;
    return list.where((p) {
      final matchesSearch = _searchQuery.isEmpty ||
          p['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCat = _activeCategoryFilter == 'Semua' || p['category'] == _activeCategoryFilter;
      return matchesSearch && matchesCat;
    }).toList();
  }

  List<String> get _currentCategories {
    if (_selectedSection == 'toko_peternakan') {
      return ['Semua', 'Pakan Sapi', 'Katul & Polar', 'Pakan Unggas', 'Vitamin & Suplemen'];
    } else {
      return ['Semua', 'Kambing & Domba', 'Hasil Ternak'];
    }
  }

  void _toggleFavorite(String itemId) {
    setState(() {
      if (_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.remove(itemId);
      } else {
        _favoriteItemIds.add(itemId);
      }
    });
    GageToast.show(
      context,
      _favoriteItemIds.contains(itemId) ? 'Ditambahkan ke favorit' : 'Dihapus dari favorit',
      type: _favoriteItemIds.contains(itemId) ? GageToastType.success : GageToastType.info,
    );
  }

  void _updateProductQuantity(BuildContext context, Map<String, dynamic> item, int delta) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();
    final prodId = item['id'] as String;
    final storeId = item['shopId'] as String? ?? 'mch-gage-ternak';

    cart.updateQuantity(prodId, delta);
    final currentQty = cart.getItemQuantity(prodId);
    multiCart.updateQuantity(storeId, prodId, currentQty);
  }

  void _addToCart(BuildContext context, Map<String, dynamic> item) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();
    final storeId = item['shopId'] as String? ?? 'mch-gage-ternak';
    final storeName = item['shop'] as String? ?? 'GAGE Ternak';

    final cartItem = CartItem(
      id: item['id'] as String,
      name: item['name'] as String,
      price: item['price'] as int,
      quantity: 1,
      storeId: storeId,
      storeName: storeName,
      category: item['category'] as String? ?? 'Ternak',
      image: '',
      menuOrigin: 'tani',
    );

    final cartItemModel = CartItemModel(
      menuId: item['id'] as String,
      merchantId: storeId,
      merchantName: storeName,
      name: item['name'] as String,
      price: item['price'] as int,
      quantity: 1,
      category: item['category'] as String? ?? 'Ternak',
      imageUrl: null,
      serviceType: 'tani',
    );

    final success = multiCart.addItem(cartItem);
    if (!success) {
      GageToast.show(
        context,
        multiCart.lastErrorMessage ?? 'Maksimal 3 toko berbeda dalam satu keranjang belanja.',
        type: GageToastType.warning,
      );
      return;
    }

    cart.addItem(cartItemModel);
    GageToast.show(
      context,
      '${item['name']} ditambahkan ke keranjang belanja',
      type: GageToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final cart = context.watch<CartProvider>();

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
                  imageAsset: 'assets/images/ternak_hero_banner.png',
                  fallbackTitle: 'GAGE TERNAK',
                  scrollController: _scrollController,
                  overlayChild: AdaptiveSpeechBubble(
                    fullText: 'Konsultasi gratis dokter hewan, klik di sini',
                    backgroundColor: const Color(0xFFD97706),
                    icon: Icons.medical_services_rounded,
                    onTap: _openWhatsAppConsultation,
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

                          // Switch Utama: Toko Peternakan vs Pasar Ternak
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
                                        _selectedSection = 'toko_peternakan';
                                        _activeCategoryFilter = 'Semua';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedSection == 'toko_peternakan'
                                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _selectedSection == 'toko_peternakan'
                                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.store_mall_directory_rounded,
                                            size: 16,
                                            color: _selectedSection == 'toko_peternakan' ? const Color(0xFFD97706) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Toko Peternakan',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedSection == 'toko_peternakan'
                                                  ? const Color(0xFFD97706)
                                                  : (isDark ? Colors.white60 : Colors.grey.shade700),
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
                                        _selectedSection = 'pasar_ternak';
                                        _activeCategoryFilter = 'Semua';
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 9),
                                      decoration: BoxDecoration(
                                        color: _selectedSection == 'pasar_ternak'
                                            ? (isDark ? const Color(0xFF0F172A) : Colors.white)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(11),
                                        boxShadow: _selectedSection == 'pasar_ternak'
                                            ? const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 1))]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.pets_rounded,
                                            size: 16,
                                            color: _selectedSection == 'pasar_ternak' ? const Color(0xFFD97706) : Colors.grey,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Pasar Ternak',
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: _selectedSection == 'pasar_ternak'
                                                  ? const Color(0xFFD97706)
                                                  : (isDark ? Colors.white60 : Colors.grey.shade700),
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

                          // Filter Kategori Horizontal di dalam Switch
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _currentCategories.map((cat) {
                                final isSelected = _activeCategoryFilter == cat;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: FilterChip(
                                    label: Text(cat),
                                    selected: isSelected,
                                    onSelected: (_) => setState(() => _activeCategoryFilter = cat),
                                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                    selectedColor: const Color(0xFFFEF3C7),
                                    checkmarkColor: const Color(0xFFD97706),
                                    labelStyle: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? const Color(0xFFD97706)
                                          : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      side: BorderSide(
                                        color: isSelected
                                            ? const Color(0xFFD97706)
                                            : (isDark ? Colors.white12 : Colors.grey.shade300),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // List Produk Ternak
                          if (_currentProducts.isEmpty)
                            Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Produk ternak tidak ditemukan untuk "$_searchQuery"',
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: _currentProducts.length,
                              itemBuilder: (ctx, idx) {
                                final prod = _currentProducts[idx];
                                final prodId = prod['id'] as String;
                                final itemQty = cart.getItemQuantity(prodId);
                                final isFav = _favoriteItemIds.contains(prodId);
                                final price = prod['price'] as int;

                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkSurface : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: isDark ? Colors.white12 : Colors.grey.shade200,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Kolom Kiri: Info Produk, Toko, Deskripsi & Harga
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFFFEF3C7),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    prod['category'] as String? ?? 'Ternak',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                      color: Color(0xFFD97706),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    '${prod['shop']} • ${prod['unit']}',
                                                    style: TextStyle(fontSize: 10.5, color: isDark ? Colors.grey.shade400 : Colors.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              prod['name'] as String,
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
                                              prod['desc'] as String? ?? '',
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
                                                color: Color(0xFFD97706),
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
                                                child: Container(
                                                  width: 88,
                                                  height: 88,
                                                  color: const Color(0xFFFEF3C7),
                                                  child: Icon(
                                                    prod['icon'] as IconData? ?? Icons.pets_rounded,
                                                    color: const Color(0xFFD97706),
                                                    size: 36,
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
                                                border: Border.all(color: const Color(0xFFD97706), width: 1.5),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  InkWell(
                                                    onTap: () => _updateProductQuantity(context, prod, -1),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      child: Icon(Icons.remove, color: Color(0xFFD97706), size: 16),
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
                                                    onTap: () => _updateProductQuantity(context, prod, 1),
                                                    child: const Padding(
                                                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                      child: Icon(Icons.add, color: Color(0xFFD97706), size: 16),
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
                                                  backgroundColor: const Color(0xFFD97706),
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                                ),
                                                onPressed: () => _addToCart(context, prod),
                                                child: const Text(
                                                  '+ Tambah',
                                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                );
                              },
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
                  MaterialPageRoute(builder: (ctx) => const TernakFavoriteScreen()),
                );
              },
              onHistoryTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const OrdersScreen()),
                );
              },
              searchHint: 'Cari pakan, suplemen, kambing, atau telur...',
              searchController: _searchController,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.pets_rounded,
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
