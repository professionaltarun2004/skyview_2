import 'package:flutter/material.dart';
import 'package:skyview_2/services/voice_service.dart';
import 'package:lottie/lottie.dart';

class VoiceFAB extends StatefulWidget {
  const VoiceFAB({super.key});

  @override
  State<VoiceFAB> createState() => _VoiceFABState();
}

class _VoiceFABState extends State<VoiceFAB> with SingleTickerProviderStateMixin {
  final VoiceService _voiceService = VoiceService();
  late AnimationController _animationController;
  bool _isListening = false;
  String _lastCommand = '';

  @override
  void initState() {
    super.initState();
    _voiceService.initialize();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleListening() async {
    if (!_isListening) {
      setState(() {
        _isListening = true;
      });
      _animationController.repeat(reverse: true);
      
      await _voiceService.startListening((command) {
        setState(() {
          _lastCommand = command as String;
        });
        _processVoiceCommand(command as String);
      });
    } else {
      setState(() {
        _isListening = false;
      });
      _animationController.stop();
      _voiceService.stopListening();
    }
  }

  void _processVoiceCommand(String command) {
    final lowerCommand = command.toLowerCase();
    
    // Simple voice command processing
    if (lowerCommand.contains('book') && lowerCommand.contains('flight')) {
      _voiceService.speak("Opening flight search");
      Navigator.of(context).pushNamed('/search');
    } else if (lowerCommand.contains('my profile') || lowerCommand.contains('show profile')) {
      _voiceService.speak("Opening your profile");
      Navigator.of(context).pushNamed('/profile');
    } else if (lowerCommand.contains('help') || lowerCommand.contains('assistant')) {
      _voiceService.speak("Opening AI assistant");
      Navigator.of(context).pushNamed('/chat');
    } else {
      _voiceService.speak("I didn't understand. Can you try again?");
    }
    
    _toggleListening();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _toggleListening,
      backgroundColor: _isListening 
          ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
          : Theme.of(context).colorScheme.primary,
      child: _isListening
          ? AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _animationController.value * 0.2,
                  child: const Icon(Icons.mic),
                );
              },
            )
          : const Icon(Icons.mic),
    );
  }
} 