class AppConstants {
  // Production: set to your Render URL, e.g. 'https://schedulr-api.onrender.com/api/v1'
  // Local dev: 'http://localhost:3000/api/v1'
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://schedulr-api.onrender.com/api/v1',
  );

  static const Map<String, String> entryTypeLabels = {
    'available': 'Available',
    'not_available': 'Not Available',
    'busy': 'Busy',
    'shoot_work_day': 'Shoot / Work Day',
    'travel': 'Travel',
    'personal_block': 'Personal Block',
    'hold': 'Hold',
    'tentative_booking': 'Tentative Booking',
    'confirmed_booking': 'Confirmed Booking',
  };

  static const Map<String, int> entryTypeColors = {
    'available': 0xFF4CAF50,
    'not_available': 0xFFE53935,
    'busy': 0xFFFF9800,
    'shoot_work_day': 0xFF1565C0,
    'travel': 0xFF00838F,
    'personal_block': 0xFF757575,
    'hold': 0xFFFBC02D,
    'tentative_booking': 0xFFAB47BC,
    'confirmed_booking': 0xFF2E7D32,
  };

  static const Map<String, String> taskTypeLabels = {
    'submission_deadline': 'Deadline',
    'preparation_reminder': 'Prep Reminder',
    'follow_up': 'Follow Up',
    'checklist': 'Checklist',
    'general': 'General',
  };

  static const Map<String, int> priorityColors = {
    'low': 0xFF4CAF50,
    'medium': 0xFFFF9800,
    'high': 0xFFF44336,
    'urgent': 0xFF9C27B0,
  };
}
