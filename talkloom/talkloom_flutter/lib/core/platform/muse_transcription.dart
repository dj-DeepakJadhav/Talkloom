import 'dart:convert';
import 'dart:io';
import 'package:record/record.dart';

/// Records learner speech to WAV and sends it to Muse Voice Transcribe
/// (Meta Model API) via the lesson repository.
///
/// WAV is required: 24 kHz mono 16-bit PCM is the model's native input.
/// Recording stays on-device until the learner stops; only the finished
/// clip is uploaded for transcription.
class MuseVoiceRecorder {
  MuseVoiceRecorder({AudioRecorder? recorder})
    : _recorder = recorder ?? AudioRecorder();

  final AudioRecorder _recorder;
  String? _path;
  bool _recording = false;

  bool get isRecording => _recording;

  /// Starts a 24 kHz mono WAV recording. Returns false when the platform
  /// cannot record WAV (caller falls back to OS recognition).
  Future<bool> start() async {
    try {
      if (!await _recorder.hasPermission()) return false;
      final dir = Directory.systemTemp;
      _path =
          '${dir.path}/talkloom_muse_${DateTime.now().millisecondsSinceEpoch}.wav';
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.wav,
          sampleRate: 24000,
          numChannels: 1,
        ),
        path: _path!,
      );
      _recording = true;
      return true;
    } catch (_) {
      _recording = false;
      return false;
    }
  }

  /// Stops recording and returns the clip as base64 WAV, or null when
  /// nothing usable was captured.
  Future<String?> stopAndRead() async {
    _recording = false;
    try {
      final path = await _recorder.stop() ?? _path;
      if (path == null) return null;
      final file = File(path);
      if (!file.existsSync()) return null;
      final bytes = await file.readAsBytes();
      try {
        await file.delete();
      } catch (_) {}
      if (bytes.length < 1000) return null;
      return base64Encode(bytes);
    } catch (_) {
      return null;
    } finally {
      _path = null;
    }
  }

  Future<void> cancel() async {
    _recording = false;
    try {
      await _recorder.stop();
    } catch (_) {}
    _path = null;
  }

  void dispose() => _recorder.dispose();
}
