import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Sheet Pengaturan Struk Thermal Paritas 1:1 Nusa Kasir (Gambar 5).
/// Menampilkan Live Preview Struk Monospaced, Slider Header (px),
/// dan konfigurasi catatan footer struk kasir.
class MerchantReceiptSettingsSheet extends StatefulWidget {
  final String storeName;

  const MerchantReceiptSettingsSheet({
    super.key,
    this.storeName = 'Dimsum Sewu Pracimantoro',
  });

  static Future<void> show(BuildContext context, {String? storeName}) {
    return GageFloatingSheet.show(
      context: context,
      title: 'Pengaturan Struk',
      builder: (_) => MerchantReceiptSettingsSheet(
        storeName: storeName ?? 'Dimsum Sewu Pracimantoro',
      ),
    );
  }

  @override
  State<MerchantReceiptSettingsSheet> createState() => _MerchantReceiptSettingsSheetState();
}

class _MerchantReceiptSettingsSheetState extends State<MerchantReceiptSettingsSheet> {
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
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _headerPx = prefs.getInt('gage_receipt_header_px') ?? 20;
        final savedFooter = prefs.getString('gage_receipt_footer_text');
        if (savedFooter != null && savedFooter.isNotEmpty) {
          _footerCtrl.text = savedFooter;
        }
        _showStoreLogo = prefs.getBool('gage_receipt_show_logo') ?? true;
      });
    }
  }

  Future<void> _saveConfig() async {
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('gage_receipt_header_px', _headerPx);
    await prefs.setString('gage_receipt_footer_text', _footerCtrl.text.trim());
    await prefs.setBool('gage_receipt_show_logo', _showStoreLogo);

    if (mounted) {
      setState(() => _isSaving = false);
      Navigator.of(context).pop();
      GageToast.show(context, 'Pengaturan struk berhasil disimpan');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview Section Header
            Text(
              'Preview',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Preview = hasil cetak asli. Data contoh, ganti pengaturan untuk melihat perubahannya langsung.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 12),

            // Live Receipt Preview (Simulasi Kertas Thermal Nyata)
            Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Toko Header
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
                    // Item baris contoh
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
                    _previewSummaryRow('Bayar: Tunai', '60.000'),
                    _previewSummaryRow('Kembali', '4.000'),
                    const SizedBox(height: 6),
                    const Text(
                      '- - - - - - - - - - - - - - - - - - - - - -',
                      style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
                    ),
                    const SizedBox(height: 8),
                    // Footer
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

            // Slider Header (px)
            Text(
              'Header (px)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Row(
              children: [
                Text(
                  '12',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _headerPx.clamp(12, 36).toDouble(),
                    min: 12,
                    max: 36,
                    divisions: 24,
                    activeColor: GageTheme.primary,
                    inactiveColor: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    label: '$_headerPx px',
                    onChanged: (v) => setState(() => _headerPx = v.round()),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: GageTheme.primary.withValues(alpha: isDark ? 0.25 : 0.1),
                    borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 14),

            // Footer Text Field
            Text(
              'Footer Struk',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _footerCtrl,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white : const Color(0xFF0F172A)),
              decoration: InputDecoration(
                hintText: 'Tuliskan ucapan terima kasih atau ketentuan pengembalian...',
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: GageTheme.primary, width: 1.8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 20),

            // Tombol Simpan
            ElevatedButton(
              onPressed: _isSaving ? null : _saveConfig,
              style: ElevatedButton.styleFrom(
                backgroundColor: GageTheme.primary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Simpan Pengaturan Struk',
                      style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
                    ),
            ),
          ],
        ),
      );
  }

  Widget _previewItemRow(String name, String qtyPrice, String total) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(name, style: const TextStyle(fontFamily: 'Courier', fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.black87)),
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
