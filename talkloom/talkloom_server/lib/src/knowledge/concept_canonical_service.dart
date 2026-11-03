/// Canonical keys for vocabulary and grammar across lessons.
///
/// Problem: the AI compiler names the same grammar differently per video
/// ("polite_indirect_question" vs "polite indirect inquiry") and the same
/// word with different id casing. This service gives every concept one
/// stable key so short and long lessons merge instead of duplicating.
///
/// No schema change: keys are derived deterministically from the stored
/// JSON, so per-video rows stay untouched and the combined view is computed
/// on read. New lessons are canonicalized at compile time; old lessons are
/// covered by the same functions during aggregation.
library;

/// `de:Kaution` -> `de:kaution`.
String canonicalVocabId(String language, String lemma) {
  final lang = language.trim().toLowerCase();
  final clean = lemma.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  return '$lang:$clean';
}

/// `Polite Indirect Question!` -> `polite_indirect_question`.
/// Keeps the original text as the display label; the slug is only the key.
String canonicalGrammarKey(String concept) {
  var slug = concept.trim().toLowerCase();
  slug = slug.replaceAll(RegExp(r'[^a-z0-9äöüß]+'), '_');
  slug = slug.replaceAll(RegExp(r'_+'), '_');
  slug = slug.replaceAll(RegExp(r'^_|_$'), '');
  return slug.isEmpty ? 'grammar' : slug;
}

String _normalizeEvidence(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();

/// One vocabulary occurrence from a single lesson.
typedef VocabOccurrence = ({
  String id,
  String lemma,
  String article,
  String meaning,
  String sourceContext,
  int lessonId,
  int sourceId,
  String lessonTitle,
});

/// One grammar occurrence from a single lesson.
typedef GrammarOccurrence = ({
  String key,
  String label,
  String sourceSentence,
  String explanation,
  int lessonId,
  int sourceId,
  String lessonTitle,
});

/// Groups vocab occurrences by canonical id, keeping every source ref so
/// the learner sees the combined entry plus where each use came from.
Map<String, ({String lemma, List<VocabOccurrence> occurrences})> groupVocab(
  List<VocabOccurrence> all,
) {
  final groups =
      <String, ({String lemma, List<VocabOccurrence> occurrences})>{};
  for (final v in all) {
    final entry = groups[v.id];
    if (entry == null) {
      groups[v.id] = (lemma: v.lemma, occurrences: [v]);
    } else {
      entry.occurrences.add(v);
    }
  }
  return groups;
}

/// Groups grammar occurrences by canonical slug.
Map<String, ({String label, List<GrammarOccurrence> occurrences})> groupGrammar(
  List<GrammarOccurrence> all,
) {
  final groups =
      <String, ({String label, List<GrammarOccurrence> occurrences})>{};
  for (final g in all) {
    final entry = groups[g.key];
    if (entry == null) {
      groups[g.key] = (label: g.label, occurrences: [g]);
    } else {
      entry.occurrences.add(g);
    }
  }
  return groups;
}

/// True when two meanings look like the same teaching (for the audit log).
bool sameMeaning(String a, String b) =>
    _normalizeEvidence(a) == _normalizeEvidence(b);

/// Compile-time canonicalization: repairs AI naming drift in place.
///
/// Vocabulary ids become `lang:lemma` (matching the compiler's own repair);
/// grammar concepts become slugs with the original kept as `label` when it
/// differs, so short and long lessons share keys. Content fields
/// (meanings, explanations, contexts) are never touched.
void canonicalizeLessonDsl(Map<String, dynamic> lesson, String language) {
  final vocabulary = lesson['vocabulary'];
  if (vocabulary is List) {
    for (final item in vocabulary.whereType<Map>()) {
      final lemma = item['lemma']?.toString() ?? '';
      if (lemma.trim().isNotEmpty) {
        item['id'] = canonicalVocabId(language, lemma);
      }
    }
  }
  final grammar = lesson['grammar'];
  if (grammar is List) {
    for (final item in grammar.whereType<Map>()) {
      final concept = item['concept']?.toString() ?? '';
      if (concept.trim().isEmpty) continue;
      final slug = canonicalGrammarKey(concept);
      if (item['label'] == null && slug != concept.trim()) {
        item['label'] = concept.trim();
      }
      item['concept'] = slug;
    }
  }
}
