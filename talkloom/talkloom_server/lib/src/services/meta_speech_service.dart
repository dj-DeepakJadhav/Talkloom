import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

/// Speech-to-text via the Meta Model API (Muse Voice Transcribe).
///
/// This is Talkloom's ONLY cloud speech provider. Uploaded learner audio is
/// transcribed with `muse-voice-transcribe-1.0` (`POST /v1/asr/transcribe`,
/// multipart `request` JSON + `audio` WAV). The endpoint only accepts
/// mono 16-bit PCM WAV at 16 or 24 kHz, matching the model's input contract.
class MetaSpeechService {
  MetaSpeechService({
    http.Client? client,
    required this.apiKey,
    this.model = 'muse-voice-transcribe-1.0',
    this.baseUrl = 'https://api.meta.ai/v1',
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String apiKey;
  final String model;
  final String baseUrl;

  static const _languageNames = <String, String>{
    'de': 'German',
    'en': 'English',
    'es': 'Spanish',
    'fr': 'French',
    'it': 'Italian',
  };

  /// Transcribes base64-encoded WAV audio, returning the transcript text.
  /// Throws [ArgumentError] on invalid input and [StateError] when Meta
  /// is unconfigured or transcription fails.
  Future<String> transcribe(
    String base64Audio, {
    String language = 'de',
    List<String>? vocabulary,
  }) async {
    final lang = language.toLowerCase().split(RegExp('[-_]')).first;
    final languageName = _languageNames[lang];
    if (languageName == null) {
      throw ArgumentError('Transcription currently supports German, English, Spanish, French, and Italian.');
    }
    if (apiKey.isEmpty) {
      throw StateError('Meta Model API key is not configured.');
    }
    Uint8List audio;
    try {
      audio = base64Decode(base64Audio);
    } on FormatException {
      throw ArgumentError('Audio must be base64-encoded WAV data.');
    }
    if (audio.length < 1000 || audio.length > 15 * 1024 * 1024) {
      throw ArgumentError('Audio must be between 1 KB and 15 MB.');
    }
    if (ascii.decode(audio.sublist(0, 4), allowInvalid: true) != 'RIFF') {
      throw ArgumentError('Audio must be a WAV file.');
    }

    final requestJson = jsonEncode({
      'mode': 'PUSH_TO_TALK',
      'model': model,
      'audioEncoding': 'WAV',
      'languageBias': [languageName],
      if (vocabulary != null && vocabulary.isNotEmpty)
        'keywords': vocabulary,
    });
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/asr/transcribe'),
    )
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['request'] = requestJson
      ..files.add(
        http.MultipartFile.fromBytes(
          'audio',
          audio,
          filename: 'audio.wav',
          contentType: MediaType('audio', 'wav'),
        ),
      );

    final streamed = await _client.send(request).timeout(
      const Duration(seconds: 60),
    );
    final body = await streamed.stream.bytesToString();
    if (streamed.statusCode != 200) {
      throw StateError(
        'Meta transcription failed (HTTP ${streamed.statusCode}): '
        '${body.length > 300 ? body.substring(0, 300) : body}',
      );
    }
    final data = jsonDecode(body);
    if (data is! Map<String, dynamic>) {
      throw StateError('Meta transcription returned an unexpected response.');
    }
    final transcript = data['transcript'];
    if (transcript is! String || transcript.trim().isEmpty) {
      throw StateError('Meta transcription returned no transcript.');
    }
    return transcript.trim();
  }

  /// Cache-style key helper kept for log correlation (no audio is cached).
  static String logKey(String text, String language) =>
      sha256.convert(utf8.encode('$language|$text')).toString().substring(0, 12);
}
