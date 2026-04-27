import 'package:flutter/foundation.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  List<Task> _tasks = [];
  bool _loading = false;
  String? _error;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  String? get error => _error;

  List<Task> get activeTasks => _tasks.where((t) => t.isActive).toList();
  List<Task> get overdueTasks => _tasks.where((t) => t.overdue).toList();
  List<Task> get todayTasks => _tasks.where((t) {
    if (t.dueDate == null || !t.isActive) return false;
    final today = DateTime.now();
    return t.dueDate!.year == today.year &&
        t.dueDate!.month == today.month &&
        t.dueDate!.day == today.day;
  }).toList();

  final ApiService _api = ApiService();

  Future<void> loadTasks({String? status, int? userId}) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _api.getTasks(status: status, userId: userId);
    } catch (e) {
      _error = e.toString();
    }

    _loading = false;
    notifyListeners();
  }

  Future<Task> createTask(Map<String, dynamic> params) async {
    final task = await _api.createTask(params);
    _tasks.insert(0, task);
    notifyListeners();
    return task;
  }

  Future<Task> updateTask(int id, Map<String, dynamic> params) async {
    final updated = await _api.updateTask(id, params);
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) _tasks[idx] = updated;
    notifyListeners();
    return updated;
  }

  Future<void> completeTask(int id) async {
    final updated = await _api.completeTask(id);
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx != -1) _tasks[idx] = updated;
    notifyListeners();
  }
}
