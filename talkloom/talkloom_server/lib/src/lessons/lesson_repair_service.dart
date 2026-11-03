import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/dual_ai_compiler_service.dart';
import '../sources/content_hygiene_service.dart';

/// Finds saved lessons with the structural defects the compiler gates now
/// reject (dirty lemmas, tautological grammar, junk builder tokens).
///
/// Detection reuses [DualLessonCompilerService.validateDslShape], so the
/// definition of "broken" can never drift from what new compiles enforce.
/// Read-only: repairing (recompiling) is a separate, quota-counted step.
abstract final class LessonRepairService {
  /// The first defect code, or null when the lesson passes current gates.
  /// [session] is optional so plain unit tests can audit without a server.
  static String? audit(Session? session, Lesson lesson) {
    // Machine junk baked into saved JSON (entities, subtitle CSS) is a
    // defect even when the shape validates.
    final combined =
        '${lesson.vocabulary} ${lesson.grammar} ${lesson.activities}';
    if (ContentHygieneService.scanText(combined).isNotEmpty) {
      session?.log(
        'Lesson audit: lesson ${lesson.id} defective (dirty_lesson_text)',
      );
      return 'dirty_lesson_text';
    }
    List<Map<String, dynamic>> decode(String raw) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) return const [];
        return decoded
            .whereType<Map>()
            .map((m) => Map<String, dynamic>.from(m))
            .toList();
      } catch (_) {
        return const [];
      }
    }

    Map<String, dynamic> decodeMap(String raw) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! Map) return const {};
        return Map<String, dynamic>.from(decoded);
      } catch (_) {
        return const {};
      }
    }

    try {
      DualLessonCompilerService(metaApiKey: '').validateDslShape({
        'objectives': lesson.objectives,
        'vocabulary': decode(lesson.vocabulary),
        'grammar': decode(lesson.grammar),
        'activities': decode(lesson.activities),
        'conversation': decodeMap(lesson.conversationPlan),
      });
      return null;
    } on LessonDslValidationException catch (e) {
      session?.log(
        'Lesson audit: lesson ${lesson.id} defective (${e.code})',
      );
      return e.code;
    } catch (_) {
      return 'unreadable_lesson';
    }
  }
}
