import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/ingest/shared_intent.dart';
import 'package:talkloom_flutter/features/ingest/universal_ingest_sheet.dart';

void main() {
  group('splitSharedText', () {
    test('pulls the link out of chat text around it', () {
      final split = splitSharedText(
        'Check this out https://www.youtube.com/watch?v=dQw4w9WgXcQ so good',
      );
      expect(split.url, 'https://www.youtube.com/watch?v=dQw4w9WgXcQ');
      expect(split.text, 'Check this out so good');
    });

    test('keeps a bare link as the url', () {
      const link = 'https://www.instagram.com/p/abc123/';
      final split = splitSharedText(link);
      expect(split.url, link);
      expect(split.text, isEmpty);
    });

    test('treats link-free shares as pasted text', () {
      final split = splitSharedText('Der Hund bellt laut im Garten.');
      expect(split.url, isNull);
      expect(split.text, 'Der Hund bellt laut im Garten.');
    });
  });

  testWidgets('sheet opens prefilled from a shared link', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: const UniversalIngestSheet(
            initialLink: 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      findsOneWidget,
    );
  });
}
