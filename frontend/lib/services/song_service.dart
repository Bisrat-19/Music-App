import 'package:flutter/foundation.dart' show kIsWeb; // Add this import
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
    required PlatformFile audioFile, // Changed to PlatformFile
    PlatformFile? coverImage, // Changed to PlatformFile
  }) async {
    try {
      print('Uploading song: title=$title, genre=$genre, artistId=$artistId');
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/songs/upload'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      print('SongService: Authorization header: Bearer $token');

      request.fields['title'] = title;
      request.fields['genre'] = genre;
      request.fields['description'] = description;
      request.fields['artistId'] = artistId;

      // Handle audio file upload
      if (kIsWeb) {
        // On web, use bytes from PlatformFile
        print('Adding audio file (web): ${audioFile.name}');
        request.files.add(http.MultipartFile.fromBytes(
          'audio',
          audioFile.bytes!,
          filename: audioFile.name,
        ));
      } else {
        // On native platforms, use file path
        print('Adding audio file (native): ${audioFile.path}');
        request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path!));
      }

      // Handle cover image upload (if provided)
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
      } else {
        final responseBody = await response.stream.bytesToString();
        throw Exception('Failed to upload track: ${response.statusCode} - $responseBody');
      }
    } catch (e) {
      print('Upload error: $e');
      throw Exception('$e');
    }
  }
}