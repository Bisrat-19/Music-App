import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class SearchService {
  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final songResponse = await http.get(Uri.parse('$baseUrl/api/songs?query=$query'));
      final artistResponse = await http.get(Uri.parse('$baseUrl/api/artists?query=$query'));

      if (songResponse.statusCode == 200 && artistResponse.statusCode == 200) {
        final songs = jsonDecode(songResponse.body) as List<dynamic>;
        final artists = jsonDecode(artistResponse.body) as List<dynamic>;
        return [
          ...songs.cast<Map<String, dynamic>>(),
          ...artists.cast<Map<String, dynamic>>(),
        ];
      } else {
        throw Exception('Failed to fetch search results: ${songResponse.statusCode} - ${artistResponse.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching: $e');
    }
  }
}