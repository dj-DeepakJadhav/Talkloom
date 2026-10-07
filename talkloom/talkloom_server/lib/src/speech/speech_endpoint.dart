import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../services/qwen_speech_service.dart';

class SpeechEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  final _speech = QwenSpeechService();

  /// Private guest sessions and registered users use the same speech path.
  Future<String> synthesize(Session session, String text, String language) async {
    final audio = await _speech.synthesize(text, language);
    return jsonEncode({'audio': base64Encode(audio), 'mimeType': 'audio/wav',
      'provider': 'qwen3-tts'});
  }
}
