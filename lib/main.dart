import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:skyview_2/screens/chat/ai_chat_screen.dart';
import 'package:skyview_2/screens/flights/search_screen.dart';
import 'package:skyview_2/screens/profile/profile_screen.dart';
import 'package:skyview_2/screens/splash_screen.dart';
import 'package:skyview_2/theme/app_theme.dart';
import 'package:skyview_2/providers/theme_provider.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/firebase_options.dart';
import 'package:skyview_2/providers/app_state.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(
          create: (context) => AppState(
            authProvider: Provider.of<AuthProvider>(context, listen: false),
            themeProvider: Provider.of<ThemeProvider>(context, listen: false),
          ),
        ),
      ],
      child: const SkyViewApp(),
    ),
  );
}

class SkyViewApp extends StatelessWidget {
  const SkyViewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return MaterialApp(
          title: 'SkyView',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/search': (context) => const SearchScreen(),
            '/chat': (context) => const AIChatScreen(),
            '/profile': (context) => const ProfileScreen(),
          },
        );
      },
    );
  }
}
