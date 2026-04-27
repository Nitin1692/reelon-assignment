class Task {
  final int id;
  final String title;
  final String? description;
  final String taskType;
  final DateTime? dueDate;
  final String priority;
  final String status;
  final bool overdue;
  final DateTime? completedAt;
  final int userId;
  final Map<String, dynamic>? createdBy;
  final int? scheduleEntryId;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.taskType,
    this.dueDate,
    required this.priority,
    required this.status,
    required this.overdue,
    this.completedAt,
    required this.userId,
    this.createdBy,
    this.scheduleEntryId,
  });

  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isActive => !isCompleted && !isCancelled;

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      taskType: json['task_type'] ?? 'general',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      priority: json['priority'] ?? 'medium',
      status: json['status'] ?? 'pending',
      overdue: json['overdue'] ?? false,
      completedAt: json['completed_at'] != null ? DateTime.parse(json['completed_at']) : null,
      userId: json['user_id'],
      createdBy: json['created_by'],
      scheduleEntryId: json['schedule_entry_id'],
    );
  }
}
