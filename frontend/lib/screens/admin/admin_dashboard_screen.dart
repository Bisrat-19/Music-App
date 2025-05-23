import 'package:flutter/material.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  AdminDashboardScreenState createState() => AdminDashboardScreenState();
}

class AdminDashboardScreenState extends State<AdminDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _fetchUsersFuture;
  late Future<List<Map<String, dynamic>>> _fetchSongsFuture;
  late Future<Map<String, dynamic>> _fetchOverviewDataFuture;
  final AdminService _adminService = AdminService();
  bool _isInitialized = false;
  String _userSearchQuery = '';
  String _songSearchQuery = '';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _initializeFutures();
      _isInitialized = true;
    }
  }

  void _initializeFutures() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    print('Initializing futures with token: $token');
    _fetchUsersFuture = _adminService.fetchAllUsers(token);
    _fetchSongsFuture = _adminService.fetchAllSongs(token);
    _fetchOverviewDataFuture = _fetchOverviewData(token);
  }

  Future<Map<String, dynamic>> _fetchOverviewData(String token) async {
    final users = await _fetchUsersFuture;
    final songs = await _fetchSongsFuture;
    final artists = users.where((user) => user['role'] == 'artist').toList();
    final totalListeners = await _adminService.fetchTotalListeners(token);
    return {
      'totalUsers': users.length,
      'totalSongs': songs.length,
      'totalArtists': artists.length,
      'totalListeners': totalListeners,
    };
  }

  Future<void> _deleteUser(String userId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.deleteUser(token, userId);
      setState(() {
        _fetchUsersFuture = _adminService.fetchAllUsers(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete user: $e')),
      );
    }
  }

  Future<void> _deleteSong(String songId) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.deleteSong(token, songId);
      setState(() {
        _fetchSongsFuture = _adminService.fetchAllSongs(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
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

  Future<void> _addUser(String fullName, String email, String role, String password) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.createUser(token, fullName, email, role, password);
      setState(() {
        _fetchUsersFuture = _adminService.fetchAllUsers(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add user: $e')),
      );
    }
  }

  Future<void> _updateUser(String userId, String fullName, String email, String role) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.updateUser(token, userId, fullName, email, role);
      setState(() {
        _fetchUsersFuture = _adminService.fetchAllUsers(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update user: $e')),
      );
    }
  }

  Future<void> _addSong(String title, String genre, String description, String artistId, String audioPath, String coverImagePath) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.createSong(token, title, genre, description, artistId, audioPath, coverImagePath);
      setState(() {
        _fetchSongsFuture = _adminService.fetchAllSongs(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add song: $e')),
      );
    }
  }

  Future<void> _updateSong(String songId, String title, String genre) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.token ?? '';
    try {
      await _adminService.updateSong(token, songId, title, genre);
      setState(() {
        _fetchSongsFuture = _adminService.fetchAllSongs(token);
        _fetchOverviewDataFuture = _fetchOverviewData(token);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Song updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update song: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, userProvider, child) {
        final userRole = userProvider.role?.toLowerCase();
        print('Current user role in dashboard: $userRole');

        if (userRole != 'admin') {
          return Scaffold(
            backgroundColor: const Color(0xFF000000),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Access Denied: Admins Only',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        }

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
                'Admin Dashboard',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
              foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
              elevation: Theme.of(context).appBarTheme.elevation,
              bottom: const TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Users'),
                  Tab(text: 'Songs'),
                ],
                indicatorColor: Color(0xFF1DB954),
                labelColor: Color(0xFF1DB954),
                unselectedLabelColor: Colors.white54,
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: () => _showAddUserDialog(context),
                  tooltip: 'Add User',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  onPressed: () => _showEditUserDialog(context, null),
                  tooltip: 'Edit User',
                ),
                IconButton(
                  icon: const Icon(Icons.music_note, color: Colors.white),
                  onPressed: () => _showAddSongDialog(context),
                  tooltip: 'Add Song',
                ),
              ],
            ),
            body: TabBarView(
              children: [
                // Overview Tab
                FutureBuilder<Map<String, dynamic>>(
                  future: _fetchOverviewDataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error loading overview: ${snapshot.error}',
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    } else if (!snapshot.hasData) {
                      return const Center(
                        child: Text(
                          'No data available.',
                          style: TextStyle(color: Colors.white),
                        ),
                      );
                    }

                    final data = snapshot.data!;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOverviewCard('Total Users', data['totalUsers'].toString()),
                              _buildOverviewCard('Total Songs', data['totalSongs'].toString()),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOverviewCard('Total Artists', data['totalArtists'].toString()),
                              _buildOverviewCard('Total Listeners', data['totalListeners'].toString()),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
                // Users Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Users',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _userSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchUsersFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'Error loading users: ${snapshot.error}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      ElevatedButton(
                                        onPressed: () {
                                          setState(() {
                                            final token = userProvider.token ?? '';
                                            _fetchUsersFuture = _adminService.fetchAllUsers(token);
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
                                    'No users found.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final users = snapshot.data!.where((user) {
                                final fullName = user['fullName']?.toString().toLowerCase() ?? '';
                                final email = user['email']?.toString().toLowerCase() ?? '';
                                final role = user['role']?.toString().toLowerCase() ?? '';
                                return fullName.contains(_userSearchQuery) ||
                                    email.contains(_userSearchQuery) ||
                                    role.contains(_userSearchQuery);
                              }).toList();
                              return constraints.maxWidth < 600
                                  ? ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: users.length,
                                      itemBuilder: (context, index) {
                                        final user = users[index];
                                        return Card(
                                          color: const Color(0xFF212121),
                                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: ListTile(
                                            title: Text(
                                              user['fullName'] ?? 'Unknown',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Email: ${user['email'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                                Text(
                                                  'Role: ${user['role'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.yellow),
                                                  onPressed: () => _showEditUserDialog(context, user),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteUser(user['_id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Name', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Email', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Role', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                                        ],
                                        rows: users.map((user) {
                                          return DataRow(cells: [
                                            DataCell(Text(user['fullName'] ?? 'Unknown', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(user['email'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(user['role'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.yellow),
                                                    onPressed: () => _showEditUserDialog(context, user),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _deleteUser(user['_id']),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                        dataRowColor: MaterialStateProperty.all(const Color(0xFF212121)),
                                        headingRowColor: MaterialStateProperty.all(const Color(0xFF1DB954)),
                                      ),
                                    );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
                // Songs Tab
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Songs',
                          labelStyle: const TextStyle(color: Colors.white70),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                          prefixIcon: const Icon(Icons.search, color: Colors.white70),
                        ),
                        style: const TextStyle(color: Colors.white),
                        onChanged: (value) {
                          setState(() {
                            _songSearchQuery = value.toLowerCase();
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return FutureBuilder<List<Map<String, dynamic>>>(
                            future: _fetchSongsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
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
                                            final token = userProvider.token ?? '';
                                            _fetchSongsFuture = _adminService.fetchAllSongs(token);
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
                                    'No songs found.',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                );
                              }

                              final songs = snapshot.data!.where((song) {
                                final title = song['title']?.toString().toLowerCase() ?? '';
                                final artistName = song['artistName']?.toString().toLowerCase() ?? '';
                                final genre = song['genre']?.toString().toLowerCase() ?? '';
                                return title.contains(_songSearchQuery) ||
                                    artistName.contains(_songSearchQuery) ||
                                    genre.contains(_songSearchQuery);
                              }).toList();
                              return constraints.maxWidth < 600
                                  ? ListView.builder(
                                      padding: const EdgeInsets.all(8.0),
                                      itemCount: songs.length,
                                      itemBuilder: (context, index) {
                                        final song = songs[index];
                                        return Card(
                                          color: const Color(0xFF212121),
                                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                                          child: ListTile(
                                            title: Text(
                                              song['title'] ?? 'Untitled',
                                              style: const TextStyle(color: Colors.white),
                                            ),
                                            subtitle: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Artist: ${song['artistName'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                                Text(
                                                  'Genre: ${song['genre'] ?? 'N/A'}',
                                                  style: const TextStyle(color: Colors.white70),
                                                ),
                                              ],
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.edit, color: Colors.yellow),
                                                  onPressed: () => _showEditSongDialog(context, song),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.delete, color: Colors.red),
                                                  onPressed: () => _deleteSong(song['_id']),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  : SingleChildScrollView(
                                      scrollDirection: Axis.horizontal,
                                      child: DataTable(
                                        columns: const [
                                          DataColumn(label: Text('Title', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Artist Name', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Genre', style: TextStyle(color: Colors.white))),
                                          DataColumn(label: Text('Actions', style: TextStyle(color: Colors.white))),
                                        ],
                                        rows: songs.map((song) {
                                          return DataRow(cells: [
                                            DataCell(Text(song['title'] ?? 'Untitled', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(song['artistName'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
                                            DataCell(Text(song['genre'] ?? 'N/A', style: const TextStyle(color: Colors.white))),
                                            DataCell(
                                              Row(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(Icons.edit, color: Colors.yellow),
                                                    onPressed: () => _showEditSongDialog(context, song),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    onPressed: () => _deleteSong(song['_id']),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ]);
                                        }).toList(),
                                        dataRowColor: MaterialStateProperty.all(const Color(0xFF212121)),
                                        headingRowColor: MaterialStateProperty.all(const Color(0xFF1DB954)),
                                      ),
                                    );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewCard(String title, String value) {
    return Expanded(
      child: Card(
        color: const Color(0xFF212121),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String fullName = '';
    String email = '';
    String role = 'listener';
    String password = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty ? 'Enter full name' : null,
                  onSaved: (value) => fullName = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
                  onSaved: (value) => email = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['listener', 'artist', 'admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      role = newValue!;
                    });
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (value) => value!.isEmpty ? 'Enter password' : null,
                  onSaved: (value) => password = value!,
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _addUser(fullName, email, role, password).then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic>? user) {
    final _formKey = GlobalKey<FormState>();
    String fullName = user?['fullName'] ?? '';
    String email = user?['email'] ?? '';
    String role = user?['role'] ?? 'listener';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit User'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: fullName,
                  decoration: const InputDecoration(labelText: 'Full Name'),
                  validator: (value) => value!.isEmpty ? 'Enter full name' : null,
                  onSaved: (value) => fullName = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: email,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value!.isEmpty || !value.contains('@') ? 'Enter valid email' : null,
                  onSaved: (value) => email = value!,
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: ['listener', 'artist', 'admin'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      role = newValue!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _updateUser(user?['_id'], fullName, email, role).then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showAddSongDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    String title = '';
    String genre = '';
    String description = '';
    String artistId = '';
    String audioPath = '';
    String coverImagePath = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Song'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value!.isEmpty ? 'Enter title' : null,
                  onSaved: (value) => title = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Genre'),
                  validator: (value) => value!.isEmpty ? 'Enter genre' : null,
                  onSaved: (value) => genre = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Description'),
                  onSaved: (value) => description = value ?? '',
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Artist ID'),
                  validator: (value) => value!.isEmpty ? 'Enter artist ID' : null,
                  onSaved: (value) => artistId = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Audio Path'),
                  validator: (value) => value!.isEmpty ? 'Enter audio path' : null,
                  onSaved: (value) => audioPath = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Cover Image Path'),
                  onSaved: (value) => coverImagePath = value ?? '',
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _addSong(title, genre, description, artistId, audioPath, coverImagePath).then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _showEditSongDialog(BuildContext context, Map<String, dynamic>? song) {
    final _formKey = GlobalKey<FormState>();
    String title = song?['title'] ?? '';
    String genre = song?['genre'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Song'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) => value!.isEmpty ? 'Enter title' : null,
                  onSaved: (value) => title = value!,
                ),
                SizedBox(height: 16),
                TextFormField(
                  initialValue: genre,
                  decoration: const InputDecoration(labelText: 'Genre'),
                  validator: (value) => value!.isEmpty ? 'Enter genre' : null,
                  onSaved: (value) => genre = value!,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  _updateSong(song?['_id'], title, genre).then((_) {
                    Navigator.of(context).pop();
                  });
                }
              },
            ),
          ],
        );
      },
    );
  }
}