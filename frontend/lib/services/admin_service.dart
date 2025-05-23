import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class AdminService {
  Future<List<Map<String, dynamic>>> fetchAllUsers(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.cast<Map<String, dynamic>>();
      } else {
        print('Fetch users failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch users: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch users error: $e');
      throw Exception('Error fetching users: $e');
    }
  }

  Future<void> createUser(String token, String fullName, String email, String role, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'role': role,
          'password': password,
        }),
      );
      if (response.statusCode != 201) {
        print('Create user failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Create user error: $e');
      throw Exception('Error creating user: $e');
    }
  }

  Future<void> updateUser(String token, String userId, String fullName, String email, String role) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'role': role,
        }),
      );
      if (response.statusCode != 200) {
        print('Update user failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update user error: $e');
      throw Exception('Error updating user: $e');
    }
  }

  Future<void> deleteUser(String token, String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/users/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        print('Delete user failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Delete user error: $e');
      throw Exception('Error deleting user: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllSongs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/songs'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.cast<Map<String, dynamic>>();
      } else {
        print('Fetch songs failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch songs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch songs error: $e');
      throw Exception('Error fetching songs: $e');
    }
  }

  Future<void> createSong(String token, String title, String genre, String description, String artistId, String audioPath, String coverImagePath) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/songs'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'genre': genre,
          'description': description,
          'artistId': artistId,
          'audioPath': audioPath,
          'coverImagePath': coverImagePath,
        }),
      );
      if (response.statusCode != 201) {
        print('Create song failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to create song: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Create song error: $e');
      throw Exception('Error creating song: $e');
    }
  }

  Future<void> updateSong(String token, String songId, String title, String genre) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/songs/$songId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'title': title,
          'genre': genre,
        }),
      );
      if (response.statusCode != 200) {
        print('Update song failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to update song: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Update song error: $e');
      throw Exception('Error updating song: $e');
    }
  }

  Future<void> deleteSong(String token, String songId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/songs/$songId'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode != 200) {
        print('Delete song failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to delete song: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Delete user error: $e');
      throw Exception('Error deleting song: $e');
    }
  }

  Future<int> fetchTotalListeners(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/listeners'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['totalListeners'] as int;
      } else {
        print('Fetch listeners failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch listeners: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch listeners error: $e');
      throw Exception('Error fetching listeners: $e');
    }
  }
}