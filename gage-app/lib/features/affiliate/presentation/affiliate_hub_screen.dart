import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

/// AffiliateHubScreen - GAGE Cuan: Portal Resmi Kreator & Affiliator Video
/// 
/// Didesain khusus untuk kreator konten & affiliator TikTok KW:
/// - Header obsidian glassmorphism dengan saldo komisi siap tarik
/// - 1-Klik tarik saldo komisi ke GAGEPay (instan, Rp 0 biaya admin)
/// - Tab 1: Konten VT Saya & Status Kurasi Keranjang Kuning (Kerkun)
/// - Tab 2: Katalog Produk Komisi Tinggi Siap Dipromosikan (Salin Tagar Kerkun)
/// - Tab 3: Riwayat Penarikan Dana Transparan
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

  // Daftar Konten VT Kreator dengan Status Kerkun Riil
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

  // Daftar Produk Komisi Tinggi Siap Di-tagar
  final List<Map<String, dynamic>> _highCommissionProducts = [
    {
      'id': 'cuan-rc-01',
      'name': 'Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)',
      'merchant': 'Rocket Chicken Pracimantoro',
      'category': 'Kuliner',
      'price': 16000,
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

  // Riwayat Penarikan Dana Komisi
  final List<Map<String, dynamic>> _withdrawalHistory = [
    {
      'id': 'WD-77291',
      'date': '07 Nov 2026, 14:22 WIB',
      'destination': 'Saldo GAGEPay (0812***4321)',
      'amount': 150000,
      'status': 'Berhasil Ditransfer',
      'isSuccess': true,
    },
    {
      'id': 'WD-76410',
      'date': '02 Nov 2026, 09:15 WIB',
      'destination': 'Saldo GAGEPay (0812***4321)',
      'amount': 350000,
      'status': 'Berhasil Ditransfer',
      'isSuccess': true,
    },
    {
      'id': 'WD-75019',
      'date': '28 Okt 2026, 16:40 WIB',
      'destination': 'Rekening BCA (***7890)',
      'amount': 200000,
      'status': 'Berhasil Ditransfer',
      'isSuccess': true,
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
    HapticFeedback.lightImpact();
    Clipboard.setData(ClipboardData(text: _referralCode));
    GageToast.show(
      context,
      'Kode referral $_referralCode berhasil disalin!',
      type: GageToastType.success,
    );
  }

  void _copyHashtag(String tag) {
    HapticFeedback.lightImpact();
    final text = '$tag #GAGE_AFFILIATE #GAGE_KULINER';
    Clipboard.setData(ClipboardData(text: text));
    GageToast.show(
      context,
      'Tagar Kerkun disalin: $text',
      type: GageToastType.success,
    );
  }

  void _showTestKerkunDialog(Map<String, dynamic> video) {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE52320).withValues(alpha: 0.4), width: 1.5),
            boxShadow: const [
              BoxShadow(color: Colors.black87, blurRadius: 24, offset: Offset(0, 10)),
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
                          color: const Color(0xFFFEF08A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_rounded, size: 14, color: Color(0xFF854D0E)),
                            SizedBox(width: 4),
                            Text('KERANJANG KUNING', style: TextStyle(color: Color(0xFF854D0E), fontSize: 10, fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text('Simulasi VT', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                video['title'] ?? 'Judul Video',
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                'Tagar Terverifikasi: ${video['hashtag']}',
                style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              // Yellow Basket Interactive Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFACC15).withValues(alpha: 0.5), width: 1.2),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        video['image'] ?? 'assets/images/culinary_mart.png',
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 56,
                          height: 56,
                          color: Colors.grey.shade800,
                          child: const Icon(Icons.fastfood, color: Colors.white54),
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
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            video['merchant'] ?? 'Mitra GAGE',
                            style: const TextStyle(color: Colors.white60, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _currencyFormat.format(video['productPrice'] ?? 16000),
                            style: const TextStyle(color: Color(0xFFFACC15), fontSize: 13, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE52320),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        GageToast.show(context, 'Alur Kerkun Valid! Pesanan otomatis mengunci komisi affiliator Anda.', type: GageToastType.success);
                      },
                      child: const Text('Beli', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                '✓ Terkunci ke kode affiliator: GAGE-CUAN-RATIH\n✓ Komisi otomatis cair saat pesanan dinyatakan SELESAI oleh customer.',
                style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmitVideoSheet() {
    HapticFeedback.lightImpact();
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();
    String selectedProduct = _highCommissionProducts.first['name'];

    GageFloatingSheet.show(
      context: context,
      title: 'Submit Video TikTok / VT',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tautkan video TikTok atau unggah konten Anda agar disematkan Keranjang Kuning resmi.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 14),
              const Text('Judul / Deskripsi Video', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  hintText: 'Misal: Review Renyah Rocket Chicken!',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Link Video TikTok (Opsional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              TextField(
                controller: urlCtrl,
                decoration: InputDecoration(
                  hintText: 'https://vt.tiktok.com/...',
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Pilih Produk Mitra yang Dipromosikan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedProduct,
                    items: _highCommissionProducts.map((p) {
                      return DropdownMenuItem<String>(
                        value: p['name'] as String,
                        child: Text(p['name'] as String, style: const TextStyle(fontSize: 12.5), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final t = titleCtrl.text.trim();
                    if (t.isEmpty) {
                      GageToast.show(context, 'Judul video tidak boleh kosong', type: GageToastType.warning);
                      return;
                    }
                    Navigator.pop(ctx);
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
                    GageToast.show(context, 'Video berhasil disubmit! Sedang direview kurator.', type: GageToastType.success);
                  },
                  child: const Text('Kirim untuk Kurasi Kerkun', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showWithdrawSheet() {
    HapticFeedback.lightImpact();
    if (_availableCommission <= 0) {
      GageToast.show(context, 'Saldo komisi Anda belum mencukupi untuk ditarik', type: GageToastType.warning);
      return;
    }

    String selectedMethod = 'GAGEPay';

    GageFloatingSheet.show(
      context: context,
      title: 'Tarik Saldo Komisi',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo Tersedia: ${_currencyFormat.format(_availableCommission)}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: GageTheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Metode Pencairan',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedMethod = 'GAGEPay'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'GAGEPay'
                              ? GageTheme.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedMethod == 'GAGEPay'
                                ? GageTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: selectedMethod == 'GAGEPay'
                                  ? GageTheme.primary
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'GAGEPay (Instan)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedMethod == 'GAGEPay'
                                    ? GageTheme.primary
                                    : Colors.black87,
                              ),
                            ),
                            const Text(
                              'Biaya Rp 0',
                              style: TextStyle(fontSize: 9.5, color: Colors.green, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setSheetState(() => selectedMethod = 'Bank'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: selectedMethod == 'Bank'
                              ? GageTheme.primary.withValues(alpha: 0.1)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: selectedMethod == 'Bank'
                                ? GageTheme.primary
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_balance_rounded,
                              color: selectedMethod == 'Bank'
                                  ? GageTheme.primary
                                  : Colors.grey.shade600,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rekening Bank',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: selectedMethod == 'Bank'
                                    ? GageTheme.primary
                                    : Colors.black87,
                              ),
                            ),
                            const Text(
                              '1-2 Hari Kerja',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    final amount = _availableCommission;
                    if (selectedMethod == 'GAGEPay') {
                      try {
                        context.read<WalletProvider>().topUp(amount);
                      } catch (_) {}
                    }
                    Navigator.pop(ctx);
                    setState(() {
                      _withdrawalHistory.insert(0, {
                        'id': 'WD-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
                        'date': 'Hari ini, ${DateFormat('HH:mm').format(DateTime.now())} WIB',
                        'destination': selectedMethod == 'GAGEPay' ? 'Saldo GAGEPay (Instan)' : 'Rekening Bank BCA',
                        'amount': amount,
                        'status': 'Berhasil Ditransfer',
                        'isSuccess': true,
                      });
                      _availableCommission = 0;
                    });
                    GageToast.show(
                      context,
                      'Penarikan ${_currencyFormat.format(amount)} ke $selectedMethod berhasil diproses!',
                      type: GageToastType.success,
                    );
                  },
                  child: const Text('Konfirmasi Penarikan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('GAGE Cuan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
            Text('Mitra Affiliator Resmi', style: TextStyle(fontSize: 11, color: Colors.white70)),
          ],
        ),
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, size: 22),
            onPressed: () {
              GageToast.show(context, 'Panduan: Upload video, sematkan tagar kerkun, dan cairkan komisi!', type: GageToastType.info);
            },
          ),
        ],
      ),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: _buildObsidianHeader(isDark),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: GageTheme.primary,
                  indicatorWeight: 3,
                  labelColor: GageTheme.primary,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [
                    Tab(text: 'Katalog Cuan'),
                    Tab(text: 'Performa & CVR'),
                    Tab(text: 'Riwayat Penarikan'),
                  ],
                ),
                isDark ? const Color(0xFF0F172A) : Colors.white,
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductsTab(isDark),
            _buildCreatorVideosTab(isDark),
            _buildWithdrawalHistoryTab(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildObsidianHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: const BoxDecoration(
        color: Color(0xFF0F172A),
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Referral Code Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE52320).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE52320).withValues(alpha: 0.4)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.verified_rounded, color: Color(0xFFE52320), size: 14),
                        SizedBox(width: 5),
                        Text('Kreator Level: Gold', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: _copyReferralCode,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _referralCode,
                        style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.copy_rounded, color: Color(0xFF38BDF8), size: 12),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Main Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE52320).withValues(alpha: 0.3)),
              boxShadow: const [
                BoxShadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Komisi Siap Tarik',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _currencyFormat.format(_availableCommission),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      onPressed: _showWithdrawSheet,
                      icon: const Icon(Icons.payments_rounded, size: 16),
                      label: const Text('Tarik Saldo', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 14),
                // Analytics Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('12.4k', 'Total Views VT'),
                    _buildStatItem('348', 'Klik Kerkun'),
                    _buildStatItem('42', 'Pesanan Selesai'),
                    _buildStatItem('12.1%', 'Rasio CVR'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10.5)),
      ],
    );
  }

  // TAB 1: Konten VT Saya & Status Kurasi Kerkun
  Widget _buildCreatorVideosTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Feed Konten & Keranjang Kuning',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  'Daftar video yang aktif dipromosikan di GAGE',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.grey.shade400 : Colors.black54),
                ),
              ],
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: _showSubmitVideoSheet,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Submit VT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
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
      statusBg = const Color(0xFF16A34A).withValues(alpha: 0.15);
      statusColor = const Color(0xFF22C55E);
      statusLabel = '✓ LOLOS KERKUN (Aktif)';
      statusIcon = Icons.check_circle_rounded;
    } else if (status == 'REVIEW') {
      statusBg = const Color(0xFFD97706).withValues(alpha: 0.15);
      statusColor = const Color(0xFFF59E0B);
      statusLabel = '⏳ SEDANG DIREVIEW';
      statusIcon = Icons.hourglass_top_rounded;
    } else {
      statusBg = const Color(0xFFE11D48).withValues(alpha: 0.15);
      statusColor = const Color(0xFFF43F5E);
      statusLabel = '✕ DITOLAK';
      statusIcon = Icons.cancel_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF131B2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
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
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.videocam_rounded, color: Colors.white54),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Produk: ${v['productName']}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
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
          const Divider(height: 1),
          const SizedBox(height: 8),
          if (status == 'APPROVED') ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${v['views']} views • ${v['clicks']} klik • ${v['orders']} pesanan',
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
                ),
                InkWell(
                  onTap: () => _showTestKerkunDialog(v),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF08A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCA8A04)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.play_circle_fill_rounded, size: 12, color: Color(0xFF854D0E)),
                        SizedBox(width: 4),
                        Text('Uji Keranjang Kuning', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Color(0xFF854D0E))),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ] else if (status == 'REVIEW') ...[
            const Text(
              '⏳ Tim GAGE sedang mencocokkan tagar produk. Diperkirakan tayang dalam 2 jam.',
              style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B)),
            ),
          ] else ...[
            Text(
              v['rejectReason'] as String? ?? 'Konten tidak memenuhi syarat kurasi.',
              style: const TextStyle(fontSize: 11, color: Color(0xFFF43F5E)),
            ),
          ],
        ],
      ),
    );
  }

  // TAB 2: Katalog Produk Komisi
  Widget _buildProductsTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _highCommissionProducts.length,
      itemBuilder: (ctx, idx) {
        final p = _highCommissionProducts[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2)),
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
                    color: Colors.grey.shade800,
                    child: const Icon(Icons.storefront_rounded, color: Colors.white54),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p['merchant'] as String,
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          _currencyFormat.format(p['price']),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '+${_currencyFormat.format(p['commission'])} (${p['rate']})',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              side: const BorderSide(color: GageTheme.primary),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _copyHashtag(p['hashtag'] as String),
                            icon: const Icon(Icons.tag_rounded, size: 14),
                            label: const Text('Salin Tagar', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                            icon: const Icon(Icons.storefront_rounded, size: 14),
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

  // TAB 3: Riwayat Penarikan Dana
  Widget _buildWithdrawalHistoryTab(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _withdrawalHistory.length,
      itemBuilder: (ctx, idx) {
        final w = _withdrawalHistory[idx];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131B2E) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_downward_rounded, color: Color(0xFF16A34A), size: 18),
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
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${w['id']} • ${w['date']}',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.grey.shade400 : Colors.black54),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currencyFormat.format(w['amount']),
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF16A34A)),
                  ),
                  const SizedBox(height: 2),
                  const Text('✓ Sukses', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF16A34A))),
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
  _SliverAppBarDelegate(this._tabBar, this.backgroundColor);

  final TabBar _tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
