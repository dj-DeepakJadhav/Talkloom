import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/ingest/universal_ingest_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/client.dart' as app_client;

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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    app_client.client = Client('http://localhost:1/')
      ..authSessionManager = FlutterAuthSessionManager(
        storage: app_client.MemoryAuthStorage(),
      );
    await app_client.client.auth.initialize();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        importControllerProvider.overrideWith(PendingImport.new),
      ],
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
      find.text('Starting…'),
      findsOneWidget,
    );
    container.read(importProgressProvider.notifier).setStage('retrieved');
    await tester.pump();
    expect(
      find.text('Source retrieved. Reading the text…'),
      findsOneWidget,
    );
    container.read(importProgressProvider.notifier).setStage('ready');
    await tester.pump();
    expect(find.text('Saved. Opening your lesson…'), findsOneWidget);
    container.read(importControllerProvider.notifier).clearError();
    (container.read(importControllerProvider.notifier) as PendingImport).fail();
    await tester.pump();
    expect(find.byType(AlertDialog), findsOneWidget);
    expect(find.text('Could not finish this import'), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
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
    expect(find.text('Your first activity is ready'), findsOneWidget);
    expect(find.text('hallo'), findsOneWidget);
    await tester.tap(find.text('Grammar 1'));
    await tester.pumpAndSettle();
    expect(find.text('The verb is second.'), findsOneWidget);
  });
}
