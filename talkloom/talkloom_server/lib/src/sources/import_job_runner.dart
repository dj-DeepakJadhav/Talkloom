import 'dart:io' show stderr;

import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'lesson_import_service.dart';

/// Runs one [ImportJob] and publishes each stage to the job's channel.
///
/// Kept apart from the Future Call so tests can drive it with a session.
class ImportJobRunner {
  ImportJobRunner({LessonImportService? service})
    : _service = service ?? LessonImportService();

  final LessonImportService _service;

  /// Server-event channel carrying [ImportJobProgress] for [jobId]. Only the
  /// owner-checked stream endpoint subscribes to it.
  static String channel(int jobId) => 'import-job-$jobId';

  static ImportJobProgress progressOf(ImportJob job) => ImportJobProgress(
    jobId: job.id!,
    stage: job.stage,
    sourceId: job.sourceId,
    lessonId: job.lessonId,
    errorCode: job.errorCode,
    errorMessage: job.errorMessage,
  );

  /// Persists [job] and notifies stream listeners.
  static Future<ImportJob> publish(Session session, ImportJob job) async {
    job.updatedAt = DateTime.now();
    final saved = await ImportJob.db.updateRow(session, job);
    await session.messages.postMessage(channel(saved.id!), progressOf(saved));
    return saved;
  }

  /// Idempotent: a job that already finished is left alone, so a retried or
  /// duplicated Future Call never compiles twice.
  Future<void> run(Session session, int jobId) async {
    var job = await ImportJob.db.findById(session, jobId);
    if (job == null || ImportStage.isTerminal(job.stage)) return;

    try {
      final lesson = await _service.importSource(
        session,
        userId: job.userId!,
        type: job.type,
        title: job.title,
        targetLanguage: job.targetLanguage,
        supportLanguage: job.supportLanguage,
        cefrLevel: job.cefrLevel,
        url: job.url,
        rawContent: job.rawContent,
        onStage: (stage, {sourceId}) async {
          job!
            ..stage = stage
            ..sourceId = sourceId ?? job!.sourceId;
          job = await publish(session, job!);
        },
      );
      job!
        ..stage = ImportStage.saved
        ..sourceId = lesson.sourceId
        ..lessonId = lesson.id
        // The pasted content has served its purpose; do not keep a copy.
        ..rawContent = null;
      await publish(session, job!);
    } catch (error, stackTrace) {
      session.log(
        'Import job $jobId failed: ${error.runtimeType}',
        level: LogLevel.warning,
        exception: error,
        stackTrace: stackTrace,
      );
      // Serverpod's session log goes to the database, not stdout, so Render's
      // Logs tab never shows why an import failed. Print a short, token-masked
      // line as well.
      // Only provider/pipeline errors are safe to quote; parse errors such as
      // FormatException echo a slice of the learner's pasted text.
      final detail = (error is StateError || error is ImportException)
          ? error
                .toString()
                .replaceAll(RegExp(r'[A-Za-z0-9_\-]{24,}'), '***')
                .replaceAll(RegExp(r'\s+'), ' ')
          : '';
      stderr.writeln(
        'Import job $jobId failed (stage ${job!.stage}): '
        '${error.runtimeType}'
        '${detail.isEmpty ? '' : ': ${detail.length > 300 ? detail.substring(0, 300) : detail}'}',
      );
      final (code, message) = _explain(
        error,
        transcriptSaved: job!.sourceId != null,
      );
      job!
        ..stage = ImportStage.failed
        ..errorCode = code
        ..errorMessage = message
        ..rawContent = null;
      await publish(session, job!);
    }
  }

  /// Learner-safe failure text; provider internals never reach the client.
  static (String, String) _explain(
    Object error, {
    required bool transcriptSaved,
  }) {
    if (error is ImportException) return (error.code, error.message);
    if (error is ArgumentError) {
      return (
        'no_text',
        error.message?.toString() ??
            'Could not read any usable text from this source.',
      );
    }
    return (
      'compile_failed',
      transcriptSaved
          ? 'We saved the source transcript, but could not prepare a complete '
                'lesson. Try again; the source will not need to be reread.'
          : 'Talkloom could not prepare this source. Try again, or paste the text.',
    );
  }
}
