import 'dart:convert';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/local_storage_service.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:frontend/config/constants.dart';
import 'dart:io' as io;
import 'package:frontend/services/home_service.dart'; // Import HomeService

class UserProvider with ChangeNotifier {
  UserModel? _user;
  String? _token;
  final LocalStorageService _storageService = LocalStorageService();
  final HomeService _homeService = HomeService(); // Instance of HomeService

  UserModel? get user => _user;
  String? get token => _token;
  String? get role => _user?.role;

  Future<void> initializeUser() async {
    try {
      _token = await _storageService.getToken();
      print('UserProvider: Token loaded: $_token');
      _homeService.updateToken(_token); // Pass token to HomeService
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
    _homeService.updateToken(_token); // Pass token to HomeService
    print('UserProvider: User set: ${_user?.id}, role: ${_user?.role}, token: $_token');
    _storageService.saveUserData(token, userData);
    notifyListeners();
  }

  void clearUser() {
    _user = null;
    _token = null;
    _homeService.updateToken(null); // Clear token in HomeService
    print('UserProvider: User cleared');
    _storageService.clearUserData();
    notifyListeners();
  }

  void logout() {
    clearUser();
    print('UserProvider: Logged out');
  }

  Future<void> updateProfileImage(String userId, dynamic image) async {
    if (_token == null) throw Exception('No token available');
    print('UserProvider: Attempting to update profile image for userId: $userId, token: $_token');

    final url = Uri.parse('$baseUrl/api/users/$userId/profile-image');
    print('UserProvider: Request URL: $url');
    final request = http.MultipartRequest('PUT', url)
      ..headers['Authorization'] = 'Bearer $_token';

    if (image != null) {
      if (image is html.File) {
        print('UserProvider: Handling web file: $image');
        final reader = html.FileReader();
        reader.readAsArrayBuffer(image);
        await reader.onLoad.first;
        final bytes = reader.result as Uint8List;
        String mimeType = 'image/jpeg';
        if (image.type.contains('png')) mimeType = 'image/png';
        request.files.add(http.MultipartFile.fromBytes(
          'profileImage',
          bytes,
          contentType: MediaType('image', mimeType),
          filename: 'profile_image.${mimeType == 'image/png' ? 'png' : 'jpg'}',
        ));
      } else if (image is io.File) {
        print('UserProvider: Adding file: ${image.path}');
        String extension = image.path.split('.').last.toLowerCase();
        String mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          image.path,
          contentType: MediaType('image', mimeType),
        ));
      } else {
        throw Exception('Unsupported image type');
      }
    } else {
      throw Exception('No image selected');
    }

    try {
      print('UserProvider: Sending request...');
      final response = await request.send();
      print('UserProvider: Response status: ${response.statusCode}');
      final responseBody = await response.stream.bytesToString();
      print('UserProvider: Response body: $responseBody');
      final decodedResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        _user = UserModel.fromJson(decodedResponse);
        await _storageService.saveUserData(_token!, decodedResponse);
        print('UserProvider: Profile image updated for user: ${_user?.id}');
        notifyListeners();
      } else {
        throw Exception(decodedResponse['message'] ?? 'Failed to update profile image');
      }
    } catch (e) {
      print('UserProvider: Error updating profile image: $e');
      throw e; // Avoid wrapping the exception
    }
  }

  Future<void> toggleFollow(String artistId, bool isFollowing) async {
    if (_user == null || _token == null) throw Exception('User not logged in');
    try {
      print('UserProvider: Toggling follow for artistId: $artistId, isFollowing: $isFollowing');
      final result = await _homeService.toggleFollow(_user!.id, artistId, isFollowing);
      print('UserProvider: Toggle follow result: $result');
      if (result['follower'] != null && result['follower'] is Map<String, dynamic>) {
        _user = UserModel.fromJson(result['follower']);
        await _storageService.saveUserData(_token!, _user!.toJson());
        print('UserProvider: Follow status updated for user: ${_user?.id}, followingCount: ${_user?.followingCount}');
      } else {
        print('UserProvider: Invalid follower data in result: ${result['follower']}');
        throw Exception('Invalid follower data received');
      }
      notifyListeners();
    } catch (e) {
      print('UserProvider: Error toggling follow: $e');
      throw e; // Avoid wrapping the exception
    }
  }
}