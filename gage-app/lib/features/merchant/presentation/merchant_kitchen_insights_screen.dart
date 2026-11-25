import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';

/// Halaman Layar Penuh (Full Screen Page) untuk Wawasan & Analitik Toko Mitra Usaha GAGE
/// Mengambil data riil dari MerchantOrderProvider, GageApiClient.getMerchantMenu,
/// dan MerchantStorefrontService tanpa angka Dimsum hardcoded.
class MerchantKitchenInsightsScreen extends StatefulWidget {
  const MerchantKitchenInsightsScreen({super.key});

  @override
  State<MerchantKitchenInsightsScreen> createState() =>
      _MerchantKitchenInsightsScreenState();
}

class _MerchantKitchenInsightsScreenState
    extends State<MerchantKitchenInsightsScreen> {
  List<Map<String, dynamic>> _menus = const [];
  MerchantRatingSummary? _ratingSummary;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInsightsData();
  }

  MerchantOrderProvider? _maybeWatchProvider(BuildContext context) {
    try {
      return context.watch<MerchantOrderProvider>();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadInsightsData() async {
    final merchantId = MerchantStorefrontService.defaultPortalMerchantId;
    List<Map<String, dynamic>> menus = const [];
    MerchantRatingSummary? rating;

    try {
      menus = await GageApiClient.getMerchantMenu(merchantId);
      rating = await MerchantStorefrontService.loadRatingSummary(
        merchantId: merchantId,
        merchantName: 'Mitra GAGE',
        domain: 'food',
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() {
      _menus = menus;
      _ratingSummary = rating;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final provider = _maybeWatchProvider(context);
    final orders = provider?.orders ?? const <OrderModel>[];
    final cookingTime = provider?.cookingTime ?? 15;
    final acceptanceScore = provider?.acceptanceScore ?? 100.0;
    final accepted = provider?.dailyAcceptedCount ?? 0;
    final rejected = provider?.dailyRejectedCount ?? 0;

    final totalMenus = _menus.length;
    final availableCount =
        _menus.where((m) => m['is_available'] == 1 || m['is_available'] == true).length;
    final stockPct =
        totalMenus > 0 ? ((availableCount / totalMenus) * 100).round() : 100;

    final avgRating = _ratingSummary != null && _ratingSummary!.totalReviews > 0
        ? '${_ratingSummary!.averageRating.toStringAsFixed(1)} ★'
        : 'Baru';
    final reviewCount = _ratingSummary?.totalReviews ?? 0;

    // 1. Hitung distribusi jam sibuk riil dari order timestamps
    int morning = 0;
    int noon = 0;
    int afternoon = 0;
    int evening = 0;
    for (final ord in orders) {
      if (ord.createdAt <= 0) continue;
      final hour =
          DateTime.fromMillisecondsSinceEpoch(ord.createdAt * 1000).hour;
      if (hour >= 6 && hour < 11) {
        morning++;
      } else if (hour >= 11 && hour < 15) {
        noon++;
      } else if (hour >= 15 && hour < 18) {
        afternoon++;
      } else {
        evening++;
      }
    }
    final totalSlotOrders = morning + noon + afternoon + evening;
    final slotCounts = [morning, noon, afternoon, evening];
    final maxSlotCount =
        slotCounts.reduce((a, b) => a > b ? a : b);

    // 2. Agregasi produk terlaris riil dari pesanan + katalog
    final Map<String, _ProductAgg> productMap = {};
    for (final ord in orders) {
      if (ord.status == 'CANCELLED') continue;
      for (final item in ord.items) {
        final key = item.name.trim();
        if (key.isEmpty) continue;
        final existing = productMap[key];
        if (existing != null) {
          existing.soldCount += item.quantity;
          existing.revenue += item.subtotal;
        } else {
          productMap[key] = _ProductAgg(
            name: key,
            soldCount: item.quantity,
            revenue: item.subtotal,
          );
        }
      }
    }
    for (final m in _menus) {
      final name = (m['name'] ?? '').toString().trim();
      final sold = (m['sold_count'] as num?)?.toInt() ?? 0;
      final price =
          (m['gage_price'] as num?)?.toInt() ?? (m['price'] as num?)?.toInt() ?? 0;
      if (name.isEmpty) continue;
      if (!productMap.containsKey(name) && sold > 0) {
        productMap[name] = _ProductAgg(
          name: name,
          soldCount: sold,
          revenue: sold * price,
        );
      }
    }
    final topProducts = productMap.values.toList()
      ..sort((a, b) => b.soldCount.compareTo(a.soldCount));
    final displayedTop = topProducts.take(5).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wawasan & Analitik Toko',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: textColor),
            ),
            Text(
              'Performa Operasional & Katalog',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subColor),
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        color: GageTheme.primary,
        onRefresh: _loadInsightsData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // 1. KPI Cards Riil (2x2 Grid)
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Waktu Siap Default',
                    value: '$cookingTime mnt',
                    badge: cookingTime <= 15 ? 'Cepat' : 'Standar',
                    badgeColor: GageTheme.accentGreen,
                    icon: Icons.timer_outlined,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Penerimaan Order',
                    value: '${acceptanceScore.toStringAsFixed(0)}%',
                    badge: '$accepted terima • $rejected tolak',
                    badgeColor: const Color(0xFF0284C7),
                    icon: Icons.check_circle_outline_rounded,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildKpiCard(
                    title: 'Ketersediaan Stok',
                    value: _isLoading ? '...' : '$stockPct%',
                    badge: _isLoading ? 'Memuat' : '$availableCount/$totalMenus Aktif',
                    badgeColor: const Color(0xFF8B5CF6),
                    icon: Icons.inventory_2_outlined,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildKpiCard(
                    title: 'Kepuasan Pembeli',
                    value: _isLoading ? '...' : avgRating,
                    badge: '$reviewCount Ulasan',
                    badgeColor: const Color(0xFFF59E0B),
                    icon: Icons.thumb_up_alt_outlined,
                    cardBg: cardBg,
                    textColor: textColor,
                    subColor: subColor,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 2. Diagram Batang Jam Sibuk Riil
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_filled_rounded, size: 17, color: GageTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Jam Sibuk Pesanan Toko',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$totalSlotOrders Pesanan',
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: GageTheme.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTimeSlotRow('Pagi (06:00 - 11:00)', morning, totalSlotOrders, maxSlotCount, textColor, subColor, isDark),
                  const SizedBox(height: 10),
                  _buildTimeSlotRow('Siang (11:00 - 15:00)', noon, totalSlotOrders, maxSlotCount, textColor, subColor, isDark),
                  const SizedBox(height: 10),
                  _buildTimeSlotRow('Sore (15:00 - 18:00)', afternoon, totalSlotOrders, maxSlotCount, textColor, subColor, isDark),
                  const SizedBox(height: 10),
                  _buildTimeSlotRow('Malam (18:00 - 06:00)', evening, totalSlotOrders, maxSlotCount, textColor, subColor, isDark),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Produk Terlaris Toko (Berbasis Pesanan & Katalog Nyata)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produk Terlaris Toko',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: textColor,
                  ),
                ),
                Text(
                  'Dari Riwayat Order',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: subColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (displayedTop.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bar_chart_rounded, size: 34, color: subColor),
                    const SizedBox(height: 8),
                    Text(
                      'Belum Ada Data Penjualan Produk',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Peringkat produk terlaris akan terisi otomatis seiring pesanan masuk dan selesai.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11.5, color: subColor),
                    ),
                  ],
                ),
              )
            else
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
                child: Column(
                  children: List.generate(displayedTop.length, (i) {
                    final item = displayedTop[i];
                    return Column(
                      children: [
                        _buildTopProductRow(
                          rank: i + 1,
                          name: item.name,
                          soldCount: item.soldCount,
                          revenue: item.revenue,
                          currencyFormatter: currencyFormatter,
                          textColor: textColor,
                          subColor: subColor,
                          isDark: isDark,
                        ),
                        if (i < displayedTop.length - 1)
                          Divider(
                            height: 1,
                            indent: 52,
                            endIndent: 16,
                            color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          ),
                      ],
                    );
                  }),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required Color cardBg,
    required Color textColor,
    required Color subColor,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.035),
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
              Icon(icon, size: 18, color: badgeColor),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: badgeColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: subColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeSlotRow(
    String label,
    int count,
    int total,
    int maxCount,
    Color textColor,
    Color subColor,
    bool isDark,
  ) {
    final pct = total > 0 ? (count / total) : 0.0;
    final pctText = total > 0 ? '${(pct * 100).round()}% ($count)' : '0%';
    final isPeak = maxCount > 0 && count == maxCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isPeak ? FontWeight.w800 : FontWeight.w600,
                color: textColor,
              ),
            ),
            Text(
              isPeak ? '$pctText • Puncak' : pctText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isPeak ? GageTheme.primary : subColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFF1F5F9),
            valueColor: AlwaysStoppedAnimation<Color>(
              isPeak ? GageTheme.primary : const Color(0xFF0284C7),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopProductRow({
    required int rank,
    required String name,
    required int soldCount,
    required int revenue,
    required NumberFormat currencyFormatter,
    required Color textColor,
    required Color subColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: rank == 1
                  ? const Color(0xFFFEF3C7)
                  : (rank == 2
                      ? const Color(0xFFF1F5F9)
                      : (rank == 3 ? const Color(0xFFFFEDD5) : Colors.transparent)),
              shape: BoxShape.circle,
              border: Border.all(
                color: rank <= 3 ? Colors.grey.shade300 : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: rank == 1
                      ? const Color(0xFFD97706)
                      : (rank == 2
                          ? const Color(0xFF475569)
                          : (rank == 3 ? const Color(0xFFEA580C) : subColor)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Terjual $soldCount unit',
                  style: TextStyle(fontSize: 11, color: subColor),
                ),
              ],
            ),
          ),
          Text(
            currencyFormatter.format(revenue),
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: GageTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductAgg {
  final String name;
  int soldCount;
  int revenue;

  _ProductAgg({
    required this.name,
    required this.soldCount,
    required this.revenue,
  });
}
