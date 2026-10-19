import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';

/// Screen Transaksi & Dompet Mitra Merchant - Tab 2
/// Dashboard transparansi finansial mitra UMKM (Omset Kotor, Komisi 10%, Penarikan Instan).
class MerchantFinanceScreen extends StatefulWidget {
  const MerchantFinanceScreen({super.key});

  @override
  State<MerchantFinanceScreen> createState() => _MerchantFinanceScreenState();
}

class _MerchantFinanceScreenState extends State<MerchantFinanceScreen> {
  int _availableBalance = 485000;
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _recentTransactions = [
    {
      'orderId': 'ORD-9021',
      'time': '12:45 WIB',
      'items': '2x Dimsum Siomay, 1x Es Teh Jumbo',
      'gross': 35000,
      'commission': 3500,
      'net': 31500,
      'status': 'Masuk Saldo',
    },
    {
      'orderId': 'ORD-9018',
      'time': '12:10 WIB',
      'items': '4x Dimsum Rambutan Crispy',
      'gross': 60000,
      'commission': 6000,
      'net': 54000,
      'status': 'Masuk Saldo',
    },
    {
      'orderId': 'ORD-9015',
      'time': '11:30 WIB',
      'items': '1x Paket Hemat Berdua',
      'gross': 45000,
      'commission': 4500,
      'net': 40500,
      'status': 'Masuk Saldo',
    },
    {
      'orderId': 'ORD-9011',
      'time': '10:50 WIB',
      'items': '3x Dimsum Mozzarella Keju',
      'gross': 54000,
      'commission': 5400,
      'net': 48600,
      'status': 'Masuk Saldo',
    },
    {
      'orderId': 'ORD-9008',
      'time': '10:15 WIB',
      'items': '2x Dimsum Udang Jamur',
      'gross': 32000,
      'commission': 3200,
      'net': 28800,
      'status': 'Masuk Saldo',
    },
  ];

  void _showWithdrawModal() {
    HapticFeedback.lightImpact();
    final amountCtrl = TextEditingController(text: _availableBalance.toString());
    bool isProcessing = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Tarik Saldo Instan Mitra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                'Dana langsung ditransfer ke rekening bank tanpa potongan biaya admin.',
                style: TextStyle(fontSize: 12, color: GageTheme.textSecondary),
              ),
              const SizedBox(height: 16),

              // Rekening Tujuan
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.account_balance_rounded, color: GageTheme.primary, size: 24),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank Central Asia (BCA)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                          Text('0188-2938-12 • a.n Dimsum Sewu Praci', style: TextStyle(fontSize: 11.5, color: GageTheme.textSecondary)),
                        ],
                      ),
                    ),
                    Icon(Icons.check_circle_rounded, color: GageTheme.accentGreen, size: 18),
                  ],
                ),
              ),

              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Nominal Penarikan',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  helperText: 'Saldo dapat ditarik: ${currencyFormatter.format(_availableBalance)}',
                ),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: isProcessing
                      ? null
                      : () async {
                          final num = int.tryParse(amountCtrl.text) ?? 0;
                          if (num <= 0 || num > _availableBalance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Nominal tidak valid atau melebihi saldo.')),
                            );
                            return;
                          }

                          final messenger = ScaffoldMessenger.of(context);
                          final nav = Navigator.of(ctx);

                          setModalState(() => isProcessing = true);
                          await Future.delayed(const Duration(milliseconds: 700));

                          if (!mounted) return;
                          setState(() {
                            _availableBalance -= num;
                          });
                          nav.pop();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text('Penarikan ${currencyFormatter.format(num)} berhasil diproses ke rekening BCA.'),
                              backgroundColor: GageTheme.accentGreen,
                            ),
                          );
                        },
                  child: isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Konfirmasi & Tarik Dana', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'Transaksi & Dompet Mitra',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Kartu Dompet Mitra (Matte Charcoal & Gold)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'SALDO DOMPET MITRA',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Colors.white70),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 12, color: Colors.amber),
                            SizedBox(width: 4),
                            Text('Settlement Otomatis', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    currencyFormatter.format(_availableBalance),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 11),
                          ),
                          icon: const Icon(Icons.arrow_upward_rounded, size: 16, color: Colors.white),
                          label: const Text('Tarik Saldo Instan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                          onPressed: _showWithdrawModal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 2. Ringkasan Omset Hari Ini (Transparent 4-Box)
            const Text(
              'Performa Penjualan Hari Ini',
              style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    label: 'Omset Kotor',
                    value: 'Rp 650.000',
                    color: const Color(0xFF2563EB),
                    icon: Icons.storefront_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    label: 'Total Pesanan',
                    value: '18 Pesanan',
                    color: Colors.orange.shade800,
                    icon: Icons.receipt_long_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    label: 'MDR Platform (10%)',
                    value: '-Rp 65.000',
                    color: Colors.red.shade700,
                    icon: Icons.percent_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricBox(
                    label: 'Bersih Diterima',
                    value: 'Rp 585.000',
                    color: GageTheme.accentGreen,
                    icon: Icons.savings_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),

            // 3. Riwayat Transaksi Per Order
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Riwayat Transaksi Harian',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
                ),
                Text(
                  '${_recentTransactions.length} Transaksi',
                  style: const TextStyle(fontSize: 12, color: GageTheme.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (ctx, idx) {
                final tx = _recentTransactions[idx];

                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            tx['orderId'] as String,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          ),
                          Text(
                            tx['time'] as String,
                            style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tx['items'] as String,
                        style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Kotor: ${currencyFormatter.format(tx['gross'])}',
                                style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MDR: -${currencyFormatter.format(tx['commission'])}',
                                style: TextStyle(fontSize: 10.5, color: Colors.red.shade400),
                              ),
                            ],
                          ),
                          Text(
                            '+${currencyFormatter.format(tx['net'])}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              color: GageTheme.accentGreen,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildMetricBox({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: GageTheme.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
          ),
        ],
      ),
    );
  }
}
