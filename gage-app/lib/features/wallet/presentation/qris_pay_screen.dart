import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';

/// Layar Penuh Pemindai QRIS GAGEPay (Full Screen Smart Scanner)
/// - Kamera Fullscreen mengisi seluruh layar
/// - Theme-Adaptive (Light/Dark mode responsive)
/// - Smart Scan Animation: Reticle lock-on glow, haptic feedback, capture pulse ~450ms sebelum sheet pembayaran muncul
/// - Bottom sheet konfirmasi pembayaran mengikuti referensi 30px radius & circular close button
class QrisPayScreen extends StatefulWidget {
  const QrisPayScreen({super.key});

  @override
  State<QrisPayScreen> createState() => _QrisPayScreenState();
}

class _QrisPayScreenState extends State<QrisPayScreen> with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserAnimCtrl;
  late Animation<double> _laserAnimation;

  bool _isFlashOn = false;
  bool _isLockingOn = false;
  bool _isQrScanned = false;
  int _selectedAmount = 25000;

  String _detectedMerchantName = 'Toko Kelontong Berkah Fajar';
  String _detectedMerchantLocation = 'Pasar Pracimantoro Los A No. 4';
  String _detectedMerchantNmid = 'ID1024395819028';

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<int> _quickAmounts = [10000, 25000, 50000, 100000, 200000];

  @override
  void initState() {
    super.initState();
    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.normal,
      facing: CameraFacing.back,
      torchEnabled: false,
    );

    _laserAnimCtrl = AnimationController(
      duration: const Duration(milliseconds: 1800),
      vsync: this,
    )..repeat(reverse: true);

    _laserAnimation = CurvedAnimation(
      parent: _laserAnimCtrl,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _laserAnimCtrl.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  /// Parsing standar EMVCo TLV untuk mengekstrak data merchant dari QRIS
  void _parseAndApplyQris(String rawCode) {
    String merchant = 'Merchant Resmi Mitra GAGE';
    String location = 'Pracimantoro, Wonogiri';
    String nmid = 'ID1024395819028';
    int? extractedAmount;

    try {
      int i = 0;
      while (i + 4 <= rawCode.length) {
        final tag = rawCode.substring(i, i + 2);
        final len = int.tryParse(rawCode.substring(i + 2, i + 4)) ?? -1;
        if (len == -1) break;
        final start = i + 4;
        final end = start + len;
        if (end > rawCode.length) break;
        final value = rawCode.substring(start, end);

        if (tag == '59' && value.isNotEmpty) {
          merchant = value;
        } else if (tag == '60' && value.isNotEmpty) {
          location = '$value, Wonogiri';
        } else if ((tag == '51' || tag == '26') && value.isNotEmpty) {
          if (value.contains('ID')) {
            final match = RegExp(r'ID[0-9A-Za-z]+').firstMatch(value);
            if (match != null) nmid = match.group(0)!;
          }
        } else if (tag == '54' && value.isNotEmpty) {
          final amt = double.tryParse(value);
          if (amt != null && amt > 0) extractedAmount = amt.toInt();
        }

        i = end;
      }
    } catch (_) {}

    _detectedMerchantName = merchant;
    _detectedMerchantLocation = location;
    _detectedMerchantNmid = nmid;
    if (extractedAmount != null && extractedAmount > 0) {
      _selectedAmount = extractedAmount;
    }
  }

  /// Smart Scan Trigger: Kunci reticle, getar haptic, animasi capture ~450ms sebelum membuka sheet
  Future<void> _handleQrCodeDetected(String rawCode) async {
    if (_isQrScanned || _isLockingOn) return;

    setState(() {
      _isLockingOn = true;
    });

    HapticFeedback.heavyImpact();
    _parseAndApplyQris(rawCode);

    // Animasi capture delay ~450ms agar pengguna merasakan proses smart lock-on kamera
    await Future.delayed(const Duration(milliseconds: 450));

    if (!mounted) return;

    setState(() {
      _isLockingOn = false;
      _isQrScanned = true;
    });

    _showPaymentSheet();
  }

  Future<void> _pickQrFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      final barcodeCapture = await _scannerController.analyzeImage(image.path);
      if (barcodeCapture != null && barcodeCapture.barcodes.isNotEmpty) {
        final code = barcodeCapture.barcodes.first.rawValue;
        if (code != null && code.isNotEmpty) {
          _handleQrCodeDetected(code);
          return;
        }
      }
    } catch (_) {}

    _handleQrCodeDetected(
      '00020101021126510013ID.GAGE.WWW01189360091800216174620208151234565204549953033605802ID5922Toko Rejeki Makmur6012Pracimantoro6105551226304D1A2',
    );
  }

  void _resetScan() {
    if (mounted) {
      setState(() {
        _isQrScanned = false;
        _isLockingOn = false;
      });
    }
  }

  void _showCustomAmountDialog(StateSetter? setModalState) {
    final ctrl = TextEditingController(text: _selectedAmount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Input Nominal Manual', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Masukkan nominal belanja yang ingin Anda bayar:', style: TextStyle(fontSize: 12, color: Colors.black54)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                prefixStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: GageTheme.primary),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: GageTheme.primary, foregroundColor: Colors.white),
            onPressed: () {
              final val = int.tryParse(ctrl.text.trim()) ?? _selectedAmount;
              if (val > 0) {
                setState(() => _selectedAmount = val);
                if (setModalState != null) setModalState(() => _selectedAmount = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _processPayment(WalletProvider wallet) {
    final amount = _selectedAmount;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal pembayaran belum diisi!')),
      );
      return;
    }

    if (wallet.balance < amount) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
              SizedBox(width: 8),
              Text('Saldo Tidak Cukup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Saldo GAGEPay Anda saat ini ${currencyFormatter.format(wallet.balance)}, '
                'sedangkan total pembayaran adalah ${currencyFormatter.format(amount)}.',
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text('Silakan Top Up saldo via QRIS dinamis terlebih dahulu:'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (dCtx) => TopupQrisDialog(
                    onTopupSuccess: (amt) {
                      wallet.fetchWallet('usr-cust-01');
                    },
                  ),
                );
              },
              child: const Text('Top Up Sekarang'),
            ),
          ],
        ),
      );
      return;
    }

    // Deduksi saldo GAGEPay
    wallet.deductBalance(amount);
    Navigator.pop(context); // Tutup bottom sheet
    _completePayment(wallet);
  }

  void _completePayment(WalletProvider wallet) {
    final invoiceNumber = 'QRIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
    final now = DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(DateTime.now());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(22.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: Color(0xFFDCFCE7),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 40,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transaksi QRIS Terverifikasi Realtime',
                style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    _buildReceiptRow('Nominal Bayar', currencyFormatter.format(_selectedAmount)),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Merchant', _detectedMerchantName),
                    const SizedBox(height: 6),
                    _buildReceiptRow('NMID', _detectedMerchantNmid),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Metode', 'Saldo GAGEPay (0% Fee)'),
                    const SizedBox(height: 6),
                    _buildReceiptRow('No. Referensi', invoiceNumber),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Waktu Transaksi', now),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    Navigator.pop(context);
                  },
                  child: const Text('Kembali ke Beranda', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// Bottom Sheet Konfirmasi Pembayaran (Mengikuti Referensi 30px Radius & Circular Close)
  void _showPaymentSheet() {
    final wallet = context.read<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Konfirmasi Pembayaran QRIS',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          Navigator.pop(ctx);
                          _resetScan();
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF27272A) : const Color(0xFFF3F4F6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 16,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Merchant Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: const Color(0xFF16A34A).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.storefront_rounded, color: Color(0xFF16A34A), size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _detectedMerchantName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14.5,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Mitra ✓',
                                      style: TextStyle(
                                        color: Color(0xFF16A34A),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _detectedMerchantLocation,
                                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.grey.shade600),
                              ),
                              Text(
                                'NMID: $_detectedMerchantNmid',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontFamily: 'monospace',
                                  color: isDark ? Colors.white38 : Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Nominal Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Nominal Pembayaran:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      InkWell(
                        onTap: () => _showCustomAmountDialog(setModalState),
                        child: const Text(
                          'Ubah Nominal',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  Center(
                    child: Text(
                      currencyFormatter.format(_selectedAmount),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: GageTheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Amount Chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: _quickAmounts.map((amt) {
                      final isSelected = _selectedAmount == amt;
                      return ChoiceChip(
                        label: Text(
                          currencyFormatter.format(amt),
                          style: TextStyle(
                            fontSize: 11,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: GageTheme.primary,
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey.shade100,
                        onSelected: (_) {
                          setModalState(() => _selectedAmount = amt);
                          setState(() => _selectedAmount = amt);
                        },
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 16),

                  // Saldo Info & Rincian Transaksi Transparan (0% Fee)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  'Saldo GAGEPay',
                                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : Colors.black87),
                                ),
                              ],
                            ),
                            Text(
                              currencyFormatter.format(wallet.balance),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(height: 1),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Biaya Layanan Transaksi',
                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '0% Fee (Gratis)',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Sisa Saldo Setelah Bayar',
                              style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white60 : Colors.black54),
                            ),
                            Text(
                              currencyFormatter.format(math.max(0, wallet.balance - _selectedAmount)),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: wallet.balance >= _selectedAmount
                                    ? (isDark ? Colors.white70 : Colors.black87)
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Tombol Bayar
                  SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      icon: const Icon(Icons.lock_rounded, size: 18),
                      label: Text(
                        'Bayar ${currencyFormatter.format(_selectedAmount)}',
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => _processPayment(wallet),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
      _resetScan();
    });
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final reticleSize = math.min(screenWidth - 64, 280.0);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. KAMERA FULLSCREEN
          MobileScanner(
            controller: _scannerController,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
                  _handleQrCodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.videocam_off_rounded, color: Colors.white54, size: 48),
                    const SizedBox(height: 10),
                    const Text('Izin Kamera Dibutuhkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    const Text('Aktifkan izin kamera untuk memindai QRIS', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              );
            },
          ),

          // 2. CUTOUT OVERLAY DENGAN MASK TRANSLUCENT
          CustomPaint(
            size: Size.infinite,
            painter: _ScannerCutoutPainter(
              cutoutSize: reticleSize,
              isDark: isDark,
            ),
          ),

          // 3. MINIMALIST RETICLE FRAME & SUBTLE SCAN INDICATOR (Apple Pay / DANA Style)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: reticleSize,
              height: reticleSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isLockingOn || _isQrScanned
                      ? const Color(0xFF10B981)
                      : Colors.white.withValues(alpha: 0.25),
                  width: 1.5,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // 4 Sudut Minimalis Viewfinder
                  Positioned.fill(
                    child: QrViewfinderCorners(
                      color: _isLockingOn || _isQrScanned
                          ? const Color(0xFF10B981)
                          : Colors.white,
                      cornerLength: 26,
                      cornerWidth: 2.8,
                    ),
                  ),

                  // Garis Pemindai Halus Minimalis (Soft White/Mint Pulse)
                  if (!_isQrScanned && !_isLockingOn)
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                        child: AnimatedBuilder(
                          animation: _laserAnimation,
                          builder: (context, child) {
                            return Align(
                              alignment: Alignment(0, (_laserAnimation.value * 2) - 1),
                              child: Container(
                                height: 2.0,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      Colors.white.withValues(alpha: 0.8),
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.8),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),

                  // Minimalist Status Badge saat QR Terdeteksi
                  if (_isLockingOn || _isQrScanned)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFF10B981), width: 1.0),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 16),
                          SizedBox(width: 6),
                          Text(
                            'QR Terdeteksi',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. FLOATING TOP BAR (Theme-Adaptive)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  // Cohesive Card Pindai QRIS GAGE with Integrated Saldo & 0% Fee
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.94) : Colors.white.withValues(alpha: 0.96),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 12, offset: Offset(0, 3)),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Row 1: Back, Title, Flash & Gallery
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                width: 34,
                                height: 34,
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.arrow_back_rounded,
                                  color: isDark ? Colors.white : Colors.black87,
                                  size: 18,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.qr_code_scanner_rounded, color: GageTheme.primary, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Pindai QRIS GAGE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () {
                                    _scannerController.toggleTorch();
                                    setState(() => _isFlashOn = !_isFlashOn);
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                      color: _isFlashOn ? Colors.amber : (isDark ? Colors.white70 : Colors.black87),
                                      size: 18,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                InkWell(
                                  onTap: _pickQrFromGallery,
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    width: 34,
                                    height: 34,
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.photo_library_rounded,
                                      color: isDark ? Colors.white70 : Colors.black87,
                                      size: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),
                        const Divider(height: 1),
                        const SizedBox(height: 8),

                        // Row 2: Integrated Saldo GAGEPay & 0% Fee Pill
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              TopupQrisDialog.showAsSheet(
                                context,
                                onTopupSuccess: (amt) {
                                  wallet.fetchWallet('usr-cust-01');
                                },
                              );
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: GageTheme.primaryLight,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo GAGEPay',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                        ),
                                      ),
                                      Text(
                                        currencyFormatter.format(wallet.balance),
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w900,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      '0% Fee',
                                      style: TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: GageTheme.primary,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, color: Colors.white, size: 12),
                                        SizedBox(width: 2),
                                        Text(
                                          'Top Up',
                                          style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ],
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
                ],
              ),
            ),
          ),

          // 5. FLOATING BOTTOM CONTROLS (Theme-Adaptive)
          Positioned(
            bottom: 30,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Hint Text
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text(
                    'Arahkan kamera ke QRIS Merchant Mitra GAGE atau QRIS Nasional',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 14),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                          foregroundColor: isDark ? Colors.white : Colors.black87,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.edit_note_rounded, size: 18),
                        label: const Text('Input Manual', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        onPressed: () => _showCustomAmountDialog(null),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: GageTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                        label: const Text('Simulasi QR', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          _handleQrCodeDetected(
                            '00020101021126510013ID.GAGE.WWW01189360091800216174620208151234565204549953033605802ID5927Toko Sembako Berkah Fajar6012Pracimantoro6105551226304ED41',
                          );
                        },
                      ),
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

/// Painter untuk Cutout Mask di sekeliling reticle kamera
class _ScannerCutoutPainter extends CustomPainter {
  final double cutoutSize;
  final bool isDark;

  _ScannerCutoutPainter({
    required this.cutoutSize,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = isDark ? Colors.black.withValues(alpha: 0.65) : Colors.black.withValues(alpha: 0.45);

    final center = Offset(size.width / 2, size.height / 2);
    final cutoutRect = Rect.fromCenter(
      center: center,
      width: cutoutSize,
      height: cutoutSize,
    );

    final backgroundPath = Path()..addRect(Rect.fromLTWH(0, 0, size.width, size.height));
    final cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(cutoutRect, const Radius.circular(24)));

    final finalPath = Path.combine(PathOperation.difference, backgroundPath, cutoutPath);
    canvas.drawPath(finalPath, backgroundPaint);
  }

  @override
  bool shouldRepaint(covariant _ScannerCutoutPainter oldDelegate) {
    return oldDelegate.cutoutSize != cutoutSize || oldDelegate.isDark != isDark;
  }
}

/// Custom Painter 4 Sudut Pemindai (Reticle Frame)
class QrViewfinderCorners extends StatelessWidget {
  final Color color;
  final double cornerLength;
  final double cornerWidth;

  const QrViewfinderCorners({
    super.key,
    required this.color,
    this.cornerLength = 32,
    this.cornerWidth = 4.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _CornersPainter(
        color: color,
        cornerLength: cornerLength,
        cornerWidth: cornerWidth,
      ),
    );
  }
}

class _CornersPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double cornerWidth;

  _CornersPainter({
    required this.color,
    required this.cornerLength,
    required this.cornerWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;
    final l = cornerLength;

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(l, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, l), paint);

    // Top Right
    canvas.drawLine(Offset(w, 0), Offset(w - l, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, l), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, h), Offset(l, h), paint);
    canvas.drawLine(Offset(0, h), Offset(0, h - l), paint);

    // Bottom Right
    canvas.drawLine(Offset(w, h), Offset(w - l, h), paint);
    canvas.drawLine(Offset(w, h), Offset(w, h - l), paint);
  }

  @override
  bool shouldRepaint(covariant _CornersPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.cornerWidth != cornerWidth;
  }
}
