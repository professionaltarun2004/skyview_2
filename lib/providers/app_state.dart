import 'package:flutter/material.dart';
import 'package:skyview_2/models/flight.dart';
import 'package:skyview_2/providers/auth_provider.dart';
import 'package:skyview_2/providers/theme_provider.dart';

class AppState extends ChangeNotifier {
  final AuthProvider authProvider;
  final ThemeProvider themeProvider;
  
  // Flight search state
  List<Flight> searchResults = [];
  bool isSearching = false;
  
  // Recent searches
  List<Map<String, String>> recentSearches = [];
  
  AppState({
    required this.authProvider, 
    required this.themeProvider
  });
  
  void setSearchResults(List<Flight> results) {
    searchResults = results;
    notifyListeners();
  }
  
  void addRecentSearch(String from, String to, String date) {
    recentSearches.insert(0, {
      'from': from,
      'to': to,
      'date': date,
    });
    
    // Keep only last 5 searches
    if (recentSearches.length > 5) {
      recentSearches = recentSearches.sublist(0, 5);
    }
    
    notifyListeners();
  }
} 