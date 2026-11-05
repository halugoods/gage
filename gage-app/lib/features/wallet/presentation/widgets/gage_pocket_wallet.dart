import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// GagePocketWallet
/// Widget Saku Dompet Kulit 3D (3D Leather Pocket Wallet):
/// - Saku dompet kulit fisik dengan bibir melengkung (curved mouth) & jahitan putus-putus (dashed stitching)
/// - Tumpukan 3 kartu rekening bank/e-wallet tersimpan (BCA, Mandiri, GoPay) yang meluncur keluar (fan-out) saat disentuh
/// - Toggle mata saldo tersembunyi/tampil pada saku depan
/// - Tombol '+' di pojok kanan atas saku untuk menambah rekening baru
/// - Indikator '${points} Poin' dengan label bersih dan posisi proporsional
/// - Tap pada kartu yang sedang keluar (fanned-out) memicu popup dialog 3D interactive flip card
class GagePocketWallet extends StatefulWidget {
  final int balance;
  final int points;
  final List<Map<String, dynamic>>? cards;
  final void Function(Map<String, dynamic> selectedCard)? onCardSelected;
  final void Function(Map<String, dynamic> card)? onCardDetailsTap;
  final VoidCallback? onEyeToggle;
  final VoidCallback? onAddAccountTap;

  const GagePocketWallet({
    super.key,
    required this.balance,
    this.points = 100,
    this.cards,
    this.onCardSelected,
    this.onCardDetailsTap,
    this.onEyeToggle,
    this.onAddAccountTap,
  });

  @override
  State<GagePocketWallet> createState() => _GagePocketWalletState();
}

class _GagePocketWalletState extends State<GagePocketWallet>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fanAnimation;
  bool _isFannedOut = false;
  bool _isBalanceVisible = true;
  int _selectedCardIndex = 0;

  final List<Map<String, dynamic>> _defaultCards = [
    {
      'id': 'card-bca',
      'bank': 'BCA',
      'label': 'Bank Central Asia',
      'holder': 'SITI RAHMAWATI',
      'maskedNumber': '•••• 4242',
      'fullNumber': '5524 9910 4242',
      'validThru': '12 / 28',
      'gradient': [const Color(0xFF1E3A8A), const Color(0xFF172554)],
      'chipColor': const Color(0xFFF59E0B),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'card-mandiri',
      'bank': 'Mandiri',
      'label': 'Bank Mandiri',
      'holder': 'SITI RAHMAWATI',
      'maskedNumber': '•••• 8810',
      'fullNumber': '9012 4432 8810',
      'validThru': '08 / 27',
      'gradient': [const Color(0xFF0F172A), const Color(0xFF334155)],
      'chipColor': const Color(0xFFE2E8F0),
      'icon': Icons.account_balance_rounded,
    },
    {
      'id': 'card-gopay',
      'bank': 'GoPay',
      'label': 'GoPay / DANA E-Wallet',
      'holder': 'SITI RAHMAWATI',
      'maskedNumber': '•••• 7890',
      'fullNumber': '0812 3456 7890',
      'validThru': '05 / 29',
      'gradient': [const Color(0xFF0D9488), const Color(0xFF065F46)],
      'chipColor': const Color(0xFFF59E0B),
      'icon': Icons.account_balance_wallet_rounded,
    },
  ];

  List<Map<String, dynamic>> get _cards =>
      (widget.cards != null && widget.cards!.isNotEmpty) ? widget.cards! : _defaultCards;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _fanAnimation = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleFan() {
    HapticFeedback.lightImpact();
    setState(() {
      _isFannedOut = !_isFannedOut;
      if (_isFannedOut) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    });
  }

  void _selectCard(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      _selectedCardIndex = index;
    });
    if (widget.onCardSelected != null) {
      widget.onCardSelected!(_cards[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeCards = _cards;
    final selectedCard = _selectedCardIndex < activeCards.length
        ? activeCards[_selectedCardIndex]
        : activeCards.first;

    return AnimatedBuilder(
      animation: _fanAnimation,
      builder: (context, _) {
        final animValue = _fanAnimation.value;

        return Column(
          children: [
            // Kontainer Utama Dompet Saku
            GestureDetector(
              onTap: _toggleFan,
              behavior: HitTestBehavior.opaque,
              child: SizedBox(
                height: 235 + (animValue * 48), // mengembang saat kartu meluncur naik
                width: double.infinity,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    // Layer 0: Bagian Belakang Dompet (Wallet Back)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1512),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: const Color(0xFF382620), width: 1.5),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black45,
                              blurRadius: 18,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Layer 1: Kartu 1 (Paling Belakang)
                    if (activeCards.isNotEmpty)
                      _buildAnimatedCard(
                        card: activeCards[0],
                        index: 0,
                        animValue: animValue,
                        normalOffsetY: -32.0,
                        fannedOffsetY: -92.0,
                        fannedRotation: -0.065, // ~-3.7 derajat
                        scale: 0.92,
                      ),

                    // Layer 2: Kartu 2 (Tengah)
                    if (activeCards.length > 1)
                      _buildAnimatedCard(
                        card: activeCards[1],
                        index: 1,
                        animValue: animValue,
                        normalOffsetY: -18.0,
                        fannedOffsetY: -60.0,
                        fannedRotation: 0.045, // ~+2.5 derajat
                        scale: 0.96,
                      ),

                    // Layer 3: Kartu 3 (Terdepan di dalam saku)
                    if (activeCards.length > 2)
                      _buildAnimatedCard(
                        card: activeCards[2],
                        index: 2,
                        animValue: animValue,
                        normalOffsetY: -4.0,
                        fannedOffsetY: -24.0,
                        fannedRotation: 0.0,
                        scale: 1.0,
                      ),

                    // Layer 4: Saku Kulit Depan (Wallet Front Pocket)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: _buildFrontPocket(selectedCard, animValue),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnimatedCard({
    required Map<String, dynamic> card,
    required int index,
    required double animValue,
    required double normalOffsetY,
    required double fannedOffsetY,
    required double fannedRotation,
    required double scale,
  }) {
    final isSelected = _selectedCardIndex == index;
    final currentOffsetY = normalOffsetY + (fannedOffsetY - normalOffsetY) * animValue;
    final currentRotation = fannedRotation * animValue;
    final currentScale = isSelected && _isFannedOut ? (scale + 0.04) : scale;

    final gradientColors = (card['gradient'] as List?)?.cast<Color>() ??
        const [Color(0xFF1E3A8A), Color(0xFF172554)];

    return Positioned(
      bottom: 0,
      left: 12,
      right: 12,
      child: Transform.translate(
        offset: Offset(0, currentOffsetY),
        child: Transform.rotate(
          angle: currentRotation,
          alignment: Alignment.bottomCenter,
          child: Transform.scale(
            scale: currentScale,
            child: GestureDetector(
              onTap: () {
                if (!_isFannedOut) {
                  _toggleFan();
                } else {
                  HapticFeedback.lightImpact();
                  if (widget.onCardDetailsTap != null) {
                    widget.onCardDetailsTap!(card);
                  } else {
                    _selectCard(index);
                  }
                }
              },
              child: Container(
                height: 165,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: gradientColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? const Color(0xFFF59E0B) : Colors.white24,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isSelected ? 0.45 : 0.25),
                      blurRadius: isSelected ? 14 : 8,
                      offset: Offset(0, isSelected ? 6 : 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Bagian Atas: Nama Bank & EMV Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(card['icon'] as IconData? ?? Icons.account_balance_rounded, color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              card['bank'] as String? ?? 'GAGE Card',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            if (_isFannedOut)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.flip_rounded, color: Colors.white, size: 10),
                                    SizedBox(width: 3),
                                    Text(
                                      '3D Flip',
                                      style: TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            // EMV Gold/Silver Chip
                            Container(
                              width: 28,
                              height: 20,
                              decoration: BoxDecoration(
                                color: card['chipColor'] as Color? ?? const Color(0xFFF59E0B),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.black26, width: 0.8),
                              ),
                              child: CustomPaint(painter: _ChipPatternPainter()),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // Bagian Bawah: Pemilik & Nomor Rekening
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HOLDER',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                            Text(
                              card['holder'] as String? ?? 'PENGGUNA GAGE',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (isSelected)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                margin: const EdgeInsets.only(bottom: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AKTIF TARIK',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            Text(
                              _isFannedOut
                                  ? (card['fullNumber'] as String? ?? '•••• •••• ••••')
                                  : (card['maskedNumber'] as String? ?? '•••• ••••'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontPocket(Map<String, dynamic> selectedCard, double animValue) {
    return Container(
      height: 145,
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      child: Stack(
        children: [
          // Background Kulit dengan Lengkungan Bibir Saku Atas (Curved Pocket Mouth)
          ClipPath(
            clipper: _PocketMouthClipper(),
            child: Container(
              height: 145,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF382620), // Rich Leather
                    Color(0xFF261915),
                    Color(0xFF1E1310),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(22)),
              ),
            ),
          ),

          // Garis Jahitan Keliling Putus-Putus (Dashed Stitching)
          Positioned.fill(
            child: CustomPaint(
              painter: _PocketStitchingPainter(),
            ),
          ),

          // Konten di Permukaan Saku Depan
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Baris 1: Label Saldo, Toggle Mata & Tombol Tambah Rekening (+)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.wallet_rounded, size: 14, color: Color(0xFFF59E0B)),
                        SizedBox(width: 6),
                        Text(
                          'TOTAL SALDO GAGEPAY',
                          style: TextStyle(
                            color: Color(0xFFD4B996),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Toggle Mata Saldo
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() => _isBalanceVisible = !_isBalanceVisible);
                            if (widget.onEyeToggle != null) widget.onEyeToggle!();
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              _isBalanceVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
                              color: const Color(0xFFD4B996),
                              size: 18,
                            ),
                          ),
                        ),
                        // Tombol Tambah Rekening (+)
                        if (widget.onAddAccountTap != null) ...[
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              widget.onAddAccountTap!();
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white24, width: 0.8),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Color(0xFFD4B996),
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                // Baris 2: Nominal Saldo Besar
                Text(
                  _isBalanceVisible
                      ? 'Rp ${widget.balance.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}'
                      : 'Rp ••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),

                // Baris 3: Poin & Kartu Penarikan Terpilih
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars_rounded, color: Color(0xFFF59E0B), size: 13),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.points} Poin',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          animValue > 0.5
                              ? 'Pilih Rekening'
                              : '${selectedCard['bank']} (${selectedCard['maskedNumber']})',
                          style: const TextStyle(
                            color: Color(0xFFD4B996),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          animValue > 0.5 ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                          color: const Color(0xFFF59E0B),
                          size: 16,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Clipper untuk bibir saku dompet kulit yang melengkung elegan ke bawah
class _PocketMouthClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Mulai dari kiri atas sedikit turun
    path.moveTo(0, 16);
    // Lengkungan saku ke tengah
    path.quadraticBezierTo(size.width * 0.5, -6, size.width, 16);
    // Ke kanan bawah
    path.lineTo(size.width, size.height);
    // Ke kiri bawah
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Painter untuk jahitan kulit putus-putus (Dashed Leather Stitching)
class _PocketStitchingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD4B996).withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Garis jahitan mengikuti lengkungan bibir saku
    path.moveTo(8, 20);
    path.quadraticBezierTo(size.width * 0.5, -2, size.width - 8, 20);
    // Jahitan kanan
    path.lineTo(size.width - 8, size.height - 8);
    // Jahitan bawah
    path.lineTo(8, size.height - 8);
    path.close();

    // Gambar dengan efek putus-putus
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0.0;
      const dashLength = 4.0;
      const spaceLength = 3.5;

      while (distance < metric.length) {
        final extractPath = metric.extractPath(distance, distance + dashLength);
        canvas.drawPath(extractPath, paint);
        distance += dashLength + spaceLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter untuk chip EMV perak/emas pada kartu
class _ChipPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black26
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), paint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), paint);
    canvas.drawLine(Offset(size.width * 0.65, 0), Offset(size.width * 0.65, size.height), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
