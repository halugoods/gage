import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/domain/chat_message.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';
import 'package:gage_app/features/chat/providers/in_app_chat_provider.dart';
import 'package:gage_app/providers/merchant_order_provider.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';

/// Tab 1: Chat Mitra Usaha GAGE (In-App Chat Hub 1:1 Paritas Customer Portal)
/// Menghubungkan komunikasi real-time toko dengan Pusat Bantuan, Driver, dan Pelanggan.
class GageMerchantChatTab extends StatefulWidget {
  const GageMerchantChatTab({super.key});

  @override
  State<GageMerchantChatTab> createState() => _GageMerchantChatTabState();
}

class _GageMerchantChatTabState extends State<GageMerchantChatTab> {
  int _activeFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Bantuan', 'Driver', 'Pelanggan'];

  final List<Map<String, dynamic>> _seedChats = [
    if (GageApiClient.useDevSeedData) ...[
      {
        'id': 'seed-driver-01',
        'name': 'Budi Santoso',
        'role': 'driver',
        'lastMessage': 'Siap Mas, saya sudah dekat kios, pesanan dimsum sedang dibungkus?',
        'time': '10:35',
        'unread': 1,
        'isOnline': true,
        'phone': '081398765432',
        'orderId': '101',
        'category': 'driver',
        'avatar': null,
      },
      {
        'id': 'seed-cust-01',
        'name': 'Siti Rahmawati',
        'role': 'customer',
        'lastMessage': 'Kak minta saus sambalnya dipisah ya, jangan dicampur. Terima kasih!',
        'time': '09:20',
        'unread': 0,
        'isOnline': true,
        'phone': '081298761234',
        'orderId': '101',
        'category': 'customer',
        'avatar': null,
      },
      {
        'id': 'seed-driver-02',
        'name': 'Agus Prabowo',
        'role': 'driver',
        'lastMessage': 'Pesanan sudah saya serahkan ke pembeli dengan aman Mas.',
        'time': 'Kemarin',
        'unread': 0,
        'isOnline': false,
        'phone': '081567890123',
        'orderId': '098',
        'category': 'driver',
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

  List<Map<String, dynamic>> _buildAllChats(
    MerchantOrderProvider? orderProv,
    InAppChatProvider? chatProv,
  ) {
    final chats = <Map<String, dynamic>>[];

    final supportMsgs = chatProv?.getMessages('cs-gage-support') ?? const [];
    final supportLast = supportMsgs.isNotEmpty
        ? _formatChatPreview(supportMsgs.last)
        : 'Halo Mitra! Tim operasional GAGE siap membantu kelancaran pesanan Anda.';
    final supportTime = supportMsgs.isNotEmpty
        ? DateFormat('HH:mm').format(supportMsgs.last.timestamp)
        : 'Aktif';

    chats.add({
      'id': 'chat-cs-01',
      'name': 'Pusat Bantuan',
      'role': 'support',
      'lastMessage': supportLast,
      'time': supportTime,
      'unread': 0,
      'isOnline': true,
      'phone': '08111222333',
      'orderId': 'cs-gage-support',
      'category': 'support',
      'avatar': 'assets/images/gage_icon.png',
    });

    final seenKeys = <String>{};
    if (orderProv != null) {
      for (final order in orderProv.orders) {
        final shortOrd = order.orderNumber.trim().isNotEmpty
            ? order.orderNumber.trim().split('/').last
            : order.id;

        // Thread Pelanggan
        final cleanCustomer = InAppChatScreen.cleanDisplayName(
          order.customerName ?? 'Pelanggan',
          role: 'customer',
        );
        final custKey = 'customer:${order.id}';
        if (seenKeys.add(custKey)) {
          final msgs = chatProv?.getMessages(order.id) ?? const [];
          final lastMsg = msgs.isNotEmpty
              ? _formatChatPreview(msgs.last)
              : 'Pesanan #$shortOrd • Chat dengan $cleanCustomer';
          final timeStr = msgs.isNotEmpty
              ? DateFormat('HH:mm').format(msgs.last.timestamp)
              : DateFormat('HH:mm').format(
                  DateTime.fromMillisecondsSinceEpoch(order.createdAt),
                );
          chats.add({
            'id': 'order-customer-${order.id}',
            'name': cleanCustomer,
            'role': 'customer',
            'lastMessage': lastMsg,
            'time': timeStr,
            'unread': 0,
            'isOnline': order.isActive,
            'phone': order.customerPhone ?? '',
            'orderId': order.id,
            'category': 'customer',
            'avatar': order.customerAvatar,
          });
        }

        // Thread Driver (jika terpasang)
        if (order.hasAssignedDriver) {
          final cleanDriver = InAppChatScreen.cleanDisplayName(
            order.driverName ?? 'Driver',
            role: 'driver',
          );
          final drvKey = 'driver:${order.id}';
          if (seenKeys.add(drvKey)) {
            final msgs = chatProv?.getMessages(order.id) ?? const [];
            final lastMsg = msgs.isNotEmpty
                ? _formatChatPreview(msgs.last)
                : 'Pesanan #$shortOrd • $cleanDriver menuju kios';
            final timeStr = msgs.isNotEmpty
                ? DateFormat('HH:mm').format(msgs.last.timestamp)
                : DateFormat('HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(order.createdAt),
                  );
            chats.add({
              'id': 'order-driver-${order.id}',
              'name': cleanDriver,
              'role': 'driver',
              'lastMessage': lastMsg,
              'time': timeStr,
              'unread': 0,
              'isOnline': order.isActive,
              'phone': '',
              'orderId': order.id,
              'category': 'driver',
              'avatar': order.driverAvatar,
            });
          }
        }
      }
    }

    if (GageApiClient.useDevSeedData && chats.length <= 1) {
      chats.addAll(_seedChats);
    }

    return chats;
  }

  List<Map<String, dynamic>> _getFilteredChats(List<Map<String, dynamic>> allChats) {
    switch (_activeFilterIndex) {
      case 1:
        return allChats.where((c) => c['category'] == 'support').toList();
      case 2:
        return allChats.where((c) => c['category'] == 'driver').toList();
      case 3:
        return allChats.where((c) => c['category'] == 'customer').toList();
      case 0:
      default:
        return allChats;
    }
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

    final allChats = _buildAllChats(orderProv, chatProv);
    final filtered = _getFilteredChats(allChats);

    return Column(
      children: [
        // Filter Pills Kapsul Penuh (BorderRadius.circular(999))
        Container(
          color: isDark ? GageTheme.darkSurface : Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _filters.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final isSelected = _activeFilterIndex == idx;
                return GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _activeFilterIndex = idx);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary
                          : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _filters[idx],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : const Color(0xFF475569)),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        // List Percakapan Chat
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState(isDark)
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 96),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final chat = filtered[index];
                    return _buildChatRow(context, chat, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildChatRow(BuildContext context, Map<String, dynamic> chat, bool isDark) {
    final unread = (chat['unread'] as int?) ?? 0;
    final isOnline = chat['isOnline'] == true;
    final role = (chat['role'] as String?) ?? 'customer';
    final displayName = (chat['name'] ?? 'Pengguna GAGE').toString();
    final avatarUrl = chat['avatar']?.toString();

    String roleBadge = 'Pelanggan';
    Color roleBadgeColor = const Color(0xFF0284C7);
    if (role == 'driver') {
      roleBadge = 'Driver';
      roleBadgeColor = GageTheme.primary;
    } else if (role == 'support' || role == 'admin') {
      roleBadge = 'Bantuan';
      roleBadgeColor = const Color(0xFF16A34A);
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => InAppChatScreen(
                  recipientName: displayName,
                  recipientRole: role,
                  orderId: (chat['orderId'] ?? '').toString(),
                  recipientPhone: (chat['phone'] ?? '').toString(),
                  recipientAvatar: avatarUrl,
                  currentRole: 'merchant',
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Avatar dengan GageAvatar & indikator online
                Stack(
                  children: [
                    GageAvatar(
                      imageUrl: avatarUrl,
                      fallbackName: displayName,
                      radius: 24,
                    ),
                    if (isOnline)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
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

                // Nama & Cuplikan Pesan
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: roleBadgeColor.withValues(alpha: isDark ? 0.25 : 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleBadge,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: roleBadgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        (chat['lastMessage'] ?? '').toString(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                          color: isDark
                              ? (unread > 0 ? Colors.white : Colors.white60)
                              : (unread > 0 ? const Color(0xFF0F172A) : Colors.grey.shade600),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Waktu & Unread Counter
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      (chat['time'] ?? '').toString(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                        color: unread > 0 ? GageTheme.primary : Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: GageTheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 56,
            color: isDark ? Colors.white24 : Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada percakapan di kategori ini',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
