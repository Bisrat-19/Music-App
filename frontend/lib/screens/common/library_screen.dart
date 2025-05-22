import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  // local in‑memory data 
  final List<Map<String, dynamic>> _playlists = []; // start empty
  final List<Map<String, dynamic>> _watchlist = []; // start empty
  

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // ─── UI build 
  @override
  Widget build(BuildContext context) {
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
      body: TabBarView(
        controller: _tab,
        children: [
          _playlists.isEmpty ? _emptyPlaylists() : _playlistList(),
          _watchlist.isEmpty ? _emptyWatchlist() : _watchlistList(),
        ],
      ),
      floatingActionButton: _playlists.isNotEmpty && _tab.index == 0
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

  // ─── Playlist list view ─────────────────────────────────────────────
  Widget _playlistList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final p = _playlists[i];
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
          title: Text(p['name'] as String,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text('${p['count']} songs',
              style: const TextStyle(color: Colors.white60)),
          trailing: const Icon(Icons.more_vert, color: Colors.white54),
          onTap: () {}, // TODO: open detail
        );
      },
    );
  }

  // ─── Watch‑list list view ───────────────────────────────────────────
  Widget _watchlistList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _watchlist.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final s = _watchlist[i];
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
          title: Text(s['title'] as String,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600)),
          subtitle: Text(s['artist'] as String,
              style: const TextStyle(color: Colors.white60)),
          trailing: Text(s['duration'] as String,
              style: const TextStyle(color: Colors.white60)),
          onTap: () {},
        );
      },
    );
  }

  // ─── New‑playlist modal ─────────────────────────────────────────────
  void _showCreatePlaylistSheet() {
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
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        setState(() {
                          _playlists.add({'name': name, 'count': 0});
                        });
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ───────────────────────── reusable empty‑state widget
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
