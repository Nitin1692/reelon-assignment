import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import '../models/schedule_entry.dart';
import '../models/task.dart';
import '../models/user.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  Future<String?> getToken() async {
    _token ??= (await SharedPreferences.getInstance()).getString('auth_token');
    return _token;
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}$path').replace(queryParameters: query);
    final response = await http.get(uri, headers: await _headers());
    return _handle(response);
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> body) async {
    final response = await http.post(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> _put(String path, Map<String, dynamic> body) async {
    final response = await http.put(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handle(response);
  }

  Future<Map<String, dynamic>> _delete(String path) async {
    final response = await http.delete(
      Uri.parse('${AppConstants.baseUrl}$path'),
      headers: await _headers(),
    );
    return _handle(response);
  }

  Map<String, dynamic> _handle(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 400) {
      throw ApiException(
        body['error'] ?? body['errors']?.toString() ?? 'Unknown error',
        response.statusCode,
      );
    }
    return body;
  }

  // Auth
  Future<Map<String, dynamic>> login(String email, String password) =>
      _post('/auth/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) =>
      _post('/auth/register', data);

  Future<Map<String, dynamic>> getMe() => _get('/auth/me');

  // Schedule Entries
  Future<List<ScheduleEntry>> getScheduleEntries({
    String? from,
    String? to,
    String? entryType,
    int? userId,
  }) async {
    final query = <String, String>{};
    if (from != null) query['from'] = from;
    if (to != null) query['to'] = to;
    if (entryType != null) query['entry_type'] = entryType;
    if (userId != null) query['user_id'] = userId.toString();

    final data = await _get('/schedule_entries', query: query);
    return (data['schedule_entries'] as List)
        .map((e) => ScheduleEntry.fromJson(e))
        .toList();
  }

  Future<ScheduleEntry> getScheduleEntry(int id) async {
    final data = await _get('/schedule_entries/$id');
    return ScheduleEntry.fromJson(data['schedule_entry']);
  }

  Future<ScheduleEntry> createScheduleEntry(Map<String, dynamic> params) async {
    final data = await _post('/schedule_entries', {'schedule_entry': params});
    return ScheduleEntry.fromJson(data['schedule_entry']);
  }

  Future<ScheduleEntry> updateScheduleEntry(int id, Map<String, dynamic> params) async {
    final data = await _put('/schedule_entries/$id', {'schedule_entry': params});
    return ScheduleEntry.fromJson(data['schedule_entry']);
  }

  Future<void> cancelScheduleEntry(int id) async {
    await _post('/schedule_entries/$id/cancel', {});
  }

  Future<Map<String, dynamic>> checkConflicts({
    required String startsAt,
    required String endsAt,
    int? userId,
    int? excludeId,
  }) async {
    final query = <String, String>{
      'starts_at': startsAt,
      'ends_at': endsAt,
    };
    if (userId != null) query['user_id'] = userId.toString();
    if (excludeId != null) query['exclude_id'] = excludeId.toString();
    return _get('/schedule_entries/check_conflicts', query: query);
  }

  // Tasks
  Future<List<Task>> getTasks({
    String? status,
    String? priority,
    int? userId,
  }) async {
    final query = <String, String>{};
    if (status != null) query['status'] = status;
    if (priority != null) query['priority'] = priority;
    if (userId != null) query['user_id'] = userId.toString();

    final data = await _get('/tasks', query: query);
    return (data['tasks'] as List).map((e) => Task.fromJson(e)).toList();
  }

  Future<Task> createTask(Map<String, dynamic> params) async {
    final data = await _post('/tasks', {'task': params});
    return Task.fromJson(data['task']);
  }

  Future<Task> updateTask(int id, Map<String, dynamic> params) async {
    final data = await _put('/tasks/$id', {'task': params});
    return Task.fromJson(data['task']);
  }

  Future<Task> completeTask(int id) async {
    final data = await _post('/tasks/$id/complete', {});
    return Task.fromJson(data['task']);
  }

  // RSVP
  Future<void> rsvp(int scheduleEntryId, String response, {String? note}) async {
    await _post('/schedule_entries/$scheduleEntryId/participations', {
      'response': response,
      if (note != null) 'note': note,
    });
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({bool? unreadOnly}) async {
    final query = <String, String>{};
    if (unreadOnly == true) query['unread'] = 'true';
    return _get('/notifications', query: query);
  }

  Future<void> markNotificationRead(int id) async {
    await _post('/notifications/$id/mark_read', {});
  }

  Future<void> markAllNotificationsRead() async {
    await _post('/notifications/mark_all_read', {});
  }

  // Users
  Future<List<User>> getUsers() async {
    final data = await _get('/users');
    return (data['users'] as List).map((u) => User.fromJson(u)).toList();
  }

  Future<List<User>> getProfessionals() async {
    final data = await _get('/users/professionals');
    return (data['users'] as List).map((u) => User.fromJson(u)).toList();
  }
}

class ApiException implements Exception {
  final String message;
  final int statusCode;
  ApiException(this.message, this.statusCode);

  @override
  String toString() => message;
}
