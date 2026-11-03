import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'device_voice_service.dart';
import 'speech_engine.dart';
import 'voice_input.dart';

/// Android/iOS (and VM tests): on-device recognition through [SpeechEngine];
/// Meta server voice audio output is shared with Web.
///
/// The class keeps the historical `WebVoiceService` name so screens import a
/// single API regardless of platform.
class WebVoiceService {
  WebVoiceService._();
  static final WebVoiceService instance = WebVoiceService._();

  static const _settingsChannel = MethodChannel('talkloom/settings');

  /// Called with the running transcript (interim and final).
  void Function(String transcript)? onTranscriptReceived;

  /// Called once with the final transcript of a listen session.
  void Function(String transcript)? onFinalTranscript;

  /// Called whenever listening starts or stops (including unexpected stops).
  void Function(bool listening)? onListeningChanged;

  /// Called when recognition fails after it started (or fails to start).
  void Function(VoiceInputFailure failure, String message)? onError;

  SpeechEngine? _engine;
  bool _ready = false;
  bool _listening = false;
  VoiceInputState _state = VoiceInputState.idle;
  VoiceInputFailure? _lastFailure;

  bool get isListening => _listening;
  VoiceInputState get state => _state;
  VoiceInputFailure? get lastFailure => _lastFailure;
  String? get lastFailureMessage => _lastFailure == null
      ? null
      : voiceFailureMessage(_lastFailure!, web: false);

  /// Settings can be opened on Android and iOS to re-grant permission.
  bool get canOpenSettings =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android);

  bool? _debugCanSpeak;

  /// Test hooks for the OS microphone permission gate. When set, they
  /// replace the `permission_handler` calls (which have no plugin in VM
  /// tests) so tests can drive denied/permanently-denied paths.
  @visibleForTesting
  Future<PermissionStatus> Function()? debugPermissionStatus;
  @visibleForTesting
  Future<PermissionStatus> Function()? debugPermissionRequest;

  /// Whether spoken playback is offered. Controls that play audio must be
  /// disabled (with [speechUnavailableReason]) when this is false.
  bool get canSpeak => _debugCanSpeak ?? true;
  String get speechUnavailableReason => canSpeak
      ? DeviceVoiceService.instance.unavailableReason
      : 'Audio is not available on this device.';

  /// Forces [canSpeak] in tests; pass null to restore the default.
  @visibleForTesting
  set debugCanSpeak(bool? value) => _debugCanSpeak = value;

  /// Replace the recognizer (tests). Resets readiness.
  @visibleForTesting
  set debugEngine(SpeechEngine? engine) {
    _engine = engine;
    _ready = false;
    _listening = false;
    _state = VoiceInputState.idle;
    _lastFailure = null;
    debugPermissionStatus = null;
    debugPermissionRequest = null;
  }

  SpeechEngine get _speech => _engine ??= PluginSpeechEngine();

  void init() {}

  void _fail(VoiceInputFailure failure) {
    _lastFailure = failure;
    _state = VoiceInputState.error;
    final wasListening = _listening;
    _listening = false;
    if (wasListening) onListeningChanged?.call(false);
    onError?.call(failure, voiceFailureMessage(failure, web: false));
  }

  Future<bool> _ensureReady() async {
    if (_ready) return true;
    try {
      _ready = await _speech.initialize(
        onError: _handleEngineError,
        onStatus: _handleStatus,
      );
    } catch (e) {
      debugPrint('[VoiceService] initialize failed: $e');
      _ready = false;
    }
    return _ready;
  }

  void _handleEngineError(String code, bool permanent) {
    debugPrint(
      '[VoiceService] recognizer error: $code (permanent: $permanent)',
    );
    if (!permanent && code != 'error_no_match') return;
    _fail(switch (code) {
      'error_permission' ||
      'error_insufficient_permissions' => VoiceInputFailure.permissionDenied,
      'error_language_not_supported' ||
      'error_language_unavailable' => VoiceInputFailure.unsupported,
      'error_no_match' || 'error_speech_timeout' => VoiceInputFailure.noSpeech,
      _ => VoiceInputFailure.error,
    });
  }

  void _handleStatus(String status) {
    if (status == 'listening') {
      if (!_listening) {
        _listening = true;
        _state = VoiceInputState.listening;
        onListeningChanged?.call(true);
      }
    } else if (status == 'notListening' || status == 'done') {
      if (_listening) {
        _listening = false;
        if (_state != VoiceInputState.error) _state = VoiceInputState.idle;
        onListeningChanged?.call(false);
      }
    }
  }

  /// Asks the OS for microphone access via `permission_handler`.
  ///
  /// Returns null when the plugin is unavailable (VM tests, unsupported
  /// platforms) so callers fall back to the recognizer's own permission
  /// signal. Otherwise returns the post-request status. The timeout keeps
  /// a broken plugin from hanging startup: the fallback below asks the
  /// recognizer itself, which is the pre-permission_handler behavior.
  static const _permissionTimeout = Duration(seconds: 2);

  Future<PermissionStatus?> _ensureMicrophoneAccess() async {
    try {
      var status = await (debugPermissionStatus != null
              ? debugPermissionStatus!()
              : Permission.microphone.status)
          .timeout(_permissionTimeout);
      if (status.isGranted || status.isLimited) return status;
      if (status.isPermanentlyDenied || status.isRestricted) return status;
      status = await (debugPermissionRequest != null
              ? debugPermissionRequest!()
              : Permission.microphone.request())
          .timeout(_permissionTimeout);
      return status;
    } catch (e) {
      debugPrint('[VoiceService] microphone permission check failed: $e');
      return null;
    }
  }

  /// Starts on-device recognition. Resolves to true only when the recognizer
  /// actually accepted the session; on false, [lastFailure] says why.
  Future<bool> startListening({String langCode = 'de-DE'}) async {
    _lastFailure = null;
    _state = VoiceInputState.starting;
    final micStatus = await _ensureMicrophoneAccess();
    if (micStatus != null && !micStatus.isGranted && !micStatus.isLimited) {
      _fail(
        micStatus.isPermanentlyDenied || micStatus.isRestricted
            ? VoiceInputFailure.permissionPermanentlyDenied
            : VoiceInputFailure.permissionDenied,
      );
      return false;
    }
    if (!await _ensureReady()) {
      // A recognizer that cannot even report permission is unsupported.
      var granted = true;
      try {
        granted = await _speech.hasPermission();
      } catch (_) {}
      _fail(
        granted
            ? VoiceInputFailure.unsupported
            : VoiceInputFailure.permissionDenied,
      );
      return false;
    }
    try {
      await _speech.listen(
        localeId: langCode,
        onResult: (words, isFinal) {
          onTranscriptReceived?.call(words);
          if (isFinal) onFinalTranscript?.call(words);
        },
      );
    } catch (e) {
      debugPrint('[VoiceService] listen failed: $e');
      _fail(VoiceInputFailure.error);
      return false;
    }
    if (_lastFailure != null) return false;
    _listening = true;
    _state = VoiceInputState.listening;
    return true;
  }

  void stopListening() {
    final wasActive = _listening || _state == VoiceInputState.starting;
    _listening = false;
    if (_state != VoiceInputState.error) _state = VoiceInputState.idle;
    if (!wasActive || !_ready) return;
    unawaited(
      _speech.stop().catchError(
        (Object e) => debugPrint('[VoiceService] stop failed: $e'),
      ),
    );
  }

  /// Opens this app's page in system Settings. Returns false when that is
  /// not possible on this platform.
  Future<bool> openSettings() async {
    if (!canOpenSettings) return false;
    try {
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        return await launchUrl(Uri.parse('app-settings:'));
      }
      return await _settingsChannel.invokeMethod<bool>('openAppSettings') ??
          false;
    } catch (e) {
      debugPrint('[VoiceService] openSettings failed: $e');
      return false;
    }
  }

  Future<bool> speak(String text, {String langCode = 'de-DE'}) =>
      DeviceVoiceService.instance.speak(text, langCode: langCode);

  /// Resolves when the active speech ends. Playing indicators await this
  /// instead of estimating a fixed duration.
  Future<void> get speechDone => DeviceVoiceService.instance.speechDone;
}
