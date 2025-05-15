// lib/services/chat_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:skyview_2/models/chat_message.dart';
import 'package:skyview_2/utils/constants.dart';
import 'package:skyview_2/utils/error_handler.dart';

class ChatService {
  // For Windows development, use this IP address
  // 10.0.2.2 points to the host machine when running in Android emulator
  // Replace with your computer's IP address if testing on a physical device
  final String baseUrl;
  
  ChatService({this.baseUrl = AppConstants.apiBaseUrl});
  
  Future<String> sendMessage(List<ChatMessage> messages) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl${AppConstants.chatEndpoint}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'messages': messages.map((msg) => {
            'content': msg.content,
            'role': msg.type == MessageType.user ? 'user' : 'ai',
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['response'];
      } else {
        ErrorHandler.logError(
          'ChatService', 
          'Failed with status: ${response.statusCode}', 
          null
        );
        return _getFallbackResponse(messages.last.content);
      }
    } on TimeoutException {
      ErrorHandler.logError('ChatService', 'Request timed out', null);
      return 'Sorry, the request timed out. Please try again when you have a better connection.';
    } catch (e, stackTrace) {
      ErrorHandler.logError('ChatService', e, stackTrace);
      return _getFallbackResponse(messages.isNotEmpty ? messages.last.content : '');
    }
  }
  
  String _getFallbackResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('book') && lowerQuery.contains('flight')) {
      return 'To book a flight, you can use the search tab and enter your travel details.';
    } else if (lowerQuery.contains('cancel') || lowerQuery.contains('refund')) {
      return 'For cancellations, go to My Bookings in your profile and select the booking you want to cancel.';
    } else {
      return 'I seem to be having trouble connecting to my knowledge service. You can still use all flight booking features while I work to resolve this.';
    }
  }
  
  Future<bool> isBackendAvailable() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConstants.healthEndpoint}')
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getFlightSuggestions(String query) async {
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConstants.flightSuggestionsEndpoint}?query=$query'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(responseData['suggestions']);
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }
}