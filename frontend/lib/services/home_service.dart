import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class HomeService {
  Future<List<Map<String, dynamic>>> fetchReleasedSongs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs'),
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

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/artists'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> artistsJson = jsonDecode(response.body);
        return artistsJson.cast<Map<String, dynamic>>();
      } else {
        print('Fetch artists failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch artists: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch artists error: $e');
      throw Exception('Error fetching artists: $e');
    }
  }
}