import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Dialog & Bottom Sheet Transparansi Layanan dan Ketentuan Biaya GAGE Pracimantoro
/// Berisi penjelasan 3 Prinsip Layanan Transparan Komersial & Legal Universal:
/// 1. Perjanjian Layanan Pengantaran Mitra Pengemudi (tarif berbasis kilometer riil)
/// 2. Kuasa Pembelian Toko Resmi (jasa titip beli kebutuhan di gerai mitra terdaftar)
/// 3. Transparansi Pembulatan Biaya Antar Rp 500 (alokasi subsidi tarif & pemeliharaan aplikasi GAGE)
class ServiceTransparencyDialog extends StatelessWidget {
  /// SharedPreferences key untuk menyimpan persetujuan ketentuan layanan transparan
  static const String prefKey = 'service_transparency_accepted';

  final bool isDialogMode;

  const ServiceTransparencyDialog({
    super.key,
    this.isDialogMode = false,
  });

  /// Cek apakah pengguna sudah pernah menyetujui ketentuan transparansi layanan
  static Future<bool> isAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reset status persetujuan (untuk testing / reset preferensi akun)
  static Future<void> resetAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }

  /// Tampilkan ServiceTransparencyDialog dalam bentuk Bottom Sheet elegan
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ServiceTransparencyDialog(isDialogMode: false),
    );
  }

  /// Tampilkan ServiceTransparencyDialog dalam bentuk Modal Dialog
  static Future<bool?> showAsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: const ServiceTransparencyDialog(isDialogMode: true),
      ),
    );
  }

  /// Static helper utama: Mengecek apakah pengguna sudah setuju,
  /// jika belum tampilkan dialog/bottom sheet dan kembalikan true saat disetujui.
  static Future<bool> checkAndShow(BuildContext context, {bool forceShow = false}) async {
    if (!forceShow) {
      final alreadyAccepted = await isAccepted();
      if (alreadyAccepted) return true;
    }
    if (!context.mounted) return false;
    final result = await show(context);
    return result == true;
  }

  Future<void> _handleAccept(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(prefKey, true);
    } catch (e) {
      debugPrint('Error saving service_transparency_accepted: $e');
    }
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * (isDialogMode ? 0.85 : 0.88);

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: GageTheme.surface,
        borderRadius: isDialogMode
            ? BorderRadius.circular(24)
            : const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle untuk mode bottom sheet
          if (!isDialogMode) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: GageTheme.accentGreen.withAlpha(25),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: GageTheme.accentGreen,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GageTheme.accentGreen.withAlpha(20),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'STANDAR LAYANAN RESMI',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: GageTheme.accentGreen,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Ketentuan Layanan & Transparansi Biaya',
                        style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                          color: GageTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: GageTheme.textSecondary, size: 22),
                  onPressed: () => Navigator.of(context).pop(false),
                  tooltip: 'Tutup',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Body Berisi Penjelasan 3 Prinsip Layanan Transparan
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ringkasan Pengantar
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: GageTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withAlpha(35)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: GageTheme.primary, size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Transaksi di GAGE Pracimantoro dijalankan secara terbuka, adil, dan terpercaya dengan 3 prinsip layanan komersial berikut:',
                            style: TextStyle(
                              fontSize: 12,
                              color: GageTheme.textSecondary,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // 1. Perjanjian Layanan Pengantaran Mitra Pengemudi
                  _buildPrincipleCard(
                    context: context,
                    number: '1',
                    badge: 'Layanan Pengantaran',
                    badgeColor: GageTheme.accentBlue,
                    title: 'Perjanjian Layanan Pengantaran Mitra Pengemudi',
                    description:
                        'Tarif jasa pengantaran dihitung secara proporsional berdasarkan jarak tempuh riil (kilometer aktual). Hak penghasilan mitra pengemudi terjamin secara akurat dan transparan tanpa potongan tersembunyi atas jarak yang ditempuh.',
                    icon: Icons.delivery_dining_rounded,
                  ),

                  const SizedBox(height: 12),

                  // 2. Kuasa Pembelian Toko Resmi
                  _buildPrincipleCard(
                    context: context,
                    number: '2',
                    badge: 'Kuasa Belanja Resmi',
                    badgeColor: GageTheme.accentYellow,
                    title: 'Kuasa Pembelian Toko Resmi',
                    description:
                        'Layanan jasa titip beli kebutuhan di gerai mitra resmi UMKM GAGE. Pengemudi bertindak sebagai perwakilan resmi pemesan untuk membeli dan mengantarkan barang sesuai pesanan yang terdaftar dalam sistem aplikasi.',
                    icon: Icons.storefront_rounded,
                  ),

                  const SizedBox(height: 12),

                  // 3. Transparansi Pembulatan Biaya Antar Rp 500
                  _buildPrincipleCard(
                    context: context,
                    number: '3',
                    badge: 'Ketentuan Tarif Rp 500',
                    badgeColor: GageTheme.accentGreen,
                    title: 'Transparansi Pembulatan Biaya Antar Rp 500',
                    description:
                        'Untuk mempermudah transaksi pembayaran tunai di lapangan dan penyiapan uang kembalian, total biaya pengantaran dibulatkan ke atas per kelipatan Rp 500. Selisih pembulatan dialokasikan secara transparan untuk subsidi tarif pelanggan, penunjang operasional, dan pemeliharaan performa aplikasi GAGE.',
                    icon: Icons.price_check_rounded,
                    extraWidget: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: GageTheme.accentGreen.withAlpha(15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: GageTheme.accentGreen.withAlpha(50)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: GageTheme.accentGreen, size: 16),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Contoh: Biaya riil Rp 12.100 dibulatkan menjadi Rp 12.500. Selisih Rp 400 dialokasikan untuk program subsidi tarif & pemeliharaan sistem.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF166534),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Banner Jaminan Keamanan & Hukum
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.gavel_rounded, color: Color(0xFF475569), size: 18),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Seluruh transaksi dilindungi ketentuan hukum perlindungan konsumen dan perjanjian kemitraan digital Republik Indonesia yang sah.',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF475569),
                              height: 1.45,
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

          const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),

          // Tombol Persetujuan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAccept(context),
                    icon: const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text(
                      'Saya Memahami & Menyetujui Ketentuan',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GageTheme.accentGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: GageTheme.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Nanti Saja',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrincipleCard({
    required BuildContext context,
    required String number,
    required String badge,
    required Color badgeColor,
    required String title,
    required String description,
    required IconData icon,
    Widget? extraWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GageTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withAlpha(35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: badgeColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: badgeColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: badgeColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GageTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: const TextStyle(
              fontSize: 11.5,
              color: GageTheme.textSecondary,
              height: 1.45,
            ),
          ),
          ?extraWidget,
        ],
      ),
    );
  }
}
