import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  final LocalStorageService _storageService = LocalStorageService();

  UserModel? get user => _user;
  String? get token => _token;

  // Fix the role getter to return the user's role
  String? get role => _user?.role;

  Future<void> initializeUser() async {
    try {
      _token = await _storageService.getToken();
      print('UserProvider: Token loaded: $_token');
      if (_token != null) {
        final userData = await _storageService.getUserData();
        print('UserProvider: User data loaded: $userData');
        _user = UserModel.fromJson(userData);
        print('UserProvider: User initialized: ${_user?.id}, role: ${_user?.role}');
      } else {
        print('UserProvider: No token found, user not initialized');
      }
      notifyListeners();
    } catch (e) {
      print('UserProvider: Error initializing user: $e');
    }
  }

  void setUser(String token, Map<String, dynamic> userData) {
    _token = token;
    _user = UserModel.fromJson(userData);
    print('UserProvider: User set: ${_user?.id}, role: ${_user?.role}, token: $_token');
    _storageService.saveUserData(token, userData);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _token = null;
    print('UserProvider: User cleared');
    _storageService.clearUserData();
    notifyListeners();
  }

  void logout() {
    clearUser();
    print('UserProvider: Logged out');
  }
}