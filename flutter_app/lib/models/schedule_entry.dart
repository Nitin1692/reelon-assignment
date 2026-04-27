class ScheduleEntry {
  final int id;
  final String entryType;
  final String? title;
  final String? notes;
  final String? location;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool allDay;
  final String status;
  final bool requiresRsvp;
  final bool hasConflict;
  final int userId;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? updatedBy;
  final String? sourceType;
  final int? sourceId;
  final Map<String, dynamic>? rsvpSummary;
  final List<dynamic>? participations;
  final List<dynamic>? conflicts;

  ScheduleEntry({
    required this.id,
    required this.entryType,
    this.title,
    this.notes,
    this.location,
    required this.startsAt,
    required this.endsAt,
    required this.allDay,
    required this.status,
    required this.requiresRsvp,
    required this.hasConflict,
    required this.userId,
    this.createdBy,
    this.updatedBy,
    this.sourceType,
    this.sourceId,
    this.rsvpSummary,
    this.participations,
    this.conflicts,
  });

  bool get isActive => status == 'active';
  bool get isLinked => sourceType != null;

  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    return entryType.replaceAll('_', ' ').toUpperCase();
  }

  factory ScheduleEntry.fromJson(Map<String, dynamic> json) {
    return ScheduleEntry(
      id: json['id'],
      entryType: json['entry_type'],
      title: json['title'],
      notes: json['notes'],
      location: json['location'],
      startsAt: DateTime.parse(json['starts_at']).toLocal(),
      endsAt: DateTime.parse(json['ends_at']).toLocal(),
      allDay: json['all_day'] ?? false,
      status: json['status'] ?? 'active',
      requiresRsvp: json['requires_rsvp'] ?? false,
      hasConflict: json['has_conflict'] ?? false,
      userId: json['user_id'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      sourceType: json['source_type'],
      sourceId: json['source_id'],
      rsvpSummary: json['rsvp_summary'],
      participations: json['participations'],
      conflicts: json['conflicts'],
    );
  }
}
