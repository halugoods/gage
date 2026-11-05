import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';
import 'package:gage_app/features/wallet/presentation/qris_pay_screen.dart';
import 'package:gage_app/features/wallet/presentation/withdraw_sheet.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_pocket_wallet.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_3d_flip_card_dialog.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

/// Full Wallet Screen (GAGEPay)
/// Dilengkapi dengan Widget Saku Dompet Kulit 3D (GagePocketWallet)
/// dan Stack Kartu Rekening Penarikan yang dapat meluncur keluar (fan-out).
class GagePayScreen extends StatefulWidget {
  final String? initialAction; // 'withdraw', 'history'

  const GagePayScreen({
    super.key,
    this.initialAction,
  });

  @override
  State<GagePayScreen> createState() => _GagePayScreenState();
}

class _GagePayScreenState extends State<GagePayScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
  final ScrollController _scrollController = ScrollController();
  String _activeFilter = 'SEMUA'; // 'SEMUA', 'TOPUP', 'WITHDRAWAL', 'BELANJA'
  Map<String, dynamic>? _selectedWithdrawCard;

  final List<Map<String, dynamic>> _userAccounts = [
    {
      'id': 'acc-bca',
      'bank': 'BCA',
      'label': 'Bank Central Asia',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '5524 9910 4242',
      'maskedNumber': '•••• 4242',
      'fullNumber': '5524 9910 4242',
      'validThru': '12 / 28',
      'color': const Color(0xFF1E3A8A),
      'gradient': [const Color(0xFF1E3A8A), const Color(0xFF172554)],
      'chipColor': const Color(0xFFF59E0B),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'acc-mandiri',
      'bank': 'Mandiri',
      'label': 'Bank Mandiri',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '9012 4432 8810',
      'maskedNumber': '•••• 8810',
      'fullNumber': '9012 4432 8810',
      'validThru': '08 / 27',
      'color': const Color(0xFF0F172A),
      'gradient': [const Color(0xFF0F172A), const Color(0xFF334155)],
      'chipColor': const Color(0xFFE2E8F0),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'acc-gopay',
      'bank': 'GoPay',
      'label': 'GoPay E-Wallet',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '0812 3456 7890',
      'maskedNumber': '•••• 7890',
      'fullNumber': '0812 3456 7890',
      'validThru': '05 / 29',
      'color': const Color(0xFF0D9488),
      'gradient': [const Color(0xFF0D9488), const Color(0xFF065F46)],
      'chipColor': const Color(0xFFF59E0B),
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'id': 'acc-bri',
      'bank': 'BRI',
      'label': 'Bank Rakyat Indonesia',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '0012 9941 2914',
      'maskedNumber': '•••• 2914',
      'fullNumber': '0012 9941 2914',
      'validThru': '11 / 28',
      'color': const Color(0xFF00529C),
      'gradient': [const Color(0xFF00529C), const Color(0xFF082F49)],
      'chipColor': const Color(0xFFF59E0B),
      'icon': Icons.account_balance_rounded,
    },
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialAction != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (widget.initialAction == 'withdraw') {
          GageWithdrawSheet.show(context);
        } else if (widget.initialAction == 'history') {
          Future.delayed(const Duration(milliseconds: 300), () {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                280.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutCubic,
              );
            }
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

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
        title: Text(
          'GAGEPay',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            letterSpacing: 0.5,
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Saldo',
            onPressed: () {
              wallet.fetchWallet('usr-cust-01');
              GageToast.show(context, 'Saldo GAGEPay diperbarui', type: GageToastType.info);
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => wallet.fetchWallet('usr-cust-01'),
        color: GageTheme.primary,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Widget Saku Dompet Kulit 3D (Interactive Leather Pocket Wallet)
              GagePocketWallet(
                balance: wallet.balance,
                points: wallet.points,
                cards: _userAccounts,
                onCardSelected: (card) {
                  setState(() => _selectedWithdrawCard = card);
                },
                onCardDetailsTap: (card) {
                  Gage3DFlipCardDialog.show(
                    context,
                    cardData: card,
                    isPrimary: _userAccounts.indexOf(card) == 0,
                    onSetAsPrimary: () {
                      setState(() {
                        _userAccounts.remove(card);
                        _userAccounts.insert(0, card);
                        _selectedWithdrawCard = card;
                      });
                    },
                  );
                },
                onAddAccountTap: () => _showAccountSelectionSheet(context),
              ),

              const SizedBox(height: 14),

              // 2. Baris 4 Fitur Cepat (Top Up, Bayar QRIS, Tarik Saldo, Tukar Poin)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(
                  color: isDark ? GageTheme.darkCard : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? GageTheme.darkBorder : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Top Up',
                      color: GageTheme.primary,
                      isDark: isDark,
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
                      isDark: isDark,
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
                      isDark: isDark,
                      onTap: () {
                        if (_selectedWithdrawCard != null) {
                          GageToast.show(
                            context,
                            'Menyiapkan penarikan ke ${_selectedWithdrawCard!['bank']} (${_selectedWithdrawCard!['maskedNumber']})...',
                            type: GageToastType.info,
                          );
                        }
                        GageWithdrawSheet.show(context);
                      },
                    ),
                    _buildQuickAction(
                      icon: Icons.stars_rounded,
                      label: 'Tukar Poin',
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                      onTap: () => _showExchangePointsSheet(context, wallet),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 3. Banner Promo GAGEPay Ramping
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 4.5,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        'assets/images/banner_gagepay_promo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(color: const Color(0xFF382620)),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.1),
                              Colors.black.withValues(alpha: 0.65),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: Row(
                          children: [
                            const Spacer(flex: 5),
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF59E0B),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text(
                                          'PROMO GAGEPAY',
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        'HEMAT 50%',
                                        style: TextStyle(
                                          color: Colors.amberAccent,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Cashback & Diskon Saldo',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.2,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Otomatis terpasang saat bayar Food, Mart & Ride',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 9.5,
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
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 22),

              // 4. Header Riwayat Transaksi (Sesuai Benchmark Gambar 4)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    '${filteredTxs.length} transaksi',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
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
                      _buildFilterChip('SEMUA', 'Semua', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('TOPUP', 'Pemasukan', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('WITHDRAWAL', 'Penarikan', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('BELANJA', 'Pengeluaran', isDark),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // 5. Daftar Transaksi Terkelompok Bulanan (Modern Grouped Transactions Card)
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
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 40, color: isDark ? Colors.white24 : Colors.black26),
                      const SizedBox(height: 8),
                      Text(
                        'Belum ada riwayat transaksi pada filter ini',
                        style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                )
              else ...[
                // Kelompok Transaksi: Bulan Berjalan
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 6),
                  child: Text(
                    'Bulan Ini',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white60 : Colors.grey.shade600,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredTxs.length,
                    separatorBuilder: (_, idx) => Divider(
                      height: 1,
                      indent: 64,
                      color: isDark ? Colors.white10 : Colors.grey.shade100,
                    ),
                    itemBuilder: (ctx, idx) {
                      final t = filteredTxs[idx];
                      final title = t['title'] as String? ?? 'Transaksi GAGEPay';
                      final type = (t['type'] as String? ?? '').toUpperCase();
                      final amount = t['amount'] as int? ?? 0;
                      final date = t['date'] as String? ?? '';
                      final isPlus = type.contains('TOPUP') || type.contains('COMMISSION');

                      IconData catIcon = Icons.payment_rounded;
                      Color catColor = const Color(0xFF64748B);
                      String categoryLabel = 'Belanja';

                      if (type.contains('TOPUP')) {
                        catIcon = Icons.add_card_rounded;
                        catColor = const Color(0xFF16A34A);
                        categoryLabel = 'Top Up';
                      } else if (type.contains('WITHDRAWAL')) {
                        catIcon = Icons.outbox_rounded;
                        catColor = const Color(0xFFEA580C);
                        categoryLabel = 'Tarik Dana';
                      } else if (title.toLowerCase().contains('dimsum') || title.toLowerCase().contains('food') || title.toLowerCase().contains('chicken')) {
                        catIcon = Icons.restaurant_rounded;
                        catColor = GageTheme.primary;
                        categoryLabel = 'Kuliner';
                      } else if (title.toLowerCase().contains('ride') || title.toLowerCase().contains('car')) {
                        catIcon = Icons.two_wheeler_rounded;
                        catColor = const Color(0xFF2563EB);
                        categoryLabel = 'Transport';
                      }

                      return InkWell(
                        onTap: () => _showTransactionDetailSheet(context, t),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: catColor, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      date.isNotEmpty ? date : 'Hari Ini',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? Colors.white60 : Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${isPlus ? "+" : "-"} ${currencyFormatter.format(amount)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13.5,
                                      color: isPlus
                                          ? const Color(0xFF16A34A)
                                          : (isDark ? Colors.white : const Color(0xFF0F172A)),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    categoryLabel,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: isDark ? Colors.white24 : Colors.grey.shade400,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAccountSelectionSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      title: 'Pilih Rekening Penarikan',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Daftar rekening bank dan e-wallet tersimpan. Geser untuk memilih atau menetapkan Rekening Utama:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),

              // Stacked Scrollable Physical Cards
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: _userAccounts.length,
                  itemBuilder: (ctx, idx) {
                    final acc = _userAccounts[idx];
                    final isSelected = (_selectedWithdrawCard?['id'] == acc['id']) ||
                        (_selectedWithdrawCard == null && idx == 0);
                    final isPrimary = idx == 0;
                    final gradientColors = (acc['gradient'] as List?)?.cast<Color>() ??
                        [acc['color'] as Color, Colors.black87];

                    return Container(
                      width: 270,
                      margin: const EdgeInsets.only(right: 14, top: 4, bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isSelected ? const Color(0xFFF59E0B) : Colors.white24,
                          width: isSelected ? 2.0 : 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(acc['icon'] as IconData, color: Colors.white, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    (acc['bank'] as String).toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 13,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              if (isPrimary)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'UTAMA',
                                    style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 8.5),
                                  ),
                                )
                              else
                                InkWell(
                                  onTap: () {
                                    setSheetState(() {
                                      setState(() {
                                        _userAccounts.remove(acc);
                                        _userAccounts.insert(0, acc);
                                        _selectedWithdrawCard = acc;
                                      });
                                    });
                                    GageToast.show(
                                      context,
                                      '${acc['bank']} ditetapkan sebagai Rekening Utama!',
                                      type: GageToastType.success,
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'Set Utama',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 8.5),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          Text(
                            acc['maskedNumber'] as String,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              letterSpacing: 2.2,
                              fontFamily: 'monospace',
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (acc['holder'] as String).toUpperCase(),
                                style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                              InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedWithdrawCard = acc);
                                  Navigator.pop(ctx);
                                  GageToast.show(
                                    context,
                                    'Rekening aktif: ${acc['bank']} (${acc['maskedNumber']})',
                                    type: GageToastType.info,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? GageTheme.primary : Colors.white24,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    isSelected ? 'Terpilih' : 'Pilih',
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GageTheme.primary,
                    side: const BorderSide(color: GageTheme.primary, width: 1.4),
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Tambah Rekening Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _showAddAccountSheet(context);
                  },
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  void _showAddAccountSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    String selectedBank = 'BCA';
    final accNumCtrl = TextEditingController();
    final nameCtrl = TextEditingController(text: 'SITI RAHMAWATI');

    GageFloatingSheet.show(
      context: context,
      title: 'Tambah Rekening Bank / E-Wallet',
      child: StatefulBuilder(
        builder: (ctx, setSheetState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pilih Bank / Dompet Digital:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['BCA', 'Mandiri', 'BRI', 'BNI', 'GoPay', 'DANA', 'OVO'].map((bank) {
                  final isSel = selectedBank == bank;
                  return ChoiceChip(
                    label: Text(bank),
                    selected: isSel,
                    selectedColor: GageTheme.primaryLight,
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                      color: isSel ? GageTheme.primary : (isDark ? Colors.white70 : Colors.black87),
                    ),
                    shape: const StadiumBorder(),
                    onSelected: (val) {
                      if (val) setSheetState(() => selectedBank = bank);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              Text('Nomor Rekening / No. HP E-Wallet:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              const SizedBox(height: 6),
              TextField(
                controller: accNumCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Misal: 552499104242',
                  hintStyle: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 12),
              Text('Nama Pemilik Rekening:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade700)),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: isDark ? Colors.white12 : Colors.grey.shade300),
                  ),
                ),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  onPressed: () {
                    final num = accNumCtrl.text.trim();
                    final name = nameCtrl.text.trim();
                    if (num.isEmpty || name.isEmpty) return;
                    Navigator.pop(ctx);
                    final masked = num.length >= 4 ? '•••• ${num.substring(num.length - 4)}' : '•••• $num';
                    final newAcc = {
                      'id': 'acc-${DateTime.now().millisecondsSinceEpoch}',
                      'bank': selectedBank,
                      'label': selectedBank,
                      'holder': name,
                      'accountNumber': num,
                      'maskedNumber': masked,
                      'color': selectedBank == 'GoPay' || selectedBank == 'DANA' ? const Color(0xFF0D9488) : const Color(0xFF1E3A8A),
                      'icon': selectedBank == 'GoPay' || selectedBank == 'DANA' || selectedBank == 'OVO' ? Icons.account_balance_wallet_rounded : Icons.account_balance_rounded,
                    };
                    setState(() {
                      _userAccounts.add(newAcc);
                      _selectedWithdrawCard = newAcc;
                    });
                    GageToast.show(
                      context,
                      'Rekening $selectedBank ($masked) berhasil ditambahkan!',
                      type: GageToastType.success,
                    );
                  },
                  child: const Text('Simpan Rekening', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                ),
              ),
              const SizedBox(height: 10),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark) {
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? GageTheme.primary : (isDark ? const Color(0xFF1E293B) : Colors.white),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ),
      ),
    );
  }

  // Floating Sheet: Tukar Poin GAGE
  void _showExchangePointsSheet(BuildContext context, WalletProvider wallet) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    GageFloatingSheet.show(
      context: context,
      title: 'Tukar Poin GAGE',
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.stars_rounded, color: Color(0xFFD97706), size: 24),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Poin GAGE Anda',
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${wallet.points} Poin',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Pilih Voucher Diskon yang Ingin Ditukar:',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),

              _buildPointVoucherOption(
                sheetContext: sheetContext,
                wallet: wallet,
                requiredPoints: 50,
                voucherName: 'Gratis Ongkir Xtra s/d Rp7.000',
                desc: 'Bisa digunakan untuk GAGE Food & Shop',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPointVoucherOption(
                sheetContext: sheetContext,
                wallet: wallet,
                requiredPoints: 75,
                voucherName: 'Diskon Kuliner Rp 10.000',
                desc: 'Potongan langsung untuk resto mitra GAGE Food',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _buildPointVoucherOption(
                sheetContext: sheetContext,
                wallet: wallet,
                requiredPoints: 40,
                voucherName: 'Diskon Perjalanan Rp 5.000',
                desc: 'Hemat biaya antar untuk ojek motor GAGE Ride',
                isDark: isDark,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPointVoucherOption({
    required BuildContext sheetContext,
    required WalletProvider wallet,
    required int requiredPoints,
    required String voucherName,
    required String desc,
    required bool isDark,
  }) {
    final canRedeem = wallet.points >= requiredPoints;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: canRedeem ? const Color(0xFFF59E0B) : (isDark ? Colors.white12 : Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  voucherName,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 4),
                Text(
                  '$requiredPoints Poin Cuan GAGE',
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
            onPressed: canRedeem
                ? () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(sheetContext);
                    GageToast.show(
                      context,
                      'Berhasil menukar $requiredPoints poin dengan $voucherName! Kupon langsung terpasang.',
                      type: GageToastType.success,
                    );
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            child: Text(
              canRedeem ? 'Tukar' : 'Poin Kurang',
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // Floating Sheet: Detail Transaksi GAGEPay
  void _showTransactionDetailSheet(BuildContext context, Map<String, dynamic> t) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = t['title'] as String? ?? 'Transaksi GAGEPay';
    final type = (t['type'] as String? ?? '').toUpperCase();
    final amount = t['amount'] as int? ?? 0;
    final status = t['status'] as String? ?? 'BERHASIL';
    final date = t['date'] as String? ?? '';
    final isPlus = type.contains('TOPUP') || type.contains('COMMISSION');
    final trxId = 'TRX-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}-${(amount.hashCode % 9000 + 1000).abs()}';

    GageFloatingSheet.show(
      context: context,
      title: 'Rincian Transaksi',
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isPlus ? const Color(0xFFDCFCE7) : const Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPlus ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isPlus ? const Color(0xFF16A34A) : GageTheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${isPlus ? "+" : "-"}${currencyFormatter.format(amount)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isPlus ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF16A34A),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Divider(color: isDark ? Colors.white12 : Colors.grey.shade200),
              const SizedBox(height: 8),

              _buildDetailRow('Deskripsi', title, isDark),
              const SizedBox(height: 10),
              _buildDetailRow('Waktu', date.isNotEmpty ? date : 'Hari ini', isDark),
              const SizedBox(height: 10),
              _buildDetailRow('Metode', isPlus ? 'QRIS' : 'GAGEPay Saldo', isDark),
              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('ID Transaksi', style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: trxId));
                      HapticFeedback.lightImpact();
                      GageToast.show(context, 'ID Transaksi disalin', type: GageToastType.success);
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            trxId,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.copy_rounded, size: 12, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54)),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
