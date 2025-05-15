import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class AssetService {
  static final AssetService _instance = AssetService._internal();
  factory AssetService() => _instance;
  AssetService._internal();

  final Map<String, dynamic> _cachedAssets = {};
  
  // Preload critical assets
  Future<void> preloadAssets(BuildContext context) async {
    await Future.wait([
      _cacheAsset('assets/animations/plane_loading.json'),
      _cacheAsset('assets/animations/success.json'),
      // Cache most important images
      precacheImage(const AssetImage('assets/images/indigo.png'), context),
      precacheImage(const AssetImage('assets/images/airindia.png'), context),
      precacheImage(const AssetImage('assets/images/spicejet.png'), context),
    ]);
  }
  
  Future<void> _cacheAsset(String path) async {
    try {
      final data = await rootBundle.load(path);
      _cachedAssets[path] = data;
    } catch (e) {
      debugPrint('Failed to cache asset: $path - $e');
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
      }
    }
    
    return missingAssets;
  }
} 