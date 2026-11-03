import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Thin seam over the on-device recognizer so tests can inject a fake.
abstract class SpeechEngine {
  /// Returns false when permission was denied or no recognizer exists.
  Future<bool> initialize({
    required void Function(String code, bool permanent) onError,
    required void Function(String status) onStatus,
  });

  /// Whether microphone/speech permission is currently granted.
  Future<bool> hasPermission();

  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
  });

  Future<void> stop();
  Future<void> cancel();
}

/// Production engine backed by the `speech_to_text` plugin (iOS SFSpeech,
/// Android SpeechRecognizer).
class PluginSpeechEngine implements SpeechEngine {
  final SpeechToText _stt = SpeechToText();

  @override
  Future<bool> initialize({
    required void Function(String code, bool permanent) onError,
    required void Function(String status) onStatus,
  }) => _stt.initialize(
    onError: (SpeechRecognitionError e) => onError(e.errorMsg, e.permanent),
    onStatus: onStatus,
  );

  @override
  Future<bool> hasPermission() => _stt.hasPermission;

  @override
  Future<void> listen({
    required String localeId,
    required void Function(String words, bool isFinal) onResult,
  }) async {
    await _stt.listen(
      onResult: (SpeechRecognitionResult r) =>
          onResult(r.recognizedWords, r.finalResult),
      listenOptions: SpeechListenOptions(
        localeId: localeId.replaceAll('-', '_'),
        partialResults: true,
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  @override
  Future<void> stop() => _stt.stop();

  @override
  Future<void> cancel() => _stt.cancel();
}
