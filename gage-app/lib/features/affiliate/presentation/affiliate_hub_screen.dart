import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

class AffiliateHubScreen extends StatefulWidget {
  const AffiliateHubScreen({super.key});

  @override
  State<AffiliateHubScreen> createState() => _AffiliateHubScreenState();
}

class _AffiliateHubScreenState extends State<AffiliateHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  bool _isRegistered = true; // State registrasi mitra kreator afiliasi

  String _affiliateHandle = '@ratih_kuliner';
  String _voucherCode = 'GAGERATIH';
  final String _bioToken = 'GAGE-AFF-8821';

  final TextEditingController _tiktokCtrl = TextEditingController();
  final TextEditingController _waCtrl = TextEditingController();
  final TextEditingController _voucherReqCtrl = TextEditingController();

  int _totalClicks = 142;
  int _totalOrders = 38;
  double _conversionRate = 26.8;
  int _totalCommission = 57000;

  // State navigasi merchant first di katalog
  Map<String, dynamic>? _selectedMerchantForAffiliate;

  final List<Map<String, dynamic>> _affiliateMerchants = [
    {
      'id': 'mch-rc-01',
      'name': 'Rocket Chicken Pracimantoro',
      'category': 'Ayam Goreng & Cepat Saji',
      'rating': 5.0,
      'commissionRate': '10%',
      'image': 'assets/images/resto_rocket_chicken.png',
      'products': [
        {
          'id': 'rc-01',
          'name': 'Paket Rocket 1 (Ayam Dada + Nasi + Es Teh)',
          'price': 18000,
          'commission': 1800,
          'image': 'assets/images/dish_rocket_1.png',
        },
        {
          'id': 'rc-02',
          'name': 'Ayam Geprek Sambal Korek Pedas Nampol',
          'price': 16000,
          'commission': 1600,
          'image': 'assets/images/dish_rocket_1.png',
        },
        {
          'id': 'rc-03',
          'name': 'Burger Crispy Cheese Spesial',
          'price': 14000,
          'commission': 1400,
          'image': 'assets/images/dish_rocket_1.png',
        },
      ],
    },
    {
      'id': 'mch-dimsum-01',
      'name': 'Dimsum Sewu - Bejo Halal Food',
      'category': 'Aneka Dimsum & Siomay Kukus',
      'rating': 4.9,
      'commissionRate': '10%',
      'image': 'assets/images/resto_dimsum_sewu.png',
      'products': [
        {
          'id': 'ds-01',
          'name': 'Dimsum Mentai Mozarella Melt (4 pcs)',
          'price': 18000,
          'commission': 1800,
          'image': 'assets/images/dish_dimsum_mentai.png',
        },
        {
          'id': 'ds-02',
          'name': 'Siomay Ayam Udang Hangat Original (5 pcs)',
          'price': 15000,
          'commission': 1500,
          'image': 'assets/images/dish_dimsum_original.png',
        },
        {
          'id': 'ds-03',
          'name': 'Pangsit Goreng Mayo Crispy (4 pcs)',
          'price': 14000,
          'commission': 1400,
          'image': 'assets/images/dish_dimsum_original.png',
        },
      ],
    },
    {
      'id': 'mch-mie-01',
      'name': 'Mie Ayam & Bakso Pak Kumis',
      'category': 'Mie Ayam & Bakso Urat Jumbo',
      'rating': 4.8,
      'commissionRate': '10%',
      'image': 'assets/images/resto_mie_ayam.png',
      'products': [
        {
          'id': 'mk-01',
          'name': 'Mie Ayam Pangsit Komplit Porsi Jumbo',
          'price': 15000,
          'commission': 1500,
          'image': 'assets/images/dish_mie_ayam.png',
        },
        {
          'id': 'mk-02',
          'name': 'Bakso Urat Spesial Tetelan Sapi Gurih',
          'price': 18000,
          'commission': 1800,
          'image': 'assets/images/dish_bakso_urat.png',
        },
      ],
    },
    {
      'id': 'mch-seblak-01',
      'name': 'Seblak Prasmanan Nyentrik',
      'category': 'Seblak Prasmanan & Jajanan Pedas',
      'rating': 4.9,
      'commissionRate': '10%',
      'image': 'assets/images/resto_seblak.png',
      'products': [
        {
          'id': 'sb-01',
          'name': 'Mangkuk Seblak Komplit Seafood & Cikuwa',
          'price': 20000,
          'commission': 2000,
          'image': 'assets/images/dish_mie_ayam.png',
        },
      ],
    },
    {
      'id': 'mch-roti-01',
      'name': 'Roti Gembong Gedhe Pracimantoro',
      'category': 'Roti & Bakery Fresh Oven',
      'rating': 4.9,
      'commissionRate': '10%',
      'image': 'assets/images/resto_roti_gembong.png',
      'products': [
        {
          'id': 'rg-01',
          'name': 'Roti Gembong Cokelat Meises Lumer',
          'price': 18000,
          'commission': 1800,
          'image': 'assets/images/dish_roti_cokelat.png',
        },
        {
          'id': 'rg-02',
          'name': 'Roti Gembong Keju Spesial Susu',
          'price': 19000,
          'commission': 1900,
          'image': 'assets/images/dish_roti_keju.png',
        },
      ],
    },
  ];

  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAffiliateData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _tiktokCtrl.dispose();
    _waCtrl.dispose();
    _voucherReqCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAffiliateData() async {
    setState(() => _isLoading = true);
    final stats = await GageApiClient.getAffiliateStats(_voucherCode);

    if (!mounted) return;
    setState(() {
      if (stats.isNotEmpty) {
        _totalClicks = (stats['total_clicks'] as num?)?.toInt() ?? _totalClicks;
        _totalOrders = (stats['total_orders'] as num?)?.toInt() ?? _totalOrders;
        _conversionRate = (stats['conversion_rate'] as num?)?.toDouble() ?? _conversionRate;
        _totalCommission = (stats['total_commission_earned'] as num?)?.toInt() ?? _totalCommission;
      }
      _isLoading = false;
    });
  }

  void _registerAffiliate() {
    final tiktok = _tiktokCtrl.text.trim();
    final wa = _waCtrl.text.trim();
    final vCode = _voucherReqCtrl.text.trim().toUpperCase();

    if (tiktok.isEmpty || wa.isEmpty || vCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi username media sosial, WhatsApp, dan kode voucher pilihan Anda.')),
      );
      return;
    }

    setState(() {
      _affiliateHandle = tiktok.startsWith('@') ? tiktok : '@$tiktok';
      _voucherCode = vCode;
      _isRegistered = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GageTheme.accentGreen,
        content: Text('Selamat! Akun kreator $_affiliateHandle aktif dengan kode voucher $_voucherCode.'),
      ),
    );
  }

  void _copyYellowCartLink(Map<String, dynamic> prod, String merchantName) {
    final prodName = prod['name'] ?? 'Menu';
    final targetUrl = 'https://gage.id/c/${prod['id']}-$_voucherCode'.toLowerCase();

    Clipboard.setData(ClipboardData(text: targetUrl));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: GageTheme.accentGreen,
        content: Text('Link Keranjang Kuning untuk "$prodName" berhasil disalin! Tempel di video TikTok/Instagram Anda.'),
      ),
    );
  }

  void _copyCaption(Map<String, dynamic> prod, String merchantName) {
    final name = prod['name'] ?? 'Menu Pilihan';
    final price = prod['price'] ?? 15000;
    final link = 'https://gage.id/c/${prod['id']}-$_voucherCode'.toLowerCase();

    final caption = '''
Cobain $name dari $merchantName cuma ${currencyFormatter.format(price)}!
Pesan antar cepat langsung lewat aplikasi GAGE.

Klik Keranjang Kuning atau link berikut:
$link

Gunakan kode voucher $_voucherCode saat checkout untuk klaim potongan ongkir ekstra!
#gage #gagedelivery #kuliner #reviewmakanan
''';

    Clipboard.setData(ClipboardData(text: caption));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: GageTheme.accentGreen,
        content: Text('Teks caption ulasan siap pakai disalin ke clipboard!'),
      ),
    );
  }

  void _showQrPosterModal(Map<String, dynamic> prod, String merchantName) {
    final name = prod['name'] ?? 'Menu Pilihan';
    final targetUrl = 'https://gage.id/c/${prod['id']}-$_voucherCode'.toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 16),
            Text('Flyer QR Menu: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 6),
            Text('Dari $merchantName • Scan untuk beli dengan diskon.', style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  const Text('GAGE DELIVERY', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.w900, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  QrImageView(
                    data: targetUrl,
                    version: QrVersions.auto,
                    size: 150.0,
                    gapless: false,
                  ),
                  const SizedBox(height: 10),
                  Text('Voucher Diskon: $_voucherCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: targetUrl));
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tautan berhasil disalin.')));
                    },
                    child: const Text('Salin Tautan'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                    onPressed: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Flyer siap dibagikan ke status WhatsApp/Instagram.')));
                    },
                    child: const Text('Bagikan Flyer', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: GageTheme.primary)),
      );
    }
    if (!_isRegistered) {
      return _buildRegistrationView();
    }

    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        title: const Text('Studio Kreator Afiliasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: GageTheme.textSecondary,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Pilih Menu Resto'),
            Tab(text: 'Statistik Komisi'),
            Tab(text: 'Kode Referral'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMerchantFirstCatalogTab(),
          _buildAnalyticsTab(),
          _buildReferralTab(),
        ],
      ),
    );
  }

  Widget _buildRegistrationView() {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Daftar Kreator Afiliasi GAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(22.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 70,
                height: 70,
                decoration: const BoxDecoration(
                  color: GageTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: GageTheme.primary, size: 38),
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Dapatkan Komisi 10% Tiap Penjualan!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GageTheme.textPrimary),
              ),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Daftar gratis sebagai kreator afiliasi resmi GAGE. Tempel link produk di bio TikTok / keranjang kuning dan terima komisi instan langsung ke saldo dompet.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: GageTheme.textSecondary),
              ),
            ),
            const SizedBox(height: 24),

            TextField(
              controller: _tiktokCtrl,
              decoration: InputDecoration(
                labelText: 'Username TikTok / Instagram',
                hintText: '@ratih_kuliner',
                prefixIcon: const Icon(Icons.alternate_email_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _waCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Nomor WhatsApp Aktif',
                hintText: '08123456789',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _voucherReqCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'Kode Voucher Pilihan (Untuk Followers)',
                hintText: 'Misal: GAGERATIH',
                prefixIcon: const Icon(Icons.confirmation_number_rounded),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _registerAffiliate,
                child: const Text('Aktifkan Akun Kreator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // TAMPILAN KATALOG AFFILIATE DENGAN FLOW: DAFTAR MERCHANT DULU -> KLIK MERCHANT -> DAFTAR PRODUK
  Widget _buildMerchantFirstCatalogTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Identitas Kreator & Kode Bio TikTok
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.black87,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_affiliateHandle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              const SizedBox(width: 4),
                              const Icon(Icons.verified, color: Colors.blue, size: 16),
                            ],
                          ),
                          const Text('Kreator Resmi GAGE (Komisi 10% per pesanan)', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                          Text('Voucher Diskon: $_voucherCode', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Token Khusus Bio TikTok
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Kode Unik Bio TikTok:', style: TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
                          Text(_bioToken, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Colors.black87)),
                        ],
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: 'Dapatkan diskon via GAGE: https://gage.id/bio/$_bioToken'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Tautan bio TikTok disalin! Tempel di bio profil media sosial Anda.')),
                          );
                        },
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: const Text('Salin Link Bio', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Saldo Komisi & Penarikan
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: GageTheme.primaryLight, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Saldo Komisi Terkumpul', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                          Text(currencyFormatter.format(_totalCommission), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                        ],
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Permintaan pencairan komisi ke GAGEPay berhasil diajukan.')),
                          );
                        },
                        child: const Text('Tarik Komisi', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        // JIKA SEDANG MEMILIH MERCHANT: TAMPILKAN DAFTAR MERCHANT TERLEBIH DAHULU
        if (_selectedMerchantForAffiliate == null) ...[
          const Text('Pilih Toko / Resto Mitra', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Pilih resto untuk melihat daftar menu yang siap dipromosikan ke keranjang kuning.', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
          const SizedBox(height: 14),

          for (var m in _affiliateMerchants)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  setState(() {
                    _selectedMerchantForAffiliate = m;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          m['image'],
                          width: 65,
                          height: 65,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 65,
                            height: 65,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.storefront_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 2),
                            Text(m['category'], style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                                  child: Text('Komisi ${m['commissionRate']}', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
                                ),
                                const SizedBox(width: 8),
                                Text('${(m['products'] as List).length} Menu Siap Promosi', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ),
        ] else ...[
          // JIKA MERCHANT SUDAH DIPILIH: TAMPILKAN MENU-MENU SIAP PROMOSI DARI MERCHANT TERSEBUT
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  setState(() {
                    _selectedMerchantForAffiliate = null;
                  });
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_selectedMerchantForAffiliate!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Pilih menu untuk diambil link keranjang kuning atau caption', style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          for (var prod in (_selectedMerchantForAffiliate!['products'] as List))
            Card(
              margin: const EdgeInsets.only(bottom: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.asset(
                            prod['image'] ?? 'assets/images/dish_dimsum_original.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              width: 60,
                              height: 60,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.restaurant_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 2),
                              Text('Harga Menu: ${currencyFormatter.format(prod['price'])}', style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(color: Colors.amber.shade50, borderRadius: BorderRadius.circular(6)),
                                child: Text('Estimasi Cuan: ${currencyFormatter.format(prod['commission'])} / pesanan',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.orange.shade800)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.accentYellow,
                              foregroundColor: Colors.black87,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () => _copyYellowCartLink(prod, _selectedMerchantForAffiliate!['name']),
                            icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                            label: const Text('Keranjang Kuning', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Salin Teks Ulasan',
                          icon: const Icon(Icons.copy_all_rounded, color: GageTheme.primary, size: 20),
                          onPressed: () => _copyCaption(prod, _selectedMerchantForAffiliate!['name']),
                        ),
                        IconButton(
                          tooltip: 'Flyer QR',
                          icon: const Icon(Icons.qr_code_2_rounded, color: Colors.black87, size: 20),
                          onPressed: () => _showQrPosterModal(prod, _selectedMerchantForAffiliate!['name']),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Statistik Performa Kreator', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Statistik pesanan yang masuk melalui link afiliasi & kode voucher Anda.', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
        const SizedBox(height: 14),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.45,
          children: [
            _buildStatCard('Klik Tautan', '$_totalClicks', 'Total klik dari media sosial', Icons.touch_app_rounded, Colors.blue),
            _buildStatCard('Pesanan Berhasil', '$_totalOrders', 'Checkout dengan voucher Anda', Icons.shopping_bag_outlined, GageTheme.accentGreen),
            _buildStatCard('Konversi', '$_conversionRate%', 'Rasio order dibanding klik', Icons.trending_up_rounded, Colors.orange),
            _buildStatCard('Total Komisi', currencyFormatter.format(_totalCommission), 'Penghasilan bersih', Icons.account_balance_wallet_outlined, GageTheme.primary),
          ],
        ),
      ],
    );
  }

  Widget _buildReferralTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: GageTheme.primary, size: 48),
                const SizedBox(height: 10),
                const Text('Program Referral GAGE', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text(
                  'Bagikan kode referral Anda ke teman atau keluarga. Setiap kali ada pengguna baru yang mendaftar menggunakan kode Anda dan melakukan transaksi pertama, Anda berdua mendapatkan saldo reward GAGEPay Rp 5.000.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: GageTheme.textSecondary, height: 1.4),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_voucherCode, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 2, color: GageTheme.primary)),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _voucherCode));
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode referral berhasil disalin!')));
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String val, String sub, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
              Icon(icon, color: color, size: 18),
            ],
          ),
          Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: GageTheme.textMuted)),
        ],
      ),
    );
  }
}
