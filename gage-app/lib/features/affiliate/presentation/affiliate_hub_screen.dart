import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/features/food/presentation/resto_detail_screen.dart';

/// AffiliateHubScreen - GAGE Cuan: Ekosistem Afiliasi & Penawaran Kuliner Lokal
///
/// Mengadaptasi arsitektur ShopeeFood Affiliate dengan standar GAGE Clean White Design System:
/// - 2 Tab Utama (Bottom Navigation): Penawaran & Performa
/// - Header alamat pengantaran aktif Pracimantoro + Search Resto/Menu
/// - Widget 3 Kolom Performa Cepat (Klik, Pesanan, Komisi Kotor)
/// - Kartu Banner "Ajak Teman Cuan Bersama GAGE" dengan kode referral 6 karakter acak
/// - Carousel horizontal "Menu Pilihan" dengan tag terjual, badge komisi, dan tombol share cepat
/// - Tab filter kapsul penuh (BorderRadius.circular(999)): Rekomendasi, Komisi Tertinggi, Terlaris
/// - Katalog resto mitra Pracimantoro dengan komisi hingga 12% dan tombol share link toko
/// - Tab Performa dengan saldo komisi siap tarik ke GAGEPay, filter status kapsul, dan empty state dokumen
class AffiliateHubScreen extends StatefulWidget {
  const AffiliateHubScreen({super.key});

  @override
  State<AffiliateHubScreen> createState() => _AffiliateHubScreenState();
}

class _AffiliateHubScreenState extends State<AffiliateHubScreen> {
  int _currentBottomNavIndex = 0; // 0: Penawaran, 1: Performa
  int _selectedFilterIndex = 0; // 0: Rekomendasi, 1: Komisi Tertinggi, 2: Terlaris
  int _selectedPerformaFilterIndex = 0; // 0: Semua, 1: Belum Dibayar, 2: Diproses, 3: Selesai

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _referralCode = 'G8K2M9';
  int _availableCommission = 148500;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<String> _filterTabs = ['Rekomendasi', 'Komisi Tertinggi', 'Terlaris'];
  final List<String> _performaTabs = ['Semua', 'Belum Dibayar', 'Diproses', 'Selesai'];

  /// Carousel Menu Pilihan
  final List<Map<String, dynamic>> _featuredMenus = [
    {
      'id': 'mnu-tahu-01',
      'name': 'Tahu kupat',
      'merchant': 'Warung Tahu Kupat Sari Rasa',
      'price': 18500,
      'sold': '12 Terjual',
      'soldValue': 12,
      'commission': '12%',
      'commissionValue': 12,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'tahu-kupat-praci',
      'merchantData': {
        'id': 'mch-tahu-01',
        'name': 'Warung Tahu Kupat Sari Rasa',
        'category': 'Kuliner Tradisional',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.8,
      },
    },
    {
      'id': 'mnu-mie-01',
      'name': 'Mie ayam bakso jumbo',
      'merchant': 'Mie Ayam & Bakso Pak Kumis',
      'price': 28000,
      'sold': '45+ Terjual',
      'soldValue': 45,
      'commission': '12%',
      'commissionValue': 12,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'mie-ayam-bakso-jumbo',
      'merchantData': {
        'id': 'mch-mie-01',
        'name': 'Mie Ayam & Bakso Pak Kumis',
        'category': 'Bakmie & Bakso',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.8,
      },
    },
    {
      'id': 'mnu-geprek-01',
      'name': 'Nasi Ayam Geprek Hemat',
      'merchant': 'Geprekin Aja Raya Pracimantoro',
      'price': 12900,
      'sold': '200+ Terjual',
      'soldValue': 200,
      'commission': '12%',
      'commissionValue': 12,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'nasi-ayam-geprek-hemat',
      'merchantData': {
        'id': 'mch-geprek-01',
        'name': 'Geprekin Aja Raya Pracimantoro',
        'category': 'Aneka Nasi, Fried Chicken',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.9,
      },
    },
    {
      'id': 'mnu-bakso-01',
      'name': 'Bakso Urat Jumbo',
      'merchant': 'RM Bakso Mas No',
      'price': 15000,
      'sold': '320+ Terjual',
      'soldValue': 320,
      'commission': '10%',
      'commissionValue': 10,
      'image': 'assets/images/culinary_mart.png',
      'slug': 'bakso-urat-jumbo',
      'merchantData': {
        'id': 'mch-bakso-masno',
        'name': 'RM Bakso Mas No',
        'category': 'Bakso & Soto',
        'image': 'assets/images/culinary_mart.png',
        'rating': 4.8,
      },
    },
    {
      'id': 'mnu-dimsum-01',
      'name': 'Dimsum Sewu Spesial Isi 10',
      'merchant': 'Dimsum Sewu Pracimantoro',
      'price': 20000,
      'sold': '180+ Terjual',
      'soldValue': 180,
      'commission': '10%',
      'commissionValue': 10,
      'image': 'assets/images/resto_dimsum_sewu.png',
      'slug': 'dimsum-sewu-isi-10',
      'merchantData': {
        'id': 'mch-dimsum-01',
        'name': 'Dimsum Sewu Pracimantoro',
        'category': 'Dimsum & Cemilan',
        'image': 'assets/images/resto_dimsum_sewu.png',
        'rating': 4.9,
      },
    },
  ];

  /// Katalog Resto Mitra Pracimantoro
  final List<Map<String, dynamic>> _merchants = [
    {
      'id': 'mch-geprek-01',
      'name': 'Geprekin Aja Raya Pracimantoro',
      'category': 'Aneka Nasi, Fried Chicken',
      'rating': 4.9,
      'reviewsCount': 582,
      'location': 'PRACIMANTORO, KAB. WONOGIRI',
      'commissionRate': '12%',
      'commissionValue': 12,
      'isStarResto': true,
      'branchText': 'Lihat 2 gerai >',
      'image': 'assets/images/culinary_mart.png',
      'discounts': ['Diskon 20%', 'Diskon Ongkir', 'Menu Diskon s/d 54%'],
      'soldCount': 1240,
    },
    {
      'id': 'mch-bakso-masno',
      'name': 'RM Bakso Mas No',
      'category': 'Bakso & Soto',
      'rating': 4.8,
      'reviewsCount': 620,
      'location': 'PRACIMANTORO, KAB. WONOGIRI',
      'commissionRate': '10%',
      'commissionValue': 10,
      'isStarResto': true,
      'branchText': 'Lihat gerai >',
      'image': 'assets/images/culinary_mart.png',
      'discounts': ['Diskon 10%', 'Gratis Ongkir XTRA'],
      'soldCount': 2100,
    },
    {
      'id': 'mch-dimsum-01',
      'name': 'Dimsum Sewu Pracimantoro',
      'category': 'Dimsum & Cemilan',
      'rating': 4.9,
      'reviewsCount': 410,
      'location': 'PRACIMANTORO, KAB. WONOGIRI',
      'commissionRate': '10%',
      'commissionValue': 10,
      'isStarResto': true,
      'branchText': 'Lihat gerai >',
      'image': 'assets/images/resto_dimsum_sewu.png',
      'discounts': ['Porsi Jumbo', 'Diskon Ongkir'],
      'soldCount': 980,
    },
    {
      'id': 'mch-rc-01',
      'name': 'Rocket Chicken Pracimantoro',
      'category': 'Kuliner Cepat Saji, Ayam Goreng',
      'rating': 4.9,
      'reviewsCount': 1200,
      'location': 'PRACIMANTORO, KAB. WONOGIRI',
      'commissionRate': '10%',
      'commissionValue': 10,
      'isStarResto': false,
      'branchText': 'Lihat gerai >',
      'image': 'assets/images/culinary_mart.png',
      'discounts': ['Paket Hemat', 'Gratis Ongkir XTRA'],
      'soldCount': 3400,
    },
    {
      'id': 'mch-mie-01',
      'name': 'Mie Ayam & Bakso Pak Kumis',
      'category': 'Bakmie & Bakso',
      'rating': 4.8,
      'reviewsCount': 390,
      'location': 'PRACIMANTORO, KAB. WONOGIRI',
      'commissionRate': '12%',
      'commissionValue': 12,
      'isStarResto': false,
      'branchText': 'Lihat gerai >',
      'image': 'assets/images/culinary_mart.png',
      'discounts': ['Pangsit Gratis', 'Diskon 15%'],
      'soldCount': 1500,
    },
  ];

  /// Riwayat Pesanan Afiliasi (Tab Performa)
  final List<Map<String, dynamic>> _affiliateOrders = [
    {
      'orderId': 'ORD-AFF-88214',
      'date': '15 Nov 2026, 12:30 WIB',
      'productName': 'Rocket Chicken Paket 1 (Ayam Geprek + Nasi + Es Teh)',
      'merchantName': 'Rocket Chicken Pracimantoro',
      'totalPrice': 16000,
      'commissionAmount': 1600,
      'commissionRate': '10%',
      'status': 'Selesai',
      'statusLabel': 'Selesai',
    },
    {
      'orderId': 'ORD-AFF-88190',
      'date': '15 Nov 2026, 10:15 WIB',
      'productName': 'Bakso Urat Jumbo Kuah Pedas',
      'merchantName': 'RM Bakso Mas No',
      'totalPrice': 15000,
      'commissionAmount': 1500,
      'commissionRate': '10%',
      'status': 'Diproses',
      'statusLabel': 'Diproses',
    },
    {
      'orderId': 'ORD-AFF-88145',
      'date': '14 Nov 2026, 19:40 WIB',
      'productName': 'Mie Ayam Bakso Jumbo Spesial',
      'merchantName': 'Mie Ayam & Bakso Pak Kumis',
      'totalPrice': 28000,
      'commissionAmount': 3360,
      'commissionRate': '12%',
      'status': 'Selesai',
      'statusLabel': 'Selesai',
    },
    {
      'orderId': 'ORD-AFF-88092',
      'date': '14 Nov 2026, 13:20 WIB',
      'productName': 'Dimsum Sewu Spesial Isi 10',
      'merchantName': 'Dimsum Sewu Pracimantoro',
      'totalPrice': 20000,
      'commissionAmount': 2000,
      'commissionRate': '10%',
      'status': 'Selesai',
      'statusLabel': 'Selesai',
    },
  ];

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
  ];

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = _months[date.month - 1];
    return '$day $month ${date.year}';
  }

  @override
  void initState() {
    super.initState();
    _loadReferralCode();
  }

  Future<void> _loadReferralCode() async {
    final code = await AffiliateCommissionService.getOrCreateReferralCode();
    if (mounted) {
      setState(() {
        _referralCode = code;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
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

  void _shareReferralWhatsApp() {
    HapticFeedback.selectionClick();
    final message = AffiliateCommissionService.generateReferralShareText(
      referralCode: _referralCode,
      userName: 'Kreator GAGE',
    );
    Clipboard.setData(ClipboardData(text: message));
    GageToast.show(
      context,
      'Teks ajakan berhasil disalin! Buka WhatsApp untuk membagikan ke teman.',
      type: GageToastType.success,
    );
  }

  void _shareMenuLink(Map<String, dynamic> menu) {
    HapticFeedback.selectionClick();
    final link = 'https://gage.co.id/item/${menu['slug']}?ref=$_referralCode';
    final shareText = AffiliateCommissionService.generateProductShareText(
      productName: menu['name'] as String,
      merchantName: menu['merchant'] as String,
      price: menu['price'] as int,
      affiliateLink: link,
    );
    Clipboard.setData(ClipboardData(text: shareText));
    GageToast.show(
      context,
      'Link menu ${menu['name']} berhasil disalin! Bagikan ke WhatsApp atau media sosial.',
      type: GageToastType.success,
    );
  }

  void _shareMerchantLink(Map<String, dynamic> merchant) {
    HapticFeedback.selectionClick();
    final link = 'https://gage.co.id/resto/${merchant['id']}?ref=$_referralCode';
    final shareText = AffiliateCommissionService.generateMerchantShareText(
      merchantName: merchant['name'] as String,
      category: merchant['category'] as String,
      affiliateLink: link,
    );
    Clipboard.setData(ClipboardData(text: shareText));
    GageToast.show(
      context,
      'Link resto ${merchant['name']} berhasil disalin! Bagikan untuk dapat komisi hingga ${merchant['commissionRate']}.',
      type: GageToastType.success,
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
      _availableCommission = 0;
    });

    GageToast.show(
      context,
      'Penarikan ${_currencyFormat.format(amount)} langsung masuk ke Saldo GAGEPay Anda!',
      type: GageToastType.success,
    );
  }

  List<Map<String, dynamic>> _getFilteredMerchants() {
    var list = List<Map<String, dynamic>>.from(_merchants);

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        final name = (m['name'] as String).toLowerCase();
        final cat = (m['category'] as String).toLowerCase();
        return name.contains(q) || cat.contains(q);
      }).toList();
    }

    if (_selectedFilterIndex == 1) {
      // Komisi Tertinggi
      list.sort((a, b) => (b['commissionValue'] as int).compareTo(a['commissionValue'] as int));
    } else if (_selectedFilterIndex == 2) {
      // Terlaris
      list.sort((a, b) => (b['soldCount'] as int).compareTo(a['soldCount'] as int));
    }

    return list;
  }

  List<Map<String, dynamic>> _getFilteredOrders() {
    final status = _performaTabs[_selectedPerformaFilterIndex];
    if (status == 'Semua') {
      return _affiliateOrders;
    }
    return _affiliateOrders.where((o) => o['status'] == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF090D16) : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _currentBottomNavIndex,
          children: [
            _buildPenawaranTab(isDark),
            _buildPerformaTab(isDark),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(isDark),
    );
  }

  /// Bottom Navigation Bar 2 Tab (ShopeeFood Affiliate Style)
  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentBottomNavIndex = 0);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu_rounded,
                    size: 22,
                    color: _currentBottomNavIndex == 0
                        ? GageTheme.primary
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Penawaran',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _currentBottomNavIndex == 0 ? FontWeight.w800 : FontWeight.w600,
                      color: _currentBottomNavIndex == 0
                          ? GageTheme.primary
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _currentBottomNavIndex = 1);
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_rounded,
                    size: 22,
                    color: _currentBottomNavIndex == 1
                        ? GageTheme.primary
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Performa',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: _currentBottomNavIndex == 1 ? FontWeight.w800 : FontWeight.w600,
                      color: _currentBottomNavIndex == 1
                          ? GageTheme.primary
                          : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 1: PENAWARAN (OFFERS & SHARING)
  // ===========================================================================

  Widget _buildPenawaranTab(bool isDark) {
    final filteredMerchants = _getFilteredMerchants();

    return CustomScrollView(
      slivers: [
        // 1. Top Bar: Lokasi Pengantaran & Search Field
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.maybePop(context),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.arrow_back_rounded,
                          size: 22,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_rounded, size: 16, color: GageTheme.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'Surya Tani, Jalan Raya Pracimantoro, Tubokarto, Pr...',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: GageTheme.primary),
                      hintText: 'Cari Resto atau Hidangan',
                      hintStyle: TextStyle(
                        fontSize: 12.5,
                        color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Widget 3 Kolom Performa Cepat
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
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
                        'Performa di GAGE Cuan',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 13,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatDate(DateTime.now()),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildMetricItem('128', 'Klik', isDark)),
                      Container(
                        height: 32,
                        width: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      Expanded(child: _buildMetricItem('18', 'Pesanan', isDark)),
                      Container(
                        height: 32,
                        width: 1,
                        color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                      ),
                      Expanded(child: _buildMetricItem('Rp 48.500', 'Komisi Kotor', isDark, isHighlight: true)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Banner Ajak Teman Cuan (Referral 6 Karakter Acak)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE52320), Color(0xFFFF5722)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'AJAK TEMAN CUAN',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'Voucher 10rb',
                          style: TextStyle(
                            color: Color(0xFF92400E),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Bagikan kode referral acak Anda ke teman atau keluarga di Pracimantoro dan nikmati komisi tiap mereka pesan di GAGE!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11.5,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      // Kode Referral Acak 6 Digit
                      InkWell(
                        onTap: _copyReferralCode,
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(999),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _referralCode,
                                style: const TextStyle(
                                  color: GageTheme.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.copy_rounded, size: 14, color: GageTheme.primary),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: const StadiumBorder(),
                          elevation: 0,
                        ),
                        onPressed: _shareReferralWhatsApp,
                        icon: const Icon(Icons.share_rounded, size: 15),
                        label: const Text(
                          'Share WhatsApp',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),

        // 4. Section Menu Pilihan (Horizontal Carousel)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Menu Pilihan',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        GageToast.show(context, 'Menampilkan seluruh menu komisi tinggi Pracimantoro');
                      },
                      child: const Row(
                        children: [
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: GageTheme.primary,
                            ),
                          ),
                          SizedBox(width: 2),
                          Icon(Icons.chevron_right_rounded, size: 16, color: GageTheme.primary),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 220,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _featuredMenus.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (ctx, idx) {
                    final menu = _featuredMenus[idx];
                    return _buildFeaturedMenuCard(menu, isDark);
                  },
                ),
              ),
            ],
          ),
        ),

        // 5. Segmented Filter Tabs (Full Capsule BorderRadius.circular(999))
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                children: List.generate(_filterTabs.length, (idx) {
                  final isSelected = _selectedFilterIndex == idx;
                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilterIndex = idx);
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? GageTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            _filterTabs[idx],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),

        // 6. Resto List (ShopeeFood Style)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, idx) {
                final merchant = filteredMerchants[idx];
                return _buildMerchantCard(merchant, isDark);
              },
              childCount: filteredMerchants.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(String value, String label, bool isDark, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: isHighlight
                ? GageTheme.primary
                : (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedMenuCard(Map<String, dynamic> menu, bool isDark) {
    return Container(
      width: 148,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: Image.asset(
                  menu['image'] as String,
                  height: 95,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 95,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.fastfood, color: Colors.grey),
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    menu['sold'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  menu['name'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _currencyFormat.format(menu['price']),
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Komisi ${menu['commission']}',
                          style: const TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            color: GageTheme.primary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _shareMenuLink(menu),
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: const BoxDecoration(
                          color: GageTheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.reply_rounded,
                          size: 13,
                          color: Colors.white,
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
    );
  }

  Widget _buildMerchantCard(Map<String, dynamic> merchant, bool isDark) {
    final discounts = merchant['discounts'] as List<String>? ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      merchant['image'] as String,
                      width: 74,
                      height: 74,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 74,
                        height: 74,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.storefront, color: Colors.grey),
                      ),
                    ),
                  ),
                  if (merchant['isStarResto'] == true)
                    Positioned(
                      top: 4,
                      left: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE52320),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Star Resto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      merchant['name'] as String,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      merchant['category'] as String,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 2),
                        Text(
                          '${merchant['rating']} (${merchant['reviewsCount']})',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '|',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white24 : const Color(0xFFCBD5E1),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            merchant['location'] as String,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: discounts.map((d) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE52320),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Komisi Hingga ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    merchant['commissionRate'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (c) => RestoDetailScreen(merchant: merchant),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        merchant['branchText'] as String? ?? 'Lihat gerai >',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _shareMerchantLink(merchant),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: const BoxDecoration(
                        color: GageTheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.reply_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // TAB 2: PERFORMA (PERFORMANCE & COMMISSIONS)
  // ===========================================================================

  Widget _buildPerformaTab(bool isDark) {
    final filteredOrders = _getFilteredOrders();

    return Column(
      children: [
        // 1. Header Tab Performa
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
            ),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentBottomNavIndex = 0);
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    size: 22,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Performa',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.search_rounded, size: 22),
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  GageToast.show(context, 'Pencarian riwayat pesanan affiliate');
                },
              ),
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 20),
                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  GageToast.show(context, 'Filter tanggal dan nominal komisi');
                },
              ),
            ],
          ),
        ),

        // 2. Kartu Saldo Komisi Siap Tarik
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Saldo Komisi Siap Tarik',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'Instan Rp 0 Admin',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _currencyFormat.format(_availableCommission),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: const StadiumBorder(),
                    elevation: 0,
                  ),
                  onPressed: _withdrawToGagePay,
                  icon: const Icon(Icons.account_balance_wallet_rounded, size: 14),
                  label: const Text(
                    'Tarik ke GAGEPay',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
        ),

        // 3. Segmented Filter Status Kapsul (Semua, Belum Dibayar, Diproses, Selesai)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: List.generate(_performaTabs.length, (idx) {
                final isSelected = _selectedPerformaFilterIndex == idx;
                return Expanded(
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedPerformaFilterIndex = idx);
                    },
                    borderRadius: BorderRadius.circular(999),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? GageTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: Text(
                          _performaTabs[idx],
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 4. Content Area: List Pesanan atau Empty State Bersih
        Expanded(
          child: filteredOrders.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  itemCount: filteredOrders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final order = filteredOrders[idx];
                    return _buildOrderCommissionCard(order, isDark);
                  },
                ),
        ),
      ],
    );
  }

  /// Empty State Dokumen Bersih (ShopeeFood ATM)
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 48,
                    color: isDark ? Colors.white30 : const Color(0xFF94A3B8),
                  ),
                  Positioned(
                    bottom: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.access_time_rounded,
                        size: 20,
                        color: isDark ? Colors.white54 : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesanan Affiliate',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Pesanan dari tautan produk atau kode referral yang Anda bagikan akan otomatis terlacak dan tampil di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF64748B),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _currentBottomNavIndex = 0);
              },
              icon: const Icon(Icons.share_rounded, size: 15),
              label: const Text(
                'Mulai Bagikan Menu',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCommissionCard(Map<String, dynamic> order, bool isDark) {
    final isDone = order['status'] == 'Selesai';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${order['orderId']} • ${order['date']}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: isDone ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  order['statusLabel'] as String,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: isDone ? const Color(0xFF16A34A) : const Color(0xFFD97706),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order['productName'] as String,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            order['merchantName'] as String,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: ${_currencyFormat.format(order['totalPrice'])}',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Komisi (${order['commissionRate']}): ',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Text(
                    '+${_currencyFormat.format(order['commissionAmount'])}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF16A34A),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
