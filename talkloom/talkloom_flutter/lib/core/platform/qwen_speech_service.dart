import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../client.dart';

final speechMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Shared Qwen audio output for Web, Android and iOS. Recognition is separate.
class QwenSpeechService {
  QwenSpeechService._();
  static final instance = QwenSpeechService._();
  final _player = AudioPlayer();
  int _request = 0;
  String unavailableReason = 'Qwen voice could not play. Please try again.';

  Future<bool> speak(String text, {String langCode = 'de-DE'}) async {
    final request = ++_request;
    final clean = text.replaceAllMapped(
      RegExp(r'\[\[new:([^:|\]]+)(?::[^\]]+)?\]\]'), (m) => m[1]!,
    ).trim();
    if (clean.isEmpty) return false;
    final messenger = speechMessengerKey.currentState;
    messenger?.hideCurrentSnackBar();
    messenger?.showSnackBar(const SnackBar(
      content: Row(children: [SizedBox(width:16,height:16,
        child:CircularProgressIndicator(strokeWidth:2)), SizedBox(width:12),
        Text('Preparing voice…')]), duration:Duration(minutes:2)));
    try {
      await _player.stop();
      final data = jsonDecode(await client.speech.synthesize(clean, langCode)
          .timeout(const Duration(seconds:125))) as Map<String,dynamic>;
      if (request != _request) return false;
      if (data['provider'] != 'qwen3-tts' || data['mimeType'] != 'audio/wav') {
        throw const FormatException('Unsupported speech response');
      }
      await _player.play(BytesSource(base64Decode(data['audio'] as String),
        mimeType:'audio/wav'));
      return true;
    } catch (_) {
      if (request == _request) {
        unavailableReason = 'Qwen voice is unavailable. Check the voice server and try again.';
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(SnackBar(content:Text(unavailableReason)));
      }
      return false;
    } finally {
      if (request == _request) {
        // Preserve the failure snackbar; remove only the loading indicator.
        if (_player.state == PlayerState.playing) messenger?.hideCurrentSnackBar();
      }
    }
  }

  Future<void> stop() async {
    ++_request;
    speechMessengerKey.currentState?.hideCurrentSnackBar();
    await _player.stop();
  }
}
