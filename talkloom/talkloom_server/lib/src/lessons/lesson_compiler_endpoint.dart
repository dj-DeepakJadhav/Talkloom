import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/dual_ai_compiler_service.dart';
import '../sources/target_language_guard.dart';
import '../usage/ai_quota_service.dart';

class LessonCompilerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.userIdentifier;
    if (authUserId == null) {
      throw StateError('Sign in to create a lesson.');
    }
    return authUserId.toString();
  }

  /// Compiles raw source text or structured input into a Lesson DSL object
  /// and saves it as a Serverpod Lesson entity.
  Future<Lesson> compileLesson(
    Session session, {
    required String sourceTitle,
    required String rawText,
    required String targetLanguage,
    required String supportLanguage,
    required String estimatedLevel,
    int? sourceId,
  }) async {
    final userId = _requireUserId(session);
    if (rawText.trim().isEmpty || rawText.length > 200000) {
      throw ArgumentError(
        'Source text must contain between 1 and 200,000 characters.',
      );
    }
    // Validate before charging quota: rejections must not burn allowance.
    TargetLanguageGuard.checkText(
      text: rawText,
      targetLanguage: targetLanguage,
    );
    await AiQuotaService.consume(session, 'import');
    if (sourceId != null && sourceId < 0) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'The selected source is not valid. Choose it from your learning content.',
      );
    }
    if (sourceId != null && sourceId > 0) {
      final source = await Source.db.findById(session, sourceId);
      if (source == null) {
        throw StateError('The selected source no longer exists.');
      }
      if (source.userId != userId) {
        throw StateError('You do not have access to the selected source.');
      }
    }

    final metaApiKey = session.serverpod.getPassword('metaApiKey') ?? '';

    final compiler = DualLessonCompilerService(metaApiKey: metaApiKey);

    final lessonDsl = await compiler.compileLesson(
      sourceTitle: sourceTitle,
      rawText: rawText,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      estimatedLevel: estimatedLevel,
    );

    int actualSourceId = sourceId ?? 0;
    if (actualSourceId == 0) {
      final savedSource = await Source.db.insertRow(
        session,
        Source(
          userId: userId,
          type: 'raw_text',
          url: null,
          rawText: rawText,
          title: sourceTitle,
          targetLanguage: targetLanguage,
          cefrLevel: estimatedLevel,
          createdAt: DateTime.now(),
        ),
      );
      actualSourceId = savedSource.id!;
    }

    return await Lesson.db.insertRow(
      session,
      Lesson(
        userId: userId,
        sourceId: actualSourceId,
        targetLanguage: targetLanguage,
        supportLanguage: supportLanguage,
        objectives:
            (lessonDsl['objectives'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        vocabulary: jsonEncode(lessonDsl['vocabulary'] ?? const []),
        grammar: jsonEncode(lessonDsl['grammar'] ?? const []),
        activities: jsonEncode(lessonDsl['activities'] ?? const []),
        conversationPlan: jsonEncode(lessonDsl['conversation'] ?? const {}),
        createdAt: DateTime.now(),
      ),
    );
  }
}
