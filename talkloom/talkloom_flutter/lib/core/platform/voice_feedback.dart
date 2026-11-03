import 'package:flutter/material.dart';

import 'web_voice_service.dart';

/// Shows an honest SnackBar for the last voice-input failure, with an
/// 'Open Settings' action when the user denied access and the platform lets
/// us open the app's settings page. Returns the message shown (or null).
String? showVoiceFailure(BuildContext context) {
  final voice = WebVoiceService.instance;
  final message = voice.lastFailureMessage;
  if (message == null) return null;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return message;
  final offerSettings =
      (voice.lastFailure == VoiceInputFailure.permissionDenied ||
          voice.lastFailure == VoiceInputFailure.permissionPermanentlyDenied) &&
      voice.canOpenSettings;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: offerSettings
            ? SnackBarAction(
                label: 'Open Settings',
                onPressed: () => voice.openSettings(),
              )
            : null,
      ),
    );
  return message;
}
