import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/services/affiliate_commission_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/data/mock/gage_mock_registry.dart';
import 'package:gage_app/features/affiliate/presentation/affiliate_merchant_detail_screen.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// AffiliateHubScreen - GAGE Cuan: Ekosistem Afiliasi & Penawaran Kuliner & UMKM Lokal
///
/// Fitur Lengkap & Arsitektur Clean GAGE:
/// - 2 Tab Utama Kapsul: Penawaran & Performa (BorderRadius.circular(999))
/// - Banner Kode Referral 6 Karakter Acak + Share WhatsApp
/// - Banner CTA Unggah Video & Keranjang Kuning (Buka AffiliateVideoUploadScreen)
/// - Segmented Switch 4 Layanan Komersial GAGE (Food, Shop, Farm, Build) Kapsul Penuh
/// - Tab Filter Cepat (Rekomendasi, Komisi Tertinggi, Terlaris)
/// - Katalog Merchant Asli Pracimantoro dengan komisi dinamis toko (maksimal 20%)
/// - Navigasi ke Detail Merchant Afiliasi (AffiliateMerchantDetailScreen)
/// - Tab Performa: Saldo komisi siap tarik instan ke GAGEPay & riwayat transaksi
class AffiliateHubScreen extends StatefulWidget {
  const AffiliateHubScreen({super.key});

  @override
  State<AffiliateHubScreen> createState() => _AffiliateHubScreenState();
}

class _AffiliateHubScreenState extends State<AffiliateHubScreen> {
  int _selectedMainTabIndex = 0; // 0: Penawaran, 1: Performa
  int _selectedServiceIndex = 0; // 0: Food, 1: Shop, 2: Farm, 3: Build
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

  final List<Map<String, dynamic>> _commerceServices = [
    {
      'name': 'Food',
      'icon': Icons.restaurant_rounded,
      'label': 'Food',
      'subtitle': 'Kuliner & Resto',
    },
    {
      'name': 'Shop',
      'icon': Icons.shopping_bag_rounded,
      'label': 'Shop',
      'subtitle': 'Sembako & Belanja',
    },
    {
      'name': 'Farm',
      'icon': Icons.agriculture_rounded,
      'label': 'Farm',
      'subtitle': 'Pertanian & Ternak',
    },
    {
      'name': 'Build',
      'icon': Icons.construction_rounded,
      'label': 'Build',
      'subtitle': 'Bahan Bangunan',
    },
  ];

  final List<String> _filterTabs = ['Rekomendasi', 'Komisi Tertinggi', 'Terlaris'];
  final List<String> _performaTabs = ['Semua', 'Belum Dibayar', 'Diproses', 'Selesai'];

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

    HapticFeedback.heavyImpact();
    GageToast.show(
      context,
      'Penarikan ${_currencyFormat.format(amount)} langsung masuk ke Saldo GAGEPay Anda!',
      type: GageToastType.success,
    );
  }

  /// Ambil daftar merchant sesuai layanan komersial yang dipilih (Food, Shop, Farm, Build)
  List<Map<String, dynamic>> _getMerchantsForActiveService() {
    switch (_selectedServiceIndex) {
      case 0:
        return GageMockRegistry.foodMerchants;
      case 1:
        return GageMockRegistry.shopMerchants;
      case 2:
        return GageMockRegistry.farmMerchants;
      case 3:
        return GageMockRegistry.buildMerchants;
      default:
        return GageMockRegistry.foodMerchants;
    }
  }

  List<Map<String, dynamic>> _getFilteredMerchants() {
    var list = List<Map<String, dynamic>>.from(_getMerchantsForActiveService());

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((m) {
        final name = (m['name'] as String? ?? '').toLowerCase();
        final cat = (m['category'] as String? ?? '').toLowerCase();
        final menus = (m['menus'] as List<dynamic>?) ?? [];
        final hasMenuMatch = menus.any((menu) {
          final mName = (menu['name'] as String? ?? '').toLowerCase();
          return mName.contains(q);
        });
        return name.contains(q) || cat.contains(q) || hasMenuMatch;
      }).toList();
    }

    if (_selectedFilterIndex == 1) {
      // Komisi Tertinggi
      list.sort((a, b) {
        final rateA = (a['commissionRate'] as num?)?.toInt() ?? 10;
        final rateB = (b['commissionRate'] as num?)?.toInt() ?? 10;
        return rateB.compareTo(rateA);
      });
    } else if (_selectedFilterIndex == 2) {
      // Terlaris (berdasarkan ratingCount / reviewsCount)
      list.sort((a, b) {
        final countA = int.tryParse('${a['ratingCount']}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        final countB = int.tryParse('${b['ratingCount']}'.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
        return countB.compareTo(countA);
      });
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
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildSegmentedTabSwitcher(isDark),
            Expanded(
              child: IndexedStack(
                index: _selectedMainTabIndex,
                children: [
                  _buildPenawaranTab(isDark),
                  _buildPerformaTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Header Bersih GAGE Cuan
  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Row(
        children: [
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.maybePop(context);
            },
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
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
                    Text(
                      'GAGE Cuan',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Afiliasi Mitra',
                        style: TextStyle(
                          color: GageTheme.primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Kemitraan & Referral Food, Shop, Farm, Build Pracimantoro',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Segmented Tab Switcher Kapsul Penuh (Penawaran vs Performa)
  Widget _buildSegmentedTabSwitcher(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildSegmentPill(
                0,
                'Penawaran',
                Icons.local_offer_rounded,
                isDark,
              ),
            ),
            Expanded(
              child: _buildSegmentPill(
                1,
                'Performa',
                Icons.insights_rounded,
                isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentPill(int index, String label, IconData icon, bool isDark) {
    final isSelected = _selectedMainTabIndex == index;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: isSelected ? GageTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: GageTheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _selectedMainTabIndex = index;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                ),
              ),
            ],
          ),
        ),
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
        // 1. Search Field Real-time
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(999),
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
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                decoration: InputDecoration(
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    size: 20,
                    color: GageTheme.primary,
                  ),
                  hintText: 'Cari produk atau resto/toko mitra...',
                  hintStyle: TextStyle(
                    fontSize: 12.5,
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
          ),
        ),

        // 2. Banner Ajak Teman Cuan (Referral 6 Karakter Acak)
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

        // 3. Segmented Switch 4 Layanan Komersial GAGE (Food, Shop, Farm, Build) - Capsule Penuh (Teks Murni)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Pilih Layanan Bisnis GAGE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Komisi hingga 20%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GageTheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: List.generate(_commerceServices.length, (idx) {
                      final s = _commerceServices[idx];
                      final isSelected = _selectedServiceIndex == idx;

                      return Expanded(
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedServiceIndex = idx;
                            });
                          },
                          borderRadius: BorderRadius.circular(999),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? GageTheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: GageTheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Center(
                              child: Text(
                                s['label'] as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
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
              ],
            ),
          ),
        ),

        // 5. Filter Sorting Kapsul (Rekomendasi, Komisi Tertinggi, Terlaris)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
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
                        padding: const EdgeInsets.symmetric(vertical: 7),
                        decoration: BoxDecoration(
                          color: isSelected ? GageTheme.primary : Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Center(
                          child: Text(
                            _filterTabs[idx],
                            style: TextStyle(
                              fontSize: 11.5,
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

        // 6. Resto & Mitra List (Full Dynamic Connection to AffiliateMerchantDetailScreen)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
          sliver: filteredMerchants.isEmpty
              ? SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    alignment: Alignment.center,
                    child: Column(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          size: 48,
                          color: isDark ? Colors.white24 : const Color(0xFF94A3B8),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Tidak ada mitra ditemukan',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
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

  /// Kartu Merchant Afiliasi Bersih (Tanpa Tombol Share Terbalik yang Membingungkan)
  Widget _buildMerchantCard(Map<String, dynamic> merchant, bool isDark) {
    final rawRate = merchant['commissionRate'] ?? 10;
    final int commissionRate = (rawRate is num ? rawRate.toInt() : int.tryParse('$rawRate') ?? 10).clamp(0, 20);
    final promoBadges = (merchant['promoBadges'] as List<dynamic>?)?.map((e) => '$e').toList() ?? [];

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
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AffiliateMerchantDetailScreen(
                    merchant: merchant,
                    referralCode: _referralCode,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    merchant['image'] as String? ?? 'assets/images/resto_rocket_chicken.png',
                    width: 74,
                    height: 74,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 74,
                      height: 74,
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      child: const Icon(Icons.storefront, color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        merchant['name'] as String? ?? 'Mitra GAGE',
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
                        merchant['category'] as String? ?? 'UMKM Pracimantoro',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white54 : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            '${merchant['rating'] ?? 4.9} (${merchant['ratingCount'] ?? '100+'})',
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
                              'Pracimantoro, Kab. Wonogiri',
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Komisi: ',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$commissionRate%',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF166534),
                      ),
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AffiliateMerchantDetailScreen(
                        merchant: merchant,
                        referralCode: _referralCode,
                      ),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Lihat Menu & Komisi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: GageTheme.primary,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 11, color: GageTheme.primary),
                    ],
                  ),
                ),
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
        // 1. Kartu Saldo Komisi Siap Tarik
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
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

        // 2. Segmented Filter Status Kapsul (Semua, Belum Dibayar, Diproses, Selesai)
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

        // 3. Content Area: List Pesanan atau Empty State Bersih
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

  /// Empty State Dokumen Bersih
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
                setState(() => _selectedMainTabIndex = 0);
              },
              icon: const Icon(Icons.share_rounded, size: 15),
              label: const Text(
                'Mulai Bagikan Produk',
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
