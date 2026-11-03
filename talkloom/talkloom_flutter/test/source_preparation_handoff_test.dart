import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart';
import 'package:talkloom_flutter/app/providers.dart';
import 'package:talkloom_flutter/domain/lesson_content.dart';
import 'package:talkloom_flutter/design/theme.dart';
import 'package:talkloom_flutter/features/content/source_detail_screen.dart';

class RefreshingImport extends ImportController {
  final completion = Completer<LessonContent>();
  @override
  Future<LessonContent?> importText({
    required String title,
    required String text,
  }) async {
    state = const AsyncValue.loading();
    final result = await completion.future;
    state = AsyncValue.data(result);
    ref.invalidate(sourcesProvider);
    // Force the pending card to be disposed before its callback resumes.
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return result;
  }
}

void main() {
  testWidgets('collection refresh cannot lose the completed source handoff', (
    tester,
  ) async {
    final source = Source(
      id: 7,
      userId: 'test',
      type: 'text',
      title: 'German passage',
      rawText: 'Ich lerne Deutsch.',
      targetLanguage: 'de',
      cefrLevel: 'A1',
      createdAt: DateTime.now(),
    );
    var refreshed = false;
    final container = ProviderContainer(
      overrides: [
        importControllerProvider.overrideWith(RefreshingImport.new),
        sourcesProvider.overrideWith((ref) async => refreshed ? [] : [source]),
        sourceLessonProvider(7).overrideWith((ref) async => null),
      ],
    );
    final router = GoRouter(
      initialLocation: '/content/7',
      routes: [
        GoRoute(
          path: '/content/:id',
          builder: (context, state) => state.pathParameters['id'] == '7'
              ? const SourceDetailScreen(sourceId: 7)
              : const Scaffold(body: Text('Actual completed lesson')),
        ),
      ],
    );
    addTearDown(container.dispose);
    addTearDown(router.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: buildTalkloomTheme(Brightness.light),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Prepare my lesson'));
    await tester.pump();
    refreshed = true;
    (container.read(importControllerProvider.notifier) as RefreshingImport)
        .completion
        .complete(
          const LessonContent(
            lessonId: 9,
            sourceId: 8,
            objectives: [],
            vocabulary: [],
            activities: [],
            conversation: ConversationPlan.empty,
          ),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
    expect(router.routeInformationProvider.value.uri.path, '/content/8');
    expect(find.text('Actual completed lesson'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
