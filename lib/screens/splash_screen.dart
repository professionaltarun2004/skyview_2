import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:skyview_2/screens/onboarding_screen.dart';
import 'package:provider/provider.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/screens/home_screen.dart';
import 'package:skyview_2/services/asset_service.dart';
import 'package:skyview_2/utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AssetService _assetService = AssetService();
  bool _assetsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAssetsAndNavigate();
  }

  Future<void> _loadAssetsAndNavigate() async {
    // Preload assets
    await _assetService.preloadAssets(context);
    
    if (!mounted) return;
    setState(() {
      _assetsLoaded = true;
    });
    
    // Wait for animation duration
    await Future.delayed(Duration(seconds: AppConstants.splashScreenDuration));
    
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
            SizedBox(
              width: 200,
              height: 200,
              child: Lottie.asset(
                AppConstants.planeLoadingAnimation,
                frameRate: FrameRate.max,
                errorBuilder: (context, error, stackTrace) {
                  print('Lottie error: $error');
                  return const Icon(
                    Icons.flight_takeoff,
                    size: 80,
                    color: Colors.blue,
                  );
                },
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