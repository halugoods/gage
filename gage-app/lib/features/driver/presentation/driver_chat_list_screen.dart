import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/driver/presentation/widgets/driver_bottom_nav_bar.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

class DriverChatListScreen extends StatelessWidget {
  const DriverChatListScreen({super.key});

  final List<Map<String, dynamic>> _chatRooms = const [
    {
      'orderId': 'ORD-88219',
      'name': 'Siti Rahmawati',
      'role': 'customer',
      'phone': '081234567890',
      'lastMessage': 'Halo mas, tolong sambalnya agak banyak yaa...',
      'time': '09:24',
      'unread': 1,
      'isOrderActive': true,
    },
    {
      'orderId': 'ORD-88219',
      'name': 'Dimsum Sewu Mas Agus',
      'role': 'merchant',
      'phone': '085712345678',
      'lastMessage': 'Siap kak Siti, sambal cocol ekstra sudah kami siapkan...',
      'time': '09:22',
      'unread': 0,
      'isOrderActive': true,
    },
    {
      'orderId': 'SYS-INFO',
      'name': 'Pusat Informasi GAGE',
      'role': 'admin',
      'phone': '082133445566',
      'lastMessage': 'Insentif jam sibuk aktif hingga pukul 13:00 WIB.',
      'time': '07:00',
      'unread': 0,
      'isOrderActive': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        elevation: 0.5,
        title: const Text(
          'Pesan & Obrolan',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17),
        ),
      ),
      body: SafeArea(
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
            Color roleColor;
            IconData roleIcon;

            if (role == 'customer') {
              avatarBg = const Color(0xFFEFF6FF);
              roleColor = const Color(0xFF2563EB);
              roleIcon = Icons.person_rounded;
            } else if (role == 'merchant') {
              avatarBg = const Color(0xFFFFF7ED);
              roleColor = const Color(0xFFEA580C);
              roleIcon = Icons.storefront_rounded;
            } else {
              avatarBg = GageTheme.primary.withValues(alpha: 0.1);
              roleColor = GageTheme.primary;
              roleIcon = Icons.verified_rounded;
            }

            return InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (c) => InAppChatScreen(
                      orderId: room['orderId'],
                      recipientName: room['name'],
                      recipientRole: role,
                      recipientPhone: room['phone'],
                      currentRole: 'driver',
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: avatarBg,
                          child: Icon(roleIcon, color: roleColor, size: 24),
                        ),
                        if (room['isOrderActive'] as bool)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: GageTheme.accentGreen,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room['name'],
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                room['time'],
                                style: TextStyle(
                                  fontSize: 11,
                                  color: unread > 0 ? GageTheme.primary : Colors.grey,
                                  fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  room['lastMessage'],
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: unread > 0
                                        ? (isDark ? Colors.white : const Color(0xFF0F172A))
                                        : (isDark ? Colors.white60 : Colors.black54),
                                    fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (unread > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: GageTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '$unread',
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
      bottomNavigationBar: const DriverBottomNavBar(currentIndex: 3),
    );
  }
}
