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
import 'package:gage_app/providers/order_provider.dart';
import 'package:gage_app/shared/widgets/gage_avatar.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Semua', 'Bantuan', 'Driver', 'Toko'];

  final List<Map<String, dynamic>> _seedChats = [
    if (GageApiClient.useDevSeedData) ...[
      {
        'id': 'chat-driver-01',
        'name': 'Budi Santoso',
        'role': 'driver',
        'lastMessage': 'Siap kak, makanan sudah saya ambil dari resto ya.',
        'time': '10:35',
        'unread': 1,
        'isOnline': true,
        'phone': '081398765432',
        'orderId': '8821',
        'category': 'driver',
        'avatar': null,
      },
      {
        'id': 'chat-store-01',
        'name': 'Dimsum Sewu Pracimantoro',
        'role': 'merchant',
        'lastMessage': 'Stok Dimsum Mozzarella ready banyak kak, siap diproses!',
        'time': '09:15',
        'unread': 0,
        'isOnline': false,
        'phone': '081398765432',
        'orderId': 'STORE-DIMSUM',
        'category': 'store',
        'avatar': 'assets/images/resto_dimsum_sewu.png',
      },
      {
        'id': 'chat-store-02',
        'name': 'Rocket Chicken Pracimantoro',
        'role': 'merchant',
        'lastMessage': 'Ayam Geprek level 3 dan nasi hangat sedang disiapkan.',
        'time': 'Kemarin',
        'unread': 0,
        'isOnline': false,
        'phone': '081298761234',
        'orderId': 'STORE-ROCKET',
        'category': 'store',
        'avatar': 'assets/images/resto_rocket_chicken.png',
      },
    ],
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatChatPreview(ChatMessage msg) {
    final text = msg.text.trim();
    if (text.isNotEmpty) return text;
    if (msg.isImage) return 'Mengirim foto';
    if (msg.isVoice) return 'Pesan suara';
    return 'Pesan baru';
  }

  List<Map<String, dynamic>> _buildChats(
    OrderProvider? orderProv,
    InAppChatProvider? chatProv,
  ) {
    final chats = <Map<String, dynamic>>[];

    final supportMsgs = chatProv?.getMessages('cs-gage-support') ?? const [];
    final supportLast = supportMsgs.isNotEmpty
        ? _formatChatPreview(supportMsgs.last)
        : 'Halo! Ada yang bisa kami bantu terkait pesanan atau layanan GAGE hari ini?';
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
      'phone': '',
      'orderId': 'cs-gage-support',
      'category': 'support',
      'avatar': 'assets/images/gage_icon.png',
    });

    final seenKeys = <String>{};
    if (orderProv != null) {
      final allOrders = [...orderProv.activeOrders, ...orderProv.orderHistory];
      for (final order in allOrders) {
        final shortOrd = order.orderNumber.trim().isNotEmpty
            ? order.orderNumber.trim().split('/').last
            : order.id;
        if (order.hasAssignedDriver) {
          final cleanDriver = InAppChatScreen.cleanDisplayName(
            order.driverName ?? 'Driver',
            role: 'driver',
          );
          final key = 'driver:${order.id}';
          if (seenKeys.add(key)) {
            final msgs = chatProv?.getMessages(order.id) ?? const [];
            final lastMsg = msgs.isNotEmpty
                ? _formatChatPreview(msgs.last)
                : 'Pesanan #$shortOrd • Chat dengan $cleanDriver';
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
              'phone': order.driverPhone ?? '',
              'orderId': order.id,
              'category': 'driver',
              'avatar': order.driverAvatar,
            });
          }
        }
        if (!order.isTransportService && order.merchantName.trim().isNotEmpty) {
          final storeKey = 'store:${order.merchantName.trim().toLowerCase()}';
          if (seenKeys.add(storeKey)) {
            final msgs = chatProv?.getMessages(order.id) ?? const [];
            final lastMsg = msgs.isNotEmpty
                ? _formatChatPreview(msgs.last)
                : 'Pesanan #$shortOrd • ${order.statusLabel}';
            final timeStr = msgs.isNotEmpty
                ? DateFormat('HH:mm').format(msgs.last.timestamp)
                : DateFormat('HH:mm').format(
                    DateTime.fromMillisecondsSinceEpoch(order.createdAt),
                  );
            chats.add({
              'id': 'order-store-${order.id}',
              'name': order.merchantName.trim(),
              'role': 'merchant',
              'lastMessage': lastMsg,
              'time': timeStr,
              'unread': 0,
              'isOnline': order.isActive,
              'phone': order.merchantPhone ?? '',
              'orderId': order.id,
              'category': 'store',
              'avatar': order.resolveMerchantAvatarAsset(),
            });
          }
        }
      }
    }

    if (GageApiClient.useDevSeedData) {
      for (final seed in _seedChats) {
        final cat = seed['category'] as String? ?? '';
        final orderId = seed['orderId'] as String? ?? '';
        final name = (seed['name'] as String? ?? '').trim().toLowerCase();
        final dupDriver = cat == 'driver' && seenKeys.contains('driver:$orderId');
        final dupStore = cat == 'store' && seenKeys.contains('store:$name');
        if (!dupDriver && !dupStore) {
          final msgs = chatProv?.getMessages(orderId) ?? const [];
          if (msgs.isNotEmpty) {
            chats.add({
              ...seed,
              'lastMessage': _formatChatPreview(msgs.last),
              'time': DateFormat('HH:mm').format(msgs.last.timestamp),
            });
          } else {
            chats.add(seed);
          }
        }
      }
    }
    return chats;
  }

  List<Map<String, dynamic>> _filterChats(
    List<Map<String, dynamic>> allChats,
    int tabIdx,
  ) {
    switch (tabIdx) {
      case 1:
        return allChats.where((c) => c['category'] == 'support').toList();
      case 2:
        return allChats.where((c) => c['category'] == 'driver').toList();
      case 3:
        return allChats.where((c) => c['category'] == 'store').toList();
      case 0:
      default:
        return allChats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    OrderProvider? orderProv;
    try {
      orderProv = context.watch<OrderProvider>();
    } catch (_) {
      orderProv = null;
    }
    InAppChatProvider? chatProv;
    try {
      chatProv = context.watch<InAppChatProvider>();
    } catch (_) {
      chatProv = null;
    }
    final allChats = _buildChats(orderProv, chatProv);

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white : const Color(0xFF1E293B),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pesan & Bantuan',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: NotificationService.instance,
            builder: (context, _) {
              if (NotificationService.instance.unreadChatCount <= 0) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () {
                  NotificationService.instance.markAllChatsAsRead();
                  GageToast.show(context, 'Semua chat ditandai dibaca', type: GageToastType.success);
                },
                icon: const Icon(Icons.done_all_rounded, size: 16, color: GageTheme.primary),
                label: const Text(
                  'Tandai Dibaca',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            color: isDark ? GageTheme.darkSurface : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Container(
              height: 38,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(999),
              ),
              child: TabBar(
                controller: _tabController,
                onTap: (_) => HapticFeedback.selectionClick(),
                indicator: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
                tabs: _tabs.map((t) => Tab(text: t)).toList(),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (idx) {
              final chats = _filterChats(allChats, idx);

              if (chats.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Belum Ada Percakapan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pesan pada kategori ini akan tersimpan di sini.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                );
              }

              // WhatsApp-Style Pure Clean Chat List with Hairline Divider
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(0, 4, 0, 16),
                itemCount: chats.length,
                separatorBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(left: 74, right: 16),
                  child: Divider(
                    height: 1,
                    thickness: 0.6,
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                ),
                itemBuilder: (ctx, itemIdx) {
                  final chat = chats[itemIdx];
                  final chatId = (chat['id'] as String?) ?? '';
                  final rawAvatar = chat['avatar'] as String?;
                  final avatarPath =
                      (rawAvatar != null && rawAvatar.trim().isNotEmpty)
                          ? rawAvatar.trim()
                          : null;
                  final category = (chat['category'] as String?) ?? '';

                  return AnimatedBuilder(
                    animation: NotificationService.instance,
                    builder: (ctx, _) {
                      final unread = NotificationService.instance.unreadCountForChat(chatId);
                      return InkWell(
                    onTap: () {
                      NotificationService.instance.markChatAsRead(chatId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InAppChatScreen(
                            orderId: chat['orderId'] ?? '8821',
                            recipientName: chat['name'] ?? 'Driver',
                            recipientRole: chat['role'] ?? 'driver',
                            recipientPhone: chat['phone'] ?? '',
                            recipientAvatar: avatarPath,
                            currentRole: 'customer',
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          // Round Avatar
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              GageAvatar(
                                imageUrl: avatarPath,
                                fallbackName: chat['name']?.toString() ?? 'Chat',
                                radius: 24,
                              ),
                              if (chat['isOnline'] == true)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: isDark ? GageTheme.darkSurface : Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),

                          // Name & Last Message
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              chat['name'],
                                              style: TextStyle(
                                                fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.bold,
                                                fontSize: 14,
                                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (category == 'driver' || category == 'store') ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                              decoration: BoxDecoration(
                                                color: category == 'driver'
                                                    ? (isDark ? GageTheme.primary.withValues(alpha: 0.15) : const Color(0xFFFEE2E2))
                                                    : (isDark ? Colors.blue.withValues(alpha: 0.15) : const Color(0xFFE0F2FE)),
                                                borderRadius: BorderRadius.circular(999),
                                              ),
                                              child: Text(
                                                category == 'driver' ? 'Driver' : 'Toko',
                                                style: TextStyle(
                                                  fontSize: 9.5,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.2,
                                                  color: category == 'driver'
                                                      ? GageTheme.primary
                                                      : (isDark ? Colors.blue.shade200 : const Color(0xFF0369A1)),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: unread > 0 ? GageTheme.primary : (isDark ? Colors.white60 : Colors.grey.shade500),
                                        fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        chat['lastMessage'],
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: unread > 0
                                              ? (isDark ? Colors.grey.shade100 : const Color(0xFF0F172A))
                                              : (isDark ? Colors.grey.shade400 : const Color(0xFF64748B)),
                                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: GageTheme.primary,
                                          borderRadius: BorderRadius.circular(999),
                                          boxShadow: [
                                            BoxShadow(
                                              color: GageTheme.primary.withValues(alpha: 0.25),
                                              blurRadius: 4,
                                              offset: const Offset(0, 1),
                                            ),
                                          ],
                                        ),
                                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                        child: Text(
                                          '$unread',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            height: 1.0,
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
              );
            }),
          ),
    );
  }
}
