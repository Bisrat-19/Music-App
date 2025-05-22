import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:provider/provider.dart';

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

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
            // Profile Picture with Checkmark
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: const AssetImage('assets/images/profile.png'),
                  backgroundColor: const Color(0xFFFF0000), // Red background
                  foregroundImage: const AssetImage('assets/images/profile.png'),
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
            CustomButton(
              text: 'Admin Dashboard',
              icon: Icons.grid_view,
              color: const Color(0xFF1DB954), // Green
              isFullWidth: true,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Admin Dashboard feature coming soon!')),
                );
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
              icon: Icons.logout, // Added logout icon to match design
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