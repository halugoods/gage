import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/cart_provider.dart';
import 'package:gage_app/features/food/presentation/food_explore_screen.dart';
import 'package:gage_app/features/food/presentation/shop_screen.dart';
import 'package:gage_app/features/ride/presentation/ride_booking_screen.dart';
import 'package:gage_app/features/ride/presentation/send_booking_screen.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/home/presentation/home_screen.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_ticket_voucher_card.dart';
import 'package:gage_app/features/home/presentation/voucher_history_screen.dart';

class PromoScreen extends StatefulWidget {
  const PromoScreen({super.key});

  @override
  State<PromoScreen> createState() => _PromoScreenState();
}

class _PromoScreenState extends State<PromoScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeCtrl = TextEditingController();
  int _selectedTabIndex = 0;

  final List<String> _tabs = ['Semua', 'Diskon', 'Gratis Ongkir'];

  // Master Database Voucher Kupon GAGE (Urutan Terstruktur: Food -> Mart -> Transport -> Logistik)
  final List<Map<String, dynamic>> _allVouchers = [
    // 1. KULINER (GAGE Food) - Diskon Utama & Ongkir
    {
      'id': 'v-food-50',
      'code': 'DISKON50',
      'service': 'GAGE Food',
      'type': 'order',
      'title': 'Diskon 50% s.d 15RB',
      'discountText': 'Diskon 50% s.d 15RB',
      'minOrder': 20000,
      'quantity': 3,
      'tag': 'Pengguna Baru',
      'expiry': '31 Des 2026',
      'terms': [
        'Diskon 50% hingga maksimal potongan Rp 15.000.',
        'Berlaku untuk semua resto kuliner mitra GAGE Food.',
        'Minimal transaksi pemesanan Rp 20.000.',
        'Dapat digabung dengan voucher gratis ongkir.',
      ],
      'howToUse': 'Klik "Pakai", lalu potongan harga langsung otomatis memotong total belanja Anda di keranjang checkout.',
    },
    {
      'id': 'v-food-20',
      'code': 'KULINER20',
      'service': 'GAGE Food',
      'type': 'order',
      'title': 'Diskon 20% s.d 20RB',
      'discountText': 'Diskon 20% s.d 20RB',
      'minOrder': 50000,
      'quantity': 2,
      'tag': 'Diskon Terus',
      'expiry': '31 Des 2026',
      'terms': [
        'Diskon 20% hingga maksimal potongan Rp 20.000.',
        'Berlaku untuk pesanan makan siang dan malam.',
        'Minimal belanja Rp 50.000.',
      ],
      'howToUse': 'Otomatis terpasang di keranjang GAGE Food.',
    },
    {
      'id': 'v-ongkir-01',
      'code': 'ONGKIRGRATIS',
      'service': 'GAGE Food',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 7RB',
      'discountText': 'Gratis Ongkir s.d 7RB',
      'minOrder': 25000,
      'quantity': 5,
      'tag': 'Semua Resto',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan ongkir gratis hingga maksimal Rp 7.000.',
        'Berlaku untuk pengantaran kurir motor GAGE Food.',
        'Minimal transaksi pemesanan Rp 25.000.',
        'Dapat digunakan bersamaan dengan voucher diskon makanan.',
      ],
      'howToUse': 'Pilih voucher ini, dan biaya kurir antar otomatis terpotong di keranjang.',
    },

    // 2. BELANJA & SEMBAKO (GAGE Mart)
    {
      'id': 'v-mart-01',
      'code': 'BELANJAMART',
      'service': 'GAGE Mart',
      'type': 'order',
      'title': 'Diskon 10RB',
      'discountText': 'Diskon 10RB',
      'minOrder': 35000,
      'quantity': 1,
      'tag': 'Mitra Toko',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 10.000 di toko mitra resmi GAGE Mart.',
        'Minimal total belanja sembako Rp 35.000.',
      ],
      'howToUse': 'Pilih voucher saat checkout belanjaan toko.',
    },

    // 3. TRANSPORTASI (GAGE Car & GAGE Ride)
    {
      'id': 'v-car-01',
      'code': 'GAGECAR15',
      'service': 'GAGE Car',
      'type': 'order',
      'title': 'Diskon 15RB',
      'discountText': 'Diskon 15RB',
      'minOrder': 30000,
      'quantity': 2,
      'tag': 'GAGE Car',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan langsung Rp 15.000 untuk pemesanan armada GAGE Car.',
        'Minimal tarif perjalanan Rp 30.000.',
        'Berlaku untuk seluruh perjalanan di area operasional GAGE.',
      ],
      'howToUse': 'Gunakan saat memesan armada GAGE Car.',
    },
    {
      'id': 'v-ride-01',
      'code': 'RIDEHEMAT',
      'service': 'GAGE Ride',
      'type': 'order',
      'title': 'Diskon 4RB',
      'discountText': 'Diskon 4RB',
      'minOrder': 10000,
      'quantity': 1,
      'tag': 'GAGE Ride',
      'expiry': '31 Des 2026',
      'terms': [
        'Potongan Rp 4.000 untuk perjalanan ojek motor GAGE Ride.',
        'Minimal transaksi Rp 10.000.',
        'Berlaku 1x sehari untuk setiap akun pengguna.',
      ],
      'howToUse': 'Pilih saat memesan GAGE Ride sebelum klik konfirmasi driver.',
    },

    // 4. PENGIRIMAN & LOGISTIK (GAGE Send)
    {
      'id': 'v-send-01',
      'code': 'KIRIMKILAT',
      'service': 'GAGE Send',
      'type': 'delivery',
      'title': 'Gratis Ongkir s.d 5RB',
      'discountText': 'Gratis Ongkir s.d 5RB',
      'minOrder': 12000,
      'quantity': 3,
      'tag': 'GAGE Send',
      'expiry': '31 Des 2026',
      'terms': [
        'Subsidi ongkir Rp 5.000 untuk pengiriman barang dan dokumen kilat.',
        'Tarif hemat khusus wilayah Pracimantoro dan sekitarnya.',
      ],
      'howToUse': 'Gunakan di halaman pemesanan kurir kirim barang GAGE Send.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && _selectedTabIndex != _tabController.index) {
        setState(() => _selectedTabIndex = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getVouchersForTab(int tabIndex) {
    switch (tabIndex) {
      case 1: // Diskon (Merangkap Food, Mart, Ride/Car, BaBe)
        return _allVouchers.where((v) => v['type'] != 'delivery').toList();
      case 2: // Gratis Ongkir (Merangkap semua layanan)
        return _allVouchers.where((v) => v['type'] == 'delivery').toList();
      default: // Semua
        return _allVouchers;
    }
  }

  void _applyAndRedirect(BuildContext context, Map<String, dynamic> voucher) {
    final cart = context.read<CartProvider>();
    final code = voucher['code'] as String;
    final service = voucher['service'] as String;
    final isOrder = voucher['type'] == 'order';

    if (isOrder) {
      final disc = code == 'DISKON50'
          ? 15000
          : (code == 'KULINER20'
              ? 20000
              : (code == 'GAGECAR15'
                  ? 15000
                  : (code == 'RIDEHEMAT' ? 4000 : 10000)));
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
        Navigator.push(context, MaterialPageRoute(builder: (_) => const FoodExploreScreen()));
        break;
      case 'GAGE Ride':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBookingScreen(initialTab: 'ride')));
        break;
      case 'GAGE Car':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBookingScreen(initialTab: 'car')));
        break;
      case 'GAGE Mart':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ShopScreen()));
        break;
      case 'GAGE Send':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SendBookingScreen()));
        break;
      default:
        break;
    }
  }

  void _showVoucherTerms(BuildContext context, Map<String, dynamic> voucher) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final terms = voucher['terms'] as List<dynamic>? ?? [];

    GageFloatingSheet.show(
      context: context,
      title: 'Syarat & Ketentuan',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.confirmation_number_rounded, color: GageTheme.primary, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        voucher['code'] ?? '',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                      ),
                      Text(
                        'Berlaku hingga ${voucher['expiry']}',
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ketentuan Pemakaian:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          ...terms.map((t) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.bold, color: GageTheme.primary)),
                    Expanded(
                      child: Text(
                        t.toString(),
                        style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87, height: 1.3),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 14),
          const Text(
            'Cara Penggunaan:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            voucher['howToUse'] ?? 'Pilih voucher saat melakukan checkout pesanan.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.grey.shade700, height: 1.3),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () {
                Navigator.pop(context);
                _applyAndRedirect(context, voucher);
              },
              child: const Text('Gunakan Voucher Ini', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClaimPromoSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _codeCtrl.clear();

    GageFloatingSheet.show(
      context: context,
      title: 'Klaim Kode Promo',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Masukkan kode promo atau voucher unik GAGE untuk mendapatkan potongan harga spesial:',
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Misal: DISKON50, ONGKIRGRATIS',
              hintStyle: TextStyle(fontSize: 12.5, color: Colors.grey.shade400),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
              ),
            ),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: () {
                final code = _codeCtrl.text.trim().toUpperCase();
                if (code.isEmpty) return;
                Navigator.pop(context);

                final match = _allVouchers.firstWhere(
                  (v) => (v['code'] as String).toUpperCase() == code,
                  orElse: () => {},
                );

                if (match.isNotEmpty) {
                  HapticFeedback.mediumImpact();
                  GageToast.show(context, 'Selamat! Voucher $code berhasil diklaim.', type: GageToastType.success);
                } else {
                  HapticFeedback.heavyImpact();
                  GageToast.show(context, 'Kode promo "$code" tidak ditemukan atau sudah habis.', type: GageToastType.error);
                }
              },
              child: const Text('Klaim Voucher', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          ),
        );
      },
      child: Scaffold(
        backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
        extendBody: true,
        appBar: AppBar(
          title: Text(
            'Voucher Saya',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 17,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
          foregroundColor: isDark ? Colors.white : Colors.black87,
          elevation: 0,
          actions: [
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VoucherHistoryScreen()),
                );
              },
              child: const Text(
                'Riwayat',
                style: TextStyle(
                  color: GageTheme.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 6),
          ],
        ),
        body: Column(
          children: [
            // 1. Input Kode Promo Bar (Full-Rounded & Frosted Blur Floating Sheet)
            Container(
              color: isDark ? GageTheme.darkSurface : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: InkWell(
                onTap: () => _showClaimPromoSheet(context),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.grey.shade300,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: GageTheme.primary, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Masukkan kode promo',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white60 : Colors.grey.shade500,
                          ),
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white38 : Colors.grey.shade400, size: 20),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Segmented Tab Switch Khas GAGE (Full Rounded Pill)
            Container(
              color: isDark ? GageTheme.darkSurface : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: List.generate(_tabs.length, (idx) {
                    final isSel = _selectedTabIndex == idx;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          _tabController.animateTo(idx);
                          setState(() => _selectedTabIndex = idx);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? GageTheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: GageTheme.primary.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            _tabs[idx],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              color: isSel
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            // 3. TabBarView dengan List Tiket Voucher Khas GAGE
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: List.generate(_tabs.length, (tabIdx) {
                  final list = _getVouchersForTab(tabIdx);

                  if (list.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.confirmation_number_outlined, size: 48, color: Colors.grey.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          Text(
                            'Belum ada voucher untuk kategori ini.',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 85),
                    itemCount: list.length,
                    itemBuilder: (ctx, idx) {
                      final v = list[idx];
                      return GageTicketVoucherCard(
                        voucher: v,
                        onApply: () => _applyAndRedirect(context, v),
                        onTermsTap: () => _showVoucherTerms(context, v),
                      );
                    },
                  );
                }),
              ),
            ),
          ],
        ),
        bottomNavigationBar: const GageBottomNavBar(currentIndex: 2),
      ),
    );
  }
}
