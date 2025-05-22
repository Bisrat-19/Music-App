import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/constants.dart'; // For BASE_URL

class SongService {
  Future<Map<String, dynamic>> uploadSong({
    required String token,
    required String title,
    required String genre,
    required String description,
    required String artistId,
    required File audioFile,
    File? coverImage,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/songs/upload'),
      );

      // Add headers
      request.headers['Authorization'] = 'Bearer $token';

      // Add metadata
      request.fields['title'] = title;
      request.fields['genre'] = genre;
      request.fields['description'] = description;
      request.fields['artistId'] = artistId;

      // Add audio file
      request.files.add(await http.MultipartFile.fromPath('audio', audioFile.path));

      // Add cover image if provided
      if (coverImage != null) {
        request.files.add(await http.MultipartFile.fromPath('coverImage', coverImage.path));
      }

      // Send request
      final response = await request.send();

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Track uploaded successfully'};
      } else {
        throw Exception('Failed to upload track: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error uploading track: $e');
    }
  }
}