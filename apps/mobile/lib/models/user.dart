class User {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'coach' | 'player'
  final String locale;
  final String? phone;
  final String? avatarUrl;

  const User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.locale,
    this.phone,
    this.avatarUrl,
  });

  bool get isCoach => role == 'coach';
  bool get isPlayer => role == 'player';

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['fullName'] as String,
        role: json['role'] as String,
        locale: (json['locale'] as String?) ?? 'tr',
        phone: json['phone'] as String?,
        avatarUrl: json['avatarUrl'] as String?,
      );
}
