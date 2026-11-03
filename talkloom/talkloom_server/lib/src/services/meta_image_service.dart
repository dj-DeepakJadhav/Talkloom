import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Vocabulary and scene illustration via the Meta Model API (Muse Image).
///
/// Style is locked server-side so every picture matches the Talkloom theme:
/// flat vector sticker, thick espresso outlines, warm paper ground, sand and
/// dusty-olive fills, no text. Clients pass only the subject — never a style.
class MetaImageService {
  MetaImageService({
    http.Client? client,
    required this.apiKey,
    this.model = 'muse-image-1.0',
    this.baseUrl = 'https://api.meta.ai/v1',
    Directory? cacheDirectory,
  }) : _client = client ?? http.Client(),
       _cacheDir =
           cacheDirectory ??
           Directory(
             Platform.environment['IMAGE_CACHE_DIR'] ?? '.serverpod/image-cache',
           );

  final http.Client _client;
  final String apiKey;
  final String model;
  final String baseUrl;
  final Directory _cacheDir;

  static const int _maxCacheBytes = 256 * 1024 * 1024; // 256 MB

  /// The one house style. Baked into every request; not client-configurable.
  static String stylePrompt(String subject) =>
      'Flat vector sticker illustration, thick espresso-brown (#30251D) '
      'outlines, warm cream paper background (#FFFCF5), fills in sand '
      '(#FDE8BA, #D2B384) and dusty olive (#646F4B) only, soft rounded '
      'shapes, no text, no letters, no words, no watermark, single centered '
      'object: $subject. Minimal, calm, picture-book clarity.';

  String _cacheKey(String subject) {
    return sha256.convert(utf8.encode('$model|$subject')).toString();
  }

  bool _isPng(Uint8List bytes) {
    return bytes.length > 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47;
  }

  bool _isJpeg(Uint8List bytes) {
    return bytes.length > 3 &&
        bytes[0] == 0xFF &&
        bytes[1] == 0xD8 &&
        bytes[2] == 0xFF;
  }

  /// Illustrates [subject] in the house style, returning PNG/JPEG bytes.
  /// Results are cached on disk keyed by subject.
  Future<Uint8List> illustrate(String subject) async {
    final clean = subject.trim();
    if (clean.isEmpty || clean.length > 200) {
      throw ArgumentError('Subject must contain 1 to 200 characters.');
    }
    if (apiKey.isEmpty) {
      throw StateError('Meta Model API key is not configured.');
    }

    final key = _cacheKey(clean.toLowerCase());
    for (final ext in const ['png', 'jpg']) {
      try {
        final cached = File('${_cacheDir.path}/$key.$ext');
        if (cached.existsSync()) {
          final bytes = await cached.readAsBytes();
          if (_isPng(bytes) || _isJpeg(bytes)) return bytes;
        }
      } catch (_) {}
    }

    final response = await _client
        .post(
          Uri.parse('$baseUrl/images/generations'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: jsonEncode({
            'model': model,
            'prompt': stylePrompt(clean),
            'size': '1024x1024',
            'response_format': 'b64_json',
          }),
        )
        .timeout(const Duration(seconds: 120));

    if (response.statusCode != 200) {
      throw StateError(
        'Meta image generation failed (HTTP ${response.statusCode}): '
        '${response.body.length > 300 ? response.body.substring(0, 300) : response.body}',
      );
    }
    final data = jsonDecode(response.body);
    final items = data is Map ? data['data'] : null;
    if (items is! List || items.isEmpty) {
      throw StateError('Meta image generation returned no image.');
    }
    final first = items.first as Map;
    Uint8List bytes;
    String ext;
    if (first['b64_json'] is String) {
      try {
        bytes = base64Decode(first['b64_json'] as String);
      } on FormatException {
        throw StateError('Meta image generation returned invalid data.');
      }
      ext = _isPng(bytes) ? 'png' : 'jpg';
    } else if (first['url'] is String) {
      final imageResponse = await _client
          .get(Uri.parse(first['url'] as String))
          .timeout(const Duration(seconds: 60));
      if (imageResponse.statusCode != 200) {
        throw StateError('Meta image download failed.');
      }
      bytes = imageResponse.bodyBytes;
      ext = _isPng(bytes) ? 'png' : 'jpg';
    } else {
      throw StateError('Meta image generation returned no image.');
    }
    if (!_isPng(bytes) && !_isJpeg(bytes)) {
      throw StateError('Meta image generation returned an unknown format.');
    }

    try {
      if (!_cacheDir.existsSync()) _cacheDir.createSync(recursive: true);
      final tmp = File('${_cacheDir.path}/$key.$ext.tmp');
      await tmp.writeAsBytes(bytes, flush: true);
      await tmp.rename('${_cacheDir.path}/$key.$ext');
      _pruneCacheIfNeeded();
    } catch (_) {}

    return bytes;
  }

  void _pruneCacheIfNeeded() {
    try {
      if (!_cacheDir.existsSync()) return;
      final files = _cacheDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.png') || f.path.endsWith('.jpg'))
          .toList();
      int total = 0;
      for (final f in files) {
        total += f.lengthSync();
      }
      if (total <= _maxCacheBytes) return;
      files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));
      for (final f in files) {
        if (total <= _maxCacheBytes) break;
        total -= f.lengthSync();
        f.deleteSync();
      }
    } catch (_) {}
  }
}
