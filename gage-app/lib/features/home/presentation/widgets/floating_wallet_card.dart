import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';

import 'package:gage_app/features/wallet/presentation/offline_qris_pay_sheet.dart';

class FloatingWalletCard extends StatelessWidget {
  const FloatingWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? (screenWidth - 560) / 2 : 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black38 : Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Sisi Kiri: Saldo GAGEPay & Poin Loyalti
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: GageTheme.primaryLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 14),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'GAGEPay',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: GageTheme.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  currencyFormatter.format(wallet.balance),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : GageTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: GageTheme.accentYellow, size: 13),
                    const SizedBox(width: 3),
                    Text(
                      '${wallet.points} Poin',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : GageTheme.textSecondary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 38, width: 1, color: Colors.grey.shade200),
          const SizedBox(width: 12),

          // Sisi Kanan: 3 Tombol Aksi Cepat (Top Up, Bayar, Riwayat)
          Row(
            children: [
              _buildWalletAction(
                context,
                icon: Icons.add_circle_outline_rounded,
                label: 'Top Up',
                color: GageTheme.primary,
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => TopupQrisDialog(
                      onTopupSuccess: (amt) {
                        wallet.fetchWallet('usr-cust-01');
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 14),
              _buildWalletAction(
                context,
                icon: Icons.qr_code_scanner_rounded,
                label: 'Bayar',
                color: Colors.blue.shade700,
                onTap: () {
                  OfflineQrisPaySheet.show(context);
                },
              ),
              const SizedBox(width: 14),
              _buildWalletAction(
                context,
                icon: Icons.receipt_long_rounded,
                label: 'Riwayat',
                color: Colors.amber.shade800,
                onTap: () {
                  _showMutationSheet(context, wallet);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white : GageTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showMutationSheet(BuildContext context, WalletProvider wallet) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Riwayat Mutasi GAGEPay', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: GageTheme.primaryLight,
                child: Icon(Icons.arrow_downward, color: GageTheme.primary),
              ),
              title: const Text('Top Up Saldo via QRIS Dinamis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: const Text('Hari ini • Berhasil', style: TextStyle(fontSize: 11)),
              trailing: Text(
                '+${currencyFormatter.format(25000)}',
                style: const TextStyle(color: GageTheme.accentGreen, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
