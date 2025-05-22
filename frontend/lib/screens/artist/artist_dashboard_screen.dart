import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:frontend/config/constants.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../../providers/user_provider.dart';
import '../../services/song_service.dart';
import '../../widgets/custom_button.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  ArtistDashboardScreenState createState() => ArtistDashboardScreenState();
}

class ArtistDashboardScreenState extends State<ArtistDashboardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGenre;
  PlatformFile? _audioFile;
  PlatformFile? _coverImage;
  bool _isLoading = false;
  late Future<List<Map<String, dynamic>>> _fetchSongsFuture;

  final SongService _songService = SongService();
  static const List<String> musicGenres = [
    'Pop',
    'Rock',
    'Hip Hop',
    'Jazz',
    'Classical',
    'Electronic',
    'R&B',
    'Country',
    'Reggae',
    'Metal',
    'Other',
  ];

  // Audio player state
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentPlayingSongId;

  @override
  void initState() {
    super.initState();
    _fetchSongsFuture = _fetchSongs();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchSongs() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    return _songService.fetchMySongs(token);
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'm4a'],
      allowMultiple: false,
      withData: true, // Required for web
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.single;
      final fileSize = platformFile.size; // Size in bytes
      const maxSize = 50 * 1024 * 1024; // 50MB in bytes

      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Audio file must be less than 50MB')),
        );
        return;
      }

      setState(() {
        _audioFile = platformFile;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'webp'],
      allowMultiple: false,
      withData: true, // Required for web
    );

    if (result != null && result.files.isNotEmpty) {
      final platformFile = result.files.single;
      final fileSize = platformFile.size; // Size in bytes
      const maxSize = 5 * 1024 * 1024; // 5MB in bytes

      if (fileSize > maxSize) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cover image must be less than 5MB')),
        );
        return;
      }

      setState(() {
        _coverImage = platformFile;
      });
    }
  }

  Future<void> _uploadTrack() async {
    if (!_formKey.currentState!.validate()) return;

    if (_audioFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an audio file')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final artistId = userProvider.user?.id ?? '';
    final token = userProvider.token ?? '';

    try {
      await _songService.uploadSong(
        token: token,
        title: _titleController.text,
        genre: _selectedGenre ?? musicGenres[0],
        description: _descriptionController.text,
        artistId: artistId,
        audioFile: _audioFile!,
        coverImage: _coverImage,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Track uploaded successfully')),
      );

      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _selectedGenre = null;
        _audioFile = null;
        _coverImage = null;
        _fetchSongsFuture = _fetchSongs(); // Refresh the song list after upload
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _playSong(String songId, String audioUrl) async {
    try {
      if (_currentPlayingSongId == songId) {
        // If the same song is playing, pause it
        await _audioPlayer.pause();
        setState(() {
          _currentPlayingSongId = null;
        });
      } else {
        // Stop any currently playing song
        await _audioPlayer.stop();
        // Play the new song
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
        setState(() {
          _currentPlayingSongId = songId;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to play song: $e')),
      );
    }
  }

  Future<void> _editSongTitle(String songId, String currentTitle) async {
    final newTitleController = TextEditingController(text: currentTitle);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Edit Song Title', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: newTitleController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Enter new title',
            hintStyle: TextStyle(color: Colors.white70),
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.white54),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF1DB954)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, newTitleController.text),
            child: const Text('Save', style: TextStyle(color: Color(0xFF1DB954))),
          ),
        ],
      ),
    );

    if (newTitle != null && newTitle.isNotEmpty && newTitle != currentTitle) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await _songService.updateSongTitle(userProvider.token ?? '', songId, newTitle);
        setState(() {
          _fetchSongsFuture = _fetchSongs(); // Refresh the song list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song title updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update title: $e')),
        );
      }
    }
  }

  Future<void> _deleteSong(String songId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: const Text('Delete Song', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to delete this song?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await _songService.deleteSong(userProvider.token ?? '', songId);
        setState(() {
          _fetchSongsFuture = _fetchSongs(); // Refresh the song list
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Song deleted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete song: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'Artist Dashboard',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: Theme.of(context).appBarTheme.elevation,
          bottom: TabBar(
            tabs: const [
              Tab(text: 'Upload Music'),
              Tab(text: 'My Music'),
              Tab(text: 'Analytics'),
            ],
            indicatorColor: const Color(0xFF1DB954),
            labelColor: const Color(0xFF1DB954),
            unselectedLabelColor: Colors.white54,
          ),
        ),
        body: TabBarView(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Upload Music',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Track Title',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1DB954)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter a track title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedGenre,
                      decoration: const InputDecoration(
                        labelText: 'Genre',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1DB954)),
                        ),
                      ),
                      dropdownColor: const Color(0xFF212121),
                      style: const TextStyle(color: Colors.white),
                      items: musicGenres.map((genre) {
                        return DropdownMenuItem<String>(
                          value: genre,
                          child: Text(genre),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGenre = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a genre';
                        }
                        return null;
                      },
                      hint: const Text(
                        'Select a genre',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        labelStyle: TextStyle(color: Colors.white70),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.white54),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF1DB954)),
                        ),
                      ),
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Audio File',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _audioFile != null
                                      ? _audioFile!.name
                                      : 'Drag and drop your audio file here or click to browse',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.upload, color: Colors.white70),
                                onPressed: _pickAudioFile,
                              ),
                            ],
                          ),
                          Text(
                            'MP3, WAV, FLAC, or M4A up to 50MB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Cover Image',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Text(
                                  _coverImage != null
                                      ? _coverImage!.name
                                      : 'Drag and drop your image file here or click to browse',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: Colors.white70,
                                      ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.upload, color: Colors.white70),
                                onPressed: _pickCoverImage,
                              ),
                            ],
                          ),
                          Text(
                            'JPG, PNG, or WEBP up to 5MB',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.white70,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: _isLoading
                          ? const CircularProgressIndicator()
                          : CustomButton(
                              text: 'Upload Track',
                              color: const Color(0xFF1DB954),
                              isFullWidth: true,
                              onPressed: _uploadTrack,
                            ),
                    ),
                  ],
                ),
              ),
            ),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchSongsFuture,
              builder: (context, snapshot) {
                print('FutureBuilder state: ${snapshot.connectionState}');
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  print('Fetch songs error: ${snapshot.error}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading songs: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _fetchSongsFuture = _fetchSongs();
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
                      'No songs uploaded yet.',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final songs = snapshot.data!;
                print('Songs fetched: ${songs.length}');
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                  itemCount: songs.length,
                  itemBuilder: (context, index) {
                    final song = songs[index];
                    print('Rendering song: ${song['title']} - Cover: ${song['coverImagePath']}');
                    final isPlaying = _currentPlayingSongId == song['_id'];
                    return Card(
                      color: const Color(0xFF212121),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        leading: song['coverImagePath'] != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(5),
                                child: Image.network(
                                  '$baseUrl${song['coverImagePath']}', // Corrected string interpolation
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    print('Failed to load image for ${song['title']}: $error');
                                    return const Icon(
                                      Icons.image_not_supported,
                                      color: Colors.white70,
                                      size: 50,
                                    );
                                  },
                                ),
                              )
                            : const Icon(
                                Icons.music_note,
                                color: Colors.white70,
                                size: 50,
                              ),
                        title: Text(
                          song['title'] ?? 'Untitled',
                          style: const TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          'Genre: ${song['genre'] ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.white70),
                              onPressed: () => _editSongTitle(song['_id'], song['title']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSong(song['_id']),
                            ),
                            IconButton(
                              icon: Icon(
                                isPlaying ? Icons.pause : Icons.play_arrow,
                                color: isPlaying ? const Color(0xFF1DB954) : Colors.white70,
                              ),
                              onPressed: () => _playSong(song['_id'], '$baseUrl${song['audioPath']}'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const Center(
              child: Text(
                'Analytics coming soon!',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}