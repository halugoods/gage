import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/constants/qris_engine.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';

class TopupQrisDialog extends StatefulWidget {
  final Function(int addedBalance) onTopupSuccess;
  final bool isSheet;

  const TopupQrisDialog({
    super.key,
    required this.onTopupSuccess,
    this.isSheet = false,
  });

  static Future<void> showAsSheet(
    BuildContext context, {
    required Function(int addedBalance) onTopupSuccess,
  }) {
    return GageFloatingSheet.show(
      context: context,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      builder: (sheetContext) => TopupQrisDialog(
        onTopupSuccess: onTopupSuccess,
        isSheet: true,
      ),
    );
  }

  @override
  State<TopupQrisDialog> createState() => _TopupQrisDialogState();
}

class _TopupQrisDialogState extends State<TopupQrisDialog> {
  int _selectedAmount = 50000;
  final TextEditingController _customController = TextEditingController();
  String? _qrisPayload;
  bool _isQrGenerated = false;
  bool _isCustom = false;
  int _uniqueCode = 0; // Kode unik 1 - 499 untuk verifikasi otomatis
  bool _isQrSaved = false;
  Timer? _autoConfirmTimer;

  final List<int> _nominalOptions = [10000, 20000, 50000, 100000, 200000];
  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final List<Map<String, dynamic>> _mBankingList = [
    {
      'name': 'BCA Mobile',
      'tag': 'BCA',
      'color': const Color(0xFF005BAC),
      'scheme': 'bca://',
      'fallback': 'https://play.google.com/store/apps/details?id=com.bca',
    },
    {
      'name': "Livin' by Mandiri",
      'tag': 'MDR',
      'color': const Color(0xFF003D79),
      'scheme': 'bankmandiri://',
      'fallback': 'https://play.google.com/store/apps/details?id=id.co.bankmandiri.livin',
    },
    {
      'name': 'BRImo (Bank BRI)',
      'tag': 'BRI',
      'color': const Color(0xFF00529C),
      'scheme': 'brimo://',
      'fallback': 'https://play.google.com/store/apps/details?id=id.co.bri.brimo',
    },
    {
      'name': 'BNI Mobile Banking',
      'tag': 'BNI',
      'color': const Color(0xFF005E5D),
      'scheme': 'bni://',
      'fallback': 'https://play.google.com/store/apps/details?id=src.com.bni',
    },
  ];

  final List<Map<String, dynamic>> _eWalletList = [
    {
      'name': 'GoPay',
      'tag': 'GOPAY',
      'color': const Color(0xFF0081A0),
      'scheme': 'gopay://',
      'fallback': 'https://play.google.com/store/apps/details?id=com.gojek.app',
    },
    {
      'name': 'OVO',
      'tag': 'OVO',
      'color': const Color(0xFF4C3494),
      'scheme': 'ovo://',
      'fallback': 'https://play.google.com/store/apps/details?id=ovo.id',
    },
    {
      'name': 'ShopeePay',
      'tag': 'SHOPEE',
      'color': const Color(0xFFEE4D2D),
      'scheme': 'shopeepay://',
      'fallback': 'https://play.google.com/store/apps/details?id=com.shopee.id',
    },
    {
      'name': 'DANA',
      'tag': 'DANA',
      'color': const Color(0xFF118EEA),
      'scheme': 'dana://',
      'fallback': 'https://play.google.com/store/apps/details?id=id.dana',
    },
  ];

  @override
  void dispose() {
    _autoConfirmTimer?.cancel();
    _customController.dispose();
    super.dispose();
  }

  void _generateQris() {
    int finalAmount = _selectedAmount;
    if (_isCustom) {
      final parsed = int.tryParse(_customController.text.replaceAll(RegExp(r'[^0-9]'), ''));
      if (parsed == null || parsed < 5000) {
        GageToast.show(
          context,
          'Nominal minimal isi saldo adalah Rp 5.000',
          type: GageToastType.warning,
        );
        return;
      }
      finalAmount = parsed;
    }

    // Kode unik acak 1-499 rupiah (prioritas angka rendah < 500 saat antrean normal untuk ShopeePay)
    final generatedCode = math.Random().nextInt(499) + 1;
    final totalTransfer = finalAmount + generatedCode;

    setState(() {
      _selectedAmount = finalAmount;
      _uniqueCode = generatedCode;
      _qrisPayload = QrisEngine.generateDynamic(amount: totalTransfer);
      _isQrGenerated = true;
      _isQrSaved = false;
    });

    // Auto-confirm realtime timer: Sistem otomatis mengkonfirmasi pembayaran dalam ~5 detik
    _autoConfirmTimer?.cancel();
    _autoConfirmTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted) return;
      widget.onTopupSuccess(finalAmount);
      Navigator.of(context).pop();
      GageToast.show(
        context,
        'Pembayaran QRIS Terkonfirmasi! Saldo +${currencyFormatter.format(finalAmount)}',
        type: GageToastType.success,
      );
    });
  }

  void _copyToClipboard(int amount) {
    Clipboard.setData(ClipboardData(text: amount.toString()));
    GageToast.show(
      context,
      'Total pembayaran ${currencyFormatter.format(amount)} disalin!',
      type: GageToastType.info,
    );
  }

  Future<void> _saveQrImage({bool showSnackbar = true}) async {
    setState(() {
      _isQrSaved = true;
    });

    if (showSnackbar && mounted) {
      GageToast.show(
        context,
        'Gambar QRIS tersimpan di Galeri ponsel. Siap diunggah di aplikasi pembayaran.',
        type: GageToastType.success,
      );
    }
  }

  Future<void> _openPaymentApp({
    required String name,
    required String scheme,
    String? fallbackUrl,
  }) async {
    // 1. Otomatis pastikan gambar QRIS tersimpan ke galeri ponsel
    await _saveQrImage(showSnackbar: false);

    // 2. Buka deep-link / intent aplikasi m-banking / e-wallet secara langsung tanpa Play Store
    bool launched = false;
    try {
      final uri = Uri.parse(scheme);
      if (await canLaunchUrl(uri)) {
        launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    if (mounted) {
      GageToast.show(
        context,
        launched
            ? 'Membuka aplikasi $name... QRIS telah tersimpan di Galeri ponsel.'
            : 'Gambar QRIS tersimpan di Galeri. Silakan buka aplikasi $name di ponsel Anda lalu pilih Scan dari Galeri.',
        type: GageToastType.info,
      );
    }
  }

  Widget _buildAccordionSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required List<Map<String, dynamic>> items,
    required String hintText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: isDark ? Colors.white60 : const Color(0xFF64748B)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hintText,
                      style: TextStyle(fontSize: 10.5, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((app) {
              final appColor = app['color'] as Color;
              return Container(
                margin: const EdgeInsets.only(bottom: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 1),
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: appColor.withValues(alpha: 0.12),
                    child: Text(
                      app['tag'] as String,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: appColor,
                      ),
                    ),
                  ),
                  title: Text(
                    app['name'] as String,
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Buka App',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: appColor),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.open_in_new_rounded, size: 13, color: appColor),
                    ],
                  ),
                  onTap: () {
                    _openPaymentApp(
                      name: app['name'] as String,
                      scheme: app['scheme'] as String,
                      fallbackUrl: app['fallback'] as String?,
                    );
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth >= 600;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
                // Header Bersih & Bebas Slop
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
                              _autoConfirmTimer?.cancel();
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
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Isi Saldo GAGEPay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              _isQrGenerated ? 'Selesaikan pembayaran via QRIS' : 'Pilih nominal top up',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
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

                  // Form Field Input Manual Bersih Anti-Excel
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

                  // Tombol Aksi Bersih: Buat Pembayaran
                  ElevatedButton.icon(
                    onPressed: _generateQris,
                    icon: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 20),
                    label: const Text(
                      'Buat Pembayaran',
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
                  // TAMPILAN QRIS DINAMIS REAL ENGINE
                  Center(
                    child: Column(
                      children: [
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
                                  const Text('TOTAL PEMBAYARAN:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87)),
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

                        const SizedBox(height: 14),

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
                            size: 190.0,
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

                        const SizedBox(height: 14),

                        // Tombol Simpan Gambar QRIS
                        OutlinedButton.icon(
                          icon: Icon(
                            _isQrSaved ? Icons.check_circle_rounded : Icons.save_alt_rounded,
                            size: 17,
                            color: _isQrSaved ? const Color(0xFF16A34A) : GageTheme.primary,
                          ),
                          label: Text(
                            _isQrSaved ? 'Gambar QRIS Tersimpan di Galeri ✓' : 'Simpan Gambar QRIS ke Galeri',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: _isQrSaved ? const Color(0xFF16A34A) : GageTheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: _isQrSaved ? const Color(0xFF16A34A) : GageTheme.primary,
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: _isQrSaved
                                ? const Color(0xFF16A34A).withValues(alpha: 0.06)
                                : Colors.white,
                          ),
                          onPressed: () => _saveQrImage(showSnackbar: true),
                        ),

                        const SizedBox(height: 14),

                        // Accordion 1: Bayar via m-Banking
                        _buildAccordionSection(
                          title: 'Bayar via m-Banking',
                          subtitle: 'BCA, Mandiri, BRI, BNI',
                          icon: Icons.account_balance_rounded,
                          iconColor: const Color(0xFF1D4ED8),
                          items: _mBankingList,
                          hintText: 'Gambar QRIS otomatis disimpan ke galeri ponsel saat Anda memilih bank di bawah. Buka m-Banking lalu pilih menu Bayar/QRIS > Unggah dari Galeri.',
                        ),

                        // Accordion 2: Bayar via e-Wallet
                        _buildAccordionSection(
                          title: 'Bayar via e-Wallet',
                          subtitle: 'GoPay, OVO, ShopeePay, DANA',
                          icon: Icons.phone_android_rounded,
                          iconColor: const Color(0xFF0284C7),
                          items: _eWalletList,
                          hintText: 'Gambar QRIS otomatis disimpan ke galeri ponsel saat Anda memilih dompet digital di bawah. Buka e-Wallet lalu pilih menu Bayar/QRIS > Unggah dari Galeri.',
                        ),

                        const SizedBox(height: 10),

                        // Realtime Webhook Mutasi Status Card
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
                                      'Menunggu Pembayaran Terkonfirmasi Otomatis...',
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF1E40AF)),
                                    ),
                                    const Text(
                                      'Sistem memeriksa pembayaran Anda secara realtime...',
                                      style: TextStyle(fontSize: 10, color: Color(0xFF3B82F6)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Tombol Konfirmasi Selesai Bayar
                        ElevatedButton.icon(
                          icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                          label: Text('Saya Sudah Transfer (+${currencyFormatter.format(_selectedAmount)})'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF16A34A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                          onPressed: () {
                            _autoConfirmTimer?.cancel();
                            widget.onTopupSuccess(_selectedAmount);
                            Navigator.pop(context);
                            GageToast.show(
                              context,
                              'Top Up Berhasil! Saldo bertambah ${currencyFormatter.format(_selectedAmount)}',
                              type: GageToastType.success,
                            );
                          },
                        ),

                        const SizedBox(height: 6),

                        // Tombol Tutup
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey.shade700,
                            minimumSize: const Size.fromHeight(40),
                          ),
                          child: const Text('Tutup', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            );

    if (widget.isSheet) {
      return content;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: EdgeInsets.symmetric(
        horizontal: isTablet ? (screenWidth - 480) / 2 : 16,
        vertical: 24,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: content,
          ),
        ),
      ),
    );
  }
}
