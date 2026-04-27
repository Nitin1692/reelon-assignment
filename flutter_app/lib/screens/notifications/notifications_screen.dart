import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/notification_model.dart';
import '../../providers/notification_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: provider.loading
          ? const Center(child: CircularProgressIndicator())
          : provider.notifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none, size: 60, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('No notifications', style: TextStyle(color: Colors.grey.shade500, fontSize: 16)),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: provider.notifications.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, indent: 70),
                  itemBuilder: (ctx, i) => _NotificationTile(notification: provider.notifications[i]),
                ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationTile({required this.notification});

  IconData get _icon {
    return switch (notification.notificationType) {
      'schedule_change' => Icons.event_note,
      'conflict' => Icons.warning_amber,
      'rsvp_update' => Icons.how_to_reg,
      'task_reminder' => Icons.task_alt,
      'assignment' => Icons.work_outline,
      _ => Icons.notifications,
    };
  }

  Color get _color {
    return switch (notification.notificationType) {
      'conflict' => Colors.orange,
      'rsvp_update' => Colors.purple,
      'task_reminder' => Colors.blue,
      _ => Colors.teal,
    };
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<NotificationProvider>();
    final timeFmt = DateFormat('MMM d, h:mm a');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: _color.withOpacity(notification.read ? 0.08 : 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(_icon, color: _color.withOpacity(notification.read ? 0.5 : 1.0), size: 20),
      ),
      title: Text(
        notification.title,
        style: TextStyle(
          fontWeight: notification.read ? FontWeight.normal : FontWeight.w600,
          color: notification.read ? Colors.grey.shade700 : null,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.body != null)
            Text(notification.body!, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          const SizedBox(height: 2),
          Text(timeFmt.format(notification.createdAt), style: TextStyle(color: Colors.grey.shade400, fontSize: 11)),
        ],
      ),
      trailing: !notification.read
          ? Container(width: 8, height: 8, decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle))
          : null,
      onTap: () {
        if (!notification.read) provider.markRead(notification.id);
      },
    );
  }
}
