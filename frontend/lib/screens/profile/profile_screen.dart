import 'package:flutter/material.dart';
import 'package:frontend/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:frontend/providers/user_provider.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'listener_profile.dart';
import 'artist_profile.dart';
import 'admin_profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: CustomButton(
            text: 'Log In',
            onPressed: () => Navigator.pushNamed(context, AppRoutes.login),
            isFullWidth: false,
          ),
        ),
      );
    }

    switch (user.role) {
      case 'listener':
        return const ListenerProfile();
      case 'artist':
        return const ArtistProfile();
      case 'admin':
        return const AdminProfile();
      default:
        return const Scaffold(
          body: Center(child: Text('Invalid role')),
        );
    }
  }
}