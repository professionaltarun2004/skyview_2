import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:skyview_2/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/screens/home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => authProvider.isLoggedIn 
            ? const HomeScreen() 
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Since we don't have the actual animation file yet, 
            // we'll leave a placeholder
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                'assets/animations/plane_loading.json',
                frameRate: FrameRate.max,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'SkyView',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'AI-Powered Flight Booking',
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 