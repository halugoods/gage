import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/features/wallet/presentation/qris_pay_screen.dart';
import 'package:gage_app/features/wallet/presentation/withdraw_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';

/// Full Wallet Hub Screen (GagePayScreen)
/// Dibuka saat user menge-tap kartu GagePay di beranda untuk manajemen saldo penuh
class GagePayScreen extends StatefulWidget {
  const GagePayScreen({super.key});

  @override
  State<GagePayScreen> createState() => _GagePayScreenState();
}

class _GagePayScreenState extends State<GagePayScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  String _activeFilter = 'SEMUA'; // 'SEMUA', 'TOPUP', 'WITHDRAWAL', 'BELANJA'

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredTxs = wallet.transactions.where((t) {
      if (_activeFilter == 'SEMUA') return true;
      final type = (t['type'] as String? ?? '').toUpperCase();
      if (_activeFilter == 'TOPUP') return type.contains('TOPUP');
      if (_activeFilter == 'WITHDRAWAL') return type.contains('WITHDRAWAL');
      if (_activeFilter == 'BELANJA') return !type.contains('TOPUP') && !type.contains('WITHDRAWAL');
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'GagePay Hub',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Saldo',
            onPressed: () {
              wallet.fetchWallet('usr-cust-01');
              GageToast.show(context, 'Saldo GagePay diperbarui', type: GageToastType.info);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => wallet.fetchWallet('usr-cust-01'),
        color: GageTheme.primary,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Kartu Saldo Utama (GagePay Platinum Card)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE11D48), Color(0xFFBE123C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x3DE11D48),
                      blurRadius: 16,
                      offset: Offset(0, 6),
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
                            Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'GAGEPay',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'PLATINUM MEMBER',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Saldo Tersedia',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    if (wallet.isLoading)
                      const GageSkeletonBox(width: 170, height: 28, borderRadius: BorderRadius.all(Radius.circular(6)))
                    else
                      Text(
                        currencyFormatter.format(wallet.balance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.monetization_on_rounded, color: GageTheme.accentYellow, size: 16),
                        const SizedBox(width: 6),
                        if (wallet.isLoading)
                          const GageSkeletonBox(width: 90, height: 14, borderRadius: BorderRadius.all(Radius.circular(4)))
                        else
                          Text(
                            '${wallet.points} Poin GAGE',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                          ),
                        const Spacer(),
                        const Text(
                          'No: 0851-****-5735',
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // 2. 4 Tombol Aksi Cepat (Top Up, Bayar, Tarik, Misi)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Top Up',
                    color: GageTheme.primary,
                    onTap: () {
                      TopupQrisDialog.showAsSheet(
                        context,
                        onTopupSuccess: (amt) {
                          wallet.fetchWallet('usr-cust-01');
                        },
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.qr_code_scanner_rounded,
                    label: 'Bayar QRIS',
                    color: const Color(0xFF0284C7),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const QrisPayScreen()),
                      );
                    },
                  ),
                  _buildQuickAction(
                    icon: Icons.outbox_rounded,
                    label: 'Tarik Saldo',
                    color: const Color(0xFF16A34A),
                    onTap: () => GageWithdrawSheet.show(context),
                  ),
                  _buildQuickAction(
                    icon: Icons.stars_rounded,
                    label: 'Tukar Poin',
                    color: const Color(0xFFD97706),
                    onTap: () {
                      GageToast.show(
                        context,
                        'Poin dapat ditukarkan voucher diskon saat checkout pesanan!',
                        type: GageToastType.info,
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Ringkasan Cashflow & Info Arbitrase Biaya Rp 1.000
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xFF2563EB), size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pencairan Bebas Ribet (H+1 Payout)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1E40AF)),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Tarik saldo ke rekening BCA, BRI, Mandiri, atau E-Wallet mana pun dengan biaya admin flat Rp 1.000.',
                          style: TextStyle(fontSize: 11, color: Color(0xFF1E3A8A)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 4. Header Riwayat Transaksi & Filter Chips
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Transaksi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${filteredTxs.length} transaksi',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (wallet.isLoading)
              const GageSkeletonCategoryPillsRow(count: 4)
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('SEMUA', 'Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('TOPUP', 'Isi Saldo'),
                    const SizedBox(width: 8),
                    _buildFilterChip('WITHDRAWAL', 'Penarikan'),
                    const SizedBox(width: 8),
                    _buildFilterChip('BELANJA', 'Belanja & Jasa'),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            // 5. Daftar Transaksi
            if (wallet.isLoading)
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                itemBuilder: (ctx, idx) => const GageSkeletonTransactionTile(),
              )
            else if (filteredTxs.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.receipt_long_rounded, size: 40, color: Colors.black26),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat transaksi pada filter ini',
                      style: TextStyle(fontSize: 12.5, color: Colors.black54),
                    ),
                  ],
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredTxs.length,
                separatorBuilder: (_, idx) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final t = filteredTxs[idx];
                  final title = t['title'] as String? ?? 'Transaksi GagePay';
                  final type = (t['type'] as String? ?? '').toUpperCase();
                  final amount = t['amount'] as int? ?? 0;
                  final status = t['status'] as String? ?? 'BERHASIL';
                  final date = t['date'] as String? ?? '';
                  final isPlus = type.contains('TOPUP') || type.contains('COMMISSION');

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isPlus ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isPlus ? const Color(0xFF16A34A) : GageTheme.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '$status • $date',
                                style: const TextStyle(fontSize: 11, color: Colors.black54),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${isPlus ? "+" : "-"}${currencyFormatter.format(amount)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isPlus ? const Color(0xFF16A34A) : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GageTapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String key, String label) {
    final isSelected = _activeFilter == key;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeFilter = key);
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? GageTheme.primary : Colors.grey.shade300),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
