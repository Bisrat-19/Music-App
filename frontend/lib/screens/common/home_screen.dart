import 'package:flutter/material.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:provider/provider.dart';
class HomeScreen extends StatelessWidget {
  final List<String> trending = ["Song 1", "Song 2", "Song 3"];
  final List<String> featuredArtists = ["Rophnan", "Artist 2", "Artist 3"];
  final List<String> newReleases = ["Shegiye", "Release 2", "Release 3"];

  HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personalized Greeting
            if (user != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Text(
                  'Welcome, ${user.fullName}!',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 22),
                ),
              ),
            const SizedBox(height: 16),
            // Discover Banner
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
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Play Featured',
                    onPressed: () {
                      // TODO: Play featured playlist
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomButton(
                    text: 'Explore',
                    isOutlined: true,
                    onPressed: () {
                      // TODO: Explore
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Trending Now'),
            _songList(context, trending),
            const SizedBox(height: 24),
            _sectionTitle(context, 'Featured Artists'),
            _artistList(context, featuredArtists),
            const SizedBox(height: 24),
            _sectionTitle(context, 'New Releases'),
            _songList(context, newReleases),
            const SizedBox(height: 80),
          ],
        ),
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
          onPressed: () {
            // TODO: Navigate to full list
          },
          child: Text(
            'View all',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _songList(BuildContext context, List<String> songs) {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: songs.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to song details
            },
            child: Container(
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
                        child: Image.asset(
                          'assets/images/song.jpg',
                          height: 100,
                          width: 120,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(color: Theme.of(context).colorScheme.surface, height: 100, width: 120),
                        ),
                      ),
                      Icon(
                        Icons.play_circle,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 32,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    songs[index],
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Artist Name',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _artistList(BuildContext context, List<String> artists) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              // TODO: Navigate to artist details
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: const AssetImage('assets/images/profile.png'),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artists[index],
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
      ),
    );
  }
}