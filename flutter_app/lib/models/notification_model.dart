class NotificationModel {
  final int id;
  final String title;
  final String? body;
  final String notificationType;
  final bool read;
  final String? notifiableType;
  final int? notifiableId;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    this.body,
    required this.notificationType,
    required this.read,
    this.notifiableType,
    this.notifiableId,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      notificationType: json['notification_type'],
      read: json['read'] ?? false,
      notifiableType: json['notifiable_type'],
      notifiableId: json['notifiable_id'],
      createdAt: DateTime.parse(json['created_at']).toLocal(),
    );
  }
}
