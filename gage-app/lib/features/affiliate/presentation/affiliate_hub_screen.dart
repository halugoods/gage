import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

/// AffiliateHubScreen - GAGE Cuan: Ekosistem Afiliasi & Kreator Video
///
/// Menggunakan GAGE Clean White Design System:
/// - AppBar putih bersih dengan aksen merah GageTheme.primary
/// - Header kartu saldo komisi siap tarik + tombol kapsul 1-klik ke GAGEPay
/// - Pilar 1: Kartu Ajak Teman (Referral WhatsApp & Kode Unik)
/// - Segmented Tab Switcher Kapsul Penuh (BorderRadius.circular(999))
/// - Tab 1: Video Saya (Konten Kreator, views, pesanan, dan status kurasi)
/// - Tab 2: Katalog Cuan (Produk komisi tinggi & simulasi markup merchant 100% utuh)
/// - Tab 3: Riwayat Komisi (Mutasi komisi masuk dan pencairan dana)
class AffiliateHubScreen extends StatefulWidget {
  const AffiliateHubScreen({super.key});

  @override
  State<AffiliateHubScreen> createState() => _AffiliateHubScreenState();
}

class _AffiliateHubScreenState extends State<AffiliateHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  int _availableCommission = 148500;
  final String _referralCode = 'GAGE-CUAN-RATIH';

  // Daftar Konten Video Kreator dengan Status Kerkun Riil
  final List<Map<String, dynamic>> _creatorVideos = [
    {
      'id': 'vt-01',
      'title': 'Mukbang Dimsum Sewu Kuah Pedas Mantap!',
      'productName': 'Dimsum Sewu Spesial Isi 10',
      'merchant': 'Dimsum Sewu Pracimantoro',
      'hashtag': '#GAGE_DIMSUM #GAGE_AFFILIATE',
      'views': '4.8k',
      'clicks': 120,
      'orders': 18,
      'commission': 36000,
      'status': 'APPROVED', // APPROVED, REVIEW, REJECTED
      'image': 'assets/images/resto_dimsum_sewu.png',
      'productPrice': 20000,
    },
    {
      'id': 'vt-02',
      'title': 'Review Jujur Rocket Chicken Sambal Bawang',
      'productName': 'Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)',
      'merchant': 'Rocket Chicken Pracimantoro',
      'hashtag': '#GAGE_RC01 #GAGE_AFFILIATE',
      'views': '6.2k',
      'clicks': 198,
      'orders': 22,
      'commission': 88000,
      'status': 'APPROVED',
      'image': 'assets/images/culinary_mart.png',
      'productPrice': 16000,
    },
    {
      'id': 'vt-03',
      'title': 'Unboxing Cat Tembok Avian TB Bangkit',
      'productName': 'Cat Kayu & Besi Avian 1 Kg',
      'merchant': 'TB Bangkit Pracimantoro',
      'hashtag': '#GAGE_CATAVIAN #GAGE_AFFILIATE',
      'views': '1.2k',
      'clicks': 30,
      'orders': 2,
      'commission': 4000,
      'status': 'REVIEW',
      'image': 'assets/images/prod_cat.png',
      'productPrice': 72000,
    },
    {
      'id': 'vt-04',
      'title': 'Tips Masak Beras Pulen C4 Super',
      'productName': 'Beras C4 Super Ramos Pulen 5kg',
      'merchant': 'Toko Sembako Berkah Fajar',
      'hashtag': '#GAGE_BERASC4 #GAGE_AFFILIATE',
      'views': '850',
      'clicks': 0,
      'orders': 0,
      'commission': 0,
      'status': 'REJECTED',
      'rejectReason': 'Tagar resmi produk mitra tidak terdeteksi pada caption video.',
      'image': 'assets/images/prod_beras.png',
      'productPrice': 68000,
    },
  ];

  // Daftar Produk Komisi Tinggi Siap Di-share & Dibuat Video
  final List<Map<String, dynamic>> _highCommissionProducts = [
    {
      'id': 'cuan-rc-01',
      'name': 'Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)',
      'merchant': 'Rocket Chicken Pracimantoro',
      'category': 'Kuliner',
      'price': 16000,
      'offlinePrice': 12800,
      'commission': 1600,
      'rate': '10%',
      'sold': '1.4k+ terjual',
      'rating': 4.9,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'rc-paket-1',
      'hashtag': '#GAGE_RC01',
      'merchantData': {
        'id': 'mch-rc-01',
        'name': 'Rocket Chicken Pracimantoro',
        'category': 'Kuliner Cepat Saji',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.9,
      },
    },
    {
      'id': 'cuan-mie-01',
      'name': 'Mie Ayam Spesial Pangsit Bakso Jumbo',
      'merchant': 'Mie Ayam & Bakso Pak Kumis',
      'category': 'Kuliner',
      'price': 15000,
      'offlinePrice': 12000,
      'commission': 1800,
      'rate': '12%',
      'sold': '890+ terjual',
      'rating': 4.8,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'mie-ayam-jumbo',
      'hashtag': '#GAGE_MIEJUMBO',
      'merchantData': {
        'id': 'mch-mie-01',
        'name': 'Mie Ayam & Bakso Pak Kumis',
        'category': 'Bakmie & Bakso',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.8,
      },
    },
    {
      'id': 'cuan-seblak-01',
      'name': 'Seblak Prasmanan Ceker Pedas Nampol Level 3',
      'merchant': 'Seblak Prasmanan Teh Eneng',
      'category': 'Kuliner',
      'price': 18000,
      'offlinePrice': 14400,
      'commission': 2000,
      'rate': '11%',
      'sold': '650+ terjual',
      'rating': 4.7,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'seblak-prasmanan',
      'hashtag': '#GAGE_SEBLAK',
      'merchantData': {
        'id': 'mch-seblak-01',
        'name': 'Seblak Prasmanan Teh Eneng',
        'category': 'Kuliner Pedas',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.7,
      },
    },
    {
      'id': 'cuan-sembako-01',
      'name': 'Beras C4 Super Ramos Pulen 5kg',
      'merchant': 'Toko Sembako Berkah Fajar',
      'category': 'Sembako',
      'price': 68000,
      'offlinePrice': 54400,
      'commission': 3500,
      'rate': '5%',
      'sold': '420+ terjual',
      'rating': 4.9,
      'image': 'assets/images/prod_beras.png',
      'slug': 'beras-c4-5kg',
      'hashtag': '#GAGE_BERASC4',
      'merchantData': {
        'id': 'shop-berkah-fajar',
        'name': 'Toko Sembako Berkah Fajar',
        'category': 'Sembako',
        'image': 'assets/images/prod_beras.png',
        'rating': 4.9,
      },
    },
    {
      'id': 'cuan-farm-01',
      'name': 'Pupuk NPK Mutiara 16-16-16 Kemasan 1kg',
      'merchant': 'Kios Tani Subur Makmur',
      'category': 'Pertanian',
      'price': 18000,
      'offlinePrice': 14400,
      'commission': 1500,
      'rate': '8%',
      'sold': '310+ terjual',
      'rating': 4.8,
      'image': 'assets/images/prod_pupuk.png',
      'slug': 'pupuk-npk-1kg',
      'hashtag': '#GAGE_NPKMUTIARA',
      'merchantData': {
        'id': 'farm-kios-subur',
        'name': 'Kios Tani Subur Makmur',
        'category': 'Pertanian',
        'image': 'assets/images/prod_pupuk.png',
        'rating': 4.8,
      },
    },
    {
      'id': 'cuan-build-01',
      'name': 'Semen Gresik UltraPro Premium 40kg',
      'merchant': 'TB Bangkit Pracimantoro',
      'category': 'Bangunan',
      'price': 54000,
      'offlinePrice': 43200,
      'commission': 2500,
      'rate': '5%',
      'sold': '560+ terjual',
      'rating': 4.9,
      'image': 'assets/images/prod_semen.png',
      'slug': 'semen-gresik-40kg',
      'hashtag': '#GAGE_SEMENGRESIK',
      'merchantData': {
        'id': 'build-tb-bangkit',
        'name': 'TB Bangkit Pracimantoro',
        'category': 'Bahan Bangunan',
        'image': 'assets/images/prod_semen.png',
        'rating': 4.9,
      },
    },
  ];

  // Riwayat Penarikan Dana & Komisi Masuk
  final List<Map<String, dynamic>> _withdrawalHistory = [
    {
      'id': 'WD-98421',
      'date': '05 Nov 2026, 14:20 WIB',
      'destination': 'Saldo GAGEPay (Instan)',
      'amount': 150000,
      'status': 'Berhasil Ditransfer',
      'isSuccess': true,
      'type': 'WITHDRAW',
    },
    {
      'id': 'KM-88123',
      'date': '04 Nov 2026, 19:12 WIB',
      'destination': 'Komisi Pesanan #ORD-98214 (Rocket Chicken)',
      'amount': 3600,
      'status': 'Komisi Masuk',
      'isSuccess': true,
      'type': 'EARNING',
    },
    {
      'id': 'KM-88102',
      'date': '03 Nov 2026, 12:45 WIB',
      'destination': 'Komisi Pesanan #ORD-97812 (Dimsum Sewu)',
      'amount': 2000,
      'status': 'Komisi Masuk',
      'isSuccess': true,
      'type': 'EARNING',
    },
    {
      'id': 'WD-82104',
      'date': '02 Nov 2026, 09:15 WIB',
      'destination': 'Saldo GAGEPay (Instan)',
      'amount': 350000,
      'status': 'Berhasil Ditransfer',
      'isSuccess': true,
      'type': 'WITHDRAW',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _copyReferralCode() {
    HapticFeedback.selectionClick();
    Clipboard.setData(ClipboardData(text: _referralCode));
    GageToast.show(
      context,
      'Kode referral $_referralCode berhasil disalin!',
      type: GageToastType.success,
    );
  }

  void _shareReferralToWhatsApp() {
    HapticFeedback.selectionClick();
    final message = AffiliateCommissionService.generateReferralShareText(
      referralCode: _referralCode,
      userName: 'Ratih Pracimantoro',
    );
    Clipboard.setData(ClipboardData(text: message));
    GageToast.show(
      context,
      'Teks ajakan berhasil disalin! Buka WhatsApp untuk membagikan ke teman.',
      type: GageToastType.success,
    );
  }

  void _copyProductLink(Map<String, dynamic> product) {
    HapticFeedback.selectionClick();
    final link = 'https://gage.co.id/item/${product['slug']}?ref=$_referralCode';
    final shareText = AffiliateCommissionService.generateProductShareText(
      productName: product['name'] as String,
      merchantName: product['merchant'] as String,
      price: product['price'] as int,
      affiliateLink: link,
    );
    Clipboard.setData(ClipboardData(text: shareText));
    GageToast.show(
      context,
      'Link afiliasi disalin! Bagikan ke WhatsApp atau media sosial Anda.',
      type: GageToastType.success,
    );
  }


  void _showTestKerkunDialog(Map<String, dynamic> video) {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_rounded, size: 14, color: Color(0xFF854D0E)),
                            SizedBox(width: 4),
                            Text(
                              'KERANJANG KUNING',
                              style: TextStyle(
                                color: Color(0xFF854D0E),
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Simulasi Video',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : const Color(0xFF64748B),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white70 : Colors.black54,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                video['title'] ?? 'Judul Video',
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Tagar Terverifikasi: ${video['hashtag']}',
                style: const TextStyle(
                  color: Color(0xFF0284C7),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              // Yellow Basket Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 1.2),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        video['image'] ?? 'assets/images/culinary_mart.png',
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 52,
                          height: 52,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.fastfood, color: Colors.grey),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video['productName'] ?? 'Nama Produk',
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video['merchant'] ?? 'Mitra GAGE',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(video['productPrice'] ?? 16000),
                            style: const TextStyle(
                              color: Color(0xFFD97706),
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        GageToast.show(
                          context,
                          'Alur Kerkun Valid! Pesanan otomatis mengunci komisi affiliator Anda.',
                          type: GageToastType.success,
                        );
                      },
                      child: const Text('Beli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '✓ Terkunci ke kode affiliator: $_referralCode\n✓ Komisi otomatis cair saat pesanan dinyatakan SELESAI oleh customer.',
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                  fontSize: 11.5,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitVideoSheet() {
    HapticFeedback.selectionClick();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String selectedProduct = _highCommissionProducts.first['name'];

    GageFloatingSheet.show(
      context: context,
      title: 'Upload Konten Video Baru',
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tautkan link video atau unggah kreasi Anda agar disematkan Keranjang Kuning resmi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Judul / Deskripsi Video',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: titleCtrl,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: Review Renyah Paket Geprek Rocket Chicken!',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Link Video TikTok / Reels (Opsional)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: urlCtrl,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Contoh: https://vt.tiktok.com/ZS.../',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pilih Produk Mitra yang Dipromosikan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedProduct,
                        dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                        items: _highCommissionProducts.map((p) {
                          return DropdownMenuItem<String>(
                            value: p['name'] as String,
                            child: Text(
                              p['name'] as String,
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setSheetState(() => selectedProduct = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: () {
                        final t = titleCtrl.text.trim();
                        if (t.isEmpty) {
                          GageToast.show(context, 'Judul video tidak boleh kosong', type: GageToastType.warning);
                          return;
                        }
                        Navigator.pop(sheetContext);
                        setState(() {
                          _creatorVideos.insert(0, {
                            'id': 'vt-${DateTime.now().millisecondsSinceEpoch}',
                            'title': t,
                            'productName': selectedProduct,
                            'merchant': 'Mitra GAGE Terverifikasi',
                            'hashtag': '#GAGE_VIRAL #GAGE_AFFILIATE',
                            'views': '0',
                            'clicks': 0,
                            'orders': 0,
                            'commission': 0,
                            'status': 'REVIEW',
                            'image': 'assets/images/culinary_mart.png',
                            'productPrice': 16000,
                          });
                        });
                        GageToast.show(
                          context,
                          'Video berhasil disubmit! Sedang dikurasi oleh tim GAGE.',
                          type: GageToastType.success,
                        );
                      },
                      child: const Text('Kirim untuk Kurasi Kerkun', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _withdrawToGagePay() {
    HapticFeedback.selectionClick();
    if (_availableCommission <= 0) {
      GageToast.show(
        context,
        'Saldo komisi Anda belum mencukupi untuk ditarik',
        type: GageToastType.warning,
      );
      return;
    }

    final amount = _availableCommission;
    try {
      context.read<WalletProvider>().topUp(amount);
    } catch (_) {}

    setState(() {
      _withdrawalHistory.insert(0, {
        'id': 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'date': 'Hari ini, ${DateFormat('HH:mm').format(DateTime.now())} WIB',
        'destination': 'Saldo GAGEPay (Instan)',
        'amount': amount,
        'status': 'Berhasil Ditransfer',
        'isSuccess': true,
        'type': 'WITHDRAW',
      });
      _availableCommission = 0;
    });

    GageToast.show(
      context,
      'Penarikan ${_currencyFormat.format(amount)} langsung masuk ke GAGEPay Anda!',
      type: GageToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GAGE Cuan',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              'Pusat Afiliasi & Kreator',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 22, color: GageTheme.primary),
            onPressed: () {
              GageToast.show(
                context,
                'Panduan: Bagikan link referral, salin link produk, atau upload video berkoleksi keranjang kuning!',
                type: GageToastType.info,
              );
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildCleanWhiteHeader(isDark),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  padding: const EdgeInsets.all(3),
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    onTap: (_) => HapticFeedback.selectionClick(),
                    indicator: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.white60 : const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    tabs: const [
                      Tab(text: 'Video Saya'),
                      Tab(text: 'Katalog Cuan'),
                      Tab(text: 'Riwayat Komisi'),
                    ],
                  ),
                ),
                isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreatorVideosTab(isDark),
            _buildProductsTab(isDark),
            _buildWithdrawalHistoryTab(isDark),
          ],
        ),
      ),
    );
  }

  /// Header Bersih GAGE Cuan (White Theme)
  Widget _buildCleanWhiteHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Kartu Saldo Komisi
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Saldo Komisi Siap Tarik',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white70 : const Color(0xFF64748B),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF16A34A)),
                          SizedBox(width: 4),
                          Text(
                            'Instan Rp 0 Admin',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Text(
                        _currencyFormat.format(_availableCommission),
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: const StadiumBorder(),
                        elevation: 0,
                      ),
                      onPressed: _withdrawToGagePay,
                      icon: const Icon(Icons.account_balance_wallet_rounded, size: 15),
                      label: const Text(
                        'Tarik ke GAGEPay',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 12),
                // Analytics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('12.4k', 'Views Konten', isDark),
                    _buildStatItem('348', 'Klik Kerkun', isDark),
                    _buildStatItem('42', 'Pesanan Cair', isDark),
                    _buildStatItem('12', 'Teman Diajak', isDark),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Pilar 1: Kartu Ajak Teman (Referral)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFFEE2E2),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group_add_rounded, color: GageTheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Ajak Teman Cuan',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF3C7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Voucher 10rb',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFB45309),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Bagikan kode referral Anda ke WhatsApp',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _copyReferralCode,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _referralCode,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: GageTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.copy_rounded, size: 13, color: GageTheme.primary),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                InkWell(
                  onTap: _shareReferralToWhatsApp,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: const BoxDecoration(
                      color: Color(0xFF25D366),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.share_rounded, size: 15, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : const Color(0xFF64748B),
            fontSize: 10.5,
          ),
        ),
      ],
    );
  }

  // TAB 1: Konten Video Saya
  Widget _buildCreatorVideosTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Feed Konten Video Kreator',
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    'Daftar video yang aktif berkoleksi Keranjang Kuning',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: _showSubmitVideoSheet,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Upload Video', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ..._creatorVideos.map((v) => _buildVideoCard(v, isDark)),
      ],
    );
  }

  Widget _buildVideoCard(Map<String, dynamic> v, bool isDark) {
    final status = v['status'] as String;
    Color statusBg;
    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (status == 'APPROVED') {
      statusBg = const Color(0xFFDCFCE7);
      statusColor = const Color(0xFF16A34A);
      statusLabel = '✓ LOLOS KERKUN';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'REVIEW') {
      statusBg = const Color(0xFFFEF3C7);
      statusColor = const Color(0xFFD97706);
      statusLabel = '⏳ SEDANG DIREVIEW';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusBg = const Color(0xFFFFE4E6);
      statusColor = const Color(0xFFE11D48);
      statusLabel = '✕ DITOLAK';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  v['image'] as String,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 50,
                    height: 50,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.videocam_rounded, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      v['title'] as String,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Produk: ${v['productName']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(6)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 11, color: statusColor),
                          const SizedBox(width: 4),
                          Text(statusLabel, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: statusColor)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          if (status == 'APPROVED') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${v['views']} views • ${v['clicks']} klik • ${v['orders']} pesanan',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                  ),
                ),
                InkWell(
                  onTap: () => _showTestKerkunDialog(v),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: const Color(0xFFF59E0B)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, size: 12, color: Color(0xFF854D0E)),
                        SizedBox(width: 4),
                        Text(
                          'Uji Kerkun',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF854D0E)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'REVIEW') ...[
            const Text(
              '⏳ Tim kurasi GAGE sedang meninjau tautan video Anda.',
              style: TextStyle(fontSize: 11, color: Color(0xFFD97706)),
            ),
          ] else ...[
            Text(
              v['rejectReason'] as String? ?? 'Konten tidak memenuhi syarat kurasi.',
              style: const TextStyle(fontSize: 11, color: Color(0xFFE11D48)),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: Katalog Produk Komisi
  Widget _buildProductsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _highCommissionProducts.length,
      itemBuilder: (ctx, idx) {
        final p = _highCommissionProducts[idx];
        final offlinePrice = p['offlinePrice'] as int? ?? ((p['price'] as int) * 0.8).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
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
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  p['image'] as String,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 72,
                    height: 72,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.storefront_rounded, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p['name'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p['merchant'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _currencyFormat.format(p['price']),
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${_currencyFormat.format(p['commission'])} (${p['rate']})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pencairan merchant utuh: ${_currencyFormat.format(offlinePrice)} (100%)',
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              side: const BorderSide(color: GageTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _copyProductLink(p),
                            icon: const Icon(Icons.share_rounded, size: 13),
                            label: const Text('Salin Link', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFF1E293B),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: const StadiumBorder(),
                              visualDensity: VisualDensity.compact,
                              elevation: 0,
                            ),
                            onPressed: () {
                              final mData = p['merchantData'] as Map<String, dynamic>?;
                              if (mData != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (c) => RestoDetailScreen(merchant: mData)),
                                );
                              }
                            },
                            icon: const Icon(Icons.storefront_rounded, size: 13),
                            label: const Text('Buka Toko', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // TAB 3: Riwayat Komisi & Penarikan Dana
  Widget _buildWithdrawalHistoryTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _withdrawalHistory.length,
      itemBuilder: (ctx, idx) {
        final w = _withdrawalHistory[idx];
        final isWithdrawal = w['type'] == 'WITHDRAW';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isWithdrawal
                      ? GageTheme.primary.withValues(alpha: 0.1)
                      : const Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isWithdrawal ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: isWithdrawal ? GageTheme.primary : const Color(0xFF16A34A),
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      w['destination'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${w['id']} • ${w['date']}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isWithdrawal ? '-' : '+'}${_currencyFormat.format(w['amount'])}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: isWithdrawal ? GageTheme.primary : const Color(0xFF16A34A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    w['status'] as String,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: isWithdrawal ? GageTheme.primary : const Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._child, this.backgroundColor);

  final Widget _child;
  final Color backgroundColor;

  @override
  double get minExtent => 52;
  @override
  double get maxExtent => 52;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      alignment: Alignment.center,
      child: _child,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
