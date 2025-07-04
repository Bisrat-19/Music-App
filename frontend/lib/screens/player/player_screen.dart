import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/user_provider.dart';

class PlayerScreen extends StatefulWidget {
  final String songUrl;
  final String songTitle;
  final String? coverImageUrl;

  const PlayerScreen({
    super.key,
    required this.songUrl,
    required this.songTitle,
    this.coverImageUrl,
  });

  @override
  _PlayerScreenState createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0; // Volume control (0.0 to 1.0)

  // Playlist management
  final List<String> _playlistUrls = [];
  final List<String> _playlistTitles = [];
  final List<String?> _playlistCoverUrls = [];
  int _currentIndex = -1;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _loadPlaylist(); // Load playlist first
    _setupPlayer();
  }

  Future<void> _loadPlaylist() async {
    // Initialize with the current song (replace with dynamic playlist from backend)
    setState(() {
      _playlistUrls.add(widget.songUrl);
      _playlistTitles.add(widget.songTitle);
      _playlistCoverUrls.add(widget.coverImageUrl);
      _currentIndex = 0; // Set current index to the loaded song
    });
  }

  Future<void> _setupPlayer() async {
    try {
      if (_currentIndex >= 0 && _currentIndex < _playlistUrls.length) {
        final url = _playlistUrls[_currentIndex];
        if (url.isEmpty || !Uri.parse(url).isAbsolute) {
          throw Exception('Invalid URL: $url');
        }
        await _audioPlayer.setUrl(url);
        _audioPlayer.setVolume(_volume); // Set initial volume
        _audioPlayer.durationStream.listen((duration) {
          if (duration != null && mounted) {
            setState(() {
              _duration = duration;
            });
          }
        }, onError: (error) {
          print('Duration stream error: $error');
        });
        _audioPlayer.positionStream.listen((position) {
          if (mounted) {
            setState(() {
              _position = position;
            });
          }
        }, onError: (error) {
          print('Position stream error: $error');
        });
        if (!_isPlaying) {
          await _audioPlayer.play();
          setState(() {
            _isPlaying = true;
          });
        }
        _audioPlayer.playerStateStream.listen((state) {
          if (mounted) {
            setState(() {
              _isPlaying = state.playing;
            });
          }
        }, onError: (error) {
          print('Player state error: $error');
        });
      }
    } catch (e) {
      print('Error setting up player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error playing song: $e. Check the URL.')),
        );
      }
    }
  }

  void _playNext() {
    if (_currentIndex < _playlistUrls.length - 1) {
      _audioPlayer.stop();
      setState(() {
        _currentIndex++;
        _updatePlayer();
      });
    }
  }

  void _playPrevious() {
    if (_currentIndex > 0) {
      _audioPlayer.stop();
      setState(() {
        _currentIndex--;
        _updatePlayer();
      });
    }
  }

  Future<void> _updatePlayer() async {
    if (_currentIndex >= 0 && _currentIndex < _playlistUrls.length) {
      final url = _playlistUrls[_currentIndex];
      if (url.isEmpty || !Uri.parse(url).isAbsolute) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Invalid URL for next/previous song.')),
          );
        }
        return;
      }
      await _audioPlayer.setUrl(url);
      _audioPlayer.setVolume(_volume);
      await _audioPlayer.play();
      setState(() {
        _isPlaying = true;
      });
    }
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume.clamp(0.0, 1.0);
      _audioPlayer.setVolume(_volume);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(_currentIndex >= 0 && _currentIndex < _playlistTitles.length
            ? _playlistTitles[_currentIndex]
            : widget.songTitle),
        backgroundColor: const Color(0xFF1DB954),
      ),
      body: SingleChildScrollView( // Added to prevent overflow
        child: Column(
          children: [
            // Cover Image Section with Gap
            Padding(
              padding: const EdgeInsets.all(16.0), // Gap on all four sides
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: _currentIndex >= 0 && _currentIndex < _playlistCoverUrls.length && _playlistCoverUrls[_currentIndex] != null
                      ? DecorationImage(
                          image: NetworkImage(_playlistCoverUrls[_currentIndex]!),
                          fit: BoxFit.cover,
                          colorFilter: ColorFilter.mode(
                            Colors.black.withOpacity(0.3),
                            BlendMode.darken,
                          ),
                        )
                      : (widget.coverImageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(widget.coverImageUrl!),
                              fit: BoxFit.cover,
                              colorFilter: ColorFilter.mode(
                                Colors.black.withOpacity(0.3),
                                BlendMode.darken,
                              ),
                            )
                          : null),
                  color: _playlistCoverUrls[_currentIndex] == null && widget.coverImageUrl == null
                      ? const Color(0xFF212121)
                      : null,
                ),
                child: (_playlistCoverUrls[_currentIndex] == null && widget.coverImageUrl == null)
                    ? const Icon(Icons.music_note, size: 100, color: Colors.white)
                    : null,
              ),
            ),
            // Controls Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min, // Prevent overflow
                children: [
                  Text(
                    _currentIndex >= 0 && _currentIndex < _playlistTitles.length
                        ? _playlistTitles[_currentIndex]
                        : widget.songTitle,
                    style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Artist Name', // Replace with dynamic artist name if available
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  // Progress Bar
                  Slider(
                    value: _position.inSeconds.toDouble(),
                    max: _duration.inSeconds.toDouble() > 0 ? _duration.inSeconds.toDouble() : 1.0, // Prevent division by zero
                    onChanged: (value) async {
                      final newPosition = Duration(seconds: value.toInt());
                      await _audioPlayer.seek(newPosition);
                    },
                    activeColor: const Color(0xFF1DB954),
                    inactiveColor: Colors.grey,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(_position), style: const TextStyle(color: Colors.white)),
                        Text(_formatDuration(_duration), style: const TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Playback Controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40),
                        onPressed: _playPrevious,
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: Icon(
                          _isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 60,
                          color: const Color(0xFF1DB954),
                        ),
                        onPressed: () async {
                          if (_isPlaying) {
                            await _audioPlayer.pause();
                          } else {
                            await _audioPlayer.play();
                          }
                          setState(() {
                            _isPlaying = !_isPlaying;
                          });
                        },
                      ),
                      const SizedBox(width: 20),
                      IconButton(
                        icon: const Icon(Icons.skip_next, color: Colors.white, size: 40),
                        onPressed: _playNext,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Volume Control
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.volume_up, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 150,
                        child: Slider(
                          value: _volume,
                          max: 1.0,
                          min: 0.0,
                          onChanged: _setVolume,
                          activeColor: const Color(0xFF1DB954),
                          inactiveColor: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}