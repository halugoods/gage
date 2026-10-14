import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Filter pill aktif di tab Voucher: 'Semua', 'GAGE Food', 'GAGE Ride', 'GAGE Car', 'GAGE Send', 'GAGE Mart', 'GAGE Pay'
  String _activeServiceFilter = 'Semua';

  final List<String> _serviceFilters = [
    'Semua',
    'GAGE Food',
    'GAGE Ride',
    'GAGE Car',
    'GAGE Send',
    'GAGE Mart',
    'GAGE Pay',
  ];

  // Daftar Semua Voucher Gabungan (Diskon Pesanan & Diskon Ongkir)
  final List<Map<String, dynamic>> _vouchers = [
    {
      'id': 'v-food-01',
      'code': 'DISKON50',
      'service': 'GAGE Food',
      'type': 'order',
      'title': 'DISKON Rp15.000 Kuliner Pengguna Baru',
      'discountText': 'Diskon 50% (Maks. Rp 15.000)',
      'minOrder': 20000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/food_hero_banner.png',
      'terms': [
        'Diskon 50% hingga maksimal potongan Rp 15.000.',
        'Berlaku untuk semua resto & merchant kuliner di GAGE Food.',
        'Minimal transaksi pemesanan Rp 20.000.',
        'Dapat digabung dengan voucher diskon ongkir.',
      ],
      'howToUse': 'Klik "Pakai", lalu potongan harga langsung otomatis memotong total belanja Anda di keranjang checkout.',
    },
    {
      'id': 'v-ongkir-01',
      'code': 'ONGKIRGRATIS',
      'service': 'GAGE Food',
      'type': 'delivery',
      'title': 'GRATIS ONGKIR Pengantaran Kuliner s.d. Rp 7.000',
      'discountText': 'Potongan Ongkir s.d. Rp 7.000',
      'minOrder': 25000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/food_hero_banner.png',
      'terms': [
        'Potongan ongkir gratis hingga maksimal Rp 7.000.',
        'Berlaku untuk pengantaran kurir motor GAGE Food.',
        'Minimal transaksi pemesanan Rp 25.000.',
        'Dapat digunakan bersamaan dengan voucher diskon makanan.',
      ],
      'howToUse': 'Pilih voucher ini, dan biaya kurir antar otomatis terpotong di keranjang.',
    },
    {
      'id': 'v-car-01',
      'code': 'GAGECAR15',
      'service': 'GAGE Car',
      'type': 'order',
      'title': 'DISKON Rp15.000 Perjalanan Rombongan Mobil GAGE Car',
      'discountText': 'Potongan Langsung Rp 15.000',
      'minOrder': 30000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/ride_hero_banner.png',
      'terms': [
        'Potongan langsung Rp 15.000 untuk pemesanan armada GAGE Car.',
        'Minimal tarif perjalanan Rp 30.000.',
        'Berlaku untuk perjalanan dalam & antar kecamatan.',
      ],
      'howToUse': 'Gunakan saat memesan armada GAGE Car.',
    },
    {
      'id': 'v-ride-01',
      'code': 'RIDEHEMAT',
      'service': 'GAGE Ride',
      'type': 'order',
      'title': 'DISKON Rp4.000 Antar Jemput Motor GAGE Ride',
      'discountText': 'Potongan Langsung Rp 4.000',
      'minOrder': 10000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/ride_hero_banner.png',
      'terms': [
        'Potongan Rp 4.000 untuk perjalanan ojek motor GAGE Ride.',
        'Minimal transaksi Rp 10.000.',
        'Berlaku 1x sehari untuk setiap akun pengguna.',
      ],
      'howToUse': 'Pilih saat memesan GAGE Ride sebelum klik konfirmasi driver.',
    },
    {
      'id': 'v-mart-01',
      'code': 'BELANJAMART',
      'service': 'GAGE Mart',
      'type': 'order',
      'title': 'DISKON Rp10.000 Belanja Sembako & Kebutuhan Harian',
      'discountText': 'Potongan Belanja Rp 10.000',
      'minOrder': 35000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/shop_hero_banner.png',
      'terms': [
        'Potongan langsung Rp 10.000 di toko mitra resmi GAGE Mart.',
        'Minimal total belanja sembako Rp 35.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout belanjaan toko.',
    },
    {
      'id': 'v-send-01',
      'code': 'KIRIMKILAT',
      'service': 'GAGE Send',
      'type': 'delivery',
      'title': 'SUBSIDI ONGKIR Rp5.000 Kirim Paket Instan',
      'discountText': 'Potongan Ongkir Rp 5.000',
      'minOrder': 12000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/send_hero_banner.png',
      'terms': [
        'Subsidi ongkir Rp 5.000 untuk pengiriman barang dan dokumen kilat.',
        'Tarif hemat khusus wilayah Pracimantoro dan sekitarnya.',
      ],
      'howToUse': 'Gunakan di halaman pemesanan kurir kirim barang GAGE Send.',
    },
    {
      'id': 'v-pay-01',
      'code': 'CASHBACK10',
      'service': 'GAGE Pay',
      'type': 'order',
      'title': 'CASHBACK 10% Saldo Dompet GAGE Pay',
      'discountText': 'Cashback 10% (Maks. Rp 10.000)',
      'minOrder': 20000,
      'expiry': '31 Des 2026',
      'image': 'assets/images/voucher_art_food.png',
      'terms': [
        'Cashback 10% dalam bentuk Koin GAGE Cuan.',
        'Berlaku untuk pembayaran menggunakan saldo dompet GAGE Pay.',
      ],
      'howToUse': 'Pilih metode pembayaran GAGE Pay saat menyelesaikan pesanan.',
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

  List<Map<String, dynamic>> get _filteredVouchers {
    if (_activeServiceFilter == 'Semua') {
      return _vouchers;
    }
    return _vouchers.where((v) => v['service'] == _activeServiceFilter).toList();
  }

  void _applyAndRedirect(BuildContext context, Map<String, dynamic> voucher, CartProvider cart) {
    final code = voucher['code'] as String;
    final service = voucher['service'] as String;
    final isOrder = voucher['type'] == 'order';

    if (isOrder) {
      final disc = code == 'DISKON50'
          ? 15000
          : (code == 'GAGECAR15'
              ? 15000
              : (code == 'RIDEHEMAT' ? 4000 : 10000));
      cart.setFoodPromo(code, disc);
    } else {
      final disc = code == 'ONGKIRGRATIS' ? 7000 : 5000;
      cart.setDeliveryPromo(code, disc);
    }

    GageToast.show(
      context,
      'Voucher $code berhasil dipasang! Mengalihkan ke $service...',
      type: GageToastType.success,
    );

    switch (service) {
      case 'GAGE Food':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const FoodExploreScreen()),
        );
        break;
      case 'GAGE Ride':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'ride')),
        );
        break;
      case 'GAGE Car':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const RideBookingScreen(initialTab: 'car')),
        );
        break;
      case 'GAGE Mart':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const ShopScreen()),
        );
        break;
      case 'GAGE Send':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (ctx) => const SendBookingScreen()),
        );
        break;
      default:
        break;
    }
  }

  void _showVoucherDetail(BuildContext context, Map<String, dynamic> voucher) {
    final cart = context.read<CartProvider>();

    GageFloatingSheet.show(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Voucher
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: AspectRatio(
                aspectRatio: 2.7,
                child: Image.asset(
                  voucher['image'],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kategori Layanan & Masa Berlaku
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    voucher['service'],
                    style: const TextStyle(
                      color: GageTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Berlaku s.d. ${voucher['expiry']}',
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Text(
              voucher['title'],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              voucher['discountText'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: GageTheme.primary,
              ),
            ),

            const Divider(height: 24),

            // Syarat & Ketentuan
            const Text('Syarat & Ketentuan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            ...((voucher['terms'] as List<String>).map((t) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                      Expanded(child: Text(t, style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary))),
                    ],
                  ),
                ))),

            const SizedBox(height: 12),

            // Cara Menggunakan
            const Text('Cara Menggunakan:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              voucher['howToUse'],
              style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary, height: 1.3),
            ),

            const SizedBox(height: 22),

            // Tombol Gunakan Voucher & Redirect
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
                  Navigator.pop(ctx);
                  _applyAndRedirect(context, voucher, cart);
                },
                child: Text(
                  'Pakai Voucher (${voucher['code']})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Voucher & paket voucher',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: isDark ? Colors.white : Colors.black87),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: GageTheme.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.grey.shade600,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          indicatorColor: GageTheme.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          tabs: const [
            Tab(text: 'Voucher'),
            Tab(text: 'GAGE Plus'),
            Tab(text: 'GAGE Max'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // TAB 1: VOUCHER (Dengan Filter Pills Gojek Style)
          _buildVouchersTab(cart),

          // TAB 2: GAGE PLUS (Membership Hemat)
          _buildGagePlusTab(),

          // TAB 3: GAGE MAX (Membership Sultan & Priority)
          _buildGageMaxTab(),
        ],
      ),
    );
  }

  // Widget Tab 1: Voucher & Horizontal Filter Pills
  Widget _buildVouchersTab(CartProvider cart) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        // Horizontal Service Filter Pills
        Container(
          height: 48,
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _serviceFilters.length,
            itemBuilder: (ctx, idx) {
              final filter = _serviceFilters[idx];
              final isSelected = _activeServiceFilter == filter;

              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSelected,
                  labelStyle: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? (isDark ? Colors.white : Colors.black87) : (isDark ? Colors.white60 : Colors.grey.shade700),
                  ),
                  backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
                  selectedColor: isDark ? GageTheme.darkBorder : Colors.grey.shade100,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(
                      color: isSelected ? GageTheme.primary : (isDark ? GageTheme.darkBorder : Colors.grey.shade300),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    setState(() => _activeServiceFilter = filter);
                  },
                ),
              );
            },
          ),
        ),

        // List Voucher Cards (Sesuai Referensi Gambar 2)
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: _filteredVouchers.length,
            itemBuilder: (ctx, idx) {
              final v = _filteredVouchers[idx];

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(color: isDark ? Colors.black38 : Colors.black12, blurRadius: 4, offset: const Offset(0, 1)),
                  ],
                ),
                child: InkWell(
                  onTap: () => _showVoucherDetail(context, v),
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner Voucher (Rasio Baku 2.7:1 - Ukuran Rekomendasi 1080x400)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: AspectRatio(
                           aspectRatio: 2.7,
                          child: Image.asset(
                            v['image'],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Container(color: GageTheme.primaryLight),
                          ),
                        ),
                      ),

                      // Keterangan Voucher di Bawah
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              v['title'],
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13.5,
                                color: isDark ? Colors.white : Colors.black87,
                                height: 1.25,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(Icons.calendar_today_rounded, size: 13, color: isDark ? Colors.white60 : Colors.black54),
                                const SizedBox(width: 6),
                                Text(
                                  'Berlaku hingga ${v['expiry']}',
                                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                                const Spacer(),
                                SizedBox(
                                  height: 32,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: GageTheme.primary,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16),
                                    ),
                                    onPressed: () => _applyAndRedirect(context, v, cart),
                                    child: const Text(
                                      'Pakai',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
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
              );
            },
          ),
        ),
      ],
    );
  }

  // Widget Tab 2: GAGE Plus Membership
  Widget _buildGagePlusTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [GageTheme.primary, Color(0xFFB91C1C)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'GAGE PLUS',
                      style: TextStyle(fontWeight: FontWeight.w900, color: GageTheme.primary, fontSize: 12),
                    ),
                  ),
                  const Text('Langganan Hemat 30 Hari', style: TextStyle(color: Colors.white70, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Paket GAGE Plus Hemat',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Hemat hingga Rp 150.000 untuk kebutuhan antar jemput, makanan & belanja harian.',
                style: TextStyle(color: Colors.white, fontSize: 12, height: 1.3),
              ),
              const Divider(color: Colors.white30, height: 24),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('10x Voucher Gratis Ongkir Kuliner & Mart', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('5x Diskon Rp 5.000 GAGE Ride & Car', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rp 19.900', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('/bulan', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      GageToast.show(
                        context,
                        'Fitur Membership GAGE Plus akan segera hadir!',
                        type: GageToastType.info,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: GageTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Beli Paket', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Widget Tab 3: GAGE Max Membership
  Widget _buildGageMaxTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.amber.shade400, width: 1.2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'GAGE MAX',
                      style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87, fontSize: 12),
                    ),
                  ),
                  const Text('VIP Sultan Unlimited', style: TextStyle(color: Colors.amber, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Paket Sultan Prioritas',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Pengalaman VIP tanpa batas: prioritas antrean driver, bebas ongkir sepuasnya, dan cashback loyalitas 15%.',
                style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.3),
              ),
              const Divider(color: Colors.white24, height: 24),
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Unlimited Diskon Ongkir di Semua Layanan', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Jalur Cepat Prioritas Penugasan Driver Instan', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 6),
              const Row(
                children: [
                  Icon(Icons.stars_rounded, color: Colors.amber, size: 16),
                  SizedBox(width: 8),
                  Expanded(child: Text('Cashback 15% Koin GAGE Cuan Tiap Transaksi', style: TextStyle(color: Colors.white, fontSize: 12))),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rp 49.900', style: TextStyle(color: Colors.amber, fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('/bulan', style: TextStyle(color: Colors.white54, fontSize: 10.5)),
                    ],
                  ),
                  ElevatedButton(
                    onPressed: () {
                      GageToast.show(
                        context,
                        'Fitur Membership GAGE Max akan segera hadir!',
                        type: GageToastType.info,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade400,
                      foregroundColor: Colors.black87,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    child: const Text('Beli Paket VIP', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
