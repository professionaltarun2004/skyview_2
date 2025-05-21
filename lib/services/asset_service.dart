import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  final Map<String, dynamic> _cachedAssets = {};
  
  // Preload critical assets
  Future<void> preloadAssets(BuildContext context) async {
    try {
      await Future.wait([
        _cacheAsset('assets/animations/success.json'),
        _cacheAsset('assets/animations/plane_loading.json'),
        // Cache most important images
        precacheImage(const AssetImage('assets/images/indigo.png'), context),
        precacheImage(const AssetImage('assets/images/airindia.png'), context),
        precacheImage(const AssetImage('assets/images/spicejet.png'), context),
      ]);
      debugPrint('All assets preloaded successfully');
    } catch (e) {
      debugPrint('Error preloading assets: $e');
      // Continue anyway, don't block app startup due to asset loading issues
    }
  }
  
  Future<void> _cacheAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      _cachedAssets[path] = data;
      debugPrint('Cached asset: $path');
    } catch (e) {
      debugPrint('Failed to cache asset: $path - $e');
      // Don't rethrow, allow the app to continue even if an asset fails to load
    }
  }
  
  ByteData? getCachedAsset(String path) {
    return _cachedAssets[path];
  }

  // Validate if assets exist
  static Future<List<String>> validateAssets(List<String> assetPaths) async {
    List<String> missingAssets = [];
    
    for (final path in assetPaths) {
      try {
        await rootBundle.load(path);
      } catch (e) {
        missingAssets.add(path);
        debugPrint('Missing asset: $path');
      }
    }
    
    return missingAssets;
  }
} 