import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import 'content_widgets.dart';
import '../shell/talkloom_navigation_bar.dart';

class SourceDetailScreen extends ConsumerWidget {
  const SourceDetailScreen({super.key, required this.sourceId});
  final int sourceId;

  void _open(
    BuildContext context,
    WidgetRef ref,
    Source source,
    LessonContent lesson,
    String route,
  ) {
    ref.read(selectedSourceProvider.notifier).select(source);
    ref.read(activeLessonProvider.notifier).open(lesson);
    context.push(route);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('From your content')),
    bottomNavigationBar: TalkloomNavigationBar(
      selectedIndex: 1,
      onDestinationSelected: (index) => context.go('/?tab=$index'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ref
            .watch(sourcesProvider)
            .when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => _Failure(
                message: Failure.from(error).message,
                onRetry: () => ref.invalidate(sourcesProvider),
              ),
              data: (sources) {
                final source = sources
                    .where((s) => s.id == sourceId)
                    .firstOrNull;
                if (source == null) {
                  return const Center(
                    child: Text(
                      'This source is not in your current collection.',
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    SourceArtwork(source: source, height: 180),
                    const SizedBox(height: 16),
                    SourceCaption(source: source),
                    const SizedBox(height: 8),
                    Text(source.title, style: context.type.headline),
                    const SizedBox(height: 20),
                    ref
                        .watch(sourceLessonProvider(sourceId))
                        .when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, _) => _Failure(
                            message: Failure.from(error).message,
                            onRetry: () =>
                                ref.invalidate(sourceLessonProvider(sourceId)),
                          ),
                          data: (saved) {
                            if (saved == null) {
                              return _PendingLesson(source: source);
                            }
                            final lesson = LessonContent.fromLesson(saved);
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _LessonKnowledgeTabs(
                                  lesson: lesson,
                                  onSpeak: () => _open(
                                    context,
                                    ref,
                                    source,
                                    lesson,
                                    TlRoutes.speak,
                                  ),
                                  onPractice: lesson.hasActivities
                                      ? () => _open(
                                          context,
                                          ref,
                                          source,
                                          lesson,
                                          TlRoutes.lesson,
                                        )
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                    const SizedBox(height: 20),
                    EditorialCard(
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Read the source text'),
                        subtitle: Text(
                          'Check the material behind your practice',
                          style: context.type.caption,
                        ),
                        children: [
                          SelectableText(
                            source.rawText,
                            style: context.type.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
      ),
    ),
  );
}

class _PendingLesson extends ConsumerStatefulWidget {
  const _PendingLesson({required this.source});
  final Source source;
  @override
  ConsumerState<_PendingLesson> createState() => _PendingLessonState();
}

class _PendingLessonState extends ConsumerState<_PendingLesson> {
  Timer? _timer;
  int _checks = 0;
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (++_checks >= 40) {
        timer.cancel();
        return;
      }
      ref.invalidate(sourceLessonProvider(widget.source.id!));
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _prepare() async {
    final source = widget.source;
    // Collection refresh can dispose this pending card before the import
    // future returns. Keep the router, rather than using this card's context
    // after the await, and only navigate if the learner is still on this page.
    final router = GoRouter.of(context);
    final originalPath = router.routeInformationProvider.value.uri.path;
    final importer = ref.read(importControllerProvider.notifier);
    final result = source.type == 'url' && source.url != null
        ? await importer.importUrl(title: source.title, url: source.url!)
        : await importer.importText(title: source.title, text: source.rawText);
    if (result?.sourceId == null ||
        router.routeInformationProvider.value.uri.path != originalPath) {
      return;
    }
    router.go('/content/${result!.sourceId}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(importControllerProvider);
    final stage = ref.watch(importProgressProvider);
    return EditorialCard(
      child: Column(
        children: [
          Text(
            state.isLoading
                ? 'Preparing words and grammar…'
                : 'Content retrieved. Your lesson is unfinished.',
            style: context.type.body,
          ),
          const SizedBox(height: 8),
          if (state.isLoading) ...[
            const LinearProgressIndicator(),
            Text(
              stage == 'retrieved'
                  ? 'Using the saved source text.'
                  : 'Checking saved results…',
            ),
          ] else
            FilledButton.icon(
              onPressed: _prepare,
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Prepare my lesson'),
            ),
          if (state.hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(Failure.from(state.error!).message),
            ),
        ],
      ),
    );
  }
}

class _LessonKnowledgeTabs extends StatefulWidget {
  const _LessonKnowledgeTabs({
    required this.lesson,
    required this.onSpeak,
    required this.onPractice,
  });

  final LessonContent lesson;
  final VoidCallback onSpeak;
  final VoidCallback? onPractice;

  @override
  State<_LessonKnowledgeTabs> createState() => _LessonKnowledgeTabsState();
}

class _LessonKnowledgeTabsState extends State<_LessonKnowledgeTabs> {
  bool _showGrammar = false;

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final words = lesson.vocabulary;
    final grammar = lesson.grammar;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Your takeaways', style: context.type.titleLarge),
        const SizedBox(height: 4),
        Text(
          'From this source · ${words.length} words · ${grammar.length} grammar patterns',
          style: context.type.bodySmall,
        ),
        const SizedBox(height: 16),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text('Words  ${words.length}'),
              icon: const Icon(LucideIcons.bookOpen, size: 16),
            ),
            ButtonSegment(
              value: true,
              label: Text('Grammar  ${grammar.length}'),
              icon: const Icon(LucideIcons.languages, size: 16),
            ),
          ],
          selected: {_showGrammar},
          onSelectionChanged: (value) =>
              setState(() => _showGrammar = value.first),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          child: _showGrammar
              ? _GrammarTakeaways(
                  key: const ValueKey('grammar'),
                  items: grammar,
                )
              : _WordTakeaways(key: const ValueKey('words'), items: words),
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: widget.onSpeak,
          icon: const Icon(LucideIcons.mic, size: 18),
          label: const Text('Speak about it'),
        ),
        if (widget.onPractice case final onPractice?) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onPractice,
            icon: const Icon(LucideIcons.gamepad2, size: 18),
            label: const Text('Play a quick practice'),
          ),
        ],
      ],
    );
  }
}

class _WordTakeaways extends StatelessWidget {
  const _WordTakeaways({super.key, required this.items});
  final List<VocabularyItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TakeawayEmpty(
        message: 'No words were extracted from this source.',
      );
    }
    return Column(
      children: [
        for (final word in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(word.display, style: context.type.title),
                  if (word.meaning.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(word.meaning, style: context.type.bodySmall),
                  ],
                  if (word.sourceContext.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('“${word.sourceContext}”', style: context.type.body),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _GrammarTakeaways extends StatelessWidget {
  const _GrammarTakeaways({super.key, required this.items});
  final List<GrammarRule> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _TakeawayEmpty(
        message: 'No grammar patterns were extracted from this source.',
      );
    }
    return Column(
      children: [
        for (final rule in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: EditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rule.concept, style: context.type.title),
                  if (rule.explanation.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(rule.explanation, style: context.type.bodySmall),
                  ],
                  if (rule.sourceSentence.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text('“${rule.sourceSentence}”', style: context.type.body),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TakeawayEmpty extends StatelessWidget {
  const _TakeawayEmpty({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => EditorialCard(
    child: Text(message, style: context.type.bodySmall),
  );
}

class _Failure extends StatelessWidget {
  const _Failure({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(message, style: context.type.body),
        TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
