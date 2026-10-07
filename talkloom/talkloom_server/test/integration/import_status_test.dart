import 'dart:convert';
import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod('Import progress', (builder, endpoints) {
    test('reports retrieved, ready, and failed only to the owner', () async {
      final owner = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '00000000-0000-4000-8000-000000000021',
          const {},
        ),
      );
      final other = builder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          '00000000-0000-4000-8000-000000000022',
          const {},
        ),
      );
      const url = 'https://www.youtube.com/watch?v=mNX1wpIQ4Uk';
      final start = DateTime.now().toUtc().subtract(const Duration(seconds: 2));
      final session = owner.build();
      try {
        final source = await Source.db.insertRow(
          session,
          Source(
            userId: '00000000-0000-4000-8000-000000000021',
            type: 'url',
            url: url,
            title: 'Import',
            rawText: 'Retrieved transcript',
            targetLanguage: 'de',
            cefrLevel: 'A1',
            createdAt: DateTime.now(),
          ),
        );
        Future<String> stage(dynamic user) async =>
            (jsonDecode(
                      await endpoints.ingestion.getImportStatus(
                        user,
                        url,
                        'de',
                        start,
                      ),
                    )
                    as Map<String, dynamic>)['stage']
                as String;
        expect(await stage(owner), 'retrieved');
        expect(await stage(other), 'reading');
        source.isArchived = true;
        await Source.db.updateRow(session, source);
        expect(await stage(owner), 'failed');
        await Lesson.db.insertRow(
          session,
          Lesson(
            userId: source.userId,
            sourceId: source.id!,
            targetLanguage: 'de',
            supportLanguage: 'en',
            objectives: [],
            vocabulary: '[]',
            grammar: '[]',
            activities: '[]',
            conversationPlan: '{}',
            createdAt: DateTime.now(),
          ),
        );
        expect(await stage(owner), 'ready');
      } finally {
        await session.close();
      }
    });
  });
}
