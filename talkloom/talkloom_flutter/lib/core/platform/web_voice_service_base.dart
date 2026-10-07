import 'package:flutter/foundation.dart';

abstract class WebVoicePlatform {
  void init(void Function(String transcript)? onTranscriptReceived);
  bool startListening({String langCode = 'de-DE'});
  void stopListening();
  bool get canSpeak;
  bool speak(String text, {String langCode = 'de-DE'});
}

class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();

  void Function(String transcript)? onTranscriptReceived;
  bool _listening = false;
  bool get isListening => _listening;
  bool get canSpeak => kIsWeb && (_platform?.canSpeak ?? false);
  String get speechUnavailableReason => kIsWeb
      ? 'Speech output is unavailable in this browser. Read the reply and continue.'
      : 'Speech output is not available on this device yet. Read the reply and continue.';

  WebVoicePlatform? _platform;

  void setPlatform(WebVoicePlatform platform) {
    _platform = platform;
  }

  void init() {
    if (!kIsWeb) return;
    _platform?.init(onTranscriptReceived);
  }

  bool startListening({String langCode = 'de-DE'}) {
    if (!kIsWeb || _platform == null) return false;
    final success = _platform!.startListening(langCode: langCode);
    _listening = success;
    return success;
  }

  void stopListening() {
    if (!kIsWeb || _platform == null) return;
    try {
      _platform!.stopListening();
    } finally {
      _listening = false;
    }
  }

  bool speak(String text, {String langCode = 'de-DE'}) {
    if (!kIsWeb || _platform == null) return false;
    return _platform!.speak(text, langCode: langCode);
  }
}
