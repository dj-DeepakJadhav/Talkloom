import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/services/source_translation_service.dart';
import 'test_tools/serverpod_test_tools.dart';

const a = '00000000-0000-4000-8000-000000000081';
const b = '00000000-0000-4000-8000-000000000082';

void main() {
  withServerpod('Source reader ownership and cache', (builder, endpoints) {
    final owner = builder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(a, const {}),
    );
    final other = builder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(b, const {}),
    );

    Future<Source> source(String type) async {
      final session = owner.build();
      try {
        return await Source.db.insertRow(
          session,
          Source(
            userId: a,
            type: type,
            title: 'Morning',
            rawText: 'Guten Morgen.\nDanke!',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.utc(2026),
          ),
        );
      } finally {
        await session.close();
      }
    }

    test(
      'private sources cannot be read without authentication or by another learner',
      () async {
        final saved = await source('text');
        await expectLater(
          endpoints.sourceReading
              .readSource(builder, saved.id!, 'en', 'original')
              .toList(),
          throwsA(anything),
        );
        await expectLater(
          endpoints.sourceReading
              .readSource(other, saved.id!, 'en', 'original')
              .toList(),
          throwsA(isA<ImportException>()),
        );
      },
    );

    for (final type in ['url', 'text', 'document', 'image', 'ocr']) {
      test(
        '$type uses the same stored-source reader without an AI call',
        () async {
          final saved = await source(type);
          final events = await endpoints.sourceReading
              .readSource(owner, saved.id!, 'en', 'original')
              .toList();
          final result = jsonDecode(events.last) as Map;
          expect(result['done'], isTrue);
          expect(result['segments'][0]['original'], 'Guten Morgen.\nDanke!');
        },
      );
    }

    test(
      'a cached translation returns aligned text without invoking Meta',
      () async {
        final saved = await source('document');
        final hash = sha256
            .convert(utf8.encode(sourceReadingText(saved.rawText)))
            .toString();
        final key = sha256
            .convert(
              utf8.encode(
                jsonEncode([
                  'source-reading-v1',
                  a,
                  saved.id!,
                  hash,
                  'en',
                  'line',
                  0,
                  'muse-spark-1.3',
                ]),
              ),
            )
            .toString();
        final session = owner.build();
        try {
          await SourceTranslationChunk.db.insertRow(
            session,
            SourceTranslationChunk(
              userId: a,
              sourceId: saved.id!,
              cacheKey: key,
              supportLanguage: 'en',
              mode: 'line',
              segments: jsonEncode(['Good morning.', 'Thanks!']),
              createdAt: DateTime.utc(2026),
            ),
          );
        } finally {
          await session.close();
        }
        final events = await endpoints.sourceReading
            .readSource(owner, saved.id!, 'en', 'line')
            .toList();
        final segments = (jsonDecode(events.last) as Map)['segments'] as List;
        expect(segments[0]['original'], 'Guten Morgen.');
        expect(segments[0]['translation'], 'Good morning.');
        expect(segments[1]['translation'], 'Thanks!');
      },
    );

    test('archived content is unavailable even to its owner', () async {
      final saved = await source('text');
      final session = owner.build();
      try {
        await Source.db.updateRow(session, saved.copyWith(isArchived: true));
      } finally {
        await session.close();
      }
      await expectLater(
        endpoints.sourceReading
            .readSource(owner, saved.id!, 'en', 'original')
            .toList(),
        throwsA(isA<ImportException>()),
      );
    });
  });
}
