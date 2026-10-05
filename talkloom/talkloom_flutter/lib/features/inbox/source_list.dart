import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';

/// Everything the learner has imported in the active language.
class SourceList extends ConsumerWidget {
  const SourceList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sources = ref.watch(sourcesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your library', style: context.type.titleLarge),
        const SizedBox(height: TlSpace.sm),
        sources.when(
          loading: () => const Column(
            children: [
              TlSkeleton(height: 66, radius: TlRadius.md),
              SizedBox(height: TlSpace.xs),
              TlSkeleton(height: 66, radius: TlRadius.md),
            ],
          ),
          error: (error, _) => TlErrorState(
            message: Failure.from(error).message,
            onRetry: () => ref.invalidate(sourcesProvider),
          ),
          data: (items) {
            if (items.isEmpty) {
              return const TlEmptyState(
                icon: LucideIcons.inbox,
                title: 'Nothing here yet',
                message:
                    'Import a link or some text above and it will show up here '
                    'as a lesson you can come back to.',
              );
            }
            return Column(
              children: [
                for (final source in items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: TlSpace.xs),
                    child: _SourceRow(source: source),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _SourceRow extends ConsumerStatefulWidget {
  const _SourceRow({required this.source});

  final Source source;

  @override
  ConsumerState<_SourceRow> createState() => _SourceRowState();
}

class _SourceRowState extends ConsumerState<_SourceRow> {
  bool _isOpening = false;
  String? _error;

  Future<void> _open() async {
    final sourceId = widget.source.id;
    if (sourceId == null || _isOpening) return;

    setState(() {
      _isOpening = true;
      _error = null;
    });

    try {
      final lesson = await ref
          .read(lessonRepositoryProvider)
          .lessonForSource(sourceId);
      if (lesson == null) {
        setState(() => _error = 'That lesson is no longer available.');
        return;
      }
      ref
          .read(activeLessonProvider.notifier)
          .open(LessonContent.fromLesson(lesson));
      if (mounted) context.push(TlRoutes.lesson);
    } catch (error) {
      setState(() => _error = Failure.from(error).message);
    } finally {
      if (mounted) setState(() => _isOpening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final source = widget.source;
    final isLink = source.type == 'url';

    return Column(
      children: [
        TlPressable(
          onTap: _open,
          child: Container(
            padding: const EdgeInsets.all(TlSpace.md),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: TlRadius.controlRadius,
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    color: colors.infoSoft,
                    borderRadius: TlRadius.pillRadius,
                  ),
                  child: Icon(
                    isLink ? LucideIcons.link : LucideIcons.fileText,
                    size: 17,
                    color: colors.info,
                  ),
                ),
                const SizedBox(width: TlSpace.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        source.title,
                        style: context.type.bodyStrong,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          TlPill(label: source.cefrLevel),
                          const SizedBox(width: 6),
                          Text(
                            _relativeTime(source.createdAt),
                            style: context.type.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (_isOpening)
                  SizedBox(
                    height: 17,
                    width: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.textMuted,
                    ),
                  )
                else
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.textMuted,
                  ),
              ],
            ),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: TlSpace.xs),
          TlErrorState(message: _error!, onRetry: _open),
        ],
      ],
    );
  }

  static String _relativeTime(DateTime timestamp) {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';
    return '${(difference.inDays / 7).floor()}w ago';
  }
}
