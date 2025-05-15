import 'package:flutter/material.dart';
import 'package:skyview_2/models/chat_message.dart';
import 'package:skyview_2/services/voice_service.dart';
import 'package:skyview_2/widgets/snap_card.dart';
import 'package:intl/intl.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    
    // Add initial greeting message
    _addMessage(
      'Hi there! I\'m your SkyView AI Assistant. I can help you with flight bookings, travel tips, or answer any questions about your journey. How can I assist you today?',
      MessageType.ai,
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addMessage(String content, MessageType type) {
    setState(() {
      _messages.add(
        ChatMessage(
          content: content,
          type: type,
        ),
      );
    });
    
    // Scroll to bottom after message is added
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    
    _messageController.clear();
    _addMessage(message, MessageType.user);
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // TODO: Replace with actual API call to Gemini
      await Future.delayed(const Duration(seconds: 2));
      
      // Mock response based on user query
      final response = _getMockResponse(message);
      
      _addMessage(response, MessageType.ai);
    } catch (e) {
      _addMessage(
        'Sorry, I encountered an error while processing your request. Please try again.',
        MessageType.ai,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getMockResponse(String query) {
    final lowerQuery = query.toLowerCase();
    
    if (lowerQuery.contains('book') && lowerQuery.contains('flight')) {
      return 'To book a flight, head to the Flights tab and enter your origin, destination, dates, and passenger details. You can also specify any preferences like class type. Need help with anything specific about the booking process?';
    } else if (lowerQuery.contains('cancel') || lowerQuery.contains('refund')) {
      return 'For cancellations and refunds, go to the Profile tab and select My Bookings. Select the booking you want to cancel and follow the cancellation steps. Refund policies vary based on the airline and fare type, but you\'ll see the applicable refund amount before confirming.';
    } else if (lowerQuery.contains('baggage') || lowerQuery.contains('luggage')) {
      return 'Baggage allowance depends on the airline and fare class. Generally, Economy allows 15-20kg checked baggage, while Business/First offer 30-40kg. Most airlines permit 7-8kg carry-on luggage. You can view specific allowances for your booking in the flight details page.';
    } else if (lowerQuery.contains('meal') || lowerQuery.contains('food')) {
      return 'Most airlines offer complimentary meals on flights over 2 hours. Special dietary requirements (vegetarian, vegan, kosher, etc.) can be requested during booking or by contacting the airline at least 24 hours before departure. Some budget carriers may charge for meals, which you can pre-book or purchase onboard.';
    } else if (lowerQuery.contains('check-in') || lowerQuery.contains('boarding')) {
      return 'Online check-in typically opens 24-48 hours before departure and closes 1-3 hours before, depending on the airline. I recommend checking in online to choose your seat and save time at the airport. For boarding, arrive at the gate at least 30 minutes before departure time.';
    } else if (lowerQuery.contains('hello') || lowerQuery.contains('hi')) {
      return 'Hello! How can I help you with your travel plans today?';
    } else {
      return 'I understand you\'re asking about "${query.substring(0, min(query.length, 50))}..." I\'m still learning about specific travel topics. Can you try rephrasing your question or ask me about flight bookings, cancellations, baggage allowance, or check-in procedures?';
    }
  }

  int min(int a, int b) {
    return a < b ? a : b;
  }

  void _startListening() async {
    setState(() {
      _isListening = true;
    });
    
    await _voiceService.startListening((result) {
      setState(() {
        _isListening = false;
        _messageController.text = result;
      });
    });
  }

  void _stopListening() {
    _voiceService.stopListening();
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.white,
              radius: 14,
              child: Icon(
                Icons.smart_toy,
                size: 16,
                color: Colors.indigo,
              ),
            ),
            SizedBox(width: 8),
            Text('AI Assistant'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('AI Assistant'),
                  content: const Text(
                    'The AI assistant can help with flight information, booking assistance, '
                    'travel tips, and more. Your conversations are processed securely.'
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
          
          // Typing indicator
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  const Text(
                    'AI is typing',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(_isListening ? Icons.mic_off : Icons.mic),
                  onPressed: _isListening ? _stopListening : _startListening,
                  color: _isListening ? Colors.red : null,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything about flights...',
                      border: InputBorder.none,
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.type == MessageType.user;
    final bubbleColor = isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).cardColor;
    final textColor = isUser ? Colors.white : null;
    final alignment = isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleBorderRadius = BorderRadius.circular(16).copyWith(
      bottomRight: isUser ? const Radius.circular(4) : null,
      bottomLeft: !isUser ? const Radius.circular(4) : null,
    );
    
    final timeFormat = DateFormat('HH:mm');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: bubbleBorderRadius,
            ),
            child: Text(
              message.content,
              style: TextStyle(color: textColor),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeFormat.format(message.timestamp),
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
} 