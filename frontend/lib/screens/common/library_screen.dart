import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/services/library_service.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:frontend/config/constants.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  Future<List<Map<String, dynamic>>>? _playlistsFuture;
  Future<List<Map<String, dynamic>>>? _watchlistFuture;
  final LibraryService _libraryService = LibraryService();
  late AudioPlayer _audioPlayer;
  String? _currentAudioUrl;
  bool _isPlaying = false;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _initializeAudioPlayer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeFutures();
    });
  }

  void _initializeFutures() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('Initializing futures with token: ${userProvider.token}');
    setState(() {
      _playlistsFuture = userProvider.token != null
          ? _libraryService.fetchPlaylists(userProvider.token)
          : Future.value([]);
      _watchlistFuture = userProvider.token != null
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
    _tab.dispose();
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

  void _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    print('Refreshing data with token: ${userProvider.token}');
    setState(() {
      _playlistsFuture = userProvider.token != null
          ? _libraryService.fetchPlaylists(userProvider.token)
          : Future.value([]);
      _watchlistFuture = userProvider.token != null
          ? _libraryService.fetchWatchlist(userProvider.token)
          : Future.value([]);
    });
    // Wait for the futures to complete
    await Future.wait([_playlistsFuture!, _watchlistFuture!]);
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_playlistsFuture == null || _watchlistFuture == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Your Library',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tab,
          labelColor: Colors.green,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.green,
          tabs: const [
            Tab(text: 'Playlists'),
            Tab(text: 'Watchlist'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tab,
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _playlistsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error loading playlists: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _refreshData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _emptyPlaylists();
                  }
                  return _playlistList(snapshot.data!);
                },
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _watchlistFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Error loading watchlist: ${snapshot.error}',
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: _refreshData,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return _emptyWatchlist();
                  }
                  return _watchlistList(snapshot.data!);
                },
              ),
            ],
          ),
          if (_isRefreshing)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: _tab.index == 0
          ? FloatingActionButton(
              backgroundColor: Colors.green,
              onPressed: _showCreatePlaylistSheet,
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,
    );
  }

  Widget _emptyPlaylists() {
    return _EmptyState(
      icon: Icons.queue_music,
      message: 'No playlists yet!',
      subText: 'Create your first playlist to organise your favourite music',
      buttonLabel: 'New Playlist',
      onPressed: _showCreatePlaylistSheet,
    );
  }

  Widget _emptyWatchlist() {
    return _EmptyState(
      icon: Icons.library_music,
      message: 'Nothing in Watchlist',
      subText: 'Save songs to listen later',
      buttonLabel: 'Browse songs',
      onPressed: () {
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.mainNav,
          arguments: 1,
        );
      },
    );
  }

  Widget _playlistList(List<Map<String, dynamic>> playlists) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = playlists[i];
        return ListTile(
          leading: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.queue_music, color: Colors.white70),
          ),
          title: Text(p['name'] ?? 'Untitled',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${(p['songs'] as List? ?? []).length} songs',
              style: const TextStyle(color: Colors.white60)),
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onSelected: (value) async {
              if (value == 'delete') {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                try {
                  await _libraryService.deletePlaylist(userProvider.token, p['_id']);
                  _refreshData();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Playlist deleted')),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PlaylistDetailScreen(
                  playlist: p,
                  libraryService: _libraryService,
                  onPlay: _playAudio,
                  onPause: _pauseAudio,
                  isPlaying: _isPlaying,
                  currentAudioUrl: _currentAudioUrl,
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _watchlistList(List<Map<String, dynamic>> watchlist) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: watchlist.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = watchlist[i];
        final audioUrl = '$baseUrl${s['audioPath'] ?? ''}';
        final durationSeconds = s['duration'] as int? ?? 0; // Default to 0 if null
        final durationFormatted = durationSeconds > 0
            ? '${(durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds % 60).toString().padLeft(2, '0')}'
            : 'N/A';

        return ListTile(
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.music_note, color: Colors.white70),
          ),
          title: Text(s['title'] ?? 'Untitled',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(s['artistName'] ?? 'Unknown Artist',
              style: const TextStyle(color: Colors.white60)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(durationFormatted,
                  style: const TextStyle(color: Colors.white60)),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  try {
                    await _libraryService.removeFromWatchlist(userProvider.token, s['_id']);
                    _refreshData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Removed from watchlist')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                },
              ),
            ],
          ),
          onTap: () {
            if (_isPlaying && _currentAudioUrl == audioUrl) {
              _pauseAudio();
            } else {
              _playAudio(audioUrl);
            }
          },
          tileColor: _currentAudioUrl == audioUrl && _isPlaying ? Colors.grey[900] : null,
        );
      },
    );
  }

  void _showCreatePlaylistSheet() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding:
            const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Create Playlist',
                style:
                    TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
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
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        try {
                          await _libraryService.createPlaylist(userProvider.token, name);
                          _refreshData();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Playlist created')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e')),
                          );
                        }
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PlaylistDetailScreen extends StatelessWidget {
  final Map<String, dynamic> playlist;
  final LibraryService libraryService;
  final Function(String) onPlay;
  final Function() onPause;
  final bool isPlaying;
  final String? currentAudioUrl;

  const PlaylistDetailScreen({
    super.key,
    required this.playlist,
    required this.libraryService,
    required this.onPlay,
    required this.onPause,
    required this.isPlaying,
    required this.currentAudioUrl,
  });

  @override
  Widget build(BuildContext context) {
    final songs = (playlist['songs'] as List? ?? []).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(playlist['name'] ?? 'Untitled'),
      ),
      body: songs.isEmpty
          ? const Center(
              child: Text(
                'No songs in this playlist.',
                style: TextStyle(color: Colors.white54),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: songs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = songs[i];
                final audioUrl = '$baseUrl${s['audioPath'] ?? ''}';
                final durationSeconds = s['duration'] as int? ?? 0; // Default to 0 if null
                final durationFormatted = durationSeconds > 0
                    ? '${(durationSeconds ~/ 60).toString().padLeft(2, '0')}:${(durationSeconds % 60).toString().padLeft(2, '0')}'
                    : 'N/A';

                return ListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[800],
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white70),
                  ),
                  title: Text(s['title'] ?? 'Untitled',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600)),
                  subtitle: Text(s['artistName'] ?? 'Unknown Artist',
                      style: const TextStyle(color: Colors.white60)),
                  trailing: Text(durationFormatted,
                      style: const TextStyle(color: Colors.white60)),
                  onTap: () {
                    if (isPlaying && currentAudioUrl == audioUrl) {
                      onPause();
                    } else {
                      onPlay(audioUrl);
                    }
                  },
                  tileColor: currentAudioUrl == audioUrl && isPlaying ? Colors.grey[900] : null,
                );
              },
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subText;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subText,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(48),
            ),
            child: Icon(icon, color: Colors.white70, size: 48),
          ),
          const SizedBox(height: 24),
          Text(message,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 8),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}