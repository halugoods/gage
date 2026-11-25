import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/wallet/presentation/withdraw_sheet.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_receive_screen.dart';
import 'package:gage_app/features/wallet/presentation/gagepay_transfer_screen.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Tab 4: GagePay Mitra Usaha GAGE (1:1 Paritas Customer Portal)
/// Dompet kas operasional toko:
/// - Saldo Siap Ditarik (Penjualan Makanan GAGE Food)
/// - Penarikan Dana Instan ke Bank BRI / BCA / Mandiri via GageWithdrawSheet
/// - Tampilkan QRIS Kasir Toko Dinamis untuk Pembayaran Offline di Toko
/// - Transfer Saldo GagePay & Riwayat Mutasi Lengkap
class GageMerchantGagePayTab extends StatefulWidget {
  final NumberFormat currencyFormatter;

  const GageMerchantGagePayTab({
    super.key,
    required this.currencyFormatter,
  });

  @override
  State<GageMerchantGagePayTab> createState() => _GageMerchantGagePayTabState();
}

class _GageMerchantGagePayTabState extends State<GageMerchantGagePayTab> {
  int _activeFilter = 0; // 0: Semua, 1: Hasil Penjualan, 2: Penarikan Bank
  final List<String> _filters = ['Semua', 'Hasil Penjualan', 'Penarikan Bank'];

  final List<Map<String, dynamic>> _mutations = [
    {
      'id': 'mut-01',
      'title': 'Pesanan Selesai #101',
      'subtitle': 'Dimsum Ayam Mix Original (2x)',
      'date': 'Hari ini, 10:45 WIB',
      'amount': 27000,
      'isIncome': true,
      'category': 'order',
      'status': 'BERHASIL',
    },
    {
      'id': 'mut-02',
      'title': 'Pesanan Selesai #098',
      'subtitle': 'Dimsum Mozzarella Kukus (1x)',
      'date': 'Hari ini, 09:12 WIB',
      'amount': 15000,
      'isIncome': true,
      'category': 'order',
      'status': 'BERHASIL',
    },
    {
      'id': 'mut-03',
      'title': 'Penarikan Dana ke Bank BRI',
      'subtitle': 'Rek. 0012-9941-2914 a.n Dimsum Sewu',
      'date': 'Kemarin, 21:30 WIB',
      'amount': 100000,
      'isIncome': false,
      'category': 'withdraw',
      'status': 'BERHASIL',
    },
    {
      'id': 'mut-04',
      'title': 'Pesanan Selesai #087',
      'subtitle': 'Combo Sewu Hemat (3x)',
      'date': 'Kemarin, 19:15 WIB',
      'amount': 45000,
      'isIncome': true,
      'category': 'order',
      'status': 'BERHASIL',
    },
  ];

  List<Map<String, dynamic>> _getFilteredMutations() {
    switch (_activeFilter) {
      case 1:
        return _mutations.where((m) => m['category'] == 'order').toList();
      case 2:
        return _mutations.where((m) => m['category'] == 'withdraw').toList();
      case 0:
      default:
        return _mutations;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<MerchantOrderProvider>();

    // Hitung total saldo siap ditarik toko dari omset selesai
    final completedOrders = provider.orders.where((o) => o.status == 'COMPLETED').toList();
    final totalCompletedNet = completedOrders.fold<int>(0, (sum, o) => sum + o.merchantNetPayout);
    final displayBalance = totalCompletedNet > 0 ? totalCompletedNet : 187000;

    final filteredMutations = _getFilteredMutations();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Hero Card Saldo GagePay Kasir Toko
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.40 : 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'GagePay Toko',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF22C55E), size: 12),
                          SizedBox(width: 4),
                          Text(
                            'Akun Terverifikasi',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Saldo Siap Ditarik',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.currencyFormatter.format(displayBalance),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 18),

                // Tombol Aksi Cepat Dompet
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          GageWithdrawSheet.show(context);
                        },
                        icon: const Icon(Icons.arrow_upward_rounded, size: 16),
                        label: const Text('Tarik Dana', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.15),
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          elevation: 0,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const GagePayReceiveScreen(
                                accountNumber: '9012 4432 8810',
                                userName: 'DIMSUM SEWU KASIR',
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.qr_code_2_rounded, size: 16),
                        label: const Text('QRIS Kasir', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GagePayTransferScreen(),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // 2. Rekening Bank Pencairan Terdaftar
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.account_balance_rounded, color: Color(0xFF00529C), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Rekening Utama Bank BRI',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '0012-9941-2914 • a.n Dimsum Sewu',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => GageWithdrawSheet.show(context),
                  child: const Text('Ubah', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // 3. Mutasi Penjualan & Transaksi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Transaksi Toko',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () => GageToast.show(context, 'Menampilkan seluruh mutasi toko'),
                child: const Text('Lihat Semua >', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: GageTheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter Pills Kapsul Mutasi
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isSelected = _activeFilter == idx;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeFilter = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[idx],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // List Mutasi
          ...filteredMutations.map((m) {
            final isIncome = m['isIncome'] == true;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isIncome
                          ? const Color(0xFFDCFCE7)
                          : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m['title'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['subtitle'],
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          m['date'],
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isIncome ? '+' : '-'} ${widget.currencyFormatter.format(m['amount'])}',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      color: isIncome ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
