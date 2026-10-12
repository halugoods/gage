import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/core/services/multi_merchant_cart_service.dart';
import 'package:gage_app/data/models/cart_item_model.dart';
import 'package:gage_app/features/checkout/presentation/checkout_screen.dart';
import 'package:gage_app/features/orders/presentation/orders_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/looping_bubble_chat.dart';

class TaniScreen extends StatefulWidget {
  const TaniScreen({super.key});

  @override
  State<TaniScreen> createState() => _TaniScreenState();
}

class _TaniScreenState extends State<TaniScreen> {
  // Main Category Switch: 'pertanian', 'peternakan', 'sewa'
  String _mainCategory = 'pertanian';

  // Sub Switch per Category:
  // - Pertanian: 'agroshop' (Bibit, Pupuk, Obat) vs 'hasil_bumi' (Panen, Beras, Sayur)
  String _pertanianSubCategory = 'agroshop';

  // - Peternakan: 'poultry_shop' (Pakan, Vitamin) vs 'hasil_ternak' (Telur, Daging, Susu)
  String _peternakanSubCategory = 'poultry_shop';

  String _searchQuery = '';
  String _deliveryLocation = 'Kecamatan Pracimantoro, Wonogiri';
  final Set<String> _favoriteItemIds = {};
  bool _showFavoritesOnly = false;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
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
    } catch (_) {
      // Fallback tetap ke default Pracimantoro
    }
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
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hubungi Kontak WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  void _openConsultationWhatsApp() {
    final String topik;
    final String sapaan;
    if (_mainCategory == 'pertanian') {
      topik = 'Pertanian & Perlindungan Tanaman (Agronomi)';
      sapaan = 'Dokter Tanaman GAGE';
    } else if (_mainCategory == 'peternakan') {
      topik = 'Peternakan, Nutrisi Ternak & Poultry';
      sapaan = 'Ahli Nutrisi & Dokter Ternak GAGE';
    } else {
      topik = 'Sewa Peralatan Alsintan Pertanian';
      sapaan = 'Koordinator Alsintan GAGE';
    }

    final msg = 'Halo $sapaan Pracimantoro,\n\n'
        'Saya ingin mengajukan *Konsultasi Gratis GAGE*:\n'
        '- Topik: $topik\n'
        '- Nama Petani/Peternak:\n'
        '- Desa / Lokasi Lahan:\n'
        '- Kendala / Kebutuhan:\n\n'
        'Mohon bantuan dan arahan rekomendasi dari tim ahli. Terima kasih!';

    _openWhatsApp(phone: '6281234567891', message: msg);
  }

  void _showLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran GAGE Tani & Ternak',
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
  // Direct Stepper add tanpa chat WA
  // ===========================================================================
  void _addToCart(BuildContext context, Map<String, dynamic> item) {
    final cart = context.read<CartProvider>();
    final multiCart = context.read<MultiMerchantCartService>();

    final storeId = item['kiosId'] as String? ?? 'mch-gage-tani';
    final storeName = item['kios'] as String? ?? 'Lapak Resmi GAGE Tani & Ternak';

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
  // DATA KATALOG RESMI GAGE TANI & TERNAK
  // ===========================================================================
  // 1. Pertanian -> Agroshop (Saprotan, Pupuk, Benih & Pestisida)
  final List<Map<String, dynamic>> _agroshopItems = [
    {
      'id': 'agr-pupuk-01',
      'name': 'Pupuk NPK Phonska Plus 25 Kg',
      'category': 'Pupuk Makro',
      'kios': 'Lapak Resmi Agro GAGE',
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
      'price': 48000,
      'unit': 'Botol 1 Liter',
      'desc': 'Bakteri premium pembenah tanah tandus, tingkatkan kesuburan tanah gamping Wonogiri.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.compost_rounded,
    },
  ];

  // 2. Pertanian -> Hasil Bumi (Panen Lokal Beras, Jagung, Sayur, Cabai)
  final List<Map<String, dynamic>> _hasilBumiItems = [
    {
      'id': 'hbm-beras-01',
      'name': 'Beras Mentik Wangi Fresh Giling Sawah 5 Kg',
      'category': 'Beras Premium',
      'kios': 'Gapoktan Binaan GAGE Tubokarto',
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
      'price': 20000,
      'unit': 'Pack 5kg',
      'desc': 'Daging umbi pulen empuk saat dikukus atau digoreng, tidak pait, panen segar hari ini.',
      'image': 'assets/images/prod_benih.png',
      'icon': Icons.grass_rounded,
    },
  ];

  // 3. Peternakan -> Poultry Shop (Pakan, Vitamin & Obat Ternak)
  final List<Map<String, dynamic>> _poultryShopItems = [
    {
      'id': 'pou-pakan-01',
      'name': 'Pakan Konsentrat Ayam Pedaging BR-1 50 Kg',
      'category': 'Pakan Unggas',
      'kios': 'Poultry Shop Mitra GAGE',
      'price': 420000,
      'unit': 'Karung 50kg',
      'desc': 'Nutrisi komplit starter ayam pedaging, FCR optimal & bobot karkas cepat naik.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.pets_rounded,
    },
    {
      'id': 'pou-vit-01',
      'name': 'Vitamin & Anti-Stres Unggas Vita Stress 250gr',
      'category': 'Vitamin Ternak',
      'kios': 'Poultry Shop Mitra GAGE',
      'price': 38000,
      'unit': 'Bungkus 250g',
      'desc': 'Cegah stres saat vaksinasi, perubahan cuaca ekstrem, serta pacu nafsu makan ayam.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.medication_rounded,
    },
    {
      'id': 'pou-sapi-01',
      'name': 'Pakan Fermentasi Konsentrat Sapi Penggemukan 40 Kg',
      'category': 'Pakan Ruminansia',
      'kios': 'Kelompok Ternak Lembu Makmur',
      'price': 185000,
      'unit': 'Karung 40kg',
      'desc': 'Tinggi protein & serat fermentasi, meningkatkan bobot harian sapi dan kambing secara sehat.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.agriculture_rounded,
    },
    {
      'id': 'pou-katul-01',
      'name': 'Dedak Katul Padi Super Halus Wangi 25 Kg',
      'category': 'Bahan Pakan',
      'kios': 'Lapak Gilingan Mitra GAGE',
      'price': 90000,
      'unit': 'Karung 25kg',
      'desc': 'Katul gilingan pertama tanpa campuran sekam kasar, aroma wangi gurih disukai ternak.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.grain_rounded,
    },
    {
      'id': 'pou-mineral-01',
      'name': 'Mineral Premix Ternak Sapi & Kambing 1 Kg',
      'category': 'Mineral Ternak',
      'kios': 'Poultry Shop Mitra GAGE',
      'price': 22000,
      'unit': 'Pack 1kg',
      'desc': 'Cegah kelumpuhan dan kalsium defisiensi, perkuat tulang dan percepat birahi indukan.',
      'image': 'assets/images/prod_pupuk.png',
      'icon': Icons.healing_rounded,
    },
  ];

  // 4. Peternakan -> Hasil Ternak (Telur Segar, Madu Asli, Susu Etawa)
  final List<Map<String, dynamic>> _hasilTernakItems = [
    {
      'id': 'trk-telur-01',
      'name': 'Telur Ayam Ras Fresh Kandang 1 Tray (30 Butir)',
      'category': 'Telur Segar',
      'kios': 'Kandang Ayam Petelur Sucipto',
      'price': 48000,
      'unit': 'Tray 30 Butir (~1.8kg)',
      'desc': 'Koleksi panen telur pagi ini, cangkang coklat tebal & kuning telur cerah padat alami.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.egg_rounded,
    },
    {
      'id': 'trk-madu-01',
      'name': 'Madu Murni Randu Hutan Wonogiri 500ml',
      'category': 'Hasil Alam',
      'kios': 'Peternak Lebah Pracimantoro',
      'price': 85000,
      'unit': 'Botol 500ml',
      'desc': 'Madu mentah murni tanpa campuran sirup gula, kaya enzim & imun booster alami.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.sanitizer_rounded,
    },
    {
      'id': 'trk-susu-01',
      'name': 'Susu Kambing Etawa Segar Pasteurisasi 1 Liter',
      'category': 'Susu Segar',
      'kios': 'Peternakan Etawa Berkah',
      'price': 32000,
      'unit': 'Botol 1 Liter',
      'desc': 'Segar tanpa bau perengus, kaya kalsium alami dan sangat baik untuk terapi stamina.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.local_drink_rounded,
    },
    {
      'id': 'trk-bebek-01',
      'name': 'Telur Bebek Segar Angon Sawah 10 Butir',
      'category': 'Telur Bebek',
      'kios': 'Peternak Bebek GAGE Wonodadi',
      'price': 27000,
      'unit': 'Pack 10 Butir',
      'desc': 'Bebek gembala alami sawah, kuning telur jingga kemerahan sangat gurih untuk martabak/asin.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.egg_outlined,
    },
    {
      'id': 'trk-ayam-01',
      'name': 'Ayam Kampung Segar Potong Bersih 1 Ekor (~0.9kg)',
      'category': 'Daging Segar',
      'kios': 'Lapak Unggas Berkah Pracimantoro',
      'price': 65000,
      'unit': 'Ekor Karkas Bersih',
      'desc': 'Diproses halal higienis saat order masuk, daging padat manis gurih alami khas ayam kampung.',
      'image': 'assets/images/prod_beras.png',
      'icon': Icons.restaurant_menu_rounded,
    },
  ];

  // 5. Sewa Peralatan Pertanian (Coming Soon)
  final List<Map<String, dynamic>> _sewaAlsintanItems = [
    {
      'id': 'als-traktor-01',
      'name': 'Traktor Bajak Sawah Quick G 1000 Boxer (Kubota 8.5 HP)',
      'category': 'Olah Tanah',
      'spec': 'Mesin Diesel Kubota RD 85 DI-2S • Singkal, Gelebeg & Rotary',
      'estimate': 'Estimasi: Rp 120.000 / Patok (Include Operator)',
      'desc': 'Bajak sawah cepat & rata untuk persiapan tanam padi dan jagung musim rendeng.',
      'icon': Icons.agriculture_rounded,
    },
    {
      'id': 'als-pompa-01',
      'name': 'Pompa Air Irigasi Alkon 3 Inch Honda GP160',
      'category': 'Pompa Irigasi',
      'spec': 'Debit 60.000 Liter/Jam • Selang spiral sedot 6m + Buang 50m',
      'estimate': 'Estimasi: Rp 50.000 / Hari Sewa',
      'desc': 'Sedot air dari sungai/sumur pantek untuk atasi kekeringan sawah musim kemarau.',
      'icon': Icons.water_drop_rounded,
    },
    {
      'id': 'als-thresher-01',
      'name': 'Mesin Perontok Padi / Thresher Portable 6.5 HP',
      'category': 'Alsintan Panen',
      'spec': 'Kapasitas 500-700 kg/jam • Roda dorong praktis masuk pematang',
      'estimate': 'Estimasi: Rp 80.000 / Hari Sewa',
      'desc': 'Perontok gabah langsung di petak sawah, minim gabah tercecer dan hemat tenaga panen.',
      'icon': Icons.precision_manufacturing_rounded,
    },
  ];

  List<Map<String, dynamic>> get _currentCategoryItems {
    if (_mainCategory == 'pertanian') {
      return _pertanianSubCategory == 'agroshop' ? _agroshopItems : _hasilBumiItems;
    } else if (_mainCategory == 'peternakan') {
      return _peternakanSubCategory == 'poultry_shop' ? _poultryShopItems : _hasilTernakItems;
    }
    return [];
  }

  // ===========================================================================
  // HERO HEADER 16:9 BERSIH (BEBAS VIGNETTE & BEBAS TEKS/BADGE OVERLAY)
  // Layering search bar terjamin di DEPAN banner menggunakan Stack Z-order baku
  // ===========================================================================
  Widget _buildTaniHeroHeader(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final rawBannerHeight = screenWidth * 9 / 16;
    final bannerHeight = isTablet ? 260.0 : rawBannerHeight;
    final topPadding = MediaQuery.of(context).padding.top;
    final bannerManager = context.watch<BannerManagerService>();
    final bannerConfig = bannerManager.getBanner('tani');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: isDark ? const Color(0xFF14532D) : Colors.white,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: topPadding,
            color: isDark ? const Color(0xFF14532D) : Colors.white,
          ),
          SizedBox(
            height: bannerHeight + 24, // Ruang untuk floating search bar overlap 50%
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // LAYER 1 (Paling Bawah): Banner Hero 16:9 Murni Bersih (Bebas vignette & bebas teks tumpuk)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: bannerHeight,
                  child: Image.asset(
                    bannerConfig.imagePath,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF166534), Color(0xFF14532D)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.grass_rounded, size: 64, color: Colors.white24),
                      ),
                    ),
                  ),
                ),

                // LAYER 2: Floating Action Controls di Atas Banner
                Positioned(
                  top: 16,
                  left: 14,
                  right: 14,
                  child: Row(
                    children: [
                      // Tombol X Back
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

                      // Pill Lokasi Mandiri
                      Flexible(
                        child: GestureDetector(
                          onTap: _showLocationPicker,
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
                                const Icon(Icons.location_on_rounded, color: Color(0xFF16A34A), size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${_formatShortAddress(_deliveryLocation)} ▾',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
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
                                    ? 'Menampilkan produk favorit Anda (${_favoriteItemIds.length})'
                                    : 'Menampilkan semua produk GAGE Tani & Ternak',
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

                      // Pill Riwayat Mandiri (Navigasi ke OrdersScreen)
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
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF16A34A), size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // LAYER 3 (Paling Depan): Floating Search Bar Overlapping 50% di Perbatasan Banner
                Positioned(
                  bottom: 0,
                  left: 16,
                  right: 16,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            textAlignVertical: TextAlignVertical.center,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                              hintText: 'Cari bibit, pupuk, pakan ternak, atau hasil bumi...',
                              hintStyle: const TextStyle(fontSize: 12, color: Colors.black45),
                              prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF15803D), size: 20),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 18, color: Colors.grey),
                                      onPressed: () => setState(() => _searchQuery = ''),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                      ),
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
  // KARTU KONSULTASI GRATIS AHLI DI DALAM TAB PERTANIAN & PETERNAKAN
  // ===========================================================================
  Widget _buildInSwitchConsultationCard() {
    final isPertanian = _mainCategory == 'pertanian';
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFDCFCE7),
            const Color(0xFFF0FDF4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF86EFAC)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xFF16A34A),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPertanian ? Icons.eco_rounded : Icons.pets_rounded,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isPertanian ? 'Konsultasi Gratis Dokter Tanaman' : 'Konsultasi Gratis Ahli Ternak',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Color(0xFF14532D),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GRATIS',
                        style: TextStyle(fontSize: 8.5, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPertanian
                      ? 'Diagnosa hama, takaran pupuk NPK & rekomendasi bibit unggul'
                      : 'Solusi kesehatan ternak, formula ransum & pencegahan penyakit',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              visualDensity: VisualDensity.compact,
            ),
            onPressed: _openConsultationWhatsApp,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.chat_bubble_rounded, size: 12),
                SizedBox(width: 4),
                Text('Tanya Ahli', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KARTU PRODUK KATALOG (STEPPER SIMPEL, BEBAS CHAT WA PER PRODUK)
  // ===========================================================================
  Widget _buildProductCard(Map<String, dynamic> item, CartProvider cart) {
    final prodId = item['id'] as String;
    final price = item['price'] as int;
    final itemQty = cart.getItemQuantity(prodId);
    final isFav = _favoriteItemIds.contains(prodId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Produk
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 76,
              height: 76,
              child: Image.asset(
                item['image'] as String? ?? 'assets/images/prod_pupuk.png',
                fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  color: const Color(0xFFDCFCE7),
                  child: Icon(item['icon'] as IconData? ?? Icons.grass_rounded, color: const Color(0xFF15803D), size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Detail Informasi
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
                        style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    InkWell(
                      onTap: () => _toggleFavorite(prodId),
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
                const SizedBox(height: 4),
                Text(
                  item['name'] as String,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item['desc'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      currencyFormatter.format(price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14.5,
                        color: Color(0xFF15803D),
                      ),
                    ),

                    // Stepper Simpel Seperti GoFood (Order Langsung ke Keranjang Bersama Tanpa Chat WA)
                    itemQty > 0
                        ? Container(
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _updateProductQuantity(context, item, -1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.remove, color: Color(0xFF16A34A), size: 16),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '$itemQty',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF16A34A)),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _updateProductQuantity(context, item, 1),
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    child: Icon(Icons.add, color: Color(0xFF16A34A), size: 16),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.add_shopping_cart_rounded, size: 14),
                            label: const Text('Beli', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                            onPressed: () => _addToCart(context, item),
                          ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // KARTU ALSINTAN PERALATAN (SEWA PERALATAN - COMING SOON)
  // ===========================================================================
  Widget _buildAlsintanCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item['icon'] as IconData? ?? Icons.agriculture_rounded, color: const Color(0xFFD97706), size: 22),
              ),
              const SizedBox(width: 10),
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
                            item['category'] as String,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Text(
                            'Segera Hadir',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item['spec'] as String,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF166534)),
          ),
          const SizedBox(height: 2),
          Text(
            item['desc'] as String,
            style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['estimate'] as String,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFD97706)),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  side: const BorderSide(color: Color(0xFF86EFAC)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                icon: const Icon(Icons.chat_outlined, size: 12),
                label: const Text('Tanya Operator', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
                onPressed: () {
                  final msg = 'Halo Tim Alsintan GAGE Pracimantoro,\n\n'
                      'Saya tertarik dengan informasi sewa peralatan: *${item['name']}*.\n'
                      'Kira-kira kapan mulai beroperasi dan bagaimana prosedur bookingnya?';
                  _openWhatsApp(phone: '6281234567891', message: msg);
                },
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final allItems = _currentCategoryItems;
    final activeItems = allItems.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final name = (item['name'] as String).toLowerCase();
      final cat = (item['category'] as String).toLowerCase();
      final desc = (item['desc'] as String).toLowerCase();
      final matchesSearch = q.isEmpty || name.contains(q) || cat.contains(q) || desc.contains(q);
      final matchesFav = !_showFavoritesOnly || _favoriteItemIds.contains(item['id'] as String);
      return matchesSearch && matchesFav;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Hero Header 16:9 Bersih (Layering search bar overlapping 50% di depan banner)
                  _buildTaniHeroHeader(context),

                  // Ruang aman 32px agar search bar (overlap 24px) tidak menabrak Switch Utama
                  const SizedBox(height: 32),

                  // Container Wrapper Responsif (Tablet & Handphone)
                  Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 2. Switch Kategori Utama (Pertanian, Peternakan, Sewa Peralatan)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade200),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Row(
                                children: [
                                  _buildMainTabButton(
                                    id: 'pertanian',
                                    label: 'Pertanian',
                                    icon: Icons.grass_rounded,
                                    isActive: _mainCategory == 'pertanian',
                                  ),
                                  _buildMainTabButton(
                                    id: 'peternakan',
                                    label: 'Peternakan',
                                    icon: Icons.pets_rounded,
                                    isActive: _mainCategory == 'peternakan',
                                  ),
                                  _buildMainTabButton(
                                    id: 'sewa',
                                    label: 'Sewa Mesin Pertanian (Traktor & Pompa)',
                                    icon: Icons.agriculture_rounded,
                                    isActive: _mainCategory == 'sewa',
                                    badge: 'Segera Hadir',
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 12),

                            // 3. Sub-Switch Ganda per Kategori
                            if (_mainCategory == 'pertanian')
                              Row(
                                children: [
                                  _buildSubPillButton(
                                    label: 'Agroshop',
                                    icon: Icons.storefront_rounded,
                                    isActive: _pertanianSubCategory == 'agroshop',
                                    onTap: () => setState(() => _pertanianSubCategory = 'agroshop'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSubPillButton(
                                    label: 'Hasil Bumi',
                                    icon: Icons.rice_bowl_rounded,
                                    isActive: _pertanianSubCategory == 'hasil_bumi',
                                    onTap: () => setState(() => _pertanianSubCategory = 'hasil_bumi'),
                                  ),
                                ],
                              )
                            else if (_mainCategory == 'peternakan')
                              Row(
                                children: [
                                  _buildSubPillButton(
                                    label: 'Poultry Shop',
                                    icon: Icons.medication_rounded,
                                    isActive: _peternakanSubCategory == 'poultry_shop',
                                    onTap: () => setState(() => _peternakanSubCategory = 'poultry_shop'),
                                  ),
                                  const SizedBox(width: 8),
                                  _buildSubPillButton(
                                    label: 'Hasil Ternak',
                                    icon: Icons.egg_rounded,
                                    isActive: _peternakanSubCategory == 'hasil_ternak',
                                    onTap: () => setState(() => _peternakanSubCategory = 'hasil_ternak'),
                                  ),
                                ],
                              ),

                            // 4. Tombol Konsultasi Gratis Ahli di dalam Switch Pertanian & Peternakan
                            if (_mainCategory == 'pertanian' || _mainCategory == 'peternakan')
                              _buildInSwitchConsultationCard(),

                            const SizedBox(height: 16),

                            // 5. Section Headline
                            if (_mainCategory != 'sewa')
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Daftar Produk (${activeItems.length})',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                                    ),
                                    const Text(
                                      'Diantar Langsung via GAGE',
                                      style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Text(
                                          'Sewa Mesin Pertanian (Traktor & Pompa)',
                                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Colors.black87),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFEF3C7),
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: const Color(0xFFFDE68A)),
                                          ),
                                          child: const Text(
                                            'Segera Hadir',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFFB45309)),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '${_sewaAlsintanItems.length} Alat Terdaftar',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),

                            // 6. Konten Produk atau Sewa Peralatan
                            if (_mainCategory == 'sewa') ...[
                              ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _sewaAlsintanItems.length,
                                itemBuilder: (ctx, idx) => _buildAlsintanCard(_sewaAlsintanItems[idx]),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Column(
                                  children: [
                                    const Icon(Icons.info_outline_rounded, size: 28, color: Color(0xFFD97706)),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Punya Traktor atau Alsintan di Pracimantoro?',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Daftarkan alsintan Anda sebagai mitra operator GAGE untuk menjangkau kelompok tani se-Kecamatan Pracimantoro.',
                                      style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.3),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 12),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF16A34A),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        elevation: 0,
                                      ),
                                      icon: const Icon(Icons.handshake_outlined, size: 16),
                                      label: const Text('Daftar Jadi Mitra Operator Alsintan', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                      onPressed: () {
                                        final msg = 'Halo Admin GAGE Pracimantoro,\n\n'
                                            'Saya pemilik alsintan dan ingin mendaftarkan unit saya (traktor/alkon/mesin panen) sebagai mitra operator sewa GAGE Tani.';
                                        _openWhatsApp(phone: '6281234567891', message: msg);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ] else if (activeItems.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                                      const SizedBox(height: 10),
                                      Text(
                                        _showFavoritesOnly
                                            ? 'Belum ada produk favorit di kategori ini.'
                                            : 'Produk tidak ditemukan untuk pencarian "$_searchQuery"',
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

                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 7. Bottom Bar Area (Looping Bubble Chat Konsultasi Dokter Tani Selalu Aktif + Cart Summary jika ada barang)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isTablet ? 680 : double.infinity),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Looping Bubble Chat Interaktif Konsultasi Dokter Tani & Ahli Ternak (Selalu Aktif)
                      Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, cart.items.isNotEmpty ? 4 : 8),
                        child: LoopingBubbleChat(
                          senderName: _mainCategory == 'pertanian'
                              ? 'Dokter Tanaman GAGE'
                              : _mainCategory == 'peternakan'
                                  ? 'Ahli Nutrisi & Dokter Ternak GAGE'
                                  : 'Koordinator Alsintan GAGE',
                          subtitle: 'Konsultasi Gratis via WA',
                          icon: _mainCategory == 'pertanian'
                              ? Icons.eco_rounded
                              : _mainCategory == 'peternakan'
                                  ? Icons.pets_rounded
                                  : Icons.agriculture_rounded,
                          primaryColor: const Color(0xFF16A34A),
                          actionLabel: 'Tanya WA',
                          messages: _mainCategory == 'pertanian'
                              ? const [
                                  '🌾 Padi terserang hama atau ayam drop produksi? Tanya Ahli Tani GAGE! ✍️ Tim agronomis siap membantu...',
                                  '🌱 Padi atau jagung menguning terserang wereng? Tanya dokter tanaman GAGE gratis!',
                                  '🧪 Butuh rekomendasi takaran pupuk NPK & obat gulma tepat dosis? Hubungi tim agronomi kami.',
                                  '🚜 Petani Pracimantoro bisa konsultasi kesuburan tanah & penyakit tanaman via WA resmi.',
                                ]
                              : _mainCategory == 'peternakan'
                                  ? const [
                                      '🐔 Ayam drop produksi atau sapi kurang nafsu makan? Tanya Ahli Nutrisi & Dokter Ternak GAGE! ✍️',
                                      '🌾 Padi terserang hama atau ayam drop produksi? Tanya Ahli Tani GAGE! ✍️ Tim dokter hewan siap membantu...',
                                      '💊 Panduan gratis jadwal vaksinasi unggas & perawatan ternak sapi kambing Pracimantoro.',
                                      '🥛 Tanya ketersediaan pakan konsentrat & vitamin ternak bergaransi resmi langsung ke ahlinya.',
                                    ]
                                  : const [
                                      '🚜 Butuh sewa traktor bajak sawah, alkon pompa air irigasi, atau perontok padi? Tanya jadwal operator di sini! ✍️',
                                      '🌾 Padi terserang hama atau ayam drop produksi? Tanya Ahli Tani GAGE! ✍️ Tim kami siap melayani se-Pracimantoro.',
                                    ],
                          onTap: _openConsultationWhatsApp,
                        ),
                      ),
                      // Cart Summary Bar (Tampil Jika Ada Barang di Keranjang Bersama)
                      if (cart.items.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            border: Border(top: BorderSide(color: Colors.green.shade100)),
                          ),
                          child: Row(
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${cart.totalItemCount} Barang (${cart.merchantCount} Toko)',
                                    style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    currencyFormatter.format(cart.subtotal),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF16A34A),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (ctx) => const CheckoutScreen()),
                                  );
                                },
                                child: const Row(
                                  children: [
                                    Text('Lihat Keranjang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                                    SizedBox(width: 4),
                                    Icon(Icons.arrow_forward_rounded, size: 16),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // WIDGET HELPER BUTTON TABS
  // ===========================================================================
  Widget _buildMainTabButton({
    required String id,
    required String label,
    required IconData icon,
    required bool isActive,
    String? badge,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _mainCategory = id;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF15803D) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 15, color: isActive ? Colors.white : Colors.grey.shade600),
                  if (badge != null) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.amber.shade300 : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey.shade700,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubPillButton({
    required String label,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF166534) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isActive ? const Color(0xFF166534) : Colors.grey.shade300),
            boxShadow: isActive
                ? [
                    BoxShadow(color: const Color(0xFF166534).withValues(alpha: 0.2), blurRadius: 6, offset: const Offset(0, 2)),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isActive ? Colors.white : Colors.black87),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
