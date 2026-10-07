import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/theme.dart';
import 'content_widgets.dart';

class ContentHome extends ConsumerWidget {
  const ContentHome({super.key, required this.today, required this.onAdd});
  final bool today;
  final VoidCallback onAdd;

  Future<void> _removeSource(
    BuildContext context,
    WidgetRef ref,
    Source source,
  ) async {
    final sourceId = source.id;
    if (sourceId == null) return;
    try {
      await ref.read(lessonRepositoryProvider).removeSource(sourceId);
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from your content'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await ref
                    .read(lessonRepositoryProvider)
                    .restoreSource(sourceId);
                ref.invalidate(sourcesProvider);
                ref.invalidate(lessonsProvider);
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Could not restore this item'),
                    ),
                  );
                }
              }
            },
          ),
        ),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(Failure.from(error).message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      await ref.read(sourcesProvider.future);
    },
    child: ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      children: [
        Text(
          today ? 'Today' : 'My content',
          style: context.type.headline,
        ),
        const SizedBox(height: 4),
        Text(
          today ? 'Pick a conversation.' : 'Keep speaking from your feed.',
          style: context.type.bodySmall,
        ),
        const SizedBox(height: 18),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOutCubic,
          child: Text(
            today ? 'Less saving. More saying.' : 'Your world, in German.',
            key: ValueKey(today),
            style: context.type.display.copyWith(fontSize: 30),
          ),
        ),
        const SizedBox(height: 20),
        ref
            .watch(sourcesProvider)
            .when(
              loading: () => const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => EditorialCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your content could not be loaded',
                      style: context.type.title,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Failure.from(error).message,
                      style: context.type.bodySmall,
                    ),
                    TextButton(
                      onPressed: () => ref.invalidate(sourcesProvider),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return EditorialCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.inbox,
                          size: 40,
                          color: context.colors.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nothing here yet',
                          style: context.type.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(Icons.add),
                          label: const Text('Add something'),
                        ),
                      ],
                    ),
                  );
                }
                final ordered = [...items]
                  ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (today) ...[
                      const SizedBox(height: 4),
                      _SourceCard(
                        source: ordered.first,
                        featured: true,
                        onRemove: () =>
                            _removeSource(context, ref, ordered.first),
                      ),
                      const SizedBox(height: 28),
                      if (ordered.length > 1) const SizedBox(height: 4),
                    ],
                    for (final source
                        in today ? ordered.skip(1).take(3) : ordered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _SourceCard(
                          source: source,
                          onRemove: () => _removeSource(context, ref, source),
                        ),
                      ),
                  ],
                );
              },
            ),
      ],
    ),
  );
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.source,
    required this.onRemove,
    this.featured = false,
  });
  final Source source;
  final VoidCallback onRemove;
  final bool featured;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: 1),
    duration: const Duration(milliseconds: 420),
    curve: Curves.easeOutCubic,
    builder: (context, value, child) => Opacity(
      opacity: value,
      child: Transform.translate(
        offset: Offset(0, 12 * (1 - value)),
        child: child,
      ),
    ),
    child: EditorialCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SourceArtwork(source: source, height: featured ? 170 : 110),
          const SizedBox(height: 16),
          SourceCaption(source: source),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(source.title, style: context.type.titleLarge),
              ),
              PopupMenuButton<String>(
                tooltip: 'Content options',
                onSelected: (value) {
                  if (value == 'remove') onRemove();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: 'remove',
                    child: Row(
                      children: [
                        Icon(LucideIcons.trash2, size: 18),
                        SizedBox(width: 10),
                        Text('Remove from my content'),
                      ],
                    ),
                  ),
                ],
                icon: const Icon(LucideIcons.ellipsis, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: source.id == null
                ? null
                : () => context.push('/content/${source.id}'),
            icon: const Icon(LucideIcons.mic, size: 18),
            label: const Text('Speak'),
          ),
        ],
      ),
    ),
  );
}
