import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

/// Open-source neural speech via the local Piper worker (self-hosted,
/// CPU-friendly, no cloud, no key).
///
/// This is Talkloom's spoken-voice path. Language models remain Meta-only;
/// speech synthesis has no Meta API, so an open model fills the gap.
/// When the worker is unreachable the client falls back to on-device voices.
class LocalTtsService {
  LocalTtsService({
    http.Client? client,
    Uri? worker,
    this.defaultVoice = 'de-thorsten-m',
  })  : _client = client ?? http.Client(),
        _worker =
            worker ??
            Uri.parse('http://127.0.0.1:8131/synthesize');

  final http.Client _client;
  final Uri _worker;
  final String defaultVoice;

  static const int maxTextLength = 600;

  bool _isValidWav(Uint8List bytes) {
    if (bytes.length < 1000 || bytes.length > 16 * 1024 * 1024) return false;
    final riff = ascii.decode(bytes.sublist(0, 4), allowInvalid: true);
    final wave = ascii.decode(bytes.sublist(8, 12), allowInvalid: true);
    return riff == 'RIFF' && wave == 'WAVE';
  }

  /// Synthesizes [text] with [voice] (a worker voice id, e.g.
  /// `de-ramona-f`). Throws [StateError] when the worker is down or
  /// returns invalid audio; callers fall back to device speech.
  Future<({Uint8List audio, String voice})> synthesize(
    String text,
    String language, {
    String? voice,
  }) async {
    final clean = text.trim();
    if (clean.isEmpty || clean.length > maxTextLength) {
      throw ArgumentError('Speech text must contain 1 to 600 characters.');
    }
    final voiceId =
        (voice != null && voice.trim().isNotEmpty) ? voice.trim() : defaultVoice;
    final response = await _client
        .post(
          _worker,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'text': clean,
            'language': language,
            'voice': voiceId,
          }),
        )
        .timeout(const Duration(seconds: 60));

    if (response.statusCode != 200) {
      throw StateError(
        'Local speech service is unavailable (HTTP ${response.statusCode}).',
      );
    }
    final bytes = response.bodyBytes;
    if (!_isValidWav(bytes)) {
      throw StateError('Local speech service returned invalid audio.');
    }
    return (audio: bytes, voice: voiceId);
  }
}
