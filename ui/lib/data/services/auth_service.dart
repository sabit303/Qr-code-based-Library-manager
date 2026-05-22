import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../../core/constants/api_constants.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userKey = 'auth_user';

  Future<UserModel> login(String email, String password, String role) async {
    final response = await http.post(
      Uri.parse(ApiConstants.login),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password, 'role': role}),
    );

    // Handle empty response body
    if (response.body.isEmpty) {
      throw Exception('Empty response from server. Status: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final token = data['token'] as String;
      
      // Decode JWT to get user info
      final parts = token.split('.');
      if (parts.length != 3) throw Exception('Invalid token');
      
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final payloadMap = jsonDecode(payload);

      final user = UserModel(
        id: payloadMap['id'] ?? '',
        username: payloadMap['name'] ?? payloadMap['email'] ?? '',
        role: payloadMap['role'] ?? role,
        registration: payloadMap['registration'],
        token: token,
      );

      await _saveSession(user);
      return user;
    }

    throw Exception(data['msg'] ?? data['message'] ?? 'Login failed (Status: ${response.statusCode})');
  }

  Future<void> _saveSession(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, user.token);
    await prefs.setString(
        _userKey,
        jsonEncode({
          'id': user.id,
          'username': user.username,
          'role': user.role,
          'registration': user.registration,
        }));
  }

  Future<UserModel?> getStoredUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token == null || userJson == null) return null;

    final userData = jsonDecode(userJson) as Map<String, dynamic>;
    return UserModel.fromJson(userData, token);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
