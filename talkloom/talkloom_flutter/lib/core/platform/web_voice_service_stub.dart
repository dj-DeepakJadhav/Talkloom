import 'qwen_speech_service.dart';
/// Recognition remains platform-specific; Qwen audio output is shared.
class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();
  void Function(String transcript)? onTranscriptReceived;
  void Function(bool listening)? onListeningChanged;
  bool get isListening => false;
  bool get canSpeak => true;
  String get speechUnavailableReason =>
      QwenSpeechService.instance.unavailableReason;
  void init() {}
  bool startListening({String langCode = 'de-DE'}) => false;
  void stopListening() {}
  Future<bool> speak(String text, {String langCode = 'de-DE'}) =>
      QwenSpeechService.instance.speak(text, langCode: langCode);
}
