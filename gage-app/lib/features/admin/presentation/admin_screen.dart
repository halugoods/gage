import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/banner_manager_service.dart';
import 'package:gage_app/core/services/gage_pricing_service.dart';
import 'package:gage_app/core/services/fare_calculation_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  Map<String, dynamic> _affiliateStats = {};
  List<Map<String, dynamic>> _merchantOrders = [];
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  // State Kelola Banner
  String _selectedBannerMenu = 'beranda';
  late TextEditingController _bannerTitleCtrl;
  late TextEditingController _bannerSubtitleCtrl;
  late TextEditingController _bannerBadgeCtrl;
  late TextEditingController _bannerCtaCtrl;
  String _selectedBannerImage = 'assets/images/hero_banner_1.png';

  // State Pengaturan Biaya Admin Dinamis
  late TextEditingController _adminFeeCashlessCtrl;
  late TextEditingController _adminFeeCodBaseCtrl;
  late TextEditingController _adminFeeCodExtraCtrl;

  // State Kurasi BaBe
  String _babeFilter = 'Semua';
  final List<Map<String, dynamic>> _babeCurationList = [
    {
      'id': 'SUB-BABE-001',
      'category': 'Gadget & Elektronik',
      'name': 'iPad Gen 9 64GB Space Grey WiFi Only Mulus',
      'sellerName': 'Pak Joko Purnomo',
      'sellerPhone': '6281234567890',
      'submittedAt': '10 Okt 2026, 14:20',
      'specs': 'Baterai Health 91%, layar retina mulus tanpa scratch, tombol home fingerprint responsif, charger original bawaan box.',
      'netPrice': 3200000,
      'markupPercent': 10,
      'photos': [
        'assets/images/hero_promo_1.png',
        'assets/images/promo_banner_1.png',
      ],
      'status': 'pending',
      'notes': 'Unit titip jual dari warga desa Gedong, siap disurvey fisik oleh kurir GAGE.',
    },
    {
      'id': 'SUB-BABE-002',
      'category': 'Sepeda & Otomotif',
      'name': 'Sepeda Lipat Pacific Noris 2.1 20 Inch 8 Speed',
      'sellerName': 'Mas Budi Santoso',
      'sellerPhone': '6285712345678',
      'submittedAt': '11 Okt 2026, 09:15',
      'specs': 'Warna hitam doff, lipatan kencang tanpa speleng, ban kenda tebal 90%, upgrade sadel gel empuk.',
      'netPrice': 1600000,
      'markupPercent': 10,
      'photos': [
        'assets/images/hero_promo_2.png',
        'assets/images/promo_banner_2.png',
      ],
      'status': 'pending',
      'notes': 'Pemilik butuh dana cepat, barang disimpan di ruko dekat pasar Pracimantoro.',
    },
    {
      'id': 'SUB-BABE-003',
      'category': 'Perkakas & Alat Rumah',
      'name': 'Kompresor Angin Lakoni Imola 75 3/4 HP Silent',
      'sellerName': 'Bpk. Slamet Riyadi',
      'sellerPhone': '6289876543210',
      'submittedAt': '09 Okt 2026, 16:45',
      'specs': 'Pengisian angin cepat 0-8 bar dalam 2 menit, oli mesin baru diganti, selang spiral 6 meter + air duster bonus.',
      'netPrice': 750000,
      'markupPercent': 10,
      'photos': [
        'assets/images/prod_traktor.png',
        'assets/images/promo_banner_3.png',
      ],
      'status': 'approved',
      'notes': 'Sudah disurvey tim kurir GAGE, kondisi fisik dan mesin prima lolos verifikasi.',
    },
    {
      'id': 'SUB-BABE-004',
      'category': 'Perabotan',
      'name': 'Sofa Bed Minimalis Lipat Busa Rebonded Super',
      'sellerName': 'Ibu Dewi Sartika',
      'sellerPhone': '6281399887766',
      'submittedAt': '08 Okt 2026, 11:30',
      'specs': 'Kain daphnie abu-abu bersih dicuci, rangka kayu mahoni oven, busa padat tidak kempes.',
      'netPrice': 1100000,
      'markupPercent': 10,
      'photos': [
        'assets/images/hero_banner_1.png',
      ],
      'status': 'rejected',
      'notes': 'Ditolak: Bahan kain ada sobekan kecil di bagian belakang yang tidak dilaporkan.',
    },
  ];

  final List<String> _bannerImageOptions = [
    'assets/images/hero_banner_1.png',
    'assets/images/hero_banner_2.png',
    'assets/images/food_hero_banner.png',
    'assets/images/promo_food_clean_16x9.png',
    'assets/images/promo_banner_1.png',
    'assets/images/promo_banner_2.png',
    'assets/images/promo_banner_3.png',
    'assets/images/hero_promo_1.png',
    'assets/images/hero_promo_2.png',
    'assets/images/hero_header_gage_1.png',
  ];

  final Map<String, String> _bannerMenuNames = {
    'beranda': 'Beranda Utama',
    'food': 'GAGE Food',
    'shop': 'GAGE Shop',
    'send': 'GAGE Send',
    'babe': 'GAGE BaBe',
    'ride': 'GAGE Ride & Car',
    'tani': 'GAGE Tani & Ternak',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _bannerTitleCtrl = TextEditingController();
    _bannerSubtitleCtrl = TextEditingController();
    _bannerBadgeCtrl = TextEditingController();
    _bannerCtaCtrl = TextEditingController();
    _adminFeeCashlessCtrl = TextEditingController(text: FareCalculationService.adminFeeCashless.toString());
    _adminFeeCodBaseCtrl = TextEditingController(text: FareCalculationService.adminFeeCodBase.toString());
    _adminFeeCodExtraCtrl = TextEditingController(text: FareCalculationService.adminFeeCodExtra.toString());
    _adminFeeCashlessCtrl.addListener(_onAdminFeeChanged);
    _adminFeeCodBaseCtrl.addListener(_onAdminFeeChanged);
    _adminFeeCodExtraCtrl.addListener(_onAdminFeeChanged);
    _syncBannerFormWithCurrent();
    _loadAdminData();
  }

  void _onAdminFeeChanged() {
    if (mounted) setState(() {});
  }

  void _syncBannerFormWithCurrent() {
    final banner = BannerManagerService.instance.getBanner(_selectedBannerMenu);
    _bannerTitleCtrl.text = banner.title;
    _bannerSubtitleCtrl.text = banner.subtitle;
    _bannerBadgeCtrl.text = banner.badge;
    _bannerCtaCtrl.text = banner.ctaText;
    _selectedBannerImage = banner.imagePath;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleCtrl.dispose();
    _bannerSubtitleCtrl.dispose();
    _bannerBadgeCtrl.dispose();
    _bannerCtaCtrl.dispose();
    _adminFeeCashlessCtrl.removeListener(_onAdminFeeChanged);
    _adminFeeCodBaseCtrl.removeListener(_onAdminFeeChanged);
    _adminFeeCodExtraCtrl.removeListener(_onAdminFeeChanged);
    _adminFeeCashlessCtrl.dispose();
    _adminFeeCodBaseCtrl.dispose();
    _adminFeeCodExtraCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    await FareCalculationService.loadConfig();
    _adminFeeCashlessCtrl.text = FareCalculationService.adminFeeCashless.toString();
    _adminFeeCodBaseCtrl.text = FareCalculationService.adminFeeCodBase.toString();
    _adminFeeCodExtraCtrl.text = FareCalculationService.adminFeeCodExtra.toString();

    final stats = await GageApiClient.getAffiliateStats('GAGERATIH');
    final orders = await GageApiClient.getMerchantOrders('m-dimsum-sewu');

    if (!mounted) return;
    setState(() {
      _affiliateStats = stats;
      _merchantOrders = orders;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GageTheme.background,
      appBar: AppBar(
        backgroundColor: GageTheme.primary,
        elevation: 0,
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: GageTheme.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GAGE Admin Hub',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17),
                ),
                Text(
                  'Monitoring Wilayah Pracimantoro Wonogiri',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Segarkan Data D1',
            onPressed: _loadAdminData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          tabs: const [
            Tab(text: 'Ringkasan'),
            Tab(text: 'Semua Order'),
            Tab(text: 'Biaya & Komisi'),
            Tab(text: 'Kelola Banner'),
            Tab(text: 'Kurasi BaBe'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: GageTheme.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildOrdersTab(),
                _buildFareAndCommissionTab(),
                _buildBannerManagerTab(),
                _buildBabeCurationTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Kartu Utama Omset Kecamatan
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFE52320), Color(0xFF991B1B)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(15),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                  SizedBox(width: 8),
                  Text('Volume Transaksi Hari Ini', style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Rp 485.000',
                style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('24 Pesanan Berhasil', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('100% Selesai Tepat Waktu', style: TextStyle(color: Colors.white, fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 18),

        // 3 Metrik Cepat
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.storefront_rounded,
                iconColor: Colors.orange,
                label: 'Merchant',
                value: '3 Aktif',
                sub: 'Dimsum Sewu dkk',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.two_wheeler_rounded,
                iconColor: Colors.blue,
                label: 'Driver Online',
                value: '1 Siap Antar',
                sub: 'Pak Sugeng (AB 4521)',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.auto_awesome_rounded,
                iconColor: GageTheme.primary,
                label: 'Kreator',
                value: '1 Afiliator',
                sub: '@ratih_kuliner',
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        // Pengaturan Biaya Admin Toko (Multi-Merchant & Live Simulation)
        _buildAdminFeeSettingsCard(),

        const SizedBox(height: 22),

        const Text('Infrastruktur Backend (Rp 0 Cloudflare)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        const SizedBox(height: 10),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              _buildInfraRow('Cloudflare Worker', 'gage-cloud (Live)', Colors.green),
              const Divider(height: 16),
              _buildInfraRow('Cloudflare D1 Database', 'gage-db (12 Tabel)', Colors.green),
              const Divider(height: 16),
              _buildInfraRow('Durable Objects Tracking', 'TrackingRoomDO (Realtime GPS)', Colors.green),
              const Divider(height: 16),
              _buildInfraRow('Biaya Server / Bulan', 'Rp 0 (100% Free Tier)', Colors.blue),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_merchantOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long_rounded, size: 54, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('Belum ada pesanan aktif.', style: TextStyle(color: GageTheme.textSecondary)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _merchantOrders.length,
      itemBuilder: (context, idx) {
        final order = _merchantOrders[idx];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Pesanan #${(order['id'] ?? '').toString().substring(0, 8).toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: GageTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order['status'] ?? 'PAID',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Total: ${currencyFormatter.format(order['total_amount'] ?? 0)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
                Text('Alamat: ${order['delivery_address'] ?? 'Kasihan, Bantul'}',
                    style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFareAndCommissionTab() {
    final totalClicks = _affiliateStats['total_clicks'] ?? 0;
    final totalOrders = _affiliateStats['total_orders'] ?? 0;
    final totalEarned = _affiliateStats['total_commission_earned'] ?? 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildAdminFeeSettingsCard(),
        const SizedBox(height: 18),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.campaign_rounded, color: GageTheme.primary),
                    SizedBox(width: 8),
                    Text('Kreator Afiliasi Utama & Komisi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: GageTheme.primaryLight,
                    child: Icon(Icons.person, color: GageTheme.primary),
                  ),
                  title: const Text('Ratih Pratiwi (@ratih_kuliner)', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Kode Voucher: GAGERATIH | Komisi: 10%'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Terverifikasi', style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatCol('Klik Video', '$totalClicks'),
                    _buildStatCol('Order Tercipta', '$totalOrders'),
                    _buildStatCol('Total Komisi', currencyFormatter.format(totalEarned)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAdminFeeSettingsCard() {
    final cashlessVal = int.tryParse(_adminFeeCashlessCtrl.text.trim()) ?? FareCalculationService.adminFeeCashless;
    final codBaseVal = int.tryParse(_adminFeeCodBaseCtrl.text.trim()) ?? FareCalculationService.adminFeeCodBase;
    final codExtraVal = int.tryParse(_adminFeeCodExtraCtrl.text.trim()) ?? FareCalculationService.adminFeeCodExtra;

    // Nilai kalkulasi realtime berdasarkan input form
    final liveSimCashless1 = 1 * cashlessVal;
    final liveSimCod2 = codBaseVal + (1 * codExtraVal);
    final liveSimCod3 = codBaseVal + (2 * codExtraVal);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                  color: GageTheme.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: GageTheme.primary, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Pengaturan Biaya Admin Toko (Multi-Merchant)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text('Penetapan tarif admin Cashless vs COD yang dinamis & adil', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () {
                  _adminFeeCashlessCtrl.text = FareCalculationService.defaultAdminFeeCashless.toString();
                  _adminFeeCodBaseCtrl.text = FareCalculationService.defaultAdminFeeCodBase.toString();
                  _adminFeeCodExtraCtrl.text = FareCalculationService.defaultAdminFeeCodExtra.toString();
                },
                icon: const Icon(Icons.restore_rounded, size: 14),
                label: const Text('Default', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  foregroundColor: GageTheme.textSecondary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _adminFeeCashlessCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Biaya Admin Cashless per Toko (Default: Rp 1.000)',
              labelStyle: const TextStyle(fontSize: 12),
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
              helperText: 'Dikenakan per toko saat bayar via GAGEPay / QRIS (cth: 2 toko = ${currencyFormatter.format(cashlessVal * 2)})',
              helperStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminFeeCodBaseCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Biaya Admin COD Toko Pertama (Default: Rp 3.000)',
              labelStyle: const TextStyle(fontSize: 12),
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
              helperText: 'Biaya penanganan tunai untuk toko pertama (toko ke-1)',
              helperStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _adminFeeCodExtraCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Biaya Admin COD Toko Tambahan (Default: Rp 1.000)',
              labelStyle: const TextStyle(fontSize: 12),
              prefixText: 'Rp ',
              prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
              helperText: 'Biaya tambahan per toko berikutnya jika multi-toko COD',
              helperStyle: const TextStyle(fontSize: 10),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          const SizedBox(height: 16),

          // LIVE SIMULATION BOX
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBBF7D0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calculate_rounded, color: Color(0xFF15803D), size: 18),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Live Simulation Kalkulasi Admin Real-time',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF166534),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.bolt_rounded, size: 12, color: Color(0xFF15803D)),
                          Text(
                            'Realtime',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Komparasi 1 Toko Cashless vs 2 Toko COD
                Row(
                  children: [
                    // Skenario 1: 1 Toko Cashless
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF86EFAC)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.qr_code_2_rounded, size: 14, color: Color(0xFF15803D)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '1 Toko Cashless',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormatter.format(liveSimCashless1),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF15803D),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1 × ${currencyFormatter.format(cashlessVal)}',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total (ongkir Rp 10.500):\n${currencyFormatter.format(10500 + liveSimCashless1)}',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Skenario 2: 2 Toko Cash COD
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.payments_rounded, size: 14, color: Color(0xFFC2410C)),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '2 Toko Cash COD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade700,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              currencyFormatter.format(liveSimCod2),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${currencyFormatter.format(codBaseVal)} + ${currencyFormatter.format(codExtraVal)}',
                              style: TextStyle(fontSize: 9.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Total (ongkir Rp 13.000):\n${currencyFormatter.format(13000 + liveSimCod2)}',
                              style: TextStyle(fontSize: 9, color: Colors.grey.shade500, height: 1.2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                // Info bar perbandingan
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(180),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 13, color: Color(0xFF15803D)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Jika 3 toko COD: ${currencyFormatter.format(liveSimCod3)} (${currencyFormatter.format(codBaseVal)} + 2×${currencyFormatter.format(codExtraVal)})',
                          style: const TextStyle(fontSize: 10, color: Color(0xFF166534)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () async {
                final cashless = int.tryParse(_adminFeeCashlessCtrl.text.trim()) ?? FareCalculationService.defaultAdminFeeCashless;
                final codBase = int.tryParse(_adminFeeCodBaseCtrl.text.trim()) ?? FareCalculationService.defaultAdminFeeCodBase;
                final codExtra = int.tryParse(_adminFeeCodExtraCtrl.text.trim()) ?? FareCalculationService.defaultAdminFeeCodExtra;

                await FareCalculationService.updateConfig(
                  cashless: cashless,
                  codBase: codBase,
                  codExtra: codExtra,
                );
                await GagePricingService.saveAdminPricingConfig(
                  newAdminFeeCashless: cashless,
                  newAdminFeeCodBase: codBase,
                  newAdminFeeCodExtra: codExtra,
                );

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: Colors.white),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pengaturan biaya admin berhasil disimpan & langsung aktif!\n'
                            'Cashless: ${currencyFormatter.format(cashless)}/toko • COD Base: ${currencyFormatter.format(codBase)} • COD Tambahan: ${currencyFormatter.format(codExtra)}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                    backgroundColor: const Color(0xFF15803D),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 3),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                );
              },
              icon: const Icon(Icons.save_rounded, size: 18),
              label: const Text('Simpan Pengaturan Biaya', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 9.5, color: GageTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildInfraRow(String label, String value, Color statusColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: GageTheme.textSecondary)),
        Row(
          children: [
            Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCol(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary)),
      ],
    );
  }

  Widget _buildBannerManagerTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Tab
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manajemen Banner Promo',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  Text(
                    'Kustomisasi visual banner 16:9 per menu aplikasi',
                    style: TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.save_rounded, color: Colors.green, size: 14),
                    SizedBox(width: 4),
                    Text('Tersimpan Lokal', style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Selector Menu Customer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.dashboard_customize_rounded, color: GageTheme.primary, size: 20),
                const SizedBox(width: 10),
                const Text('Pilih Menu:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedBannerMenu,
                      isExpanded: true,
                      items: _bannerMenuNames.entries.map((e) {
                        return DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedBannerMenu = val;
                            _syncBannerFormWithCurrent();
                          });
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // SECTION: Interactive Live Preview 16:9 Card
          Row(
            children: [
              const Icon(Icons.remove_red_eye_rounded, color: GageTheme.primary, size: 18),
              const SizedBox(width: 6),
              const Text('Live Preview 16:9 Card', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('LIVE PREVIEW', style: TextStyle(color: Color(0xFFE52320), fontSize: 9.5, fontWeight: FontWeight.w900)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // The 16:9 Card
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      _selectedBannerImage,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: GageTheme.primary),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.70),
                            Colors.black.withValues(alpha: 0.35),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(14.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE52320),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _bannerBadgeCtrl.text.isEmpty ? 'PROMO' : _bannerBadgeCtrl.text,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9.5,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.55),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.white30),
                                ),
                                child: Text(
                                  _bannerMenuNames[_selectedBannerMenu] ?? 'Menu',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _bannerTitleCtrl.text.isEmpty ? 'Judul Promo' : _bannerTitleCtrl.text,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  height: 1.2,
                                  shadows: [
                                    Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _bannerSubtitleCtrl.text.isEmpty ? 'Deskripsi promo' : _bannerSubtitleCtrl.text,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10.5,
                                  height: 1.25,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  _bannerCtaCtrl.text.isEmpty ? 'Lihat Promo' : _bannerCtaCtrl.text,
                                  style: const TextStyle(
                                    color: Color(0xFFE52320),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
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
          ),
          const SizedBox(height: 20),

          // Form Editor
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Form Konfigurasi Banner', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),

                  // Input Judul
                  TextFormField(
                    controller: _bannerTitleCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Judul Promo Banner',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input Subtitle
                  TextFormField(
                    controller: _bannerSubtitleCtrl,
                    onChanged: (_) => setState(() {}),
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Subtitle / Keterangan Banner',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input Badge Promo
                  TextFormField(
                    controller: _bannerBadgeCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Teks Badge (Label Kiri Atas)',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Input Tombol CTA
                  TextFormField(
                    controller: _bannerCtaCtrl,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'Teks Tombol CTA',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Dropdown Gambar Asset
                  DropdownButtonFormField<String>(
                    initialValue: _selectedBannerImage,
                    decoration: InputDecoration(
                      labelText: 'Pilih Gambar Asset Promo',
                      labelStyle: const TextStyle(fontSize: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                    ),
                    items: _bannerImageOptions.map((img) {
                      return DropdownMenuItem(
                        value: img,
                        child: Text(
                          img.replaceAll('assets/images/', ''),
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedBannerImage = val);
                      }
                    },
                  ),
                  const SizedBox(height: 18),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () async {
                            final current = BannerManagerService.instance.getBanner(_selectedBannerMenu);
                            final updated = current.copyWith(
                              title: _bannerTitleCtrl.text.trim(),
                              subtitle: _bannerSubtitleCtrl.text.trim(),
                              badge: _bannerBadgeCtrl.text.trim(),
                              ctaText: _bannerCtaCtrl.text.trim(),
                              imagePath: _selectedBannerImage,
                            );
                            await BannerManagerService.instance.updateBanner(_selectedBannerMenu, updated);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Banner ${_bannerMenuNames[_selectedBannerMenu]} berhasil diperbarui & disimpan!'),
                                  backgroundColor: GageTheme.accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          child: const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade400),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        ),
                        onPressed: () async {
                          await BannerManagerService.instance.resetToDefaults();
                          setState(() {
                            _syncBannerFormWithCurrent();
                          });
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Semua konfigurasi banner direset ke bawaan awal.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildBabeCurationTab() {
    final pendingCount = _babeCurationList.where((x) => x['status'] == 'pending').length;
    final approvedCount = _babeCurationList.where((x) => x['status'] == 'approved').length;
    final rejectedCount = _babeCurationList.where((x) => x['status'] == 'rejected').length;

    List<Map<String, dynamic>> filteredList = _babeCurationList;
    if (_babeFilter == 'Menunggu Review') {
      filteredList = _babeCurationList.where((x) => x['status'] == 'pending').toList();
    } else if (_babeFilter == 'Lolos Listing') {
      filteredList = _babeCurationList.where((x) => x['status'] == 'approved').toList();
    } else if (_babeFilter == 'Ditolak') {
      filteredList = _babeCurationList.where((x) => x['status'] == 'rejected').toList();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header Info Escrow & Anti-Bypass
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFBBF7D0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: GageTheme.accentGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.verified_user_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Pusat Kurasi GAGE BaBe & Anti-Bypass Escrow',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF166534)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Semua pengajuan barang bekas melewati kurasi ketat tim GAGE. Komisi 10% dipungut transparan lewat markup harga listing aplikasi, sehingga penjual tetap menerima harga bersih penuh. Kontak penjual dimaskir dari publik demi keamanan transaksi & garansi 48 jam GAGE.',
                style: TextStyle(fontSize: 11.5, color: Color(0xFF14532D), height: 1.4),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Metrik Ringkasan Pengajuan
        Row(
          children: [
            _buildStatCard('Total Pengajuan', '${_babeCurationList.length}', Colors.grey.shade700, const Color(0xFFF1F5F9)),
            const SizedBox(width: 8),
            _buildStatCard('Menunggu QC', '$pendingCount', Colors.amber.shade900, const Color(0xFFFEF3C7)),
            const SizedBox(width: 8),
            _buildStatCard('Lolos Listing', '$approvedCount', const Color(0xFF166534), const Color(0xFFDCFCE7)),
            const SizedBox(width: 8),
            _buildStatCard('Ditolak', '$rejectedCount', const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
          ],
        ),

        const SizedBox(height: 16),

        // Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['Semua', 'Menunggu Review', 'Lolos Listing', 'Ditolak'].map((filter) {
              final isSelected = _babeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(filter, style: TextStyle(fontSize: 11.5, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  selected: isSelected,
                  selectedColor: GageTheme.primary,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                  backgroundColor: Colors.white,
                  checkmarkColor: Colors.white,
                  onSelected: (val) {
                    setState(() => _babeFilter = filter);
                  },
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 14),

        // Daftar Item Pengajuan BaBe
        if (filteredList.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            alignment: Alignment.center,
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 8),
                Text('Tidak ada pengajuan dalam status ini', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
              ],
            ),
          )
        else
          ...filteredList.map((item) {
            final netPrice = item['netPrice'] as int;
            final markupCommission = (netPrice * 0.1).round();
            final listingPrice = netPrice + markupCommission;
            final photos = item['photos'] as List<dynamic>;
            final status = item['status'] as String;

            Color statusColor = Colors.amber.shade800;
            Color statusBg = const Color(0xFFFEF3C7);
            String statusText = 'Menunggu QC / Survey';
            if (status == 'approved') {
              statusColor = const Color(0xFF166534);
              statusBg = const Color(0xFFDCFCE7);
              statusText = 'Lolos Listing';
            } else if (status == 'rejected') {
              statusColor = const Color(0xFF991B1B);
              statusBg = const Color(0xFFFEE2E2);
              statusText = 'Ditolak';
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar: ID & Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['id'],
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, fontFamily: 'monospace', color: Colors.black87),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: GageTheme.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item['category'],
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: GageTheme.primary),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // Judul Barang
                  Text(
                    item['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                  ),

                  const SizedBox(height: 10),

                  // Multi-Photo Slider
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (ctx, pIdx) {
                        return Container(
                          width: 105,
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.grey.shade300),
                            image: DecorationImage(
                              image: AssetImage(photos[pIdx]),
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Spesifikasi Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Spesifikasi & Kondisi:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                        const SizedBox(height: 3),
                        Text(item['specs'], style: const TextStyle(fontSize: 11.5, color: Colors.black87, height: 1.3)),
                        if (item['notes'] != null && (item['notes'] as String).isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text('Catatan Surveyor: ${item['notes']}', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.blueGrey.shade700)),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Finansial & Markup 10%
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Harga Bersih Pemilik:', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                            Text(currencyFormatter.format(netPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Markup Komisi GAGE (10%):', style: TextStyle(fontSize: 11.5, color: Colors.black54)),
                            Text('+ ${currencyFormatter.format(markupCommission)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.accentGreen)),
                          ],
                        ),
                        const Divider(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HARGA LISTING KONSUMEN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                            Text(
                              currencyFormatter.format(listingPrice),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: GageTheme.primary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Info Pengaju & Action Hubungi WA
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${item['sellerName']} (${item['sellerPhone']})',
                          style: const TextStyle(fontSize: 11.5, color: Colors.black87, fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InkWell(
                        onTap: () async {
                          final uri = Uri.parse(
                            'https://wa.me/${item['sellerPhone']}?text=${Uri.encodeComponent('Halo ${item['sellerName']}, kami dari Tim Kurasi GAGE BaBe ingin konfirmasi terkait pengajuan barang "${item['name']}" (ID: ${item['id']}).')}',
                          );
                          try {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          } catch (_) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Gagal membuka WhatsApp. Pastikan aplikasi WA terpasang.')),
                              );
                            }
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.chat_rounded, size: 13, color: Color(0xFF166534)),
                              SizedBox(width: 4),
                              Text('Chat WA', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF166534))),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Action Buttons (Setujui / Tolak)
                  if (status == 'pending')
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.accentGreen,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Setujui & Publikasikan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              setState(() {
                                item['status'] = 'approved';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Barang "${item['name']}" berhasil disetujui & dipublikasikan ke katalog BaBe!'),
                                  backgroundColor: GageTheme.accentGreen,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade700,
                            side: BorderSide(color: Colors.red.shade300),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              item['status'] = 'rejected';
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Pengajuan "${item['name']}" ditolak.'),
                                backgroundColor: Colors.red.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: const Text('Tolak', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    )
                  else if (status == 'approved')
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 16, color: GageTheme.accentGreen),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('Telah tayang di katalog GAGE BaBe aplikasi pelanggan.', style: TextStyle(fontSize: 11, color: GageTheme.accentGreen, fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              item['status'] = 'pending';
                            });
                          },
                          child: const Text('Tarik Listing', style: TextStyle(fontSize: 11, color: Colors.red)),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Icon(Icons.cancel_rounded, size: 16, color: Colors.red),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text('Pengajuan ini ditolak dan tidak tampil di katalog.', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              item['status'] = 'pending';
                            });
                          },
                          child: const Text('Tinjau Ulang', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color textColor, Color bgColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 9.5, color: textColor.withValues(alpha: 0.8)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}
