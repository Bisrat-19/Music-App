import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';
import '../../services/song_service.dart'; 
import '../../widgets/custom_button.dart';

class ArtistDashboardScreen extends StatefulWidget {
  const ArtistDashboardScreen({super.key});

  @override
  ArtistDashboardScreenState createState() => ArtistDashboardScreenState(); // Updated to public type
}

class ArtistDashboardScreenState extends State<ArtistDashboardScreen> { // Made public
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedGenre;
  File? _audioFile;
  File? _coverImage;
  bool _isLoading = false;

  // SongService instance
  final SongService _songService = SongService();

  // List of music genres for the dropdown
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'flac', 'm4a'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _audioFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'webp'],
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _coverImage = File(result.files.single.path!);
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

      // Reset form
      setState(() {
        _titleController.clear();
        _descriptionController.clear();
        _selectedGenre = null;
        _audioFile = null;
        _coverImage = null;
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
            // Upload Music Tab
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
                    // Genre Dropdown
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
                                      ? _audioFile!.path.split('/').last
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
                            'MP3, WAV, or FLAC up to 50MB',
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
                                      ? _coverImage!.path.split('/').last
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
            // My Music Tab (Placeholder)
            const Center(
              child: Text(
                'My Music coming soon!',
                style: TextStyle(color: Colors.white),
              ),
            ),
            // Analytics Tab (Placeholder)
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