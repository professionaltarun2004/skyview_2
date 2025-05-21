import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class MapsService {
  static final MapsService _instance = MapsService._internal();
  factory MapsService() => _instance;
  MapsService._internal();
  
  // Map controller completer
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // Get controller completer
  Completer<GoogleMapController> get controller => _controller;
  
  // Default map styles
  final String _dayMapStyle = '[]'; // Empty style for default
  final String _nightMapStyle = '''
  [
    {
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#242f3e"
        }
      ]
    },
    {
      "featureType": "administrative.locality",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#263c3f"
        }
      ]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#6b9a76"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#38414e"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#212a37"
        }
      ]
    },
    {
      "featureType": "road",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#9ca5b3"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#746855"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#1f2835"
        }
      ]
    },
    {
      "featureType": "road.highway",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#f3d19c"
        }
      ]
    },
    {
      "featureType": "transit",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#2f3948"
        }
      ]
    },
    {
      "featureType": "transit.station",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#d59563"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "geometry",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.fill",
      "stylers": [
        {
          "color": "#515c6d"
        }
      ]
    },
    {
      "featureType": "water",
      "elementType": "labels.text.stroke",
      "stylers": [
        {
          "color": "#17263c"
        }
      ]
    }
  ]
  ''';
  
  // Set map style based on theme
  Future<void> setMapStyle(bool isDarkMode) async {
    try {
      final GoogleMapController mapController = await _controller.future;
      await mapController.setMapStyle(isDarkMode ? _nightMapStyle : _dayMapStyle);
    } catch (e) {
      ErrorHandler.logError('MapsService', 'Error setting map style: $e', null);
    }
  }
  
  // Animate camera to a position
  Future<void> animateToPosition(LatLng position) async {
    try {
      final GoogleMapController mapController = await _controller.future;
      await mapController.animateCamera(CameraUpdate.newLatLng(position));
    } catch (e) {
      ErrorHandler.logError('MapsService', 'Error animating camera: $e', null);
    }
  }
  
  // Fetch airport location from name
  Future<LatLng?> getAirportLocation(String airportName) async {
    try {
      // This is placeholder code - in production, this would connect to a geocoding API
      // or a custom airports database. For now, we'll return mock data.
      
      // Common airports in India (mock data)
      final Map<String, LatLng> commonAirports = {
        'delhi': const LatLng(28.5561, 77.1006),
        'mumbai': const LatLng(19.0896, 72.8656),
        'bangalore': const LatLng(13.1989, 77.7068),
        'chennai': const LatLng(12.9941, 80.1709),
        'kolkata': const LatLng(22.6453, 88.4467),
        'hyderabad': const LatLng(17.2403, 78.4294),
        'kochi': const LatLng(10.1520, 76.3982),
        'ahmedabad': const LatLng(23.0769, 72.6345),
      };
      
      final lowercaseAirport = airportName.toLowerCase();
      for (var airport in commonAirports.keys) {
        if (lowercaseAirport.contains(airport)) {
          return commonAirports[airport];
        }
      }
      
      // If not found in our predefined list
      return null;
    } catch (e) {
      ErrorHandler.logError('MapsService', 'Error getting airport location: $e', null);
      return null;
    }
  }
  
  // Draw flight path between two airports
  List generateFlightPath(LatLng origin, LatLng destination, [int points = 20]) {
    try {
      // Create a curved path between two points (simplified great circle)
      List<LatLng> path = [];
      
      for (int i = 0; i <= points; i++) {
        double fraction = i / points;
        
        // Linear interpolation
        double lat = origin.latitude + fraction * (destination.latitude - origin.latitude);
        double lng = origin.longitude + fraction * (destination.longitude - origin.longitude);
        
        // Add a slight curve by adjusting the latitude
        // This is a simplified approach - actual flight paths use Great Circle calculations
        double curveStrength = 0.2;
        double curve = sin(fraction * 3.14) * curveStrength;
        lat += curve;
        
        path.add(LatLng(lat, lng));
      }
      
      return path;
    } catch (e) {
      ErrorHandler.logError('MapsService', 'Error generating flight path: $e', null);
      return [];
    }
  }
  
  // Dispose the controller
  Future<void> dispose() async {
    if (_controller.isCompleted) {
      final controller = await _controller.future;
      controller.dispose();
    }
  }
  
  // Math sin function
  double sin(double radians) {
    return 0 - radians * (radians * radians / 6.0) + radians;
  }
} 