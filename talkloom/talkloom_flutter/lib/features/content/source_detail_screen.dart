import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/app_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../design/theme.dart';
import '../../design/components/tl_sticker.dart';
import '../../design/components/tl_surface.dart';
import '../../domain/lesson_content.dart';
import 'content_widgets.dart';
import 'source_artwork_hero.dart';
import '../practice/practice_launcher.dart';

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

  void _practice(
    BuildContext context,
    WidgetRef ref,
    Source source,
    LessonContent lesson,
  ) {
    final args = PracticeLauncher.forLesson(
      lesson,
      ref.read(wordTrackingAnalyticsProvider),
      title: source.title,
    );
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This link has no words to practise yet.'),
        ),
      );
      return;
    }
    context.push(TlRoutes.practice, extra: args);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(title: const Text('Your lesson')),
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
                    SourceArtworkHero(
                      sourceId: source.id ?? -1,
                      subject: source.title,
                    ),
                    const SizedBox(height: 14),
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
                                  onLesson: lesson.hasPracticeContent
                                      ? () => _open(
                                          context,
                                          ref,
                                          source,
                                          lesson,
                                          TlRoutes.lesson,
                                        )
                                      : null,
                                  onPractice: lesson.hasPracticeContent
                                      ? () => _practice(
                                          context,
                                          ref,
                                          source,
                                          lesson,
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
                        title: const Text('Original source'),
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
            Text(importStageMessage(stage)),
          ] else
            FilledButton.icon(
              onPressed: _prepare,
              icon: const Icon(AppIcons.refreshCw, size: 18),
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

class _LessonKnowledgeTabs extends ConsumerStatefulWidget {
  const _LessonKnowledgeTabs({
    required this.lesson,
    required this.onSpeak,
    required this.onLesson,
    required this.onPractice,
  });

  final LessonContent lesson;
  final VoidCallback onSpeak;
  final VoidCallback? onLesson;
  final VoidCallback? onPractice;

  @override
  ConsumerState<_LessonKnowledgeTabs> createState() =>
      _LessonKnowledgeTabsState();
}

class _LessonKnowledgeTabsState extends ConsumerState<_LessonKnowledgeTabs> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    final sourceId = widget.lesson.sourceId;
    if (sourceId == null || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final session = ref.read(learningSessionProvider);
      await ref
          .read(lessonRepositoryProvider)
          .refreshLesson(session: session, sourceId: sourceId);
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      ref.invalidate(sourceLessonProvider(sourceId));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lesson refreshed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Failure.from(error).message)),
        );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = widget.lesson;
    final words = lesson.vocabulary;
    final grammar = lesson.grammar;
    final sourceId = lesson.sourceId;
    final sourcePath = sourceId == null ? null : '/content/$sourceId';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _ActivityTile(
              icon: AppIcons.bookOpenText,
              label: 'Vocabulary',
              count: words.length,
              onTap: sourcePath == null
                  ? null
                  : () => context.push('$sourcePath/vocabulary'),
            ),
            _ActivityTile(
              icon: AppIcons.spellCheck,
              label: 'Grammar',
              count: grammar.length,
              onTap: sourcePath == null
                  ? null
                  : () => context.push('$sourcePath/grammar'),
            ),
            _ActivityTile(
              icon: AppIcons.gamepad2,
              label: 'Play',
              onTap: widget.onPractice ?? widget.onLesson,
            ),
            _ActivityTile(
              icon: AppIcons.speech,
              label: 'Speak',
              onTap: widget.onSpeak,
            ),
          ],
        ),
        if (words.isNotEmpty && sourcePath != null) ...[
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => context.push('$sourcePath/vocabulary'),
            icon: const Icon(AppIcons.play, size: 18),
            label: const Text('Continue vocabulary'),
          ),
        ],
        const SizedBox(height: 8),
        Center(
          child: TextButton.icon(
            onPressed: _refreshing || sourceId == null ? null : _refresh,
            icon: _refreshing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(AppIcons.refreshCw, size: 16),
            label: Text(
              _refreshing ? 'Refreshing lesson…' : 'Refresh lesson',
            ),
          ),
        ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.count,
  });
  final IconData icon;
  final String label;
  final int? count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tint = switch (label) {
      'Grammar' => context.colors.infoSoft,
      'Play' => context.colors.successSoft,
      'Speak' => context.colors.primarySoft,
      _ => context.colors.surfaceRaised,
    };
    final face = Material(
      color: tint,
      elevation: 2,
      shadowColor: context.colors.shadow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: null,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  child: TlSticker(
                    kind: stickerKindForIcon(icon),
                    size: 100,
                    animate: false,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(label, style: context.type.label),
              if (count != null) Text('$count', style: context.type.labelSmall),
            ],
          ),
        ),
      ),
    );
    return onTap == null
        ? face
        : TlPressable(
            onTap: onTap!,
            semanticLabel: count == null ? label : '$label $count',
            child: SizedBox.expand(child: face),
          );
  }
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

/// One honest message per server-pushed import stage.
String importStageMessage(String stage) => switch (stage) {
  'queued' => 'Waiting for a free slot…',
  'fetching' => 'Fetching your source…',
  'transcript' || 'retrieved' => 'Source retrieved. Reading the text…',
  'compiling' => 'Extracting words and grammar from your source…',
  'validating' => 'Checking every word against your source…',
  'saved' || 'ready' => 'Saved. Opening your lesson…',
  'failed' => 'Lesson preparation failed.',
  _ => 'Starting…',
};
