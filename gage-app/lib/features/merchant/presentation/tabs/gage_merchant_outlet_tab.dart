import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/merchant_storefront_service.dart';
import 'package:gage_app/features/merchant/presentation/merchant_menu_screen.dart';
import 'package:gage_app/features/merchant/presentation/merchant_profile_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/operating_schedule_editor_sheet.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 2: Outlet & Manajemen Toko Mitra Usaha GAGE
/// Mengadopsi arsitektur hero card omset & skor resto, 8 grid fitur operasional,
/// banner Star Resto, serta panduan legalitas NIB untuk UMKM Pracimantoro.
class GageMerchantOutletTab extends StatelessWidget {
  final NumberFormat currencyFormatter;
  final ValueChanged<int>? onNavigateTab;

  const GageMerchantOutletTab({
    super.key,
    required this.currencyFormatter,
    this.onNavigateTab,
  });

  void _showScoreDetailSheet(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Rincian Skor Outlet',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '98 / 100 • Sangat Baik',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF166534),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildScoreMetricRow('Kecepatan Menyiapkan Pesanan', '10.5 menit (Sangat Cepat)', 38, 40, isDark),
            const SizedBox(height: 12),
            _buildScoreMetricRow('Ketersediaan Stok Menu', '100% Menu Aktif', 30, 30, isDark),
            const SizedBox(height: 12),
            _buildScoreMetricRow('Tingkat Penyelesaian Pesanan', '0% Pembatalan Toko', 30, 30, isDark),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Mengerti', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  static Widget _buildScoreMetricRow(String title, String subtitle, int current, int max, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            Text('$current/$max poin', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: current / max,
            minHeight: 5,
            backgroundColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
          ),
        ),
      ],
    );
  }

  void _showBranchSwitcherDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Cabang Outlet',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEE2E2),
                child: Icon(Icons.storefront_rounded, color: GageTheme.primary),
              ),
              title: const Text('Dimsum Sewu, Alfamidi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
              subtitle: const Text('Jl. Raya Pracimantoro No. 12', style: TextStyle(fontSize: 11.5)),
              trailing: const Icon(Icons.check_circle_rounded, color: GageTheme.primary),
              onTap: () {
                Navigator.pop(ctx);
                GageToast.show(context, 'Outlet aktif: Dimsum Sewu, Alfamidi');
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  void _showSimpleInfoSheet(BuildContext context, String title, String content, bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: title,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();

    // Hitung omset hari ini dari pesanan berstatus COMPLETED
    final completedOrders = provider.orders.where((o) => o.status == 'COMPLETED').toList();
    final todayGross = completedOrders.fold<int>(0, (sum, o) => sum + o.merchantNetPayout);
    final todayCount = completedOrders.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header Outlet Switcher (Cabang Aktif)
          InkWell(
            onTap: () => _showBranchSwitcherDialog(context, isDark),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Dimsum Sewu, Alfamidi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: 20,
                    color: isDark ? Colors.white70 : Colors.grey.shade700,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 2. Hero Card Omset & Skor Outlet (Gradient Red GAGE)
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
                  color: GageTheme.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tag Layanan GAGE Food
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'GAGE Food',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Metrik Penjualan & Transaksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Penjualan (Rp)',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormatter.format(todayGross > 0 ? todayGross : 87360),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Total Transaksi',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${todayCount > 0 ? todayCount : 1}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Strip Skor Outlet
                InkWell(
                  onTap: () => _showScoreDetailSheet(context, isDark),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.restaurant_rounded, size: 16, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Skor Outlet',
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
                              '😊 98/100',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: Colors.white.withValues(alpha: 0.95),
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

          const SizedBox(height: 18),

          // 3. Status Operasional Toko
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Toko Buka Menerima Pesanan',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Jadwal: 09:00 - 21:00 WIB',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    side: BorderSide(color: GageTheme.primary.withValues(alpha: 0.5)),
                  ),
                  onPressed: () async {
                    final newSched = await showOperatingScheduleEditorSheet(
                      context: context,
                      initialSchedule: MerchantOperatingSchedule.defaults(open: '09:00', close: '21:00'),
                    );
                    if (newSched != null && context.mounted) {
                      GageToast.show(context, 'Jadwal operasional toko diperbarui');
                    }
                  },
                  child: const Text('Atur Jadwal', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 4. 8 Grid Fitur Cepat Toko
          Text(
            'Layanan Operasional Kios',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Column(
              children: [
                // Baris 1: Menu & Stok, Jadwal Toko, Lokasi & Peta
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGridItem(
                      icon: Icons.restaurant_menu_rounded,
                      color: const Color(0xFFEA580C),
                      label: 'Menu & Stok',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MerchantMenuScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildGridItem(
                      icon: Icons.schedule_rounded,
                      color: const Color(0xFF0284C7),
                      label: 'Jadwal Toko',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showOperatingScheduleEditorSheet(
                          context: context,
                          initialSchedule: MerchantOperatingSchedule.defaults(),
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildGridItem(
                      icon: Icons.storefront_rounded,
                      color: const Color(0xFF8B5CF6),
                      label: 'Lokasi & Peta',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MerchantProfileScreen(),
                          ),
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Baris 2: Penilaian, Wawasan Dapur, Pusat Bantuan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildGridItem(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFF59E0B),
                      label: 'Penilaian',
                      onTap: () {
                        _showSimpleInfoSheet(
                          context,
                          'Penilaian & Reputasi Toko',
                          'Rating Keseluruhan: 4.9 / 5.0 (98 Ulasan Positif)\n\n• Rasa Makanan: 5.0 / 5.0\n• Kerapian Kemasan: 4.9 / 5.0\n• Kecepatan Penyajian: 4.8 / 5.0\n\nUlasan Terkini:\n"Dimsumnya mantap, masih hangat waktu driver antar!" - Siti R.\n"Porsi pas dan bumbu sausnya nagih." - Mas Bowo',
                          isDark,
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildGridItem(
                      icon: Icons.insights_rounded,
                      color: const Color(0xFF16A34A),
                      label: 'Wawasan Dapur',
                      onTap: () {
                        _showSimpleInfoSheet(
                          context,
                          'Wawasan Operasional Dapur',
                          '• Rata-rata Waktu Masak: 8.5 menit per tiket\n• Jam Sibuk Resto: 11:30 - 13:00 WIB & 18:30 - 20:00 WIB\n• Menu Terlaris Pekan Ini: Dimsum Siomay Ayam (142 porsi)\n• Ketersediaan Bahan Baku: 98% (Aman)',
                          isDark,
                        );
                      },
                      isDark: isDark,
                    ),
                    _buildGridItem(
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFF0D9488),
                      label: 'Pusat Bantuan',
                      onTap: () {
                        _showSimpleInfoSheet(
                          context,
                          'Pusat Bantuan Mitra GAGE 24/7',
                          'Butuh kendala order, pencairan saldo, atau ubah menu?\n\n• Layanan WhatsApp CS Mitra: 0812-3456-7890 (Fast Response)\n• Tim Lapangan Pracimantoro: Jl. Raya Pracimantoro No. 88\n• Email Dukungan: mitra@gageapp.id',
                          isDark,
                        );
                      },
                      isDark: isDark,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 5. Banner Carousel Slider Interaktif Star Resto GAGE
          MerchantPromoBannerSlider(isDark: isDark),
        ],
      ),
    );
  }

  Widget _buildGridItem({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.20 : 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MerchantPromoBannerSlider extends StatefulWidget {
  final bool isDark;

  const MerchantPromoBannerSlider({
    super.key,
    required this.isDark,
  });

  @override
  State<MerchantPromoBannerSlider> createState() => _MerchantPromoBannerSliderState();
}

class _MerchantPromoBannerSliderState extends State<MerchantPromoBannerSlider> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showStarRestoDialog(BuildContext context, bool isDark) {
    HapticFeedback.lightImpact();
    GageFloatingSheet.show(
      context: context,
      title: 'Program Star Resto GAGE',
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lencana eksklusif mitra resto terbaik Pracimantoro',
              style: TextStyle(
                fontSize: 12,
                color: widget.isDark ? Colors.white70 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Syarat Kualifikasi Toko Anda:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            _buildRequirementRow('Rating Pembeli >= 4.8', 'Aktif: 4.9 (Memenuhi)', true, widget.isDark),
            const SizedBox(height: 8),
            _buildRequirementRow('Pesanan Selesai >= 50', 'Aktif: 128 Pesanan (Memenuhi)', true, widget.isDark),
            const SizedBox(height: 8),
            _buildRequirementRow('Pembatalan Toko < 1%', 'Aktif: 0% (Memenuhi)', true, widget.isDark),
            const SizedBox(height: 8),
            _buildRequirementRow('Waktu Masak < 15 Menit', 'Aktif: 8.5 Menit (Memenuhi)', true, widget.isDark),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD97706),
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  GageToast.show(context, 'Pengajuan Star Resto Anda sedang ditinjau tim GAGE!');
                },
                child: const Text('Ajukan Lencana Star Resto Sekarang', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementRow(String title, String status, bool passed, bool isDark) {
    return Row(
      children: [
        Icon(
          passed ? Icons.check_circle_rounded : Icons.cancel_rounded,
          color: passed ? const Color(0xFF16A34A) : Colors.red,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
        Text(
          status,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: passed ? const Color(0xFF16A34A) : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      _BannerSlideData(
        title: 'JADI STAR RESTO GAGE',
        description: 'Tingkatkan kepercayaan pelanggan & dapatkan komisi prioritas kurir.',
        buttonText: 'Syarat & Gabung',
        gradientColors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        icon: Icons.stars_rounded,
        onTap: () => _showStarRestoDialog(context, widget.isDark),
      ),
      _BannerSlideData(
        title: 'FESTIVAL KULINER GAGE',
        description: 'Dapatkan sorotan utama di Beranda Pelanggan & subsidi voucher gratis ongkir!',
        buttonText: 'Ikuti Event',
        gradientColors: [const Color(0xFFE11D48), const Color(0xFFBE123C)],
        icon: Icons.festival_rounded,
        onTap: () {
          GageToast.show(context, 'Pendaftaran Festival Kuliner Pracimantoro dibuka!');
        },
      ),
      _BannerSlideData(
        title: 'STANDAR DAPUR HIGIENIS',
        description: 'Gunakan segel kemasan anti-tumpah untuk menjaga rating bintang 5 konsisten.',
        buttonText: 'Lihat Tips',
        gradientColors: [const Color(0xFF0284C7), const Color(0xFF0369A1)],
        icon: Icons.clean_hands_rounded,
        onTap: () {
          GageToast.show(context, 'Panduan SOP kemasan higienis berhasil dibuka!');
        },
      ),
    ];

    return Column(
      children: [
        SizedBox(
          height: 115,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: slides.length,
            itemBuilder: (context, index) {
              final slide = slides[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: slide.gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: slide.gradientColors.first.withValues(alpha: 0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(slide.icon, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                slide.title,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            slide.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.92),
                              height: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: slide.gradientColors.last,
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                      onPressed: slide.onTap,
                      child: Text(
                        slide.buttonText,
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dots Indicator - Full Rounded Capsule
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (idx) {
            final isActive = idx == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: isActive ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: isActive ? GageTheme.primary : (widget.isDark ? Colors.white24 : Colors.grey.shade300),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _BannerSlideData {
  final String title;
  final String description;
  final String buttonText;
  final List<Color> gradientColors;
  final IconData icon;
  final VoidCallback onTap;

  _BannerSlideData({
    required this.title,
    required this.description,
    required this.buttonText,
    required this.gradientColors,
    required this.icon,
    required this.onTap,
  });
}
