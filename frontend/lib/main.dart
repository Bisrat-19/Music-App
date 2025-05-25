import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'config/app_routes.dart';
import 'providers/user_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userProvider = UserProvider();
  await userProvider.initializeUser();
  runApp(ArifMusicApp(userProvider: userProvider));
}

class ArifMusicApp extends StatelessWidget {
  final UserProvider userProvider;

  const ArifMusicApp({super.key, required this.userProvider});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: userProvider),
      ],
      child: MaterialApp(
        title: 'ArifMusic',
        debugShowCheckedModeBanner: false,
        theme: appTheme,
        initialRoute: AppRoutes.welcome,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}