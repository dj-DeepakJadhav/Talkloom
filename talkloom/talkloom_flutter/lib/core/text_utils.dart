/// Shared text/math helpers. German-first copy lives at the call sites;
/// these helpers only centralize copy-pasted logic.
library;

/// Clamps the seconds elapsed since [turnStart] into the 0.5–20.0 s range
/// used for tutor turn-latency reporting.
///
/// Call-site replacement (owned by another agent — do NOT rewire here):
/// ```dart
/// // Before:
/// final latency =
///     (DateTime.now().difference(_turnStart).inMilliseconds / 1000.0).clamp(
///       0.5,
///       20.0,
///     );
/// // After:
/// final latency = turnLatencySeconds(_turnStart);
/// ```
/// Applies to talk_canvas_screen, voice_arena_screen,
/// immersive_voice_modal and speak_screen.
double turnLatencySeconds(DateTime turnStart, [DateTime? now]) {
  final elapsed =
      ((now ?? DateTime.now()).difference(turnStart).inMilliseconds / 1000.0);
  return elapsed.clamp(0.5, 20.0);
}

/// Extracts the lemma from a `'<...>:<lemma>'` identifier.
///
/// Call-site replacement (owned by another agent — do NOT rewire here):
/// ```dart
/// // Before:
/// final raw = id.contains(':') ? id.split(':').last : id;
/// // or: .map((id) => id.split(':').last.trim())
/// // After:
/// final raw = parseLemmaId(id);
/// ```
/// Applies to word_tracking_analytics, speak_screen and mission_tracker.
String parseLemmaId(String id, {bool trim = true}) {
  final raw = id.contains(':') ? id.split(':').last : id;
  return trim ? raw.trim() : raw;
}
