import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/data/lesson_repository.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/source_reading.dart';
import 'package:talkloom_flutter/features/content/source_reader.dart';
import 'package:talkloom_flutter/features/content/source_text.dart';

class _Repository extends LessonRepository {
  _Repository() : super(Client('http://localhost:1/'));
  final requests = <String>[];
  final streams = <String, StreamController<SourceReadingBatch>>{};
  @override
  Stream<SourceReadingBatch> readSource({
    required int sourceId,
    required String supportLanguage,
    required String mode,
  }) {
    requests.add('$sourceId:$supportLanguage:$mode');
    return (streams[mode] = StreamController<SourceReadingBatch>()).stream;
  }
}

void main() {
  testWidgets(
    'reader switches modes, preserves original and retains completed sections on failure',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = _Repository();
      addTearDown(() async {
        for (final stream in repo.streams.values) {
          await stream.close();
        }
      });
      final source = Source(
        id: 1,
        userId: 'test',
        type: 'document',
        title: 'Morning',
        rawText: 'Guten Morgen.\nDanke!',
        targetLanguage: 'de',
        cefrLevel: 'A1',
        createdAt: DateTime.utc(2026),
      );
      tester.view.physicalSize = const Size(720, 1600);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            lessonRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            theme: buildTalkloomTheme(Brightness.light),
            home: Scaffold(
              body: SingleChildScrollView(child: SourceReader(source: source)),
            ),
          ),
        ),
      );
      expect(repo.requests, isEmpty);
      await tester.tap(find.text('Line by line'));
      await tester.pump();
      expect(repo.requests.single, '1:en:line');
      repo.streams['line']!.add(
        const SourceReadingBatch(
          mode: 'line',
          language: 'en',
          total: 2,
          segments: [
            SourceReadingSegment(
              id: 0,
              original: 'Guten Morgen.',
              translation: 'Good morning.',
            ),
          ],
          done: false,
        ),
      );
      await tester.pump();
      expect(find.text('1 of 2 sections translated'), findsOneWidget);
      expect(
        tester
            .widgetList<SourceText>(find.byType(SourceText))
            .map((w) => w.text),
        containsAll(['Guten Morgen.', 'Good morning.']),
      );
      repo.streams['line']!.addError(Exception('offline'));
      await tester.pump();
      expect(find.text('Try again'), findsOneWidget);
      expect(
        tester
            .widgetList<SourceText>(find.byType(SourceText))
            .map((w) => w.text),
        contains('Good morning.'),
      );
      await tester.tap(find.text('Full translation'));
      await tester.pump();
      repo.streams['complete']!.add(
        const SourceReadingBatch(
          mode: 'complete',
          language: 'en',
          total: 1,
          segments: [
            SourceReadingSegment(
              id: 0,
              original: 'Guten Morgen.\nDanke!',
              translation: 'Good morning.\nThanks!',
            ),
          ],
          done: true,
        ),
      );
      await tester.pump();
      final texts = tester
          .widgetList<SourceText>(find.byType(SourceText))
          .map((w) => w.text)
          .toList();
      expect(texts, ['Good morning.\nThanks!']);
      await tester.tap(find.text('Original'));
      await tester.pump();
      expect(
        tester.widget<SourceText>(find.byType(SourceText)).text,
        source.rawText,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
