class UserModel {
  final String id;
  final String username;
  final String role;
  final String? registration;
  final String token;

  UserModel({
    required this.id,
    required this.username,
    required this.role,
    this.registration,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      role: json['role'] ?? 'student',
      registration: json['registration'],
      token: token,
    );
  }

  bool get isLibrarian => role == 'librarian';
  bool get isStudent => role == 'student';
}
