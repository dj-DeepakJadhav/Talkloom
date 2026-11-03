import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../knowledge/concept_canonical_service.dart';
import '../sources/lesson_import_service.dart';
import '../usage/ai_quota_service.dart';
import 'lesson_repair_service.dart';

/// Combined vocabulary + grammar across all of one learner's lessons.
///
/// Per-video rows stay the source of truth (each lesson keeps its own
/// vocabulary/grammar JSON). This endpoint aggregates them on read using
/// canonical keys, so a short video and a long video teaching the same
/// grammar merge into one entry with references to every lesson it came
/// from. Filtering and sorting happen over the merged groups, not over
/// one-to-one lesson rows.
class KnowledgeEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  String _requireUserId(Session session) {
    final authUserId = session.authenticated?.userIdentifier;
    if (authUserId == null) {
      throw StateError('Sign in to access your learning content.');
    }
    return authUserId.toString();
  }

  List<Map<String, dynamic>> _decodeList(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is List
          ? decoded
                .whereType<Map>()
                .map((m) => Map<String, dynamic>.from(m))
                .toList()
          : const [];
    } catch (_) {
      return const [];
    }
  }

  /// Merged vocabulary and grammar for [targetLanguage].
  ///
  /// Each entry carries `sources` (lessonId/sourceId/title per occurrence)
  /// so the learner can jump back to the video it came from. [query]
  /// filters by lemma/concept substring; [sort] is `recent` (default),
  /// `alpha`, or `coverage` (most sources first).
  Future<String> getCombinedKnowledge(
    Session session,
    String targetLanguage, {
    String query = '',
    String sort = 'recent',
    int limit = 200,
  }) async {
    final userId = _requireUserId(session);
    final capped = limit.clamp(1, 500);
    final lessons = await Lesson.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: 1000,
    );
    if (lessons.isEmpty) {
      return jsonEncode({'vocabulary': [], 'grammar': []});
    }
    final sourceIds = lessons.map((l) => l.sourceId).toSet();
    final sources = await Source.db.find(
      session,
      where: (t) =>
          t.id.inSet(sourceIds) &
          t.userId.equals(userId) &
          t.isArchived.equals(false),
    );
    final byId = {for (final s in sources) s.id: s};
    final visible = lessons.where((l) => byId.containsKey(l.sourceId)).toList();
    final titles = {for (final l in visible) l.id: byId[l.sourceId]!.title};

    final vocabAll = <VocabOccurrence>[];
    final grammarAll = <GrammarOccurrence>[];
    for (final lesson in visible) {
      final title = titles[lesson.id] ?? '';
      for (final item in _decodeList(lesson.vocabulary)) {
        final lemma = item['lemma']?.toString() ?? '';
        if (lemma.trim().isEmpty) continue;
        vocabAll.add((
          id: canonicalVocabId(targetLanguage, lemma),
          lemma: lemma.trim(),
          article: item['article']?.toString() ?? '',
          meaning: item['meaning']?.toString() ?? '',
          sourceContext: item['sourceContext']?.toString() ?? '',
          lessonId: lesson.id!,
          sourceId: lesson.sourceId,
          lessonTitle: title,
        ));
      }
      for (final item in _decodeList(lesson.grammar)) {
        final concept = item['concept']?.toString() ?? '';
        if (concept.trim().isEmpty) continue;
        grammarAll.add((
          key: canonicalGrammarKey(concept),
          label: (item['label']?.toString().trim().isNotEmpty ?? false)
              ? item['label'].toString().trim()
              : concept.trim(),
          sourceSentence: item['sourceSentence']?.toString() ?? '',
          explanation: item['explanation']?.toString() ?? '',
          lessonId: lesson.id!,
          sourceId: lesson.sourceId,
          lessonTitle: title,
        ));
      }
    }

    final q = query.trim().toLowerCase();
    final vocabGroups = groupVocab(vocabAll);
    var vocab = vocabGroups.entries
        .map((e) {
          final occ = e.value.occurrences;
          final latest = occ
              .map((o) => o.lessonId)
              .reduce((a, b) => a > b ? a : b);
          return {
            'id': e.key,
            'lemma': e.value.lemma,
            'meanings': occ
                .map((o) => o.meaning)
                .where((m) => m.isNotEmpty)
                .toSet()
                .toList(),
            'articles': occ
                .map((o) => o.article)
                .where((a) => a.isNotEmpty)
                .toSet()
                .toList(),
            'occurrences': occ.length,
            'latestLessonId': latest,
            'sources': occ
                .map(
                  (o) => {
                    'lessonId': o.lessonId,
                    'sourceId': o.sourceId,
                    'title': o.lessonTitle,
                    'context': o.sourceContext,
                  },
                )
                .toList(),
          };
        })
        .where(
          (v) => q.isEmpty || (v['lemma'] as String).toLowerCase().contains(q),
        )
        .toList();

    final grammarGroups = groupGrammar(grammarAll);
    var grammar = grammarGroups.entries
        .map((e) {
          final occ = e.value.occurrences;
          final latest = occ
              .map((o) => o.lessonId)
              .reduce((a, b) => a > b ? a : b);
          return {
            'key': e.key,
            'label': e.value.label,
            'explanations': occ
                .map((o) => o.explanation)
                .where((x) => x.isNotEmpty)
                .toSet()
                .toList(),
            'occurrences': occ.length,
            'latestLessonId': latest,
            'sources': occ
                .map(
                  (o) => {
                    'lessonId': o.lessonId,
                    'sourceId': o.sourceId,
                    'title': o.lessonTitle,
                    'sentence': o.sourceSentence,
                  },
                )
                .toList(),
          };
        })
        .where(
          (g) =>
              q.isEmpty ||
              (g['label'] as String).toLowerCase().contains(q) ||
              (g['key'] as String).contains(q),
        )
        .toList();

    void sortEntries(List<Map<String, dynamic>> list) {
      switch (sort) {
        case 'alpha':
          list.sort(
            (a, b) => (a['lemma'] as String? ?? a['label'] as String)
                .toLowerCase()
                .compareTo(
                  (b['lemma'] as String? ?? b['label'] as String).toLowerCase(),
                ),
          );
        case 'coverage':
          list.sort(
            (a, b) =>
                (b['occurrences'] as int).compareTo(a['occurrences'] as int),
          );
        default:
          list.sort(
            (a, b) => (b['latestLessonId'] as int).compareTo(
              a['latestLessonId'] as int,
            ),
          );
      }
    }

    sortEntries(vocab);
    sortEntries(grammar);
    if (vocab.length > capped) vocab = vocab.sublist(0, capped);
    if (grammar.length > capped) grammar = grammar.sublist(0, capped);
    return jsonEncode({'vocabulary': vocab, 'grammar': grammar});
  }

  /// Repairs the learner's own saved lessons against the current compiler
  /// gates: audits every lesson, recompiles the defective ones from source
  /// (refetching live content for links), and reports per-lesson results.
  /// Capped per call; each repair consumes daily AI quota like an import.
  Future<String> repairMyLessons(
    Session session,
    String targetLanguage, {
    int maxRepairs = 5,
  }) async {
    final userId = _requireUserId(session);
    final lessons = await Lesson.db.find(
      session,
      where: (t) =>
          t.userId.equals(userId) & t.targetLanguage.equals(targetLanguage),
      orderBy: (t) => t.createdAt.desc(),
      limit: 500,
    );
    if (lessons.isEmpty) {
      return jsonEncode({'repaired': [], 'failed': [], 'clean': 0});
    }
    final sourceIds = lessons.map((l) => l.sourceId).toSet();
    final sources = await Source.db.find(
      session,
      where: (t) => t.id.inSet(sourceIds) & t.userId.equals(userId),
    );
    final titles = {for (final s in sources) s.id: s.title};

    final repaired = <Map<String, dynamic>>[];
    final failed = <Map<String, dynamic>>[];
    var clean = 0;
    var repairs = 0;
    final importer = LessonImportService();
    for (final lesson in lessons) {
      final defect = LessonRepairService.audit(session, lesson);
      if (defect == null) {
        clean++;
        continue;
      }
      if (repairs >= maxRepairs.clamp(1, 20)) {
        failed.add({
          'lessonId': lesson.id,
          'sourceId': lesson.sourceId,
          'title': titles[lesson.sourceId] ?? '',
          'reason': 'paused: repair the rest with another run',
        });
        continue;
      }
      repairs++;
      try {
        await AiQuotaService.consume(session, 'import');
        final fresh = await importer.refreshLesson(
          session,
          userId: userId,
          sourceId: lesson.sourceId,
          // Shell rows poison the audit; links rebuild from live content.
          refetch: true,
        );
        repaired.add({
          'lessonId': fresh.id,
          'sourceId': fresh.sourceId,
          'title': titles[lesson.sourceId] ?? '',
          'was': defect,
        });
      } on ImportException catch (e) {
        failed.add({
          'lessonId': lesson.id,
          'sourceId': lesson.sourceId,
          'title': titles[lesson.sourceId] ?? '',
          'reason': _short(e.message),
        });
        // No allowance left: further repairs would fail the same way.
        if (e.code == 'quota_exceeded') break;
      } catch (e) {
        failed.add({
          'lessonId': lesson.id,
          'sourceId': lesson.sourceId,
          'title': titles[lesson.sourceId] ?? '',
          'reason': _short(e.toString()),
        });
      }
    }
    return jsonEncode({
      'repaired': repaired,
      'failed': failed,
      'clean': clean,
    });
  }

  static String _short(String value) {
    final flat = value.replaceAll(RegExp(r'\s+'), ' ');
    return flat.length > 200 ? '${flat.substring(0, 200)}…' : flat;
  }
}
