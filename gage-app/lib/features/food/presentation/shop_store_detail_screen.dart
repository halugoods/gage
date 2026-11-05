import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/shared/widgets/gage_digital_schedule_sheet.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'shop_favorite_screen.dart';
import 'resto_info_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

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
  bool _isLoading = true;
  final Map<String, String> _tempNotes = {};
  late final List<Map<String, dynamic>> _catalog;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _catalog = _generateStoreCatalog(widget.store['id'] ?? 'ret-berkah-01');
    _loadFavoriteStatus();
    _loadCatalogData();
  }

  Future<void> _loadCatalogData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 280));
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
                  onTap: () async {
                    Navigator.pop(ctx);
                    final shareText = Uri.encodeComponent('Kunjungi ${widget.store["name"] ?? "Toko Mitra"} di GAGE Pracimantoro!');
                    final waUri = Uri.parse('https://wa.me/?text=$shareText');
                    if (await canLaunchUrl(waUri)) {
                      await launchUrl(waUri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
                _buildShareAction(
                  icon: Icons.copy_rounded,
                  label: 'Salin Tautan',
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.pop(ctx);
                    Clipboard.setData(ClipboardData(text: 'https://gage.id/store/${widget.store["id"] ?? "shop"}'));
                    GageToast.show(context, 'Tautan toko berhasil disalin ke clipboard!', type: GageToastType.success);
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
    } else if (storeId.startsWith('farm-')) {
      return [
        {
          'id': 'prod-npk-mutiara',
          'name': 'Pupuk NPK Mutiara 16-16-16 Kemasan 1 Kg',
          'category': 'Pupuk & Nutrisi',
          'price': 18000,
          'unit': '1 kg',
          'image': 'assets/images/prod_pupuk.png',
          'desc': 'Pupuk majemuk lengkap nutrisi nitrogen, fosfat dan kalium seimbang untuk kesuburan tanaman.',
        },
        {
          'id': 'prod-pupuk-urea',
          'name': 'Pupuk Urea Nitrea Non-Subsidi 5 Kg',
          'category': 'Pupuk & Nutrisi',
          'price': 38000,
          'unit': '5 kg',
          'image': 'assets/images/prod_pupuk.png',
          'desc': 'Kandungan nitrogen tinggi 46% mempercepat pertumbuhan anakan dan daun hijau royo-royo.',
        },
        {
          'id': 'prod-benih-padi',
          'name': 'Benih Padi Unggul Inpari 32 Karung 5 Kg',
          'category': 'Benih & Bibit',
          'price': 75000,
          'unit': '5 kg',
          'image': 'assets/images/prod_benih.png',
          'desc': 'Benih padi bersertifikat resmi tahan wereng batang coklat dan hawar daun bakteri.',
        },
        {
          'id': 'prod-benih-cabai',
          'name': 'Benih Cabai Rawit Merah Unggul Ori 212 10 Gram',
          'category': 'Benih & Bibit',
          'price': 45000,
          'unit': 'Pack 10gr',
          'image': 'assets/images/prod_cabai.png',
          'desc': 'Daya tumbuh 85% buah tegak lebat tahan layu bakteri dan antraknosa.',
        },
        {
          'id': 'prod-pakan-br1',
          'name': 'Pakan Ayam Broiler BR-1 Pokphand Karung 5 Kg',
          'category': 'Pakan Ternak',
          'price': 52000,
          'unit': '5 kg',
          'image': 'assets/images/prod_pakan.png',
          'desc': 'Pakan crumble masa starter ayam pedaging berprotein tinggi cepat besar sehat.',
        },
        {
          'id': 'prod-konsentrat-sapi',
          'name': 'Konsentrat Penggemukan Sapi Potong Karung 50 Kg',
          'category': 'Pakan Ternak',
          'price': 225000,
          'unit': '50 kg',
          'image': 'assets/images/prod_pakan.png',
          'desc': 'Pakan konsentrat fermentasi kaya protein kasar untuk percepatan bobot sapi dan kambing.',
        },
        {
          'id': 'prod-vitachick',
          'name': 'Vitamin Pertumbuhan Anak Ayam Vitachick 100gr',
          'category': 'Vitamin & Obat Hewan',
          'price': 16000,
          'unit': 'Sachet 100gr',
          'image': 'assets/images/prod_telur.png',
          'desc': 'Serbuk multivitamin dan antibiotik mencegah stres dan mempercepat pertumbuhan DOC anak ayam.',
        },
        {
          'id': 'prod-sprayer-16l',
          'name': 'Tangki Sprayer Elektrik Pertanian Swan 16 Liter',
          'category': 'Alat Tani',
          'price': 285000,
          'unit': '1 Unit',
          'image': 'assets/images/prod_traktor.png',
          'desc': 'Semprotan hama elektrik baterai cas tahan 6 jam semburan kabut halus merata.',
        },
      ];
    } else if (storeId.startsWith('build-')) {
      return [
        {
          'id': 'prod-semen-gresik',
          'name': 'Semen Gresik Portland Composite 40 Kg',
          'category': 'Semen & Pasir',
          'price': 54000,
          'unit': 'Zak 40kg',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Semen berkualitas tinggi daya rekat kuat dan hasil plesteran acian lebih halus kokoh.',
        },
        {
          'id': 'prod-semen-tigaroda',
          'name': 'Semen Tiga Roda Master Portland 40 Kg',
          'category': 'Semen & Pasir',
          'price': 53000,
          'unit': 'Zak 40kg',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Pilihan utama tukang bangunan untuk pasangan bata, cor beton, dan plester dinding.',
        },
        {
          'id': 'prod-cat-dulux',
          'name': 'Cat Tembok Interior Dulux Catylac Putih 5 Kg',
          'category': 'Cat & Thinner',
          'price': 138000,
          'unit': 'Pail 5kg',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Formula Chroma Brite warna cerah menawan tidak mudah pudar dan minim cipratan cat.',
        },
        {
          'id': 'prod-cat-avian',
          'name': 'Cat Kayu & Besi Avian Super Glossy Hitam 1 Kg',
          'category': 'Cat & Thinner',
          'price': 68000,
          'unit': 'Kaleng 1kg',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Cat minyak mengkilap daya tutup maksimal cepat kering dan tahan cuaca panas hujan.',
        },
        {
          'id': 'prod-besi-8mm',
          'name': 'Besi Beton Polos SNI 8mm (Panjang 12 Meter)',
          'category': 'Besi & Baja',
          'price': 49000,
          'unit': 'Batang 12m',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Besi tulangan cor standar SNI kuat tarik teruji untuk kolom dan balok bangunan rumah.',
        },
        {
          'id': 'prod-pipa-pvc',
          'name': 'Pipa PVC Wavin / Rucika AW 3/4 Inch (4 Meter)',
          'category': 'Pipa & Sanitasi',
          'price': 34000,
          'unit': 'Batang 4m',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Pipa instalasi saluran air bersih bertekanan tebal tidak mudah pecah atau berlumut.',
        },
        {
          'id': 'prod-palu-baja',
          'name': 'Palu Kambing Martil Baja Gagang Karet Anti Slip',
          'category': 'Alat Pertukangan',
          'price': 42000,
          'unit': '1 Pcs',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Kepala palu baja tempa padat dengan pencabut paku presisi dan handle karet nyaman.',
        },
        {
          'id': 'prod-kuas-cat',
          'name': 'Kuas Cat Tembok Bulu Putih Tebal Eterna 3 Inch',
          'category': 'Alat Pertukangan',
          'price': 13000,
          'unit': '1 Pcs',
          'image': 'assets/icons/ic_build.png',
          'desc': 'Bulu kuas halus rapat tidak mudah rontok menghasilkan sapuan cat rata sempurna.',
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


  void _showJadwalinSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    DateTime? selectedTime = cart.scheduledDeliveryTime;
    String scheduleMode = selectedTime == null ? 'now' : 'custom';

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final nowPlus1Hour = DateTime.now().add(const Duration(hours: 1));

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Jadwalkan Pengantaran',
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
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
                  'Pilih kapan resto harus menyiapkan dan mengantar pesanan Anda.',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
                ),
                const SizedBox(height: 16),

                // 1. Kirim Sekarang (Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == 'now',
                  icon: Icons.bolt_rounded,
                  title: 'Kirim Sekarang',
                  subtitle: 'Estimasi tiba 20-30 menit',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setSheetState(() {
                      scheduleMode = 'now';
                      selectedTime = null;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // 2. 1 Jam Lagi (Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == '1hour',
                  icon: Icons.schedule_rounded,
                  title: '1 Jam Lagi',
                  subtitle: '${nowPlus1Hour.hour.toString().padLeft(2, '0')}:${nowPlus1Hour.minute.toString().padLeft(2, '0')} WIB',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setSheetState(() {
                      scheduleMode = '1hour';
                      selectedTime = nowPlus1Hour;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // 3. Atur Sendiri (Langsung Buka Digital Picker, Full Rounded Pill 24px)
                _buildSchedulePillOption(
                  isDark: isDark,
                  isSelected: scheduleMode == 'custom',
                  icon: Icons.edit_calendar_rounded,
                  title: 'Atur Sendiri',
                  subtitle: selectedTime != null && scheduleMode == 'custom'
                      ? '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')} WIB'
                      : 'Pilih tanggal & jam pengantaran bebas',
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    final picked = await GageDigitalScheduleSheet.show(
                      context,
                      initialTime: selectedTime ?? DateTime.now().add(const Duration(hours: 2)),
                    );
                    if (picked != null) {
                      setSheetState(() {
                        scheduleMode = 'custom';
                        selectedTime = picked;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      cart.setScheduledDeliveryTime(selectedTime);
                      Navigator.pop(ctx);
                      GageToast.show(
                        context,
                        selectedTime != null
                            ? 'Pengantaran dijadwalkan pukul ${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')} WIB'
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

  Widget _buildSchedulePillOption({
    required bool isDark,
    required bool isSelected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? GageTheme.primary : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            width: isSelected ? 1.5 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected
                    ? GageTheme.primary.withValues(alpha: 0.14)
                    : (isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6)),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? GageTheme.primary : Colors.grey.shade600,
                size: 19,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13.5,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? GageTheme.primary : Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _showGroupOrderSheet(BuildContext context, CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isGroupActive = cart.groupOrderId != null;
    final roomId = cart.groupOrderId ?? 'GAGE-${widget.store['id']?.toString().split('-').last.toUpperCase() ?? '8821'}';
    final storeName = widget.store['name'] ?? 'Toko';

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesan Bareng (Group Order)',
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
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
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
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFBFDBFE),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.groups_rounded, color: Color(0xFF2563EB), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pesan Belanja Bareng ke 1 Alamat',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ajak teman atau tetangga belanja di $storeName sekaligus. Tagihan otomatis dipisahkan per orang dan ongkos kirim dibagi hemat bersama!',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Room Code Container
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF27272A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'KODE RUANGAN BELANJA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            roomId,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: GageTheme.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          visualDensity: VisualDensity.compact,
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.share_rounded, size: 14),
                        label: const Text('Bagi ke WA', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          GageToast.show(
                            context,
                            'Tautan Pesan Bareng $roomId disalin ke WhatsApp!',
                            type: GageToastType.success,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Anggota Pesan Bareng (2 Orang)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 14,
                            backgroundColor: GageTheme.primary,
                            child: Text('K', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Kamu (Host Pesanan)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Siap Order', style: TextStyle(color: Colors.green.shade700, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.blue.shade600,
                            child: const Text('B', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text('Budi (Anggota)', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12.5)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('Memilih Produk...', style: TextStyle(color: Colors.amber.shade800, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isGroupActive ? Colors.grey.shade700 : GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      if (isGroupActive) {
                        cart.deactivateGroupOrder();
                        GageToast.show(
                          context,
                          'Pesan Bareng dinonaktifkan',
                          type: GageToastType.info,
                        );
                      } else {
                        cart.activateGroupOrder(
                          roomId,
                          merchantId: widget.store['id'] ?? 'store-default',
                          merchantName: widget.store['name'] ?? 'Toko Mitra',
                        );
                        GageToast.show(
                          context,
                          'Pesan Bareng aktif ($roomId)! 2 Teman bergabung',
                          type: GageToastType.success,
                        );
                      }
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isGroupActive ? 'Bubarkan Pesan Bareng' : 'Mulai Pesan Bareng Sekarang',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProductDetailModal(
    BuildContext context,
    Map<String, dynamic> prod,
    CartProvider cart,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final prodId = prod['id'] as String;
    final prodName = prod['name'] ?? 'Produk';
    final prodImage = prod['image'] ?? 'assets/images/prod_beras.png';
    final price = prod['price'] as int;
    final unit = prod['unit'] ?? 'pcs';
    final desc = prod['desc'] ?? 'Produk segar & berkualitas terbaik pilihan langsung dari toko mitra resmi GAGE.';
    final storeId = widget.store['id'] ?? 'store-default';
    final storeName = widget.store['name'] ?? 'Toko';
    final category = prod['category'] ?? 'Sembako';

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final inCartQty = cart.getItemQuantity(prodId);

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Title & Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        prodName,
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Foto Produk 1:1 Square dengan Badge Kategori di Pojok Kanan Atas
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.asset(
                            prodImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                              child: const Icon(Icons.shopping_bag_rounded, size: 48, color: GageTheme.primary),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 10,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              category,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Baris: Harga & Satuan di kiri, Tombol Tambah / Stepper di kanan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormatter.format(price),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: GageTheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Satuan: $unit',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.grey.shade400 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (inCartQty == 0)
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            elevation: 0,
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
                                category: category,
                                imageUrl: prodImage,
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
                                  category: category,
                                  image: prodImage,
                                  menuOrigin: 'shop',
                                ),
                              );
                            }
                            setModalState(() {});
                          },
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text(
                            'Tambah',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ),
                      )
                    else
                      Container(
                        height: 36,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                if (inCartQty > 0) {
                                  cart.updateQuantity(prodId, -1);
                                  final newQty = cart.getItemQuantity(prodId);
                                  MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                  setModalState(() {});
                                }
                              },
                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.remove, size: 16, color: Color(0xFF16A34A)),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                '$inCartQty',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                cart.updateQuantity(prodId, 1);
                                final newQty = cart.getItemQuantity(prodId);
                                MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                setModalState(() {});
                              },
                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(18)),
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                child: Icon(Icons.add, size: 16, color: Color(0xFF16A34A)),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),

                // Deskripsi Produk
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
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
    // Sunset Orange (#EA580C) for Product discount, Deep Teal (#0D9488) for Delivery discount
    final activeColor = isFood ? const Color(0xFFEA580C) : const Color(0xFF0D9488);
    final bgColor = isFood
        ? (isDark ? const Color(0xFF2A170A) : const Color(0xFFFFF7ED))
        : (isDark ? const Color(0xFF032726) : const Color(0xFFF0FDFA));
    final badgeTag = isFood ? '-${discount ~/ 1000}RB' : 'ONGKIR';

    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: activeColor.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: activeColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFood ? Icons.local_offer_rounded : Icons.delivery_dining_rounded,
              color: activeColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: activeColor,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeTag,
                        style: const TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
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
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final storeName = widget.store['name'] ?? 'Toko Mitra Resmi';
    final storeAddress = widget.store['address'] ?? 'Pracimantoro, Wonogiri';
    final storeDistance = widget.store['distance'] ?? '1.0 km';
    final storeRating = widget.store['rating'] ?? 4.9;
    final storeId = widget.store['id'] ?? 'ret-berkah-01';
    final storeImage = widget.store['image'] ?? 'assets/images/shop_banner_1.png';
    final storeCategory = widget.store['category'] ?? 'Toko Mitra';

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
                  background: Image.asset(
                    storeImage,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
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
                      InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (ctx) => RestoInfoScreen(
                                restoName: storeName,
                                restoImage: storeImage,
                                address: storeAddress,
                                distance: storeDistance,
                                rating: storeRating is num ? storeRating.toDouble() : 4.9,
                                ratingCount: '40+',
                                category: storeCategory,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Color(0xFFF97316), size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '$storeRating (40+)',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade500),
                            const SizedBox(width: 6),
                            Text('•', style: TextStyle(color: Colors.grey.shade400)),
                            const SizedBox(width: 6),
                            Text(
                              '15-25 min ($storeDistance)',
                              style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
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
                                  child: Text(
                                    'Delivery',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: !cart.isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                    ),
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
                                  child: Text(
                                    'Pickup',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: cart.isPickup ? Colors.white : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                    ),
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

                          // Group Order (Pesan Bareng)
                          InkWell(
                            onTap: () => _showGroupOrderSheet(context, cart),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                              decoration: BoxDecoration(
                                color: cart.groupOrderId != null
                                    ? (isDark ? const Color(0xFF2C1E1E) : const Color(0xFFFFF1F0))
                                    : (isDark ? GageTheme.darkSurface : Colors.white),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: cart.groupOrderId != null ? GageTheme.primary : (isDark ? Colors.grey.shade700 : Colors.grey.shade300),
                                  width: cart.groupOrderId != null ? 1.5 : 1.0,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.group_rounded, size: 16, color: GageTheme.primary),
                                  const SizedBox(width: 6),
                                  Text(
                                    cart.groupOrderId != null ? 'Group: ${cart.groupOrderId}' : 'Group Order',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: cart.groupOrderId != null ? GageTheme.primary : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                    decoration: BoxDecoration(
                                      color: GageTheme.primary,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      cart.groupOrderId != null ? 'AKTIF' : 'NEW',
                                      style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
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
          if (_isLoading)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const GageSkeletonMenuItem(),
                  childCount: 4,
                ),
              ),
            )
          else if (_filteredCatalog.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'Produk tidak ditemukan.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final prod = _filteredCatalog[index];
                  final price = prod['price'] as int;
                  final prodId = prod['id'] as String;
                  final itemQty = cart.getItemQuantity(prodId);

                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                          width: 0.8,
                        ),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // KIRI: Info Produk & Harga (Klik Detail Modal)
                          Expanded(
                            child: InkWell(
                              onTap: () => _showProductDetailModal(context, prod, cart),
                              borderRadius: BorderRadius.circular(8),
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
                          ),
                          const SizedBox(width: 14),

                          // KANAN: Thumbnail Produk (80x80) + Stepper / '+ Tambah' Presisi
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Stack(
                                children: [
                                  InkWell(
                                    onTap: () => _showProductDetailModal(context, prod, cart),
                                    borderRadius: BorderRadius.circular(12),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: SizedBox(
                                        width: 80,
                                        height: 80,
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

                              // Tombol Tambah / Stepper (80px Presisi)
                              itemQty > 0
                                  ? SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            InkWell(
                                              onTap: () {
                                                cart.updateQuantity(prodId, -1);
                                                final newQty = cart.getItemQuantity(prodId);
                                                MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                              },
                                              borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Icon(Icons.remove, color: Color(0xFF16A34A), size: 16),
                                              ),
                                            ),
                                            Text(
                                              '$itemQty',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                            ),
                                            InkWell(
                                              onTap: () {
                                                cart.updateQuantity(prodId, 1);
                                                final newQty = cart.getItemQuantity(prodId);
                                                MultiMerchantCartService.instance.updateQuantity(storeId, prodId, newQty);
                                              },
                                              borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                                child: Icon(Icons.add, color: Color(0xFF16A34A), size: 16),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : SizedBox(
                                      width: 80,
                                      height: 32,
                                      child: ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: GageTheme.primary,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          padding: EdgeInsets.zero,
                                          elevation: 0,
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
                                        child: const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.add, size: 14),
                                            SizedBox(width: 2),
                                            Text('Tambah', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
                                          ],
                                        ),
                                      ),
                                    ),
                            ],
                          ),
                        ],
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
