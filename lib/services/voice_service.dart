import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter/foundation.dart';

enum VoiceCommandType {
  searchFlight,
  bookFlight,
  cancelBooking,
  checkStatus,
  help,
  unknown
}

class VoiceCommand {
  final VoiceCommandType type;
  final Map<String, dynamic> parameters;

  VoiceCommand({required this.type, this.parameters = const {}});
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isInitialized = false;

  Future<void> initialize() async {
    debugPrint('VoiceService: initialize called');
    try {
      debugPrint('VoiceService: Initializing SpeechToText...');
      _isInitialized = await _speechToText.initialize(
        onError: (error) => debugPrint('VoiceService: Speech recognition error: $error'),
        onStatus: (status) => debugPrint('VoiceService: Speech recognition status: $status'),
      );
      debugPrint('VoiceService: SpeechToText initialized status: $_isInitialized');

      if (_isInitialized) {
         debugPrint('VoiceService: Initializing FlutterTts...');
        await _flutterTts.setLanguage('en-US');
        await _flutterTts.setSpeechRate(0.5);
        await _flutterTts.setVolume(1.0);
        await _flutterTts.setPitch(1.0);
        
        _flutterTts.setErrorHandler((error) {
          debugPrint('VoiceService: TTS error: $error');
        });
        
        _flutterTts.setCompletionHandler(() {
          debugPrint('VoiceService: TTS completed');
        });
         debugPrint('VoiceService: FlutterTts initialized');

      } else {
         debugPrint('VoiceService: SpeechToText initialization failed, TTS not initialized');
      }

    } catch (e) {
      debugPrint('VoiceService: Failed to initialize voice service: $e');
      _isInitialized = false;
    }
     debugPrint('VoiceService: Initialization finished. _isInitialized: $_isInitialized');
  }

  Future<void> startListening(Function(String) onResult) async {
    if (!_isInitialized) {
      debugPrint('VoiceService: startListening called but not initialized');
      await speak('Voice service is not initialized. Please try again.');
      return;
    }

    if (!_isListening) {
      debugPrint('VoiceService: Starting listening...');
      try {
        _isListening = true;
        
        await _speechToText.listen(
          onResult: (result) {
            debugPrint('VoiceService: Speech result: ${result.recognizedWords}');
            if (result.finalResult) {
               debugPrint('VoiceService: Final speech result: ${result.recognizedWords}');
              onResult(result.recognizedWords);
            }
          },
          listenFor: const Duration(seconds: 30),
          pauseFor: const Duration(seconds: 3),
          partialResults: false,
          onDevice: true,
          cancelOnError: true,
          listenMode: ListenMode.dictation,
        );
         debugPrint('VoiceService: Listening started');
      } catch (e) {
        debugPrint('VoiceService: Error starting speech recognition: $e');
        _isListening = false;
        await speak('Sorry, I encountered an error starting speech recognition. Please try again.');
      }
    }
  }

  Future<void> stopListening() async {
    if (_isListening) {
      debugPrint('VoiceService: Stopping listening...');
      try {
        await _speechToText.stop();
        _isListening = false;
         debugPrint('VoiceService: Listening stopped');
      } catch (e) {
        debugPrint('VoiceService: Error stopping speech recognition: $e');
      }
    }
  }

  Future<void> speak(String text) async {
    debugPrint('VoiceService: Speaking: $text');
    try {
      await _flutterTts.speak(text);
       debugPrint('VoiceService: Speak command issued');
    } catch (e) {
      debugPrint('VoiceService: Error speaking text: $e');
    }
  }

  Future<void> stop() async {
     debugPrint('VoiceService: Stopping TTS...');
    try {
      await _flutterTts.stop();
       debugPrint('VoiceService: TTS stopped');
    } catch (e) {
      debugPrint('VoiceService: Error stopping TTS: $e');
    }
  }

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;

  void dispose() {
    debugPrint('VoiceService: Disposing resources...');
    _speechToText.cancel();
    _flutterTts.stop();
     debugPrint('VoiceService: Resources disposed');
  }
} 