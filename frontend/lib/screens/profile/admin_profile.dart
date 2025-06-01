import 'dart:io';
import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/config/constants.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/screens/admin/admin_dashboard_screen.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:html' as html;

class AdminProfile extends StatefulWidget {
  const AdminProfile({super.key});

  @override
  _AdminProfileState createState() => _AdminProfileState();
}

class _AdminProfileState extends State<AdminProfile> {
  dynamic _image;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (html.window.navigator.userAgent.contains('Chrome')) {
        final xhr = html.HttpRequest();
        xhr.open('GET', pickedFile.path, async: true);
        xhr.responseType = 'blob';
        xhr.send();
        await xhr.onLoad.first;
        final blob = xhr.response as html.Blob;
        if (blob == null) {
          print('AdminProfile: Failed to get blob from xhr.response');
          return;
        }
        final webFile = html.File([blob], 'profile_image.jpg', {'type': 'image/jpeg'});
        print('AdminProfile: Created webFile: $webFile, type: ${webFile.runtimeType}');
        setState(() {
          _image = webFile;
        });
      } else {
        setState(() {
          _image = File(pickedFile.path);
        });
      }
    }
  }

  Future<void> _updateProfileImage() async {
    print('AdminProfile: Starting profile image update');
    setState(() {
      _isLoading = true;
    });

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null || userProvider.token == null) {
        throw Exception('User not logged in');
      }
      print('AdminProfile: User ID: ${userProvider.user!.id}, Token: ${userProvider.token}');
      print('AdminProfile: Image to upload: $_image, type: ${_image.runtimeType}');

      await userProvider.updateProfileImage(
        userProvider.user!.id,
        _image,
      );

      setState(() {
        _image = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e) {
      print('AdminProfile: Error updating profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile image: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Black background
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          'Profile',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: Theme.of(context).appBarTheme.elevation,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Profile Picture with Checkmark and Camera Icon
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: const Color(0xFFFF0000), // Red background
                  child: _image != null
                      ? ClipOval(
                          child: _image is html.File
                              ? Image.network(
                                  html.Url.createObjectUrl(_image),
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  _image,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                        )
                      : user?.profileImagePath != null
                          ? ClipOval(
                              child: Image.network(
                                '$baseUrl${user!.profileImagePath}',
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  print('AdminProfile: Error loading image: $error');
                                  return const Icon(
                                    Icons.person,
                                    size: 60,
                                    color: Colors.white,
                                  );
                                },
                              ),
                            )
                          : const Icon(
                              Icons.person,
                              size: 60,
                              color: Colors.white,
                            ),
                ),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1DB954), // Green checkmark background
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: _pickImage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Name
            Text(
              user?.fullName ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            // Role
            Text(
              user?.role.toUpperCase() ?? 'Administrator',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 20),
            // Buttons
            if (_image != null)
              CustomButton(
                text: 'Save Profile Image',
                icon: Icons.save,
                color: const Color(0xFF1DB954),
                isFullWidth: true,
                onPressed: _isLoading ? null : _updateProfileImage,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : null,
              ),
            if (_image != null) const SizedBox(height: 12),
            CustomButton(
              text: 'Admin Dashboard',
              icon: Icons.grid_view,
              color: const Color(0xFF1DB954),
              isFullWidth: true,
              onPressed: () {
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                print('Navigating to Admin Dashboard, role: ${userProvider.role}'); // Debug log
                if (userProvider.role?.toLowerCase() == 'admin') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Access Denied: Admins Only')),
                  );
                }
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Manage Featured Content',
              icon: Icons.star,
              color: const Color(0xFFA100FF), // Purple
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Manage Featured Content feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Edit Profile',
              icon: Icons.edit,
              trailingIcon: Icons.arrow_forward,
              color: const Color(0xFF212121), // Dark gray
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit Profile feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Settings',
              icon: Icons.settings,
              trailingIcon: Icons.arrow_forward,
              color: const Color(0xFF212121), // Dark gray
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Help & Support',
              icon: Icons.help,
              trailingIcon: Icons.arrow_forward,
              color: const Color(0xFF212121), // Dark gray
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Help & Support feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'About',
              icon: Icons.info,
              trailingIcon: Icons.arrow_forward,
              color: const Color(0xFF212121), // Dark gray
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About feature coming soon!')),
                );
              },
            ),
            const SizedBox(height: 24),
            // Logout Button (Functional)
            CustomButton(
              text: 'Logout',
              icon: Icons.logout,
              color: const Color(0xFFFF0000), // Red
              isFullWidth: true,
              onPressed: () async {
                try {
                  print('Logging out...');
                  userProvider.logout(); // Clear user data
                  print('User logged out. Navigating to login screen...');
                  if (!context.mounted) return;
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    AppRoutes.login,
                    (route) => false,
                  );
                } catch (e) {
                  print('Logout error: $e');
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Logout failed: $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}