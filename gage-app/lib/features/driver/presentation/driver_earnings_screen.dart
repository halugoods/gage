import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/driver_wallet_provider.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';
import 'package:gage_app/features/wallet/presentation/withdraw_sheet.dart';

class DriverEarningsScreen extends StatefulWidget {
  const DriverEarningsScreen({super.key});

  @override
  State<DriverEarningsScreen> createState() => _DriverEarningsScreenState();
}

class _DriverEarningsScreenState extends State<DriverEarningsScreen> {
  final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  final List<Map<String, dynamic>> _weeklyHistory = [
    {'day': 'Min (Hari ini)', 'trips': 5, 'amount': 42500, 'tupo': false},
    {'day': 'Sabtu', 'trips': 9, 'amount': 84000, 'tupo': false},
    {'day': 'Jumat', 'trips': 12, 'amount': 110000, 'tupo': true},
    {'day': 'Kamis', 'trips': 11, 'amount': 92000, 'tupo': true},
    {'day': 'Rabu', 'trips': 7, 'amount': 65000, 'tupo': false},
    {'day': 'Selasa', 'trips': 10, 'amount': 88500, 'tupo': true},
    {'day': 'Senin', 'trips': 8, 'amount': 74000, 'tupo': false},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProv = context.watch<DriverWalletProvider>();
    final balance = walletProv.balance;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        title: const Text(
          'Pendapatan & Dompet',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Kartu Dompet Driver Matte Charcoal & Emas GAGE
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.account_balance_wallet_rounded, color: Color(0xFFFCD34D), size: 18),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Saldo Dompet Mitra',
                              style: TextStyle(fontSize: 12.5, color: Colors.white70, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'GAGE PAY',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      currencyFormatter.format(balance),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: GageTheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              GageWithdrawSheet.show(context);
                            },
                            icon: const Icon(Icons.download_rounded, size: 18),
                            label: const Text('Tarik Saldo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                              padding: const EdgeInsets.symmetric(vertical: 11),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                            },
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Mutasi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Kartu Misi Tupo Harian
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.emoji_events_rounded, color: Color(0xFFD97706), size: 20),
                            ),
                            const SizedBox(width: 10),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Misi Harian & Bonus Tupo',
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                                ),
                                Text(
                                  'Bonus tunai cair instan ke dompet',
                                  style: TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '+Rp 25.000',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: Color(0xFFB45309)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: const LinearProgressIndicator(
                        value: 5 / 10,
                        minHeight: 8,
                        backgroundColor: Color(0xFFE2E8F0),
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Target: 5 dari 10 Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        Text('Sisa 5 order lagi', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // 3. Rekap Mingguan 7 Hari Terakhir
              const Text(
                'Rekap Pendapatan 7 Hari',
                style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _weeklyHistory.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (ctx, idx) {
                  final item = _weeklyHistory[idx];
                  final isTupo = item['tupo'] as bool;

                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['day'],
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                Text(
                                  '${item['trips']} Trip Selesai',
                                  style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                                ),
                                if (isTupo) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'TUPO',
                                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Color(0xFFB45309)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                        Text(
                          currencyFormatter.format(item['amount']),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.accentGreen,
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
      bottomNavigationBar: const DriverBottomNavBar(currentIndex: 2),
    );
  }
}
