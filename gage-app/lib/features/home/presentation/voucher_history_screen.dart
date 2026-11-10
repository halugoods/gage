import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:intl/intl.dart';

/// VoucherHistoryScreen
/// Layar penuh riwayat pemakaian voucher kupon di aplikasi GAGE.
/// Menampilkan daftar kupon yang telah digunakan atau kedaluwarsa beserta invoice pemesanan terkait.
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
      'title': 'Diskon 50% Kuliner Pengguna Baru',
      'service': 'GAGE Food',
      'discountAmount': 15000,
      'status': 'USED',
      'usedAt': '04 Nov 2026, 12:45 WIB',
      'orderNumber': 'GAGE-20261104-001',
      'merchantName': 'Dimsum Sewu Pracimantoro',
    },
    {
      'id': 'hist-02',
      'code': 'ONGKIRGRATIS',
      'title': 'Gratis Ongkir Xtra s/d Rp7.000',
      'service': 'GAGE Food',
      'discountAmount': 7000,
      'status': 'USED',
      'usedAt': '04 Nov 2026, 12:45 WIB',
      'orderNumber': 'GAGE-20261104-001',
      'merchantName': 'Dimsum Sewu Pracimantoro',
    },
    {
      'id': 'hist-03',
      'code': 'RIDEHEMAT',
      'title': 'Potongan Rp4.000 Motor GAGE Ride',
      'service': 'GAGE Ride',
      'discountAmount': 4000,
      'status': 'USED',
      'usedAt': '02 Nov 2026, 08:15 WIB',
      'orderNumber': 'GAGE-20261102-044',
      'merchantName': 'Ojek Motor Stasiun',
    },
    {
      'id': 'hist-04',
      'code': 'GAJIANOKT',
      'title': 'Cashback Spesial Gajian Oktober',
      'service': 'GAGE Pay',
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
    final currencyFmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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

          // List Riwayat Voucher
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

                      final stubGradient = isUsed
                          ? const [Color(0xFF475569), Color(0xFF334155)]
                          : const [Color(0xFF94A3B8), Color(0xFF64748B)];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.03),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Stack(
                            children: [
                              Row(
                                children: [
                                  // Stub Kiri
                                  Container(
                                    width: 78,
                                    constraints: const BoxConstraints(minHeight: 104),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: stubGradient,
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Colors.white.withValues(alpha: 0.2),
                                          ),
                                          child: Icon(
                                            isUsed ? Icons.check_circle_rounded : Icons.timer_off_rounded,
                                            color: Colors.white,
                                            size: 18,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          isUsed ? 'Voucher\nTerpakai' : 'Voucher\nKedaluwarsa',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w800,
                                            height: 1.15,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Garis Perforasi
                                  Container(
                                    width: 1,
                                    constraints: const BoxConstraints(minHeight: 104),
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                  ),

                                  // Konten Kanan
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                item['code'] as String,
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 13.5,
                                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                                ),
                                              ),
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: isUsed
                                                      ? const Color(0xFFDCFCE7)
                                                      : (isDark ? Colors.white10 : Colors.grey.shade200),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  isUsed ? 'TERPAKAI' : 'KEDALUWARSA',
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    fontWeight: FontWeight.w900,
                                                    color: isUsed ? const Color(0xFF16A34A) : Colors.grey.shade600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            item['title'] as String,
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w600,
                                              color: isDark ? Colors.white70 : const Color(0xFF334155),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Hemat ${currencyFmt.format(item['discountAmount'])}',
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              fontWeight: FontWeight.w900,
                                              color: isUsed ? const Color(0xFF16A34A) : Colors.grey.shade500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          if (item['orderNumber'] != null)
                                            Text(
                                              '#${item['orderNumber']} • ${item['merchantName']}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: isDark ? Colors.white54 : Colors.grey.shade500,
                                              ),
                                            ),
                                          Text(
                                            item['usedAt'] as String,
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              color: isDark ? Colors.white38 : Colors.grey.shade400,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // Takik Setengah Lingkaran
                              Positioned(
                                left: 71,
                                top: -7,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: 71,
                                bottom: -7,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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
      onTap: () => setState(() => _activeFilter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? GageTheme.primary
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
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
