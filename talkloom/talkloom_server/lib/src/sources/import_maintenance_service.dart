import 'dart:convert';

import 'package:serverpod/serverpod.dart';
import '../generated/future_calls.dart';
import '../generated/protocol.dart';
import '../knowledge/concept_canonical_service.dart';
import 'content_hygiene_service.dart';
import 'import_job_runner.dart';
import 'lesson_import_service.dart';

/// Agentic maintenance loop for background imports.
///
/// Runs on a recurring Future Call (see `ImportMaintenanceFutureCall`):
/// finds jobs stuck in a non-terminal stage, retries them once by
/// re-scheduling the compile call, and fails them with a learner-safe
/// message when they stay stuck. Every action is logged for Insights and
/// published on the job's progress channel so open streams close.
class ImportMaintenanceService {
  static const staleAfter = Duration(minutes: 30);
  static const maxAttempts = 2;

  /// Jobs stuck longer than [staleAfter] in a non-terminal stage.
  static bool isStale(ImportJob job, DateTime now) =>
      !ImportStage.isTerminal(job.stage) &&
      now.difference(job.updatedAt) > staleAfter;

  /// One sweep. Returns (retried, failed).
  Future<({int retried, int failed})> sweep(Session session) async {
    final now = DateTime.now();
    final cutoff = now.subtract(staleAfter);
    final stuck = await ImportJob.db.find(
      session,
      where: (t) =>
          (t.updatedAt < cutoff) &
          (t.stage.notEquals(ImportStage.saved)) &
          (t.stage.notEquals(ImportStage.failed)),
      limit: 100,
    );
    var retried = 0;
    var failed = 0;
    for (final job in stuck) {
      if (job.id == null) continue;
      final age = now.difference(job.updatedAt);
      final attempts = _attempts(job);
      if (attempts < maxAttempts && age < staleAfter * 4) {
        job
          ..stage = ImportStage.queued
          ..updatedAt = now
          ..errorCode = null
          ..errorMessage = null;
        await ImportJob.db.updateRow(session, job);
        await session.messages.postMessage(
          ImportJobRunner.channel(job.id!),
          ImportJobRunner.progressOf(job),
        );
        await session.serverpod.futureCalls
            .callWithDelay(
              Duration.zero,
              identifier: 'import-job-${job.id}',
            )
            .importJob
            .compile(job.id!);
        retried++;
        session.log(
          'Import maintenance retried job ${job.id} '
          '(stage=${job.stage} age=${age.inMinutes}m)',
        );
      } else {
        job
          ..stage = ImportStage.failed
          ..errorCode = 'timeout'
          ..errorMessage = 'This import got stuck and was stopped. Try again.'
          ..rawContent = null
          ..updatedAt = now;
        await ImportJobRunner.publish(session, job);
        failed++;
        session.log(
          'Import maintenance failed stale job ${job.id} '
          '(age=${age.inMinutes}m)',
          level: LogLevel.warning,
        );
      }
    }
    if (retried + failed > 0) {
      session.log(
        'Import maintenance sweep: retried=$retried failed=$failed '
        'checked=${stuck.length}',
      );
    }
    await auditKnowledge(session);
    return (retried: retried, failed: failed);
  }

  /// Consistency audit for the knowledge loop: groups recent lessons by
  /// canonical keys and logs concepts whose teachings diverge (same word
  /// with different meanings, same grammar with different labels).
  /// Read-only; never rewrites learner data.
  Future<void> auditKnowledge(Session session) async {
    try {
      final lessons = await Lesson.db.find(
        session,
        orderBy: (t) => t.createdAt.desc(),
        limit: 200,
      );
      final meanings = <String, Set<String>>{};
      final labels = <String, Set<String>>{};
      for (final lesson in lessons) {
        for (final item in _decodeJsonList(lesson.vocabulary)) {
          final lemma = item['lemma']?.toString() ?? '';
          if (lemma.trim().isEmpty) continue;
          final id = canonicalVocabId(lesson.targetLanguage, lemma);
          final meaning = item['meaning']?.toString().trim() ?? '';
          if (meaning.isNotEmpty) {
            meanings.putIfAbsent(id, () => {}).add(meaning.toLowerCase());
          }
        }
        for (final item in _decodeJsonList(lesson.grammar)) {
          final concept = item['concept']?.toString() ?? '';
          if (concept.trim().isEmpty) continue;
          final key = canonicalGrammarKey(concept);
          final label = item['label']?.toString().trim().isNotEmpty ?? false
              ? item['label'].toString().trim().toLowerCase()
              : concept.trim().toLowerCase();
          labels.putIfAbsent(key, () => {}).add(label);
        }
      }
      final divergentVocab = meanings.entries
          .where((e) => e.value.length > 1)
          .length;
      final divergentGrammar = labels.entries
          .where((e) => e.value.length > 1)
          .length;
      if (divergentVocab + divergentGrammar > 0) {
        session.log(
          'Knowledge audit: $divergentVocab vocab ids and '
          '$divergentGrammar grammar keys have divergent teachings '
          'across ${lessons.length} recent lessons.',
        );
      }
      await auditHygiene(session);
    } catch (e) {
      session.log('Knowledge audit skipped: $e', level: LogLevel.warning);
    }
  }

  /// Hygiene loop: scans recent sources and lessons for reader shells,
  /// subtitle CSS, raw entities and template junk. Read-only; findings go
  /// to Insights so parser fixes can be verified ("did the CSS signature
  /// disappear after the VTT fix?"), and the one-tap Repair flow in the app
  /// is what heals the flagged rows.
  static Future<void> auditHygiene(Session session) async {
    try {
      final sources = await Source.db.find(
        session,
        orderBy: (t) => t.createdAt.desc(),
        limit: 200,
      );
      final counts = <String, int>{};
      var poisonedSources = 0;
      for (final source in sources) {
        final defects = ContentHygieneService.scanText(source.rawText);
        if (defects.isEmpty) continue;
        for (final defect in defects) {
          counts[defect] = (counts[defect] ?? 0) + 1;
        }
        if (ContentHygieneService.isPoisoned(source.rawText)) {
          poisonedSources++;
        }
      }
      final lessons = await Lesson.db.find(
        session,
        orderBy: (t) => t.createdAt.desc(),
        limit: 200,
      );
      var dirtyLessons = 0;
      for (final lesson in lessons) {
        final combined =
            '${lesson.vocabulary} ${lesson.grammar} ${lesson.activities}';
        if (ContentHygieneService.scanText(combined).isNotEmpty) {
          dirtyLessons++;
        }
      }
      if (counts.isNotEmpty || dirtyLessons > 0) {
        session.log(
          'Hygiene audit: sources=$counts poisonedShells=$poisonedSources '
          'dirtyLessons=$dirtyLessons '
          '(heal via Repair lessons in the app)',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      session.log('Hygiene audit skipped: $e', level: LogLevel.warning);
    }
  }

  static List<Map<String, dynamic>> _decodeJsonList(String raw) {
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

  /// Attempt count carried in the job row without a schema change:
  /// a retry clears the error fields, a stuck failure keeps them.
  static int _attempts(ImportJob job) => job.errorCode == null ? 1 : 2;
}
