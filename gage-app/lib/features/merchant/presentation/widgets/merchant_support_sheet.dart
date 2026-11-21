import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_floating_sheet.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

/// Modal Floating Sheet untuk Pusat Bantuan Mitra Usaha GAGE (Pracimantoro)
/// Memberikan akses cepat ke Hotline 24 Jam, WhatsApp Center, dan FAQ Operasional.
class MerchantSupportSheet extends StatelessWidget {
  const MerchantSupportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return GageFloatingSheet.show(
      context: context,
      title: 'Pusat Bantuan Mitra Usaha',
      builder: (_) => const MerchantSupportSheet(),
    );
  }

  Future<void> _makePhoneCall(BuildContext context, String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        GageToast.show(context, 'Tidak dapat membuka panggilan telepon: $phone');
      }
    }
  }

  Future<void> _openWhatsApp(BuildContext context, String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=Halo%20Admin%20GAGE,%20saya%20Mitra%20Dimsum%20Sewu%20ingin%20berkonsultasi.');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        GageToast.show(context, 'Tidak dapat membuka WhatsApp: $phone');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Dukungan 24/7
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark ? Colors.white12 : const Color(0xFFBFDBFE),
              ),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  backgroundColor: Color(0xFF2563EB),
                  child: Icon(Icons.support_agent_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tim Operasional Siaga 24 Jam',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Siap mendampingi kelancaran pesanan, pencairan saldo, dan operasional dapur Anda.',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? Colors.white60 : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Tombol Hubungi Cepat
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    elevation: 0,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openWhatsApp(context, '081234567890');
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 16),
                  label: const Text('WhatsApp CS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _makePhoneCall(context, '081234567890');
                  },
                  icon: const Icon(Icons.phone_in_talk_rounded, size: 16, color: GageTheme.primary),
                  label: const Text('Hotline Telepon', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // FAQ Singkat
          Text(
            'Panduan Mitra Sering Ditanyakan',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),

          _buildFaqTile(
            title: 'Bagaimana cara serah terima pesanan ke Driver?',
            subtitle: 'Berikan 4 angka PIN Serah Terima acak yang tertera di rincian pesanan. Driver wajib menginput PIN tersebut di HP miliknya.',
            isDark: isDark,
          ),
          _buildFaqTile(
            title: 'Kapan hasil penjualan masuk ke saldo GagePay?',
            subtitle: 'Saldo bersih penjualan (setelah potongan MDR 10%) langsung cair secara instan H+0 saat pesanan berstatus Selesai.',
            isDark: isDark,
          ),
          _buildFaqTile(
            title: 'Bagaimana jika bahan baku mendadak habis?',
            subtitle: 'Buka menu "Menu & Stok", geser saklar menu menjadi Habis, atau hubungi pelanggan melalui fitur Chat Mitra.',
            isDark: isDark,
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  static Widget _buildFaqTile({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.help_outline_rounded, size: 14, color: GageTheme.primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.35,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
