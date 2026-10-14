import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/location_service.dart';
import 'package:gage_app/core/services/osm_geocoding_service.dart';
import 'package:gage_app/features/babe/presentation/babe_detail_screen.dart';
import 'package:gage_app/features/babe/presentation/babe_sell_form_screen.dart';
import 'package:gage_app/features/babe/presentation/babe_favorite_screen.dart';
import 'package:gage_app/shared/widgets/location_picker_sheet.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/adaptive_speech_bubble.dart';
import 'package:gage_app/shared/widgets/seamless_floating_cart_bar.dart';
import 'package:gage_app/shared/widgets/gage_service_header.dart';

class BabeScreen extends StatefulWidget {
  const BabeScreen({super.key});

  @override
  State<BabeScreen> createState() => _BabeScreenState();
}

class _BabeScreenState extends State<BabeScreen> {
  String _selectedCategory = 'Semua';
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchCtrl = TextEditingController();
  String _deliveryLocation = 'Mendeteksi titik GPS Anda...';
  final Set<String> _favoriteItemIds = {};
  final bool _showFavoritesOnly = false;
  List<Map<String, dynamic>> _babeHistory = [];
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<String> _categories = [
    'Semua',
    'Gadget & Elektronik',
    'Sepeda & Otomotif',
    'Perkakas & Alat Rumah',
    'Perabotan',
  ];

  final List<Map<String, dynamic>> _babeItems = [
    {
      'id': 'babe-gdt-01',
      'name': 'iPhone 11 128GB Black Mulus Like New',
      'category': 'Gadget & Elektronik',
      'condition': 'Mulus 92% • Normal Total',
      'qcNote': 'Fisik 92% mulus, Baterai Health 87%, TrueTone & FaceID aktif normal, IMEI Kemenperin terdaftar resmi, fullset box OEM.',
      'sellerPrice': 3500000,
      'price': 3850000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery',
      'image': 'assets/images/babe_iphone_11.jpg',
      'images': [
        'assets/images/babe_iphone_11.jpg',
        'assets/images/hero_promo_1.png',
        'assets/images/promo_banner_1.png',
      ],
      'icon': Icons.phone_iphone_rounded,
      'specs': {
        'Kapasitas': '128 GB',
        'RAM': '4 GB',
        'Baterai': '87% Original',
        'Kelengkapan': 'Fullset Box + Kabel Lightning',
        'Status Sinyal': 'All Operator Permanen',
      },
    },
    {
      'id': 'babe-gdt-02',
      'name': 'Smart TV Samsung 43 Inch 4K UHD Crystal',
      'category': 'Gadget & Elektronik',
      'condition': 'Mulus 95% • Layar Jernih',
      'qcNote': 'Panel layar jernih tanpa dead-pixel, remote original, Wi-Fi lancar, speaker Dolby 20W stereo bulat, kardus masih ada.',
      'sellerPrice': 2225000,
      'price': 2450000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery (GAGE Car)',
      'image': 'assets/images/babe_smart_tv.jpg',
      'images': [
        'assets/images/babe_smart_tv.jpg',
        'assets/images/promo_banner_1.png',
        'assets/images/hero_banner_1.png',
      ],
      'icon': Icons.tv_rounded,
      'specs': {
        'Ukuran Layar': '43 Inch 4K UHD (3840 x 2160)',
        'Sistem Operasi': 'Tizen Smart Hub OS',
        'Konektivitas': 'Wi-Fi 5, Bluetooth, HDMI 3x, USB 2x',
        'Kelengkapan': 'Unit TV, Kaki Stand, Remote Magic, Kardus',
      },
    },
    {
      'id': 'babe-oto-01',
      'name': 'Sepeda Hybrid Polygon Heist 2.0 Alloy 700c',
      'category': 'Sepeda & Otomotif',
      'condition': 'Kondisi 90% • Siap Gowes',
      'qcNote': 'Frame alloy mulus tanpa retak/penyok, groupset Shimano 3x8 speed presisi, rem cakram mekanik pakem, ban tebal 85%.',
      'sellerPrice': 1770000,
      'price': 1950000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery',
      'image': 'assets/images/babe_polygon_bike.jpg',
      'images': [
        'assets/images/babe_polygon_bike.jpg',
        'assets/images/hero_promo_2.png',
        'assets/images/promo_banner_2.png',
      ],
      'icon': Icons.directions_bike_rounded,
      'specs': {
        'Frame': 'ALX 6061 Alloy Hybrid Size M',
        'Drivetrain': 'Shimano Altus 3x8 Speed',
        'Pengereman': 'Tektro Mechanical Disc Brake',
        'Roda': 'Double Wall Alloy 700x38c Kenda',
      },
    },
    {
      'id': 'babe-oto-02',
      'name': 'Helm Full Face KYT TT Course D-City Original',
      'category': 'Sepeda & Otomotif',
      'condition': 'Mulus 96% • Busa Bersih Wangi',
      'qcNote': 'Busa pipi tebal wangi baru dicuci steam, visor clear flat minim goresan, tali DD-ring standar balap kuat aman, sarung helm ada.',
      'sellerPrice': 590000,
      'price': 650000,
      'isNego': false,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery',
      'image': 'assets/images/babe_kyt_helmet.jpg',
      'images': [
        'assets/images/babe_kyt_helmet.jpg',
        'assets/images/promo_banner_2.png',
      ],
      'icon': Icons.sports_motorsports_rounded,
      'specs': {
        'Ukuran': 'Size L (Lingkar Kepala 59-60 cm)',
        'Visor': 'Flat Clear Pinlock Ready',
        'Sistem Kuncian': 'Double D-Ring Balap',
        'Kelengkapan': 'Unit Helm & Sarung Asli KYT',
      },
    },
    {
      'id': 'babe-pkk-01',
      'name': 'Mesin Bor Impact Drill Maktec MT80B Heavy Duty',
      'category': 'Perkakas & Alat Rumah',
      'condition': 'Kondisi 88% • Putaran Kuat Normal',
      'qcNote': 'Motor bertenaga 500W, putaran bolak-balik normal, carbon brush tebal, kepala chuck 13mm kokoh, bonus handle & pengukur kedalaman.',
      'sellerPrice': 268000,
      'price': 295000,
      'isNego': false,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery',
      'image': 'assets/images/babe_impact_drill.jpg',
      'images': [
        'assets/images/babe_impact_drill.jpg',
        'assets/images/prod_traktor.png',
      ],
      'icon': Icons.handyman_rounded,
      'specs': {
        'Daya Listrik': '500 Watt (220V)',
        'Kapasitas Chuck': '13 mm Keyed',
        'Mode Kerja': 'Drill & Hammer Drill Tembok',
        'Kecepatan': '0 - 2.900 RPM Variable Speed',
      },
    },
    {
      'id': 'babe-pkk-02',
      'name': 'Kompresor Angin Lakoni Imola 75 3/4 HP Silent',
      'category': 'Perkakas & Alat Rumah',
      'condition': 'Kondisi 91% • Pengisian 0-8 Bar Cepat',
      'qcNote': 'Pengisian angin cepat 0-8 bar dalam 2 menit, oli baru ganti, tabung 10L bersih, suara halus normal, bonus selang spiral 6m & air duster.',
      'sellerPrice': 750000,
      'price': 825000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery (GAGE Car)',
      'image': 'assets/images/babe_impact_drill.jpg',
      'images': [
        'assets/images/babe_impact_drill.jpg',
        'assets/images/prod_traktor.png',
        'assets/images/promo_banner_3.png',
      ],
      'icon': Icons.construction_rounded,
      'specs': {
        'Daya': '3/4 HP (550 Watt)',
        'Kapasitas Tangki': '10 Liter',
        'Tekanan Max': '8 Bar (116 PSI)',
        'Kelengkapan': 'Unit Kompresor, Selang Spiral 6m, Gun Duster',
      },
    },
    {
      'id': 'babe-prb-01',
      'name': 'Meja Kerja Minimalis Kayu Jati Belanda Kokoh',
      'category': 'Perabotan',
      'condition': 'Mulus 94% • Kokoh Anti Goyang',
      'qcNote': 'Kayu solid jati belanda finishing vernis natural mengkilap anti rayap, kaki besi hollow 4x4 cm kokoh anti-goyang, ukuran 120x60x75 cm.',
      'sellerPrice': 409000,
      'price': 450000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery (GAGE Car)',
      'image': 'assets/images/babe_meja_jati.jpg',
      'images': [
        'assets/images/babe_meja_jati.jpg',
        'assets/images/hero_banner_1.png',
      ],
      'icon': Icons.table_restaurant_rounded,
      'specs': {
        'Material Daun': 'Kayu Jati Belanda Solid Oven (Tebal 2.5 cm)',
        'Rangka Kaki': 'Besi Hollow 4x4 cm Cat Doff Hitam',
        'Dimensi': '120 cm (P) x 60 cm (L) x 75 cm (T)',
        'Daya Beban': 'Kuat hingga 80 kg',
      },
    },
    {
      'id': 'babe-prb-02',
      'name': 'Lemari Pakaian 2 Pintu Panel Cermin Modern',
      'category': 'Perabotan',
      'condition': 'Mulus 90% • Bersih Siap Pakai',
      'qcNote': 'Engsel pintu soft-close normal tidak berisik, cermin utuh bening tanpa retak, rak dan gantungan baju kokoh bersih, warna Sonoma Oak modern.',
      'sellerPrice': 618000,
      'price': 680000,
      'isNego': true,
      'warranty': 'Garansi Toko Resmi GAGE 48 Jam',
      'delivery': 'Diantar langsung ke rumah via GAGE Delivery (GAGE Car)',
      'image': 'assets/images/babe_meja_jati.jpg',
      'images': [
        'assets/images/babe_meja_jati.jpg',
        'assets/images/hero_banner_2.png',
      ],
      'icon': Icons.inventory_2_rounded,
      'specs': {
        'Material': 'MDF Solid Grade E1 Lapisan Paper Foil Anti Lembab',
        'Fitur': 'Cermin Full Badan Pintu Kanan, Kunci 2 Pintu',
        'Dimensi': '80 cm (P) x 43 cm (L) x 180 cm (T)',
        'Kapasitas': 'Gantungan Chrome & 3 Ruang Rak Bawah',
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _initDeliveryLocation();
    _loadBabeLocalData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchCtrl.dispose();
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
    } catch (_) {
      if (mounted) {
        setState(() {
          _deliveryLocation = 'Kecamatan Pracimantoro, Wonogiri';
        });
      }
    }
  }

  Future<void> _loadBabeLocalData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favList = prefs.getStringList('gage_babe_favorites') ?? [];
      final histList = prefs.getStringList('gage_babe_history') ?? [];
      if (mounted) {
        setState(() {
          _favoriteItemIds.clear();
          _favoriteItemIds.addAll(favList);
          _babeHistory = histList.map((e) {
            try {
              return jsonDecode(e) as Map<String, dynamic>;
            } catch (_) {
              return <String, dynamic>{'title': e, 'time': '-'};
            }
          }).toList();
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleFavorite(String itemId) async {
    setState(() {
      if (_favoriteItemIds.contains(itemId)) {
        _favoriteItemIds.remove(itemId);
      } else {
        _favoriteItemIds.add(itemId);
      }
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('gage_babe_favorites', _favoriteItemIds.toList());
    } catch (_) {}
  }

  void _showFormTitipJual(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const BabeSellFormScreen()),
    ).then((_) => _loadBabeLocalData());
  }

  void _openItemDetailScreen(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => BabeDetailScreen(item: item)),
    ).then((_) => _loadBabeLocalData());
  }

  void _showLocationPicker() {
    LocationPickerSheet.show(
      context,
      title: 'Pilih Lokasi Pengantaran BaBe',
      onSelected: (title, fullAddress, latLng) {
        setState(() {
          _deliveryLocation = title.isNotEmpty ? title : fullAddress;
        });
      },
    );
  }

  void _showHistoryModal() {
    GageFloatingSheet.show(
      context: context,
      isScrollControlled: true,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (sheetCtx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, color: GageTheme.primary, size: 24),
                    const SizedBox(width: 10),
                    const Text(
                      'Riwayat Belanja & Titip Jual BaBe',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(sheetCtx),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                if (_babeHistory.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: GageTheme.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.history_rounded, size: 36, color: GageTheme.primary),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Belum Ada Riwayat Transaksi BaBe',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.black87),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Seluruh transaksi pembelian, tawar harga (nego), dan pengajuan titip jual barang bekas Anda tercatat khusus di sini.',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600, height: 1.35),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: GageTheme.primary,
                                side: const BorderSide(color: GageTheme.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.explore_rounded, size: 18),
                              label: const Text('Jelajahi Produk BaBe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                              onPressed: () => Navigator.pop(sheetCtx),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _babeHistory.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (c, idx) {
                        final hist = _babeHistory[idx];
                        final isNego = hist['type'] == 'nego';
                        final isTitip = hist['type'] == 'titip_jual';
                        final title = hist['title'] ?? hist['productName'] ?? 'Transaksi BaBe';
                        final status = hist['status'] ?? 'Menunggu';
                        final price = hist['finalPrice'] ?? hist['price'] ?? 0;
                        final date = hist['timestamp'] ?? '-';

                        Color badgeColor = const Color(0xFF16A34A);
                        Color badgeBg = const Color(0xFFDCFCE7);
                        if (status.toString().contains('Menunggu Review')) {
                          badgeColor = Colors.amber.shade900;
                          badgeBg = const Color(0xFFFEF3C7);
                        } else if (status.toString().contains('Garansi Keamanan') ||
                            status.toString().contains('Pembayaran') ||
                            status.toString().contains('WA')) {
                          badgeColor = const Color(0xFF2563EB);
                          badgeBg = const Color(0xFFEFF6FF);
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.grey.shade200),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 1)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isTitip ? const Color(0xFFF1F5F9) : const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      isTitip ? 'Titip Jual' : (isNego ? 'Deal Nego' : 'Pesanan BaBe'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: isTitip ? Colors.blueGrey : const Color(0xFF2563EB),
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: badgeBg,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      status.toString(),
                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: badgeColor),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                title.toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    price is int ? currencyFormatter.format(price) : price.toString(),
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 13),
                                  ),
                                  Text(
                                    date.toString(),
                                    style: TextStyle(fontSize: 10.5, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () {
                                  final msg = 'Halo Admin GAGE BaBe Pracimantoro,\n'
                                      'Saya ingin menanyakan update status untuk transaksi BaBe:\n'
                                      '📦 *${title.toString()}*\n'
                                      '🏷️ Status Saat Ini: *${status.toString()}*';
                                  final uri = Uri.parse('https://wa.me/6281234567890?text=${Uri.encodeComponent(msg)}');
                                  launchUrl(uri, mode: LaunchMode.externalApplication);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chat_outlined, size: 13, color: GageTheme.primary),
                                      const SizedBox(width: 4),
                                      const Text(
                                        'Tanya Admin CS GAGE',
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.pop(sheetCtx),
                    child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            );
        },
      ),
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



  Widget _buildProductCard(Map<String, dynamic> item) {
    final itemId = item['id'] as String;
    final isFav = _favoriteItemIds.contains(itemId);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: InkWell(
        onTap: () => _openItemDetailScreen(item),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail Foto Real Produk BaBe
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 86,
                  height: 86,
                  color: const Color(0xFFF1F5F9),
                  child: Image.asset(
                    item['image'] ?? 'assets/images/babe_iphone_11.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Center(
                      child: Icon(
                        item['icon'] as IconData? ?? Icons.inventory_2_rounded,
                        color: GageTheme.primary,
                        size: 38,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Label Kondisi Realistis
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Text(
                            item['condition'],
                            style: const TextStyle(
                              color: Color(0xFF334155),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => _toggleFavorite(itemId),
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
                      item['name'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          currencyFormatter.format(item['price']),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFE52320),
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: item['isNego'] ? Colors.orange.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['isNego'] ? 'Bisa Nego' : 'Harga Pas',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: item['isNego'] ? Colors.deepOrange : Colors.blue.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.delivery_dining_rounded, color: Colors.grey, size: 14),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item['delivery'],
                            style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerManager = context.watch<BannerManagerService>();
    final babeBanner = bannerManager.getBanner('babe');
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredItems = _babeItems.where((item) {
      final matchesCat = _selectedCategory == 'Semua' || item['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase().trim();
      final matchesSearch = q.isEmpty ||
          (item['name'] as String).toLowerCase().contains(q) ||
          (item['category'] as String).toLowerCase().contains(q);
      final matchesFav = !_showFavoritesOnly || _favoriteItemIds.contains(item['id'] as String);
      return matchesCat && matchesSearch && matchesFav;
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
                  imageAsset: babeBanner.imagePath,
                  fallbackTitle: 'GAGE BABE',
                  scrollController: _scrollController,
                  overlayChild: AdaptiveSpeechBubble(
                    fullText: 'Titip jual barang bekas gratis di BaBe, klik di sini',
                    backgroundColor: const Color(0xFF4F46E5),
                    icon: Icons.sell_rounded,
                    onTap: () => _showFormTitipJual(context),
                  ),
                ),

                const SizedBox(height: 38),

                // Responsive container wrapper for Tablet & Phone
                Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: isTablet ? 760 : double.infinity),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 2. Category Horizontal Filter Chips
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            scrollDirection: Axis.horizontal,
                            itemCount: _categories.length,
                            separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                            itemBuilder: (ctx, idx) {
                              final cat = _categories[idx];
                              final isSelected = _selectedCategory == cat;
                              return ChoiceChip(
                                label: Text(cat),
                                selected: isSelected,
                                onSelected: (_) => setState(() => _selectedCategory = cat),
                                selectedColor: GageTheme.primary.withValues(alpha: 0.15),
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                ),
                                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                                  ),
                                ),
                                visualDensity: VisualDensity.compact,
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 3. Section Title
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Koleksi Barang (${filteredItems.length})',
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

                        const SizedBox(height: 8),

                        // 4. List Barang Bekas (Adaptif Multi-Kolom saat Tablet)
                        if (filteredItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(32),
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade400),
                                const SizedBox(height: 10),
                                Text(
                                  'Tidak ada barang ditemukan',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _showFavoritesOnly
                                      ? 'Belum ada barang yang ditandai favorit di menu BaBe.'
                                      : 'Coba ganti kata kunci pencarian atau kategori.',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                ),
                              ],
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
                                mainAxisExtent: 138,
                              ),
                              itemCount: filteredItems.length,
                              itemBuilder: (ctx, idx) => _buildProductCard(filteredItems[idx]),
                            ),
                          )
                        else
                          ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: filteredItems.length,
                            itemBuilder: (ctx, idx) => _buildProductCard(filteredItems[idx]),
                          ),

                        const SizedBox(height: 90),
                      ],
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
                  MaterialPageRoute(builder: (ctx) => const BabeFavoriteScreen()),
                );
              },
              onHistoryTap: _showHistoryModal,
              searchHint: 'Cari gadget, motor, perabot bekas...',
              searchController: _searchCtrl,
              onSearchChanged: (val) => setState(() => _searchQuery = val),
              serviceIcon: Icons.recycling_rounded,
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
