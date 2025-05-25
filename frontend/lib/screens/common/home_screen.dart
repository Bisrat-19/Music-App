import 'dart:async';
import 'package:flutter/material.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/services/home_service.dart';
import 'package:frontend/services/library_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  Future<List<Map<String, dynamic>>>? _fetchSongsFuture;
  Future<List<Map<String, dynamic>>>? _fetchArtistsFuture;
  Future<List<Map<String, dynamic>>>? _fetchWatchlistFuture;
  final HomeService _homeService = HomeService();
  final LibraryService _libraryService = LibraryService();
  late AudioPlayer _audioPlayer;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFutures();
    });
  }

  void _initializeFutures() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('Initializing HomeScreen futures with token: ${userProvider.token}');
    setState(() {
      _fetchSongsFuture = _homeService.fetchReleasedSongs();
      _fetchArtistsFuture = _homeService.fetchArtists();
      _fetchWatchlistFuture = userProvider.token != null
          ? _libraryService.fetchWatchlist(userProvider.token)
          : Future.value([]);
    });
  }

  Future<void> _initializeAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    if (kIsWeb) {
      await Future.delayed(const Duration(milliseconds: 500));
    }
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _playAudio(String audioUrl) async {
    try {
      if (_currentAudioUrl != audioUrl) {
        await _audioPlayer.stop();
        await _audioPlayer.setSourceUrl(audioUrl);
        _currentAudioUrl = audioUrl;
      }
      await _audioPlayer.resume();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  Future<void> _pauseAudio() async {
    await _audioPlayer.pause();
  }

  Future<void> _toggleWatchlist(String songId) async {
    try {
      setState(() {
        _isRefreshing = true;
      });
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.token == null) throw Exception('No token available');
      final watchlist = await _fetchWatchlistFuture!;
      final isInWatchlist = watchlist.any((song) => song['_id'] == songId);
      if (isInWatchlist) {
        await _libraryService.removeFromWatchlist(userProvider.token, songId);
      } else {
        await _libraryService.addToWatchlist(userProvider.token, songId);
      }
      // Refresh the watchlist
      setState(() {
        _fetchWatchlistFuture = _libraryService.fetchWatchlist(userProvider.token);
      });
      await _fetchWatchlistFuture; // Wait for the fetch to complete
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(isInWatchlist
                ? 'Removed from watchlist'
                : 'Added to watchlist')),
      );
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showAddToPlaylistDialog(String songId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to add to playlists')),
      );
      return;
    }
    final playlists = await _libraryService.fetchPlaylists(userProvider.token);
    final controller = TextEditingController();
    bool createNew = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding:
              const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                createNew ? 'Create New Playlist' : 'Add to Playlist',
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              if (createNew)
                TextField(
                  controller: controller,
                  maxLength: 25,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'Playlist name',
                    hintStyle: TextStyle(color: Colors.white54),
                    counterStyle: TextStyle(color: Colors.white54, fontSize: 12),
                    enabledBorder:
                        OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder:
                        OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
                  ),
                )
              else
                playlists.isEmpty
                    ? const Text(
                        'No playlists available. Create one to add this song.',
                        style: TextStyle(color: Colors.white54),
                      )
                    : SizedBox(
                        height: 150,
                        child: ListView.builder(
                          itemCount: playlists.length,
                          itemBuilder: (context, index) {
                            final playlist = playlists[index];
                            return ListTile(
                              title: Text(
                                playlist['name'] ?? 'Untitled',
                                style: const TextStyle(color: Colors.white),
                              ),
                              onTap: () async {
                                try {
                                  await _libraryService.addToPlaylist(
                                      userProvider.token, playlist['_id'], songId);
                                  // Refresh the watchlist in case it's affected
                                  setState(() {
                                    _fetchWatchlistFuture = _libraryService.fetchWatchlist(userProvider.token);
                                  });
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Added to ${playlist['name']}')),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white54,
                          side: const BorderSide(color: Colors.white24)),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green),
                      onPressed: () async {
                        if (createNew) {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            try {
                              final newPlaylist =
                                  await _libraryService.createPlaylist(userProvider.token, name);
                              await _libraryService.addToPlaylist(
                                  userProvider.token, newPlaylist['_id'], songId);
                              // Refresh the watchlist
                              setState(() {
                                _fetchWatchlistFuture = _libraryService.fetchWatchlist(userProvider.token);
                              });
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text('Created and added to $name')),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          }
                        } else {
                          setModalState(() {
                            createNew = true;
                          });
                        }
                      },
                      child: Text(createNew ? 'Create & Add' : 'New Playlist'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

    if (_fetchSongsFuture == null ||
        _fetchArtistsFuture == null ||
        _fetchWatchlistFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Home',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (user != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      'Welcome, ${user.fullName}!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                    ),
                  ),
                const SizedBox(height: 16),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/banner.jpg',
                        width: double.infinity,
                        height: 160,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Theme.of(context).colorScheme.surface, height: 160),
                      ),
                    ),
                    Positioned.fill(
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "Discover Ethiopian Music\nStream the best Ethiopian artists and discover new music from emerging talent",
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 14,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomButton(
                        text: 'Play Featured',
                        onPressed: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomButton(
                        text: 'Explore',
                        isOutlined: true,
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Trending Now'),
                _songList(context, _fetchSongsFuture!, isTrending: true),
                const SizedBox(height: 24),
                _sectionTitle(context, 'Featured Artists'),
                _artistList(context, _fetchArtistsFuture!),
                const SizedBox(height: 24),
                _sectionTitle(context, 'New Releases'),
                _songList(context, _fetchSongsFuture!, isNewReleases: true),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isRefreshing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
        ),
        TextButton(
          onPressed: () {},
          child: Text(
            'View all',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _songList(BuildContext context, Future<List<Map<String, dynamic>>> songsFuture, {bool isTrending = false, bool isNewReleases = false}) {
    return SizedBox(
      height: 180,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: songsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                children: [
                  Text(
                    'Error loading songs: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fetchSongsFuture = _homeService.fetchReleasedSongs();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No songs available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final songs = snapshot.data!;
          final displayedSongs = isTrending
              ? songs.take(3).toList()
              : isNewReleases
                  ? songs.reversed.take(3).toList()
                  : songs;

          return FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchWatchlistFuture!,
            builder: (context, watchlistSnapshot) {
              if (watchlistSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final watchlist = watchlistSnapshot.data ?? [];
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: displayedSongs.length,
                itemBuilder: (context, index) {
                  final song = displayedSongs[index];
                  final audioUrl = '$baseUrl${song['audioPath'] ?? ''}';
                  final isInWatchlist = watchlist.any((w) => w['_id'] == song['_id']);
                  final durationSeconds = (song['duration'] is int)
                      ? song['duration'] as int? ?? 0
                      : 0;
                  final durationFormatted = durationSeconds > 0
                      ? '${(durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds % 60).toString().padLeft(2, '0')}'
                      : 'N/A';

                  return Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                song['coverImagePath'] != null
                                    ? '$baseUrl${song['coverImagePath']}'
                                    : 'https://via.placeholder.com/120x100',
                                height: 100,
                                width: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Theme.of(context).colorScheme.surface,
                                  height: 100,
                                  width: 120,
                                ),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isInWatchlist ? Icons.favorite : Icons.favorite_border,
                                    color: isInWatchlist ? Colors.red : Theme.of(context).colorScheme.onSurface,
                                    size: 24,
                                  ),
                                  onPressed: () => _toggleWatchlist(song['_id']),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.playlist_add,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    size: 24,
                                  ),
                                  onPressed: () => _showAddToPlaylistDialog(song['_id']),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () {
                            if (_isPlaying && _currentAudioUrl == audioUrl) {
                              _pauseAudio();
                            } else {
                              _playAudio(audioUrl);
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                _isPlaying && _currentAudioUrl == audioUrl ? Icons.pause : Icons.play_circle,
                                color: Theme.of(context).colorScheme.onSurface,
                                size: 24,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  song['title'] ?? 'Untitled',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          song['artistName'] ?? 'Unknown Artist',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                        Text(
                          durationFormatted,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _artistList(BuildContext context, Future<List<Map<String, dynamic>>> artistsFuture) {
    return SizedBox(
      height: 110,
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: artistsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                children: [
                  Text(
                    'Error loading artists: ${snapshot.error}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _fetchArtistsFuture = _homeService.fetchArtists();
                      });
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No artists available.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          final artists = snapshot.data!.take(3).toList();
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return GestureDetector(
                onTap: () {},
                child: Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        child: const Icon(Icons.person, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        artist['fullName'] ?? 'Unknown',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '1.5M Followers',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}