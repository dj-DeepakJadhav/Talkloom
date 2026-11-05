import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/app_icons.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../../domain/word_tracking_analytics.dart';
import '../ingest/universal_ingest_sheet.dart';
import 'content_widgets.dart';

class MyGermanScreen extends ConsumerStatefulWidget {
  const MyGermanScreen({super.key});
  @override
  ConsumerState<MyGermanScreen> createState() => _MyGermanScreenState();
}

class _MyGermanScreenState extends ConsumerState<MyGermanScreen> {
  bool _grammar = false;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final sources = ref.watch(sourcesProvider).asData?.value ?? [];
    final savedState = ref.watch(lessonsProvider);
    final analyticsTracker = ref.watch(wordTrackingAnalyticsProvider);
    final analytics = analyticsTracker.analytics;
    final records = savedState.asData?.value ?? const [];
    final hasSavedLessons = records.isNotEmpty;
    final grammarCount = records.fold<int>(
      0,
      (total, lesson) =>
          total + LessonContent.fromLesson(lesson).grammar.length,
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Row(
          children: [
            Expanded(child: Text('My learning', style: context.type.headline)),
            Chip(
              label: Text(ref.watch(learningSessionProvider).target.endonym),
              side: BorderSide.none,
              backgroundColor: context.colors.surfaceSunken,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: false,
              label: Text('Vocabulary (${analytics.totalUniqueWords})'),
              icon: const Icon(AppIcons.bookOpen),
            ),
            ButtonSegment(
              value: true,
              label: Text('Grammar ($grammarCount)'),
              icon: const Icon(AppIcons.languages),
            ),
          ],
          selected: {_grammar},
          onSelectionChanged: (value) => setState(() => _grammar = value.first),
        ),
        if (hasSavedLessons) ...[
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) => setState(() => _query = value.toLowerCase()),
            decoration: const InputDecoration(
              prefixIcon: Icon(AppIcons.search),
              hintText: 'Search',
            ),
          ),
          const SizedBox(height: 20),
        ] else
          const SizedBox(height: 14),
        savedState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => EditorialCard(
            child: Column(
              children: [
                Text(Failure.from(error).message, style: context.type.body),
                TextButton(
                  onPressed: () => ref.invalidate(lessonsProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
          data: (saved) {
            final entries = <Widget>[];
            final seenLemmas = <String>{};

            for (final record in saved) {
              final lesson = LessonContent.fromLesson(record);
              final source = sources
                  .where((s) => s.id == record.sourceId)
                  .firstOrNull;
              final title = source?.title ?? 'Imported content';
              void openSource() => context.push('/content/${record.sourceId}');
              if (_grammar) {
                for (final rule in lesson.grammar) {
                  if (!'${rule.concept} ${rule.explanation}'
                      .toLowerCase()
                      .contains(_query)) {
                    continue;
                  }
                  entries.add(
                    _Entry(
                      title: rule.display,
                      description: rule.explanation,
                      quote: rule.sourceSentence,
                      source: title,
                      onSource: openSource,
                    ),
                  );
                }
              } else {
                for (final word in lesson.vocabulary) {
                  final lemmaKey = word.lemma.trim().toLowerCase();
                  if (seenLemmas.contains(lemmaKey)) continue;
                  seenLemmas.add(lemmaKey);

                  if (!'${word.display} ${word.meaning}'.toLowerCase().contains(
                    _query,
                  )) {
                    continue;
                  }

                  final tracked = analyticsTracker.getTrackedWord(word);
                  final status = analyticsTracker.getStatus(
                    word,
                    sourceId: record.sourceId,
                  );
                  final encounterCount = analyticsTracker.getEncounterCount(
                    word,
                  );

                  final badgeLabel =
                      tracked?.statusBadgeLabel(
                        currentSourceId: record.sourceId,
                      ) ??
                      (status == WordTrackingStatus.newWord
                          ? 'New'
                          : 'Seen 1×');

                  entries.add(
                    _Entry(
                      title: word.display,
                      badge: badgeLabel,
                      status: status,
                      repetitionCount: encounterCount,
                      description: word.meaning,
                      quote: word.sourceContext,
                      source: title,
                      onSource: openSource,
                    ),
                  );
                }
              }
            }
            if (entries.isEmpty) {
              if (saved.isEmpty) {
                return EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nothing here yet.', style: context.type.body),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => UniversalIngestSheet.show(context),
                        icon: const Icon(AppIcons.plus),
                        label: const Text('Add content'),
                      ),
                    ],
                  ),
                );
              }
              return EditorialCard(
                child: Text(
                  _query.isNotEmpty
                      ? 'No matches. Try a different word or meaning.'
                      : 'No ${_grammar ? 'grammar patterns' : 'words'} matching this filter.',
                  style: context.type.body,
                ),
              );
            }
            return Column(children: entries);
          },
        ),
      ],
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({
    required this.title,
    this.badge,
    this.status,
    this.repetitionCount,
    required this.description,
    required this.quote,
    required this.source,
    required this.onSource,
  });
  final String title;
  final String? badge;
  final WordTrackingStatus? status;
  final int? repetitionCount;
  final String description, quote, source;
  final VoidCallback onSource;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: EditorialCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(title, style: context.type.titleLarge),
                ),
                if (badge != null && status != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: switch (status!) {
                        WordTrackingStatus.newWord => colors.primarySoft,
                        WordTrackingStatus.repeated => colors.surfaceSunken,
                        WordTrackingStatus.practiced ||
                        WordTrackingStatus.mastered => colors.primarySoft,
                      },
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: switch (status!) {
                          WordTrackingStatus.newWord => colors.borderStrong,
                          WordTrackingStatus.repeated => colors.border,
                          WordTrackingStatus.practiced ||
                          WordTrackingStatus.mastered => colors.primary,
                        },
                      ),
                    ),
                    child: Text(
                      badge!,
                      style: context.type.labelSmall.copyWith(
                        color: switch (status!) {
                          WordTrackingStatus.newWord => colors.primary,
                          WordTrackingStatus.repeated => colors.textSecondary,
                          WordTrackingStatus.practiced ||
                          WordTrackingStatus.mastered => colors.primary,
                        },
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(description, style: context.type.bodySmall),
            if (quote.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('“$quote”', style: context.type.body),
            ],
            if (repetitionCount != null && repetitionCount! > 1) ...[
              const SizedBox(height: 6),
              Text(
                'Reinforced across $repetitionCount sources in your library',
                style: context.type.labelSmall.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onSource,
              icon: const Icon(AppIcons.arrowRight, size: 16),
              label: Text(
                'From $source',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
