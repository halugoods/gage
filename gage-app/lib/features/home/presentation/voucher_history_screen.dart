import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/home/presentation/widgets/gage_ticket_voucher_card.dart';

/// VoucherHistoryScreen
/// Layar penuh riwayat pemakaian voucher kupon di aplikasi GAGE.
/// Menampilkan daftar kupon yang telah digunakan atau kedaluwarsa dengan desain 1:1 kartu tiket menu promo (monokrom).
class VoucherHistoryScreen extends StatefulWidget {
  const VoucherHistoryScreen({super.key});

  @override
  State<VoucherHistoryScreen> createState() => _VoucherHistoryScreenState();
}

class _VoucherHistoryScreenState extends State<VoucherHistoryScreen> {
  String _activeFilter = 'SEMUA'; // 'SEMUA', 'TERPAKAI', 'KEDALUWARSA'

  final List<Map<String, dynamic>> _historyData = [
    {
      'id': 'hist-01',
      'code': 'DISKON50',
      'title': 'Diskon 50% s.d 15RB',
      'service': 'GAGE Food',
      'type': 'order',
      'discountAmount': 15000,
      'status': 'USED',
      'usedAt': '04 Nov 2026',
      'orderNumber': 'GAGE-20261104-001',
      'merchantName': 'Dimsum Sewu Pracimantoro',
    },
    {
      'id': 'hist-02',
      'code': 'ONGKIRGRATIS',
      'title': 'Gratis Ongkir s.d 7RB',
      'service': 'GAGE Food',
      'type': 'delivery',
      'discountAmount': 7000,
      'status': 'USED',
      'usedAt': '04 Nov 2026',
      'orderNumber': 'GAGE-20261104-001',
      'merchantName': 'Dimsum Sewu Pracimantoro',
    },
    {
      'id': 'hist-03',
      'code': 'RIDEHEMAT',
      'title': 'Diskon 4RB',
      'service': 'GAGE Ride',
      'type': 'order',
      'discountAmount': 4000,
      'status': 'USED',
      'usedAt': '02 Nov 2026',
      'orderNumber': 'GAGE-20261102-044',
      'merchantName': 'Ojek Motor Stasiun',
    },
    {
      'id': 'hist-04',
      'code': 'GAJIANOKT',
      'title': 'Cashback s.d 10RB',
      'service': 'GAGE Pay',
      'type': 'order',
      'discountAmount': 10000,
      'status': 'EXPIRED',
      'usedAt': 'Kedaluwarsa 31 Okt 2026',
      'orderNumber': null,
      'merchantName': null,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredList = _historyData.where((item) {
      if (_activeFilter == 'TERPAKAI') return item['status'] == 'USED';
      if (_activeFilter == 'KEDALUWARSA') return item['status'] == 'EXPIRED';
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Riwayat Voucher',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 17,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
        ),
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0.5,
      ),
      body: Column(
        children: [
          // Filter Tabs Full-Rounded Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: isDark ? GageTheme.darkSurface : Colors.white,
            child: Row(
              children: [
                _buildFilterChip('Semua', 'SEMUA', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Terpakai', 'TERPAKAI', isDark),
                const SizedBox(width: 8),
                _buildFilterChip('Kedaluwarsa', 'KEDALUWARSA', isDark),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // List Riwayat Voucher (Menggunakan GageTicketVoucherCard 1:1 Monokrom)
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.history_toggle_off_rounded, size: 54, color: Colors.grey.shade400),
                        const SizedBox(height: 12),
                        Text(
                          'Belum ada riwayat voucher',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final item = filteredList[index];
                      final isUsed = item['status'] == 'USED';
                      final isDelivery = item['type'] == 'delivery';

                      final voucherMap = {
                        'id': item['code'],
                        'code': item['code'],
                        'service': item['service'] ?? 'GAGE Food',
                        'type': item['type'] ?? 'order',
                        'title': item['title'],
                        'discountText': item['title'],
                        'minOrder': isDelivery ? 15000 : 20000,
                        'quantity': 1,
                        'tag': item['code'],
                        'expiry': item['usedAt'] ?? '31 Des 2026',
                        'terms': [
                          'Voucher resmi GAGE Pracimantoro',
                          if (item['orderNumber'] != null) 'Terkait pesanan #${item['orderNumber']}',
                          if (item['merchantName'] != null) 'Merchant: ${item['merchantName']}',
                        ],
                      };

                      return GageTicketVoucherCard(
                        voucher: voucherMap,
                        statusBadge: isUsed ? 'TERPAKAI' : 'KEDALUWARSA',
                        isMonochrome: true,
                        onApply: () {},
                        onTermsTap: () {},
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isDark) {
    final isSelected = _activeFilter == value;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _activeFilter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? GageTheme.primary
                : (isDark ? Colors.white12 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
