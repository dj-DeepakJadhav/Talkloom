import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../design/app_icons.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../../domain/practice_engine.dart';
import '../content/content_widgets.dart';
import 'practice_launcher.dart';
import 'practice_session_screen.dart';

/// The Practice tab: games over every word the learner has collected, and the
/// same games for one link at a time, grouped by where the link came from.
class PracticeHome extends ConsumerWidget {
  const PracticeHome({super.key, required this.onAdd});
  final VoidCallback onAdd;

  void _start(BuildContext context, PracticeSessionArgs? args) {
    if (args == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Not enough words yet for this game. Add more content.',
          ),
        ),
      );
      return;
    }
    context.push(TlRoutes.practice, extra: args);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lessons = ref.watch(lessonsProvider);
    final sources = ref.watch(sourcesProvider);
    final analytics = ref.watch(wordTrackingAnalyticsProvider);

    return lessons.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => TlErrorState(
        message: Failure.from(error).message,
        onRetry: () => ref.invalidate(lessonsProvider),
      ),
      data: (lessonList) {
        final contents = {
          for (final l in lessonList) l.sourceId: LessonContent.fromLesson(l),
        };
        final wordCount = contents.values.fold<int>(
          0,
          (sum, c) => sum + c.vocabulary.length,
        );
        final sourceList = sources.asData?.value ?? const <Source>[];

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          children: [
            Text('Practice', style: context.type.headline),
            const SizedBox(height: 4),
            Text(
              'Games made from the words and sentences in your own links.',
              style: context.type.bodySmall,
            ),
            const SizedBox(height: TlSpace.lg),
            if (wordCount == 0)
              TlEmptyState(
                icon: AppIcons.gamepad2,
                title: 'Nothing to practise yet',
                message:
                    'Add a link and its words and sentences become games here.',
                actionLabel: 'Add something',
                onAction: onAdd,
              )
            else ...[
              _HeroCard(
                wordCount: wordCount,
                linkCount: contents.length,
                onStart: () => _start(
                  context,
                  PracticeLauncher.forAllWords(lessonList, analytics),
                ),
              ),
              const SizedBox(height: TlSpace.xl),
              Text('Choose a game', style: context.type.titleLarge),
              const SizedBox(height: TlSpace.sm),
              _GameGrid(
                onPick: (mode) => _start(
                  context,
                  PracticeLauncher.forAllWords(
                    lessonList,
                    analytics,
                    mode: mode,
                  ),
                ),
              ),
              const SizedBox(height: TlSpace.xl),
              Text('Practise one link', style: context.type.titleLarge),
              const SizedBox(height: TlSpace.sm),
              _LinkGroups(
                sources: sourceList
                    .where((s) => contents.containsKey(s.id))
                    .toList(),
                contents: contents,
                onPractice: (source, content) => _start(
                  context,
                  PracticeLauncher.forLesson(
                    content,
                    analytics,
                    title: source.title,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.wordCount,
    required this.linkCount,
    required this.onStart,
  });

  final int wordCount;
  final int linkCount;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TlCard(
      padding: const EdgeInsets.all(TlSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.dumbbell, color: colors.primary),
              const SizedBox(width: TlSpace.xs),
              Expanded(
                child: Text('Practise my words', style: context.type.title),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$wordCount words from $linkCount '
            '${linkCount == 1 ? 'link' : 'links'}. Words you keep meeting '
            'but have not practised come first.',
            style: context.type.bodySmall,
          ),
          const SizedBox(height: TlSpace.md),
          TlButton(label: 'Start', icon: AppIcons.play, onPressed: onStart),
        ],
      ),
    );
  }
}

class _GameGrid extends StatelessWidget {
  const _GameGrid({required this.onPick});
  final ValueChanged<PracticeMode> onPick;

  static const _games = [
    (
      PracticeMode.match,
      AppIcons.puzzle,
      'Word match',
      'Pair words with meanings',
    ),
    (
      PracticeMode.listen,
      AppIcons.headphones,
      'Listening',
      'Tap what you hear',
    ),
    (
      PracticeMode.gap,
      AppIcons.pencil,
      'Fill the gap',
      'Finish real sentences',
    ),
    (
      PracticeMode.sentence,
      AppIcons.languages,
      'Build sentences',
      'Put words in order',
    ),
  ];

  Widget _tile(
    BuildContext context,
    (PracticeMode, IconData, String, String) game,
  ) {
    final (mode, icon, title, subtitle) = game;
    return TlCard(
      onTap: () => onPick(mode),
      padding: const EdgeInsets.all(TlSpace.md),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: context.colors.info, size: 26),
            const SizedBox(height: TlSpace.sm),
            Text(title, style: context.type.bodyStrong),
            Text(subtitle, style: context.type.caption),
          ],
        ),
      ),
    );
  }

  /// Two cards a row, each row as tall as its taller card, so large text
  /// grows the cards instead of overflowing them.
  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (var i = 0; i < _games.length; i += 2) ...[
        if (i > 0) const SizedBox(height: TlSpace.sm),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _tile(context, _games[i])),
              const SizedBox(width: TlSpace.sm),
              Expanded(child: _tile(context, _games[i + 1])),
            ],
          ),
        ),
      ],
    ],
  );
}

String _providerLabel(Source source) => switch (source.platform) {
  'youtube' => 'YouTube',
  'tiktok' => 'TikTok',
  'instagram' => 'Instagram',
  'reddit' => 'Reddit',
  'x' => 'X',
  'facebook' => 'Facebook',
  'web' => 'Web',
  'text' => 'Your text',
  'document' => 'Your documents',
  'image' => 'Your images',
  _ => sourcePlatform(source),
};

class _LinkGroups extends StatelessWidget {
  const _LinkGroups({
    required this.sources,
    required this.contents,
    required this.onPractice,
  });

  final List<Source> sources;
  final Map<int, LessonContent> contents;
  final void Function(Source source, LessonContent content) onPractice;

  @override
  Widget build(BuildContext context) {
    final byProvider = <String, List<Source>>{};
    for (final s in sources) {
      byProvider.putIfAbsent(_providerLabel(s), () => []).add(s);
    }
    final labels = byProvider.keys.toList()..sort();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final label in labels) ...[
          Padding(
            padding: const EdgeInsets.only(top: TlSpace.sm, bottom: TlSpace.xs),
            child: Text(label, style: context.type.label),
          ),
          for (final source in byProvider[label]!)
            Padding(
              padding: const EdgeInsets.only(bottom: TlSpace.xs),
              child: _LinkRow(
                source: source,
                content: contents[source.id]!,
                onPractice: () => onPractice(source, contents[source.id]!),
              ),
            ),
        ],
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({
    required this.source,
    required this.content,
    required this.onPractice,
  });

  final Source source;
  final LessonContent content;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (source.creator != null && source.creator!.isNotEmpty) source.creator!,
      '${content.vocabulary.length} words',
      if (content.grammar.isNotEmpty) '${content.grammar.length} grammar',
    ].join(' · ');
    return TlCard(
      padding: const EdgeInsets.all(TlSpace.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(detail, style: context.type.caption),
              ],
            ),
          ),
          const SizedBox(width: TlSpace.sm),
          TlButton(
            label: 'Practise',
            size: TlButtonSize.compact,
            isFullWidth: false,
            onPressed: onPractice,
          ),
        ],
      ),
    );
  }
}
