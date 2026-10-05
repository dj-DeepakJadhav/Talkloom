import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;
import 'dart:js_interop';

@JS('talkloomVoice.startListening')
external bool _jsStartListening(JSString? langCode);

@JS('talkloomVoice.stopListening')
external void _jsStopListening();

@JS('talkloomVoice.speakText')
external void _jsSpeakText(JSString text, JSString? langCode);

class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();

  void Function(String transcript)? onTranscriptReceived;
  bool _listening = false;
  bool get isListening => _listening;

  void init() {
    if (!kIsWeb) return;
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
    } catch (e) {
      debugPrint('[WebVoiceService] init listener error: $e');
    }
  }

  bool startListening({String langCode = 'de-DE'}) {
    if (!kIsWeb) return false;
    try {
      final success = _jsStartListening(langCode.toJS);
      _listening = success;
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
      _listening = false;
    }
  }

  void speak(String text, {String langCode = 'de-DE'}) {
    if (!kIsWeb) return;
    try {
      _jsSpeakText(text.toJS, langCode.toJS);
    } catch (e) {
      debugPrint('[WebVoiceService] speak error: $e');
    }
  }
}
