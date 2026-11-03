/// Recall projection: turns raw evidence events into per-word memory bars.
///
/// Inspired by the idea (not the code) that recall strength comes from
/// *spaced, independent* use: distinct days matter more than repetitions on
/// one day, a later mistake (lapse) weakens the trace, and strength fades
/// when a word is not revisited. Everything here is computed on read from
/// existing evaluation rows — no schema change, no migration.
class RecallObservation {
  const RecallObservation({
    required this.at,
    required this.independent,
    required this.lapse,
  });

  /// When the evidence was recorded.
  final DateTime at;

  /// Eligible, correct, in-context, spontaneous use (our "independent").
  final bool independent;

  /// The word was used incorrectly *after* learning started (lapse signal).
  final bool lapse;
}

class RecallState {
  const RecallState({
    required this.bars,
    required this.label,
    required this.explanation,
    required this.dueAt,
    required this.independentUses,
  });

  /// 0–3. 0 = seen but never used alone; 3 = held across days.
  final int bars;
  final String label;
  final String explanation;

  /// When the word should be revisited next. Null when there is nothing
  /// to revisit yet.
  final DateTime? dueAt;
  final int independentUses;
}

/// Intervals (days) a word at each bar level may rest before review.
const recallIntervalsDays = <int>[1, 1, 4, 14];

String recallLabel(int bars) => switch (bars) {
  0 => 'New',
  1 => 'Fragile',
  2 => 'Growing',
  _ => 'Steady',
};

String recallExplanation(int bars) => switch (bars) {
  0 => 'Seen but not yet used on your own.',
  1 => 'Used once on your own. Bring it back another day.',
  2 => 'Recalled on different days. Still worth revisiting.',
  _ => 'Held across days. Revisit before it fades.',
};

/// Projects memory bars from a word's evidence history (oldest first
/// preferred, any order accepted).
RecallState projectRecall(List<RecallObservation> events, {DateTime? now}) {
  final at = (now ?? DateTime.now()).toUtc();
  final independent = events.where((e) => e.independent).toList()
    ..sort((a, b) => a.at.compareTo(b.at));
  if (independent.isEmpty) {
    return const RecallState(
      bars: 0,
      label: 'New',
      explanation: 'Seen but not yet used on your own.',
      dueAt: null,
      independentUses: 0,
    );
  }

  final days = <DateTime>{
    for (final e in independent)
      DateTime.utc(e.at.year, e.at.month, e.at.day),
  }.toList()..sort();
  var bars = 1;
  if (days.length >= 2) bars = 2;
  if (days.length >= 3 &&
      days.last.difference(days.first).inDays >= 7) {
    bars = 3;
  }

  // A later mistake weakens the trace back toward fragile.
  final lastIndependent = independent.last.at;
  final lapsed = events.any(
    (e) => e.lapse && e.at.isAfter(lastIndependent),
  );
  if (lapsed) bars = bars > 1 ? 1 : bars;

  // Strength fades when the word is not revisited in time.
  var dueAt = lastIndependent.add(Duration(days: recallIntervalsDays[bars]));
  if (at.isAfter(dueAt) && bars > 1) {
    bars -= 1;
    dueAt = lastIndependent.add(Duration(days: recallIntervalsDays[bars]));
  }

  return RecallState(
    bars: bars,
    label: recallLabel(bars),
    explanation: recallExplanation(bars),
    dueAt: dueAt,
    independentUses: independent.length,
  );
}
