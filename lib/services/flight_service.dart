import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:skyview_2/models/flight.dart';
import 'package:skyview_2/models/location.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FlightService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String baseUrl = 'http://10.0.2.2:8000';  // For Android emulator
  // static const String baseUrl = 'http://localhost:8000';  // For iOS simulator

  // Get all available locations
  Stream<List<Location>> getLocations() {
    try {
      return _firestore
          .collection('locations')
          .orderBy('city')
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Location.fromJson(doc.data()))
              .toList());
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error fetching locations: $e', null);
      return Stream.value([]);
    }
  }

  // Get popular destinations
  Stream<List<Location>> getPopularDestinations() {
    try {
      return _firestore
          .collection('locations')
          .where('isPopular', isEqualTo: true)
          .orderBy('popularity', descending: true)
          .limit(10)
          .snapshots()
          .map((snapshot) => snapshot.docs
              .map((doc) => Location.fromJson(doc.data()))
              .toList());
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error fetching popular destinations: $e', null);
      return Stream.value([]);
    }
  }

  // Search locations by query
  Future<List<Location>> searchLocations(String query) async {
    try {
      if (query.isEmpty) return [];

      final snapshot = await _firestore
          .collection('locations')
          .where('searchKeywords', arrayContains: query.toLowerCase())
          .limit(10)
          .get();

      return snapshot.docs
          .map((doc) => Location.fromJson(doc.data()))
          .toList();
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error searching locations: $e', null);
      return [];
    }
  }

  // Get flights based on search criteria
  Stream<List<Flight>> searchFlights({
    required String from,
    required String to,
    required DateTime departDate,
    DateTime? returnDate,
    required int passengers,
    required String travelClass,
  }) async* {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flights/search').replace(
          queryParameters: {
            'departure_city': from,
            'arrival_city': to,
            'departure_date': departDate.toIso8601String(),
            if (returnDate != null) 'return_date': returnDate.toIso8601String(),
            'passengers': passengers.toString(),
            'travel_class': travelClass,
            'page': '1',
            'limit': '20',
          },
        ),
        headers: {
          'X-API-Key': 'dev-key',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final flights = data.map((json) => Flight.fromJson(json)).toList();
        yield flights;
      } else {
        ErrorHandler.logError(
          'FlightService',
          'Error searching flights: ${response.statusCode}',
          null,
        );
        yield [];
      }
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error searching flights: $e', null);
      yield [];
    }
  }

  // Get return flights for round trips
  Stream<List<Flight>> getReturnFlights({
    required String from,
    required String to,
    required DateTime returnDate,
    required int passengers,
    required String travelClass,
  }) async* {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flights/search').replace(
          queryParameters: {
            'departure_city': to,
            'arrival_city': from,
            'departure_date': returnDate.toIso8601String(),
            'passengers': passengers.toString(),
            'travel_class': travelClass,
            'page': '1',
            'limit': '20',
          },
        ),
        headers: {
          'X-API-Key': 'dev-key',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final flights = data.map((json) => Flight.fromJson(json)).toList();
        yield flights;
      } else {
        ErrorHandler.logError(
          'FlightService',
          'Error getting return flights: ${response.statusCode}',
          null,
        );
        yield [];
      }
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error getting return flights: $e', null);
      yield [];
    }
  }

  // Update flight availability in real-time
  Future<void> updateFlightAvailability(String flightId, int seatsBooked) async {
    try {
      await _firestore.collection('flights').doc(flightId).update({
        'availableSeats': FieldValue.increment(-seatsBooked),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error updating flight availability: $e', null);
      rethrow;
    }
  }

  // Get real-time price updates
  Stream<double> getFlightPrice(String flightId) {
    try {
      return _firestore
          .collection('flights')
          .doc(flightId)
          .snapshots()
          .map((doc) => doc.data()?['price'] as double? ?? 0.0);
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error getting flight price: $e', null);
      return Stream.value(0.0);
    }
  }

  // Get flight details
  Future<Flight?> getFlightDetails(String flightId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/flights/$flightId'),
        headers: {
          'X-API-Key': 'dev-key',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return Flight.fromJson(data);
      }
      return null;
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error getting flight details: $e', null);
      return null;
    }
  }

  // Get flight status
  Stream<String> getFlightStatus(String flightId) {
    try {
      return _firestore
          .collection('flights')
          .doc(flightId)
          .snapshots()
          .map((doc) => doc.data()?['status'] as String? ?? 'Unknown');
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error getting flight status: $e', null);
      return Stream.value('Unknown');
    }
  }

  // Get flight amenities
  Future<List<String>> getFlightAmenities(String flightId) async {
    try {
      final doc = await _firestore.collection('flights').doc(flightId).get();
      if (!doc.exists) return [];
      return List<String>.from(doc.data()?['amenities'] ?? []);
    } catch (e) {
      ErrorHandler.logError('FlightService', 'Error getting flight amenities: $e', null);
      return [];
    }
  }
} 