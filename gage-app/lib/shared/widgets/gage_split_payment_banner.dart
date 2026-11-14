import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';

/// Upgraded in-card banner shown inside Metode Pembayaran when the user
/// selects GAGEPay with insufficient balance, surfacing Top Up and clean
/// GAGEPay + COD / GAGEPay + QRIS split cards (only when walletBalance > 0),
/// or direct QRIS / COD fallback switches when walletBalance == 0.
class GageSplitPaymentBanner extends StatelessWidget {
  final int walletBalance;
  final int totalAmount;
  final NumberFormat currencyFormatter;
  final VoidCallback onTopUp;
  final VoidCallback onSelectCodSplit;
  final VoidCallback onSelectQrisSplit;
  final VoidCallback? onSelectPureCod;
  final VoidCallback? onSelectPureQris;

  const GageSplitPaymentBanner({
    super.key,
    required this.walletBalance,
    required this.totalAmount,
    required this.currencyFormatter,
    required this.onTopUp,
    required this.onSelectCodSplit,
    required this.onSelectQrisSplit,
    this.onSelectPureCod,
    this.onSelectPureQris,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deficit = (totalAmount - walletBalance).clamp(0, 99999999);
    final canSplit = walletBalance > 0 && deficit > 0;

    final containerBg = isDark
        ? const Color(0xFF1E1B24)
        : const Color(0xFFFFF8F6);
    final containerBorder = isDark
        ? GageTheme.primary.withValues(alpha: 0.35)
        : const Color(0xFFFECDD3);
    final titleColor = isDark ? const Color(0xFFFCA5A5) : const Color(0xFF9F1239);
    final subtitleColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: containerBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: GageTheme.primary.withValues(alpha: isDark ? 0.22 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
                  color: GageTheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      walletBalance <= 0
                          ? 'Saldo GAGEPay Rp 0'
                          : 'Saldo kurang ${currencyFormatter.format(deficit)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      canSplit
                          ? 'Saldo aktif ${currencyFormatter.format(walletBalance)} bisa dikombinasikan'
                          : 'Isi saldo GAGEPay atau pilih QRIS / COD',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final missingAmount = deficit > 0 ? deficit : 10000;
                  TopupQrisDialog.showAsSheet(
                    context,
                    initialAmount: missingAmount,
                    onTopupSuccess: (added) {
                      try {
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final wallet = Provider.of<WalletProvider>(context, listen: false);
                        final uid = auth.currentUser?.id ?? (GageApiClient.useDevSeedData ? 'usr-cust-01' : '');
                        if (uid.isNotEmpty) {
                          wallet.fetchWallet(uid);
                        }
                      } catch (_) {}
                      onTopUp();
                    },
                  );
                },
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                  decoration: BoxDecoration(
                    color: GageTheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Isi Saldo',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            canSplit ? 'Pilih kombinasi Split Payment:' : 'Beralih ke metode lain:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SplitOptionCard(
                  isDark: isDark,
                  icon: Icons.payments_outlined,
                  accentColor: const Color(0xFF16A34A),
                  title: canSplit ? 'GAGEPay + COD' : 'Pakai COD',
                  subtitle: canSplit
                      ? 'Sisa tunai ${currencyFormatter.format(deficit)}'
                      : 'Bayar tunai langsung',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (canSplit) {
                      onSelectCodSplit();
                    } else if (onSelectPureCod != null) {
                      onSelectPureCod!();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SplitOptionCard(
                  isDark: isDark,
                  icon: Icons.qr_code_2_rounded,
                  accentColor: const Color(0xFF0284C7),
                  title: canSplit ? 'GAGEPay + QRIS' : 'Pakai QRIS',
                  subtitle: canSplit
                      ? 'Scan sisa ${currencyFormatter.format(deficit)}'
                      : 'Bayar instan via QRIS',
                  onTap: () {
                    HapticFeedback.selectionClick();
                    if (canSplit) {
                      onSelectQrisSplit();
                    } else if (onSelectPureQris != null) {
                      onSelectPureQris!();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SplitOptionCard extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SplitOptionCard({
    required this.isDark,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final titleColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.45), width: 1.2),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: subColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
