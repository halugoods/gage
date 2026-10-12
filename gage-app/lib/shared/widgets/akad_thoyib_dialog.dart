import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gage_app/core/theme/gage_theme.dart';

/// Dialog & Bottom Sheet Transparansi Akad Syar'i GAGE Pracimantoro
/// Berisi penjelasan 3 Akad Muamalah:
/// 1. Akad Ijarah (Sewa Jasa Antar Pengemudi)
/// 2. Akad Wakalah bil Ujrah (Jasa Titip Beli Toko Resmi Mitra)
/// 3. Akad Thoyib Pembulatan Ongkir (Tabungan Bersama Subsidi & Pemeliharaan Sistem)
class AkadThoyibDialog extends StatelessWidget {
  /// SharedPreferences key untuk menyimpan persetujuan akad
  static const String prefKey = 'akad_thoyib_accepted';

  final bool isDialogMode;

  const AkadThoyibDialog({
    super.key,
    this.isDialogMode = false,
  });

  /// Cek apakah pengguna sudah pernah menyetujui akad syar'i
  static Future<bool> isAccepted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(prefKey) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Reset status persetujuan (untuk testing / pengaturan akun)
  static Future<void> resetAcceptance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(prefKey);
    } catch (_) {}
  }

  /// Tampilkan AkadThoyib dalam bentuk Bottom Sheet elegan
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const AkadThoyibDialog(isDialogMode: false),
    );
  }

  /// Tampilkan AkadThoyib dalam bentuk Modal Dialog
  static Future<bool?> showAsDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: const AkadThoyibDialog(isDialogMode: true),
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
      debugPrint('Error saving akad_thoyib_accepted: $e');
    }
    if (context.mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * (isDialogMode ? 0.85 : 0.88);

    final content = Container(
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
          // Drag handle jika mode bottom sheet
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
                          "GAGE PRACIMANTORO SYAR'I",
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
                        'Transparansi Akad & Berkah',
                        style: TextStyle(
                          fontSize: 17,
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

          // Body Berisi Penjelasan 3 Akad
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pengantar
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
                            'Bismillahirrohmanirrohim. Transaksi di GAGE Pracimantoro berlandaskan prinsip saling ridho (an taradin minkum) melalui 3 akad syar\'i yang jujur & transparan:',
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

                  // 1. Akad Ijarah
                  _buildAkadCard(
                    context: context,
                    number: '1',
                    badge: 'Sewa Jasa Antar',
                    badgeColor: GageTheme.accentBlue,
                    title: 'Akad Ijarah (Jasa Antar Driver)',
                    description:
                        'Sewa jasa antar pengemudi sesuai jarak tempuh riil kilometer aktual. Hak jerih payah driver terlindungi penuh secara eksak tanpa pembulatan atau potongan terselubung atas jarak yang ditempuh.',
                    icon: Icons.delivery_dining_rounded,
                  ),

                  const SizedBox(height: 12),

                  // 2. Akad Wakalah bil Ujrah
                  _buildAkadCard(
                    context: context,
                    number: '2',
                    badge: 'Amanah Pembelian',
                    badgeColor: GageTheme.accentYellow,
                    title: 'Akad Wakalah bil Ujrah (Jasa Titip Beli)',
                    description:
                        'Jasa titip amanah pembelian barang di toko resmi mitra UMKM GAGE. Driver bertindak sebagai wakil sah pembeli dengan biaya penanganan layanan yang adil dan transparan.',
                    icon: Icons.storefront_rounded,
                  ),

                  const SizedBox(height: 12),

                  // 3. Akad Thoyib Pembulatan Ongkir
                  _buildAkadCard(
                    context: context,
                    number: '3',
                    badge: 'Kerelaan Rp 500',
                    badgeColor: GageTheme.accentGreen,
                    title: 'Akad Thoyib Pembulatan Ongkir',
                    description:
                        'Kerelaan atas pembulatan ongkir ke atas per Rp 500 (misal Rp 12.100 menjadi Rp 12.500). Selisih pembulatan dialokasikan sebagai tabungan bersama untuk subsidi diskon ongkir sesama warga & pemeliharaan ekosistem digital GAGE Pracimantoro.',
                    icon: Icons.volunteer_activism_rounded,
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
                              'Contoh: Ongkir riil Rp 12.100 -> dibulatkan Rp 12.500. Selisih Rp 400 masuk tabungan subsidi warga.',
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

                  // Dalil / Kutipan Muamalah
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEFCE8),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFEF08A)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'يَا أَيُّهَا الَّذِينَ آمَنُوا لَا تَأْكُلُوا أَمْوَالَكُم بَيْنَكُم بِالْبَاطِلِ إِلَّا أَن تَكُونَ تِجَارَةً عَن تَرَاضٍ مِّنكُمْ',
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF713F12),
                            height: 1.6,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '"...kecuali dengan jalan perniagaan yang berlaku dengan suka sama-suka di antara kamu." (QS. An-Nisa: 29)',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Color(0xFF854D0E),
                            height: 1.4,
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
                      'Saya Setuju & Ridho (Bismillah)',
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

    return content;
  }

  Widget _buildAkadCard({
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
