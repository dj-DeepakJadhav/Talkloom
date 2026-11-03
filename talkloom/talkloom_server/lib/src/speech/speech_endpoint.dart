import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../services/meta_speech_service.dart';
import '../services/local_tts_service.dart';
import '../usage/ai_quota_service.dart';

class SpeechEndpoint extends Endpoint {
  @override
  bool get requireLogin => true;

  /// Transcribes learner audio with Muse Voice Transcribe via the Meta
  /// Model API — the only cloud speech provider in this project.
  /// [base64Audio] must be mono 16-bit PCM WAV (16 or 24 kHz).
  Future<String> transcribe(
    Session session,
    String base64Audio,
    String language, {
    List<String>? vocabulary,
  }) async {
    await AiQuotaService.consume(session, 'transcription');
    final speech = MetaSpeechService(
      apiKey: session.serverpod.getPassword('metaApiKey') ?? '',
    );
    final text = await speech.transcribe(
      base64Audio,
      language: language,
      vocabulary: vocabulary,
    );
    return jsonEncode({'text': text, 'provider': 'meta'});
  }

  /// Spoken output via the self-hosted open-source voice worker (Piper).
  /// Meta offers no TTS, so an open model fills the gap; all language
  /// understanding stays Meta-only. The client falls back to on-device
  /// speech when the worker is unreachable.
  Future<String> synthesize(
    Session session,
    String text,
    String language, {
    String? voice,
  }) async {
    final worker = Uri.tryParse(
      Platform.environment['TTS_WORKER_URL'] ??
          'http://127.0.0.1:8131/synthesize',
    );
    final tts = LocalTtsService(
      worker: worker,
      defaultVoice:
          session.serverpod.getPassword('ttsVoice') ?? 'de-thorsten-m',
    );
    final result = await tts.synthesize(text, language, voice: voice);
    return jsonEncode({
      'audio': base64Encode(result.audio),
      'mimeType': 'audio/wav',
      'provider': 'piper',
      'voice': result.voice,
    });
  }
}
