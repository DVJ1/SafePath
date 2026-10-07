import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsAudioService {
  final FlutterTts _flutterTts = FlutterTts();
  bool _isTtsInitialized = false;
  bool _isSpeaking = false;
  String _lastSpokenText = '';
  double _speechRate = 0.5;
  final double _volume = 1.0;
  final double _pitch = 1.0;

  String get lastSpokenText => _lastSpokenText;
  bool get isSpeaking => _isSpeaking;

  Future<void> init({double initialRate = 0.5}) async {
    _speechRate = initialRate;
    try {
      await _flutterTts.setLanguage('en-US');
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(_volume);
      await _flutterTts.setPitch(_pitch);

      _flutterTts.setStartHandler(() {
        _isSpeaking = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        debugPrint('FlutterTts error: $msg');
      });

      _isTtsInitialized = true;
    } catch (e) {
      debugPrint('TtsAudioService initialization notice: $e');
      _isTtsInitialized = false;
    }
  }

  /// Speak accessible text with priority level
  Future<void> speak(String text, {bool interrupt = false, bool haptic = true}) async {
    _lastSpokenText = text;
    if (haptic) {
      triggerLightHaptic();
    }

    if (interrupt) {
      await stop();
    }

    if (!_isTtsInitialized) {
      debugPrint('TTS [Simulated Audio Engine]: $text');
      return;
    }

    try {
      await _flutterTts.speak(text);
    } catch (e) {
      debugPrint('TTS speak failed: $e');
    }
  }

  /// Emergency urgent announcement with rapid tactile alert
  Future<void> speakEmergency(String text) async {
    _lastSpokenText = text;
    triggerEmergencyHapticPattern();
    await stop();

    if (_isTtsInitialized) {
      try {
        await _flutterTts.setPitch(1.1);
        await _flutterTts.speak(text);
      } catch (_) {}
    } else {
      debugPrint('EMERGENCY VOICE ALERT: $text');
    }
  }

  Future<void> stop() async {
    if (_isTtsInitialized) {
      try {
        await _flutterTts.stop();
      } catch (_) {}
    }
    _isSpeaking = false;
  }

  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    if (_isTtsInitialized) {
      try {
        await _flutterTts.setSpeechRate(rate);
      } catch (_) {}
    }
  }

  // --- Haptic Feedback Methods ---
  void triggerLightHaptic() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void triggerMediumHaptic() {
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void triggerHeavyHaptic() {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  void triggerSelectionClick() {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  /// Repeated vibrating burst for emergency / fall detection
  Future<void> triggerEmergencyHapticPattern() async {
    for (int i = 0; i < 4; i++) {
      try {
        HapticFeedback.heavyImpact();
        await Future.delayed(const Duration(milliseconds: 150));
        HapticFeedback.vibrate();
        await Future.delayed(const Duration(milliseconds: 150));
      } catch (_) {}
    }
  }
}
