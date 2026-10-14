import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'shop_favorite_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

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
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  bool _isHeaderCollapsed = false;
  bool _isFavorite = false;
  final Map<String, String> _tempNotes = {};
  late final List<Map<String, dynamic>> _catalog;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _catalog = _generateStoreCatalog(widget.store['id'] ?? 'ret-berkah-01');
    _loadFavoriteStatus();
  }

  void _onScroll() {
    final offset = _scrollController.hasClients ? _scrollController.offset : 0.0;
    final isCollapsed = offset > 140;
    if (isCollapsed != _isHeaderCollapsed) {
      setState(() {
        _isHeaderCollapsed = isCollapsed;
      });
    }
  }

  Future<void> _loadFavoriteStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.store['id'] ?? 'ret-berkah-01';
    if (mounted) {
      setState(() {
        _isFavorite = prefs.getBool('fav_shop_$id') ?? false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final prefs = await SharedPreferences.getInstance();
    final id = widget.store['id'] ?? 'ret-berkah-01';
    final newVal = !_isFavorite;
    await prefs.setBool('fav_shop_$id', newVal);
    if (mounted) {
      setState(() => _isFavorite = newVal);
      GageToast.show(
        context,
        newVal ? 'Toko disimpan ke Favorit' : 'Toko dihapus dari Favorit',
        type: newVal ? GageToastType.success : GageToastType.info,
      );
    }
  }

  void _showShareBottomSheet(BuildContext context, String storeName, String storeAddress) {
    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.share_rounded, color: GageTheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bagikan $storeName',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        storeAddress,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.black54),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.pop(ctx),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded, size: 18, color: isDark ? Colors.white70 : Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildShareAction(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () {
                    Navigator.pop(ctx);
                    GageToast.show(context, 'Tautan dibagikan ke WhatsApp', type: GageToastType.success);
                  },
                ),
                _buildShareAction(
                  icon: Icons.copy_rounded,
                  label: 'Salin Tautan',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(ctx);
                    GageToast.show(context, 'Tautan toko berhasil disalin!', type: GageToastType.success);
                  },
                ),
                _buildShareAction(
                  icon: Icons.share_location_rounded,
                  label: 'Bagikan Lokasi',
                  color: const Color(0xFFF97316),
                  onTap: () {
                    Navigator.pop(ctx);
                    GageToast.show(context, 'Lokasi toko siap dibagikan', type: GageToastType.info);
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildShareAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
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
    var list = _selectedCategory == 'Semua'
        ? _catalog
        : _catalog.where((p) => p['category'] == _selectedCategory).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        final name = (p['name'] ?? '').toString().toLowerCase();
        final desc = (p['desc'] ?? '').toString().toLowerCase();
        final cat = (p['category'] ?? '').toString().toLowerCase();
        return name.contains(q) || desc.contains(q) || cat.contains(q);
      }).toList();
    }
    return list;
  }

  Future<void> _openWhatsApp() async {
    final phone = widget.store['phone_wa'] ?? '081234567890';
    final name = widget.store['name'] ?? 'Toko';
    final uri = Uri.parse('https://wa.me/$phone?text=Halo%20${Uri.encodeComponent(name)},%20saya%20mau%20tanya%20stok%20belanja%20di%20GAGE');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showJadwalinSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? selectedTime = cart.scheduledDeliveryTime;

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final options = [
              {'label': 'Kirim Sekarang', 'sub': 'Estimasi tiba 20-30 menit', 'time': null},
              {
                'label': 'Hari Ini, 1 Jam Lagi',
                'sub': DateFormat('HH:mm').format(DateTime.now().add(const Duration(hours: 1))),
                'time': DateTime.now().add(const Duration(hours: 1)),
              },
              {
                'label': 'Siang Ini (12:00 WIB)',
                'sub': 'Pesanan belanja disiapkan tepat waktu',
                'time': DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, 12, 0),
              },
              {
                'label': 'Besok Pagi (08:00 WIB)',
                'sub': 'Sembako dan sayur segar langsung diantar',
                'time': DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 1, 8, 0),
              },
            ];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwal Pengantaran Belanja',
                      style: TextStyle(
                        fontSize: 16.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.pop(ctx),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Pilih kapan toko harus menyiapkan dan mengantar pesanan belanja Anda.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ...options.map((opt) {
                  final target = opt['time'] as DateTime?;
                  final isSelected = (target == null && selectedTime == null) ||
                      (target != null && selectedTime != null &&
                          target.hour == selectedTime!.hour &&
                          target.day == selectedTime!.day);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                          : (isDark ? const Color(0xFF1E293B) : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? GageTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      onTap: () => setSheetState(() => selectedTime = target),
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? GageTheme.primary.withValues(alpha: 0.12)
                              : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          target == null ? Icons.bolt_rounded : Icons.schedule_rounded,
                          color: isSelected ? GageTheme.primary : Colors.grey.shade600,
                          size: 19,
                        ),
                      ),
                      title: Text(
                        opt['label'] as String,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      subtitle: Text(
                        opt['sub'] as String,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                      ),
                      trailing: Icon(
                        isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: isSelected ? GageTheme.primary : Colors.grey,
                        size: 20,
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      cart.setScheduledDeliveryTime(selectedTime);
                      Navigator.pop(ctx);
                      GageToast.show(
                        context,
                        selectedTime != null
                            ? 'Pengantaran belanja dijadwalkan pukul ${DateFormat('HH:mm').format(selectedTime!)} WIB'
                            : 'Pengantaran diatur langsung (Kirim Sekarang)',
                        type: GageToastType.info,
                      );
                    },
                    child: const Text('Simpan Jadwal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildInteractiveVoucherCard({
    required BuildContext context,
    required CartProvider cart,
    required String code,
    required String title,
    required String sub,
    required int discount,
    required bool isFood,
    required bool isDark,
  }) {
    final isApplied = isFood ? (cart.foodPromoCode == code) : (cart.deliveryPromoCode == code);

    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isDark ? GageTheme.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isApplied ? GageTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade200),
          width: isApplied ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          if (isApplied) {
            if (isFood) {
              cart.removeFoodPromo();
            } else {
              cart.removeDeliveryPromo();
            }
            GageToast.show(
              context,
              'Voucher $code dilepas',
              type: GageToastType.info,
            );
          } else {
            if (isFood) {
              cart.setFoodPromo(code, discount);
            } else {
              cart.setDeliveryPromo(code, discount);
            }
            GageToast.show(
              context,
              'Voucher $code berhasil diterapkan!',
              type: GageToastType.success,
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isApplied ? const Color(0xFF16A34A) : GageTheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isApplied ? Icons.check_rounded : Icons.percent_rounded,
                  color: Colors.white,
                  size: 13,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey.shade400 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                isApplied ? 'Batal' : 'Pakai',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isApplied ? Colors.red.shade700 : GageTheme.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final storeName = widget.store['name'] ?? 'Toko Mitra Resmi';
    final storeAddress = widget.store['address'] ?? 'Kecamatan Pracimantoro';
    final storeDistance = widget.store['distance'] ?? '1.0 km';
    final storeRating = widget.store['rating'] ?? 4.9;
    final storeId = widget.store['id'] ?? 'ret-berkah-01';
    final storeImage = widget.store['image'] ?? 'assets/images/shop_banner_1.png';

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8F9FA),
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              // Header Sliver AppBar dengan Scroll Morphing Header
              SliverAppBar(
                expandedHeight: 180.0,
                pinned: true,
                backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                foregroundColor: _isHeaderCollapsed ? (isDark ? Colors.white : Colors.black87) : Colors.white,
                elevation: _isHeaderCollapsed ? 1.0 : 0.0,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 14.0),
                  child: Center(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: _isHeaderCollapsed ? (isDark ? GageTheme.darkCard : Colors.white) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark ? GageTheme.darkBorder : Colors.black12,
                            width: 0.8,
                          ),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
                titleSpacing: _isHeaderCollapsed ? 8 : NavigationToolbar.kMiddleSpacing,
                title: _isHeaderCollapsed
                    ? Padding(
                        padding: const EdgeInsets.only(right: 14.0),
                        child: Container(
                          height: 38,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              width: 0.8,
                            ),
                          ),
                          child: TextField(
                            controller: _searchController,
                            autofocus: false,
                            textAlignVertical: TextAlignVertical.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Cari produk di $storeName...',
                              hintStyle: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                              ),
                              prefixIcon: const Icon(Icons.search_rounded, size: 18, color: GageTheme.primary),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() => _searchQuery = '');
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                            ),
                            onChanged: (val) {
                              setState(() => _searchQuery = val);
                            },
                          ),
                        ),
                      )
                    : null,
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
                ),
                actions: _isHeaderCollapsed
                    ? const []
                    : [
                        Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (_scrollController.hasClients) {
                                    _scrollController.animateTo(
                                      150,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.search_rounded,
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const ShopFavoriteScreen()),
                                  );
                                },
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    _isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                                    color: _isFavorite ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                    size: 20,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _showShareBottomSheet(context, storeName, storeAddress),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: isDark ? GageTheme.darkCard : Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isDark ? GageTheme.darkBorder : Colors.black12,
                                      width: 0.8,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.share_outlined,
                                    color: isDark ? Colors.white : Colors.black87,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
              ),

              // Detail Toko Info Card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? GageTheme.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              storeName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                              color: _isFavorite ? GageTheme.primary : (isDark ? Colors.white60 : Colors.black45),
                              size: 22,
                            ),
                            onPressed: _toggleFavorite,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF97316), size: 18),
                          const SizedBox(width: 4),
                          Text(
                            '$storeRating (40+)',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                          ),
                          const SizedBox(width: 8),
                          Text('•', style: TextStyle(color: Colors.grey.shade400)),
                          const SizedBox(width: 8),
                          Text(
                            '15-25 min ($storeDistance)',
                            style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 15, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              storeAddress,
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Switcher Delivery vs Pickup (10px Rounded)
                      Container(
                        height: 42,
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            // Tab Delivery
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (cart.isPickup) {
                                    cart.setIsPickup(false);
                                    GageToast.show(
                                      context,
                                      'Mode: Pesan Antar (Delivery) aktif',
                                      type: GageToastType.info,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: !cart.isPickup ? GageTheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Image.asset(
                                        'assets/images/gage_ride_3d.png',
                                        width: 18,
                                        height: 18,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => Icon(
                                          Icons.two_wheeler_rounded,
                                          size: 16,
                                          color: !cart.isPickup ? Colors.white : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Delivery',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: !cart.isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Tab Pickup
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  if (!cart.isPickup) {
                                    cart.setIsPickup(true);
                                    GageToast.show(
                                      context,
                                      'Mode: Ambil Sendiri (Pickup - Bebas Ongkir) aktif',
                                      type: GageToastType.info,
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: cart.isPickup ? GageTheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.shopping_bag_outlined,
                                        size: 16,
                                        color: cart.isPickup ? Colors.white : Colors.grey.shade600,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'Pickup',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: cart.isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
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

                      // Actions: Jadwalin & Chat Toko (10px Rounded)
                      Row(
                        children: [
                          // Jadwalin
                          InkWell(
                            onTap: () => _showJadwalinSheet(context, cart),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: cart.scheduledDeliveryTime != null
                                    ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                                    : (isDark ? GageTheme.darkSurface : Colors.white),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  width: cart.scheduledDeliveryTime != null ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.calendar_month_outlined,
                                    size: 16,
                                    color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    cart.scheduledDeliveryTime != null
                                        ? 'Jadwal: ${DateFormat('HH:mm').format(cart.scheduledDeliveryTime!)}'
                                        : 'Jadwalin',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: cart.scheduledDeliveryTime != null ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),

                          // Chat Toko
                          InkWell(
                            onTap: _openWhatsApp,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: isDark ? GageTheme.darkSurface : Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                                  width: 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chat_bubble_outline_rounded, size: 15, color: GageTheme.accentGreen),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Chat Toko',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Interactive Voucher Slider
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _buildInteractiveVoucherCard(
                          context: context,
                          cart: cart,
                          code: 'BELANJAHEMAT',
                          title: 'Diskon belanja Rp 8.000',
                          sub: 'Min. pembelian Rp 25.000',
                          discount: 8000,
                          isFood: true,
                          isDark: isDark,
                        ),
                        _buildInteractiveVoucherCard(
                          context: context,
                          cart: cart,
                          code: 'SEMBAKOMURAH',
                          title: 'Diskon belanja Rp 10.000',
                          sub: 'Min. pembelian Rp 40.000',
                          discount: 10000,
                          isFood: true,
                          isDark: isDark,
                        ),
                        _buildInteractiveVoucherCard(
                          context: context,
                          cart: cart,
                          code: 'ONGKIRSHOP',
                          title: 'Diskon Ongkir Rp 5.000',
                          sub: 'Khusus pengantaran Delivery',
                          discount: 5000,
                          isFood: false,
                          isDark: isDark,
                        ),
                      ],
                    ),
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
                          // KIRI: Info Produk & Harga
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod['name'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.5,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Satuan: ${prod['unit']}',
                                  style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                                ),
                                if (prod['desc'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 3.0),
                                    child: Text(
                                      prod['desc'],
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  currencyFormatter.format(price),
                                  style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 14.5),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // KANAN: Thumbnail Produk (86x86) + Favorite Heart Badge + Stepper / '+ Tambah'
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                      width: 86,
                                      height: 86,
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
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () {
                                        final favKey = 'fav_prod_$prodId';
                                        final isFav = _tempNotes[favKey] == 'true';
                                        setState(() {
                                          _tempNotes[favKey] = isFav ? 'false' : 'true';
                                        });
                                        GageToast.show(
                                          context,
                                          !isFav ? '${prod['name']} disukai!' : '${prod['name']} dihapus dari favorit',
                                          type: !isFav ? GageToastType.success : GageToastType.info,
                                        );
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                        ),
                                        child: Icon(
                                          _tempNotes['fav_prod_$prodId'] == 'true' ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                          size: 14,
                                          color: _tempNotes['fav_prod_$prodId'] == 'true' ? GageTheme.primary : Colors.black45,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),

                              // Tombol Tambah / Stepper (10px Rounded)
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
                                            GageToast.show(
                                              context,
                                              'Maksimal 3 toko berbeda dalam satu kali pengantaran.',
                                              type: GageToastType.warning,
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
      const Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: SeamlessFloatingCartBar(),
      ),
    ],
  ),
);
  }
}
