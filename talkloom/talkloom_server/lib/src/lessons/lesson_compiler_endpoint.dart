import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_idp_server/core.dart';
import '../generated/protocol.dart';
import '../services/dual_ai_compiler_service.dart';
import '../services/tavily_service.dart';

class LessonCompilerEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.authUserId;
    if (authUserId == null) {
      throw StateError('Sign in before creating a lesson.');
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
    if (sourceId != null && sourceId < 0) {
      throw ArgumentError.value(
        sourceId,
        'sourceId',
        'Must be a positive source id.',
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

    final nebiusApiKey = session.serverpod.getPassword('nebiusApiKey') ?? '';
    final geminiApiKey = session.serverpod.getPassword('geminiApiKey') ?? '';
    final nvidiaApiKey = session.serverpod.getPassword('nvidiaApiKey') ?? '';
    final groqApiKey = session.serverpod.getPassword('groqApiKey') ?? '';
    final aiProviderSetting = session.serverpod.getPassword('aiProvider');
    final provider = AiProvider.fromSetting(aiProviderSetting);

    final tavilyApiKey = session.serverpod.getPassword('tavilyApiKey') ?? '';
    final tavilyService = TavilyService(apiKey: tavilyApiKey);
    final grounding = await tavilyService.groundTopic(
      topic: sourceTitle,
      targetLanguage: targetLanguage,
      contextSnippet: rawText.length > 200
          ? rawText.substring(0, 200)
          : rawText,
    );

    final compiler = DualLessonCompilerService(
      provider: provider,
      geminiApiKey: geminiApiKey,
      nebiusApiKey: nebiusApiKey,
      nvidiaApiKey: nvidiaApiKey,
      groqApiKey: groqApiKey,
    );

    final lessonDsl = await compiler.compileLesson(
      sourceTitle: sourceTitle,
      rawText: rawText,
      targetLanguage: targetLanguage,
      supportLanguage: supportLanguage,
      estimatedLevel: estimatedLevel,
      grounding: grounding,
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
