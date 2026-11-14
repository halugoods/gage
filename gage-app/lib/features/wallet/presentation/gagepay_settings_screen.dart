import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/utils/luhn_algorithm.dart';
import 'package:gage_app/providers/auth_provider.dart';
import 'package:gage_app/providers/wallet_provider.dart';
import 'package:gage_app/features/wallet/presentation/widgets/gage_atm_card_widget.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Layar Pengaturan GAGEPay (GagePaySettingsScreen)
/// Menyediakan manajemen komprehensif:
/// 1. Detail Kartu ATM 2.5D Digital & Fitur Bagikan Kartu 2.5D
/// 2. Keamanan: Ubah PIN 6-Digit & Autentikasi Biometrik (Fingerprint/Face Unlock)
/// 3. Limit Transaksi Harian (Transfer, QRIS, Penarikan)
/// 4. Rekening Penarikan Terdaftar
/// 5. Preferensi Notifikasi & Mode Privasi Saldo
/// 6. Bantuan & Lisensi Resmi PT Halu Goods Indonesia
class GagePaySettingsScreen extends StatefulWidget {
  const GagePaySettingsScreen({super.key});

  @override
  State<GagePaySettingsScreen> createState() => _GagePaySettingsScreenState();
}

class _GagePaySettingsScreenState extends State<GagePaySettingsScreen> {
  final GlobalKey _cardBoundaryKey = GlobalKey();
  bool _isSharingCard = false;
  bool _isCardFrozen = false;
  bool _isBiometricEnabled = true;
  bool _isPushNotificationEnabled = true;
  bool _isPrivacyModeEnabled = false;

  final currencyFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  /// Menangkap visual Kartu ATM 2.5D dan membagikannya sebagai PNG dengan teks ringkas
  Future<void> _shareAtmCard(String accountNumber, String userName) async {
    HapticFeedback.lightImpact();
    setState(() => _isSharingCard = true);

    try {
      final boundary = _cardBoundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      final tempDir = await getTemporaryDirectory();

      final shareText = 'Kartu GAGEPay: $accountNumber\n'
          'a.n. $userName\n'
          'Status: ${_isCardFrozen ? "Dibekukan Sementara" : "Aktif & Terverifikasi"}';

      List<XFile> files = [];
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();
          final filePath = '${tempDir.path}/kartu_gagepay_$accountNumber.png';
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
          subject: 'Kartu ATM Digital GAGEPay - $userName',
          files: files,
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSharingCard = false);
      GageToast.show(context, 'Gagal membagikan kartu rekening.', type: GageToastType.error);
    }
  }

  // Dialog Ubah PIN Transaksi
  void _showChangePinDialog(BuildContext context) {
    HapticFeedback.lightImpact();
    final pinCtrl = TextEditingController();
    final confirmPinCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Ubah PIN GAGEPay', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Masukkan 6 digit PIN baru untuk otorisasi transaksi belanja & transfer.',
              style: TextStyle(fontSize: 12.5, color: Colors.black54),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'PIN Baru (6 Digit)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: confirmPinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 6,
              decoration: InputDecoration(
                labelText: 'Konfirmasi PIN Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: GageTheme.primary,
              foregroundColor: Colors.white,
              shape: const StadiumBorder(),
              elevation: 0,
            ),
            onPressed: () {
              if (pinCtrl.text.length != 6 || pinCtrl.text != confirmPinCtrl.text) {
                GageToast.show(context, 'PIN harus 6 digit dan cocok.', type: GageToastType.warning);
                return;
              }
              Navigator.pop(ctx);
              HapticFeedback.heavyImpact();
              GageToast.show(context, 'PIN GAGEPay berhasil diperbarui!', type: GageToastType.success);
            },
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallet = context.watch<WalletProvider>();
    final auth = context.watch<AuthProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = auth.currentUser?.name ?? 'Pengguna GAGE';
    final accountNumber = wallet.accountNumber;
    final formattedAcc = LuhnAlgorithm.formatWithSpaces(accountNumber);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Pengaturan GAGEPay',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Section: Detail Kartu ATM 2.5D Digital
            _buildSectionHeader('DETAIL KARTU DIGITAL'),
            const SizedBox(height: 10),

            // Visual Kartu ATM 2.5D Digital
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: RepaintBoundary(
                  key: _cardBoundaryKey,
                  child: GageAtmCardWidget(
                    accountNumber: accountNumber,
                    userName: userName,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Dua Tombol Aksi Kartu: Salin Rekening & Bagikan Kartu 2.5D
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                      foregroundColor: isDark ? Colors.white : const Color(0xFF1E293B),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: accountNumber));
                      HapticFeedback.selectionClick();
                      GageToast.show(context, 'Nomor rekening $formattedAcc berhasil disalin!', type: GageToastType.success);
                    },
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Salin Rekening', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.primary,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                    ),
                    onPressed: _isSharingCard ? null : () => _shareAtmCard(accountNumber, userName),
                    icon: _isSharingCard
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.share_rounded, size: 16),
                    label: const Text('Bagikan Kartu 2.5D', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // Toggle Kunci Kartu Sementara
            Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Kunci Kartu Sementara',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Cegah transaksi keluar sementara waktu saat kartu tidak digunakan.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  value: _isCardFrozen,
                  activeColor: GageTheme.primary,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() => _isCardFrozen = val);
                    GageToast.show(
                      context,
                      val ? 'Kartu GAGEPay berhasil dibekukan sementara.' : 'Kartu GAGEPay kembali aktif.',
                      type: val ? GageToastType.warning : GageToastType.success,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 2. Section: Keamanan & Autentikasi
            _buildSectionHeader('KEAMANAN & AUTENTIKASI'),
            const SizedBox(height: 8),

            Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.lock_reset_rounded, color: GageTheme.primary),
                      title: const Text('Ubah PIN GAGEPay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Perbarui 6 digit PIN transaksi Anda', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () => _showChangePinDialog(context),
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    SwitchListTile(
                      secondary: const Icon(Icons.fingerprint_rounded, color: Color(0xFF0D9488)),
                      title: const Text('Biometrik (Sidik Jari / Wajah)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Gunakan biometrik untuk login & pembayaran cepat', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isBiometricEnabled,
                      activeColor: GageTheme.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _isBiometricEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 3. Section: Limit Transaksi Harian
            _buildSectionHeader('LIMIT TRANSAKSI HARIAN'),
            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _buildLimitRow('Transfer Sesama GAGEPay', 'Rp 10.000.000 / hari', Icons.send_rounded),
                  const Divider(height: 20),
                  _buildLimitRow('Pembayaran QRIS Merchant', 'Rp 5.000.000 / hari', Icons.qr_code_scanner_rounded),
                  const Divider(height: 20),
                  _buildLimitRow('Penarikan Saldo ke Bank', 'Rp 10.000.000 / hari', Icons.account_balance_rounded),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 4. Section: Preferensi Notifikasi & Privasi
            _buildSectionHeader('PREFERENSI & PRIVASI'),
            const SizedBox(height: 8),

            Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      secondary: const Icon(Icons.notifications_active_outlined, color: Color(0xFF2563EB)),
                      title: const Text('Notifikasi Transaksi Real-Time', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Dapatkan push notifikasi saat saldo masuk atau keluar', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isPushNotificationEnabled,
                      activeColor: GageTheme.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _isPushNotificationEnabled = val);
                      },
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    SwitchListTile(
                      secondary: const Icon(Icons.visibility_off_outlined, color: Color(0xFF7C3AED)),
                      title: const Text('Mode Privasi Saldo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Sembunyikan angka saldo saat pertama kali membuka dompet', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      value: _isPrivacyModeEnabled,
                      activeColor: GageTheme.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _isPrivacyModeEnabled = val);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 5. Section: Pusat Bantuan & Lisensi
            _buildSectionHeader('INFORMASI & BANTUAN'),
            const SizedBox(height: 8),

            Material(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.support_agent_rounded, color: Color(0xFFD97706)),
                      title: const Text('Layanan Bantuan 24/7', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('Hubungi tim helpdesk resmi GAGE Pracimantoro', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () {
                        GageToast.show(context, 'Menghubungkan ke Pusat Bantuan GAGE...', type: GageToastType.info);
                      },
                    ),
                    Divider(height: 1, color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
                    ListTile(
                      leading: const Icon(Icons.verified_user_outlined, color: Color(0xFF16A34A)),
                      title: const Text('Lisensi & Regulasi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                      subtitle: const Text('GAGE by PT Halu Goods Indonesia', style: TextStyle(fontSize: 11, color: Colors.grey)),
                      trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      onTap: () {
                        GageToast.show(context, 'Lisensi Resmi PT Halu Goods Indonesia', type: GageToastType.info);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w900,
        color: Color(0xFF94A3B8),
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildLimitRow(String title, String limit, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: const Color(0xFF64748B)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          limit,
          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }
}
