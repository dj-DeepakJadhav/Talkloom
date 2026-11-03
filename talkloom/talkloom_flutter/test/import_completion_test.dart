import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/core/failure.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:talkloom_flutter/domain/learning_session.dart';

/// Replaces the Serverpod transport with a scripted job and progress stream.
class _ScriptedRepository extends LessonRepository {
  _ScriptedRepository(this.streams) : super(Client('http://127.0.0.1:1/'));

  /// One list of events per subscription; an [Exception] entry is thrown.
  final List<List<Object>> streams;
  int subscriptions = 0;
  int starts = 0;

  @override
  Future<ImportJob> startImportJob({
    required LearningSession session,
    required String type,
    required String title,
    String? url,
    String? rawContent,
  }) async {
    starts++;
    return ImportJob(
      id: 5,
      type: type,
      title: title,
      targetLanguage: 'de',
      supportLanguage: 'en',
      cefrLevel: 'A1',
      url: url,
      stage: 'queued',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Stream<ImportJobProgress> watchImportJob(int jobId) async* {
    for (final event in streams[subscriptions++]) {
      if (event is Exception) throw event;
      yield event as ImportJobProgress;
    }
  }

  @override
  Future<Lesson?> lessonForSource(int sourceId) async => Lesson(
    id: 1,
    sourceId: sourceId,
    userId: 'guest',
    targetLanguage: 'de',
    supportLanguage: 'en',
    objectives: [],
    vocabulary: '[]',
    grammar: '[]',
    activities: '[]',
    conversationPlan: '{}',
    createdAt: DateTime.now(),
  );
}

ImportJobProgress _p(String stage, {int? sourceId, String? code}) =>
    ImportJobProgress(
      jobId: 5,
      stage: stage,
      sourceId: sourceId,
      errorCode: code,
      errorMessage: code == null ? null : 'Server explanation.',
    );

void main() {
  test('pushed stages are reported and the saved lesson is opened', () async {
    final repo = _ScriptedRepository([
      [
        _p('queued'),
        _p('fetching'),
        _p('transcript', sourceId: 2),
        _p('compiling', sourceId: 2),
        _p('validating', sourceId: 2),
        _p('saved', sourceId: 2),
      ],
    ]);
    final stages = <String>[];
    final lesson = await repo.compileFromUrl(
      session: LearningSession.guestDefault(),
      title: '',
      url: 'https://www.youtube.com/watch?v=mNX1wpIQ4Uk',
      onProgress: stages.add,
    );
    expect(lesson.sourceId, 2);
    expect(stages, [
      'queued',
      'queued',
      'fetching',
      'transcript',
      'compiling',
      'validating',
      'saved',
    ]);
  });

  test(
    'a dropped stream reconnects to the same job without re-importing',
    () async {
      final repo = _ScriptedRepository([
        [_p('compiling', sourceId: 2), Exception('socket closed')],
        [_p('saved', sourceId: 2)],
      ]);
      final lesson = await repo.compileFromText(
        session: LearningSession.guestDefault(),
        title: 'Text',
        text: 'Ich lerne Deutsch.',
      );
      expect(lesson.sourceId, 2);
      expect(repo.starts, 1);
      expect(repo.subscriptions, 2);
    },
  );

  test('a failed job surfaces the server explanation', () async {
    final repo = _ScriptedRepository([
      [_p('fetching'), _p('failed', code: 'blocked')],
    ]);
    await expectLater(
      repo.compileFromUrl(
        session: LearningSession.guestDefault(),
        title: '',
        url: 'https://example.com/article',
      ),
      throwsA(
        isA<Failure>()
            .having((f) => f.message, 'message', 'Server explanation.')
            .having((f) => f.title, 'title', 'This site blocks readers'),
      ),
    );
  });
}
