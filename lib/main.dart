import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:provider/provider.dart';
import 'package:skyview_2/screens/chat/ai_chat_screen.dart';
import 'package:skyview_2/screens/flights/search_screen.dart';
import 'package:skyview_2/screens/profile/profile_screen.dart';
import 'package:skyview_2/screens/splash_screen.dart';
import 'package:skyview_2/theme/app_theme.dart';
import 'package:skyview_2/providers/theme_provider.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/providers/app_state.dart';
import 'package:skyview_2/firebase_options.dart';
import 'package:skyview_2/services/navigation_service.dart';
import 'package:skyview_2/services/api_service.dart';
import 'package:skyview_2/screens/quiz/quiz_screen.dart';
import 'package:skyview_2/screens/feedback/feedback_screen.dart';
import 'package:skyview_2/screens/profile/edit_profile_screen.dart';
import 'package:skyview_2/screens/profile/seat_preference_screen.dart';
import 'package:skyview_2/screens/profile/meal_preference_screen.dart';
import 'package:skyview_2/screens/profile/payment_methods_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialize Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!const bool.fromEnvironment('DEBUG'));
    
    // Pass all uncaught errors to Crashlytics
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterError;
    
    print('Firebase initialized successfully');
  } catch (e) {
    print('Failed to initialize Firebase: $e');
    // Continue without Firebase, app will fallback to local functionality
  }
  
  // Initialize API services
  try {
    await ApiService().initialize();
    print('API services initialized successfully');
  } catch (e) {
    print('Failed to initialize API services: $e');
    // Continue anyway, API services will handle failures gracefully
  }
  
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
          navigatorKey: NavigationService.navigatorKey,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          home: const SplashScreen(),
          routes: {
            '/search': (context) => const SearchScreen(),
            '/chat': (context) => const AIChatScreen(),
            '/profile': (context) => const ProfileScreen(),
            '/quiz': (context) => const QuizScreen(),
            '/feedback': (context) => const FeedbackScreen(),
            '/edit_profile': (context) => const EditProfileScreen(),
            '/seat_preference': (context) => const SeatPreferenceScreen(),
            '/meal_preference': (context) => const MealPreferenceScreen(),
            '/payment_methods': (context) => const PaymentMethodsScreen(),
          },
          builder: (context, child) {
            // Add error handling at the app level
            ErrorWidget.builder = (FlutterErrorDetails details) {
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Something went wrong',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'The app ran into a problem. Please try again.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (_) => const SplashScreen()),
                          );
                        },
                        child: const Text('Restart App'),
                      ),
                    ],
                  ),
                ),
              );
            };
            
            return child!;
          },
        );
      },
    );
  }
}