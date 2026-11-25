import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/merchant_kitchen_insights_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_review_screen.dart';
import 'package:gage_app/features/merchant/presentation/settings/merchant_operating_schedule_screen.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 2: Etalase & Performa Outlet Mitra Usaha GAGE (Food, Shop, Farm)
/// Dirancang ulang dari nol berbasis data riil:
/// - Hero Card Pendapatan Bersih, Order Selesai/Berjalan & Performa Penerimaan
/// - Kartu Etalase Live di Aplikasi Customer (Status, Jadwal, Kesehatan Katalog & Quick-Restock)
/// - Menu Kerja Harian Seamless Grouped Cards (Produk & Stok, Wawasan, Ulasan, Promo)
class GageMerchantOutletTab extends StatefulWidget {
  final NumberFormat currencyFormatter;
  final ValueChanged<int>? onNavigateTab;

  const GageMerchantOutletTab({
    super.key,
    required this.currencyFormatter,
    this.onNavigateTab,
  });

  @override
  State<GageMerchantOutletTab> createState() => _GageMerchantOutletTabState();
}

class _GageMerchantOutletTabState extends State<GageMerchantOutletTab> {
  MerchantStorefrontData? _storefront;
  MerchantRatingSummary? _ratingSummary;
  List<Map<String, dynamic>> _menus = const [];
  bool _isLoadingCatalog = true;
  String? _loadedForBranchId;

  @override
  void initState() {
    super.initState();
    _loadOutletData();
  }

  MerchantOrderProvider? _maybeWatchProvider(BuildContext context) {
    try {
      return context.watch<MerchantOrderProvider>();
    } catch (_) {
      return null;
    }
  }

  String _resolveServiceLabel(MerchantOrderProvider? provider) {
    final branchId = (provider?.activeBranchId ?? '').toLowerCase();
    if (branchId.contains('sh') || branchId.contains('shop') || branchId.contains('toko')) {
      return 'GAGE Shop';
    }
    if (branchId.contains('fm') || branchId.contains('farm') || branchId.contains('tani')) {
      return 'GAGE Farm';
    }
    final firstChannel = provider?.orders.isNotEmpty == true
        ? provider!.orders.first.channel.toLowerCase()
        : 'food';
    if (firstChannel == 'shop') return 'GAGE Shop';
    if (firstChannel == 'farm') return 'GAGE Farm';
    return 'GAGE Food';
  }

  Future<void> _loadOutletData() async {
    final merchantId = MerchantStorefrontService.defaultPortalMerchantId;
    MerchantStorefrontData? loadedStore;
    MerchantRatingSummary? loadedRating;
    List<Map<String, dynamic>> loadedMenus = const [];

    String domain = 'food';
    final bId = (_loadedForBranchId ?? merchantId).toLowerCase();
    if (bId.contains('sh') || bId.contains('shop') || bId.contains('toko')) {
      domain = 'shop';
    } else if (bId.contains('fm') || bId.contains('farm') || bId.contains('tani')) {
      domain = 'farm';
    }

    try {
      loadedStore = await MerchantStorefrontService.loadStorefront(merchantId);
      loadedRating = await MerchantStorefrontService.loadRatingSummary(
        merchantId: merchantId,
        merchantName: loadedStore?.name ?? 'Mitra GAGE',
        domain: domain,
      );
      loadedMenus = await GageApiClient.getMerchantMenu(merchantId);
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _storefront = loadedStore;
      _ratingSummary = loadedRating;
      _menus = loadedMenus;
      _isLoadingCatalog = false;
    });
  }

  Future<void> _quickRestoreStock(Map<String, dynamic> item) async {
    final id = (item['id'] ?? '').toString();
    final name = (item['name'] ?? 'Produk').toString();
    if (id.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _menus = _menus.map((m) {
        if ((m['id'] ?? '').toString() == id) {
          return {...m, 'is_available': 1};
        }
        return m;
      }).toList();
    });

    await GageApiClient.toggleMerchantStock(id, true);
    if (mounted) {
      GageToast.show(context, '$name diaktifkan kembali di etalase Customer', type: GageToastType.success);
    }
  }

  void _showRevenueAndScoreSheet(BuildContext context, MerchantOrderProvider? provider, bool isDark) {
    HapticFeedback.lightImpact();
    final gross = provider?.todayGrossRevenue ?? 0;
    final platformFee = provider?.todayPlatformFee ?? 0;
    final net = provider?.todayNetRevenue ?? 0;
    final escrow = provider?.escrowBalance ?? 0;
    final acceptance = provider?.acceptanceScore ?? 100.0;
    final accepted = provider?.dailyAcceptedCount ?? 0;
    final rejected = provider?.dailyRejectedCount ?? 0;
    final cooking = provider?.cookingTime ?? 15;

    final cardBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    GageFloatingSheet.show(
      context: context,
      title: 'Rincian Pendapatan & Performa',
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Rincian Keuangan Nyata Hari Ini
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PENDAPATAN HARI INI',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                    color: subColor,
                  ),
                ),
                const SizedBox(height: 10),
                _buildMoneyRow(
                  'Omset Penjualan Kotor',
                  widget.currencyFormatter.format(gross),
                  textColor: textColor,
                  subColor: subColor,
                ),
                const SizedBox(height: 6),
                _buildMoneyRow(
                  'Biaya Platform GAGE (10%)',
                  '- ${widget.currencyFormatter.format(platformFee)}',
                  textColor: GageTheme.primary,
                  subColor: subColor,
                ),
                Divider(height: 18, color: borderColor),
                _buildMoneyRow(
                  'Pendapatan Bersih Selesai',
                  widget.currencyFormatter.format(net),
                  textColor: GageTheme.accentGreen,
                  subColor: textColor,
                  isBold: true,
                ),
                if (escrow > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Estimasi Order Sedang Berjalan',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D4ED8)),
                        ),
                        Text(
                          widget.currencyFormatter.format(escrow),
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF1D4ED8)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Performa Penerimaan & Dapur Riil
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Tingkat Penerimaan Order',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    Text(
                      '${acceptance.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: GageTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (acceptance / 100.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(GageTheme.accentGreen),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '$accepted diterima • $rejected ditolak • Estimasi penyiapan default $cooking mnt',
                  style: TextStyle(fontSize: 11.5, color: subColor),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            height: 48,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                widget.onNavigateTab?.call(4);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              icon: const Icon(Icons.account_balance_wallet_rounded, size: 18),
              label: const Text(
                'Kelola Saldo di GagePay',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoneyRow(
    String label,
    String value, {
    required Color textColor,
    required Color subColor,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w500,
            color: subColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13.5 : 12,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final dividerColor = isDark ? Colors.white10 : const Color(0xFFF1F5F9);

    final provider = _maybeWatchProvider(context);
    final branchId = provider?.activeBranchId ?? MerchantStorefrontService.defaultPortalMerchantId;
    if (_loadedForBranchId != null && _loadedForBranchId != branchId) {
      _loadedForBranchId = branchId;
      WidgetsBinding.instance.addPostFrameCallback((_) => _loadOutletData());
    } else {
      _loadedForBranchId ??= branchId;
    }

    final completedCount = provider?.completedOrders.length ?? 0;
    final activeCount = provider?.activeOrderCount ?? 0;
    final todayNet = provider?.todayNetRevenue ?? 0;
    final acceptanceScore = provider?.acceptanceScore ?? 100.0;
    final cookingTime = provider?.cookingTime ?? 15;
    final dailyAccepted = provider?.dailyAcceptedCount ?? 0;

    final isOpen = provider?.isOpen ?? (_storefront?.isOpen ?? true);
    final isBusy = provider?.isBusy ?? false;
    final busyRemaining = provider?.busyRemainingMinutes ?? 0;
    final serviceLabel = _resolveServiceLabel(provider);

    final schedule = _storefront?.schedule ?? MerchantOperatingSchedule.defaults();
    final scheduleSummary = schedule.infoSummary();

    // Real catalog health metrics
    final totalMenus = _menus.length;
    final availableMenus = _menus.where((m) => m['is_available'] == 1 || m['is_available'] == true).toList();
    final outOfStockMenus = _menus.where((m) => m['is_available'] != 1 && m['is_available'] != true).toList();

    final itemPromos = _storefront?.itemPromoPrices ?? const <String, int>{};
    int promoMenuCount = 0;
    for (final item in _menus) {
      final id = (item['id'] ?? '').toString();
      final gagePrice = (item['gage_price'] as num?)?.toInt() ?? (item['price'] as num?)?.toInt() ?? 0;
      final savedPromo = itemPromos[id] ?? (item['promo_price'] as num?)?.toInt() ?? 0;
      if (savedPromo > 0 && savedPromo < gagePrice) {
        promoMenuCount++;
      }
    }
    final hasDirectDiscount = _storefront?.directDiscountActive == true && (_storefront?.directDiscountAmount ?? 0) > 0;
    final totalActivePromos = promoMenuCount + (hasDirectDiscount ? 1 : 0);

    final avgRating = _ratingSummary != null && _ratingSummary!.totalReviews > 0
        ? '${_ratingSummary!.averageRating.toStringAsFixed(1)} ★'
        : 'Baru';
    final reviewCount = _ratingSummary?.totalReviews ?? 0;

    return RefreshIndicator(
      color: GageTheme.primary,
      onRefresh: () async {
        await provider?.fetchOrders(silent: true);
        await _loadOutletData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 108),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Card Omset & Performa Hari Ini (Real Data, Zero Fallback Palsu)
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE52320), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: GageTheme.primary.withValues(alpha: 0.30),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          serviceLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.20),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isBusy
                                    ? const Color(0xFFFBBF24)
                                    : (isOpen ? const Color(0xFF4ADE80) : const Color(0xFFFCA5A5)),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isBusy
                                  ? 'ISTIRAHAT ${busyRemaining}M'
                                  : (isOpen ? 'ETALASE BUKA' : 'ETALASE TUTUP'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pendapatan Bersih Hari Ini',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.88),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.currencyFormatter.format(todayNet),
                              style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Order Selesai',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Colors.white.withValues(alpha: 0.88),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '$completedCount',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              if (activeCount > 0) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    '+$activeCount aktif',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  InkWell(
                    onTap: () => _showRevenueAndScoreSheet(context, provider, isDark),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.trending_up_rounded, size: 17, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Performa Terima Order',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                '${acceptanceScore.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.white70),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 2. Etalase Pelanggan Live & Kesehatan Katalog
            _buildSectionHeader('ETALASE DI APLIKASI CUSTOMER', subColor),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Status & Jadwal Sinkronisasi Customer Portal
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (isBusy
                                  ? GageTheme.accentOrange
                                  : (isOpen ? GageTheme.accentGreen : GageTheme.primary))
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.schedule_rounded,
                          size: 20,
                          color: isBusy
                              ? GageTheme.accentOrange
                              : (isOpen ? GageTheme.accentGreen : GageTheme.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isBusy
                                  ? 'Mode Sibuk ($busyRemaining mnt tersisa)'
                                  : (isOpen
                                      ? 'Toko Buka & Aktif'
                                      : 'Toko Sedang Tutup'),
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: textColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              scheduleSummary,
                              style: TextStyle(fontSize: 11.5, color: subColor),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.5)),
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          HapticFeedback.lightImpact();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MerchantOperatingScheduleScreen(
                                merchantId: MerchantStorefrontService.defaultPortalMerchantId,
                                initialSchedule: schedule,
                              ),
                            ),
                          );
                          await _loadOutletData();
                        },
                        child: const Text(
                          'Atur Jadwal',
                          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: GageTheme.primary),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),
                  Divider(height: 1, color: dividerColor),
                  const SizedBox(height: 14),

                  // 3 Ringkasan Kesehatan Katalog Live (Expanded anti-overflow)
                  Row(
                    children: [
                      Expanded(
                        child: _buildCatalogStatWell(
                          label: 'Tersedia',
                          value: _isLoadingCatalog ? '...' : '${availableMenus.length}',
                          accent: GageTheme.accentGreen,
                          isDark: isDark,
                          subColor: subColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCatalogStatWell(
                          label: 'Stok Habis',
                          value: _isLoadingCatalog ? '...' : '${outOfStockMenus.length}',
                          accent: outOfStockMenus.isNotEmpty ? GageTheme.primary : subColor,
                          isDark: isDark,
                          subColor: subColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildCatalogStatWell(
                          label: 'Promo Aktif',
                          value: _isLoadingCatalog ? '...' : '$totalActivePromos',
                          accent: totalActivePromos > 0 ? const Color(0xFF0284C7) : subColor,
                          isDark: isDark,
                          subColor: subColor,
                        ),
                      ),
                    ],
                  ),

                  // Quick-Restock Alert (Hanya muncul saat ada produk stok habis)
                  if (outOfStockMenus.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: GageTheme.primary.withValues(alpha: isDark ? 0.14 : 0.06),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, size: 15, color: GageTheme.primary),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${outOfStockMenus.length} Produk Ditandai Habis di Customer',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w800,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ...outOfStockMenus.take(3).map((item) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (item['name'] ?? 'Produk').toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () => _quickRestoreStock(item),
                                    borderRadius: BorderRadius.circular(999),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: GageTheme.primary,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Aktifkan',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Menu Kerja Harian Outlet (Seamless Inset Grouped Cards)
            _buildSectionHeader('KELOLA OUTLET & PERFORMA', subColor),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  type: MaterialType.transparency,
                  child: Column(
                    children: [
                      _buildGroupedActionTile(
                        icon: Icons.inventory_2_rounded,
                        iconColor: const Color(0xFFEA580C),
                        title: 'Kelola Produk & Stok',
                        subtitle: _isLoadingCatalog
                            ? 'Atur menu, harga promo & urutan kategori'
                            : '$totalMenus produk • ${availableMenus.length} siap dipesan pelanggan',
                        badge: outOfStockMenus.isNotEmpty ? '${outOfStockMenus.length} HABIS' : null,
                        badgeColor: GageTheme.primary,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () async {
                          HapticFeedback.lightImpact();
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantMenuScreen()),
                          );
                          await _loadOutletData();
                        },
                      ),
                      Divider(height: 1, indent: 58, endIndent: 16, color: dividerColor),
                      _buildGroupedActionTile(
                        icon: Icons.insights_rounded,
                        iconColor: GageTheme.accentGreen,
                        title: 'Wawasan & Analitik Toko',
                        subtitle: 'Estimasi siap $cookingTime mnt • $dailyAccepted order diterima',
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantKitchenInsightsScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 58, endIndent: 16, color: dividerColor),
                      _buildGroupedActionTile(
                        icon: Icons.star_rounded,
                        iconColor: const Color(0xFFF59E0B),
                        title: 'Penilaian & Ulasan Pembeli',
                        subtitle: '$avgRating • $reviewCount ulasan dari aplikasi Customer',
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const MerchantReviewScreen()),
                          );
                        },
                      ),
                      Divider(height: 1, indent: 58, endIndent: 16, color: dividerColor),
                      _buildGroupedActionTile(
                        icon: Icons.local_offer_rounded,
                        iconColor: GageTheme.primary,
                        title: 'Promo & Voucher Toko',
                        subtitle: hasDirectDiscount
                            ? 'Voucher toko ${widget.currencyFormatter.format(_storefront!.directDiscountAmount!)} aktif'
                            : 'Atur harga coret, flash sale & afiliasi',
                        badge: totalActivePromos > 0 ? '$totalActivePromos AKTIF' : null,
                        badgeColor: GageTheme.accentGreen,
                        textColor: textColor,
                        subColor: subColor,
                        isDark: isDark,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          widget.onNavigateTab?.call(3);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color subColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
          color: subColor,
        ),
      ),
    );
  }

  Widget _buildCatalogStatWell({
    required String label,
    required String value,
    required Color accent,
    required bool isDark,
    required Color subColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: subColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? badge,
    Color? badgeColor,
    required Color textColor,
    required Color subColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: badgeColor ?? GageTheme.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.5, color: subColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: isDark ? Colors.white30 : Colors.black26),
          ],
        ),
      ),
    );
  }
}
