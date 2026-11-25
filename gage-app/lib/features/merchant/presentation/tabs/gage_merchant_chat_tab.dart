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

/// Tab 1: Chat Mitra Usaha GAGE (Paritas 1:1 dengan ChatHubScreen Customer Portal)
/// - Segmented Capsule TabBar (Semua, Bantuan, Driver, Pelanggan) + TabBarView
/// - WhatsApp-style clean list with hairline divider (tanpa kotak kartu per item)
class GageMerchantChatTab extends StatefulWidget {
  const GageMerchantChatTab({super.key});

  @override
  State<GageMerchantChatTab> createState() => _GageMerchantChatTabState();
}

class _GageMerchantChatTabState extends State<GageMerchantChatTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Semua', 'Bantuan', 'Driver', 'Pelanggan'];

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

    return Container(
      color: isDark ? GageTheme.darkBackground : Colors.white,
      child: Column(
        children: [
          // Segmented Capsule TabBar (Paritas 1:1 ChatHubScreen Customer)
          Container(
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

          // WhatsApp-Style Pure Clean Chat List with Hairline Divider
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(_tabs.length, (idx) {
                final chats = _filterChats(allChats, idx);
                if (chats.isEmpty) {
                  return _buildEmptyState(isDark);
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
                  itemCount: chats.length,
                  separatorBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.only(left: 74, right: 16),
                    child: Divider(
                      height: 1,
                      thickness: 0.6,
                      color: isDark ? Colors.white10 : Colors.grey.shade200,
                    ),
                  ),
                  itemBuilder: (context, index) {
                    return _buildChatRow(context, chats[index], isDark);
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatRow(BuildContext context, Map<String, dynamic> chat, bool isDark) {
    final unread = (chat['unread'] as int?) ?? 0;
    final isOnline = chat['isOnline'] == true;
    final role = (chat['role'] as String?) ?? 'customer';
    final category = (chat['category'] as String?) ?? '';
    final displayName = (chat['name'] ?? 'Pengguna GAGE').toString();
    final avatarUrl = chat['avatar']?.toString();

    return InkWell(
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Round Avatar + Online Dot
            Stack(
              clipBehavior: Clip.none,
              children: [
                GageAvatar(
                  imageUrl: avatarUrl,
                  fallbackName: displayName,
                  radius: 24,
                ),
                if (isOnline)
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
                                displayName,
                                style: TextStyle(
                                  fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (category == 'driver' || category == 'customer') ...[
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
                                  category == 'driver' ? 'Driver' : 'Pelanggan',
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
                        (chat['time'] ?? '').toString(),
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
                          (chat['lastMessage'] ?? '').toString(),
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
  }

  Widget _buildEmptyState(bool isDark) {
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
}
