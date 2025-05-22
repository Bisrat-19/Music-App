import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';
import '../config/constants.dart';
import '../services/local_storage_service.dart';

class AuthService {
  final LocalStorageService _storage = LocalStorageService();

  Future<Map<String, dynamic>> register(String fullName, String email, String password, String role) async {
    final url = Uri.parse('$baseUrl/api/auth/register');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'fullName': fullName,
        'email': email,
        'password': password,
        'role': role,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);
      await _storage.saveUserData(data['token'], data['user']);
      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Registration failed: ${error['message'] ?? response.body}');
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      await _storage.saveUserData(data['token'], data['user']);
      return {
        'success': true,
        'token': data['token'],
        'user': data['user'],
      };
    } else {
      final error = jsonDecode(response.body);
      throw Exception('Login failed: ${error['message'] ?? response.body}');
    }
  }

  Future<UserModel> getProfile() async {
    final token = await _storage.getToken();
    if (token == null) throw Exception('No token found');

    final response = await http.get(
      Uri.parse('$baseUrl/user/profile'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return UserModel.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to fetch profile: ${response.body}');
    }
  }
}