import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/source_translation_service.dart';
import '../usage/ai_quota_service.dart';

/// Owner-scoped reading and translation for every stored source type.
class SourceReadingEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Streams complete, aligned batches. Previously saved batches cost no AI
  /// quota; switching language or modifying a source creates a different key.
  Stream<String> readSource(
    Session session,
    int sourceId,
    String supportLanguage,
    String mode,
  ) async* {
    final userId = session.authenticated?.userIdentifier;
    if (userId == null) throw StateError('A private session is required.');
    final language = SourceTranslationService.languageCode(supportLanguage);
    final source = await Source.db.findFirstRow(
      session,
      where: (t) =>
          t.id.equals(sourceId) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    if (source == null)
      throw ImportException(
        code: 'not_found',
        message: 'This source is not in your collection.',
      );
    final units = sourceReadingSegments(source.rawText, mode);
    final hash = sha256
        .convert(utf8.encode(sourceReadingText(source.rawText)))
        .toString();
    final translator = SourceTranslationService(
      apiKey: session.serverpod.getPassword('metaApiKey') ?? '',
    );
    try {
      yield jsonEncode({
        'mode': mode,
        'language': language,
        'total': units.length,
        'segments': [],
        'done': units.isEmpty,
      });
      for (var offset = 0; offset < units.length;) {
        // Bound each paid call by both input size and segment count.
        final batch = <String>[];
        var length = 0;
        while (offset + batch.length < units.length && batch.length < 16) {
          final unit = units[offset + batch.length];
          if (batch.isNotEmpty && length + unit.length > 5000) break;
          batch.add(unit);
          length += unit.length;
        }
        List<String> translations;
        if (mode == 'original') {
          translations = batch;
        } else {
          final cacheKey = sha256
              .convert(
                utf8.encode(
                  jsonEncode([
                    'source-reading-v1',
                    userId,
                    sourceId,
                    hash,
                    language,
                    mode,
                    offset,
                    translator.model,
                  ]),
                ),
              )
              .toString();
          final saved = await SourceTranslationChunk.db.findFirstRow(
            session,
            where: (t) => t.userId.equals(userId) & t.cacheKey.equals(cacheKey),
          );
          if (saved != null) {
            translations = (jsonDecode(saved.segments) as List).cast<String>();
          } else {
            await AiQuotaService.consume(session, 'translation');
            translations = await translator.translate(batch, language);
            try {
              await SourceTranslationChunk.db.insertRow(
                session,
                SourceTranslationChunk(
                  userId: userId,
                  sourceId: sourceId,
                  cacheKey: cacheKey,
                  supportLanguage: language,
                  mode: mode,
                  segments: jsonEncode(translations),
                  createdAt: DateTime.now().toUtc(),
                ),
              );
            } catch (_) {
              // A parallel request may have saved the same immutable batch.
              final existing = await SourceTranslationChunk.db.findFirstRow(
                session,
                where: (t) =>
                    t.userId.equals(userId) & t.cacheKey.equals(cacheKey),
              );
              if (existing == null) rethrow;
            }
          }
        }
        yield jsonEncode({
          'mode': mode,
          'language': language,
          'total': units.length,
          'segments': [
            for (var i = 0; i < batch.length; i++)
              {
                'id': offset + i,
                'original': batch[i],
                'translation': translations[i],
              },
          ],
          'done': offset + batch.length == units.length,
        });
        offset += batch.length;
      }
    } on ImportException {
      rethrow;
    } catch (_) {
      throw ImportException(
        code: 'translation_failed',
        message:
            'Translation could not finish. Your original source and completed sections are still available. Try again to continue.',
      );
    } finally {
      translator.close();
    }
  }
}
