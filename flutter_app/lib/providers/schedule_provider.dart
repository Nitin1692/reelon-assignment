import 'package:flutter/foundation.dart';
import '../models/schedule_entry.dart';
import '../services/api_service.dart';

class ScheduleProvider with ChangeNotifier {
  List<ScheduleEntry> _entries = [];
  bool _loading = false;
  String? _error;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  List<ScheduleEntry> get entries => _entries;
  bool get loading => _loading;
  String? get error => _error;
  DateTime get focusedDay => _focusedDay;
  DateTime? get selectedDay => _selectedDay;

  final ApiService _api = ApiService();

  List<ScheduleEntry> entriesForDay(DateTime day) {
    return _entries.where((e) {
      final start = DateTime(e.startsAt.year, e.startsAt.month, e.startsAt.day);
      final end = DateTime(e.endsAt.year, e.endsAt.month, e.endsAt.day);
      final d = DateTime(day.year, day.month, day.day);
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  List<ScheduleEntry> get selectedDayEntries =>
      _selectedDay != null ? entriesForDay(_selectedDay!) : [];

  void setFocusedDay(DateTime day) {
    _focusedDay = day;
    notifyListeners();
    loadMonthEntries(day);
  }

  void setSelectedDay(DateTime day) {
    _selectedDay = day;
    notifyListeners();
  }

  Future<void> loadMonthEntries(DateTime month, {int? userId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final from = DateTime(month.year, month.month, 1);
      final to = DateTime(month.year, month.month + 1, 0, 23, 59, 59);

      _entries = await _api.getScheduleEntries(
        from: from.toUtc().toIso8601String(),
        to: to.toUtc().toIso8601String(),
        userId: userId,
      );
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<ScheduleEntry> createEntry(Map<String, dynamic> params) async {
    final entry = await _api.createScheduleEntry(params);
    _entries.add(entry);
    notifyListeners();
    return entry;
  }

  Future<ScheduleEntry> updateEntry(int id, Map<String, dynamic> params) async {
    final updated = await _api.updateScheduleEntry(id, params);
    final idx = _entries.indexWhere((e) => e.id == id);
    if (idx != -1) _entries[idx] = updated;
    notifyListeners();
    return updated;
  }

  Future<void> cancelEntry(int id) async {
    await _api.cancelScheduleEntry(id);
    _entries.removeWhere((e) => e.id == id);
    notifyListeners();
  }

  Future<Map<String, dynamic>> checkConflicts({
    required DateTime startsAt,
    required DateTime endsAt,
    int? excludeId,
    int? userId,
  }) async {
    return _api.checkConflicts(
      startsAt: startsAt.toUtc().toIso8601String(),
      endsAt: endsAt.toUtc().toIso8601String(),
      excludeId: excludeId,
      userId: userId,
    );
  }
}
