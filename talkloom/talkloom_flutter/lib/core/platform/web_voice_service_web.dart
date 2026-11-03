import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

import 'device_voice_service.dart';
import 'voice_input.dart';

@JS('talkloomVoice.startListening')
external bool _jsStartListening(JSString? langCode);

@JS('talkloomVoice.stopListening')
external void _jsStopListening();

@JS('talkloomVoice.isListening')
external bool get _jsIsListening;

@JS('talkloomVoice.lastError')
external JSString? get _jsLastError;

/// Web: recognition through the browser Web Speech API bridge in
/// `web/index.html`; Meta server voice audio output is shared with Android/iOS.
class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();

  /// Called with the running transcript (interim and final).
  void Function(String transcript)? onTranscriptReceived;

  /// Called once with the last transcript when a listen session ends.
  void Function(String transcript)? onFinalTranscript;

  /// Called when listening stops on its own (timeout, error, permission).
  void Function(bool listening)? onListeningChanged;

  /// Called when recognition fails after it started (or fails to start).
  void Function(VoiceInputFailure failure, String message)? onError;

  bool _initialized = false;
  Timer? _monitor;
  bool _listening = false;
  String _transcript = '';
  VoiceInputState _state = VoiceInputState.idle;
  VoiceInputFailure? _lastFailure;

  bool get isListening => _listening;
  VoiceInputState get state => _state;
  VoiceInputFailure? get lastFailure => _lastFailure;
  String? get lastFailureMessage => _lastFailure == null
      ? null
      : voiceFailureMessage(_lastFailure!, web: true);

  /// Browsers do not let pages open their permission settings.
  bool get canOpenSettings => false;

  /// Device speech synthesis is always offered; failures surface
  /// through [speechUnavailableReason] after a speak attempt.
  bool get canSpeak => DeviceVoiceService.instance.canSpeak;

  /// Resolves when the current utterance finishes, matching the native
  /// implementation so call sites stay platform-agnostic.
  Future<void> get speechDone => DeviceVoiceService.instance.speechDone;

  String get speechUnavailableReason =>
      DeviceVoiceService.instance.unavailableReason;

  void init() {
    if (_initialized) return;
    try {
      web.window.addEventListener(
        'talkloom_speech_result',
        (web.Event event) {
          final customEvent = event as web.CustomEvent;
          final detail = (customEvent.detail as JSString?)?.toDart;
          if (detail != null) {
            _transcript = detail;
            onTranscriptReceived?.call(detail);
          }
        }.toJS,
      );
      _initialized = true;
    } catch (e) {
      debugPrint('[WebVoiceService] init listener error: $e');
    }
  }

  VoiceInputFailure? _readJsFailure() {
    String? code;
    try {
      code = _jsLastError?.toDart;
    } catch (_) {}
    return switch (code) {
      null => null,
      'not-allowed' ||
      'service-not-allowed' => VoiceInputFailure.permissionDenied,
      'unsupported' ||
      'language-not-supported' => VoiceInputFailure.unsupported,
      'no-speech' => VoiceInputFailure.noSpeech,
      'aborted' => null,
      _ => VoiceInputFailure.error,
    };
  }

  void _setFailure(VoiceInputFailure failure) {
    _lastFailure = failure;
    _state = VoiceInputState.error;
    onError?.call(failure, voiceFailureMessage(failure, web: true));
  }

  Future<bool> startListening({String langCode = 'de-DE'}) async {
    if (!kIsWeb) return false;
    _lastFailure = null;
    _transcript = '';
    try {
      final success = _jsStartListening(langCode.toJS);
      _listening = success;
      _monitor?.cancel();
      if (success) {
        _state = VoiceInputState.listening;
        _monitor = Timer.periodic(const Duration(milliseconds: 300), (timer) {
          if (!_jsIsListening) {
            timer.cancel();
            _listening = false;
            _state = VoiceInputState.idle;
            final failure = _readJsFailure();
            if (failure != null) _setFailure(failure);
            if (_transcript.isNotEmpty) onFinalTranscript?.call(_transcript);
            onListeningChanged?.call(false);
          }
        });
      } else {
        _setFailure(_readJsFailure() ?? VoiceInputFailure.unsupported);
      }
      return success;
    } catch (e) {
      debugPrint('[WebVoiceService] startListening error: $e');
      _listening = false;
      _setFailure(VoiceInputFailure.unsupported);
      return false;
    }
  }

  void stopListening() {
    if (!kIsWeb) return;
    try {
      _jsStopListening();
    } catch (e) {
      debugPrint('[WebVoiceService] stopListening error: $e');
    } finally {
      _monitor?.cancel();
      _listening = false;
      if (_state != VoiceInputState.error) _state = VoiceInputState.idle;
    }
  }

  Future<bool> openSettings() async => false;

  Future<bool> speak(String text, {String langCode = 'de-DE'}) =>
      DeviceVoiceService.instance.speak(text, langCode: langCode);
}
