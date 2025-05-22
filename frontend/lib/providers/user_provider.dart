import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/local_storage_service.dart';

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  final LocalStorageService _storageService = LocalStorageService();

  UserModel? get user => _user;
  String? get token => _token;

  Future<void> initializeUser() async {
    _token = await _storageService.getToken();
    if (_token != null) {
      final userData = await _storageService.getUserData();
      _user = UserModel.fromJson(userData);
      notifyListeners();
    }
  }

  void setUser(String token, Map<String, dynamic> userData) {
    _token = token;
    _user = UserModel.fromJson(userData);
    _storageService.saveUserData(token, userData);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _token = null;
    _storageService.clearUserData();
    notifyListeners();
  }

  void logout() {}
}