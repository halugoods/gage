import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Pusat Poin Loyalitas & Rewards GAGE (GagePointsRewardScreen)
/// Menyediakan fitur komprehensif pemanfaatan poin:
/// 1. Konversi Poin Langsung ke Saldo Belanja GAGEPay
/// 2. Loyalty Tier Membership (Pratama, Madya, Utama, Sultan Pracimantoro)
/// 3. Katalog E-Voucher & Promo UMKM Lokal
/// 4. GAGE Peduli Pracimantoro (Program Donasi Sosial)
/// 5. Transfer Poin ke Sesama Pengguna
/// 6. Buku Besar Riwayat Aktivitas Poin
class GagePointsRewardScreen extends StatefulWidget {
  const GagePointsRewardScreen({super.key});

  @override
  State<GagePointsRewardScreen> createState() => _GagePointsRewardScreenState();
}

class _GagePointsRewardScreenState extends State<GagePointsRewardScreen> {
  int _selectedTabIndex = 0; // 0: Tukar Poin, 1: GAGE Peduli, 2: Transfer & Riwayat
  final TextEditingController _transferRecipientCtrl = TextEditingController();
  final TextEditingController _transferPointsCtrl = TextEditingController();
  bool _isTransferring = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _transferRecipientCtrl.dispose();
    _transferPointsCtrl.dispose();
    super.dispose();
  }

  // Menentukan Tier Loyalti berdasarkan akumulasi poin
  Map<String, dynamic> _getLoyaltyTier(int points) {
    if (points >= 5000) {
      return {
        'name': 'Sultan Pracimantoro',
        'badge': 'DIAMOND',
        'color': const Color(0xFF6366F1),
        'icon': Icons.diamond_rounded,
        'multiplier': '2.0x Poin',
        'perk': 'Bebas biaya admin penarikan & CS prioritas VIP',
        'nextThreshold': 10000,
        'progress': 1.0,
      };
    } else if (points >= 1500) {
      return {
        'name': 'Utama',
        'badge': 'PLATINUM',
        'color': const Color(0xFF0EA5E9),
        'icon': Icons.workspace_premium_rounded,
        'multiplier': '1.5x Poin',
        'perk': 'Gratis 2x admin penarikan/bulan & prioritas driver',
        'nextThreshold': 5000,
        'progress': (points - 1500) / 3500,
      };
    } else if (points >= 500) {
      return {
        'name': 'Madya',
        'badge': 'GOLD',
        'color': const Color(0xFFF59E0B),
        'icon': Icons.star_rounded,
        'multiplier': '1.2x Poin',
        'perk': 'Diskon admin penarikan 25% & kupon bulanan',
        'nextThreshold': 1500,
        'progress': (points - 500) / 1000,
      };
    } else {
      return {
        'name': 'Pratama',
        'badge': 'SILVER',
        'color': const Color(0xFF94A3B8),
        'icon': Icons.shield_rounded,
        'multiplier': '1.0x Poin',
        'perk': 'Dapatkan poin dari setiap transaksi kuliner & perjalanan',
        'nextThreshold': 500,
        'progress': points / 500,
      };
    }
  }

  // Konversi Poin ke Saldo GAGEPay
  void _convertPointsToBalance(BuildContext context, WalletProvider wallet, int requiredPoints, int balanceReward) {
    HapticFeedback.mediumImpact();
    if (wallet.points < requiredPoints) {
      GageToast.show(
        context,
        'Poin tidak mencukupi. Butuh $requiredPoints poin (Tersedia: ${wallet.points} poin).',
        type: GageToastType.warning,
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Konfirmasi Tukar Saldo', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Text(
          'Tukarkan $requiredPoints Poin menjadi ${currencyFormatter.format(balanceReward)} saldo GAGEPay sekarang?',
          style: const TextStyle(fontSize: 13.5, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              wallet.addPoints(-requiredPoints);
              wallet.topUp(balanceReward);
              wallet.addTransaction({
                'id': 'tx-pts-sal-${DateTime.now().millisecondsSinceEpoch}',
                'type': 'TOPUP',
                'title': 'Tukar $requiredPoints Poin GAGE',
                'amount': balanceReward,
                'description': 'Konversi $requiredPoints Poin ke Saldo GAGEPay',
                'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'status': 'SUCCESS',
              });
              HapticFeedback.heavyImpact();
              GageToast.show(
                context,
                'Berhasil! Saldo bertambah ${currencyFormatter.format(balanceReward)}.',
                type: GageToastType.success,
              );
            },
            child: const Text('Tukarkan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Tukar Poin ke Voucher
  void _claimVoucher(BuildContext context, WalletProvider wallet, int requiredPoints, String voucherName) {
    HapticFeedback.mediumImpact();
    if (wallet.points < requiredPoints) {
      GageToast.show(
        context,
        'Poin tidak mencukupi untuk klaim voucher ini.',
        type: GageToastType.warning,
      );
      return;
    }

    wallet.addPoints(-requiredPoints);
    wallet.addTransaction({
      'id': 'tx-pts-vch-${DateTime.now().millisecondsSinceEpoch}',
      'type': 'POINT_REDEEM',
      'title': 'Klaim $voucherName',
      'amount': requiredPoints,
      'description': 'Penukaran $requiredPoints Poin untuk $voucherName',
      'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'status': 'SUCCESS',
    });
    HapticFeedback.heavyImpact();
    GageToast.show(
      context,
      'Voucher "$voucherName" berhasil diklaim dan aktif di akun Anda!',
      type: GageToastType.success,
    );
  }

  // Donasi Poin GAGE Peduli
  void _donatePoints(BuildContext context, WalletProvider wallet, int pointsToDonate, String programTitle) {
    HapticFeedback.mediumImpact();
    if (wallet.points < pointsToDonate) {
      GageToast.show(context, 'Poin tidak mencukupi untuk berdonasi.', type: GageToastType.warning);
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Donasi GAGE Peduli', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Text(
          'Donasikan $pointsToDonate Poin (setara ${currencyFormatter.format(pointsToDonate * 100)}) untuk program "$programTitle"?\n\nDonasi akan disalurkan oleh PT Halu Goods Indonesia secara transparan.',
          style: const TextStyle(fontSize: 13, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              wallet.addPoints(-pointsToDonate);
              wallet.addTransaction({
                'id': 'tx-pts-don-${DateTime.now().millisecondsSinceEpoch}',
                'type': 'DONATION',
                'title': 'Donasi: $programTitle',
                'amount': pointsToDonate * 100,
                'description': 'Donasi $pointsToDonate Poin untuk $programTitle',
                'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
                'status': 'SUCCESS',
              });
              HapticFeedback.heavyImpact();
              GageToast.show(
                context,
                'Terima kasih! Donasi $pointsToDonate poin berhasil disalurkan.',
                type: GageToastType.success,
              );
            },
            child: const Text('Donasikan Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // Transfer Poin ke Sesama Pengguna
  void _transferPoints(BuildContext context, WalletProvider wallet) {
    final dest = _transferRecipientCtrl.text.trim();
    final pts = int.tryParse(_transferPointsCtrl.text.trim()) ?? 0;

    if (dest.isEmpty) {
      GageToast.show(context, 'Masukkan nomor rekening atau HP penerima.', type: GageToastType.warning);
      return;
    }

    if (pts < 10) {
      GageToast.show(context, 'Minimal transfer poin adalah 10 Poin.', type: GageToastType.warning);
      return;
    }

    if (wallet.points < pts) {
      GageToast.show(context, 'Poin Anda tidak mencukupi.', type: GageToastType.warning);
      return;
    }

    setState(() => _isTransferring = true);
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() => _isTransferring = false);
      wallet.addPoints(-pts);
      wallet.addTransaction({
        'id': 'tx-pts-tf-${DateTime.now().millisecondsSinceEpoch}',
        'type': 'POINT_TRANSFER',
        'title': 'Kirim $pts Poin ke $dest',
        'amount': pts,
        'description': 'Transfer $pts Poin ke rekening $dest',
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        'status': 'SUCCESS',
      });
      _transferPointsCtrl.clear();
      _transferRecipientCtrl.clear();
      HapticFeedback.heavyImpact();
      GageToast.show(context, 'Berhasil mengirimkan $pts poin ke $dest!', type: GageToastType.success);
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tier = _getLoyaltyTier(wallet.points);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pusat Poin & Rewards',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Header Visual Mewah Gradien Obsidian & Emas Amber
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                      : [const Color(0xFF2E1065), const Color(0xFF4C1D95)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Sisi Kiri: Saldo Poin & Nilai Rupiah
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL POIN SAYA',
                            style: TextStyle(
                              color: Color(0xFFFDE68A),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                '${wallet.points}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Poin',
                                style: TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            'Estimasi nilai: ${currencyFormatter.format(wallet.points * 100)}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      // Sisi Kanan: Badge Loyalty Tier
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: (tier['color'] as Color).withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: tier['color'] as Color, width: 1.2),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(tier['icon'] as IconData, color: tier['color'] as Color, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              tier['badge'] as String,
                              style: TextStyle(
                                color: tier['color'] as Color,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Progress Bar Loyalty Tier
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tier: ${tier['name']} (${tier['multiplier']})',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${tier['nextThreshold']} Poin',
                              style: const TextStyle(color: Colors.white60, fontSize: 11),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: (tier['progress'] as double).clamp(0.0, 1.0),
                            backgroundColor: Colors.white12,
                            valueColor: AlwaysStoppedAnimation<Color>(tier['color'] as Color),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          tier['perk'] as String,
                          style: const TextStyle(color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 2. Segmented Pill Tabs Kapsul Penuh Sesuai Aturan AGENTS.md
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _buildPillTab(index: 0, label: 'Tukar Poin', isDark: isDark),
                    _buildPillTab(index: 1, label: 'GAGE Peduli', isDark: isDark),
                    _buildPillTab(index: 2, label: 'Transfer & Riwayat', isDark: isDark),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 3. Tab Content Sesuai Pilihan
            if (_selectedTabIndex == 0) ...[
              _buildExchangeTab(context, wallet, isDark),
            ] else if (_selectedTabIndex == 1) ...[
              _buildPeduliTab(context, wallet, isDark),
            ] else ...[
              _buildTransferAndHistoryTab(context, wallet, isDark),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Segmented Pill Tab Widget
  Widget _buildPillTab({required int index, required String label, required bool isDark}) {
    final isSelected = _selectedTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTabIndex = index);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: GageTheme.primary.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
            ),
          ),
        ),
      ),
    );
  }

  // TAB 1: Tukar Poin (Saldo Langsung & E-Voucher)
  Widget _buildExchangeTab(BuildContext context, WalletProvider wallet, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subheader: Tukar ke Saldo GAGEPay
          const Text(
            'Tukar Langsung ke Saldo Belanja',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            'Gunakan poin Anda sebagai saldo tunai untuk order makanan dan ojek.',
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 12),

          // Pilihan Konversi Saldo
          Row(
            children: [
              Expanded(
                child: _buildSaldoConversionCard(
                  context: context,
                  wallet: wallet,
                  points: 50,
                  rupiah: 5000,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSaldoConversionCard(
                  context: context,
                  wallet: wallet,
                  points: 100,
                  rupiah: 10000,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildSaldoConversionCard(
                  context: context,
                  wallet: wallet,
                  points: 200,
                  rupiah: 20000,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildSaldoConversionCard(
                  context: context,
                  wallet: wallet,
                  points: 500,
                  rupiah: 50000,
                  isDark: isDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Subheader: Katalog E-Voucher & Promo UMKM
          const Text(
            'Katalog E-Voucher & Promo UMKM',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          _buildVoucherItem(
            context: context,
            wallet: wallet,
            title: 'Diskon Kuliner Mitra GAGE Food',
            desc: 'Potongan Rp 10.000 untuk order makanan di resto mitra Pracimantoro',
            points: 75,
            icon: Icons.restaurant_rounded,
            badgeColor: const Color(0xFFDC2626),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildVoucherItem(
            context: context,
            wallet: wallet,
            title: 'Gratis Ongkir Ekstra s/d Rp 7.000',
            desc: 'Berlaku untuk layanan GAGE Food dan GAGE Mart',
            points: 50,
            icon: Icons.local_shipping_rounded,
            badgeColor: const Color(0xFF2563EB),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildVoucherItem(
            context: context,
            wallet: wallet,
            title: 'Diskon Perjalanan GAGE Ride Rp 5.000',
            desc: 'Hemat biaya ongkos ojek motor ke pasar atau stasiun',
            points: 40,
            icon: Icons.two_wheeler_rounded,
            badgeColor: const Color(0xFF059669),
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildVoucherItem(
            context: context,
            wallet: wallet,
            title: 'Kupon Belanja UMKM Sembako Rp 15.000',
            desc: 'Belanja hemat produk kebutuhan sehari-hari di toko kelontong lokal',
            points: 120,
            icon: Icons.storefront_rounded,
            badgeColor: const Color(0xFFD97706),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Card Konversi Saldo
  Widget _buildSaldoConversionCard({
    required BuildContext context,
    required WalletProvider wallet,
    required int points,
    required int rupiah,
    required bool isDark,
  }) {
    final canRedeem = wallet.points >= points;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: canRedeem
              ? GageTheme.primary.withValues(alpha: 0.3)
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$points Poin',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFB45309),
                  ),
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            currencyFormatter.format(rupiah),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Saldo GAGEPay',
            style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 34,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canRedeem ? GageTheme.primary : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
                padding: EdgeInsets.zero,
              ),
              onPressed: canRedeem
                  ? () => _convertPointsToBalance(context, wallet, points, rupiah)
                  : null,
              child: const Text('Tukar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // Item E-Voucher
  Widget _buildVoucherItem({
    required BuildContext context,
    required WalletProvider wallet,
    required String title,
    required String desc,
    required int points,
    required IconData icon,
    required Color badgeColor,
    required bool isDark,
  }) {
    final canClaim = wallet.points >= points;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: badgeColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points Poin',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFD97706),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: canClaim ? GageTheme.primary : Colors.grey.shade400,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            onPressed: canClaim ? () => _claimVoucher(context, wallet, points, title) : null,
            child: const Text('Klaim', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // TAB 2: GAGE Peduli (Donasi Sosial)
  Widget _buildPeduliTab(BuildContext context, WalletProvider wallet, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Peduli
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF065F46), Color(0xFF047857)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.volunteer_activism_rounded, color: Colors.white, size: 24),
                    SizedBox(width: 8),
                    Text(
                      'GAGE Peduli Pracimantoro',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Salurkan poin loyalitas Anda menjadi kebaikan nyata untuk masyarakat, UMKM pra-sejahtera, dan pelestarian lingkungan Wonogiri.',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          _buildDonationCard(
            context: context,
            wallet: wallet,
            title: 'Paket Sembako UMKM Pra-Sejahtera',
            desc: 'Pemberian beras, minyak goreng, dan telur untuk keluarga pedagang kecil di Pracimantoro.',
            points: 50,
            icon: Icons.shopping_basket_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildDonationCard(
            context: context,
            wallet: wallet,
            title: 'Bibit Pohon & Penghijauan Wonogiri',
            desc: 'Penanaman bibit pohon buah dan perindang di area perbukitan kapur Pracimantoro.',
            points: 100,
            icon: Icons.park_rounded,
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          _buildDonationCard(
            context: context,
            wallet: wallet,
            title: 'Beasiswa Belajar Anak Mitra Driver',
            desc: 'Bantuan perlengkapan sekolah dan buku tulis bagi anak mitra driver ojek GAGE.',
            points: 150,
            icon: Icons.school_rounded,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Card Donasi Sosial
  Widget _buildDonationCard({
    required BuildContext context,
    required WalletProvider wallet,
    required String title,
    required String desc,
    required int points,
    required IconData icon,
    required bool isDark,
  }) {
    final canDonate = wallet.points >= points;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: const Color(0xFF16A34A), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Donasi: $points Poin (${currencyFormatter.format(points * 100)})',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            desc,
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canDonate ? const Color(0xFF16A34A) : Colors.grey.shade400,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              onPressed: canDonate ? () => _donatePoints(context, wallet, points, title) : null,
              child: const Text('Donasikan Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: Transfer Poin & Riwayat Aktivitas
  Widget _buildTransferAndHistoryTab(BuildContext context, WalletProvider wallet, bool isDark) {
    final pointTxs = wallet.transactions.where((t) {
      final type = (t['type'] as String? ?? '').toUpperCase();
      return type.contains('POINT') || type.contains('DONATION') || type.contains('TOPUP');
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form Transfer Poin
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Kirim Poin ke Sesama Akun GAGE',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bagi poin loyalitas kepada teman atau keluarga sesama pengguna GAGEPay.',
                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),

                TextField(
                  controller: _transferRecipientCtrl,
                  decoration: InputDecoration(
                    labelText: 'Nomor Rekening',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    hintText: 'Contoh: 8908 1234 5678',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined, size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _transferPointsCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Jumlah Poin',
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white60 : const Color(0xFF64748B),
                    ),
                    hintText: 'Minimal 10 Poin',
                    hintStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.normal,
                      color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    ),
                    prefixIcon: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 20),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                    ),
                    onPressed: _isTransferring ? null : () => _transferPoints(context, wallet),
                    child: _isTransferring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Kirim Poin Sekarang', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Riwayat Aktivitas Poin
          const Text(
            'Riwayat Aktivitas Poin',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),

          if (pointTxs.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Center(
                child: Text(
                  'Belum ada riwayat aktivitas poin.',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          ] else ...[
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pointTxs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final tx = pointTxs[idx];
                final title = tx['title'] ?? tx['description'] ?? 'Aktivitas Poin';
                final desc = tx['description'] ?? '';
                final isAdd = (tx['type'] as String? ?? '').contains('TOPUP');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isAdd ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isAdd ? Icons.add_circle_outline_rounded : Icons.remove_circle_outline_rounded,
                          color: isAdd ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                            if (desc.isNotEmpty && desc != title)
                              Text(
                                desc,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white60 : const Color(0xFF64748B),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}
