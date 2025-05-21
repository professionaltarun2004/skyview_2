// lib/services/chat_service.dart

import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:skyview_2/models/chat_message.dart';
import 'package:skyview_2/utils/constants.dart';
import 'package:skyview_2/utils/error_handler.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint

class ChatService {
  // For Windows development, use this IP address
  // 10.0.2.2 points to the host machine when running in Android emulator
  // Replace with your computer's IP address if testing on a physical device
  final String baseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _geminiApiKey = 'AIzaSyB7t7KatWmliVfyvtoj6BJJIZLLdYtHc-E';
  
  ChatService({this.baseUrl = AppConstants.apiBaseUrl});
  
  Future<String> sendMessage(List<ChatMessage> messages) async {
    debugPrint('ChatService: sendMessage called');
    try {
      // Check connectivity first
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        debugPrint('ChatService: No internet connection');
        return 'No internet connection. Please check your connection and try again.';
      }
      debugPrint('ChatService: Internet connection available');

      // Get user ID if authenticated
      String? userId;
      if (_auth.currentUser != null) {
        userId = _auth.currentUser!.uid;
        debugPrint('ChatService: User authenticated with ID: $userId');
      } else {
        debugPrint('ChatService: User not authenticated');
      }
      
      bool backendFailed = false;
      bool geminiFailed = false;

      // First try the backend API
      debugPrint('ChatService: Attempting backend API call');
      try {
        final url = Uri.parse('$baseUrl${AppConstants.chatEndpoint}');
        final headers = {
          'Content-Type': 'application/json',
          'X-API-Key': 'dev-key',
        };
        final body = jsonEncode({
          'messages': messages.map((msg) => {
            'content': msg.content,
            'role': msg.type == MessageType.user ? 'user' : 'ai',
          }).toList(),
          'user_id': userId,
        });
        debugPrint('ChatService: Backend API URL: $url');
        debugPrint('ChatService: Backend API Headers: $headers');
        debugPrint('ChatService: Backend API Body (partial): ${body.substring(0, body.length > 200 ? 200 : body.length)}...');

        final response = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
        
        debugPrint('ChatService: Backend API Response Status Code: ${response.statusCode}');
        debugPrint('ChatService: Backend API Response Body (partial): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          debugPrint('ChatService: Backend API call successful');
          return responseData['response'];
        } else {
           backendFailed = true;
           ErrorHandler.logError('ChatService', 'Backend API failed with status: ${response.statusCode}', null);
           debugPrint('ChatService: Backend API failed - Status: ${response.statusCode}');
        }
      } catch (e) {
        backendFailed = true;
        ErrorHandler.logError('ChatService', 'Backend API failed: $e', null);
        debugPrint('ChatService: Backend API failed - Exception: $e');
      }
      
      // If backend fails, try Gemini API directly
      if (backendFailed) {
        debugPrint('ChatService: Attempting Gemini API call');
        try {
          final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$_geminiApiKey');
           final headers = {
            'Content-Type': 'application/json',
          };
          final body = jsonEncode({
            'contents': [
              {
                'parts': [
                  {
                    'text': messages.last.content,
                  }
                ],
              }
            ],
            'generationConfig': {
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 1024,
            },
          });
          debugPrint('ChatService: Gemini API URL: $url');
          debugPrint('ChatService: Gemini API Headers: $headers');
          debugPrint('ChatService: Gemini API Body (partial): ${body.substring(0, body.length > 200 ? 200 : body.length)}...');

          final geminiResponse = await http.post(url, headers: headers, body: body).timeout(const Duration(seconds: 15));
          
          debugPrint('ChatService: Gemini API Response Status Code: ${geminiResponse.statusCode}');
          debugPrint('ChatService: Gemini API Response Body (partial): ${geminiResponse.body.substring(0, geminiResponse.body.length > 200 ? 200 : geminiResponse.body.length)}...');

          if (geminiResponse.statusCode == 200) {
            final responseData = jsonDecode(geminiResponse.body);
            debugPrint('ChatService: Gemini API call successful');
            if (responseData['candidates'] != null && 
                responseData['candidates'].isNotEmpty &&
                responseData['candidates'][0]['content'] != null &&
                responseData['candidates'][0]['content']['parts'] != null &&
                responseData['candidates'][0]['content']['parts'].isNotEmpty) {
               debugPrint('ChatService: Gemini API response parsed successfully');
              return responseData['candidates'][0]['content']['parts'][0]['text'];
            }
             debugPrint('ChatService: Gemini API response missing expected data');
             geminiFailed = true;
          } else {
             geminiFailed = true;
             ErrorHandler.logError('ChatService', 'Gemini API failed with status: ${geminiResponse.statusCode}', null);
             debugPrint('ChatService: Gemini API failed - Status: ${geminiResponse.statusCode}');
          }
        } catch (e) {
          geminiFailed = true;
          ErrorHandler.logError('ChatService', 'Gemini API failed: $e', null);
          debugPrint('ChatService: Gemini API failed - Exception: $e');
        }
      }
      
      // If both APIs fail, return fallback response
      if (backendFailed && geminiFailed) {
         debugPrint('ChatService: Both APIs failed, returning fallback response');
         return getFallbackResponse(messages.last.content);
      }
      
      // If for some reason we reach here without returning, return a generic error
      debugPrint('ChatService: Reached end of sendMessage without successful response');
      return 'Sorry, an unexpected error occurred and I could not fetch a response.';
      
    } on TimeoutException {
      ErrorHandler.logError('ChatService', 'Request timed out', null);
      debugPrint('ChatService: Request timed out exception');
      return 'Sorry, the request timed out. Please check your connection and try again.';
    } catch (e, stackTrace) {
      ErrorHandler.logError('ChatService', 'Error sending message: $e', stackTrace);
      debugPrint('ChatService: Caught unexpected error: $e');
      return 'Sorry, an unexpected error occurred. Please try again later.';
    }
  }
  
  String getFallbackResponse(String query) {
     debugPrint('ChatService: getFallbackResponse called');
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('book') && lowerQuery.contains('flight')) {
       debugPrint('ChatService: Falling back to book flight response');
      return 'To book a flight, you can use the search tab and enter your travel details.';
    } else if (lowerQuery.contains('cancel') || lowerQuery.contains('refund')) {
       debugPrint('ChatService: Falling back to cancel/refund response');
      return 'For cancellations, go to My Bookings in your profile and select the booking you want to cancel.';
    } else if (lowerQuery.contains('baggage') || lowerQuery.contains('luggage')) {
       debugPrint('ChatService: Falling back to baggage response');
      return 'Baggage allowance varies by airline and fare class. Usually, economy class allows 15-20kg checked baggage and 7kg hand luggage.';
    } else if (lowerQuery.contains('payment') || lowerQuery.contains('pay')) {
       debugPrint('ChatService: Falling back to payment response');
      return 'We support various payment methods including credit/debit cards, UPI, and net banking. All transactions are secure and encrypted.';
    } else if (lowerQuery.contains('login') || lowerQuery.contains('sign in')) {
       debugPrint('ChatService: Falling back to login response');
      return 'To log in, please go to the Profile tab and enter your registered email and password.';
    } else if (lowerQuery.contains('register') || lowerQuery.contains('sign up')) {
       debugPrint('ChatService: Falling back to register response');
      return 'To create a new account, please go to the Profile tab and select the Register option.';
    } else if (lowerQuery.contains('profile') || lowerQuery.contains('account')) {
       debugPrint('ChatService: Falling back to profile response');
      return 'Your profile contains your personal information, recent bookings, and app settings. You can access it from the Profile tab.';
    } else if (lowerQuery.contains('search') || lowerQuery.contains('find flights')) {
       debugPrint('ChatService: Falling back to search response');
      return 'To find flights, use the Flights tab. Enter your origin, destination, dates, and the number of passengers.';
    } else {
       debugPrint('ChatService: Falling back to generic response');
      return 'I understand you\'re asking about "${query.substring(0, query.length > 50 ? 50 : query.length)}..." I\'m still learning about specific travel topics. Can you try rephrasing your question or ask me about flight bookings, cancellations, baggage allowance, or check-in procedures?';
    }
  }
  
  Future<bool> isBackendAvailable() async {
     debugPrint('ChatService: isBackendAvailable called');
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConstants.healthEndpoint}'),
        headers: {
          'X-API-Key': 'dev-key',
        },
      ).timeout(const Duration(seconds: 5));
       debugPrint('ChatService: isBackendAvailable response status: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      ErrorHandler.logError('ChatService', 'Error checking backend: $e', null);
       debugPrint('ChatService: isBackendAvailable failed: $e');
      return false;
    }
  }
  
  Future<List<Map<String, dynamic>>> getFlightSuggestions(String query) async {
     debugPrint('ChatService: getFlightSuggestions called with query: $query');
    if (query.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl${AppConstants.flightSuggestionsEndpoint}?query=$query'),
        headers: {
          'X-API-Key': 'dev-key',
        },
      ).timeout(const Duration(seconds: 5));
      
       debugPrint('ChatService: getFlightSuggestions response status: ${response.statusCode}');
       debugPrint('ChatService: getFlightSuggestions response body (partial): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
         debugPrint('ChatService: getFlightSuggestions successful');
        return List<Map<String, dynamic>>.from(responseData['suggestions']);
      } else {
        ErrorHandler.logError(
          'ChatService', 
          'Flight suggestions failed with status: ${response.statusCode}', 
          null
        );
         debugPrint('ChatService: getFlightSuggestions failed - Status: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      ErrorHandler.logError('ChatService', 'Error getting flight suggestions: $e', null);
       debugPrint('ChatService: getFlightSuggestions failed - Exception: $e');
      return [];
    }
  }
}