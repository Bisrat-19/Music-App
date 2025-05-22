import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/app_routes.dart';
import 'providers/user_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ArifMusicApp());
}

class ArifMusicApp extends StatelessWidget {
  const ArifMusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'ArifMusic',
        debugShowCheckedModeBanner: false,
        theme: appTheme, // Ensure theme is set
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}