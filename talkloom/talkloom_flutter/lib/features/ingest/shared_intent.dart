/// Android share-target intake: links and text shared from apps like
/// Instagram, WhatsApp or YouTube arrive here as plain text, often with
/// commentary around the link ("Check this out https://…").
library;

import 'package:flutter/services.dart';

final _urlPattern = RegExp(r'https?://[^\s)>\]]+');

/// Splits shared text into the first link (if any) and the remaining text.
///
/// A shared YouTube or Instagram message usually carries one link; the
/// import flow takes the link and ignores the surrounding chat text.
/// A share with no link is treated as pasted text to learn from.
({String? url, String text}) splitSharedText(String raw) {
  final match = _urlPattern.firstMatch(raw);
  if (match == null) return (url: null, text: raw.trim());
  final url = match.group(0)!;
  final rest = (raw.replaceFirst(
    url,
    ' ',
  )).replaceAll(RegExp(r'\s+'), ' ').trim();
  return (url: url, text: rest);
}

/// Reads one pending share from the host app through MainActivity.
///
/// Returns null on platforms without the channel (web, iOS, tests) or
/// when nothing was shared. Each share is delivered once.
class ShareIntake {
  ShareIntake({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel('talkloom/share');

  final MethodChannel _channel;

  Future<String?> takeSharedText() async {
    try {
      final text = await _channel.invokeMethod<String>('takeSharedText');
      return text?.trim().isEmpty == true ? null : text?.trim();
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }
}
