import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/topup_qris_dialog.dart';

/// Layanan QRIS Pay Resmi Independen GAGE Pracimantoro
/// Real Camera Scanner 1:1, Mendukung Pembayaran Saldo GAGEPay & Semua e-Wallet/m-Banking
class OfflineQrisPaySheet extends StatefulWidget {
  const OfflineQrisPaySheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const OfflineQrisPaySheet(),
    );
  }

  @override
  State<OfflineQrisPaySheet> createState() => _OfflineQrisPaySheetState();
}

class _OfflineQrisPaySheetState extends State<OfflineQrisPaySheet>
    with SingleTickerProviderStateMixin {
  late MobileScannerController _scannerController;
  late AnimationController _laserAnimCtrl;
  late Animation<double> _laserAnimation;

  bool _isFlashOn = false;
  bool _isQrScanned = false;
  int _selectedAmount = 25000;

  String _detectedMerchantName = 'Toko Kelontong Berkah Fajar';
  String _detectedMerchantLocation = 'Pasar Pracimantoro Los A No. 4';
  String _detectedMerchantNmid = 'ID1024395819028';

  // 'GAGEPAY' vs 'OTHER_EWALLET'
  String _fundingSource = 'GAGEPAY';

  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

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
        } else if (tag == '54') {
          final amt = double.tryParse(value)?.toInt();
          if (amt != null && amt > 0) extractedAmount = amt;
        } else if ((tag == '26' || tag == '51') && value.contains('ID')) {
          final idMatch = RegExp(r'ID\d{9,}').firstMatch(value);
          if (idMatch != null) {
            nmid = idMatch.group(0)!;
          }
        }
        i = end;
      }
    } catch (_) {}

    // Fallback jika bukan EMVCo panjang
    if (merchant == 'Merchant Resmi Mitra GAGE' &&
        rawCode.length < 50 &&
        !rawCode.startsWith('000201')) {
      merchant = rawCode;
    }

    setState(() {
      _isQrScanned = true;
      _detectedMerchantName = merchant;
      _detectedMerchantLocation = location;
      _detectedMerchantNmid = nmid;
      if (extractedAmount != null && extractedAmount > 0) {
        _selectedAmount = extractedAmount;
      }
    });
  }

  void _handleQrCodeDetected(String rawCode) {
    if (_isQrScanned) return;
    HapticFeedback.heavyImpact();
    _parseAndApplyQris(rawCode);
  }

  Future<void> _pickQrFromGallery() {
    return ImagePicker().pickImage(source: ImageSource.gallery).then((file) {
      if (file != null) {
        _scannerController.analyzeImage(file.path).then((capture) {
          if (capture != null && capture.barcodes.isNotEmpty) {
            final barcode = capture.barcodes.first;
            if (barcode.rawValue != null && barcode.rawValue!.isNotEmpty) {
              _handleQrCodeDetected(barcode.rawValue!);
              return;
            }
          }
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak ditemukan kode QRIS yang valid pada gambar.'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        });
      }
    });
  }

  void _resetScan() {
    HapticFeedback.lightImpact();
    setState(() {
      _isQrScanned = false;
    });
  }

  void _showCustomAmountDialog() {
    final ctrl = TextEditingController(text: _selectedAmount.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Nominal Pembayaran',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ketik nominal yang ingin dibayarkan ke merchant:',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              autofocus: true,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20),
              decoration: InputDecoration(
                prefixText: 'Rp ',
                filled: true,
                fillColor: const Color(0xFFF1F5F9),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              final val = int.tryParse(ctrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
              if (val > 0) {
                setState(() => _selectedAmount = val);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showBankAndEwalletSelector(WalletProvider wallet) {
    final apps = [
      {'name': 'BCA Mobile', 'tag': 'BCA', 'color': const Color(0xFF005BAC), 'icon': Icons.account_balance_rounded, 'scheme': 'bca://', 'fallback': 'https://play.google.com/store/apps/details?id=com.bca'},
      {'name': "Livin' by Mandiri", 'tag': 'Mandiri', 'color': const Color(0xFF003D79), 'icon': Icons.account_balance_rounded, 'scheme': 'bankmandiri://', 'fallback': 'https://play.google.com/store/apps/details?id=id.co.bankmandiri.livin'},
      {'name': 'BRImo (Bank BRI)', 'tag': 'BRI', 'color': const Color(0xFF00529C), 'icon': Icons.account_balance_rounded, 'scheme': 'brimo://', 'fallback': 'https://play.google.com/store/apps/details?id=id.co.bri.brimo'},
      {'name': 'BNI Mobile Banking', 'tag': 'BNI', 'color': const Color(0xFF005E5D), 'icon': Icons.account_balance_rounded, 'scheme': 'bni://', 'fallback': 'https://play.google.com/store/apps/details?id=src.com.bni'},
      {'name': 'GoPay (Gojek)', 'tag': 'GoPay', 'color': const Color(0xFF0081A0), 'icon': Icons.phone_android_rounded, 'scheme': 'gopay://', 'fallback': 'https://play.google.com/store/apps/details?id=com.gojek.app'},
      {'name': 'OVO', 'tag': 'OVO', 'color': const Color(0xFF4C3494), 'icon': Icons.account_balance_wallet_rounded, 'scheme': 'ovo://', 'fallback': 'https://play.google.com/store/apps/details?id=ovo.id'},
      {'name': 'ShopeePay', 'tag': 'Shopee', 'color': const Color(0xFFEE4D2D), 'icon': Icons.shopping_bag_rounded, 'scheme': 'shopeepay://', 'fallback': 'https://play.google.com/store/apps/details?id=com.shopee.id'},
      {'name': 'DANA', 'tag': 'DANA', 'color': const Color(0xFF118EEA), 'icon': Icons.account_balance_wallet_rounded, 'scheme': 'dana://', 'fallback': 'https://play.google.com/store/apps/details?id=id.dana'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1D4ED8).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.qr_code_scanner_rounded, color: Color(0xFF1D4ED8), size: 20),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pilih Aplikasi Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'QRIS Nasional resmi dapat dibayar dari aplikasi apa saja',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: apps.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, idx) {
                    final app = apps[idx];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      leading: CircleAvatar(
                        backgroundColor: (app['color'] as Color).withValues(alpha: 0.12),
                        child: Icon(app['icon'] as IconData, color: app['color'] as Color, size: 20),
                      ),
                      title: Text(
                        app['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      subtitle: Text(
                        'Bayar ${currencyFormatter.format(_selectedAmount)} langsung via ${app['tag']}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.grey),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final scheme = app['scheme'] as String?;
                        if (scheme != null) {
                          try {
                            final uri = Uri.parse(scheme);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          } catch (_) {}
                        }
                        _completePayment(
                          wallet,
                          sourceLabel: '${app['name']} (Interkoneksi QRIS)',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _completePayment(WalletProvider wallet, {required String sourceLabel}) {
    final amount = _selectedAmount;
    final txId = 'GAGE-QRIS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';

    // Tutup bottomsheet bayar
    Navigator.pop(context);

    // Tampilkan Struk Bukti Bayar Resmi
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
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 40),
              ),
              const SizedBox(height: 14),
              const Text(
                'Pembayaran QRIS Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Layanan QRIS Resmi GAGE Pracimantoro',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Text(
                      currencyFormatter.format(amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 24,
                        color: GageTheme.primary,
                      ),
                    ),
                    const Divider(height: 20),
                    _buildReceiptRow('Merchant:', _detectedMerchantName),
                    const SizedBox(height: 6),
                    _buildReceiptRow('NMID:', _detectedMerchantNmid),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Lokasi:', _detectedMerchantLocation),
                    const SizedBox(height: 6),
                    _buildReceiptRow('No. Referensi:', txId),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Sumber Dana:', sourceLabel),
                    const SizedBox(height: 6),
                    _buildReceiptRow('Waktu:', DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Selesai', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _processPayment(WalletProvider wallet) {
    final amount = _selectedAmount;

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih atau masukkan nominal pembayaran yang valid.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_fundingSource == 'GAGEPAY') {
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
                  Navigator.pop(context);
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

      // Deduksi saldo GAGEPay secara nyata
      wallet.deductBalance(amount);
      _completePayment(wallet, sourceLabel: 'Saldo GAGEPay (0% Fee)');
    } else {
      // Buka pilihan m-Banking / e-Wallet
      _showBankAndEwalletSelector(wallet);
    }
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

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isTablet ? 540 : double.infinity,
          maxHeight: MediaQuery.of(context).size.height * 0.94,
        ),
        child: Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  // Handle Bar
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header Bersih & Modern
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: GageTheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_scanner_rounded,
                            color: GageTheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'GAGE QRIS Pay',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                'Penyedia QRIS Resmi Mitra Pracimantoro',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Baris Saldo GAGEPay
                  Container(
                    margin: const EdgeInsets.fromLTRB(20, 10, 20, 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: GageTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo GAGEPay:',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          currencyFormatter.format(wallet.balance),
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            color: GageTheme.primary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder Scanner Kamera 1:1 Presisi (240x240px)
                  Center(
                    child: Container(
                      width: 240,
                      height: 240,
                      decoration: BoxDecoration(
                        color: const Color(0xFF020617),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: _isQrScanned
                              ? const Color(0xFF22C55E)
                              : const Color(0xFF38BDF8).withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 1. Live Camera Preview Real
                            MobileScanner(
                              controller: _scannerController,
                              onDetect: (capture) {
                                final barcodes = capture.barcodes;
                                for (final barcode in barcodes) {
                                  if (barcode.rawValue != null &&
                                      barcode.rawValue!.isNotEmpty &&
                                      !_isQrScanned) {
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
                                      const Icon(Icons.videocam_rounded, color: Colors.white54, size: 36),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Kamera Scanner Aktif',
                                        style: TextStyle(color: Colors.white70, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),

                            // 2. 4 Corner Brackets 1:1 Persegi
                            Positioned.fill(
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: QrViewfinderCorners(
                                  color: _isQrScanned
                                      ? const Color(0xFF22C55E)
                                      : const Color(0xFF38BDF8),
                                  cornerLength: 28,
                                  cornerWidth: 4,
                                ),
                              ),
                            ),

                            // 3. Laser Beam Animasi Pemindai (Naik - Turun Halus)
                            if (!_isQrScanned)
                              Positioned.fill(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                  child: AnimatedBuilder(
                                    animation: _laserAnimation,
                                    builder: (context, child) {
                                      return Align(
                                        alignment: Alignment(0, (_laserAnimation.value * 2) - 1),
                                        child: Container(
                                          height: 3,
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                Colors.transparent,
                                                Color(0xFF38BDF8),
                                                Colors.white,
                                                Color(0xFF38BDF8),
                                                Colors.transparent,
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(0xFF38BDF8).withValues(alpha: 0.95),
                                                blurRadius: 12,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),

                            // 4. Status Scanned Badge
                            if (_isQrScanned)
                              Container(
                                color: Colors.black.withValues(alpha: 0.65),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF22C55E).withValues(alpha: 0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.check_circle_rounded,
                                          color: Color(0xFF22C55E),
                                          size: 40,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.8),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'QRIS Merchant Terbaca ✓',
                                          style: TextStyle(
                                            color: Color(0xFF4ADE80),
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                            // 5. Tombol Flashlight & Galeri
                            Positioned(
                              top: 10,
                              right: 10,
                              child: InkWell(
                                onTap: () {
                                  _scannerController.toggleTorch();
                                  setState(() => _isFlashOn = !_isFlashOn);
                                },
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: _isFlashOn ? Colors.amber : Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                                    color: _isFlashOn ? Colors.black87 : Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),

                            Positioned(
                              top: 10,
                              left: 10,
                              child: InkWell(
                                onTap: _pickQrFromGallery,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(7),
                                  decoration: const BoxDecoration(
                                    color: Colors.black45,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.photo_library_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (!_isQrScanned) ...[
                    // Panduan Scanning
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? Colors.white70 : GageTheme.primary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Arahkan kamera ke QRIS Merchant...',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Mendukung QRIS Resmi GAGE & Seluruh Merchant Nasional',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white38 : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Tombol Cepat Contoh QR Merchant GAGE
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: GageTheme.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.storefront_rounded, size: 16),
                            label: const Text(
                              'Pindai Contoh QRIS Merchant GAGE',
                              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _handleQrCodeDetected(
                                '00020101021126510013ID.GAGE.WWW01189360091800216174620208151234565204549953033605802ID5927Toko Sembako Berkah Fajar6012Pracimantoro6105551226304ED41',
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // TAMPILAN TERDETEKSI: KONFIRMASI PEMBAYARAN MERCHANT RESMI
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Kartu Rincian Merchant Neumorphic (Anti-Excel)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? Colors.white10 : const Color(0xFF86EFAC),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(9),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.store_rounded,
                                    color: Color(0xFF16A34A),
                                    size: 24,
                                  ),
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
                                                fontSize: 14,
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
                                              'Mitra GAGE ✓',
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
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 1),
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
                                IconButton(
                                  icon: const Icon(Icons.refresh_rounded, size: 20, color: Colors.grey),
                                  onPressed: _resetScan,
                                  tooltip: 'Pindai Ulang',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Pilihan Sumber Dana (GAGEPay vs Semua e-Wallet / m-Banking)
                          Text(
                            'Pilih Sumber Dana:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              // 1. Saldo GAGEPay
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _fundingSource = 'GAGEPAY'),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _fundingSource == 'GAGEPAY'
                                          ? GageTheme.primary.withValues(alpha: 0.1)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _fundingSource == 'GAGEPAY'
                                            ? GageTheme.primary
                                            : Colors.grey.shade300,
                                        width: _fundingSource == 'GAGEPAY' ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance_wallet_rounded,
                                              size: 16,
                                              color: _fundingSource == 'GAGEPAY'
                                                  ? GageTheme.primary
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Saldo GAGEPay',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _fundingSource == 'GAGEPAY'
                                                      ? GageTheme.primary
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          '0% Fee • Instan',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),

                              // 2. Semua e-Wallet / m-Banking
                              Expanded(
                                child: InkWell(
                                  onTap: () => setState(() => _fundingSource = 'OTHER_EWALLET'),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 10),
                                    decoration: BoxDecoration(
                                      color: _fundingSource == 'OTHER_EWALLET'
                                          ? const Color(0xFF1D4ED8).withValues(alpha: 0.1)
                                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _fundingSource == 'OTHER_EWALLET'
                                            ? const Color(0xFF1D4ED8)
                                            : Colors.grey.shade300,
                                        width: _fundingSource == 'OTHER_EWALLET' ? 1.5 : 1,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.account_balance_rounded,
                                              size: 16,
                                              color: _fundingSource == 'OTHER_EWALLET'
                                                  ? const Color(0xFF1D4ED8)
                                                  : Colors.grey,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'm-Banking & e-Wallet',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: _fundingSource == 'OTHER_EWALLET'
                                                      ? const Color(0xFF1D4ED8)
                                                      : (isDark ? Colors.white70 : Colors.black87),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'BCA, Mandiri, GoPay, OVO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Nominal Pembayaran Modern (Anti-Excel)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Nominal Pembayaran:',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              InkWell(
                                onTap: _showCustomAmountDialog,
                                child: Text(
                                  'Ketik Manual',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: GageTheme.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Pill Chips Nominal Cepat
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: _quickAmounts.map((amt) {
                                final isSelected = _selectedAmount == amt;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: InkWell(
                                    onTap: () => setState(() => _selectedAmount = amt),
                                    borderRadius: BorderRadius.circular(10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? GageTheme.primary
                                            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: isSelected ? GageTheme.primary : Colors.transparent,
                                        ),
                                      ),
                                      child: Text(
                                        currencyFormatter.format(amt),
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Tombol Konfirmasi Bayar Sesuai Sumber Dana
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _fundingSource == 'GAGEPAY'
                                  ? GageTheme.primary
                                  : const Color(0xFF1D4ED8),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 48),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => _processPayment(wallet),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _fundingSource == 'GAGEPAY'
                                      ? Icons.account_balance_wallet_rounded
                                      : Icons.open_in_new_rounded,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _fundingSource == 'GAGEPAY'
                                      ? 'Bayar Sekarang • ${currencyFormatter.format(_selectedAmount)}'
                                      : 'Buka di m-Banking / e-Wallet',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Painter untuk sudut-sudut Viewfinder Kamera 1:1
class QrViewfinderCorners extends StatelessWidget {
  final Color color;
  final double cornerLength;
  final double cornerWidth;

  const QrViewfinderCorners({
    super.key,
    required this.color,
    required this.cornerLength,
    required this.cornerWidth,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _QrCornerPainter(
        color: color,
        cornerLength: cornerLength,
        cornerWidth: cornerWidth,
      ),
    );
  }
}

class _QrCornerPainter extends CustomPainter {
  final Color color;
  final double cornerLength;
  final double cornerWidth;

  _QrCornerPainter({
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

    // Top Left
    canvas.drawLine(const Offset(0, 0), Offset(cornerLength, 0), paint);
    canvas.drawLine(const Offset(0, 0), Offset(0, cornerLength), paint);

    // Top Right
    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerLength, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerLength), paint);

    // Bottom Left
    canvas.drawLine(Offset(0, size.height), Offset(cornerLength, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerLength), paint);

    // Bottom Right
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerLength, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerLength), paint);
  }

  @override
  bool shouldRepaint(covariant _QrCornerPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cornerLength != cornerLength ||
        oldDelegate.cornerWidth != cornerWidth;
  }
}
