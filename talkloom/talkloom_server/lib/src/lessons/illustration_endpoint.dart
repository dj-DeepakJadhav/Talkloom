import 'dart:convert';
import 'dart:typed_data';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/meta_image_service.dart';
import '../usage/ai_quota_service.dart';

/// House-style illustration via Muse Image (Meta Model API).
/// The style is locked server-side; callers pass only the subject.
class IllustrationEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Current house style. Bumping this retires every stored picture at
  /// once: lookups only ever read this version.
  static const int styleVersion = 1;

  MetaImageService _images(Session session) => MetaImageService(
    apiKey: session.serverpod.getPassword('metaApiKey') ?? '',
    model: session.serverpod.getPassword('metaImageModel') ?? 'muse-image-1.0',
  );

  /// Illustrates [subject] (a scene or one-off picture) in the Talkloom
  /// house style. Returns base64 PNG/JPEG bytes for the client to cache.
  Future<String> illustrate(Session session, String subject) async {
    await AiQuotaService.consume(session, 'illustration');
    final bytes = await _images(session).illustrate(subject);
    return jsonEncode({
      'image': base64Encode(bytes),
      'mimeType': _mimeType(bytes),
      'provider': 'meta',
    });
  }

  /// Vocabulary art shared across all learners and languages, keyed by
  /// lower-cased lemma. First request generates and stores it; every later
  /// request (any learner, any language) reuses the stored bytes.
  Future<String> wordArt(
    Session session,
    String lemma,
    String language, {
    String? meaning,
  }) async {
    final key = lemma.trim().toLowerCase();
    if (key.isEmpty || key.length > 100) {
      throw ArgumentError('A word of 1 to 100 characters is required.');
    }
    final stored = await VocabArtwork.db.findFirstRow(
      session,
      where: (t) =>
          t.lemmaKey.equals(key) & t.styleVersion.equals(styleVersion),
    );
    if (stored != null) {
      stored.hitCount += 1;
      stored.lastUsedAt = DateTime.now();
      await VocabArtwork.db.updateRow(session, stored);
      final bytes = stored.artwork.buffer.asUint8List();
      return jsonEncode({
        'image': base64Encode(bytes),
        'mimeType': stored.mimeType,
        'provider': 'meta',
        'cached': true,
      });
    }
    final subject = meaning == null || meaning.trim().isEmpty
        ? 'dictionary illustration of "$key"'
        : 'dictionary illustration of "$key" (meaning: ${meaning.trim()})';
    // Shared cache hit above cost nothing; only generation consumes quota.
    await AiQuotaService.consume(session, 'illustration');
    final bytes = await _images(session).illustrate(subject);
    await VocabArtwork.db.insertRow(
      session,
      VocabArtwork(
        lemmaKey: key,
        language: language.trim().isEmpty ? 'und' : language.trim(),
        styleVersion: styleVersion,
        mimeType: _mimeType(bytes),
        artwork: ByteData.sublistView(bytes),
        hitCount: 1,
        createdAt: DateTime.now(),
        lastUsedAt: DateTime.now(),
      ),
    );
    return jsonEncode({
      'image': base64Encode(bytes),
      'mimeType': _mimeType(bytes),
      'provider': 'meta',
      'cached': false,
    });
  }

  static String _mimeType(Uint8List bytes) =>
      bytes.length > 3 && bytes[0] == 0x89 ? 'image/png' : 'image/jpeg';
}
