import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../client.dart';
import 'voice_pick.dart';

final speechMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Spoken output for Web, Android, and iOS. Recognition is separate.
///
/// Voice order: the self-hosted open-source voice (Piper, selected in
/// Settings — 2 female + 2 male German voices) first for natural speech,
/// then the device's own voices as the offline fallback. Language models
/// stay Meta-only; speech synthesis uses open weights because Meta
/// offers no TTS API.
class DeviceVoiceService {
  DeviceVoiceService._() {
    // Stream subscriptions must never take down playback: in widget tests
    // (and on broken platform plugins) these channels have no native side.
    runZonedGuarded(() {
      _player.onPlayerComplete.listen(
        (_) => _finishSpeech(),
        onError: (_) => _finishSpeech(),
      );
    }, (error, stack) => _finishSpeech());
    // Synchronous setters; the try/catch is for missing-plugin platforms.
    try {
      _tts
        ..setCompletionHandler(_finishSpeech)
        ..setCancelHandler(_finishSpeech)
        ..setErrorHandler((_) => _finishSpeech());
    } catch (_) {}
  }
  static final instance = DeviceVoiceService._();
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _player = AudioPlayer();
  int _request = 0;
  Completer<void>? _speechCompleter;

  /// Completes when the current utterance finishes, is superseded, or
  /// is stopped. Never hangs: [stop] completes it as well.
  Future<void> get speechDone => _speechCompleter?.future ?? Future.value();

  void _finishSpeech() {
    final completer = _speechCompleter;
    if (completer != null && !completer.isCompleted) completer.complete();
  }

  /// Open-voice id synced from app preferences (see main.dart).
  static String serverVoiceId = 'de-thorsten-m';

  final Map<String, Map<String, String>> _deviceVoices = {};

  String unavailableReason = 'Voice audio could not play. Please try again.';

  /// Always offered; failures surface through [unavailableReason].
  bool get canSpeak => true;

  bool _isValidWav(Uint8List bytes) {
    if (bytes.length < 1000 || bytes.length > 16 * 1024 * 1024) return false;
    final riff = ascii.decode(bytes.sublist(0, 4), allowInvalid: true);
    final wave = ascii.decode(bytes.sublist(8, 12), allowInvalid: true);
    return riff == 'RIFF' && wave == 'WAVE';
  }

  Future<bool> speak(String text, {String langCode = 'de-DE'}) async {
    final request = ++_request;
    _speechCompleter = Completer<void>();
    final clean = text
        .replaceAllMapped(
          RegExp(r'\[\[new:([^:|\]]+)(?::[^\]]+)?\]\]'),
          (m) => m[1]!,
        )
        .trim();
    if (clean.isEmpty) {
      _finishSpeech();
      return false;
    }
    try {
      await _player.stop();
    } catch (_) {}
    // 1. Open-voice server (Piper). Fast when warm; falls through on any
    // failure so a down worker never blocks speech.
    try {
      final data =
          jsonDecode(
                await client.speech.synthesize(
                  clean,
                  langCode,
                  voice: serverVoiceId,
                ),
              )
              as Map<String, dynamic>;
      final played = await _playServerAudio(
        data['audio'],
        request: request,
      );
      if (played) {
        _finishSpeech();
        return true;
      }
    } catch (_) {
      // Fall through to on-device speech.
    }
    // 2. On-device speech.
    try {
      await _tts.stop();
      await _tts.setLanguage(langCode);
      final voice = await _bestDeviceVoice(langCode);
      if (voice != null) {
        await _tts.setVoice(voice);
      }
      await _tts.setSpeechRate(0.9);
      await _tts.speak(clean);
      _finishSpeech();
      return request == _request;
    } catch (_) {
      if (request == _request) {
        unavailableReason =
            'Voice service is currently unavailable. Please try again.';
      }
      _finishSpeech();
      return false;
    }
  }

  Future<bool> _playServerAudio(Object? audio, {required int request}) async {
    if (audio is! String || audio.isEmpty) return false;
    late Uint8List bytes;
    try {
      bytes = base64Decode(audio);
    } catch (_) {
      return false;
    }
    if (!_isValidWav(bytes) || request != _request) return false;
    try {
      await _player.play(BytesSource(Uint8List.fromList(bytes)));
      return request == _request;
    } catch (_) {
      return false;
    }
  }

  /// Best installed on-device voice for [langCode], memoized per language.
  /// Null means: let the engine decide.
  Future<Map<String, String>?> _bestDeviceVoice(String langCode) async {
    final prefix = langCode.toLowerCase().split(RegExp('[-_]')).first;
    if (_deviceVoices.containsKey(prefix)) {
      return _deviceVoices[prefix];
    }
    try {
      final raw = await _tts.getVoices;
      final candidates = <VoiceCandidate>[];
      final raws = <Map<String, String>>[];
      if (raw is List) {
        for (final entry in raw) {
          if (entry is! Map) continue;
          final name = entry['name']?.toString() ?? '';
          final locale = entry['locale']?.toString() ?? '';
          if (name.isEmpty) continue;
          candidates.add(VoiceCandidate(name: name, lang: locale));
          raws.add({'name': name, 'locale': locale});
        }
      }
      final index = pickBestVoiceIndex(candidates, langCode);
      if (index == null) return null;
      return _deviceVoices[prefix] = raws[index];
    } catch (_) {
      return null;
    }
  }

  Future<void> stop() async {
    ++_request;
    _finishSpeech();
    speechMessengerKey.currentState?.hideCurrentSnackBar();
    try {
      await _player.stop();
    } catch (_) {}
    try {
      await _tts.stop();
    } catch (_) {}
  }
}
