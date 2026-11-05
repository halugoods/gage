import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

typedef InboxScreen = NotificationScreen;

class NotificationScreen extends StatefulWidget {
  final int initialTabIndex; // 0: Notif, 1: Chat

  const NotificationScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _mainTabController;
  final Set<String> _expandedNotifIds = {};

  // Chat Tab Sub-filters
  String _selectedChatFilter = 'Semua'; // 'Semua', 'Bantuan AI', 'Driver', 'Toko'

  final List<Map<String, dynamic>> _allChats = [
    {
      'id': 'chat-ai-01',
      'name': 'Gage AI Assistant (24/7)',
      'role': 'ai',
      'lastMessage': 'Halo! Ada yang bisa saya bantu terkait pesanan atau promo hari ini?',
      'time': '10:42',
      'unread': 1,
      'isOnline': true,
      'phone': '081234567890',
      'orderId': 'AI-SUPPORT',
      'category': 'ai',
      'avatar': 'assets/images/gage_chat_icon.png',
    },
    {
      'id': 'chat-driver-01',
      'name': 'Budi Santoso (Driver GAGE)',
      'role': 'driver',
      'lastMessage': 'Siap kak, makanan sudah saya ambil dari resto ya.',
      'time': '10:35',
      'unread': 1,
      'isOnline': true,
      'phone': '081398765432',
      'orderId': 'ORD-88219',
      'category': 'driver',
      'avatar': 'assets/images/gage_chat_icon.png',
    },
    {
      'id': 'chat-store-01',
      'name': 'Dimsum Sewu Mas Agus',
      'role': 'merchant',
      'lastMessage': 'Stok Dimsum Mozzarella ready banyak kak, siap diproses!',
      'time': '09:15',
      'unread': 0,
      'isOnline': false,
      'phone': '081398765432',
      'orderId': 'ORD-88219',
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
  ];

  @override
  void initState() {
    super.initState();
    _mainTabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
  }

  @override
  void dispose() {
    _mainTabController.dispose();
    super.dispose();
  }

  String _formatRelativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 1 ? 1 : diff.inMinutes} mnt lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} jam lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(time);
    }
  }

  IconData _getCategoryIcon(String cat) {
    switch (cat) {
      case 'transaksi':
        return Icons.receipt_long_rounded;
      case 'promo':
        return Icons.local_offer_rounded;
      case 'sistem':
      default:
        return Icons.info_outline_rounded;
    }
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'transaksi':
        return const Color(0xFF16A34A);
      case 'promo':
        return const Color(0xFFEA580C);
      case 'sistem':
      default:
        return const Color(0xFF2563EB);
    }
  }

  List<Map<String, dynamic>> get _filteredChats {
    if (_selectedChatFilter == 'Semua') return _allChats;
    if (_selectedChatFilter == 'Bantuan AI') return _allChats.where((c) => c['category'] == 'ai').toList();
    if (_selectedChatFilter == 'Driver') return _allChats.where((c) => c['category'] == 'driver').toList();
    if (_selectedChatFilter == 'Toko') return _allChats.where((c) => c['category'] == 'store').toList();
    return _allChats;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: NotificationService.instance,
      builder: (context, _) {
        final notifService = NotificationService.instance;
        final allNotifs = notifService.items;

        return Scaffold(
          backgroundColor: isDark ? GageTheme.darkBackground : const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
            elevation: 0.5,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Inbox',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 17,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            actions: [
              if (notifService.hasUnread)
                TextButton.icon(
                  onPressed: () {
                    notifService.markAllAsRead();
                    GageToast.show(context, 'Semua notifikasi ditandai telah dibaca', type: GageToastType.success);
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 16, color: GageTheme.primary),
                  label: const Text(
                    'Tandai Dibaca',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GageTheme.primary),
                  ),
                ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(52),
              child: Container(
                color: isDark ? GageTheme.darkSurface : Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TabBar(
                    controller: _mainTabController,
                    indicator: BoxDecoration(
                      color: GageTheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    dividerColor: Colors.transparent,
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    tabs: const [
                      Tab(text: 'Notif'),
                      Tab(text: 'Chat'),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: TabBarView(
            controller: _mainTabController,
            children: [
              // TAB 1: NOTIF (Flat listing bersih tanpa sub-filter)
              _buildNotificationList(allNotifs, notifService, isDark),

              // TAB 2: CHAT (WhatsApp style list + 4 filter chips)
              _buildChatList(isDark),
            ],
          ),
        );
      },
    );
  }

  // Widget List Notifikasi Flat Bersih
  Widget _buildNotificationList(List<GageNotification> allNotifs, NotificationService notifService, bool isDark) {
    if (allNotifs.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.notifications_off_outlined, size: 52, color: Colors.grey.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'Belum ada notifikasi baru',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Promo, update pesanan, dan info akun akan muncul di sini',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade500 : Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: allNotifs.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 0.6,
        color: isDark ? Colors.white10 : Colors.grey.shade200,
      ),
      itemBuilder: (context, idx) {
        final item = allNotifs[idx];
        final isExpanded = _expandedNotifIds.contains(item.id);
        final catColor = _getCategoryColor(item.category);
        final catIcon = _getCategoryIcon(item.category);

        return InkWell(
          onTap: () {
            setState(() {
              if (isExpanded) {
                _expandedNotifIds.remove(item.id);
              } else {
                _expandedNotifIds.add(item.id);
              }
            });
            if (!item.isRead) {
              notifService.markAsRead(item.id);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
            color: !item.isRead
                ? (isDark ? GageTheme.primary.withValues(alpha: 0.08) : GageTheme.primary.withValues(alpha: 0.04))
                : Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Kategori Bulat
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),

                // Konten Judul & Body
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: !item.isRead ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatRelativeTime(item.timestamp),
                            style: TextStyle(
                              fontSize: 10.5,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        item.body,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          height: 1.3,
                        ),
                        maxLines: isExpanded ? null : 1,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Arrow Accordion Expand
                Padding(
                  padding: const EdgeInsets.only(left: 6, top: 4),
                  child: Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Widget List Chat Gaya WhatsApp
  Widget _buildChatList(bool isDark) {
    final chats = _filteredChats;

    return Column(
      children: [
        // Sub-filter Chips: Semua, Bantuan AI, Driver, Toko (Segmented Pill)
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: ['Semua', 'Bantuan AI', 'Driver', 'Toko'].map((filter) {
              final isSelected = _selectedChatFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedChatFilter = filter);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? GageTheme.primary
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? GageTheme.primary
                            : (isDark ? Colors.white10 : Colors.grey.shade300),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        filter,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey.shade300 : const Color(0xFF475569)),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const Divider(height: 1, thickness: 0.6),

        // Daftar Chat WhatsApp Style
        Expanded(
          child: chats.isEmpty
              ? Center(
                  child: Text(
                    'Tidak ada percakapan dalam kategori ini',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemCount: chats.length,
                  separatorBuilder: (_, _) => Divider(
                    height: 1,
                    indent: 68,
                    thickness: 0.5,
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                  ),
                  itemBuilder: (context, idx) {
                    final item = chats[idx];
                    final unread = (item['unread'] ?? 0) as int;

                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => InAppChatScreen(
                              orderId: item['orderId'] ?? 'ORD-88219',
                              recipientName: item['name'] ?? 'Kontak',
                              recipientRole: item['role'] ?? 'driver',
                              recipientPhone: item['phone'] ?? '08123456789',
                            ),
                          ),
                        );
                      },
                      leading: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: SizedBox(
                              width: 46,
                              height: 46,
                              child: Image.asset(
                                item['avatar'] ?? 'assets/images/gage_chat_icon.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: GageTheme.primary.withValues(alpha: 0.1),
                                  child: const Icon(Icons.person_rounded, color: GageTheme.primary, size: 24),
                                ),
                              ),
                            ),
                          ),
                          if (item['isOnline'] == true)
                            Positioned(
                              right: 1,
                              bottom: 1,
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF16A34A),
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
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['name'] ?? '',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            item['time'] ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
                              color: unread > 0 ? GageTheme.primary : (isDark ? Colors.grey.shade400 : Colors.grey.shade500),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item['lastMessage'] ?? '',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (unread > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: const BoxDecoration(
                                color: GageTheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$unread',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
