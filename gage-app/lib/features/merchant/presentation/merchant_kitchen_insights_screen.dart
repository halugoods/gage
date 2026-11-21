import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Halaman Layar Penuh (Full Screen Page) untuk Wawasan & Analitik Dapur Mitra Usaha GAGE
/// Dilengkapi metrik kecepatan penyajian, visual diagram jam sibuk,
/// serta daftar 5 menu terlaris dan rekomendasi stok bahan baku.
class MerchantKitchenInsightsScreen extends StatelessWidget {
  const MerchantKitchenInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wawasan & Analitik Dapur',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            Text(
              'Performa Operasional Toko',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : GageTheme.textPrimary,
        elevation: 0.5,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // 1. KPI Cards (2x2 Grid)
          Row(
            children: [
              Expanded(
                child: _buildKpiCard(
                  title: 'Waktu Masak',
                  value: '8.5 mnt',
                  badge: 'Sangat Cepat',
                  badgeColor: const Color(0xFF16A34A),
                  icon: Icons.timer_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Penyelesaian',
                  value: '100%',
                  badge: '0 Batal',
                  badgeColor: const Color(0xFF0284C7),
                  icon: Icons.check_circle_outline_rounded,
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
                  title: 'Akurasi Stok',
                  value: '98.5%',
                  badge: 'Sangat Baik',
                  badgeColor: const Color(0xFF8B5CF6),
                  icon: Icons.inventory_2_outlined,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildKpiCard(
                  title: 'Kepuasan Pembeli',
                  value: '4.9 ★',
                  badge: '98 Ulasan',
                  badgeColor: const Color(0xFFF59E0B),
                  icon: Icons.thumb_up_alt_outlined,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. Diagram Batang Jam Sibuk Dapur
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time_filled_rounded, size: 16, color: GageTheme.primary),
                        SizedBox(width: 8),
                        Text(
                          'Jam Sibuk Dapur & Pesanan',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
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
                      child: const Text(
                        'Puncak Siang & Malam',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: GageTheme.primary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visual Bars
                _buildTimeSlotBar('Pagi (08:00 - 11:00)', 0.10, '10%', isDark),
                const SizedBox(height: 10),
                _buildTimeSlotBar('Siang (11:00 - 14:00)', 0.45, '45% 🔥 Puncak', isDark, isPeak: true),
                const SizedBox(height: 10),
                _buildTimeSlotBar('Sore (14:00 - 18:00)', 0.20, '20%', isDark),
                const SizedBox(height: 10),
                _buildTimeSlotBar('Malam (18:00 - 21:00)', 0.25, '25% 🔥 Puncak', isDark, isPeak: true),

                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.tips_and_updates_rounded, size: 18, color: Color(0xFFD97706)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tip Dapur: Kukus stok siomay 10 menit sebelum jam 11:30 WIB agar kurir dapat langsung menerima paket tanpa antre.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white70 : const Color(0xFF92400E),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 3. Top 5 Menu Terlaris Pekan Ini
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5 Menu Terlaris (Paling Laku)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(
                '7 Hari Terakhir',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildTopMenuItem(
            rank: 1,
            name: 'Dimsum Siomay Ayam Jamur',
            soldCount: 142,
            revenue: 2272000,
            currencyFormatter: currencyFormatter,
            isDark: isDark,
          ),
          _buildTopMenuItem(
            rank: 2,
            name: 'Dimsum Mozzarella Keju Lumer',
            soldCount: 118,
            revenue: 2124000,
            currencyFormatter: currencyFormatter,
            isDark: isDark,
          ),
          _buildTopMenuItem(
            rank: 3,
            name: 'Dimsum Hakau Udang Segar',
            soldCount: 94,
            revenue: 1692000,
            currencyFormatter: currencyFormatter,
            isDark: isDark,
          ),
          _buildTopMenuItem(
            rank: 4,
            name: 'Dimsum Kulit Tahu Crispy',
            soldCount: 86,
            revenue: 1290000,
            currencyFormatter: currencyFormatter,
            isDark: isDark,
          ),
          _buildTopMenuItem(
            rank: 5,
            name: 'Es Teh Manis Jumbo Segar',
            soldCount: 160,
            revenue: 640000,
            currencyFormatter: currencyFormatter,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  static Widget _buildKpiCard({
    required String title,
    required String value,
    required String badge,
    required Color badgeColor,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, size: 18, color: badgeColor),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge,
                  style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor),
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
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildTimeSlotBar(String label, double pct, String pctText, bool isDark, {bool isPeak = false}) {
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
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            Text(
              pctText,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isPeak ? GageTheme.primary : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: pct,
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

  static Widget _buildTopMenuItem({
    required int rank,
    required String name,
    required int soldCount,
    required int revenue,
    required NumberFormat currencyFormatter,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          // Medali Rank
          Container(
            width: 26,
            height: 26,
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
                          : (rank == 3 ? const Color(0xFFEA580C) : Colors.grey.shade500)),
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
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Terjual $soldCount porsi',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white60 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),

          Text(
            currencyFormatter.format(revenue),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: GageTheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
