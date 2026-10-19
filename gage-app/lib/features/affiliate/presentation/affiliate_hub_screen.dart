import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class AffiliateHubScreen extends StatefulWidget {
  const AffiliateHubScreen({super.key});

  @override
  State<AffiliateHubScreen> createState() => _AffiliateHubScreenState();
}

class _AffiliateHubScreenState extends State<AffiliateHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final String _voucherCode = 'GAGECUAN-SYAMS';

  int _totalClicks = 142;
  int _totalOrders = 38;
  double _conversionRate = 26.8;
  int _totalCommission = 185000;
  int _availableBalance = 85000;
  bool _isLoadingStats = true;

  // State navigasi merchant first di katalog
  Map<String, dynamic>? _selectedMerchantForAffiliate;

  final List<Map<String, dynamic>> _affiliateMerchants = [
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
      'id': 'mch-rc-01',
      'name': 'Rocket Chicken Sambiroto',
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
          'image': 'assets/images/resto_rocket_chicken.png',
        },
        {
          'id': 'rc-02',
          'name': 'Ayam Geprek Sambal Korek Pedas',
          'price': 16000,
          'commission': 1600,
          'image': 'assets/images/resto_rocket_chicken.png',
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
          'image': 'assets/images/resto_mie_ayam.png',
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
      'id': 'mch-shop-01',
      'name': 'Toko Sembako Barokah Pracimantoro',
      'category': 'Sembako & Kebutuhan Dapur',
      'rating': 4.9,
      'commissionRate': '5%',
      'image': 'assets/images/prod_beras.png',
      'products': [
        {
          'id': 'sh-01',
          'name': 'Beras Rojolele Delanggu 5 Kg',
          'price': 72000,
          'commission': 3600,
          'image': 'assets/images/prod_beras.png',
        },
        {
          'id': 'sh-02',
          'name': 'Minyak Goreng Sawit 2 Liter Pouch',
          'price': 34000,
          'commission': 1700,
          'image': 'assets/images/prod_beras.png',
        },
      ],
    },
  ];

  final List<Map<String, dynamic>> _commissionHistory = [
    {
      'title': 'Komisi Pembelian Dimsum Mentai',
      'source': 'Referral @ratna_warga',
      'amount': 3600,
      'date': 'Hari ini, 13:42',
      'status': 'MASUK',
    },
    {
      'title': 'Komisi Paket Rocket 1 x2',
      'source': 'Referral @budi_praci',
      'amount': 3600,
      'date': 'Kemarin, 19:15',
      'status': 'MASUK',
    },
    {
      'title': 'Penarikan Saldo Cuan ke GagePay',
      'source': 'Pencairan Otomatis Saldo Dompet',
      'amount': -100000,
      'date': '14 Okt 2026, 10:00',
      'status': 'SELESAI',
    },
    {
      'title': 'Komisi Belanja Sembako Beras 5Kg',
      'source': 'Referral @siti_maryam',
      'amount': 3600,
      'date': '13 Okt 2026, 09:20',
      'status': 'MASUK',
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
    super.dispose();
  }

  Future<void> _loadAffiliateData() async {
    try {
      final stats = await GageApiClient.getAffiliateStats(_voucherCode);
      if (mounted && stats.isNotEmpty) {
        setState(() {
          _totalClicks = (stats['total_clicks'] as num?)?.toInt() ?? _totalClicks;
          _totalOrders = (stats['total_orders'] as num?)?.toInt() ?? _totalOrders;
          _conversionRate = (stats['conversion_rate'] as num?)?.toDouble() ?? _conversionRate;
          _totalCommission = (stats['total_commission_earned'] as num?)?.toInt() ?? _totalCommission;
          _isLoadingStats = false;
        });
      } else if (mounted) {
        setState(() => _isLoadingStats = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingStats = false);
    }
  }

  void _copyReferralCode() {
    Clipboard.setData(ClipboardData(text: _voucherCode));
    GageToast.show(
      context,
      'Kode referral $_voucherCode berhasil disalin!',
      type: GageToastType.success,
    );
  }

  Future<void> _shareToWhatsApp() async {
    final text = 'Halo lur! Mau pesan makanan, belanja sembako, atau kirim paket di Pracimantoro makin hemat dan praktis pakai aplikasi *GAGE*. '
        'Pakai kode referral saya *$_voucherCode* saat daftar buat klaim voucher diskon Rp 10.000 langsung! '
        'Download aplikasi GAGE di sini: https://gage.id/cuan/$_voucherCode';
    final url = 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        Clipboard.setData(ClipboardData(text: text));
        if (mounted) {
          GageToast.show(context, 'Teks ajakan berhasil disalin ke clipboard!', type: GageToastType.info);
        }
      }
    } catch (_) {
      Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        GageToast.show(context, 'Teks ajakan berhasil disalin ke clipboard!', type: GageToastType.info);
      }
    }
  }

  void _withdrawCommission() {
    if (_availableBalance <= 0) {
      GageToast.show(context, 'Saldo komisi belum mencukupi untuk ditarik.', type: GageToastType.warning);
      return;
    }

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: GageTheme.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 24),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarik Saldo Cuan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    SizedBox(height: 2),
                    Text('Pindahkan komisi langsung ke saldo GagePay', style: TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Jumlah Penarikan:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                Text(
                  currencyFormatter.format(_availableBalance),
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: GageTheme.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Saldo akan langsung masuk ke dompet GagePay dan dapat dipakai untuk transaksi atau ditarik ke rekening bank lokal.',
            style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary, height: 1.35),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  _availableBalance = 0;
                  _commissionHistory.insert(0, {
                    'title': 'Penarikan Saldo Cuan ke GagePay',
                    'source': 'Pencairan Mandiri oleh Pengguna',
                    'amount': -85000,
                    'date': 'Baru saja',
                    'status': 'SELESAI',
                  });
                });
                GageToast.show(
                  context,
                  'Berhasil! Komisi Rp 85.000 telah masuk ke saldo GagePay Anda.',
                  type: GageToastType.success,
                );
              },
              child: const Text('Konfirmasi & Pindahkan ke GagePay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _copyProductLink(Map<String, dynamic> prod, String merchantName) {
    final prodName = prod['name'] ?? 'Menu';
    final targetUrl = 'https://gage.id/c/${prod['id']}-$_voucherCode'.toLowerCase();

    Clipboard.setData(ClipboardData(text: targetUrl));
    GageToast.show(
      context,
      'Link komisi untuk "$prodName" berhasil disalin!',
      type: GageToastType.success,
    );
  }

  void _showQrPosterModal(Map<String, dynamic> prod, String merchantName) {
    final name = prod['name'] ?? 'Menu Pilihan';
    final targetUrl = 'https://gage.id/c/${prod['id']}-$_voucherCode'.toLowerCase();

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Flyer QR Menu: $name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text('Dari $merchantName • Scan untuk beli dengan diskon.', style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade300),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                const Text('GAGE PRACIMANTORO', style: TextStyle(color: GageTheme.primary, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
                const SizedBox(height: 4),
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                QrImageView(
                  data: targetUrl,
                  version: QrVersions.auto,
                  size: 140.0,
                  gapless: false,
                ),
                const SizedBox(height: 8),
                Text('Kode Promo: $_voucherCode', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: GageTheme.primary)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: targetUrl));
                Navigator.pop(ctx);
                GageToast.show(context, 'Tautan flyer berhasil disalin!', type: GageToastType.success);
              },
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Salin Tautan Flyer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'GAGE Cuan',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.3),
        ),
        actions: [
          IconButton(
            tooltip: 'Bagikan ke WhatsApp',
            icon: const Icon(Icons.share_rounded),
            onPressed: _shareToWhatsApp,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: isDark ? Colors.white60 : GageTheme.textSecondary,
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: 'Produk Cuan'),
            Tab(text: 'Riwayat Komisi'),
            Tab(text: 'Panduan & Banner'),
          ],
        ),
      ),
      body: Column(
        children: [
          // HERO BANNER SALDO CUAN
          _buildHeroCuanCard(isDark),

          // TAB CONTENT
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() => _isLoadingStats = true);
                await _loadAffiliateData();
              },
              color: GageTheme.primary,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildProductCatalogTab(isDark),
                  _buildHistoryTab(isDark),
                  _buildReferralGuideTab(isDark),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCuanCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [const Color(0xFFEF4444), const Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : GageTheme.primary).withValues(alpha: 0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.monetization_on_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Saldo Cuan Siap Tarik',
                    style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _voucherCode,
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isLoadingStats) ...[
                    const GageSkeletonBox(width: 140, height: 26),
                    const SizedBox(height: 6),
                    const GageSkeletonBox(width: 180, height: 13),
                  ] else ...[
                    Text(
                      currencyFormatter.format(_availableBalance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total Cuan Diperoleh: ${currencyFormatter.format(_totalCommission)}',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 11.5),
                    ),
                  ],
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: GageTheme.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _withdrawCommission,
                icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                label: const Text('Tarik Cuan', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProductCatalogTab(bool isDark) {
    if (_selectedMerchantForAffiliate == null) {
      if (_isLoadingStats) {
        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Katalog Toko Berkomisi', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
                Text('Komisi s/d 10%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Pilih toko mitra untuk membagikan link produk menu dan raih komisi instan setiap pesanan.',
              style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            for (int i = 0; i < 4; i++) const GageSkeletonStoreCard(),
          ],
        );
      }

      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Katalog Toko Berkomisi', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold)),
              Text('Komisi s/d 10%', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih toko mitra untuk membagikan link produk menu dan raih komisi instan setiap pesanan.',
            style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary),
          ),
          const SizedBox(height: 12),

          for (var m in _affiliateMerchants)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => setState(() => _selectedMerchantForAffiliate = m),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          m['image'],
                          width: 58,
                          height: 58,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            width: 58,
                            height: 58,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.storefront_rounded),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(m['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                            const SizedBox(height: 2),
                            Text(m['category'], style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(6)),
                              child: Text('Komisi ${m['commissionRate']}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green.shade700)),
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
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back_rounded, size: 20),
              onPressed: () => setState(() => _selectedMerchantForAffiliate = null),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_selectedMerchantForAffiliate!['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                  const Text('Pilih produk untuk salin link komisi', style: TextStyle(fontSize: 11, color: GageTheme.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (var prod in (_selectedMerchantForAffiliate!['products'] as List))
          Card(
            margin: const EdgeInsets.only(bottom: 10),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      prod['image'],
                      width: 58,
                      height: 58,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        width: 58,
                        height: 58,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(prod['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text(currencyFormatter.format(prod['price']), style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text('Cuan: +${currencyFormatter.format(prod['commission'])}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Salin Link Komisi',
                        icon: const Icon(Icons.link_rounded, color: GageTheme.primary, size: 22),
                        onPressed: () => _copyProductLink(prod, _selectedMerchantForAffiliate!['name']),
                      ),
                      IconButton(
                        tooltip: 'Flyer QR',
                        icon: const Icon(Icons.qr_code_2_rounded, size: 22),
                        onPressed: () => _showQrPosterModal(prod, _selectedMerchantForAffiliate!['name']),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        // Ringkasan Statistik Grid (Skeleton Shimmer saat loading)
        if (_isLoadingStats)
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: const [
              GageSkeletonStatBox(),
              GageSkeletonStatBox(),
              GageSkeletonStatBox(),
              GageSkeletonStatBox(),
            ],
          )
        else
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.1,
            children: [
              _buildMiniStat('Total Klik', '$_totalClicks kali', Icons.touch_app_rounded, Colors.blue),
              _buildMiniStat('Pesanan Berhasil', '$_totalOrders order', Icons.shopping_bag_outlined, GageTheme.accentGreen),
              _buildMiniStat('Rasio Konversi', '$_conversionRate%', Icons.trending_up_rounded, Colors.orange),
              _buildMiniStat('Referral Aktif', '32 Pengguna', Icons.group_rounded, GageTheme.primary),
            ],
          ),

        const SizedBox(height: 16),
        const Text('Riwayat Komisi & Penarikan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        const SizedBox(height: 8),

        if (_isLoadingStats)
          for (int i = 0; i < 4; i++) const GageSkeletonTransactionTile()
        else
          for (var item in _commissionHistory)
            Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: (item['amount'] as int) > 0 ? Colors.green.shade50 : Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    (item['amount'] as int) > 0 ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: (item['amount'] as int) > 0 ? Colors.green.shade700 : Colors.red.shade700,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['title'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text('${item['source']} • ${item['date']}', style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
                    ],
                  ),
                ),
                Text(
                  (item['amount'] as int) > 0
                      ? '+${currencyFormatter.format(item['amount'])}'
                      : currencyFormatter.format(item['amount']),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                    color: (item['amount'] as int) > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildReferralGuideTab(bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      children: [
        // Kode Referral Card
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade200),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Icon(Icons.celebration_rounded, color: GageTheme.primary, size: 36),
                const SizedBox(height: 8),
                const Text('Kode Referral Unik Anda', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                const Text(
                  'Ajak tetangga & warung sekitar Pracimantoro bergabung. Mereka dapat diskon Rp 10.000, Anda dapat komisi selamanya.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary, height: 1.35),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _voucherCode,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5, color: GageTheme.primary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 20),
                        onPressed: _copyReferralCode,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF25D366),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _shareToWhatsApp,
                    icon: const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Bagikan ke WhatsApp Warga', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),
        const Text('3 Langkah Mudah Cuan di GAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
        const SizedBox(height: 8),

        _buildStepItem('1', 'Bagikan Kode Referral', 'Kirim kode Anda ke grup WhatsApp keluarga, tetangga, atau status WA.'),
        _buildStepItem('2', 'Teman Daftar & Belanja', 'Teman Anda mendapatkan potongan diskon Rp 10.000 untuk pesanan pertama.'),
        _buildStepItem('3', 'Terima Komisi Mengalir', 'Setiap kali teman bertransaksi, komisi 10% masuk otomatis ke saldo dompet Anda.'),
      ],
    );
  }

  Widget _buildStepItem(String num, String title, String desc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: GageTheme.primary,
            child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 2),
                Text(desc, style: const TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: const TextStyle(fontSize: 10.5, color: GageTheme.textSecondary)),
                Text(val, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w900, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
