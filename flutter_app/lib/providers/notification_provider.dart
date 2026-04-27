import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _loading = false;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get loading => _loading;

  final ApiService _api = ApiService();

  Future<void> load() async {
    _loading = true;
    notifyListeners();

    try {
      final data = await _api.getNotifications();
      _notifications = (data['notifications'] as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      _unreadCount = data['unread_count'] ?? 0;
    } catch (_) {}

    _loading = false;
    notifyListeners();
  }

  Future<void> markRead(int id) async {
    await _api.markNotificationRead(id);
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1 && !_notifications[idx].read) {
      _notifications[idx] = NotificationModel(
        id: _notifications[idx].id,
        title: _notifications[idx].title,
        body: _notifications[idx].body,
        notificationType: _notifications[idx].notificationType,
        read: true,
        notifiableType: _notifications[idx].notifiableType,
        notifiableId: _notifications[idx].notifiableId,
        createdAt: _notifications[idx].createdAt,
      );
      _unreadCount = (_unreadCount - 1).clamp(0, 999);
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _api.markAllNotificationsRead();
    _notifications = _notifications.map((n) => NotificationModel(
      id: n.id,
      title: n.title,
      body: n.body,
      notificationType: n.notificationType,
      read: true,
      notifiableType: n.notifiableType,
      notifiableId: n.notifiableId,
      createdAt: n.createdAt,
    )).toList();
    _unreadCount = 0;
    notifyListeners();
  }
}
