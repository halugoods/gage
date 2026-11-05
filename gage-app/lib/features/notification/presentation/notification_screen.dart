import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['Semua', 'Transaksi', 'Promo', 'Informasi'];
  final Set<String> _expandedNotifIds = {};

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

  List<GageNotification> _filterList(List<GageNotification> all, int tabIdx) {
    switch (tabIdx) {
      case 1:
        return all.where((n) => n.category == 'transaksi').toList();
      case 2:
        return all.where((n) => n.category == 'promo').toList();
      case 3:
        return all.where((n) => n.category == 'sistem').toList();
      case 0:
      default:
        return all;
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
              'Notifikasi',
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
          body: TabBarView(
            controller: _tabController,
            children: List.generate(_tabs.length, (idx) {
              final list = _filterList(allNotifs, idx);

              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.notifications_off_outlined, size: 36, color: Colors.grey.shade400),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Belum Ada Notifikasi',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pemberitahuan aktivitas ${_tabs[idx].toLowerCase()} Anda akan muncul di sini.',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 6),
                itemCount: list.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  thickness: 0.6,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                itemBuilder: (ctx, itemIdx) {
                  final notif = list[itemIdx];
                  final catColor = _getCategoryColor(notif.category);
                  final catIcon = _getCategoryIcon(notif.category);
                  final isExpanded = _expandedNotifIds.contains(notif.id);

                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isExpanded) {
                          _expandedNotifIds.remove(notif.id);
                        } else {
                          _expandedNotifIds.add(notif.id);
                        }
                      });
                      if (!notif.isRead) {
                        notifService.markAsRead(notif.id);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      color: notif.isRead
                          ? Colors.transparent
                          : (isDark ? const Color(0xFF241515) : const Color(0xFFFFF8F7)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar Category
                              Container(
                                width: 36,
                                height: 36,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(catIcon, color: catColor, size: 18),
                              ),
                              const SizedBox(width: 12),

                              // Text Content & Chevron
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: TextStyle(
                                              fontWeight: notif.isRead ? FontWeight.bold : FontWeight.w900,
                                              fontSize: 13.5,
                                              color: isDark ? Colors.white : Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _formatRelativeTime(notif.timestamp),
                                          style: TextStyle(fontSize: 10.5, color: Colors.grey.shade500),
                                        ),
                                        if (!notif.isRead) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            width: 7,
                                            height: 7,
                                            decoration: const BoxDecoration(
                                              color: GageTheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 4),
                                        Icon(
                                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: isDark ? Colors.white38 : Colors.grey.shade500,
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.body,
                                      style: TextStyle(
                                        fontSize: 12,
                                        height: 1.35,
                                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                      ),
                                      maxLines: isExpanded ? null : 1,
                                      overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        );
      },
    );
  }
}
