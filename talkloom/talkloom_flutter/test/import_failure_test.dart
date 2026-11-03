import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/core/failure.dart';

void main() {
  test('blocked site maps to an actionable popup message', () {
    final failure = Failure.from(
      ImportException(code: 'blocked', message: 'example.com blocks readers.'),
    );
    expect(failure.title, 'This site blocks readers');
    expect(failure.message, 'example.com blocks readers.');
    expect(failure.suggestsPastingText, isTrue);
    expect(failure.isRetryable, isFalse);
  });

  test('unsupported link does not suggest pasting text', () {
    final failure = Failure.from(
      ImportException(code: 'unsupported_link', message: 'Use an HTTPS link.'),
    );
    expect(failure.suggestsPastingText, isFalse);
  });

  test('timeouts are retryable', () {
    final failure = Failure.from(
      ImportException(code: 'timeout', message: 'Too slow.'),
    );
    expect(failure.isRetryable, isTrue);
  });
}
