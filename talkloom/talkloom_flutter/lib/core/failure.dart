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
  const Failure(this.message, {this.isRetryable = true, this.cause});

  /// Learner-facing copy. No stack traces, no endpoint names.
  final String message;

  final bool isRetryable;
  final Object? cause;

  static Failure from(Object error) {
    if (error is Failure) return error;

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
        'That took too long. Building a lesson can be slow — try again.',
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
