import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

class MembershipScreen extends StatefulWidget {
  final String initialTier;

  const MembershipScreen({
    super.key,
    this.initialTier = 'plus',
  });

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  late String _selectedTier; // 'plus' or 'max'
  String _selectedDuration = '1 Bulan'; // '1 Bulan', '3 Bulan', '1 Tahun'
  String _currentActivePlan = 'GAGE Basic (Gratis)';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier;
    _loadMembership();
  }

  Future<void> _loadMembership() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  int _getPriceFor(String tier, String duration) {
    if (tier == 'plus') {
      if (duration == '1 Bulan') return 19900;
      if (duration == '3 Bulan') return 49900;
      return 179000;
    } else {
      if (duration == '1 Bulan') return 39900;
      if (duration == '3 Bulan') return 99900;
      return 359000;
    }
  }

  String _getPerMonthNote(String tier, String duration) {
    if (tier == 'plus') {
      if (duration == '1 Bulan') return '/bulan';
      if (duration == '3 Bulan') return '/3 bulan (Rp 16.633/bln)';
      return '/tahun (Rp 14.916/bln)';
    } else {
      if (duration == '1 Bulan') return '/bulan';
      if (duration == '3 Bulan') return '/3 bulan (Rp 33.300/bln)';
      return '/tahun (Rp 29.916/bln)';
    }
  }

  int get _calculatedPrice => _getPriceFor(_selectedTier, _selectedDuration);

  void _showQrisPaymentSheet() {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalAmount = _calculatedPrice;
    final planTitle = _selectedTier == 'plus' ? 'GAGE Plus' : 'GAGE Max';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrisPaymentSheet(
        planTitle: planTitle,
        duration: _selectedDuration,
        totalAmount: totalAmount,
        currencyFormatter: currencyFormatter,
        onPaymentSuccess: () {
          setState(() {
            _currentActivePlan = '$planTitle ($_selectedDuration)';
          });
          Navigator.pop(ctx);
          _showSuccessDialog(planTitle);
        },
      ),
    );
  }

  void _showSuccessDialog(String planTitle) {
    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: Color(0xFFE8F5E9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat! Anda Kini $planTitle',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Text(
              'Langganan $planTitle berhasil diaktifkan. Nikmati potongan ongkir, diskon kuliner, dan keuntungan eksklusif lainnya sekarang!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.5, color: Colors.black54, height: 1.3),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dlgCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Mulai Nikmati Keuntungan', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text('Langganan GAGE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembership,
        color: GageTheme.primary,
        child: _isLoading
            ? const GageSkeletonMembership()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // 1. Hero Header Banner (Luxury Emerald & Gold VIP Card)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Image.asset(
                        'assets/images/membership_header_card.png',
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Color(0xFF0A3D24), Color(0xFF021B10)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: const [
                                    BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 1)),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.workspace_premium_rounded, size: 14, color: Colors.black87),
                                    SizedBox(width: 4),
                                    Text(
                                      'GAGE MEMBERSHIP VIP',
                                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w900, color: Colors.black87),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.35),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5), width: 1),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFFFFD54F)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Status: $_currentActivePlan',
                                      style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Pasti dapet diskon tiap hari.\nMakin sering pesan, makin untung!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              height: 1.25,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: Color(0xFFFFD54F), size: 14),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Bebas ongkir kuliner & diskon perjalanan tanpa syarat rumit.',
                                  style: TextStyle(color: Colors.white70, fontSize: 11.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 4),

            // 2. Pilih Paket (GAGE Plus vs GAGE Max)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Paket Langganan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      // Card GAGE Plus
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTier = 'plus'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedTier == 'plus' ? GageTheme.primary : Colors.grey.shade200,
                                width: _selectedTier == 'plus' ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedTier == 'plus'
                                      ? GageTheme.primary.withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                                      'GAGE Plus',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    if (_selectedTier == 'plus')
                                      const Icon(Icons.check_circle_rounded, color: GageTheme.primary, size: 18)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Paling Populer 🔥',
                                    style: TextStyle(color: GageTheme.primary, fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currencyFormatter.format(_getPriceFor('plus', _selectedDuration)),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                                ),
                                Text(
                                  _getPerMonthNote('plus', _selectedDuration),
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '• Diskon ongkir s.d Rp 10rb\n• 4x Voucher Diskon 25%\n• Bebas biaya layanan',
                                  style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Card GAGE Max
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTier = 'max'),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedTier == 'max' ? const Color(0xFFE52320) : Colors.grey.shade200,
                                width: _selectedTier == 'max' ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: _selectedTier == 'max'
                                      ? const Color(0xFFE52320).withValues(alpha: 0.15)
                                      : Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
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
                                      'GAGE Max',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black87),
                                    ),
                                    if (_selectedTier == 'max')
                                      const Icon(Icons.check_circle_rounded, color: Color(0xFFE52320), size: 18)
                                    else
                                      Icon(Icons.circle_outlined, color: Colors.grey.shade400, size: 18),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFEBEE),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'VIP Sultan 👑',
                                    style: TextStyle(color: Color(0xFFE52320), fontSize: 9.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  currencyFormatter.format(_getPriceFor('max', _selectedDuration)),
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFE52320)),
                                ),
                                Text(
                                  _getPerMonthNote('max', _selectedDuration),
                                  style: const TextStyle(fontSize: 10.5, color: Colors.black54),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '• GRATIS ONGKIR Tanpa Batas\n• Diskon Kuliner 35%\n• Jalur Ekspres VIP Driver',
                                  style: TextStyle(fontSize: 11, color: Colors.black87, height: 1.35),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // 3. Durasi Berlangganan
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pilih Durasi Langganan',
                    style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildDurationChip('1 Bulan', 'Normal'),
                      const SizedBox(width: 8),
                      _buildDurationChip('3 Bulan', 'Hemat 15%'),
                      const SizedBox(width: 8),
                      _buildDurationChip('1 Tahun', 'Hemat 30%'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Tabel Perbandingan Keuntungan (Basic vs Plus vs Max)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.table_chart_rounded, size: 18, color: GageTheme.primary),
                      SizedBox(width: 6),
                      Text(
                        'Tabel Perbandingan Keuntungan',
                        style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.0),
                        1: FlexColumnWidth(1.4),
                        2: FlexColumnWidth(1.6),
                        3: FlexColumnWidth(1.6),
                      },
                      border: TableBorder(
                        horizontalInside: BorderSide(color: Colors.grey.shade100, width: 1),
                      ),
                      children: [
                        // Header
                        TableRow(
                          decoration: BoxDecoration(color: Colors.grey.shade50),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              child: Text('Keuntungan', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black54)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              child: Text('Basic', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              child: Text('Plus', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                              child: Text('Max', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFE52320))),
                            ),
                          ],
                        ),
                        // Row 1: Diskon Ongkir
                        _buildTableRow('Diskon Ongkir', 'Rp 0', 's.d Rp 10rb', 'Gratis (Free)'),
                        // Row 2: Diskon Kuliner
                        _buildTableRow('Voucher Makanan', 'Standar', '4x @25%', 'Bebas @35%'),
                        // Row 3: Biaya Layanan
                        _buildTableRow('Biaya Layanan', 'Rp 2.000', 'Gratis (Rp0)', 'Gratis (Rp0)'),
                        // Row 4: Prioritas Driver
                        _buildTableRow('Prioritas Driver', 'Standar', 'Tinggi', 'Ekspres VIP'),
                        // Row 5: CS Support
                        _buildTableRow('Customer Care', 'Jam Kerja', 'Fast Priority', 'Dedikasi 24/7'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 100), // padding bottom for floating bar
          ],
        ),
      ),
    ),

      // 5. Bottom Sticky Bar & Checkout CTA
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -3)),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Langganan ($_selectedDuration)',
                      style: const TextStyle(fontSize: 11, color: Colors.black54),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currencyFormatter.format(_calculatedPrice),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _showQrisPaymentSheet,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Bayar Sekarang', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                    SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDurationChip(String duration, String badge) {
    final isSel = _selectedDuration == duration;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDuration = duration),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel ? const Color(0xFFFFEBEE) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? GageTheme.primary : Colors.grey.shade300,
              width: isSel ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                duration,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isSel ? GageTheme.primary : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                badge,
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w600,
                  color: isSel ? GageTheme.primary : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(String feature, String basic, String plus, String max) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Text(feature, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Text(basic, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, color: Colors.black54)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Text(plus, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: GageTheme.primary)),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
          child: Text(max, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFE52320))),
        ),
      ],
    );
  }
}

// -------------------------------------------------------------
// QRIS Payment Modal Bottom Sheet ("Cukup bayar pakai QRIS")
// -------------------------------------------------------------
class _QrisPaymentSheet extends StatefulWidget {
  final String planTitle;
  final String duration;
  final int totalAmount;
  final NumberFormat currencyFormatter;
  final VoidCallback onPaymentSuccess;

  const _QrisPaymentSheet({
    required this.planTitle,
    required this.duration,
    required this.totalAmount,
    required this.currencyFormatter,
    required this.onPaymentSuccess,
  });

  @override
  State<_QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends State<_QrisPaymentSheet> {
  int _secondsLeft = 899; // 14:59 timer
  Timer? _timer;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formattedTimer {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _checkPayment() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    setState(() => _isChecking = false);
    widget.onPaymentSuccess();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pembayaran Langganan',
                    style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.planTitle} (${widget.duration})',
                    style: const TextStyle(fontSize: 12, color: GageTheme.primary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(height: 20),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Total Tagihan Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran:', style: TextStyle(fontSize: 13, color: Colors.black54)),
                        Text(
                          widget.currencyFormatter.format(widget.totalAmount),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: GageTheme.primary),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Narasi Instruksi (Sesuai arahan: "cukup bayar pakai QRIS")
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_scanner_rounded, size: 18, color: GageTheme.primary),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Cukup bayar pakai QRIS dari m-Banking atau E-Wallet apa saja.',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: GageTheme.primary),
                          ),
                        ),
                        Text(
                          _formattedTimer,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // QRIS Card Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.grey.shade300, width: 1.2),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4)),
                      ],
                    ),
                    child: Column(
                      children: [
                        // QRIS Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black87,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'QRIS',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
                              ),
                            ),
                            const Text(
                              'GAGE INDONESIA',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // QRIS Matrix Canvas / Visual
                        Container(
                          width: 200,
                          height: 200,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: CustomPaint(
                            painter: _QrisMatrixPainter(),
                          ),
                        ),

                        const SizedBox(height: 12),
                        const Text(
                          'NMID: ID1020268899210',
                          style: TextStyle(fontSize: 10.5, color: Colors.black45, letterSpacing: 0.5),
                        ),
                        const Text(
                          'Mendukung: BCA, Mandiri, BRI, BNI, GoPay, OVO, ShopeePay, Dana, LinkAja',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isChecking ? null : _checkPayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isChecking
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Cek Status Pembayaran',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// Visual QR Matrix Painter
class _QrisMatrixPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black87;
    final w = size.width;
    final h = size.height;

    // Draw 3 corner positioning squares (QR standard)
    void drawCornerSquare(double left, double top) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left, top, 46, 46), const Radius.circular(8)),
        paint,
      );
      final whitePaint = Paint()..color = Colors.white;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left + 8, top + 8, 30, 30), const Radius.circular(4)),
        whitePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(left + 15, top + 15, 16, 16), const Radius.circular(3)),
        paint,
      );
    }

    drawCornerSquare(6, 6);
    drawCornerSquare(w - 52, 6);
    drawCornerSquare(6, h - 52);

    // Decorative QR data modules
    final dataPaint = Paint()..color = Colors.black87;
    const step = 9.0;
    for (double x = 10; x < w - 10; x += step) {
      for (double y = 10; y < h - 10; y += step) {
        // Skip corners
        if (x < 58 && y < 58) continue;
        if (x > w - 58 && y < 58) continue;
        if (x < 58 && y > h - 58) continue;

        // Pattern generator hash
        final v = ((x * 13 + y * 29).toInt()) % 11;
        if (v < 5) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromLTWH(x, y, 6.5, 6.5), const Radius.circular(1.5)),
            dataPaint,
          );
        }
      }
    }

    // Centered GAGE Logo Dot
    final centerPaint = Paint()..color = GageTheme.primary;
    canvas.drawCircle(Offset(w / 2, h / 2), 16, centerPaint);
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'G',
        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
      ),
      textDirection: ui.TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset(w / 2 - textPainter.width / 2, h / 2 - textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
