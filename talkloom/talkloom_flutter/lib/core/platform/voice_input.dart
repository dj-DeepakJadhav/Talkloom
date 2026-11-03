/// Shared speech-input types used by the web and native voice services.
library;

/// Why the last attempt to listen did not (or no longer does) work.
enum VoiceInputFailure {
  /// The user denied microphone or speech-recognition access, but can be
  /// asked again.
  permissionDenied,

  /// The user permanently denied microphone access ("don't ask again").
  /// Only the system Settings page can re-grant it.
  permissionPermanentlyDenied,

  /// This device or browser has no usable speech recognizer.
  unsupported,

  /// Recognition ran but heard nothing it could transcribe.
  noSpeech,

  /// Any other recognizer error (network, busy, audio, ...).
  error,
}

/// Coarse, UI-facing state of the microphone.
enum VoiceInputState { idle, starting, listening, error }

/// Honest, user-facing text for [failure]. Always points at typing as the
/// fallback so the user is never stuck.
String voiceFailureMessage(VoiceInputFailure failure, {required bool web}) {
  switch (failure) {
    case VoiceInputFailure.permissionDenied:
      return web
          ? 'Microphone access is blocked. Allow it in your browser settings, or type your reply.'
          : 'Mikrofonzugriff ist aus. Erlaube ihn in den Einstellungen oder tippe deine Antwort. / Microphone access is off. Turn it on in Settings, or type your reply.';
    case VoiceInputFailure.permissionPermanentlyDenied:
      return web
          ? 'Microphone access is blocked. Allow it in your browser settings, or type your reply.'
          : 'Mikrofonzugriff ist dauerhaft blockiert. Öffne die Einstellungen, um ihn wieder zu erlauben, oder tippe deine Antwort. / Microphone access is permanently blocked. Turn it on in Settings, or type your reply.';
    case VoiceInputFailure.unsupported:
      return web
          ? 'Voice input is not supported in this browser. Type your reply instead.'
          : 'Speech recognition is not available on this device. Type your reply instead.';
    case VoiceInputFailure.noSpeech:
      return 'I did not catch that. Try again, or type your reply.';
    case VoiceInputFailure.error:
      return 'Voice input stopped unexpectedly. Try again, or type your reply.';
  }
}
