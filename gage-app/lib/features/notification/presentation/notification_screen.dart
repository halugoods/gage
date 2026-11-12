import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gage_app/core/theme/gage_theme.dart';
import 'package:gage_app/core/services/notification_service.dart';
import 'package:gage_app/shared/widgets/gage_toast.dart';

typedef InboxScreen = NotificationScreen;

class NotificationScreen extends StatefulWidget {
  final int initialTabIndex;

  const NotificationScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final Set<String> _expandedNotifIds = {};
  final Set<String> _sessionUnreadIds = {};

  @override
  void initState() {
    super.initState();
    _sessionUnreadIds.addAll(
      NotificationService.instance.items.where((n) => !n.isRead).map((n) => n.id),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      NotificationService.instance.markAllAsRead();
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes <= 0 ? 1 : diff.inMinutes}m lalu';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}j lalu';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}h lalu';
    } else {
      return DateFormat('d MMM', 'id_ID').format(time);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'promo':
        return Icons.local_offer_rounded;
      case 'transaksi':
      case 'order':
        return Icons.receipt_long_rounded;
      case 'dompet':
      case 'wallet':
        return Icons.account_balance_wallet_rounded;
      case 'sistem':
      default:
        return Icons.info_rounded;
    }
  }

  Color _getTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'promo':
        return const Color(0xFFE52320);
      case 'transaksi':
      case 'order':
        return const Color(0xFF16A34A);
      case 'dompet':
      case 'wallet':
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
              if (notifService.hasUnread || _sessionUnreadIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    notifService.markAllAsRead();
                    setState(() => _sessionUnreadIds.clear());
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
          ),
          body: _buildNotificationList(allNotifs, notifService, isDark),
        );
      },
    );
  }

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
            const SizedBox(height: 6),
            Text(
              'Info promo, pesanan, dan sistem akan muncul di sini',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: allNotifs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final notif = allNotifs[idx];
        final isUnread = !notif.isRead || _sessionUnreadIds.contains(notif.id);
        final isExpanded = _expandedNotifIds.contains(notif.id);
        final color = _getTypeColor(notif.type);
        final icon = _getTypeIcon(notif.type);

        return Dismissible(
          key: Key(notif.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
          ),
          onDismissed: (_) {
            notifService.delete(notif.id);
            GageToast.show(context, 'Notifikasi dihapus', type: GageToastType.info);
          },
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? (!isUnread ? GageTheme.darkSurface : const Color(0xFF1E293B))
                  : (!isUnread ? Colors.white : const Color(0xFFFFF7ED)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: !isUnread
                    ? (isDark ? Colors.white10 : Colors.grey.shade200)
                    : GageTheme.primary.withValues(alpha: 0.35),
                width: !isUnread ? 0.8 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (!notif.isRead) {
                    notifService.markAsRead(notif.id);
                  }
                  setState(() {
                    _sessionUnreadIds.remove(notif.id);
                    if (isExpanded) {
                      _expandedNotifIds.remove(notif.id);
                    } else {
                      _expandedNotifIds.add(notif.id);
                    }
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 19),
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
                                    notif.title,
                                    style: TextStyle(
                                      fontWeight: !isUnread ? FontWeight.bold : FontWeight.w900,
                                      fontSize: 13.5,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _formatTime(notif.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              notif.body,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: isDark ? Colors.grey.shade300 : const Color(0xFF334155),
                              ),
                              maxLines: isExpanded ? 10 : 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (isUnread) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: GageTheme.primary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: GageTheme.primary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
