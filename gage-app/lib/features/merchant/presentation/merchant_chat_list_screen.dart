import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/merchant/presentation/widgets/merchant_bottom_nav_bar.dart';

/// Screen Daftar Percakapan Merchant - Tab 3
/// Menghubungkan langsung Mitra Dapur dengan Driver Pengambil & Pelanggan Pemesan.
class MerchantChatListScreen extends StatefulWidget {
  const MerchantChatListScreen({super.key});

  @override
  State<MerchantChatListScreen> createState() => _MerchantChatListScreenState();
}

class _MerchantChatListScreenState extends State<MerchantChatListScreen> {
  final List<Map<String, dynamic>> _chatRooms = [
    {
      'orderId': 'ORD-9021',
      'name': 'Mas Budi (Kurir GAGE)',
      'role': 'driver',
      'phone': '6281234567890',
      'lastMessage': 'Sudah sampai depan outlet ya mas, pesanan siap?',
      'time': '12:46',
      'unread': 1,
    },
    {
      'orderId': 'ORD-9021',
      'name': 'Mba Siti Rahayu',
      'role': 'customer',
      'phone': '6281987654321',
      'lastMessage': 'Saus sambal dimsumnya tolong dipisah ya kak.',
      'time': '12:40',
      'unread': 0,
    },
    {
      'orderId': 'ORD-9018',
      'name': 'Pak Joko (Driver Motor)',
      'role': 'driver',
      'phone': '6285712345678',
      'lastMessage': 'Pesanan sudah diterima customer dengan baik, suwun mas!',
      'time': '12:22',
      'unread': 0,
    },
    {
      'orderId': 'GAGE-INFO',
      'name': 'Pusat Mitra GAGE Pracimantoro',
      'role': 'system',
      'phone': '628111222333',
      'lastMessage': 'Program Promo Subsidi Dimsum 20% berlaku mulai besok!',
      'time': '09:00',
      'unread': 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'Pesan & Chat Masuk',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: _chatRooms.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 72,
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          ),
          itemBuilder: (ctx, idx) {
            final room = _chatRooms[idx];
            final role = room['role'] as String;
            final unread = room['unread'] as int;

            Color avatarBg;
            IconData avatarIcon;
            if (role == 'driver') {
              avatarBg = GageTheme.accentGreen.withValues(alpha: 0.12);
              avatarIcon = Icons.two_wheeler_rounded;
            } else if (role == 'customer') {
              avatarBg = GageTheme.primary.withValues(alpha: 0.12);
              avatarIcon = Icons.person_rounded;
            } else {
              avatarBg = const Color(0xFF2563EB).withValues(alpha: 0.12);
              avatarIcon = Icons.campaign_rounded;
            }

            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InAppChatScreen(
                      orderId: room['orderId'] as String,
                      recipientName: room['name'] as String,
                      recipientRole: role,
                      recipientPhone: room['phone'] as String,
                      currentRole: 'merchant',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: avatarBg,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        avatarIcon,
                        color: role == 'driver'
                            ? GageTheme.accentGreen
                            : (role == 'customer' ? GageTheme.primary : const Color(0xFF2563EB)),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room['name'] as String,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                room['time'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: unread > 0 ? GageTheme.primary : GageTheme.textSecondary,
                                  fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  room['lastMessage'] as String,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: unread > 0
                                        ? (isDark ? Colors.white : Colors.black87)
                                        : GageTheme.textSecondary,
                                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: const BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    unread.toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const MerchantBottomNavBar(currentIndex: 3),
    );
  }
}
