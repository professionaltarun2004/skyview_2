import 'package:flutter/services.dart';

class AssetValidator {
  static Future<bool> validateAsset(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      print('Asset found: $assetPath');
      return true;
    } catch (e) {
      print('Asset NOT found: $assetPath');
      return false;
    }
  }
  
  static Future<void> validateAllAssets() async {
    // Animations
    await validateAsset('assets/animations/plane_loading.json');
    await validateAsset('assets/animations/success.json');
    
    // Images
    await validateAsset('assets/images/goa.jpg');
    await validateAsset('assets/images/kerala.jpg');
    await validateAsset('assets/images/rajasthan.jpg');
    await validateAsset('assets/images/shimla.jpg');
    await validateAsset('assets/images/indigo.png');
    await validateAsset('assets/images/airindia.png');
    await validateAsset('assets/images/spicejet.png');
  }
} 