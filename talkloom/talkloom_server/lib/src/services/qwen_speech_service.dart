import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class QwenSpeechService {
  QwenSpeechService({http.Client? client, Uri? worker})
      : _client = client ?? http.Client(),
        _worker = worker ?? Uri.parse(Platform.environment['QWEN_TTS_URL'] ??
            'http://127.0.0.1:8130/synthesize');
  final http.Client _client;
  final Uri _worker;

  Future<Uint8List> synthesize(String text, String language) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > 600) {
      throw ArgumentError('Speech text must contain 1–600 characters.');
    }
    final lang = language.toLowerCase().split(RegExp('[-_]')).first;
    if (!['de', 'en'].contains(lang)) {
      throw ArgumentError('Speech currently supports German and English.');
    }
    final response = await _client.post(_worker,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'text': clean, 'language': lang}),
    ).timeout(const Duration(seconds: 120));
    final bytes = response.bodyBytes;
    if (response.statusCode != 200 || bytes.length < 44 ||
        bytes.length > 8 * 1024 * 1024 ||
        ascii.decode(bytes.sublist(0, 4), allowInvalid: true) != 'RIFF' ||
        ascii.decode(bytes.sublist(8, 12), allowInvalid: true) != 'WAVE') {
      throw StateError('Qwen speech is unavailable or returned invalid audio.');
    }
    return bytes;
  }
}
