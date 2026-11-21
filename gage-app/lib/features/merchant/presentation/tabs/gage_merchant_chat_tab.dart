import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gage_app/core/network/gage_api_client.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/features/chat/presentation/in_app_chat_screen.dart';

/// Tab 1: Chat Mitra Usaha GAGE (In-App Chat Hub 1:1 Paritas Customer Portal)
/// Menghubungkan komunikasi real-time toko dengan Driver, Pelanggan, dan Layanan Bantuan CS GAGE.
class GageMerchantChatTab extends StatefulWidget {
  const GageMerchantChatTab({super.key});

  @override
  State<GageMerchantChatTab> createState() => _GageMerchantChatTabState();
}

class _GageMerchantChatTabState extends State<GageMerchantChatTab> {
  int _activeFilterIndex = 0;
  final List<String> _filters = ['Semua', 'Driver', 'Pelanggan', 'Bantuan CS GAGE'];

  final List<Map<String, dynamic>> _mockChats = [
    {
      'id': 'chat-cs-01',
      'name': 'Pusat Bantuan Mitra GAGE (24/7)',
      'role': 'admin',
      'lastMessage': 'Halo Mitra Dimsum Sewu! Tim operasional GAGE siap membantu kelancaran pesanan Anda.',
      'time': 'Aktif',
      'unread': 0,
      'isOnline': true,
      'phone': '081234567890',
      'orderId': 'GAGE-CARE',
      'category': 'admin',
      'avatar': 'assets/icons/ic_launcher.png',
    },
    if (GageApiClient.useDevSeedData) ...[
      {
        'id': 'chat-driver-01',
        'name': 'Budi Santoso (Driver GAGE)',
        'role': 'driver',
        'lastMessage': 'Siap Mas, saya sudah dekat kios Alfamidi, pesanan dimsum sedang dibungkus?',
        'time': '10:35',
        'unread': 1,
        'isOnline': true,
        'phone': '081398765432',
        'orderId': '101',
        'category': 'driver',
        'avatar': 'assets/images/gage_chat_icon.png',
      },
      {
        'id': 'chat-cust-01',
        'name': 'Siti Rahmawati (Pelanggan)',
        'role': 'customer',
        'lastMessage': 'Kak minta saus sambalnya dipisah ya, jangan dicampur. Terima kasih!',
        'time': '09:20',
        'unread': 0,
        'isOnline': true,
        'phone': '081298761234',
        'orderId': '101',
        'category': 'customer',
        'avatar': 'assets/images/gage_chat_icon.png',
      },
      {
        'id': 'chat-driver-02',
        'name': 'Agus Prabowo (Driver GAGE)',
        'role': 'driver',
        'lastMessage': 'Pesanan sudah saya serahkan ke pembeli dengan aman Mas.',
        'time': 'Kemarin',
        'unread': 0,
        'isOnline': false,
        'phone': '081567890123',
        'orderId': '098',
        'category': 'driver',
        'avatar': 'assets/images/gage_chat_icon.png',
      },
    ],
  ];

  List<Map<String, dynamic>> _getFilteredChats() {
    switch (_activeFilterIndex) {
      case 1:
        return _mockChats.where((c) => c['category'] == 'driver').toList();
      case 2:
        return _mockChats.where((c) => c['category'] == 'customer').toList();
      case 3:
        return _mockChats.where((c) => c['category'] == 'admin').toList();
      case 0:
      default:
        return _mockChats;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = _getFilteredChats();

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
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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

    String roleBadge = 'Pelanggan';
    Color roleBadgeColor = const Color(0xFF0284C7);
    if (role == 'driver') {
      roleBadge = 'Driver GAGE';
      roleBadgeColor = GageTheme.primary;
    } else if (role == 'admin') {
      roleBadge = 'Bantuan CS';
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
                  recipientName: chat['name'],
                  recipientRole: role,
                  orderId: chat['orderId'],
                  recipientPhone: chat['phone'],
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
                // Avatar dengan indikator online
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                      child: ClipOval(
                        child: Image.asset(
                          chat['avatar'] ?? 'assets/images/gage_chat_icon.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.person_rounded,
                            color: GageTheme.primary,
                          ),
                        ),
                      ),
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
                              chat['name'],
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
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
                                fontWeight: FontWeight.w800,
                                color: roleBadgeColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        chat['lastMessage'],
                        style: TextStyle(
                          fontSize: 12,
                          color: unread > 0
                              ? (isDark ? Colors.white : const Color(0xFF0F172A))
                              : (isDark ? Colors.white60 : Colors.grey.shade600),
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Waktu & Unread Badge
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      chat['time'],
                      style: TextStyle(
                        fontSize: 11,
                        color: unread > 0 ? GageTheme.primary : (isDark ? Colors.white54 : Colors.grey.shade500),
                        fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unread > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: GageTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$unread',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
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
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 32,
                color: isDark ? Colors.white38 : Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Belum Ada Pesan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Percakapan dengan Driver dan Pelanggan per pesanan akan otomatis terhubung di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
