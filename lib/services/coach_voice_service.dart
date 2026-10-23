import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/coach_profile.dart';

class CoachVoiceService {
  static final CoachVoiceService instance = CoachVoiceService._internal();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  bool isMuted = false;

  CoachVoiceService._internal();

  bool get isSpeaking => _isSpeaking;

  Future<void> init() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() {
        _isSpeaking = true;
      });

      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _tts.setCancelHandler(() {
        _isSpeaking = false;
      });

      _tts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('[CoachVoiceService] TTS Error: $msg');
      });
    } catch (e) {
      debugPrint('[CoachVoiceService] TTS init failed: $e');
    }
  }

  /// Speaks commentary with coach-specific vocal personality
  Future<void> speakCommentary({
    required String commentary,
    required CoachPersonality personality,
  }) async {
    if (isMuted) return;
    await init();

    try {
      await _tts.stop();

      // Clean emojis and symbols that sound awkward when read aloud
      final cleanText = _sanitizeForSpeech(commentary);
      if (cleanText.isEmpty) return;

      // Adjust vocal pitch and speed per coach personality
      switch (personality) {
        case CoachPersonality.gotham:
          await _tts.setSpeechRate(0.58);
          await _tts.setPitch(1.2);
          break;
        case CoachPersonality.grandmaster:
          await _tts.setSpeechRate(0.46);
          await _tts.setPitch(0.95);
          break;
        case CoachPersonality.roast:
          await _tts.setSpeechRate(0.44);
          await _tts.setPitch(0.85);
          break;
        case CoachPersonality.encouraging:
          await _tts.setSpeechRate(0.50);
          await _tts.setPitch(1.15);
          break;
        case CoachPersonality.ruthless:
          await _tts.setSpeechRate(0.52);
          await _tts.setPitch(1.0);
          break;
        case CoachPersonality.classic:
          await _tts.setSpeechRate(0.53);
          await _tts.setPitch(1.05);
          break;
      }

      await _tts.speak(cleanText);
    } catch (e) {
      debugPrint('[CoachVoiceService] Speak error: $e');
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (_) {}
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) {
      stop();
    }
  }

  String _sanitizeForSpeech(String raw) {
    // Strip emojis
    final emojiRegex = RegExp(
      r'[\u{1F600}-\u{1F64F}\u{1F300}-\u{1F5FF}\u{1F680}-\u{1F6FF}\u{1F700}-\u{1F77F}\u{1F780}-\u{1F7FF}\u{1F800}-\u{1F8FF}\u{1F900}-\u{1F9FF}\u{1FA00}-\u{1FA6F}\u{1FA70}-\u{1FAFF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}\u{2300}-\u{23FF}]',
      unicode: true,
    );
    String cleaned = raw.replaceAll(emojiRegex, '');

    // Replace chess notation symbols so TTS pronounces them properly
    cleaned = cleaned.replaceAll('??', ' blunder, ');
    cleaned = cleaned.replaceAll('?!', ' inaccuracy, ');
    cleaned = cleaned.replaceAll('!?', ' interesting move, ');
    cleaned = cleaned.replaceAll('!!', ' brilliant move! ');
    cleaned = cleaned.replaceAll('!', ' good move! ');
    cleaned = cleaned.replaceAll('+', ' check');
    cleaned = cleaned.replaceAll('#', ' checkmate');

    // Clean up excessive whitespace
    return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}
