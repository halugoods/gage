import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/shared/widgets/storefront_image.dart';

/// Full Screen Page: Pengaturan Tampilan Struk Kasir Thermal
/// Menampilkan pratinjau kertas thermal monospaced real-time, saklar tampilkan logo,
/// pengatur ukuran header (px), dan catatan footer struk.
class MerchantReceiptSettingsScreen extends StatefulWidget {
  final String storeName;
  final String? storeLogo;

  const MerchantReceiptSettingsScreen({
    super.key,
    this.storeName = 'Dimsum Sewu Pracimantoro',
    this.storeLogo,
  });

  @override
  State<MerchantReceiptSettingsScreen> createState() => _MerchantReceiptSettingsScreenState();
}

class _MerchantReceiptSettingsScreenState extends State<MerchantReceiptSettingsScreen> {
  int _headerPx = 20;
  final TextEditingController _footerCtrl = TextEditingController(
    text: 'Terima kasih atas kunjungan Anda!\nBarang yang sudah dibeli tidak dapat ditukar.',
  );
  bool _showStoreLogo = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _footerCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      setState(() {
        _headerPx = prefs.getInt('gage_receipt_header_px') ?? 20;
        final savedFooter = prefs.getString('gage_receipt_footer_text');
        if (savedFooter != null && savedFooter.isNotEmpty) {
          _footerCtrl.text = savedFooter;
        }
        _showStoreLogo = prefs.getBool('gage_receipt_show_logo') ?? true;
      });
    } catch (_) {}
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gage_receipt_header_px', _headerPx);
    await prefs.setString('gage_receipt_footer_text', _footerCtrl.text.trim());
    await prefs.setBool('gage_receipt_show_logo', _showStoreLogo);

    if (!mounted) return;
    setState(() => _isSaving = false);
    GageToast.show(context, 'Pengaturan struk berhasil disimpan', type: GageToastType.success);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final inputBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: textColor, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Pengaturan Struk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'PRATINJAU HASIL CETAK',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: subColor,
              ),
            ),
            const SizedBox(height: 8),

            // Live Thermal Receipt Preview
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0).withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Container(
                width: 288,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    if (_showStoreLogo) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: ColorFiltered(
                            colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation),
                            child: StorefrontImage(
                              path: widget.storeLogo ?? 'assets/images/resto_dimsum_sewu.png',
                              fit: BoxFit.cover,
                              fallback: const Icon(Icons.storefront_rounded, size: 22, color: Colors.black87),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Text(
                      widget.storeName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: _headerPx * 0.8,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'INV-GAGE-20261124-001\n24/11/2026  17:30\nKasir: Kasir Toko',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 10.5,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    _previewItemRow('Siomay Ayam Spesial', '2 x 15.000', '30.000'),
                    _previewItemRow('Dimsum Udang Keju', '1 x 18.000', '18.000'),
                    _previewItemRow('Es Teh Manis', '2 x 4.000', '8.000'),
                    const SizedBox(height: 6),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 6),
                    _previewSummaryRow('Total', '56.000', isBold: true),
                    _previewSummaryRow('Bayar: GAGEPay', '56.000'),
                    const SizedBox(height: 6),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _footerCtrl.text.isNotEmpty ? _footerCtrl.text : 'Terima kasih atas kunjungan Anda!',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 9.5,
                        color: Colors.black87,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Text(
              'KUSTOMISASI FORMAT STRUK',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.7,
                color: subColor,
              ),
            ),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle Logo di Header Struk
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image_outlined, color: Color(0xFF10B981), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tampilkan Logo Toko',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: textColor),
                            ),
                            Text(
                              'Cetak emblem logo monokrom di bagian atas struk',
                              style: TextStyle(fontSize: 11, color: subColor),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _showStoreLogo,
                        activeTrackColor: GageTheme.primary.withValues(alpha: 0.45),
                        activeThumbColor: GageTheme.primary,
                        onChanged: (val) {
                          HapticFeedback.selectionClick();
                          setState(() => _showStoreLogo = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: borderColor),
                  const SizedBox(height: 14),

                  // Slider Header (px)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ukuran Judul Header',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$_headerPx px',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _headerPx.clamp(12, 36).toDouble(),
                    min: 12,
                    max: 36,
                    divisions: 24,
                    activeColor: GageTheme.primary,
                    inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    label: '$_headerPx px',
                    onChanged: (v) => setState(() => _headerPx = v.round()),
                  ),
                  const SizedBox(height: 8),

                  // Footer Text Field
                  Text(
                    'Catatan Footer Struk',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _footerCtrl,
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(fontSize: 13, color: textColor),
                    decoration: InputDecoration(
                      hintText: 'Tuliskan ucapan terima kasih atau ketentuan pengembalian...',
                      hintStyle: TextStyle(fontSize: 12, color: subColor),
                      filled: true,
                      fillColor: inputBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: GageTheme.primary, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            border: Border(top: BorderSide(color: borderColor)),
          ),
          child: SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan Pengaturan Struk',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _previewItemRow(String name, String qtyPrice, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('  $qtyPrice', style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black87)),
              Text(total, style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black87)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _previewSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 10.5,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
