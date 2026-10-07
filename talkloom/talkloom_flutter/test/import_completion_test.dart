import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:talkloom_flutter/domain/learning_session.dart';

void main() {
  test(
    'ready status opens saved data even while original request is pending',
    () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      final pending = Completer<void>();
      final lesson = Lesson(
        id: 1,
        sourceId: 2,
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
      server.listen((request) async {
        try {
          await request.drain<void>();
          request.response.headers.contentType = ContentType.json;
          if (request.uri.path.endsWith('processSourceAndCompile')) {
            await pending.future;
            request.response.write(jsonEncode(lesson.toJson()));
          } else if (request.uri.path.endsWith('getImportStatus')) {
            request.response.write(
              jsonEncode(jsonEncode({'stage': 'ready', 'sourceId': 2})),
            );
          } else {
            request.response.write(jsonEncode(lesson.toJson()));
          }
          await request.response.close();
        } catch (_) {
          /* The held request is closed by test teardown. */
        }
      });
      final client = Client('http://127.0.0.1:${server.port}/');
      try {
        final result = await LessonRepository(client)
            .compileFromUrl(
              session: LearningSession.guestDefault(),
              title: '',
              url: 'https://www.youtube.com/watch?v=mNX1wpIQ4Uk',
            )
            .timeout(const Duration(seconds: 8));
        expect(result.sourceId, 2);
        expect(pending.isCompleted, isFalse);
      } finally {
        pending.complete();
        client.close();
        await server.close(force: true);
      }
    },
  );
}
