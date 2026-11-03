/// Picks the most human-sounding installed voice for a language.
///
/// Robotic defaults (eSpeak, compact system voices) ruin pronunciation
/// practice. This ranks installed voices so every platform speaks with the
/// best voice it has — no cloud, no key, fully offline.
///
/// Rules, in order:
/// 1. Exact locale match with a natural/neural/premium voice.
/// 2. Any natural/neural/premium voice with the right language prefix.
/// 3. Exact locale match, any voice.
/// 4. Any voice with the language prefix.
/// 5. Otherwise null (caller falls back to its default).
int? pickBestVoiceIndex(List<VoiceCandidate> voices, String langCode) {
  if (voices.isEmpty) return null;
  final want = langCode.toLowerCase().replaceAll('_', '-');
  final prefix = want.split('-').first;

  bool natural(VoiceCandidate v) =>
      RegExp('natural|neural|premium|siri|anna|katja|helena|conchita|marlene',
              caseSensitive: false)
          .hasMatch(v.name);
  bool exact(VoiceCandidate v) =>
      v.lang.toLowerCase().replaceAll('_', '-') == want;
  bool sameLanguage(VoiceCandidate v) =>
      v.lang.toLowerCase().replaceAll('_', '-').startsWith(prefix);

  int? firstWhere(bool Function(VoiceCandidate) test) {
    for (var i = 0; i < voices.length; i++) {
      if (test(voices[i])) return i;
    }
    return null;
  }

  return firstWhere((v) => exact(v) && natural(v)) ??
      firstWhere((v) => sameLanguage(v) && natural(v)) ??
      firstWhere(exact) ??
      firstWhere(sameLanguage);
}

/// A voice installed on the device, in platform-neutral form.
class VoiceCandidate {
  const VoiceCandidate({required this.name, required this.lang});

  final String name;
  final String lang;
}
