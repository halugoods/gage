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
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';
import 'package:gage_app/shared/widgets/gage_tap_scale.dart';
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
      'color': const Color(0xFF1E3A8A),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'acc-mandiri',
      'bank': 'Mandiri',
      'label': 'Bank Mandiri',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '9012 4432 8810',
      'maskedNumber': '•••• 8810',
      'color': const Color(0xFF0F172A),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'acc-gopay',
      'bank': 'GoPay',
      'label': 'GoPay E-Wallet',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '0812 3456 7890',
      'maskedNumber': '•••• 7890',
      'color': const Color(0xFF0D9488),
      'icon': Icons.account_balance_wallet_rounded,
    },
    {
      'id': 'acc-bri',
      'bank': 'BRI',
      'label': 'Bank Rakyat Indonesia',
      'holder': 'SITI RAHMAWATI',
      'accountNumber': '0012 9941 2914',
      'maskedNumber': '•••• 2914',
      'color': const Color(0xFF00529C),
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
                onCardSelected: (card) {
                  setState(() => _selectedWithdrawCard = card);
                },
                onManageCardsTap: () => _showAccountSelectionSheet(context),
              ),

              const SizedBox(height: 14),

              // 2. 4 Tombol Aksi Cepat Frameless (Icon 3D MCP Flow Transparan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildQuickAction(
                      imageAsset: 'assets/icons/gagepay/action_topup_3d.png',
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
                      imageAsset: 'assets/icons/gagepay/action_qris_3d.png',
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
                      imageAsset: 'assets/icons/gagepay/action_withdraw_3d.png',
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
                      imageAsset: 'assets/icons/gagepay/action_points_3d.png',
                      icon: Icons.stars_rounded,
                      label: 'Tukar Poin',
                      color: const Color(0xFFD97706),
                      isDark: isDark,
                      onTap: () => _showExchangePointsSheet(context, wallet),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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

              // 4. Header Riwayat Transaksi & Filter Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Riwayat Transaksi',
                    style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold),
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
                      _buildFilterChip('TOPUP', 'Isi Saldo', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('WITHDRAWAL', 'Penarikan', isDark),
                      const SizedBox(width: 8),
                      _buildFilterChip('BELANJA', 'Belanja & Jasa', isDark),
                    ],
                  ),
                ),

              const SizedBox(height: 14),

              // 5. Daftar Transaksi Terkelompok (Modern Grouped Transactions)
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
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredTxs.length,
                  separatorBuilder: (_, idx) => const SizedBox(height: 8),
                  itemBuilder: (ctx, idx) {
                    final t = filteredTxs[idx];
                    final title = t['title'] as String? ?? 'Transaksi GAGEPay';
                    final type = (t['type'] as String? ?? '').toUpperCase();
                    final amount = t['amount'] as int? ?? 0;
                    final status = t['status'] as String? ?? 'BERHASIL';
                    final date = t['date'] as String? ?? '';
                    final isPlus = type.contains('TOPUP') || type.contains('COMMISSION');

                    IconData catIcon = Icons.payment_rounded;
                    Color catColor = const Color(0xFF64748B);
                    if (type.contains('TOPUP')) {
                      catIcon = Icons.add_card_rounded;
                      catColor = const Color(0xFF16A34A);
                    } else if (type.contains('WITHDRAWAL')) {
                      catIcon = Icons.outbox_rounded;
                      catColor = const Color(0xFFEA580C);
                    } else if (title.toLowerCase().contains('dimsum') || title.toLowerCase().contains('food')) {
                      catIcon = Icons.restaurant_rounded;
                      catColor = GageTheme.primary;
                    } else if (title.toLowerCase().contains('ride') || title.toLowerCase().contains('car')) {
                      catIcon = Icons.two_wheeler_rounded;
                      catColor = const Color(0xFF2563EB);
                    }

                    return InkWell(
                      onTap: () => _showTransactionDetailSheet(context, t),
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
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
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '$status • $date',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${isPlus ? "+" : "-"}${currencyFormatter.format(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: isPlus ? const Color(0xFF16A34A) : (isDark ? Colors.white : Colors.black87),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Rincian >',
                                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    required String imageAsset,
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GageTapScale(
      onTap: onTap,
      scaleDown: 0.90,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.asset(
                imageAsset,
                width: 54,
                height: 54,
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 26),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: 0.2,
            ),
          ),
        ],
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
                'Pilih rekening bank atau e-wallet utama Anda untuk penarikan saldo GAGEPay:',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 14),
              ..._userAccounts.map((acc) {
                final isSelected = (_selectedWithdrawCard?['id'] == acc['id']) ||
                    (_selectedWithdrawCard == null && acc['id'] == _userAccounts.first['id']);

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? GageTheme.primary : (isDark ? Colors.white12 : Colors.grey.shade300),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (acc['color'] as Color).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(acc['icon'] as IconData, color: acc['color'] as Color, size: 22),
                    ),
                    title: Text(
                      '${acc['bank']} • ${acc['maskedNumber']}',
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      'a.n. ${acc['holder']} (${acc['accountNumber']})',
                      style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.grey.shade600),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 22)
                        : Icon(Icons.radio_button_off_rounded, color: Colors.grey.shade400, size: 22),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedWithdrawCard = acc);
                      setSheetState(() {});
                      Navigator.pop(ctx);
                      GageToast.show(
                        context,
                        'Rekening aktif: ${acc['bank']} (${acc['maskedNumber']})',
                        type: GageToastType.info,
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 8),
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
                  label: const Text('+ Tambah Rekening Baru', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
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
