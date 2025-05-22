import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_routes.dart';
import '../../providers/user_provider.dart';
import '../../widgets/custom_button.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.initializeUser();
    if (userProvider.user != null) {
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.mainNav,
        arguments: 3, // Profile tab
      );
    } else {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: IntrinsicHeight(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 56,
                    backgroundColor: Theme.of(context).primaryColor,
                    child: Icon(Icons.music_note, size: 56, color: Theme.of(context).iconTheme.color),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'ArifMusic',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Ethiopian Music Streaming',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 48),
                  CustomButton(
                    text: 'Login',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                  ),
                  const SizedBox(height: 12),
                  CustomButton(
                    text: 'Register',
                    isOutlined: true,
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.register);
                    },
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Provider.of<UserProvider>(context, listen: false).clearUser();
                      Navigator.pushNamed(
                        context,
                        AppRoutes.mainNav,
                        arguments: 0, // Home tab
                      );
                    },
                    child: const Text('Continue as Guest'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}