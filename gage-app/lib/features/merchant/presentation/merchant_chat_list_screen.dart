import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/domain/chat_message.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';

/// Screen Daftar Percakapan Merchant - Tab 3
/// Menghubungkan langsung Mitra Dapur dengan Driver Pengambil, Pelanggan Pemesan, dan Pusat Bantuan.
class MerchantChatListScreen extends StatefulWidget {
  const MerchantChatListScreen({super.key});

  @override
  State<MerchantChatListScreen> createState() => _MerchantChatListScreenState();
}

class _MerchantChatListScreenState extends State<MerchantChatListScreen> {
  final List<Map<String, dynamic>> _seedRooms = [
    if (GageApiClient.useDevSeedData) ...[
      {
        'orderId': 'ORD-9021',
        'name': 'Mas Budi',
        'role': 'driver',
        'phone': '6281226001000',
        'lastMessage': 'Sudah sampai depan outlet ya mas, pesanan siap?',
        'time': '12:46',
        'unread': 1,
        'avatar': null,
      },
      {
        'orderId': 'ORD-9021',
        'name': 'Mba Siti Rahayu',
        'role': 'customer',
        'phone': '6281987654321',
        'lastMessage': 'Saus sambal dimsumnya tolong dipisah ya kak.',
        'time': '12:40',
        'unread': 0,
        'avatar': null,
      },
      {
        'orderId': 'ORD-9018',
        'name': 'Pak Joko',
        'role': 'driver',
        'phone': '6285712345678',
        'lastMessage': 'Pesanan sudah diterima customer dengan baik, suwun mas!',
        'time': '12:22',
        'unread': 0,
        'avatar': null,
      },
    ],
  ];

  String _formatChatPreview(ChatMessage msg) {
    final text = msg.text.trim();
    if (text.isNotEmpty) return text;
    if (msg.isImage) return 'Mengirim foto';
    if (msg.isVoice) return 'Pesan suara';
    return 'Pesan baru';
  }

  List<Map<String, dynamic>> _buildRooms(
    MerchantOrderProvider? orderProv,
    InAppChatProvider? chatProv,
  ) {
    final rooms = <Map<String, dynamic>>[
      {
        'orderId': 'cs-gage-support',
        'name': 'Pusat Bantuan',
        'role': 'support',
        'phone': '628111222333',
        'lastMessage': 'Tim operasional GAGE siap membantu kelancaran pesanan Anda.',
        'time': 'Aktif',
        'unread': 0,
        'avatar': 'assets/images/gage_icon.png',
      },
    ];

    final seenKeys = <String>{};
    if (orderProv != null) {
      for (final order in orderProv.orders) {
        final shortOrd = order.orderNumber.trim().isNotEmpty
            ? order.orderNumber.trim().split('/').last
            : order.id;

        final cleanCust = InAppChatScreen.cleanDisplayName(
          order.customerName ?? 'Pelanggan',
          role: 'customer',
        );
        if (seenKeys.add('cust:${order.id}')) {
          final msgs = chatProv?.getMessages(order.id) ?? const [];
          rooms.add({
            'orderId': order.id,
            'name': cleanCust,
            'role': 'customer',
            'phone': order.customerPhone ?? '',
            'lastMessage': msgs.isNotEmpty
                ? _formatChatPreview(msgs.last)
                : 'Pesanan #$shortOrd',
            'time': msgs.isNotEmpty
                ? DateFormat('HH:mm').format(msgs.last.timestamp)
                : DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order.createdAt)),
            'unread': 0,
            'avatar': order.customerAvatar,
          });
        }

        if (order.hasAssignedDriver) {
          final cleanDrv = InAppChatScreen.cleanDisplayName(
            order.driverName ?? 'Driver',
            role: 'driver',
          );
          if (seenKeys.add('drv:${order.id}')) {
            final msgs = chatProv?.getMessages(order.id) ?? const [];
            rooms.add({
              'orderId': order.id,
              'name': cleanDrv,
              'role': 'driver',
              'phone': '',
              'lastMessage': msgs.isNotEmpty
                  ? _formatChatPreview(msgs.last)
                  : 'Pesanan #$shortOrd • Driver menuju kios',
              'time': msgs.isNotEmpty
                  ? DateFormat('HH:mm').format(msgs.last.timestamp)
                  : DateFormat('HH:mm').format(DateTime.fromMillisecondsSinceEpoch(order.createdAt)),
              'unread': 0,
              'avatar': order.driverAvatar,
            });
          }
        }
      }
    }

    if (GageApiClient.useDevSeedData && rooms.length <= 1) {
      rooms.addAll(_seedRooms);
    }

    return rooms;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    MerchantOrderProvider? orderProv;
    InAppChatProvider? chatProv;
    try {
      orderProv = context.watch<MerchantOrderProvider>();
    } catch (_) {}
    try {
      chatProv = context.watch<InAppChatProvider>();
    } catch (_) {}

    final rooms = _buildRooms(orderProv, chatProv);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        titleSpacing: 16,
        elevation: 0.5,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        title: const Text(
          'Pesan & Chat Masuk',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: rooms.length,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            indent: 72,
            color: isDark ? const Color(0xFF334155) : Colors.grey.shade200,
          ),
          itemBuilder: (ctx, idx) {
            final room = rooms[idx];
            final role = (room['role'] ?? 'customer').toString();
            final name = (room['name'] ?? 'Pengguna').toString();
            final avatar = room['avatar']?.toString();
            final roomKey = 'mch-${room['orderId']}-$role';

            return AnimatedBuilder(
              animation: NotificationService.instance,
              builder: (ctx, _) {
                final unread = NotificationService.instance.unreadCountForMerchantChat(roomKey);
                return InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    NotificationService.instance.markMerchantChatAsRead(roomKey);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => InAppChatScreen(
                          orderId: (room['orderId'] ?? '').toString(),
                          recipientName: name,
                          recipientRole: role,
                          recipientPhone: (room['phone'] ?? '').toString(),
                          recipientAvatar: avatar,
                          currentRole: 'merchant',
                        ),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        GageAvatar(
                          imageUrl: avatar,
                          fallbackName: name,
                          radius: 23,
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
                                      name,
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    (room['time'] ?? '').toString(),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: unread > 0 ? GageTheme.primary : GageTheme.textSecondary,
                                      fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      (room['lastMessage'] ?? '').toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: unread > 0
                                            ? (isDark ? Colors.white : Colors.black87)
                                            : GageTheme.textSecondary,
                                        fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
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
                                          fontWeight: FontWeight.w700,
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
            );
          },
        ),
      ),
    );
  }
}
