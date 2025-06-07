import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class HomeService {
  Future<List<Map<String, dynamic>>> fetchReleasedSongs() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/songs'));
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
      final response = await http.get(Uri.parse('$baseUrl/api/artists'));
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

  Future<Map<String, dynamic>> fetchArtistById(String artistId) async {
    try {
      print('Fetching artist with ID: $artistId');
      final response = await http.get(Uri.parse('$baseUrl/api/artists/$artistId'));
      if (response.statusCode == 200) {
        final artistJson = jsonDecode(response.body);
        return artistJson as Map<String, dynamic>;
      } else if (response.statusCode == 404) {
        print('Artist not found: ${response.statusCode} - ${response.body}');
        throw Exception('Artist not found: ${response.statusCode} - ${response.body}');
      } else {
        print('Fetch artist by ID failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch artist: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch artist by ID error: $e');
      throw Exception('Error fetching artist: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSongsByArtist(String artistId) async {
    try {
      print('Fetching songs for artist ID: $artistId');
      final response = await http.get(Uri.parse('$baseUrl/api/songs/artist/$artistId')); // Updated endpoint
      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.cast<Map<String, dynamic>>();
      } else {
        print('Fetch songs by artist failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch songs by artist: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Fetch songs by artist error: $e');
      throw Exception('Error fetching songs by artist: $e');
    }
  }
}