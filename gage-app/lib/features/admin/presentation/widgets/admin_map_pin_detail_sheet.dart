import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

/// iOS Inset Floating Bottom Sheet untuk menampilkan detail entitas (Pengguna, Pesanan, Driver, Merchant)
/// yang di-tap pada GAGE Heatmap.
class AdminMapPinDetailSheet extends StatelessWidget {
  final Map<String, dynamic> data;

  const AdminMapPinDetailSheet({
    super.key,
    required this.data,
  });

  static Future<void> show(BuildContext context, Map<String, dynamic> data) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminMapPinDetailSheet(data: data),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final type = data['type'] as String? ?? 'user';
    final name = data['name'] as String? ?? 'Entitas';
    final phone = data['phone'] as String? ?? '';
    final address = data['address'] as String? ?? 'Pracimantoro, Wonogiri';
    final status = data['status'] as String? ?? 'Aktif';
    final subtitle = data['subtitle'] as String? ?? '';
    final orderId = data['orderId'] as String?;

    IconData typeIcon;
    Color typeColor;
    String typeLabel;

    switch (type) {
      case 'order':
        typeIcon = Icons.shopping_bag_rounded;
        typeColor = GageTheme.primary;
        typeLabel = 'Pesanan Aktif';
        break;
      case 'driver':
        typeIcon = Icons.two_wheeler_rounded;
        typeColor = const Color(0xFF00AA13);
        typeLabel = 'Driver Online';
        break;
      case 'merchant':
        typeIcon = Icons.storefront_rounded;
        typeColor = Colors.orange.shade700;
        typeLabel = 'Merchant';
        break;
      case 'registered_user':
      case 'user':
      default:
        typeIcon = Icons.person_rounded;
        typeColor = Colors.blue.shade700;
        typeLabel = data['hasOrdered'] == true ? 'Pengguna Aktif' : 'Pengguna Baru Terdaftar';
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header Type Badge & Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: typeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(typeIcon, color: typeColor, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: typeColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          typeLabel,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: typeColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00AA13).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF00AA13),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 14),

            // Detail Lokasi / Alamat
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),

            if (data['extraInfo'] != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                ),
                child: Text(
                  data['extraInfo'] as String,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.black87,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Tombol Aksi
            Row(
              children: [
                if (phone.isNotEmpty) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: Colors.green.shade400),
                      ),
                      icon: const Icon(Icons.chat_rounded, color: Colors.green, size: 16),
                      label: const Text(
                        'WhatsApp',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green),
                      ),
                      onPressed: () async {
                        final uri = Uri.parse('https://wa.me/$phone');
                        if (await canLaunchUrl(uri)) {
                          launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                if (orderId != null && orderId.isNotEmpty)
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GageTheme.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.forum_rounded, size: 16),
                      label: const Text(
                        'Chat In-App',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => InAppChatScreen(
                              orderId: orderId,
                              recipientName: name,
                              recipientRole: type == 'merchant' ? 'merchant' : (type == 'driver' ? 'driver' : 'customer'),
                              recipientPhone: phone,
                              currentRole: 'merchant',
                            ),
                          ),
                        );
                      },
                    ),
                  )
                else
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
                        foregroundColor: isDark ? Colors.white : Colors.black87,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 16),
                      label: const Text(
                        'Tutup',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
