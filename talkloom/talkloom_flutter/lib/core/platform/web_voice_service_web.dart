import 'dart:async';
import 'qwen_speech_service.dart';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

@JS('talkloomVoice.startListening')
external bool _jsStartListening(JSString? langCode);

@JS('talkloomVoice.stopListening')
external void _jsStopListening();

@JS('talkloomVoice.isListening')
external bool get _jsIsListening;

class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();

  void Function(String transcript)? onTranscriptReceived;
  void Function(bool listening)? onListeningChanged;
  bool _initialized = false;
  Timer? _monitor;
  bool _listening = false;
  bool get isListening => _listening;
  bool get canSpeak {
    try {
      return true;
    } catch (_) {
      return false;
    }
  }

  String get speechUnavailableReason => QwenSpeechService.instance.unavailableReason;

  void init() {
    if (_initialized) return;
    try {
      web.window.addEventListener(
        'talkloom_speech_result',
        (web.Event event) {
          final customEvent = event as web.CustomEvent;
          final detail = (customEvent.detail as JSString?)?.toDart;
          if (detail != null && onTranscriptReceived != null) {
            onTranscriptReceived!(detail);
          }
        }.toJS,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[WebVoiceService] init listener error: $e');
    }
  }

  bool startListening({String langCode = 'de-DE'}) {
    if (!kIsWeb) return false;
    try {
      final success = _jsStartListening(langCode.toJS);
      _listening = success;
      _monitor?.cancel();
      if (success) {
        _monitor = Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (!_jsIsListening) {
            timer.cancel();
            _listening = false;
            onListeningChanged?.call(false);
          }
        });
      }
      return success;
    } catch (e) {
      debugPrint('[WebVoiceService] startListening error: $e');
      _listening = false;
      return false;
    }
  }

  void stopListening() {
    if (!kIsWeb) return;
    try {
      _jsStopListening();
    } catch (e) {
      debugPrint('[WebVoiceService] stopListening error: $e');
    } finally {
      _monitor?.cancel();
      _listening = false;
    }
  }

  Future<bool> speak(String text, {String langCode = 'de-DE'}) =>
      QwenSpeechService.instance.speak(text, langCode: langCode);
}
