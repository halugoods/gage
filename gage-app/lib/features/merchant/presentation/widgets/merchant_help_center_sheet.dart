import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Interactive Floating Sheet: Pusat Bantuan Resmi Mitra Usaha GAGE (Non-Gimmick)
/// Menyediakan Hotline Dispatcher Pracimantoro, WhatsApp Layanan CS,
/// serta direktori FAQ interaktif mengenai order, printer, settlement dana, dan kurir.
class MerchantHelpCenterSheet extends StatefulWidget {
  final String storeName;
  final String storeId;

  const MerchantHelpCenterSheet({
    super.key,
    required this.storeName,
    required this.storeId,
  });

  static Future<void> show(
    BuildContext context, {
    required String storeName,
    required String storeId,
  }) {
    return GageFloatingSheet.show(
      context: context,
      title: 'Pusat Bantuan Mitra Usaha',
      builder: (_) => MerchantHelpCenterSheet(
        storeName: storeName,
        storeId: storeId,
      ),
    );
  }

  @override
  State<MerchantHelpCenterSheet> createState() => _MerchantHelpCenterSheetState();
}

class _MerchantHelpCenterSheetState extends State<MerchantHelpCenterSheet> {
  int? _expandedFaqIndex;

  final List<Map<String, String>> _faqs = [
    {
      'q': 'Kapan saldo penjualan toko otomatis dicairkan?',
      'a':
          'Saldo dari pesanan yang telah berstatus Selesai akan otomatis diproses settlement ke rekening bank atau e-wallet mitra pada H+1 hari kerja pukul 09.00 WIB tanpa potongan biaya admin.',
    },
    {
      'q': 'Driver belum datang padahal pesanan sudah siap diambil?',
      'a':
          'Tunggu toleransi waktu 5 menit. Jika kurir tidak kunjung tiba atau titik navigasi berhenti, gunakan tombol Hotline Dispatcher di atas agar Admin Dispatcher Pracimantoro dapat menugaskan kurir terdekat lainnya.',
    },
    {
      'q': 'Bagaimana cara pairing printer bluetooth thermal?',
      'a':
          'Pastikan Bluetooth HP sudah menyala. Buka menu Printer Thermal di Pengaturan Toko, pilih ukuran kertas (58mm atau 80mm), lalu tekan tombol Hubungkan pada nama printer thermal yang terdeteksi.',
    },
    {
      'q': 'Pelanggan meminta perubahan pesanan atau catatan khusus?',
      'a':
          'Mitra dapat langsung membaca Catatan Pelanggan di kartu pesanan atau berkomunikasi via Chat Pembeli resmi di dalam aplikasi sebelum menekan tombol Terima Pesanan.',
    },
    {
      'q': 'Bagaimana prosedur pindah alamat atau titik GPS toko?',
      'a':
          'Gunakan menu "Ajukan Pindah Lokasi Toko" di Pengaturan. Pilih titik koordinat baru di peta interaktif dan sertakan alasan. Admin GAGE akan memverifikasi dalam waktu maksimal 1x24 jam kerja.',
    },
  ];

  Future<void> _launchWhatsApp(BuildContext context) async {
    HapticFeedback.lightImpact();
    final text = 'Halo Tim Bantuan GAGE, saya pemilik outlet ${widget.storeName} (${widget.storeId}) butuh bantuan operasional.';
    final uri = Uri.parse('https://wa.me/628111222333?text=${Uri.encodeComponent(text)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      GageToast.show(context, 'Gagal membuka WhatsApp. Silakan hubungi 0811-1222-333');
    }
  }

  Future<void> _launchCall(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final uri = Uri.parse('tel:08111222333');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else if (context.mounted) {
      GageToast.show(context, 'Hotline Dispatcher: 0811-1222-333');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Layanan bantuan operasional, kendala teknis, dan investigasi order toko GAGE Pracimantoro.',
          style: TextStyle(fontSize: 11.5, color: subColor),
        ),
        const SizedBox(height: 14),

        // Saluran Cepat: 2 Tombol Aksi Kapsul
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchCall(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: GageTheme.primary,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  elevation: 0,
                ),
                icon: const Icon(Icons.phone_in_talk_rounded, size: 16),
                label: const Text(
                  'Hotline Darurat',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _launchWhatsApp(context),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF16A34A)),
                  foregroundColor: const Color(0xFF16A34A),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                ),
                icon: const Icon(Icons.chat_rounded, size: 16),
                label: const Text(
                  'Chat CS WhatsApp',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Header FAQ
        Text(
          'PERTANYAAN UMUM (FAQ)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: subColor,
          ),
        ),
        const SizedBox(height: 8),

        // Daftar FAQ Accordion
        Column(
          children: List.generate(_faqs.length, (idx) {
            final faq = _faqs[idx];
            final isExpanded = _expandedFaqIndex == idx;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isExpanded ? GageTheme.primary.withValues(alpha: 0.3) : borderColor,
                ),
              ),
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _expandedFaqIndex = isExpanded ? null : idx;
                  });
                },
                borderRadius: BorderRadius.circular(14),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.help_outline_rounded,
                            size: 16,
                            color: isExpanded ? GageTheme.primary : subColor,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              faq['q']!,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: subColor,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 8),
                        Divider(height: 1, color: borderColor),
                        const SizedBox(height: 8),
                        Text(
                          faq['a']!,
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.5,
                            color: isDark ? Colors.white70 : const Color(0xFF475569),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
