import 'package:flutter/material.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;
  final SearchService _searchService = SearchService();
  List<Map<String, dynamic>> _searchResults = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_hasQuery) {
      _fetchSearchResults();
    } else {
      setState(() {
        _searchResults = [];
        _errorMessage = '';
      });
    }
  }

  Future<void> _fetchSearchResults() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      final results = await _searchService.search(_searchCtrl.text.trim());
      setState(() {
        _searchResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error fetching results: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false, // no back arrow in tab view
        title: const Text('Search',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 16),
            Expanded(
              child: _hasQuery ? _buildResultsView() : _buildSuggestionsView(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green, width: 1),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: Colors.white70),
          hintText: 'songs, artists...',
          hintStyle: TextStyle(color: Colors.white60),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildSuggestionsView() {
    return ListView.separated(
      itemCount: 4, // Limited to 4 suggestions for simplicity
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final suggestions = ['Song title or name', 'Artist Name', 'teddy afro', 'Aster Aweke'];
        final label = suggestions[index];
        return GestureDetector(
          onTap: () {
            _searchCtrl.text = label;
            _fetchSearchResults();
          },
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
        );
      },
    );
  }

  Widget _buildResultsView() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _errorMessage.isNotEmpty
            ? Center(child: Text(_errorMessage, style: const TextStyle(color: Colors.red)))
            : ListView(
                children: [
                  const Text('Top Results',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  const Text('Songs',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._searchResults
                      .where((result) => result.containsKey('title'))
                      .map((song) => _SongResultTile(song: song)),
                  const SizedBox(height: 24),
                  const Text('Artists',
                      style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ..._searchResults
                      .where((result) => result.containsKey('fullName'))
                      .map((artist) => _ArtistResultTile(artist: artist)),
                ],
              );
  }
}

class _SongResultTile extends StatelessWidget {
  final Map<String, dynamic> song;
  const _SongResultTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network(
          '${song['coverImagePath'] != null ? '$baseUrl${song['coverImagePath']}' : 'https://via.placeholder.com/40x40'}',
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(
            color: Colors.grey[800],
            width: 40,
            height: 40,
          ),
        ),
      ),
      title: Text(song['title'] ?? 'Untitled',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(song['artistName'] ?? 'Unknown Artist',
          style: const TextStyle(color: Colors.white60)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(song['duration'] ?? 'N/A',
              style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 4),
          const Icon(Icons.play_circle_fill, color: Colors.green),
        ],
      ),
      onTap: () {
        // TODO: Navigate to player screen with this song
      },
    );
  }
}

class _ArtistResultTile extends StatelessWidget {
  final Map<String, dynamic> artist;
  const _ArtistResultTile({required this.artist});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          '${artist['avatarPath'] != null ? '$baseUrl${artist['avatarPath']}' : 'https://via.placeholder.com/48x48'}',
        ),
        radius: 24,
        onBackgroundImageError: (_, __) => Container(color: Colors.grey[800]),
      ),
      title: Text(artist['fullName'] ?? 'Unknown Artist',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      onTap: () {
        // TODO: Navigate to artist profile
      },
    );
  }
}