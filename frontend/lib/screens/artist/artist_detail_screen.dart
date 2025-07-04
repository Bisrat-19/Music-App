import 'package:flutter/material.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/services/home_service.dart';
import 'package:provider/provider.dart';
import 'package:frontend/screens/player/player_screen.dart'; // Import PlayerScreen

class ArtistDetailScreen extends StatefulWidget {
  final String artistId;

  const ArtistDetailScreen({super.key, required this.artistId});

  @override
  _ArtistDetailScreenState createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends State<ArtistDetailScreen> {
  late Future<Map<String, dynamic>> _fetchArtistFuture;
  late Future<List<Map<String, dynamic>>> _fetchSongsFuture;
  final HomeService _homeService = HomeService();
  bool _isFollowing = false;
  int _followerCount = 0;
  int _followingCount = 0;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _homeService.updateToken(userProvider.token);
    _fetchArtistFuture = _homeService.fetchArtistById(widget.artistId);
    _fetchSongsFuture = _homeService.fetchSongsByArtist(widget.artistId);
    _checkFollowStatus();
    print('initState: Initialized with artistId: ${widget.artistId}, token: ${userProvider.token}');
  }

  Future<void> _checkFollowStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user != null) {
      try {
        final user = await _homeService.fetchUserById(userProvider.user!.id);
        final artist = await _homeService.fetchArtistById(widget.artistId);
        print('checkFollowStatus: User data: $user, Artist data: $artist');
        setState(() {
          _isFollowing = (user['following'] as List<dynamic>).contains(widget.artistId);
          _followingCount = user['followingCount'] ?? 0;
          _followerCount = artist['followerCount'] ?? 0;
          print('checkFollowStatus: Updated _isFollowing: $_isFollowing, _followingCount: $_followingCount, _followerCount: $_followerCount');
        });
      } catch (e) {
        print('checkFollowStatus error: $e');
      }
    } else {
      print('checkFollowStatus: No user logged in');
    }
  }

  Future<void> _toggleFollow() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.user?.role == 'listener') {
      try {
        print('toggleFollow: Attempting to toggle for artistId: ${widget.artistId}, current _isFollowing: $_isFollowing');
        await userProvider.toggleFollow(widget.artistId, _isFollowing);
        // Refresh state after toggle
        final updatedUser = await _homeService.fetchUserById(userProvider.user!.id);
        final updatedArtist = await _homeService.fetchArtistById(widget.artistId);
        print('toggleFollow: Updated user: $updatedUser, Updated artist: $updatedArtist');
        setState(() {
          _isFollowing = (updatedUser['following'] as List<dynamic>).contains(widget.artistId);
          _followingCount = updatedUser['followingCount'] ?? _followingCount;
          _followerCount = updatedArtist['followerCount'] ?? _followerCount;
          print('toggleFollow: Updated _isFollowing: $_isFollowing, _followingCount: $_followingCount, _followerCount: $_followerCount');
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isFollowing ? 'You’re now rocking with this artist!' : 'Unfollowed—your rhythm, your rules!'),
          backgroundColor: _isFollowing ? Colors.green : Colors.grey,
        ));
      } catch (e) {
        print('toggleFollow error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Oops, hit a wrong note: $e'),
          backgroundColor: Colors.red,
        ));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Only listeners can follow artists!'),
        backgroundColor: Colors.orange,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Artist Detail',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: _fetchArtistFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  print('FutureBuilder error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 40),
                        const SizedBox(height: 10),
                        Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _fetchArtistFuture = _homeService.fetchArtistById(widget.artistId);
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Center(child: Text('Artist not found.', style: TextStyle(color: Colors.white)));
                }

                final artist = snapshot.data!;
                final imagePath = artist['avatarPath'];
                final imageUrl = imagePath != null ? '$baseUrl$imagePath' : null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[800],
                      child: imageUrl != null
                          ? ClipOval(
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: 80,
                                height: 80,
                                errorBuilder: (context, error, stackTrace) {
                                  print('Image load error for $imageUrl: $error');
                                  return const Icon(Icons.person, color: Colors.white, size: 40);
                                },
                                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                                  if (wasSynchronouslyLoaded) return child;
                                  return AnimatedOpacity(
                                    opacity: frame == null ? 0 : 1,
                                    duration: const Duration(milliseconds: 500),
                                    child: child,
                                    curve: Curves.easeOut,
                                  );
                                },
                              ),
                            )
                          : const Icon(Icons.person, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      artist['fullName'] ?? 'Unknown Artist',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Followers: $_followerCount',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      'Following: $_followingCount',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isFollowing ? Colors.grey : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_isFollowing ? Icons.person_remove : Icons.person_add, size: 20),
                          const SizedBox(width: 8),
                          Text(_isFollowing ? 'Unfollow' : 'Follow the Beat!', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Songs',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSongsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                } else if (snapshot.hasError) {
                  print('Songs FutureBuilder error: ${snapshot.error}');
                  return Center(
                    child: Text('Error loading songs: ${snapshot.error}', style: const TextStyle(color: Colors.white)),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No songs available for this artist.', style: TextStyle(color: Colors.white)));
                }

                final songs = snapshot.data!.where((song) => song['artistId'] == widget.artistId).toList();
                if (songs.isEmpty && snapshot.data!.isNotEmpty) {
                  final artistName = snapshot.data![0]['artistName'];
                  songs.addAll(snapshot.data!.where((song) => song['artistName'] == artistName));
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    final audioUrl = '$baseUrl${song['audioPath'] ?? ''}';
                    final coverImageUrl = song['coverImagePath'] != null ? '$baseUrl${song['coverImagePath']}' : null;
                    final artistName = song['artistName'] ?? 'Unknown Artist';
                    final songTitle = song['title'] ?? 'Untitled';

                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.network(
                            coverImageUrl ?? 'https://via.placeholder.com/40x40',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              print('Song cover load error for ${song['coverImagePath']}: $error');
                              return Container(
                                color: Colors.grey[800],
                                width: 40,
                                height: 40,
                              );
                            },
                          ),
                        ),
                        title: Text(
                          songTitle,
                          style: const TextStyle(color: Colors.white, fontSize: 16),
                        ),
                        subtitle: Text(
                          artistName,
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              song['duration'] ?? 'N/A',
                              style: TextStyle(color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.play_circle, color: Colors.green, size: 20),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PlayerScreen(
                                songUrl: audioUrl,
                                songTitle: songTitle,
                                coverImageUrl: coverImageUrl,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}