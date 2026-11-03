import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';

import 'test_tools/serverpod_test_tools.dart';

const _userA = '00000000-0000-4000-8000-000000000001';
const _userB = '00000000-0000-4000-8000-000000000002';

void main() {
  withServerpod('Lesson compiler ownership boundary', (
    sessionBuilder,
    endpoints,
  ) {
    final userASession = sessionBuilder.copyWith(
      authentication: AuthenticationOverride.authenticationInfo(
        _userA,
        const {},
      ),
    );

    test('rejects unauthenticated lesson compilation', () async {
      await expectLater(
        endpoints.lessonCompiler.compileLesson(
          sessionBuilder,
          sourceTitle: 'Private source',
          rawText: 'Hallo.',
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
        ),
        throwsA(anything),
      );
    });

    test('rejects a foreign source before invoking providers', () async {
      final session = userASession.build();
      late Source foreignSource;
      try {
        foreignSource = await Source.db.insertRow(
          session,
          Source(
            userId: _userB,
            type: 'text',
            rawText: 'Privater Inhalt.',
            title: 'Andere Person',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.utc(2026),
          ),
        );
      } finally {
        await session.close();
      }

      await expectLater(
        endpoints.lessonCompiler.compileLesson(
          userASession,
          sourceTitle: 'Private source',
          rawText: 'Privater Inhalt.',
          targetLanguage: 'de',
          supportLanguage: 'en',
          estimatedLevel: 'A1',
          sourceId: foreignSource.id,
        ),
        throwsA(anything),
      );
    });
  });
}
