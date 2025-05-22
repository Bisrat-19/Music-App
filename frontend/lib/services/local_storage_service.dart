import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalStorageService {
  final _storage = FlutterSecureStorage();

  Future<void> saveUserData(String token, Map<String, dynamic> user) async {
    await _storage.write(key: 'jwt_token', value: token);
    await _storage.write(key: 'user_id', value: user['_id']);
    await _storage.write(key: 'user_fullName', value: user['fullName'] ?? '');
    await _storage.write(key: 'user_email', value: user['email'] ?? '');
    await _storage.write(key: 'user_role', value: user['role'] ?? '');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, dynamic>> getUserData() async {
    return {
      '_id': await _storage.read(key: 'user_id') ?? '',
      'fullName': await _storage.read(key: 'user_fullName') ?? '',
      'email': await _storage.read(key: 'user_email') ?? '',
      'role': await _storage.read(key: 'user_role') ?? '',
    };
  }

  Future<void> clearUserData() async {
    await _storage.deleteAll();
  }
}