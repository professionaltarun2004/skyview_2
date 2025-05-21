import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:skyview_2/services/chat_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Services
  final chatService = ChatService();
  
  // Set this to your backend IP or 10.0.2.2 for Android emulator
  static const String baseUrl = 'http://10.0.2.2:8000';
  
  // Initialize all services
  Future<void> initialize() async {
    // Add any initialization code here
  }

  Future<List<dynamic>> getFlights() async {
    final response = await http.get(Uri.parse('$baseUrl/flights'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load flights');
  }

  Future<Map<String, dynamic>> getFlight(String id) async {
    final response = await http.get(Uri.parse('$baseUrl/flights/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load flight');
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> booking) async {
    final response = await http.post(
      Uri.parse('$baseUrl/bookings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(booking),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to create booking');
  }

  Future<List<dynamic>> getUserBookings(String userId) async {
    final response = await http.get(Uri.parse('$baseUrl/bookings/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load bookings');
  }

  Future<List<dynamic>> getRecommendations([String? userId]) async {
    final url = userId == null
        ? '$baseUrl/recommendations'
        : '$baseUrl/recommendations?user_id=$userId';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['recommendations'];
    }
    throw Exception('Failed to load recommendations');
  }
} 