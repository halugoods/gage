import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';

class ShopStoreDetailScreen extends StatefulWidget {
  final Map<String, dynamic> store;

  const ShopStoreDetailScreen({
    super.key,
    required this.store,
  });

  @override
  State<ShopStoreDetailScreen> createState() => _ShopStoreDetailScreenState();
}

class _ShopStoreDetailScreenState extends State<ShopStoreDetailScreen> {
  String _selectedCategory = 'Semua';
  late final List<Map<String, dynamic>> _catalog;

  @override
  void initState() {
    super.initState();
    _catalog = _generateStoreCatalog(widget.store['id'] ?? 'ret-berkah-01');
  }

  List<Map<String, dynamic>> _generateStoreCatalog(String storeId) {
    if (storeId == 'shop-berkah-fajar' || storeId == 'ret-berkah-01' || storeId == 'ret-sembako-01') {
      return [
        {
          'id': 'prod-beras-5kg',
          'name': 'Beras C4 Super Raja 5 Kg',
          'category': 'Sembako & Beras',
          'price': 72000,
          'unit': '5 kg',
          'image': 'assets/images/prod_beras.png',
          'desc': 'Beras pulen pilihan petani Wonogiri, putih alami tanpa pemutih.',
        },
        {
          'id': 'prod-minyak-2l',
          'name': 'Minyak Goreng Bimoli Klasik 2 Liter',
          'category': 'Minyak & Bumbu',
          'price': 38500,
          'unit': 'Pouch 2L',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Minyak sawit murni jernih dua kali penyaringan.',
        },
        {
          'id': 'prod-gula-1kg',
          'name': 'Gula Pasir Kristal Putih Gulaku 1 Kg',
          'category': 'Sembako & Beras',
          'price': 18000,
          'unit': '1 kg',
          'image': 'assets/images/prod_gula.png',
          'desc': 'Gula tebu kristal premium manis alami higienis.',
        },
        {
          'id': 'prod-telur-1kg',
          'name': 'Telur Ayam Negeri Segar Peternak Lokal 1 Kg',
          'category': 'Sembako & Beras',
          'price': 28000,
          'unit': '1 kg (~16 butir)',
          'image': 'assets/images/prod_telur.png',
          'desc': 'Telur ayam fresh baru panen pagi hari dari peternak kandang.',
        },
        {
          'id': 'prod-terigu-1kg',
          'name': 'Tepung Terigu Segitiga Biru 1 Kg',
          'category': 'Sembako & Beras',
          'price': 13500,
          'unit': '1 kg',
          'image': 'assets/images/prod_beras.png',
          'desc': 'Tepung terigu serbaguna untuk gorengan dan aneka olahan.',
        },
        {
          'id': 'prod-kecap-bango',
          'name': 'Kecap Manis Bango Refill 520ml',
          'category': 'Minyak & Bumbu',
          'price': 22500,
          'unit': '520 ml',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Kecap manis kedelai hitam mallika kental gurih.',
        },
        {
          'id': 'prod-garam-daun',
          'name': 'Garam Beryodium Cap Daun 250g',
          'category': 'Minyak & Bumbu',
          'price': 3500,
          'unit': '250 gram',
          'image': 'assets/images/prod_gula.png',
          'desc': 'Garam halus beryodium murni standar kesehatan.',
        },
      ];
    } else if (storeId == 'shop-kelontong-bu-sri') {
      return [
        {
          'id': 'prod-beras-delanggu',
          'name': 'Beras Pulen Raja Delanggu 5 Kg',
          'category': 'Sembako & Beras',
          'price': 74000,
          'unit': '5 kg',
          'image': 'assets/images/prod_beras.png',
          'desc': 'Beras wangi khas Delanggu pulen lezat.',
        },
        {
          'id': 'prod-minyak-fortune',
          'name': 'Minyak Goreng Fortune Pouch 2 Liter',
          'category': 'Minyak & Bumbu',
          'price': 36500,
          'unit': 'Pouch 2L',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Minyak goreng fortified vitamin A & E higienis.',
        },
        {
          'id': 'prod-kopi-kapal-api',
          'name': 'Kopi Kapal Api Spesial Mix (10 Sachet)',
          'category': 'Makanan Ringan',
          'price': 14500,
          'unit': 'Renceng 10 Sachet',
          'image': 'assets/images/prod_gula.png',
          'desc': 'Kopi hitam bubuk plus gula mantap khas kapal api.',
        },
        {
          'id': 'prod-biskuit-roma',
          'name': 'Biskuit Roma Kelapa 300 Gram',
          'category': 'Makanan Ringan',
          'price': 11500,
          'unit': '300 gram',
          'image': 'assets/images/hero_promo_2.png',
          'desc': 'Biskuit kelapa renyah gurih teman ngeteh.',
        },
        {
          'id': 'prod-kerupuk-bawang',
          'name': 'Kerupuk Bawang Renyah Gurih 250g',
          'category': 'Makanan Ringan',
          'price': 8000,
          'unit': '250 gram',
          'image': 'assets/images/prod_telur.png',
          'desc': 'Kerupuk mentah siap goreng mekar gurih sedap.',
        },
        {
          'id': 'prod-daia-putih',
          'name': 'Deterjen Bubuk Daia Putih 850g',
          'category': 'Sabun & Kebersihan',
          'price': 18500,
          'unit': '850 gram',
          'image': 'assets/images/hero_banner_1.png',
          'desc': 'Deterjen pembersih noda pakaian wangi tahan lama.',
        },
      ];
    } else if (storeId == 'shop-minimarket-losari' || storeId == 'ret-sumber-02' || storeId == 'ret-mart-02' || storeId == 'ret-mart-03') {
      return [
        {
          'id': 'prod-susu-uht',
          'name': 'Susu UHT Ultra Milk Cokelat 1 Liter',
          'category': 'Makanan Ringan',
          'price': 19500,
          'unit': '1 Liter',
          'image': 'assets/images/prod_gula.png',
          'desc': 'Susu sapi segar kaya kalsium dan vitamin.',
        },
        {
          'id': 'prod-mie-dus',
          'name': 'Indomie Goreng Spesial 1 Dus (40 Pcs)',
          'category': 'Makanan Ringan',
          'price': 118000,
          'unit': 'Dus (40 pcs)',
          'image': 'assets/images/prod_indomie.png',
          'desc': 'Mi instan goreng favorit Indonesia harga hemat.',
        },
        {
          'id': 'prod-chiki-taro',
          'name': 'Chiki Taro Net Seaweed 65g',
          'category': 'Makanan Ringan',
          'price': 8500,
          'unit': 'Pack 65g',
          'image': 'assets/images/hero_promo_2.png',
          'desc': 'Snack kentang gurih rasa rumput laut.',
        },
        {
          'id': 'prod-sunlight-700ml',
          'name': 'Sunlight Jeruk Nipis Cuci Piring 700ml',
          'category': 'Sabun & Kebersihan',
          'price': 14000,
          'unit': 'Pouch 700ml',
          'image': 'assets/images/hero_banner_1.png',
          'desc': 'Pembersih lemak bandel wangi segar jeruk nipis.',
        },
        {
          'id': 'prod-sabun-lifebuoy',
          'name': 'Sabun Mandi Lifebuoy Total 10 (Pack 4x85g)',
          'category': 'Sabun & Kebersihan',
          'price': 16500,
          'unit': 'Pack 4 Bar',
          'image': 'assets/images/hero_promo_1.png',
          'desc': 'Perlindungan kuman antibakteri alami untuk keluarga.',
        },
        {
          'id': 'prod-shampo-pantene',
          'name': 'Shampo Pantene Anti Dandruff 160ml',
          'category': 'Sabun & Kebersihan',
          'price': 24000,
          'unit': 'Botol 160ml',
          'image': 'assets/images/hero_banner_2.png',
          'desc': 'Shampo perawatan rambut bebas ketombe segar berkilau.',
        },
      ];
    } else if (storeId == 'shop-grosir-sentosa') {
      return [
        {
          'id': 'prod-indomie-dus-sentosa',
          'name': 'Indomie Goreng Spesial 1 Dus (40 Pcs)',
          'category': 'Makanan Ringan',
          'price': 118000,
          'unit': 'Dus (40 pcs)',
          'image': 'assets/images/prod_indomie.png',
          'desc': 'Grosir mi instan goreng kartonan segel pabrik.',
        },
        {
          'id': 'prod-indomie-soto-dus',
          'name': 'Indomie Rasa Soto Mie 1 Dus (40 Pcs)',
          'category': 'Makanan Ringan',
          'price': 115000,
          'unit': 'Dus (40 pcs)',
          'image': 'assets/images/prod_indomie.png',
          'desc': 'Mi instan kuah soto gurih segar kuah sedap.',
        },
        {
          'id': 'prod-minyak-karton',
          'name': 'Minyak Bimoli Karton (6 Pouch x 2L)',
          'category': 'Minyak & Bumbu',
          'price': 228000,
          'unit': 'Karton 12L',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Kartonan minyak goreng murah untuk warung dan hajatan.',
        },
        {
          'id': 'prod-beras-sak-25kg',
          'name': 'Beras C4 Super Karung Sak 25 Kg',
          'category': 'Sembako & Beras',
          'price': 355000,
          'unit': 'Karung 25kg',
          'image': 'assets/images/prod_beras.png',
          'desc': 'Karungan beras kualitas super pulen asli Pracimantoro.',
        },
        {
          'id': 'prod-gula-sak-25kg',
          'name': 'Gula Pasir Kristal Putih Sak 25 Kg',
          'category': 'Sembako & Beras',
          'price': 435000,
          'unit': 'Karung 25kg',
          'image': 'assets/images/prod_gula.png',
          'desc': 'Gula pasir kristal putih murni sak grosir resmi.',
        },
      ];
    } else if (storeId == 'shop-sayur-bu-marti' || storeId == 'ret-sayur-03' || storeId == 'ret-sayur-04' || storeId == 'ret-bumbu-06') {
      return [
        {
          'id': 'prod-sayur-bayam',
          'name': 'Sayur Bayam Cabut Segar Petani Lokal (3 Ikat)',
          'category': 'Sembako & Beras',
          'price': 6000,
          'unit': '3 Ikat',
          'image': 'assets/images/prod_cabai.png',
          'desc': 'Bayam hijau segar tanpa pestisida kimia panen pagi.',
        },
        {
          'id': 'prod-cabai-rawit',
          'name': 'Cabai Rawit Merah Pedas Segar 250 Gram',
          'category': 'Minyak & Bumbu',
          'price': 14000,
          'unit': '250 gram',
          'image': 'assets/images/prod_cabai.png',
          'desc': 'Cabai rawit merah petik segar pedas mantap.',
        },
        {
          'id': 'prod-bawang-merah',
          'name': 'Bawang Merah Brebes Pilihan 500 Gram',
          'category': 'Minyak & Bumbu',
          'price': 19000,
          'unit': '500 gram',
          'image': 'assets/images/prod_cabai.png',
          'desc': 'Bawang merah kering bersih wangi tajam masakan nusantara.',
        },
        {
          'id': 'prod-tomat-segar',
          'name': 'Tomat Buah Segar Kualitas Super 1 Kg',
          'category': 'Minyak & Bumbu',
          'price': 11000,
          'unit': '1 kg',
          'image': 'assets/images/prod_cabai.png',
          'desc': 'Tomat merah matang pohon segar untuk jus dan sambal.',
        },
        {
          'id': 'prod-bumbu-racik',
          'name': 'Aneka Bumbu Racik Masak Nusantara (Pack 5 Pcs)',
          'category': 'Minyak & Bumbu',
          'price': 10000,
          'unit': 'Pack 5 Pcs',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Bumbu instan komplit ayam goreng, lodeh, dan sop.',
        },
      ];
    } else {
      return [
        {
          'id': 'prod-gas-3kg',
          'name': 'Gas Elpiji Melon 3 Kg (Tukar Tabung)',
          'category': 'Sembako & Beras',
          'price': 22000,
          'unit': 'Tabung 3kg',
          'image': 'assets/images/prod_beras.png',
          'desc': 'Gas LPG subsidi resmi aman dan berbobot pas.',
        },
        {
          'id': 'prod-galon-aqua',
          'name': 'Air Mineral Galon Aqua 19 Liter (Refill)',
          'category': 'Sembako & Beras',
          'price': 20000,
          'unit': 'Galon 19L',
          'image': 'assets/images/prod_minyak.png',
          'desc': 'Air mineral pegunungan asli kemasan galon resmi.',
        },
        {
          'id': 'prod-sunlight-refill',
          'name': 'Sunlight Jeruk Nipis Cuci Piring 700ml',
          'category': 'Sabun & Kebersihan',
          'price': 14000,
          'unit': 'Pouch 700ml',
          'image': 'assets/images/hero_banner_1.png',
          'desc': 'Pembersih lemak bandel wangi segar jeruk nipis.',
        },
      ];
    }
  }

  List<String> get _categories {
    final set = {'Semua'};
    for (var p in _catalog) {
      final c = p['category'];
      if (c != null && c.toString().isNotEmpty) {
        set.add(c.toString());
      }
    }
    return set.toList();
  }

  List<Map<String, dynamic>> get _filteredCatalog {
    if (_selectedCategory == 'Semua') return _catalog;
    return _catalog.where((p) => p['category'] == _selectedCategory).toList();
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.store['phone_wa'] ?? '081234567890';
    final name = widget.store['name'] ?? 'Toko';
    final uri = Uri.parse('https://wa.me/$phone?text=Halo%20${Uri.encodeComponent(name)},%20saya%20mau%20tanya%20stok%20belanja%20di%20GAGE');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final storeName = widget.store['name'] ?? 'Toko Mitra Resmi';
    final storeAddress = widget.store['address'] ?? 'Kecamatan Pracimantoro';
    final storeDistance = widget.store['distance'] ?? '1.0 km';
    final storeRating = widget.store['rating'] ?? 4.9;
    final storeId = widget.store['id'] ?? 'ret-berkah-01';
    final storeImage = widget.store['image'] ?? 'assets/images/shop_banner_1.png';

    return Scaffold(
      backgroundColor: GageTheme.background,
      body: CustomScrollView(
        slivers: [
          // Header Sliver AppBar 16:9
          SliverAppBar(
            expandedHeight: 200.0,
            pinned: true,
            backgroundColor: GageTheme.primary,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    storeImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black38, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                storeName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.white,
                  shadows: [
                    Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 1)),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Tautan $storeName siap dibagikan!')),
                  );
                },
              ),
            ],
          ),

          // Detail Toko Info Card
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GageTheme.primaryLight,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'MITRA RESMI GAGE',
                          style: TextStyle(color: GageTheme.primary, fontSize: 10.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'BUKA',
                          style: TextStyle(color: Colors.green.shade700, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Spacer(),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GageTheme.accentGreen,
                          side: const BorderSide(color: GageTheme.accentGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: _openWhatsApp,
                        icon: const Icon(Icons.chat_bubble_outline_rounded, size: 16),
                        label: const Text('Chat Toko', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: GageTheme.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(storeAddress, style: const TextStyle(color: GageTheme.textSecondary, fontSize: 12)),
                      ),
                      Text('• $storeDistance (⭐ $storeRating)', style: const TextStyle(color: GageTheme.accentGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Kategori Filter Chips
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: _categories.map((cat) {
                    final isSel = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: FilterChip(
                        selected: isSel,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          color: isSel ? Colors.white : GageTheme.textPrimary,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                        selectedColor: GageTheme.primary,
                        backgroundColor: Colors.grey.shade100,
                        checkmarkColor: Colors.white,
                        onSelected: (_) => setState(() => _selectedCategory = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Daftar Produk Katalog Toko
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prod = _filteredCatalog[index];
                  final price = prod['price'] as int;
                  final prodId = prod['id'] as String;
                  final itemQty = cart.getItemQuantity(prodId);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Thumbnail Produk
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: SizedBox(
                              width: 78,
                              height: 78,
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
                          const SizedBox(width: 12),

                          // Info Produk & Harga
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod['name'],
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Satuan: ${prod['unit']}',
                                  style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                ),
                                if (prod['desc'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2.0),
                                    child: Text(
                                      prod['desc'],
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Text(
                                  currencyFormatter.format(price),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 14),
                                ),
                              ],
                            ),
                          ),

                          // Tombol Tambah / Stepper
                          Column(
                            children: [
                              itemQty > 0
                                  ? Container(
                                      height: 32,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(color: GageTheme.primary, width: 1.5),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          InkWell(
                                            onTap: () {
                                              cart.updateQuantity(prodId, -1);
                                              final newQty = cart.getItemQuantity(prodId);
                                              MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                            },
                                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.remove, color: GageTheme.primary, size: 16),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 4),
                                            child: Text(
                                              '$itemQty',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () {
                                              cart.updateQuantity(prodId, 1);
                                              final newQty = cart.getItemQuantity(prodId);
                                              MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                            },
                                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                            child: const Padding(
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              child: Icon(Icons.add, color: GageTheme.primary, size: 16),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : SizedBox(
                                      height: 32,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GageTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: const EdgeInsets.symmetric(horizontal: 14),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                        onPressed: () {
                                          final added = cart.addItem(
                                            CartItemModel(
                                              menuId: prodId,
                                              merchantId: storeId,
                                              merchantName: storeName,
                                              name: prod['name'],
                                              price: price,
                                              quantity: 1,
                                              category: prod['category'] ?? 'Sembako',
                                              imageUrl: prod['image'],
                                              serviceType: 'shop',
                                            ),
                                          );
                                          if (!added) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                backgroundColor: Colors.orange,
                                                content: Text('Maksimal 3 toko berbeda dalam satu kali pengantaran.'),
                                              ),
                                            );
                                          } else {
                                            MultiMerchantCartService.instance.addItem(
                                              CartItem(
                                                id: prodId,
                                                name: prod['name'],
                                                price: price,
                                                quantity: 1,
                                                storeId: storeId,
                                                storeName: storeName,
                                                category: prod['category'] ?? 'Sembako',
                                                image: prod['image'] ?? '',
                                                menuOrigin: 'shop',
                                              ),
                                            );
                                          }
                                        },
                                        child: const Text('+ Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                      ),
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: _filteredCatalog.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 90)),
        ],
      ),

      // Sticky Bottom Cart Bar
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
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cart.totalItemCount} Barang (${cart.merchantCount} Toko)',
                          style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary, fontWeight: FontWeight.bold),
                        ),
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
                          Text('Lihat Keranjang', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 6),
                          Icon(Icons.arrow_forward_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
