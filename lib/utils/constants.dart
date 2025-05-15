class AppConstants {
  // API Endpoints
  static const String apiBaseUrl = 'http://10.0.2.2:8000';
  static const String chatEndpoint = '/chat';
  static const String healthEndpoint = '/health';
  static const String flightSuggestionsEndpoint = '/flight-suggestions';
  
  // Animation Assets
  static const String planeLoadingAnimation = 'assets/animations/plane_loading.json';
  static const String successAnimation = 'assets/animations/success.json';
  
  // Image Assets
  static const String indigoLogo = 'assets/images/indigo.png';
  static const String airIndiaLogo = 'assets/images/airindia.png';
  static const String spiceJetLogo = 'assets/images/spicejet.png';
  
  // App Settings
  static const int splashScreenDuration = 3; // seconds
  static const int animationDuration = 300; // milliseconds
  
  // Storage Keys
  static const String themePreferenceKey = 'themeMode';
  static const String userTokenKey = 'userToken';
  static const String recentSearchesKey = 'recentSearches';
} 