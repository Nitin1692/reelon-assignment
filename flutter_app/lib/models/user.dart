class User {
  final int id;
  final String email;
  final String name;
  final String role;
  final String? phone;
  final String? timezone;
  final String? avatarUrl;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.phone,
    this.timezone,
    this.avatarUrl,
  });

  bool get isManager => role == 'manager' || role == 'admin';
  bool get isProfessional => role == 'professional';

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      role: json['role'],
      phone: json['phone'],
      timezone: json['timezone'],
      avatarUrl: json['avatar_url'],
    );
  }
}
