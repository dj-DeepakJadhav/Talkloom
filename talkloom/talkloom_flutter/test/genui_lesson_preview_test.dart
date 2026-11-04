import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/features/content/genui_lesson_preview.dart';

final lesson = LessonContent.fromLesson(
  Lesson(
    id: 2,
    userId: 'test',
    sourceId: 1,
    targetLanguage: 'de',
    supportLanguage: 'en',
    objectives: [],
    vocabulary:
        '[{"id":"de:haus","lemma":"Haus","meaning":"house","sourceContext":"Das Haus ist groß."},{"id":"de:tag","lemma":"Tag","meaning":"day"}]',
    grammar:
        '[{"concept":"Adjectives","explanation":"Describe the house.","sourceSentence":"Das Haus ist groß."}]',
    activities: '[]',
    conversationPlan: '{}',
    createdAt: DateTime.utc(2026),
  ),
);

void main() {
  test(
    'catalog accepts only bounded references to the server-loaded lesson',
    () {
      final data = <String, Object?>{
        'id': 'root',
        'component': 'LessonItem',
        'kind': 'word',
        'index': 0,
      };
      expect(validLessonComponent(data, lesson), isTrue);
      expect(validLessonComponent({...data, 'index': -1}, lesson), isFalse);
      expect(validLessonComponent({...data, 'index': 99}, lesson), isFalse);
      expect(
        validLessonComponent({...data, 'component': 'WebView'}, lesson),
        isFalse,
      );
      expect(validLessonComponent({...data, 'correct': true}, lesson), isFalse);
      expect(validLessonComponent({...data, 'index': '0'}, lesson), isFalse);
    },
  );

  testWidgets('A2UI renders saved words, switches to grammar and advances', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(720, 1600);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: Scaffold(body: GenUiLessonPreview(lesson: lesson)),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Haus'), findsOneWidget);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Tag'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Grammar'));
    await tester.pumpAndSettle();
    expect(find.text('Adjectives'), findsOneWidget);
    expect(find.text('Describe the house.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
