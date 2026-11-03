import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:talkloom_server/src/generated/protocol.dart';
import 'package:talkloom_server/src/sources/import_job_runner.dart';
import 'package:talkloom_server/src/sources/lesson_import_service.dart';

import 'test_tools/serverpod_test_tools.dart';

const _userA = '00000000-0000-4000-8000-000000000031';
const _userB = '00000000-0000-4000-8000-000000000032';

/// Walks the real stage sequence without fetching or calling an AI provider.
class _FakeImportService extends LessonImportService {
  _FakeImportService({this.failWith});
  final Object? failWith;

  @override
  Future<Lesson> importSource(
    Session session, {
    required String userId,
    required String type,
    required String title,
    required String targetLanguage,
    required String supportLanguage,
    required String cefrLevel,
    String? url,
    String? rawContent,
    ImportStageCallback? onStage,
  }) async {
    await onStage?.call(ImportStage.fetching);
    await onStage?.call(ImportStage.transcript, sourceId: 77);
    await onStage?.call(ImportStage.compiling, sourceId: 77);
    if (failWith != null) throw failWith!;
    await onStage?.call(ImportStage.validating, sourceId: 77);
    return Lesson(
      id: 88,
      userId: userId,
      sourceId: 77,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      objectives: const [],
      vocabulary: '[]',
      grammar: '[]',
      activities: '[]',
      conversationPlan: '{}',
      createdAt: DateTime.now(),
    );
  }
}

void main() {
  withServerpod(
    'Given background import jobs',
    (sessionBuilder, endpoints) {
      final userA = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          _userA,
          const {},
        ),
      );
      final userB = sessionBuilder.copyWith(
        authentication: AuthenticationOverride.authenticationInfo(
          _userB,
          const {},
        ),
      );

      Future<ImportJob> startText(TestSessionBuilder who) =>
          endpoints.ingestion.startImport(
            who,
            'text',
            'Mein Text',
            'de',
            'en',
            'A1',
            null,
            'Ich lerne jeden Tag ein bisschen Deutsch.',
          );

      test(
        'when unauthenticated then starting an import is rejected',
        () async {
          await expectLater(
            startText(sessionBuilder),
            throwsA(isA<ServerpodUnauthenticatedException>()),
          );
        },
      );

      test(
        'when starting an import then a queued job returns at once',
        () async {
          final job = await startText(userA);
          expect(job.id, isNotNull);
          expect(job.stage, ImportStage.queued);
          // Owner and pasted content are server-only and never serialized.
          expect(job.toJsonForProtocol().containsKey('userId'), isFalse);
          expect(job.toJsonForProtocol().containsKey('rawContent'), isFalse);
        },
      );

      test('when the link targets a private address then it is refused '
          'before anything is queued', () async {
        await expectLater(
          endpoints.ingestion.startImport(
            userA,
            'url',
            '',
            'de',
            'en',
            'A1',
            'http://127.0.0.1:8080/admin',
            null,
          ),
          throwsA(
            isA<ImportException>().having(
              (e) => e.code,
              'code',
              'unsupported_link',
            ),
          ),
        );
        final jobs = await ImportJob.db.find(
          sessionBuilder.build(),
          where: (t) => t.url.equals('http://127.0.0.1:8080/admin'),
        );
        expect(jobs, isEmpty);
      });

      test('when user B reads user A\'s job then it is not found', () async {
        final job = await startText(userA);
        expect(
          await endpoints.ingestion.getImportJob(userA, job.id!),
          isNotNull,
        );
        expect(await endpoints.ingestion.getImportJob(userB, job.id!), isNull);
      });

      test('when user B streams user A\'s job then the stream fails', () async {
        final job = await startText(userA);
        await expectLater(
          endpoints.ingestion.watchImportJob(userB, job.id!),
          emitsError(
            isA<ImportException>().having((e) => e.code, 'code', 'not_found'),
          ),
        );
      });

      test(
        'when the job runs then the owner streams every stage to saved',
        () async {
          final job = await startText(userA);
          final stream = endpoints.ingestion.watchImportJob(userA, job.id!);
          final stages = stream.map((p) => p.stage).toList();
          await flushEventQueue();

          await ImportJobRunner(
            service: _FakeImportService(),
          ).run(sessionBuilder.build(), job.id!);

          expect(await stages, [
            ImportStage.queued,
            ImportStage.fetching,
            ImportStage.transcript,
            ImportStage.compiling,
            ImportStage.validating,
            ImportStage.saved,
          ]);
          final done = await endpoints.ingestion.getImportJob(userA, job.id!);
          expect(done!.stage, ImportStage.saved);
          expect(done.sourceId, 77);
          expect(done.lessonId, 88);
          final row = await ImportJob.db.findById(
            sessionBuilder.build(),
            job.id!,
          );
          expect(row!.rawContent, isNull);
        },
      );

      test('when a finished job is streamed then it reports the final state '
          'and closes', () async {
        final job = await startText(userA);
        await ImportJobRunner(
          service: _FakeImportService(),
        ).run(sessionBuilder.build(), job.id!);
        final progress = await endpoints.ingestion
            .watchImportJob(userA, job.id!)
            .toList();
        expect(progress.map((p) => p.stage), [ImportStage.saved]);
      });

      test(
        'when compilation fails then the job fails with a safe message',
        () async {
          final job = await startText(userA);
          await ImportJobRunner(
            service: _FakeImportService(
              failWith: Exception('provider 500: secret-key-123'),
            ),
          ).run(sessionBuilder.build(), job.id!);
          final failed = await endpoints.ingestion.getImportJob(userA, job.id!);
          expect(failed!.stage, ImportStage.failed);
          expect(failed.errorCode, 'compile_failed');
          expect(failed.sourceId, 77);
          expect(failed.errorMessage, isNot(contains('secret')));
          expect(failed.errorMessage, contains('saved the source transcript'));
        },
      );

      test(
        'when an import exception is raised then its code reaches the job',
        () async {
          final job = await startText(userA);
          await ImportJobRunner(
            service: _FakeImportService(
              failWith: ImportException(code: 'blocked', message: 'Blocked.'),
            ),
          ).run(sessionBuilder.build(), job.id!);
          final failed = await endpoints.ingestion.getImportJob(userA, job.id!);
          expect(failed!.errorCode, 'blocked');
          expect(failed.errorMessage, 'Blocked.');
        },
      );

      test('when a finished job is run again then nothing changes', () async {
        final job = await startText(userA);
        final runner = ImportJobRunner(service: _FakeImportService());
        await runner.run(sessionBuilder.build(), job.id!);
        await ImportJobRunner(
          service: _FakeImportService(failWith: Exception('x')),
        ).run(sessionBuilder.build(), job.id!);
        final done = await endpoints.ingestion.getImportJob(userA, job.id!);
        expect(done!.stage, ImportStage.saved);
      });
    },
    // The progress stream and the job runner use the database concurrently,
    // which per-test rollback transactions do not allow. Each group still gets
    // its own ephemeral database.
    rollbackDatabase: RollbackDatabase.disabled,
  );
}
