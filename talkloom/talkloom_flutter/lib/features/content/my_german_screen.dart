import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
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
    final records = savedState.asData?.value ?? const [];
    final vocabularyCount = records.fold<int>(
      0,
      (total, lesson) =>
          total + LessonContent.fromLesson(lesson).vocabulary.length,
    );
    final grammarCount = records.fold<int>(
      0,
      (total, lesson) =>
          total + LessonContent.fromLesson(lesson).grammar.length,
    );
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('My German', style: context.type.headline),
        const SizedBox(height: 4),
        Text(
          '$vocabularyCount words · $grammarCount grammar patterns',
          style: context.type.bodySmall,
        ),
        const SizedBox(height: 18),
        SegmentedButton<bool>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: false,
              label: Text('Words'),
              icon: Icon(LucideIcons.bookOpen),
            ),
            ButtonSegment(
              value: true,
              label: Text('Grammar'),
              icon: Icon(LucideIcons.languages),
            ),
          ],
          selected: {_grammar},
          onSelectionChanged: (value) => setState(() => _grammar = value.first),
        ),
        const SizedBox(height: 16),
        TextField(
          onChanged: (value) => setState(() => _query = value.toLowerCase()),
          decoration: const InputDecoration(
            prefixIcon: Icon(LucideIcons.search),
            hintText: 'Search your collection',
          ),
        ),
        const SizedBox(height: 20),
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
                      title: rule.concept,
                      description: rule.explanation,
                      quote: rule.sourceSentence,
                      source: title,
                      onSource: openSource,
                    ),
                  );
                }
              } else {
                for (final word in lesson.vocabulary) {
                  if (!'${word.display} ${word.meaning}'.toLowerCase().contains(
                    _query,
                  )) {
                    continue;
                  }
                  entries.add(
                    _Entry(
                      title: word.display,
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
              return EditorialCard(
                child: Text(
                  saved.isEmpty
                      ? 'Add a video, link or document to collect its words and grammar here.'
                      : _query.isNotEmpty
                      ? 'No matches. Try a different word or meaning.'
                      : 'No ${_grammar ? 'grammar patterns' : 'words'} were extracted from your content yet.',
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
    required this.description,
    required this.quote,
    required this.source,
    required this.onSource,
  });
  final String title, description, quote, source;
  final VoidCallback onSource;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: EditorialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.type.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: context.type.bodySmall),
          if (quote.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('“$quote”', style: context.type.body),
          ],
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onSource,
            icon: const Icon(Icons.arrow_outward, size: 16),
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
