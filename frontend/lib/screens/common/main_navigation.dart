import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'search_screen.dart';
import 'library_screen.dart' as libScreen; 
import '../profile/profile_screen.dart';

class MainNavigation extends StatefulWidget {
  final int initialIndex;
  const MainNavigation({super.key, this.initialIndex = 0});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex;
  final GlobalKey<State<HomeScreen>> _homeScreenKey = GlobalKey<State<HomeScreen>>();
  final GlobalKey<State<libScreen.LibraryScreen>> _libraryScreenKey = GlobalKey<State<libScreen.LibraryScreen>>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  List<Widget> _buildTabs() {
    return [
      HomeScreen(key: _homeScreenKey),
      const SearchScreen(),
      libScreen.LibraryScreen(key: _libraryScreenKey),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: IndexedStack(index: _currentIndex, children: _buildTabs()),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) async {
          setState(() {
            _currentIndex = i;
          });
          // When the Home tab is selected, trigger a refresh
          if (i == 0) {
            final homeState = _homeScreenKey.currentState as libScreen.RefreshableScreen?;
            await homeState?.refreshData();
          }
          // When the Library tab is selected, trigger a refresh
          if (i == 2) {
            final libraryState = _libraryScreenKey.currentState as libScreen.RefreshableScreen?;
            await libraryState?.refreshData();
          }
        },
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Theme.of(context).unselectedWidgetColor,
        backgroundColor: Theme.of(context).bottomNavigationBarTheme.backgroundColor,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}