import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/features/wallet/presentation/qris_pay_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_screen.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';

class FloatingWalletCard extends StatelessWidget {
  const FloatingWalletCard({super.key});

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    if (wallet.isLoading) {
      return const GageSkeletonWalletCard();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GagePayScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            child: Row(
              children: [
                // Sisi Kiri: Saldo GAGEPay & Poin Loyalti
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: GageTheme.primary,
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'GAGEPay',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 2),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: isDark ? Colors.white60 : Colors.black45,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            currencyFormatter.format(wallet.balance),
                            style: TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w900,
                              color: isDark ? Colors.white : Colors.black87,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(1.5),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF59E0B),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.star_rounded, color: Colors.white, size: 11),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${wallet.points} Poin',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Container(
                  height: 38,
                  width: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                ),
                const SizedBox(width: 6),

                // Sisi Kanan: 4 Tombol Aksi Cepat (Top Up, Bayar, Tarik, Riwayat)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildWalletAction(
                      context,
                      isDark: isDark,
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Top Up',
                      onTap: () {
                        TopupQrisDialog.showAsSheet(
                          context,
                          onTopupSuccess: (amt) {
                            final auth = context.read<AuthProvider>();
                            final uid = auth.currentUser?.id ?? (GageApiClient.useDevSeedData ? 'usr-cust-01' : '');
                            if (uid.isNotEmpty) {
                              wallet.fetchWallet(uid);
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    _buildWalletAction(
                      context,
                      isDark: isDark,
                      icon: Icons.qr_code_scanner_rounded,
                      label: 'Bayar',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (ctx) => const QrisPayScreen()),
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    _buildWalletAction(
                      context,
                      isDark: isDark,
                      icon: Icons.outbox_rounded,
                      label: 'Tarik',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GagePayScreen(initialAction: 'withdraw'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 3),
                    _buildWalletAction(
                      context,
                      isDark: isDark,
                      icon: Icons.history_rounded,
                      label: 'Riwayat',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GagePayScreen(initialAction: 'history'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletAction(
    BuildContext context, {
    required bool isDark,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GageTapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
        constraints: const BoxConstraints(minWidth: 42, minHeight: 46),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isDark ? Colors.white10 : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200,
                  width: 0.8,
                ),
              ),
              child: Icon(icon, color: GageTheme.primary, size: 18),
            ),
            const SizedBox(height: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
