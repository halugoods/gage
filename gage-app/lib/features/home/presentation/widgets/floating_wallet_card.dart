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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Mutasi GAGEPay',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Saldo: ${currencyFormatter.format(wallet.balance)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: GageTheme.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (wallet.transactions.isNotEmpty)
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wallet.transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = wallet.transactions[index];
                      final isTopup = (tx['type'] ?? 'TOPUP') == 'TOPUP';
                      final amt = (tx['amount'] ?? 0) as int;
                      final desc = (tx['description'] ?? (isTopup ? 'Top Up QRIS' : 'Pembayaran QRIS')) as String;
                      final time = (tx['created_at'] ?? 'Hari ini') as String;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isTopup
                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                              : Colors.red.withValues(alpha: 0.12),
                          child: Icon(
                            isTopup ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: isTopup ? const Color(0xFF16A34A) : Colors.red,
                            size: 18,
                          ),
                        ),
                        title: Text(
                          desc,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        subtitle: Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        trailing: Text(
                          '${isTopup ? '+' : '-'}${currencyFormatter.format(amt)}',
                          style: TextStyle(
                            color: isTopup ? const Color(0xFF16A34A) : Colors.red,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                  ),
                )
              else ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFDCFCE7),
                    child: Icon(Icons.arrow_downward_rounded, color: Color(0xFF16A34A), size: 18),
                  ),
                  title: const Text('Top Up Saldo via QRIS Dinamis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Hari ini • Berhasil', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    '+${currencyFormatter.format(50000)}',
                    style: const TextStyle(color: Color(0xFF16A34A), fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFEE2E2),
                    child: Icon(Icons.arrow_upward_rounded, color: Colors.red, size: 18),
                  ),
                  title: const Text('Pembayaran QRIS Merchant Mitra', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: const Text('Kemarin • Berhasil', style: TextStyle(fontSize: 11, color: Colors.grey)),
                  trailing: Text(
                    '-${currencyFormatter.format(25000)}',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
