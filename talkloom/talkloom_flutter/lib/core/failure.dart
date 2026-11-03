import 'dart:async';
import 'dart:io';
import 'package:talkloom_client/talkloom_client.dart';

/// A failure that is safe and useful to show a learner.
///
/// Every repository call funnels exceptions through [Failure.from] so the UI
/// always has something to render. This is the replacement for the previous
/// `catch (_) {}` blocks, which left the user staring at a spinner that
/// silently stopped.
class Failure implements Exception {
  const Failure(
    this.message, {
    this.isRetryable = true,
    this.cause,
    this.title,
    this.suggestsPastingText = false,
  });

  /// Short heading for popups; null falls back to a generic one.
  final String? title;

  /// True when pasting the source text is a workable next step.
  final bool suggestsPastingText;

  /// Learner-facing copy. No stack traces, no endpoint names.
  final String message;

  final bool isRetryable;
  final Object? cause;

  static const _importTitles = {
    'no_learning_content': 'Could not prepare this content',
    'blocked': 'This site blocks readers',
    'not_found': 'Page not found',
    'unavailable': 'Content temporarily unreachable',
    'no_text': 'No readable text found',
    'timeout': 'Connection took too long',
    'unreachable': "Couldn't reach this link",
    'unsupported_link': 'Link not supported',
    'unreadable': 'Could not read this source',
    'wrong_language': 'Not in your learning language',
    'quota_exceeded': 'Daily free limit reached',
  };

  static Failure from(Object error) {
    if (error is Failure) return error;

    if (error is ImportException) {
      final quota = error.code == 'quota_exceeded';
      return Failure(
        error.message,
        title: _importTitles[error.code] ?? 'Could not finish this import',
        isRetryable: error.code == 'timeout' || error.code == 'unavailable',
        suggestsPastingText:
            !quota && error.code != 'unsupported_link',
        cause: error,
      );
    }
    if (error is ServerpodClientUnauthorized) {
      return Failure(
        'Your session expired. Sign in again to continue.',
        isRetryable: false,
        cause: error,
      );
    }
    if (error is ServerpodClientException) {
      return Failure(
        'The server could not handle that. Please try again.',
        cause: error,
      );
    }
    if (error is TimeoutException) {
      return Failure(
        'That took too long. Building a lesson can be slow. Try again.',
        cause: error,
      );
    }
    if (error is SocketException || error is HttpException) {
      return Failure(
        'No connection to Talkloom. Check your network and try again.',
        cause: error,
      );
    }
    if (error is ArgumentError) {
      return Failure(
        error.message?.toString() ?? 'That source could not be used.',
        isRetryable: false,
        cause: error,
      );
    }

    return Failure('Something went wrong. Please try again.', cause: error);
  }

  @override
  String toString() => 'Failure($message)';
}
