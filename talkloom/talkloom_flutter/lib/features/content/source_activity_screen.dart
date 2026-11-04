import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart' show Source;
import '../../app/providers.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../../domain/practice_engine.dart';
import '../practice/practice_launcher.dart';
import 'content_widgets.dart';
import 'learning_components.dart';

/// Resolves the URL's source independently of the last in-memory activity.
class SourceActivityScope extends ConsumerWidget {
  const SourceActivityScope({
    super.key,
    required this.sourceId,
    required this.child,
  });
  final int sourceId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref
      .watch(sourceLessonProvider(sourceId))
      .when(
        loading: () => Scaffold(
          appBar: AppBar(title: const Text('Your lesson')),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (_, _) => Scaffold(
          appBar: AppBar(title: const Text('Your lesson')),
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(sourceLessonProvider(sourceId)),
              child: const Text('Retry loading lesson'),
            ),
          ),
        ),
        data: (saved) {
          if (saved == null) {
            return const _ActivityEmpty(
              title: 'Your lesson',
              message:
                  'This lesson is not ready yet. Return to the source to prepare it.',
            );
          }
          final source = ref
              .watch(sourcesProvider)
              .asData
              ?.value
              .where((s) => s.id == sourceId)
              .firstOrNull;
          return ProviderScope(
            overrides: [
              activeLessonProvider.overrideWith(
                () => _RouteLesson(LessonContent.fromLesson(saved)),
              ),
              selectedSourceProvider.overrideWith(() => _RouteSource(source)),
            ],
            child: child,
          );
        },
      );
}

class _RouteLesson extends ActiveLessonController {
  _RouteLesson(this.lesson);
  final LessonContent lesson;
  @override
  LessonContent? build() => lesson;
}

class _RouteSource extends SelectedSourceController {
  _RouteSource(this.source);
  final Source? source;
  @override
  Source? build() => source;
}

class VocabularyActivityScreen extends ConsumerStatefulWidget {
  const VocabularyActivityScreen({super.key});

  @override
  ConsumerState<VocabularyActivityScreen> createState() =>
      _VocabularyActivityScreenState();
}

class _VocabularyActivityScreenState
    extends ConsumerState<VocabularyActivityScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final lesson = ref.watch(activeLessonProvider);
    if (lesson == null || lesson.vocabulary.isEmpty) {
      return _ActivityEmpty(
        title: 'Vocabulary',
        message: 'No vocabulary was saved for this source yet.',
      );
    }
    final analytics = ref.watch(wordTrackingAnalyticsProvider);
    final items = lesson.vocabulary;
    final index = _index.clamp(0, items.length - 1);
    final word = items[index];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vocabulary'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: Text('${index + 1} / ${items.length}')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  VocabularyPresentation(word: word),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: index > 0
                              ? () => setState(() => _index = index - 1)
                              : null,
                          child: const Text('Previous'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            final args = PracticeLauncher.forLesson(
                              lesson,
                              analytics,
                              title:
                                  ref.read(selectedSourceProvider)?.title ??
                                  'Vocabulary',
                            );
                            if (args == null) return;
                            context.push('/practice', extra: args);
                          },
                          child: const Text('Practice'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: index + 1 < items.length
                        ? () => setState(() => _index = index + 1)
                        : () => context.pop(),
                    child: Text(
                      index + 1 < items.length ? 'Next word' : 'Done',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GrammarActivityScreen extends ConsumerWidget {
  const GrammarActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lesson = ref.watch(activeLessonProvider);
    if (lesson == null || lesson.grammar.isEmpty) {
      return const _ActivityEmpty(
        title: 'Grammar',
        message: 'No grammar patterns were saved for this source yet.',
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Grammar')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView.separated(
            padding: const EdgeInsets.all(24),
            itemCount: lesson.grammar.length,
            separatorBuilder: (_, _) => const SizedBox(height: 14),
            itemBuilder: (context, index) {
              final rule = lesson.grammar[index];
              return EditorialCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    GrammarExplanation(
                      concept: rule.concept,
                      explanation: rule.explanation,
                      sentence: rule.sourceSentence,
                    ),
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: () {
                        final args = PracticeLauncher.forLesson(
                          lesson,
                          ref.read(wordTrackingAnalyticsProvider),
                          title:
                              ref.read(selectedSourceProvider)?.title ??
                              'Grammar',
                          mode: PracticeMode.sentence,
                        );
                        if (args != null) {
                          context.push('/practice', extra: args);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'No sentence practice is available for this source yet.',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Try it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ActivityEmpty extends StatelessWidget {
  const _ActivityEmpty({required this.title, required this.message});
  final String title;
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: context.type.body,
        ),
      ),
    ),
  );
}
