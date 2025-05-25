import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:frontend/config/constants.dart';

class LibraryService {
  Future<List<Map<String, dynamic>>> fetchWatchlist(String? token) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/watchlist');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Fetching watchlist from: $url');
      print('Headers: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final watchlist = data.map((item) {
            final map = Map<String, dynamic>.from(item);
            if (map['duration'] != null && map['duration'] is String) {
              final parts = map['duration'].split(':');
              if (parts.length == 2) {
                final minutes = int.tryParse(parts[0]) ?? 0;
                final seconds = int.tryParse(parts[1]) ?? 0;
                map['duration'] = minutes * 60 + seconds;
              } else {
                map['duration'] = int.tryParse(map['duration']) ?? 0;
              }
            }
            return map;
          }).toList();
          return watchlist;
        } else {
          throw Exception('Unexpected response format: ${data.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch watchlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchWatchlist: $e');
      throw Exception('Error fetching watchlist: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPlaylists(String? token) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/playlists');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Fetching playlists from: $url');
      print('Headers: $headers');

      final response = await http.get(
        url,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception('Unexpected response format: ${data.runtimeType}');
        }
      } else {
        throw Exception('Failed to fetch playlists: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in fetchPlaylists: $e');
      throw Exception('Error fetching playlists: $e');
    }
  }

  Future<Map<String, dynamic>> addToWatchlist(String? token, String songId) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/watchlist');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'songId': songId});
      print('Adding to watchlist at: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to add to watchlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addToWatchlist: $e');
      throw Exception('Error adding to watchlist: $e');
    }
  }

  Future<void> removeFromWatchlist(String? token, String songId) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/watchlist/$songId');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Removing from watchlist at: $url');
      print('Headers: $headers');

      final response = await http.delete(
        url,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to remove from watchlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in removeFromWatchlist: $e');
      throw Exception('Error removing from watchlist: $e');
    }
  }

  Future<Map<String, dynamic>> createPlaylist(String? token, String name) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/playlists');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'name': name});
      print('Creating playlist at: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return Map<String, dynamic>.from(data);
      } else {
        throw Exception('Failed to create playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in createPlaylist: $e');
      throw Exception('Error creating playlist: $e');
    }
  }

  Future<void> addToPlaylist(String? token, String playlistId, String songId) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/playlists/$playlistId/songs');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      final body = jsonEncode({'songId': songId});
      print('Adding to playlist at: $url');
      print('Headers: $headers');
      print('Body: $body');

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to add to playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in addToPlaylist: $e');
      throw Exception('Error adding to playlist: $e');
    }
  }

  Future<void> deletePlaylist(String? token, String playlistId) async {
    try {
      if (token == null) {
        throw Exception('No token available');
      }

      final url = Uri.parse('$baseUrl/api/playlists/$playlistId');
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };
      print('Deleting playlist at: $url');
      print('Headers: $headers');

      final response = await http.delete(
        url,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete playlist: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in deletePlaylist: $e');
      throw Exception('Error deleting playlist: $e');
    }
  }
}