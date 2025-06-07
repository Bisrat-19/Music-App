import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/services/home_service.dart';
import 'package:frontend/services/library_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'library_screen.dart' as libScreen;
import 'package:frontend/screens/artist/artist_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> with libScreen.RefreshableScreen {
  Future<List<Map<String, dynamic>>>? _fetchSongsFuture;
  Future<List<Map<String, dynamic>>>? _fetchArtistsFuture;
  Future<List<Map<String, dynamic>>>? _fetchWatchlistFuture;
  List<Map<String, dynamic>> _watchlist = [];
  final HomeService _homeService = HomeService();
  final LibraryService _libraryService = LibraryService();
  late AudioPlayer _audioPlayer;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  String? _playlistId;
  Function? _onSongAdded;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFutures();
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map) {
        setState(() {
          _playlistId = args['playlistId'] as String?;
          _onSongAdded = args['onSongAdded'] as Function?;
        });
      }
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

  @override
  Future<void> refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('Refreshing HomeScreen data with token: ${userProvider.token}');
    setState(() {
      _fetchSongsFuture = _homeService.fetchReleasedSongs();
      _fetchArtistsFuture = _homeService.fetchArtists();
      _fetchWatchlistFuture = userProvider.token != null
          ? _libraryService.fetchWatchlist(userProvider.token)
          : Future.value([]);
    });
    await Future.wait([_fetchSongsFuture!, _fetchArtistsFuture!, _fetchWatchlistFuture!]);
    setState(() {
      _isRefreshing = false;
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
      if (!_isPlaying) {
        await _audioPlayer.resume();
      }
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
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.token == null) throw Exception('No token available');
      
      final isInWatchlist = _watchlist.any((song) => song['_id'] == songId);
      
      if (isInWatchlist) {
        await _libraryService.removeFromWatchlist(userProvider.token, songId);
        setState(() {
          _watchlist.removeWhere((song) => song['_id'] == songId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Removed from watchlist')),
        );
      } else {
        await _libraryService.addToWatchlist(userProvider.token, songId);
        final songs = await _fetchSongsFuture;
        final songToAdd = songs?.firstWhere((song) => song['_id'] == songId, orElse: () => {});
        if (songToAdd != null && songToAdd.isNotEmpty) {
          setState(() {
            _watchlist.add(songToAdd);
          });
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Added to watchlist')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addToPlaylist(String playlistId, String songId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    try {
      await _libraryService.addToPlaylist(userProvider.token, playlistId, songId);
      if (_onSongAdded != null) {
        _onSongAdded!();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song added to playlist')),
      );
      if (_playlistId != null) {
        Navigator.pop(context);
      }
    } catch (e) {
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
    if (_playlistId != null) {
      await _addToPlaylist(_playlistId!, songId);
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
          padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                createNew ? 'Create New Playlist' : 'Add to Playlist',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
                    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.green)),
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
                                Navigator.pop(context);
                                await _addToPlaylist(playlist['_id'], songId);
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
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      onPressed: () async {
                        if (createNew) {
                          final name = controller.text.trim();
                          if (name.isNotEmpty) {
                            try {
                              final newPlaylist = await _libraryService.createPlaylist(userProvider.token, name);
                              Navigator.pop(context);
                              await _addToPlaylist(newPlaylist['_id'], songId);
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

    if (_fetchSongsFuture == null || _fetchArtistsFuture == null || _fetchWatchlistFuture == null) {
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
    return FutureBuilder<List<Map<String, dynamic>>>(
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
                    refreshData();
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
            ? songs
            : isNewReleases
                ? songs.reversed.toList()
                : songs;

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchWatchlistFuture!,
          builder: (context, watchlistSnapshot) {
            if (watchlistSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            _watchlist = watchlistSnapshot.data ?? [];
            
            final ScrollController scrollController = ScrollController();

            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: SingleChildScrollView(
                controller: scrollController,
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width,
                  ),
                  child: Row(
                    children: displayedSongs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final song = entry.value;
                      print('Song $index: $song');
                      final audioUrl = '$baseUrl${song['audioPath'] ?? ''}';
                      final isInWatchlist = _watchlist.any((w) => w['_id'] == song['_id']);

                      return Container(
                        width: 120,
                        margin: const EdgeInsets.only(right: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
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
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: Icon(
                                      isInWatchlist ? Icons.favorite : Icons.favorite_border,
                                      color: isInWatchlist ? Colors.red : Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    onPressed: () => _toggleWatchlist(song['_id']),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
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
                                  PopupMenuButton<String>(
                                    icon: Icon(
                                      Icons.more_vert,
                                      color: Theme.of(context).colorScheme.onSurface,
                                      size: 20,
                                    ),
                                    onSelected: (value) {
                                      if (value == 'add_to_playlist') {
                                        _showAddToPlaylistDialog(song['_id']);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'add_to_playlist',
                                        child: Text('Add to Playlist'),
                                      ),
                                    ],
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              song['artistName'] ?? 'Unknown Artist',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _artistList(BuildContext context, Future<List<Map<String, dynamic>>> artistsFuture) {
    final Uint8List placeholderBytes = Uint8List.fromList(List.filled(64 * 64 * 4, 128)); // 64x64 RGBA, grey

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
                      refreshData();
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
          print('Artist data: $artists'); // Log full artist data
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              final imagePath = artist['avatarPath'] ?? artist['profileImagePath']; // Use avatarPath as primary, fallback to profileImagePath
              final imageUrl = imagePath != null ? '$baseUrl$imagePath' : null;
              print('Artist $index: ${artist['fullName']}, imagePath: $imagePath, imageUrl: $imageUrl');

              return MouseRegion(
                cursor: SystemMouseCursors.click, // Changes cursor to a small hand on hover
                child: GestureDetector(
                  onTap: () {
                    if (artist['_id'] != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ArtistDetailScreen(artistId: artist['_id'] as String),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Theme.of(context).colorScheme.surface,
                          child: imageUrl != null
                              ? ClipOval(
                                  child: FadeInImage(
                                    placeholder: MemoryImage(placeholderBytes),
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                    width: 64,
                                    height: 64,
                                    imageErrorBuilder: (context, error, stackTrace) {
                                      print('Image load error for $imageUrl: $error');
                                      return const Icon(Icons.person, color: Colors.white, size: 32);
                                    },
                                  ),
                                )
                              : const Icon(Icons.person, color: Colors.white, size: 32),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          artist['fullName'] ?? 'Unknown',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
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