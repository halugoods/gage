import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Penuh Terima Saldo GAGEPay
/// - Layar penuh (Full Screen) lega dan fokus
/// - QR Code dinamis (berubah saat nominal diatur)
/// - Kartu ATM 2.5D dirender off-screen khusus untuk kebutuhan share gambar
/// - Teks bagikan bersih tanpa fluff (Hanya No Rek, a.n., dan nominal)
class GagePayReceiveScreen extends StatefulWidget {
  final String accountNumber;
  final String userName;

  const GagePayReceiveScreen({
    super.key,
    required this.accountNumber,
    required this.userName,
  });

  @override
  State<GagePayReceiveScreen> createState() => _GagePayReceiveScreenState();
}

class _GagePayReceiveScreenState extends State<GagePayReceiveScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  int? _requestedAmount;
  final TextEditingController _amountCtrl = TextEditingController();
  bool _isRequestingNominal = false;
  bool _isSharingCard = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _copyAccount(BuildContext context) {
    Clipboard.setData(ClipboardData(text: widget.accountNumber));
    HapticFeedback.selectionClick();
    GageToast.show(
      context,
      'Nomor rekening ${widget.accountNumber} berhasil disalin!',
      type: GageToastType.success,
    );
  }

  /// Menangkap visual Kartu ATM 2.5D dari off-screen render dan membagikannya dengan teks ringkas
  Future<void> _shareAccountCard() async {
    HapticFeedback.lightImpact();
    setState(() => _isSharingCard = true);

    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final tempDir = await getTemporaryDirectory();

      final amtText = _requestedAmount != null && _requestedAmount! > 0
          ? '\nNominal: ${currencyFormatter.format(_requestedAmount)}'
          : '';

      // Teks ringkas, padat, dan bebas AI slop sesuai instruksi pengguna
      final shareText = 'Rekening GAGEPay: ${widget.accountNumber}\n'
          'a.n. ${widget.userName}$amtText';

      List<XFile> files = [];
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final filePath = '${tempDir.path}/kartu_gagepay_${widget.accountNumber}.png';
          final file = File(filePath);
          await file.writeAsBytes(pngBytes);
          files.add(XFile(file.path, mimeType: 'image/png'));
        }
      }

      if (!mounted) return;
      setState(() => _isSharingCard = false);

      await SharePlus.instance.share(
        ShareParams(
          text: shareText,
          subject: 'Nomor Rekening GAGEPay ${widget.userName}',
          files: files,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSharingCard = false);
      GageToast.show(context, 'Gagal membagikan kartu rekening.', type: GageToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final formattedAcc = LuhnAlgorithm.formatWithSpaces(widget.accountNumber);

    // Payload QR Code Dinamis: Mengikut sertakan nominal bila telah ditentukan
    final amtParam = _requestedAmount != null && _requestedAmount! > 0
        ? '&amount=$_requestedAmount'
        : '';
    final qrPayload =
        'gagepay://transfer?to=${widget.accountNumber}&name=${Uri.encodeComponent(widget.userName)}$amtParam';

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Terima Saldo',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: Stack(
        children: [
          // 0. Off-screen 2.5D ATM Card Widget (HANYA dirender di background untuk kebutuhan share gambar)
          Positioned(
            left: -9999,
            top: -9999,
            child: RepaintBoundary(
              key: _cardBoundaryKey,
              child: SizedBox(
                width: 320,
                child: GageAtmCardWidget(
                  accountNumber: widget.accountNumber,
                  userName: widget.userName,
                  requestedAmount: _requestedAmount,
                ),
              ),
            ),
          ),

          // 1. Konten Utama Layar Penuh
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      // Card Nomor Rekening GAGEPay
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'NOMOR REKENING GAGEPAY',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: isDark ? Colors.white54 : const Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formattedAcc,
                                    style: TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 1.2,
                                      fontFamily: 'monospace',
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'a.n. ${widget.userName}',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GageTheme.primary,
                                foregroundColor: Colors.white,
                                shape: const StadiumBorder(),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _copyAccount(context),
                              icon: const Icon(Icons.copy_rounded, size: 14),
                              label: const Text(
                                'Salin',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Card QR Code Dinamis
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                          boxShadow: const [
                            BoxShadow(color: Color(0x18000000), blurRadius: 18, offset: Offset(0, 6)),
                          ],
                        ),
                        child: Column(
                          children: [
                            QrImageView(
                              data: qrPayload,
                              version: QrVersions.auto,
                              size: 220.0,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF0F172A),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 12),
                            // Badge Nominal Tagihan (Jika Dinamis di-set)
                            if (_requestedAmount != null && _requestedAmount! > 0) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(color: GageTheme.primary.withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'Tagihan: ${currencyFormatter.format(_requestedAmount)}',
                                      style: const TextStyle(
                                        color: GageTheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    InkWell(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        setState(() {
                                          _requestedAmount = null;
                                          _amountCtrl.clear();
                                        });
                                      },
                                      child: const Icon(Icons.cancel_rounded, size: 16, color: GageTheme.primary),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              Text(
                                'Scan QR code untuk bayar atau transfer langsung',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      if (_isRequestingNominal) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: GageTheme.primary.withValues(alpha: 0.4)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _amountCtrl,
                                  keyboardType: TextInputType.number,
                                  autofocus: true,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    hintText: 'Contoh: 50000',
                                    prefixText: 'Rp ',
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: GageTheme.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  final val = int.tryParse(_amountCtrl.text.trim());
                                  setState(() {
                                    _requestedAmount = val;
                                    _isRequestingNominal = false;
                                  });
                                  HapticFeedback.selectionClick();
                                },
                                child: const Text('Terapkan', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar: Tombol Kanan-Kiri Berdampingan
              Container(
                padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: GageTheme.primary, width: 1.5),
                            foregroundColor: GageTheme.primary,
                            shape: const StadiumBorder(),
                          ),
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            setState(() => _isRequestingNominal = !_isRequestingNominal);
                          },
                          icon: Icon(
                            _requestedAmount != null ? Icons.edit_note_rounded : Icons.tune_rounded,
                            size: 19,
                          ),
                          label: Text(
                            _requestedAmount != null ? 'Ubah Nominal' : 'Set Nominal',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: GageTheme.primary,
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                            elevation: 0,
                          ),
                          onPressed: _isSharingCard ? null : _shareAccountCard,
                          icon: _isSharingCard
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.share_rounded, size: 19),
                          label: const Text(
                            'Bagikan Detail',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Widget Kartu ATM 2.5D Digital Virtual GAGEPay (Digunakan khusus untuk off-screen render PNG)
class GageAtmCardWidget extends StatelessWidget {
  final String accountNumber;
  final String userName;
  final int? requestedAmount;

  const GageAtmCardWidget({
    super.key,
    required this.accountNumber,
    required this.userName,
    this.requestedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final formattedAcc = LuhnAlgorithm.formatWithSpaces(accountNumber);

    return AspectRatio(
      aspectRatio: 1.586, // Standar ISO ID-1 credit/debit card ratio
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF18181B), // Dark Titanium Obsidian
              Color(0xFF27131A), // Deep Crimson Ruby
              Color(0xFF0F0F12),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFFDC2626).withValues(alpha: 0.55),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: Stack(
            children: [
              // Efek Spekular Cahaya Studio 2.5D
              Positioned(
                top: -60,
                right: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.12),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              // Konten Kartu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Baris Atas: Branding GAGEPAY by Halu Goods Indonesia
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'GAGEPAY',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              Text(
                                'by Halu Goods Indonesia',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 9,
                                  letterSpacing: 0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.white24, width: 0.8),
                          ),
                          child: const Text(
                            'REKENING UTAMA',
                            style: TextStyle(
                              color: Color(0xFFFDE047),
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Baris Tengah: Realistic Gold EMV Chip & Contactless Wave
                    Row(
                      children: [
                        // Chip EMV Emas
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFDE047), Color(0xFFCA8A04), Color(0xFFEAB308)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFFEF08A), width: 0.8),
                          ),
                          child: CustomPaint(
                            painter: _EmvChipPainter(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.contactless_rounded,
                          color: Colors.white.withValues(alpha: 0.65),
                          size: 22,
                        ),
                      ],
                    ),

                    // Baris Nomor Rekening Timbul (Embossed 12-Digit)
                    Text(
                      formattedAcc,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.2,
                        fontFamily: 'monospace',
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(1, 2),
                          ),
                        ],
                      ),
                    ),

                    // Baris Bawah: Nama Pemilik & Tagihan (jika ada)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'NAMA PEMILIK',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.55),
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                userName.toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (requestedAmount != null && requestedAmount! > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: GageTheme.primary,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 4, offset: Offset(0, 2)),
                              ],
                            ),
                            child: Text(
                              'Rp ${requestedAmount.toString().replaceAllMapped(RegExp(r"(\d{1,3})(?=(\d{3})+(?!\d))"), (m) => "${m[1]}.")}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
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
    );
  }
}

/// Painter garis-garis mikro chip EMV kartu ATM
class _EmvChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF78350F).withValues(alpha: 0.7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    // Garis pembagi horizontal
    canvas.drawLine(Offset(0, h * 0.5), Offset(w, h * 0.5), paint);
    // Garis pembagi vertikal
    canvas.drawLine(Offset(w * 0.35, 0), Offset(w * 0.35, h), paint);
    canvas.drawLine(Offset(w * 0.65, 0), Offset(w * 0.65, h), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
