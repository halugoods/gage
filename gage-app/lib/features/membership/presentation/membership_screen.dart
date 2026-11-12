import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_shimmer.dart';

/// MembershipScreen - Desain Redesain Mewah Berbasis Model Bisnis Riil
/// - Mendukung tema dinamis (Light Mode & Dark Mode) tanpa hardcode paksaan obsidian
/// - 2 Tier Langganan Strategis: **GAGE Plus** vs **GAGE Max**
/// - Parameter Kuota Voucher & Pricing sesuai Laporan Bisnis Konsultan Senior:
///   * GAGE Plus: 900 voucher (Rp 19.900 / 30 Hari, Rp 49.900 / 90 Hari, Rp 179.000 / 1 Thn)
///   * GAGE Max: 2.000 voucher (Rp 39.900 / 30 Hari, Rp 99.900 / 90 Hari, Rp 359.000 / 1 Thn)
/// - Durasi Pinterest-style 3 Kartu (30 Hari, 90 Hari [Best Value], 1 Tahun)
/// - Ticking Countdown Timer ("Promo Berakhir Dalam: 00 : 11 : 24 : 20")
/// - Tiket Perforasi Gojek PLUS dengan Notch Melingkar & Expandable Rincian Ketentuan
/// - Sticky Bottom Bar dengan Rekap Hemat & Tombol Langganan
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
  // 'plus' atau 'max'
  late String _selectedTier;

  // Durasi: '30 Hari', '90 Hari', '1 Tahun'
  String _selectedDuration = '90 Hari';
  String _currentActivePlan = 'GAGE Basic (Gratis)';
  bool _isLoading = true;

  // Countdown timer state (Pinterest reference: 00 : 11 : 24 : 20)
  late Timer _countdownTimer;
  int _remainingSeconds = 11 * 3600 + 24 * 60 + 20;

  // Expanded voucher items - Default tertutup seluruhnya
  final Set<String> _expandedItems = <String>{};

  // Pilihan metode pembayaran interaktif
  String _selectedPaymentMethod = 'GAGEPay (Saldo Rp 50.000)';

  @override
  void initState() {
    super.initState();
    _selectedTier = widget.initialTier.toLowerCase().contains('max') ? 'max' : 'plus';
    _loadMembership();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadMembership() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 250));
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // ==========================================================================
  // PRICING MATRIX BERDASARKAN TIER & DURASI
  // ==========================================================================
  int get _originalPrice {
    if (_selectedTier == 'max') {
      switch (_selectedDuration) {
        case '30 Hari':
          return 59900;
        case '90 Hari':
          return 149900;
        case '1 Tahun':
          return 599000;
        default:
          return 149900;
      }
    } else {
      switch (_selectedDuration) {
        case '30 Hari':
          return 29900;
        case '90 Hari':
          return 74900;
        case '1 Tahun':
          return 299000;
        default:
          return 74900;
      }
    }
  }

  int get _calculatedPrice {
    if (_selectedTier == 'max') {
      switch (_selectedDuration) {
        case '30 Hari':
          return 39900; // hemat s.d. 350rb
        case '90 Hari':
          return 99900; // Best Value - 33.300/bln
        case '1 Tahun':
          return 359000; // Ultimate - 29.916/bln
        default:
          return 99900;
      }
    } else {
      switch (_selectedDuration) {
        case '30 Hari':
          return 19900; // hemat s.d. 150rb
        case '90 Hari':
          return 49900; // Best Value - 16.633/bln
        case '1 Tahun':
          return 179000; // Super Hemat - 14.916/bln
        default:
          return 49900;
      }
    }
  }

  int get _discountAmount => _originalPrice - _calculatedPrice;

  String get _tierDisplayName => _selectedTier == 'max' ? 'GAGE MAX' : 'GAGE PLUS';

  // Identitas Warna Resmi GAGE: Merah (#E52320) & Crimson VIP (#DC2626)
  Color get _tierPrimaryColor =>
      _selectedTier == 'max' ? const Color(0xFFDC2626) : const Color(0xFFE52320);

  Color get _tierAccentColor =>
      _selectedTier == 'max' ? const Color(0xFFF59E0B) : const Color(0xFFE52320);

  void _showPaymentMethodSelector(BuildContext context) {
    HapticFeedback.lightImpact();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);

    final paymentMethods = [
      {
        'title': 'GAGEPay (Saldo Rp 50.000)',
        'subtitle': 'Cepat, praktis, cashback koin 2x',
        'icon': Icons.account_balance_wallet_rounded,
        'badge': 'Rekomendasi',
      },
      {
        'title': 'QRIS Instan',
        'subtitle': 'GoPay, OVO, Dana, ShopeePay, BCA',
        'icon': Icons.qr_code_scanner_rounded,
        'badge': null,
      },
      {
        'title': 'Transfer Virtual Account',
        'subtitle': 'BCA, Mandiri, BRI, BNI (Bebas Biaya)',
        'icon': Icons.account_balance_rounded,
        'badge': null,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Pilih Metode Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                ...paymentMethods.map((pm) {
                  final titleStr = pm['title'] as String;
                  final isSelected = _selectedPaymentMethod.startsWith(titleStr.split(' (')[0]);
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE52320).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(pm['icon'] as IconData, color: const Color(0xFFE52320), size: 20),
                    ),
                    title: Row(
                      children: [
                        Flexible(
                          child: Text(
                            pm['title'] as String,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textPrimary,
                            ),
                          ),
                        ),
                        if (pm['badge'] != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE52320).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              pm['badge'] as String,
                              style: const TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFE52320),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      pm['subtitle'] as String,
                      style: TextStyle(fontSize: 11.5, color: textSecondary),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded, color: Color(0xFFE52320), size: 20)
                        : null,
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedPaymentMethod = pm['title'] as String;
                      });
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQrisPaymentSheet() {
    HapticFeedback.mediumImpact();
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final totalAmount = _calculatedPrice;
    final planTitle = _tierDisplayName;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _QrisPaymentSheet(
        planTitle: planTitle,
        tierKey: _selectedTier,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final voucherText =
        _selectedTier == 'max' ? '2.000 voucher diskon' : '900 voucher diskon';

    showDialog(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: _tierAccentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle_rounded, color: _tierAccentColor, size: 42),
            ),
            const SizedBox(height: 16),
            Text(
              'Selamat! Anda Kini Member $planTitle',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paket $_selectedDuration aktif. Nikmati $voucherText, prioritas driver, dan keuntungan eksklusif di ekosistem GAGE!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white70 : Colors.black87,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dlgCtx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _tierPrimaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                ),
                child: const Text('Mulai Nikmati Keuntungan',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currencyFormatter =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    // Formatter countdown: 00 : HH : MM : SS
    final hours = (_remainingSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_remainingSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');

    // Palet warna adaptif
    final bgColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Langganan $_tierDisplayName',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textPrimary,
          ),
        ),
        backgroundColor: bgColor,
        foregroundColor: textPrimary,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _tierAccentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _tierAccentColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, size: 14, color: _tierAccentColor),
                const SizedBox(width: 4),
                Text(
                  _currentActivePlan.contains('PLUS') || _currentActivePlan.contains('MAX')
                      ? 'VIP AKTIF'
                      : 'BASIC',
                  style: TextStyle(
                    color: _tierAccentColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadMembership,
        color: _tierPrimaryColor,
        child: _isLoading
            ? const GageSkeletonMembership()
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // =========================================================
                    // 1. TIER SELECTOR: GAGE PLUS vs GAGE MAX (Segmented Pill)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          children: [
                            // Tab GAGE Plus (GAGE Red)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTier = 'plus');
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _selectedTier == 'plus'
                                        ? GageTheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: _selectedTier == 'plus'
                                        ? [
                                            BoxShadow(
                                              color: GageTheme.primary.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.stars_rounded,
                                        size: 16,
                                        color: _selectedTier == 'plus'
                                            ? Colors.white
                                            : (isDark ? Colors.white60 : Colors.black54),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GAGE Plus',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: _selectedTier == 'plus'
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),

                            // Tab GAGE Max (Crimson VIP)
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedTier = 'max');
                                },
                                borderRadius: BorderRadius.circular(999),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(vertical: 9),
                                  decoration: BoxDecoration(
                                    color: _selectedTier == 'max'
                                        ? GageTheme.primary
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(999),
                                    boxShadow: _selectedTier == 'max'
                                        ? [
                                            BoxShadow(
                                              color: GageTheme.primary.withValues(alpha: 0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.workspace_premium_rounded,
                                        size: 16,
                                        color: _selectedTier == 'max'
                                            ? Colors.amber
                                            : (isDark ? Colors.white60 : Colors.black54),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'GAGE Max',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: _selectedTier == 'max'
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: _selectedTier == 'max'
                                              ? Colors.amber
                                              : Colors.amber.shade200,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'VIP',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.w900,
                                            color: _selectedTier == 'max'
                                                ? Colors.black87
                                                : Colors.amber.shade900,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // =========================================================
                    // 2. HERO HEADER: Value Proposition Berdasarkan Paket
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            _selectedTier == 'max'
                                ? 'Diskon s.d. 25rb tanpa batas, Rp 0 Biaya Layanan & VIP Driver Dispatch!'
                                : 'Pasti dapet diskon s.d. 12rb di setiap transaksi. Yuk, langganan!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedTier == 'max'
                                ? 'Paket terlengkap untuk Power User & UMKM: 2.000 voucher, 2x poin cuan & Layanan CS Prioritas 24/7.'
                                : 'Paket hemat untuk komuter harian: 900 voucher, 1.2x poin cuan & diskon 50% admin fee.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // =========================================================
                    // 3. PINTEREST-STYLE 3 DURATION CARDS
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          // 30 Hari
                          _buildDurationCard(
                            isDark: isDark,
                            duration: '30 Hari',
                            topBadge: 'POPULER',
                            badgeColor: const Color(0xFF3B82F6),
                            priceFormatted: _selectedTier == 'max' ? 'Rp 39.900' : 'Rp 19.900',
                            subRate: _selectedTier == 'max' ? 'Rp 9.975/mgg' : 'Rp 4.975/mgg',
                            isSelected: _selectedDuration == '30 Hari',
                          ),
                          const SizedBox(width: 8),
                          // 90 Hari (Best Value)
                          _buildDurationCard(
                            isDark: isDark,
                            duration: '90 Hari',
                            topBadge: 'BEST VALUE 🔥',
                            badgeColor: _tierAccentColor,
                            priceFormatted: _selectedTier == 'max' ? 'Rp 99.900' : 'Rp 49.900',
                            subRate: _selectedTier == 'max' ? 'Rp 7.680/mgg' : 'Rp 3.830/mgg',
                            isSelected: _selectedDuration == '90 Hari',
                            isFeatured: true,
                          ),
                          const SizedBox(width: 8),
                          // 1 Tahun (Hemat Maksimal)
                          _buildDurationCard(
                            isDark: isDark,
                            duration: '1 Tahun',
                            topBadge: _selectedTier == 'max' ? 'HEMAT 65%' : 'HEMAT 60%',
                            badgeColor: const Color(0xFFF59E0B),
                            priceFormatted: _selectedTier == 'max' ? 'Rp 359.000' : 'Rp 179.000',
                            subRate: _selectedTier == 'max' ? 'Rp 6.900/mgg' : 'Rp 3.440/mgg',
                            isSelected: _selectedDuration == '1 Tahun',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // =========================================================
                    // 4. COUNTDOWN URGENCY BOX (Pinterest Reference)
                    // =========================================================
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 15, color: Color(0xFFF59E0B)),
                            const SizedBox(width: 8),
                            Text(
                              'Promo Berakhir Dalam:',
                              style: TextStyle(
                                color: textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildTimerBox(isDark, '00'),
                            Text(' : ', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                            _buildTimerBox(isDark, hours),
                            Text(' : ', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                            _buildTimerBox(isDark, minutes),
                            Text(' : ', style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                            _buildTimerBox(isDark, seconds),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // =========================================================
                    // 5. GOJEK PLUS VOUCHER BUNDLE CARDS (900 vs 2.000 Kuota)
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Voucher & Keuntungan $_tierDisplayName',
                                style: TextStyle(
                                  color: textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _tierAccentColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _selectedTier == 'max'
                                      ? 'Total 2.000 Voucher'
                                      : 'Total 900 Voucher',
                                  style: TextStyle(
                                    color: _tierAccentColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Card 1: GAGE Food
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'food',
                            icon: Icons.restaurant_rounded,
                            iconColor: const Color(0xFFE52320),
                            serviceName: 'GAGE Food',
                            title: _selectedTier == 'max'
                                ? 'Diskon hingga 25.000'
                                : 'Diskon hingga 12.000',
                            tagline: 'Jajan yang enak biar mood enak',
                            voucherCount: _selectedTier == 'max' ? '700 voucher' : '300 voucher',
                            details: _selectedTier == 'max'
                                ? [
                                    'Diskon s.d. 25rb untuk min. pembelian 60rb di resto berlogo GAGE MAX.',
                                    'Diskon ongkir 10rb tanpa minimal belanja setiap hari.',
                                    'Berlaku hingga 8 transaksi per hari (700 voucher selama periode).',
                                    'Prioritas pesanan dapur diproses duluan oleh resto mitra.',
                                  ]
                                : [
                                    'Diskon hingga 10rb untuk min. pembelian 40rb di resto mitra GAGE PLUS.',
                                    'Diskon hingga 12rb untuk min. pembelian 80rb di resto mitra pilihan.',
                                    'Berlaku untuk pengiriman Express & Reguler (300 voucher per periode).',
                                  ],
                          ),
                          const SizedBox(height: 10),

                          // Card 2: GAGE Gratis Ongkir
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'ongkir',
                            icon: Icons.local_shipping_rounded,
                            iconColor: const Color(0xFFE52320),
                            serviceName: 'GAGE Gratis Ongkir',
                            title: _selectedTier == 'max'
                                ? 'Voucher Gratis Ongkir s.d. 20.000'
                                : 'Voucher Gratis Ongkir s.d. 10.000',
                            tagline: _selectedTier == 'max'
                                ? 'Bebas ongkir tanpa batas & tanpa syarat'
                                : 'Pasti bebas ongkir jajan & belanja harian',
                            voucherCount: _selectedTier == 'max' ? '300 voucher' : '150 voucher',
                            badge: _selectedTier == 'max' ? 'BEBAS ONGKIR' : 'GRATIS ONGKIR',
                            details: _selectedTier == 'max'
                                ? [
                                    'Voucher potongan ongkir s.d. Rp 20.000 tanpa syarat minimal belanja.',
                                    'Berlaku di seluruh merchant mitra, toko sembako, dan kurir kilat.',
                                    'Total 300 voucher bebas ongkir selama masa aktif langganan.',
                                    'Bisa digabung dengan voucher diskon makanan & sembako.',
                                  ]
                                : [
                                    'Voucher potongan ongkir s.d. Rp 10.000 per transaksi.',
                                    'Berlaku di seluruh merchant GAGE Food, Mart, dan Send.',
                                    'Total 150 voucher gratis ongkir selama masa aktif langganan.',
                                    'Dapat digunakan untuk pengiriman kilat & reguler.',
                                  ],
                          ),
                          const SizedBox(height: 10),

                          // Card 2: Loyalty & Admin Fee Perks
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'star',
                            icon: Icons.stars_rounded,
                            iconColor: Colors.amber,
                            serviceName: 'GAGE Star Loyalty',
                            title: _selectedTier == 'max'
                                ? 'Dapat 2.0x Double Star Cuan'
                                : 'Dapat 1.2x Level Star Cuan',
                            tagline: _selectedTier == 'max'
                                ? 'Rp 0 Bebas Biaya Layanan & Admin Fee'
                                : 'Diskon 50% Biaya Layanan Aplikasi',
                            voucherCount: _selectedTier == 'max' ? '2.0x Poin' : '1.2x Poin',
                            badge: _selectedTier == 'max' ? 'VIP PERK' : 'HEMAT',
                            details: _selectedTier == 'max'
                                ? [
                                    'Double cashback koin Star di setiap transaksi makanan, mart & ojek.',
                                    'Bebas biaya penanganan aplikasi (Rp 0 Admin Fee) selamanya!',
                                    'Layanan CS Prioritas 24/7 di dalam aplikasi untuk bantuan instan.',
                                  ]
                                : [
                                    'Kumpulkan poin loyalty 1.2x lebih cepat di setiap orderan.',
                                    'Diskon 50% biaya layanan aplikasi di semua layanan.',
                                    'Tukarkan poin koin Star untuk potongan langsung di kasir GAGEPay.',
                                  ],
                          ),
                          const SizedBox(height: 10),

                          // Card 3: GAGE Ride & Car
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'ride',
                            icon: Icons.directions_car_rounded,
                            iconColor: const Color(0xFF16A34A),
                            serviceName: 'GAGE Ride & Car',
                            title: _selectedTier == 'max'
                                ? 'Diskon hingga 20.000'
                                : 'Diskon hingga 10.000',
                            tagline: _selectedTier == 'max'
                                ? 'VIP Instant Driver Dispatch (Tanpa Antre)'
                                : 'Nyaman, cepat dan aman',
                            voucherCount: _selectedTier == 'max' ? '600 voucher' : '300 voucher',
                            details: _selectedTier == 'max'
                                ? [
                                    'Diskon tarif perjalanan hingga 20rb untuk mobil & ojek motor.',
                                    'Sistem prioritas VIP: Alokasi driver tercepat tanpa perlu antre di jam sibuk.',
                                    'Bebas biaya pembatalan darurat jika terjadi perubahan jadwal.',
                                  ]
                                : [
                                    'Potongan ongkir tarif ojek motor & mobil se-Pracimantoro & Wonogiri.',
                                    'Prioritas menengah alokasi driver terdekat.',
                                  ],
                          ),
                          const SizedBox(height: 10),

                          // Card 4: GAGE Send
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'send',
                            icon: Icons.inventory_2_rounded,
                            iconColor: const Color(0xFF0284C7),
                            serviceName: 'GAGE Send',
                            title: _selectedTier == 'max'
                                ? 'Diskon hingga 15.000'
                                : 'Diskon hingga 10.000',
                            tagline: 'Kirim barang gak pake lama',
                            voucherCount: _selectedTier == 'max' ? '400 voucher' : '150 voucher',
                            details: [
                              'Diskon ongkir kirim paket, dokumen, & produk dagangan UMKM.',
                              'Garansi kurir antar cepat pada hari yang sama (instant dispatch).',
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Card 5: GAGE Mart
                          _buildTicketVoucherCard(
                            isDark: isDark,
                            id: 'mart',
                            icon: Icons.shopping_bag_rounded,
                            iconColor: const Color(0xFFEA580C),
                            serviceName: 'GAGE Mart & UMKM',
                            title: _selectedTier == 'max'
                                ? 'Diskon hingga 10.000'
                                : 'Diskon hingga 4.000',
                            tagline: 'Buat belanja sembako & kebutuhan harian',
                            voucherCount: _selectedTier == 'max' ? '300 voucher' : '150 voucher',
                            details: [
                              'Potongan harga belanja sembako, sayuran, dan produk UMKM lokal.',
                              'Bebas biaya packing dan penanganan toko.',
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // =========================================================
                    // 6. FOOTER SYARAT & KETENTUAN RESMI
                    // =========================================================
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            'Dengan melanjutkan, Anda menyetujui Ketentuan Berlangganan $_tierDisplayName by Halu Goods Indonesia. Langganan dapat dibatalkan sewaktu-waktu tanpa denda pinalti.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: textSecondary.withValues(alpha: 0.7), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: Text('Syarat Layanan',
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline)),
                              ),
                              Text('•', style: TextStyle(color: textSecondary)),
                              TextButton(
                                onPressed: () {},
                                child: Text('Kebijakan Privasi',
                                    style: TextStyle(
                                        color: textSecondary,
                                        fontSize: 11,
                                        decoration: TextDecoration.underline)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 120), // Spacing for sticky bottom
                  ],
                ),
              ),
      ),

      // =========================================================
      // 7. STICKY BOTTOM BAR (Gojek PLUS + Pinterest Hybrid)
      // =========================================================
      bottomSheet: _isLoading
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.98) : Colors.white,
                border: Border(top: BorderSide(color: borderColor)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Interactive Payment Method Selector Button & Discount Badge
                    InkWell(
                      onTap: () => _showPaymentMethodSelector(context),
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE52320).withValues(alpha: 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.account_balance_wallet_rounded, size: 13, color: Color(0xFFE52320)),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  _selectedPaymentMethod,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 3),
                                Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: textSecondary),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE52320).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE52320).withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                'Hemat ${currencyFormatter.format(_discountAmount)}',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFE52320),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Price and CTA button
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencyFormatter.format(_originalPrice),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary.withValues(alpha: 0.6),
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    currencyFormatter.format(_calculatedPrice),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '/$_selectedDuration',
                                    style: TextStyle(fontSize: 11.5, color: textSecondary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showQrisPaymentSheet,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE52320),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                            elevation: 3,
                            shadowColor: const Color(0xFFE52320).withValues(alpha: 0.4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Langganan $_selectedDuration',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Perpanjangan otomatis ${currencyFormatter.format(_originalPrice)}. Batalin kapan saja.',
                      style: TextStyle(fontSize: 10, color: textSecondary.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // Duration Card Widget (Pinterest-Style)
  Widget _buildDurationCard({
    required bool isDark,
    required String duration,
    required String topBadge,
    required Color badgeColor,
    required String priceFormatted,
    required String subRate,
    required bool isSelected,
    bool isFeatured = false,
  }) {
    final cardBg = isDark
        ? (isSelected ? const Color(0xFF1E293B) : const Color(0xFF131B2E))
        : (isSelected ? Colors.white : const Color(0xFFF1F5F9));

    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedDuration = duration);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _tierPrimaryColor : (isDark ? Colors.white12 : const Color(0xFFCBD5E1)),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: _tierPrimaryColor.withValues(alpha: isDark ? 0.3 : 0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge Top
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  topBadge,
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w900,
                    color: badgeColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                duration,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                priceFormatted,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: isSelected ? _tierPrimaryColor : textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subRate,
                style: TextStyle(
                  fontSize: 9.5,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Timer Box Widget
  Widget _buildTimerBox(bool isDark, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? Colors.black54 : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF0F172A),
          fontSize: 11.5,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }

  // Gojek PLUS Ticket Voucher Card (Notched & Perforated)
  Widget _buildTicketVoucherCard({
    required bool isDark,
    required String id,
    required IconData icon,
    required Color iconColor,
    required String serviceName,
    required String title,
    required String tagline,
    required String voucherCount,
    String? badge,
    required List<String> details,
  }) {
    final isExpanded = _expandedItems.contains(id);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final notchColor = isDark ? const Color(0xFF0B0F19) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final innerDetailsBg = isDark ? const Color(0xFF131B2E) : const Color(0xFFF8FAFC);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top Main Row
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Service Icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(width: 12),

                  // Service & Title Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              serviceName,
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                            if (badge != null) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  badge,
                                  style: const TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.amber,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tagline,
                          style: TextStyle(fontSize: 11, color: textSecondary),
                        ),
                      ],
                    ),
                  ),

                  // Dotted vertical divider & Voucher Count
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    height: 38,
                    width: 1,
                    color: isDark ? Colors.white12 : const Color(0xFFCBD5E1),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        voucherCount.split(' ').first,
                        style: TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w900,
                          color: textPrimary,
                        ),
                      ),
                      Text(
                        voucherCount.split(' ').length > 1
                            ? voucherCount.split(' ').last
                            : 'voucher',
                        style: TextStyle(fontSize: 10, color: textSecondary),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Dashed separator line with circle notches
            Stack(
              clipBehavior: Clip.none,
              children: [
                Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  thickness: 1,
                ),
                Positioned(
                  left: -8,
                  top: -7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: notchColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Positioned(
                  right: -8,
                  top: -7,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: notchColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),

            // Expand / Collapse Details Bar
            InkWell(
              onTap: () {
                setState(() {
                  if (isExpanded) {
                    _expandedItems.remove(id);
                  } else {
                    _expandedItems.add(id);
                  }
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                color: innerDetailsBg,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isExpanded ? 'Tutup rincian voucher' : 'Lihat rincian ketentuan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: textSecondary,
                      ),
                    ),
                    Icon(
                      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: textSecondary,
                    ),
                  ],
                ),
              ),
            ),

            // Expandable details list
            if (isExpanded)
              Container(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                color: innerDetailsBg,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: details
                      .map((d) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('• ', style: TextStyle(fontSize: 12, color: textSecondary)),
                                Expanded(
                                  child: Text(
                                    d,
                                    style: TextStyle(fontSize: 11.5, color: textPrimary, height: 1.3),
                                  ),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// MODAL SHEET SIMULASI PEMBAYARAN QRIS / GAGEPAY
// ============================================================================
class _QrisPaymentSheet extends StatefulWidget {
  final String planTitle;
  final String tierKey;
  final String duration;
  final int totalAmount;
  final NumberFormat currencyFormatter;
  final VoidCallback onPaymentSuccess;

  const _QrisPaymentSheet({
    required this.planTitle,
    required this.tierKey,
    required this.duration,
    required this.totalAmount,
    required this.currencyFormatter,
    required this.onPaymentSuccess,
  });

  @override
  State<_QrisPaymentSheet> createState() => _QrisPaymentSheetState();
}

class _QrisPaymentSheetState extends State<_QrisPaymentSheet> {
  bool _isProcessing = false;

  void _handleSimulatePay() async {
    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (mounted) {
      widget.onPaymentSuccess();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final boxBg = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9);
    final boxBorder = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    final primaryBtnColor =
        widget.tierKey == 'max' ? const Color(0xFF7C3AED) : const Color(0xFF16A34A);

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Konfirmasi Pembayaran ${widget.planTitle}',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            'Durasi Keanggotaan: ${widget.duration}',
            style: TextStyle(fontSize: 12, color: textSecondary),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: boxBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: boxBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total Pembayaran', style: TextStyle(color: textSecondary, fontSize: 13)),
                Text(
                  widget.currencyFormatter.format(widget.totalAmount),
                  style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _handleSimulatePay,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBtnColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Bayar via GAGEPay / QRIS',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }
}
