import 'package:flutter/material.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/shared/widgets/gage_bottom_nav_bar.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

class ChatHubScreen extends StatefulWidget {
  const ChatHubScreen({super.key});

  @override
  State<ChatHubScreen> createState() => _ChatHubScreenState();
}

class _ChatHubScreenState extends State<ChatHubScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Semua', 'Bantuan AI', 'Driver', 'Toko'];

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
      'orderId': '8821',
      'category': 'driver',
      'avatar': 'assets/images/gage_chat_icon.png',
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

  List<Map<String, dynamic>> _filterChats(int tabIdx) {
    switch (tabIdx) {
      case 1:
        return _allChats.where((c) => c['category'] == 'ai').toList();
      case 2:
        return _allChats.where((c) => c['category'] == 'driver').toList();
      case 3:
        return _allChats.where((c) => c['category'] == 'store').toList();
      case 0:
      default:
        return _allChats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? GageTheme.darkBackground : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? GageTheme.darkSurface : Colors.white,
        elevation: 0.5,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset(
              'assets/images/gage_chat_icon.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => const Icon(Icons.chat_bubble_rounded, color: GageTheme.primary, size: 24),
            ),
            const SizedBox(width: 10),
            Text(
              'Pesan & Bantuan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
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
                borderRadius: BorderRadius.circular(24),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: GageTheme.primary,
                  borderRadius: BorderRadius.circular(20),
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
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (idx) {
              final chats = _filterChats(idx);

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
                itemBuilder: (ctx, itemIdx) {
                  final chat = chats[itemIdx];
                  final unread = (chat['unread'] as int?) ?? 0;
                  final avatarPath = chat['avatar'] as String? ?? 'assets/images/gage_chat_icon.png';

                  return InkWell(
                    onTap: () {
                      setState(() => chat['unread'] = 0);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => InAppChatScreen(
                            orderId: chat['orderId'] ?? '8821',
                            recipientName: chat['name'] ?? 'Driver',
                            recipientRole: chat['role'] ?? 'driver',
                            recipientPhone: chat['phone'] ?? '081234567890',
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
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                                child: ClipOval(
                                  child: Image.asset(
                                    avatarPath,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (c, e, s) => const Icon(Icons.chat_bubble_rounded, color: GageTheme.primary, size: 24),
                                  ),
                                ),
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
                                      child: Text(
                                        chat['name'],
                                        style: TextStyle(
                                          fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : Colors.black87,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      chat['time'],
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: unread > 0 ? const Color(0xFF16A34A) : Colors.grey.shade500,
                                        fontWeight: unread > 0 ? FontWeight.bold : FontWeight.normal,
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
                                              ? (isDark ? Colors.grey.shade200 : Colors.black87)
                                              : (isDark ? Colors.grey.shade400 : Colors.black54),
                                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (unread > 0)
                                      Container(
                                        margin: const EdgeInsets.only(left: 8),
                                        padding: const EdgeInsets.all(5),
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF16A34A),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '$unread',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.bold,
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
            }),
          ),

          // Floating Bottom Navigation Bar (Tab 3: Chat)
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: GageBottomNavBar(currentIndex: 3),
          ),
        ],
      ),
    );
  }
}
