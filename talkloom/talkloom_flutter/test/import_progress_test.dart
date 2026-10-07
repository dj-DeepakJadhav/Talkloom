import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/ingest/universal_ingest_sheet.dart';

class PendingImport extends ImportController {
  @override
  AsyncValue<LessonContent?> build() => const AsyncValue.loading();
  void finish(LessonContent value) => state = AsyncValue.data(value);
  void fail() =>
      state = AsyncValue.error(Exception('test failure'), StackTrace.current);
}

void main() {
  testWidgets('retrieved server state updates the open import sheet', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [importControllerProvider.overrideWith(PendingImport.new)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: buildTalkloomTheme(Brightness.light),
          home: const Scaffold(body: UniversalIngestSheet()),
        ),
      ),
    );
    expect(
      find.text('Checking saved content and reading your source…'),
      findsOneWidget,
    );
    container.read(importProgressProvider.notifier).setStage('retrieved');
    await tester.pump();
    expect(
      find.text('Content retrieved. Preparing your words and grammar…'),
      findsOneWidget,
    );
    container.read(importProgressProvider.notifier).setStage('ready');
    await tester.pump();
    expect(find.text('Ready. Opening your takeaways…'), findsOneWidget);
    container.read(importControllerProvider.notifier).clearError();
    (container.read(importControllerProvider.notifier) as PendingImport).fail();
    await tester.pump();
    expect(
      find.textContaining('Could not finish this import.'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    (container.read(importControllerProvider.notifier) as PendingImport).finish(
      const LessonContent(
        lessonId: 1,
        sourceId: 2,
        objectives: [],
        vocabulary: [
          VocabularyItem(id: 'hallo', lemma: 'hallo', meaning: 'hello'),
        ],
        grammar: [
          GrammarRule(
            concept: 'Word order',
            sourceSentence: 'Ich lerne Deutsch.',
            explanation: 'The verb is second.',
          ),
        ],
        activities: [],
        conversation: ConversationPlan(
          role: '',
          situation: '',
          hiddenTargets: [],
          culturalNotes: [],
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Your content is ready'), findsOneWidget);
    expect(find.text('hallo'), findsOneWidget);
    await tester.tap(find.text('Grammar 1'));
    await tester.pumpAndSettle();
    expect(find.text('The verb is second.'), findsOneWidget);
  });
}
