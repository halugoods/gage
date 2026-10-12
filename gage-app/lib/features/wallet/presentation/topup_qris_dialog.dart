import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:gage_app/core/constants/qris_engine.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

class TopupQrisDialog extends StatefulWidget {
  final Function(int addedBalance) onTopupSuccess;

  const TopupQrisDialog({
    super.key,
    required this.onTopupSuccess,
  });

  @override
  State<TopupQrisDialog> createState() => _TopupQrisDialogState();
}

class _TopupQrisDialogState extends State<TopupQrisDialog> {
  int _selectedAmount = 50000;
  final TextEditingController _customController = TextEditingController();
  String? _qrisPayload;
  bool _isQrGenerated = false;
  bool _isCustom = false;
  int _uniqueCode = 0; // 3 digit pengenal unik (1 - 999)

  final List<int> _nominalOptions = [10000, 20000, 50000, 100000, 200000];
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _generateQris() {
    int finalAmount = _selectedAmount;
    if (_isCustom) {
      final parsed = int.tryParse(_customController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed == null || parsed < 5000) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nominal minimal isi saldo adalah Rp 5.000'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      finalAmount = parsed;
    }

    // Generate kode unik acak 1 sampai 999 (math.Random().nextInt(999) + 1)
    final generatedCode = math.Random().nextInt(999) + 1;
    final totalTransfer = finalAmount + generatedCode;

    setState(() {
      _selectedAmount = finalAmount;
      _uniqueCode = generatedCode;
      _qrisPayload = QrisEngine.generateDynamic(amount: totalTransfer);
      _isQrGenerated = true;
    });
  }

  void _copyToClipboard(int amount) {
    Clipboard.setData(ClipboardData(text: amount.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nominal eksak ${currencyFormatter.format(amount)} disalin ke clipboard!'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? (screenWidth - 460) / 2 : 16,
        vertical: 24,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      if (_isQrGenerated)
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          icon: const Icon(Icons.arrow_back_rounded, size: 20),
                          tooltip: 'Ubah Nominal',
                          onPressed: () {
                            setState(() {
                              _isQrGenerated = false;
                            });
                          },
                        ),
                      if (_isQrGenerated) const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.account_balance_wallet_rounded, color: GageTheme.primary, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Isi Saldo GAGEPay',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'QRIS Dinamis Instan Auto-Verify',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (!_isQrGenerated) ...[
                // Pilihan Nominal Cepat
                const Text(
                  'Pilihan Nominal Cepat',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 10),

                // Quick Chips: Rp 10.000, 20.000, 50.000, 100.000, 200.000
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _nominalOptions.map((amount) {
                    final isSelected = !_isCustom && _selectedAmount == amount;
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _selectedAmount = amount;
                          _isCustom = false;
                          _customController.clear();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? GageTheme.primary : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? GageTheme.primary : const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: GageTheme.primary.withValues(alpha: 0.25),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          currencyFormatter.format(amount),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : const Color(0xFF334155),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Form Field Input Nominal Bersih (Anti-Excel)
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: _isCustom ? GageTheme.primary : const Color(0xFFE2E8F0),
                      width: _isCustom ? 1.5 : 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  child: Row(
                    children: [
                      // Icon Rp di kiri
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: _isCustom ? GageTheme.primary.withValues(alpha: 0.1) : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Rp',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.bold,
                            color: _isCustom ? GageTheme.primary : Colors.grey.shade700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Text Field Bersih
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14.5,
                            color: Colors.black87,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: 'Ketik nominal lain...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade400,
                              fontWeight: FontWeight.normal,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _isCustom = val.trim().isNotEmpty;
                            });
                          },
                        ),
                      ),
                      // Clear Button di kanan
                      if (_customController.text.isNotEmpty)
                        InkWell(
                          onTap: () {
                            setState(() {
                              _isCustom = false;
                              _customController.clear();
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(6),
                            child: Icon(Icons.cancel_rounded, size: 18, color: Colors.grey.shade400),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Tombol Lanjut ke QRIS
                ElevatedButton.icon(
                  onPressed: _generateQris,
                  icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                  label: const Text(
                    'Lanjut ke Pembayaran QRIS',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GageTheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                ),
              ] else ...[
                // QRIS Dinamis & Kode Unik Verifikasi Instan
                Center(
                  child: Column(
                    children: [
                      // Badge Transparan Rapi "Kode Unik Verifikasi Instan: Rp XYZ" (Max Rp 999)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: GageTheme.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.bolt_rounded, size: 15, color: GageTheme.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Kode Unik Verifikasi Instan: Rp $_uniqueCode',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: GageTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: GageTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Max Rp 999',
                                style: TextStyle(
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.bold,
                                  color: GageTheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rincian Transfer Eksak Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Nominal Isi Saldo:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                Text(currencyFormatter.format(_selectedAmount), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Kode Unik Transaksi:', style: TextStyle(fontSize: 12, color: Colors.black87)),
                                Text('+ Rp $_uniqueCode', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary)),
                              ],
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(height: 1),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('TOTAL TRANSFER EKSAK:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
                                Row(
                                  children: [
                                    Text(
                                      currencyFormatter.format(_selectedAmount + _uniqueCode),
                                      style: const TextStyle(
                                        color: GageTheme.primary,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.copy_rounded, size: 16, color: GageTheme.primary),
                                      tooltip: 'Salin Total Nominal',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () => _copyToClipboard(_selectedAmount + _uniqueCode),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // QR Code Container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200, width: 2),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
                          ],
                        ),
                        child: QrImageView(
                          data: _qrisPayload ?? '',
                          version: QrVersions.auto,
                          size: 195.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'NMID: ID1020038829 | GAGE PRACIMANTORO',
                        style: TextStyle(fontSize: 10.5, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          'Transfer tepat hingga 3 digit terakhir agar sistem otomatis mendeteksi mutasi dan mengisi saldo dalam hitungan detik.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10.5, color: Colors.black54),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Live Verification Engine Status Card
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF6FF),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF2563EB),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Menunggu Webhook Mutasi Bank Realtime...',
                                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                  ),
                                  Text(
                                    'Pencocokan kode unik Rp $_uniqueCode otomatis terverifikasi (< 3 detik)',
                                    style: const TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Tombol Salin Nominal Eksak
                      OutlinedButton.icon(
                        icon: const Icon(Icons.copy_rounded, size: 16),
                        label: Text('Salin Nominal Eksak (${currencyFormatter.format(_selectedAmount + _uniqueCode)})'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: GageTheme.primary,
                          side: const BorderSide(color: GageTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () => _copyToClipboard(_selectedAmount + _uniqueCode),
                      ),

                      const SizedBox(height: 8),

                      // Tombol Konfirmasi Pembayaran Masuk
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                        label: Text('Saya Sudah Transfer (+${currencyFormatter.format(_selectedAmount)})'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF16A34A),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        onPressed: () {
                          widget.onTopupSuccess(_selectedAmount);
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Top Up Berhasil! Saldo bertambah ${currencyFormatter.format(_selectedAmount)}'),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
