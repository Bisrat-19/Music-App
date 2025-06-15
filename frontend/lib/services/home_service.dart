import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

class HomeService {
  String? _token;

  void updateToken(String? token) {
    _token = token;
    print('HomeService: Token updated to: $_token');
  }

  Future<List<Map<String, dynamic>>> fetchReleasedSongs() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs'),
        headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      );
      print('fetchReleasedSongs: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.cast<Map<String, dynamic>>();
      } else {
        print('fetchReleasedSongs failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch songs: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('fetchReleasedSongs error: $e');
      throw Exception('Error fetching songs: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchArtists() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/artists'),
        headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      );
      print('fetchArtists: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> artistsJson = jsonDecode(response.body);
        return artistsJson.cast<Map<String, dynamic>>();
      } else {
        print('fetchArtists failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch artists: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('fetchArtists error: $e');
      throw Exception('Error fetching artists: $e');
    }
  }

  Future<Map<String, dynamic>> fetchArtistById(String artistId) async {
    try {
      print('fetchArtistById: Fetching artist with ID: $artistId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/artists/$artistId'),
        headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      );
      print('fetchArtistById: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final artistJson = jsonDecode(response.body);
        if (artistJson is Map<String, dynamic>) return artistJson;
        throw Exception('Invalid artist data format: $artistJson');
      } else if (response.statusCode == 404) {
        print('fetchArtistById: Artist not found: ${response.statusCode} - ${response.body}');
        throw Exception('Artist not found: ${response.statusCode} - ${response.body}');
      } else {
        print('fetchArtistById failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch artist: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('fetchArtistById error: $e');
      throw Exception('Error fetching artist: $e');
    }
  }

  Future<List<Map<String, dynamic>>> fetchSongsByArtist(String artistId) async {
    try {
      print('fetchSongsByArtist: Fetching songs for artist ID: $artistId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/songs/artist/$artistId'),
        headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      );
      print('fetchSongsByArtist: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final List<dynamic> songsJson = jsonDecode(response.body);
        return songsJson.cast<Map<String, dynamic>>();
      } else {
        print('fetchSongsByArtist failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch songs by artist: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('fetchSongsByArtist error: $e');
      throw Exception('Error fetching songs by artist: $e');
    }
  }

  Future<Map<String, dynamic>> fetchUserById(String userId) async {
    try {
      print('fetchUserById: Fetching user with ID: $userId');
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
      );
      print('fetchUserById: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final userJson = jsonDecode(response.body);
        if (userJson is Map<String, dynamic>) return userJson;
        throw Exception('Invalid user data format: $userJson');
      } else {
        print('fetchUserById failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to fetch user: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('fetchUserById error: $e');
      throw Exception('Error fetching user: $e');
    }
  }

  Future<Map<String, dynamic>> toggleFollow(String userId, String artistId, bool isFollowing) async {
    try {
      print('toggleFollow: Toggling follow - userId: $userId, artistId: $artistId, isFollowing: $isFollowing');
      final url = Uri.parse('$baseUrl/api/users/${isFollowing ? 'unfollow' : 'follow'}');
      final response = isFollowing
          ? await http.delete(
              url,
              headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
              body: jsonEncode({'artistId': artistId, 'userId': userId}),
            )
          : await http.post(
              url,
              headers: _token != null ? {'Authorization': 'Bearer $_token', 'Content-Type': 'application/json'} : {'Content-Type': 'application/json'},
              body: jsonEncode({'artistId': artistId, 'userId': userId}),
            );
      print('toggleFollow: Response status: ${response.statusCode}, Body: ${response.body}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final follower = await fetchUserById(userId);
          final followed = await fetchArtistById(artistId);
          return {
            'follower': follower,
            'followed': followed,
          };
        }
        throw Exception('Invalid response format from toggleFollow: $data');
      } else {
        print('toggleFollow failed: ${response.statusCode} - ${response.body}');
        throw Exception('Failed to toggle follow: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('toggleFollow error: $e');
      throw Exception('Error toggling follow: $e');
    }
  }
}