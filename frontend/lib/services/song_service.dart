import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class SongService {
  Future<Map<String, dynamic>> uploadSong({
    required String token,
    required String title,
    required String genre,
    required String description,
    required String artistId,
    required PlatformFile audioFile,
    PlatformFile? coverImage,
  }) async {
    try {
      print('Uploading song: title=$title, genre=$genre, artistId=$artistId');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/songs/upload'), // Fixed baseUrl to BASE_URL
      );

      request.headers['Authorization'] = 'Bearer $token';
      print('SongService: Authorization header: Bearer $token');

      request.fields['title'] = title;
      request.fields['genre'] = genre;
      request.fields['description'] = description;
      request.fields['artistId'] = artistId;

      if (kIsWeb) {
        print('Adding audio file (web): ${audioFile.name}');
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioFile.bytes!,
          filename: audioFile.name,
        ));
      } else {
        print('Adding audio file (native): ${audioFile.path}');
        request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path!));
      }

      if (coverImage != null) {
        if (kIsWeb) {
          print('Adding cover image (web): ${coverImage.name}');
          request.files.add(http.MultipartFile.fromBytes(
            'coverImage',
            coverImage.bytes!,
            filename: coverImage.name,
          ));
        } else {
          print('Adding cover image (native): ${coverImage.path}');
          request.files.add(await http.MultipartFile.fromPath('coverImage', coverImage.path!));
        }
      }

      final response = await request.send().timeout(const Duration(seconds: 30));
      print('Response status: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Track uploaded successfully'};
      } else if (response.statusCode == 403) {
        throw Exception('Access denied: You must be an artist to upload tracks');
      } else if (response.statusCode == 401) {
        throw Exception('Authentication failed: Please log in again');
      } else if (response.statusCode == 404) {
        throw Exception('Upload endpoint not found. Please check if the backend server is running.');
      } else {
        final responseBody = await response.stream.bytesToString();
        final errorMessage = responseBody.contains('<pre>')
            ? responseBody.split('<pre>')[1].split('</pre>')[0]
            : responseBody;
        throw Exception('Failed to upload track: ${response.statusCode} - $errorMessage');
      }
    } catch (e) {
      print('Upload error: $e');
      throw Exception('$e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchMySongs(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs/my-songs'), // Fixed baseUrl to BASE_URL
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch songs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch songs error: $e');
      throw Exception('Error fetching songs: $e');
    }
  }

  Future<Map<String, dynamic>> updateSongTitle(String token, String songId, String newTitle) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/songs/songs/$songId'), // Fixed path to match backend
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'title': newTitle}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
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
        Uri.parse('$baseUrl/api/songs/songs/$songId'), // Fixed path to match backend
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to delete song: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Delete song error: $e');
      throw Exception('Error deleting song: $e');
    }
  }
}