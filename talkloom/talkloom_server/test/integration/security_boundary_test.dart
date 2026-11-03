import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _userA = '00000000-0000-4000-8000-000000000001';
const _userB = '00000000-0000-4000-8000-000000000002';

void main() {
  withServerpod('Authenticated content and evidence boundaries', (
    sessionBuilder,
    endpoints,
  ) {
    final userASession = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        _userA,
        const {},
      ),
    );
    final userBSession = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        _userB,
        const {},
      ),
    );

    test('source lists are isolated by authenticated owner', () async {
      final session = userASession.build();
      try {
        final sourceA = await Source.db.insertRow(
          session,
          Source(
            userId: _userA,
            type: 'text',
            rawText: 'A private source owned by user A.',
            title: 'A source',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.utc(2026),
          ),
        );
        final sourceB = await Source.db.insertRow(
          session,
          Source(
            userId: _userB,
            type: 'text',
            rawText: 'A private source owned by user B.',
            title: 'B source',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.utc(2026),
          ),
        );
        await Lesson.db.insertRow(
          session,
          Lesson(
            userId: _userA,
            sourceId: sourceA.id!,
            targetLanguage: 'de',
            supportLanguage: 'en',
            objectives: const [],
            vocabulary: '[]',
            grammar: '[]',
            activities: '[]',
            conversationPlan: '{}',
            createdAt: DateTime.utc(2026),
          ),
        );
        await Lesson.db.insertRow(
          session,
          Lesson(
            userId: _userB,
            sourceId: sourceB.id!,
            targetLanguage: 'de',
            supportLanguage: 'en',
            objectives: const [],
            vocabulary: '[]',
            grammar: '[]',
            activities: '[]',
            conversationPlan: '{}',
            createdAt: DateTime.utc(2026),
          ),
        );
      } finally {
        await session.close();
      }

      final aSources = await endpoints.ingestion.listSources(
        userASession,
        'de',
        limit: 50,
        offset: 0,
      );
      final bSources = await endpoints.ingestion.listSources(
        userBSession,
        'de',
        limit: 50,
        offset: 0,
      );
      expect(aSources.map((source) => source.title), ['A source']);
      expect(bSources.map((source) => source.title), ['B source']);
      final aLessons = await endpoints.ingestion.listLessons(
        userASession,
        'de',
        limit: 50,
        offset: 0,
      );
      final bLessons = await endpoints.ingestion.listLessons(
        userBSession,
        'de',
        limit: 50,
        offset: 0,
      );
      expect(aLessons, hasLength(1));
      expect(bLessons, hasLength(1));
      expect(
        await endpoints.ingestion.getLessonBySourceId(
          userBSession,
          aSources.single.id!,
        ),
        isNull,
      );
      expect(
        await endpoints.ingestion.removeSource(
          userBSession,
          aSources.single.id!,
        ),
        isFalse,
      );
      expect(
        await endpoints.ingestion.removeSource(
          userASession,
          aSources.single.id!,
        ),
        isTrue,
      );
      expect(
        await endpoints.ingestion.getLessonBySourceId(
          userASession,
          aSources.single.id!,
        ),
        isNull,
      );
      expect(
        await endpoints.ingestion.listSources(
          userASession,
          'de',
          limit: 50,
          offset: 0,
        ),
        isEmpty,
      );
      expect(
        await endpoints.ingestion.listSources(
          userBSession,
          'de',
          limit: 50,
          offset: 0,
        ),
        hasLength(1),
      );
    });

    test('client mastery and spontaneity flags are never trusted', () async {
      final session = userASession.build();
      try {
        final source = await Source.db.insertRow(
          session,
          Source(
            userId: _userA,
            type: 'text',
            rawText: 'Hallo!',
            title: 'Greeting',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.utc(2026),
          ),
        );
        await Lesson.db.insertRow(
          session,
          Lesson(
            userId: _userA,
            sourceId: source.id!,
            targetLanguage: 'de',
            supportLanguage: 'en',
            objectives: const [],
            vocabulary: '[{"lemma":"hallo","meaning":"hello"}]',
            grammar: '[]',
            activities: '[]',
            conversationPlan: '{}',
            createdAt: DateTime.utc(2026),
          ),
        );
      } finally {
        await session.close();
      }

      final event = await endpoints.learnerState.recordEvidenceEvent(
        userASession,
        targetLanguage: 'de',
        itemId: 'de:hallo',
        activityType: 'flashcard',
        supportLevel: 'none',
        spontaneous: true,
        correct: true,
      );

      expect(event.correct, isFalse);
      expect(event.spontaneous, isFalse);
      expect(event.itemId, 'hallo');
      expect(
        await endpoints.learnerState.getLearnerState(userASession, 'de'),
        isNull,
      );
      expect(
        await endpoints.learnerState.getEvidenceHistory(
          userASession,
          'de',
          limit: 20,
        ),
        hasLength(1),
      );
      expect(
        await endpoints.learnerState.getEvidenceHistory(
          userBSession,
          'de',
          limit: 20,
        ),
        isEmpty,
      );
      await expectLater(
        endpoints.learnerState.recordEvidenceEvent(
          userASession,
          targetLanguage: 'de',
          itemId: 'de:not-in-the-user-lesson',
          activityType: 'flashcard',
          supportLevel: 'none',
          spontaneous: true,
          correct: true,
        ),
        throwsA(anything),
      );
    });

    test(
      'archived URL lessons remain reusable without exposing the original',
      () async {
        const url = 'https://example.com/german-source';
        const rawText =
            'Ich lerne Deutsch. Ich spreche Deutsch. Das ist ein Haus.';
        late final int originalSourceId;
        final ownerSession = userASession.build();
        try {
          final original = await Source.db.insertRow(
            ownerSession,
            Source(
              userId: _userA,
              type: 'url',
              url: url,
              rawText: rawText,
              title: 'Original source',
              targetLanguage: 'de',
              cefrLevel: 'A1',
              isArchived: true,
              createdAt: DateTime.utc(2026),
            ),
          );
          originalSourceId = original.id!;
          await Lesson.db.insertRow(
            ownerSession,
            Lesson(
              userId: _userA,
              sourceId: originalSourceId,
              targetLanguage: 'de',
              supportLanguage: 'en',
              objectives: const ['Talk about learning German'],
              vocabulary:
                  '[{"lemma":"lernen","meaning":"to learn",'
                  '"sourceContext":"Ich lerne Deutsch."}]',
              grammar: '[]',
              activities: '[]',
              conversationPlan: '{}',
              createdAt: DateTime.utc(2026),
            ),
          );
        } finally {
          await ownerSession.close();
        }

        final reusedLesson = await endpoints.ingestion.processSourceAndCompile(
          userBSession,
          'url',
          'Shared German source',
          'de',
          'en',
          'A1',
          url,
          null,
        );
        final reusedSourceSession = userBSession.build();
        late final Source? reusedSource;
        try {
          reusedSource = await Source.db.findById(
            reusedSourceSession,
            reusedLesson.sourceId,
          );
        } finally {
          await reusedSourceSession.close();
        }

        expect(reusedLesson.userId, _userB);
        expect(reusedLesson.sourceId, isNot(originalSourceId));
        expect(reusedSource?.userId, _userB);
        expect(reusedSource?.rawText, rawText);
        expect(
          await endpoints.ingestion.listSources(
            userASession,
            'de',
            limit: 50,
            offset: 0,
          ),
          isEmpty,
        );
        expect(
          await endpoints.ingestion.listSources(
            userBSession,
            'de',
            limit: 50,
            offset: 0,
          ),
          hasLength(1),
        );
      },
    );

    test('unauthenticated calls cannot access user content', () async {
      await expectLater(
        endpoints.ingestion.listSources(
          sessionBuilder,
          'de',
          limit: 50,
          offset: 0,
        ),
        throwsA(anything),
      );
      await expectLater(
        endpoints.learnerState.getLearnerState(sessionBuilder, 'de'),
        throwsA(anything),
      );
    });
  });
}
