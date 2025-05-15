import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;

  ThemeProvider() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final savedThemeMode = prefs.getString('themeMode');
    
    if (savedThemeMode != null) {
      _themeMode = savedThemeMode == 'dark' 
          ? ThemeMode.dark 
          : savedThemeMode == 'light'
              ? ThemeMode.light
              : ThemeMode.system;
      notifyListeners();
    }
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeMode == ThemeMode.dark 
          ? 'dark' 
          : themeMode == ThemeMode.light
              ? 'light'
              : 'system',
    );
    
    notifyListeners();
  }
} 