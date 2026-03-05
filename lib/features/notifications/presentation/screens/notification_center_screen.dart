import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/entities/app_notification.dart';
import '../bloc/notification_bloc.dart';
import '../bloc/notification_event.dart';
import '../bloc/notification_state.dart';

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    context.read<NotificationBloc>().add(const NotificationsLoadRequested());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppConstants.backgroundDark,
        foregroundColor: Colors.white,
        title: const Text(
          'مركز الإشعارات',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          BlocBuilder<NotificationBloc, NotificationState>(
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton.icon(
                onPressed: () => context
                    .read<NotificationBloc>()
                    .add(const NotificationMarkAllRead()),
                icon: const Icon(Icons.done_all, color: AppConstants.primaryCyan, size: 18),
                label: const Text(
                  'قراءة الكل',
                  style: TextStyle(
                    color: AppConstants.primaryCyan,
                    fontFamily: 'Cairo',
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined, color: Colors.white54),
            tooltip: 'مسح الكل',
            onPressed: () => _confirmClearAll(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppConstants.primaryCyan,
          labelColor: AppConstants.primaryCyan,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: const TextStyle(fontFamily: 'Cairo', fontSize: 13),
          tabs: const [
            Tab(text: 'الكل'),
            Tab(text: 'غير مقروءة'),
            Tab(text: 'حرجة'),
          ],
        ),
      ),
      body: BlocBuilder<NotificationBloc, NotificationState>(
        builder: (context, state) {
          if (state.status == NotificationStatus.loading ||
              state.status == NotificationStatus.initial) {
            return const Center(
              child: CircularProgressIndicator(color: AppConstants.primaryCyan),
            );
          }

          return TabBarView(
            controller: _tabs,
            children: [
              _NotificationList(notifications: state.notifications),
              _NotificationList(notifications: state.unread),
              _NotificationList(notifications: state.criticalNotifications),
            ],
          );
        },
      ),
    );
  }

  void _confirmClearAll(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppConstants.surfaceDark,
        title: const Text(
          'مسح جميع الإشعارات',
          style: TextStyle(color: Colors.white, fontFamily: 'Cairo'),
        ),
        content: const Text(
          'هل تريد حذف جميع الإشعارات؟ لا يمكن التراجع.',
          style: TextStyle(color: Colors.white70, fontFamily: 'Cairo'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء',
                style: TextStyle(color: Colors.white54, fontFamily: 'Cairo')),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context
                  .read<NotificationBloc>()
                  .add(const NotificationsClearAll());
            },
            child: const Text('مسح',
                style: TextStyle(color: Colors.redAccent, fontFamily: 'Cairo')),
          ),
        ],
      ),
    );
  }
}

// ── Notification list ─────────────────────────────────────────────────────────

class _NotificationList extends StatelessWidget {
  final List<AppNotification> notifications;

  const _NotificationList({required this.notifications});

  @override
  Widget build(BuildContext context) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none_outlined,
              color: Colors.white24,
              size: 64,
            ),
            const SizedBox(height: 12),
            const Text(
              'لا توجد إشعارات',
              style: TextStyle(
                color: Colors.white38,
                fontFamily: 'Cairo',
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: notifications.length,
      separatorBuilder: (_, __) =>
          const Divider(color: Colors.white10, height: 1, indent: 72),
      itemBuilder: (context, index) {
        final n = notifications[index];
        return _NotificationTile(notification: n);
      },
    );
  }
}

// ── Single notification tile ──────────────────────────────────────────────────

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final n = notification;

    return Dismissible(
      key: ValueKey(n.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        color: Colors.redAccent,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) =>
          context.read<NotificationBloc>().add(NotificationDeleted(n.id)),
      child: InkWell(
        onTap: () {
          if (!n.isRead) {
            context.read<NotificationBloc>().add(NotificationMarkRead(n.id));
          }
          if (n.route != null) {
            Navigator.of(context).pop();
            // Navigate to the linked route.
          }
        },
        child: Container(
          color: n.isRead ? Colors.transparent : Colors.white.withAlpha(8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon badge
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _iconBgColor(n.type),
                ),
                child: Icon(_iconData(n.type), color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              // ── Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _TypeChip(type: n.type),
                        Text(
                          _formatTime(n.createdAt),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 11,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.titleAr,
                      style: TextStyle(
                        color: n.isRead ? Colors.white70 : Colors.white,
                        fontFamily: 'Cairo',
                        fontWeight: n.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        fontSize: 14,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    if (n.bodyAr.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.bodyAr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white54,
                          fontFamily: 'Cairo',
                          fontSize: 12,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ],
                ),
              ),
              // ── Unread dot
              if (!n.isRead) ...[
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 4,
                  backgroundColor: AppConstants.primaryCyan,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _iconBgColor(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.breach:          return Colors.red.shade700;
      case AppNotificationType.suspiciousLogin: return Colors.orange.shade800;
      case AppNotificationType.weakPassword:    return Colors.amber.shade700;
      case AppNotificationType.syncComplete:    return Colors.teal.shade700;
      case AppNotificationType.achievement:     return Colors.purple.shade600;
      case AppNotificationType.security:        return AppConstants.primaryCyan.withAlpha(200);
      case AppNotificationType.system:          return Colors.blueGrey.shade700;
    }
  }

  IconData _iconData(AppNotificationType type) {
    switch (type) {
      case AppNotificationType.breach:          return Icons.security_outlined;
      case AppNotificationType.suspiciousLogin: return Icons.warning_amber_outlined;
      case AppNotificationType.weakPassword:    return Icons.lock_open_outlined;
      case AppNotificationType.syncComplete:    return Icons.sync_outlined;
      case AppNotificationType.achievement:     return Icons.emoji_events_outlined;
      case AppNotificationType.security:        return Icons.shield_outlined;
      case AppNotificationType.system:          return Icons.info_outline;
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

class _TypeChip extends StatelessWidget {
  final AppNotificationType type;
  const _TypeChip({required this.type});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        type.labelAr,
        style: const TextStyle(
          color: Colors.white60,
          fontFamily: 'Cairo',
          fontSize: 10,
        ),
      ),
    );
  }
}
