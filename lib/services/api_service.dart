import 'package:skyview_2/services/chat_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  
  // Services
  final chatService = ChatService();
  
  // Initialize all services
  Future<void> initialize() async {
    // Add any initialization code here
  }
} 