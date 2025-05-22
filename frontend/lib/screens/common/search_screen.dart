import 'package:flutter/material.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  bool get _hasQuery => _searchCtrl.text.trim().isNotEmpty;

  // ── Dummy data ───────────────────────────────────────────────────────
  final List<Map<String, String>> songs = List.generate(
    3,
    (_) => {
      'title': 'Song Title',
      'artist': 'Artist Name',
      'duration': '3:45',
      'thumb': 'assets/images/song.jpg',
    },
  );

  final List<String> suggestedKeywords = [
    'Song title or name',
    'Artist Name',
    'teddy afro',
    'Aster Aweke',
  ];


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,  // no back arrow in tab view
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
          hintText: 'songs ,artists...',
          hintStyle: TextStyle(color: Colors.white60),
          border: InputBorder.none,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }


  Widget _buildSuggestionsView() {
    return ListView.separated(
      itemCount: suggestedKeywords.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final label = suggestedKeywords[index];
        return GestureDetector(
          onTap: () {
            _searchCtrl.text = label;
            setState(() {});
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
    return ListView(
      children: [
        const Text('Top Results',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        const Text('Songs',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...songs.map((song) => _SongResultTile(song: song)),
        const SizedBox(height: 24),
        const Text('Artists',
            style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const _ArtistResultTile(
          artistName: 'Artist Name',
          avatarPath: 'assets/images/profile.png',
        ),
      ],
    );
  }
}


class _SongResultTile extends StatelessWidget {
  final Map<String, String> song;
  const _SongResultTile({required this.song});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.asset(song['thumb']!,
            width: 40, height: 40, fit: BoxFit.cover),
      ),
      title: Text(song['title']!,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: Text(song['artist']!,
          style: const TextStyle(color: Colors.white60)),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(song['duration']!,
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
  final String artistName;
  final String avatarPath;
  const _ArtistResultTile(
      {required this.artistName, required this.avatarPath});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: AssetImage(avatarPath),
        radius: 24,
      ),
      title: Text(artistName,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      onTap: () {
        // TODO: Navigate to artist profile
      },
    );
  }
}
