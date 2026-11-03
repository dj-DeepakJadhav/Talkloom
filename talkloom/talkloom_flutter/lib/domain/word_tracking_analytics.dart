import 'dart:convert';
import 'package:talkloom_client/talkloom_client.dart';
import 'lesson_content.dart';

enum WordTrackingStatus {
  newWord,
  repeated,
  practiced,
  mastered,
}

@immutable
class TrackedWord {
  const TrackedWord({
    required this.id,
    required this.lemma,
    required this.display,
    required this.meaning,
    this.article = '',
    this.sourceContext = '',
    required this.sourceIds,
    required this.earliestSourceId,
    required this.encounterCount,
    required this.status,
    this.isPracticed = false,
    this.isMastered = false,
  });

  final String id;
  final String lemma;
  final String display;
  final String meaning;
  final String article;
  final String sourceContext;
  final Set<int> sourceIds;
  final int? earliestSourceId;
  final int encounterCount;
  final WordTrackingStatus status;
  final bool isPracticed;
  final bool isMastered;

  bool isNewInSource(int? sourceId) {
    if (sourceId == null) return encounterCount <= 1;
    return earliestSourceId == sourceId || encounterCount <= 1;
  }

  String statusBadgeLabel({int? currentSourceId}) {
    if (isMastered) return 'Mastered';
    if (isPracticed) return 'Practiced';
    if (isNewInSource(currentSourceId)) return 'New';
    return 'Seen $encounterCount×';
  }
}

@immutable
class LexiconAnalytics {
  const LexiconAnalytics({
    required this.totalUniqueWords,
    required this.newWordsCount,
    required this.repeatedWordsCount,
    required this.practicedWordsCount,
    required this.masteredWordsCount,
    required this.totalSourcesCount,
    required this.tier1Count,
    required this.tier2Count,
    required this.tier3Count,
  });

  final int totalUniqueWords;
  final int newWordsCount;
  final int repeatedWordsCount;
  final int practicedWordsCount;
  final int masteredWordsCount;
  final int totalSourcesCount;

  /// 1x encounter (new/fresh words)
  final int tier1Count;

  /// 2-3x encounters (reinforcing)
  final int tier2Count;

  /// 4+ encounters (consolidated)
  final int tier3Count;

  static const empty = LexiconAnalytics(
    totalUniqueWords: 0,
    newWordsCount: 0,
    repeatedWordsCount: 0,
    practicedWordsCount: 0,
    masteredWordsCount: 0,
    totalSourcesCount: 0,
    tier1Count: 0,
    tier2Count: 0,
    tier3Count: 0,
  );
}

@immutable
class WordTrackingAnalytics {
  const WordTrackingAnalytics({
    required this.analytics,
    required this.wordsByLemma,
  });

  final LexiconAnalytics analytics;
  final Map<String, TrackedWord> wordsByLemma;

  TrackedWord? getTrackedWord(VocabularyItem item) {
    final key = item.lemma.trim().toLowerCase();
    return wordsByLemma[key];
  }

  WordTrackingStatus getStatus(VocabularyItem item, {int? sourceId}) {
    final tracked = getTrackedWord(item);
    if (tracked == null) return WordTrackingStatus.newWord;
    if (tracked.isMastered) return WordTrackingStatus.mastered;
    if (tracked.isPracticed) return WordTrackingStatus.practiced;
    if (tracked.isNewInSource(sourceId)) return WordTrackingStatus.newWord;
    return WordTrackingStatus.repeated;
  }

  int getEncounterCount(VocabularyItem item) {
    return getTrackedWord(item)?.encounterCount ?? 1;
  }

  static WordTrackingAnalytics fromData({
    required List<Lesson> lessons,
    LearnerState? learnerState,
    List<WordEvidenceSummary> evidence = const [],
  }) {
    final sortedLessons = List<Lesson>.from(lessons)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    final activeLemmas = <String>{};
    if (learnerState != null) {
      for (final id in learnerState.activeWords) {
        final raw = id.contains(':') ? id.split(':').last : id;
        activeLemmas.add(raw.trim().toLowerCase());
      }
    }

    final evidenceByLemma = <String, WordEvidenceSummary>{};
    for (final summary in evidence) {
      final id = summary.itemId;
      final raw = id.contains(':') ? id.split(':').last : id;
      evidenceByLemma[raw.trim().toLowerCase()] = summary;
    }

    final lemmaSources = <String, Set<int>>{};
    final earliestSource = <String, int>{};
    final lemmaItemMap = <String, VocabularyItem>{};

    for (final lesson in sortedLessons) {
      final sId = lesson.sourceId;
      try {
        final decoded = jsonDecode(lesson.vocabulary);
        if (decoded is! List) continue;
        for (final itemJson in decoded) {
          if (itemJson is! Map<String, dynamic>) continue;
          final item = VocabularyItem.fromJson(itemJson);
          if (item == null) continue;
          final lemma = item.lemma.trim().toLowerCase();
          if (lemma.isEmpty) continue;

          lemmaSources.putIfAbsent(lemma, () => <int>{}).add(sId);
          earliestSource.putIfAbsent(lemma, () => sId);
          lemmaItemMap.putIfAbsent(lemma, () => item);
        }
      } catch (_) {}
    }

    final trackedWords = <String, TrackedWord>{};
    var newCount = 0;
    var repeatedCount = 0;
    var practicedCount = 0;
    var masteredCount = 0;
    var tier1 = 0;
    var tier2 = 0;
    var tier3 = 0;

    for (final entry in lemmaSources.entries) {
      final lemma = entry.key;
      final sources = entry.value;
      final encounterCount = sources.length;
      final sampleItem = lemmaItemMap[lemma];
      if (sampleItem == null) continue;

      final summary = evidenceByLemma[lemma];
      final isMastered = summary?.mastered ?? false;
      final isPracticed =
          (summary?.eligibleCorrectTurns ?? 0) > 0 ||
          activeLemmas.contains(lemma);

      final WordTrackingStatus status;
      if (isMastered) {
        status = WordTrackingStatus.mastered;
        masteredCount++;
      } else if (isPracticed) {
        status = WordTrackingStatus.practiced;
        practicedCount++;
      } else if (encounterCount > 1) {
        status = WordTrackingStatus.repeated;
        repeatedCount++;
      } else {
        status = WordTrackingStatus.newWord;
        newCount++;
      }

      if (encounterCount == 1) {
        tier1++;
      } else if (encounterCount <= 3) {
        tier2++;
      } else {
        tier3++;
      }

      trackedWords[lemma] = TrackedWord(
        id: sampleItem.id,
        lemma: sampleItem.lemma,
        display: sampleItem.display,
        meaning: sampleItem.meaning,
        article: sampleItem.article,
        sourceContext: sampleItem.sourceContext,
        sourceIds: sources,
        earliestSourceId: earliestSource[lemma],
        encounterCount: encounterCount,
        status: status,
        isPracticed: isPracticed,
        isMastered: isMastered,
      );
    }

    final totalSources = sortedLessons.map((l) => l.sourceId).toSet().length;

    final analytics = LexiconAnalytics(
      totalUniqueWords: trackedWords.length,
      newWordsCount: newCount,
      repeatedWordsCount: repeatedCount,
      practicedWordsCount: practicedCount,
      masteredWordsCount: masteredCount,
      totalSourcesCount: totalSources,
      tier1Count: tier1,
      tier2Count: tier2,
      tier3Count: tier3,
    );

    return WordTrackingAnalytics(
      analytics: analytics,
      wordsByLemma: trackedWords,
    );
  }
}
