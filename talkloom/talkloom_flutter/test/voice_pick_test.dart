import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/core/platform/voice_pick.dart';

void main() {
  const de = [
    VoiceCandidate(name: 'eSpeak-DE', lang: 'de'),
    VoiceCandidate(name: 'Anna', lang: 'de-DE'),
    VoiceCandidate(name: 'Google Deutsch', lang: 'de-DE'),
  ];

  test('prefers an exact-locale natural voice', () {
    expect(pickBestVoiceIndex(de, 'de-DE'), 1);
  });

  test('falls back to any same-language voice', () {
    const voices = [VoiceCandidate(name: 'eSpeak-DE', lang: 'de')];
    expect(pickBestVoiceIndex(voices, 'de-DE'), 0);
  });

  test('returns null when nothing matches', () {
    const voices = [VoiceCandidate(name: 'Ting-Ting', lang: 'zh-CN')];
    expect(pickBestVoiceIndex(voices, 'de-DE'), isNull);
    expect(pickBestVoiceIndex(const [], 'de-DE'), isNull);
  });

  test('ignores underscore locale separators', () {
    const voices = [VoiceCandidate(name: 'Anna', lang: 'de_DE')];
    expect(pickBestVoiceIndex(voices, 'de-DE'), 0);
  });
}
