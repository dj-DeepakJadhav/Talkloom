import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/services/ingestion_service.dart';
import 'package:talkloom_server/src/sources/lesson_import_service.dart';
import 'package:test/test.dart';

import 'test_tools/serverpod_test_tools.dart';

const _userA = '00000000-0000-4000-8000-000000000041';
const _userB = '00000000-0000-4000-8000-000000000042';
const _url = 'https://www.youtube.com/watch?v=abc123';
const _transcript =
    '[YouTube Video: Ein Tag by DW Deutsch | captions: de, manual]\n'
    'Ich gehe heute in die Stadt und kaufe frisches Brot.';

/// Any fetch means the cache was bypassed.
class _NoFetchIngestion extends IngestionService {
  int fetches = 0;

  @override
  Future<String> ingestUrl(String url, {String? userScopeId}) async {
    fetches++;
    throw StateError('unexpected fetch');
  }
}

LinkAnalysis _analysis({
  String? key,
  String platform = 'youtube',
  String cefr = 'A1',
  DateTime? expiresAt,
  String? vocabulary,
}) {
  final now = DateTime.now();
  return LinkAnalysis(
    normalizedUrl: key ?? _url,
    platform: platform,
    creator: 'DW Deutsch',
    creatorKey: 'dw deutsch',
    title: 'Ein Tag',
    targetLanguage: 'de',
    supportLanguage: 'en',
    cefrLevel: cefr,
    transcript: _transcript,
    contentHash: 'h',
    objectives: const ['Talk about your day'],
    vocabulary:
        vocabulary ??
        jsonEncode([
          {
            'lemma': 'Brot',
            'meaning': 'bread',
            'sourceContext': 'kaufe frisches Brot',
          },
        ]),
    grammar: '[]',
    activities: '[]',
    conversationPlan: '{}',
    createdAt: now,
    lastUsedAt: now,
    expiresAt: expiresAt,
  );
}

void main() {
  withServerpod('Given the shared link analysis cache', (
    sessionBuilder,
    endpoints,
  ) {
    late Session session;
    late _NoFetchIngestion ingestion;
    late LessonImportService service;

    setUp(() {
      session = sessionBuilder.build();
      ingestion = _NoFetchIngestion();
      service = LessonImportService(ingestionService: ingestion);
    });

    Future<Lesson> import(String user, {String cefr = 'A1', String? link}) =>
        service.importSource(
          session,
          userId: user,
          type: 'url',
          title: '',
          targetLanguage: 'de',
          supportLanguage: 'en',
          cefrLevel: cefr,
          url: link ?? _url,
        );

    test('when another learner imported the link then it is served from the '
        'database with no fetch', () async {
      await LinkAnalysis.db.insertRow(session, _analysis());

      // A different spelling of the same video still hits.
      final lesson = await import(_userB, link: 'https://youtu.be/abc123?si=x');

      expect(ingestion.fetches, 0);
      expect(lesson.userId, _userB);
      expect(lesson.vocabulary, contains('Brot'));
      final source = await Source.db.findById(session, lesson.sourceId);
      expect(source!.platform, 'youtube');
      expect(source.creator, 'DW Deutsch');
      final row = await LinkAnalysis.db.findFirstRow(session);
      expect(row!.hitCount, 1);
    });

    test('when another learner pasted the same text then it is served from '
        'the database, whatever the spacing and case', () async {
      const text =
          'Ich gehe heute in die Stadt und kaufe frisches Brot, weil ich Hunger habe.';
      final hash = sha256.convert(utf8.encode(text.toLowerCase())).toString();
      await LinkAnalysis.db.insertRow(
        session,
        _analysis(key: 'content:$hash', platform: 'text')
          ..transcript = text
          ..vocabulary = jsonEncode([
            {
              'lemma': 'Brot',
              'meaning': 'bread',
              'sourceContext': 'kaufe frisches Brot',
            },
          ]),
      );

      final lesson = await service.importSource(
        session,
        userId: _userB,
        type: 'text',
        title: 'Mein Text',
        targetLanguage: 'de',
        supportLanguage: 'en',
        cefrLevel: 'A1',
        rawContent:
            '  ICH gehe heute in die Stadt und kaufe frisches Brot,\n'
            'weil ich Hunger habe. ',
      );

      expect(lesson.userId, _userB);
      final source = await Source.db.findById(session, lesson.sourceId);
      expect(source!.type, 'text');
      expect(source.url, isNull);
      expect(source.platform, 'text');
      expect(source.title, 'Mein Text');
    });

    test('when a long page yields only one grammar pattern then it is still '
        'shared, so the link is not paid for again', () async {
      final longText = '$_transcript ${'Das Wetter ist heute schön. ' * 100}';
      await LinkAnalysis.db.insertRow(
        session,
        _analysis()
          ..transcript = longText
          ..vocabulary = jsonEncode([
            for (var i = 0; i < 8; i++)
              {
                'lemma': 'Wort$i',
                'meaning': 'word $i',
                'sourceContext': 'Das Wetter ist heute schön',
              },
          ])
          ..grammar = jsonEncode([
            {
              'concept': 'Word order',
              'explanation': 'Verb second',
              'sourceSentence': 'Das Wetter ist heute schön.',
            },
          ]),
      );

      final lesson = await import(_userB);

      expect(ingestion.fetches, 0);
      expect(lesson.userId, _userB);
    });

    test('when the analysis expired then it is not served', () async {
      await LinkAnalysis.db.insertRow(
        session,
        _analysis(expiresAt: DateTime.now().subtract(const Duration(days: 1))),
      );
      // The stored transcript is also skipped, so a fetch is attempted.
      await expectLater(import(_userA), throwsA(anything));
      expect(ingestion.fetches, 1);
    });

    test('when only the level differs then the stored transcript is reused '
        'without a fetch', () async {
      await LinkAnalysis.db.insertRow(session, _analysis(cefr: 'A1'));
      // No AI keys are configured, so compilation fails after the transcript
      // was read from the database rather than fetched.
      await expectLater(import(_userA, cefr: 'B1'), throwsA(anything));
      expect(ingestion.fetches, 0);
    });

    test('when the stored lesson is not backed by the transcript then it is '
        'not served', () async {
      await LinkAnalysis.db.insertRow(
        session,
        _analysis(
          vocabulary: jsonEncode([
            {'lemma': 'Auto', 'meaning': 'car', 'sourceContext': 'nicht da'},
          ]),
        ),
      );
      await expectLater(import(_userA), throwsA(anything));
    });
  });
}
