import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/app_icons.dart';
import '../../design/theme.dart';
import '../../design/brand.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_states.dart';
import '../ads/ad_banner.dart';
import '../../domain/language.dart';
import 'content_widgets.dart';

class ContentHome extends ConsumerWidget {
  const ContentHome({super.key, required this.onAdd});
  final VoidCallback onAdd;

  Future<void> _removeSource(
    BuildContext context,
    WidgetRef ref,
    Source source,
  ) async {
    final id = source.id;
    if (id == null) return;
    try {
      await ref.read(lessonRepositoryProvider).removeSource(id);
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Removed from your learning'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () async {
              try {
                await ref.read(lessonRepositoryProvider).restoreSource(id);
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
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learningSessionProvider);
    final importState = ref.watch(importControllerProvider);
    final importing = importState.isLoading;
    final codes =
        ref
            .watch(sharedPreferencesProvider)
            .getStringList('talkloom.languages.v1') ??
        [session.target.code];
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(sourcesProvider);
        ref.invalidate(lessonsProvider);
        await ref.read(sourcesProvider.future);
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        children: [
          Row(
            children: [
              Expanded(
                child: const Align(alignment: Alignment.centerLeft,
                  child: FittedBox(fit: BoxFit.scaleDown, child: TalkloomWordmark())),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                tooltip: 'Change learning language',
                onSelected: (code) async {
                  await ref
                      .read(learningSessionProvider.notifier)
                      .switchTarget(LanguageCatalog.byCode(code));
                  ref.invalidate(sourcesProvider);
                  ref.invalidate(lessonsProvider);
                  ref.invalidate(learnerStateProvider);
                  ref.invalidate(wordEvidenceProvider);
                },
                itemBuilder: (context) => codes
                    .map(
                      (code) => PopupMenuItem(
                        value: code,
                        child: Text(LanguageCatalog.byCode(code).endonym),
                      ),
                    )
                    .toList(),
                child: Chip(
                  avatar: const Icon(AppIcons.chevronDown, size: 16),
                  label: SizedBox(
                    width: 94,
                    child: Text(
                      session.target.endonym,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  backgroundColor: context.colors.surfaceSunken,
                  side: BorderSide.none,
                ),
              ),
              IconButton(
                tooltip: 'Profile',
                onPressed: () => context.go('/?tab=2'),
                icon: const Icon(AppIcons.userRound),
              ),
            ],
          ),
          const SizedBox(height: 26),
          Consumer(
            builder: (context, ref, _) {
              final countAsync = ref.watch(sourcesProvider);
              final count = countAsync.maybeWhen(
                data: (items) => items.length,
                orElse: () => null,
              );
              final today = MaterialLocalizations.of(
                context,
              ).formatMediumDate(DateTime.now());
              final headline = count == 0
                  ? 'Make room for your words.'
                  : 'Your next conversation';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: context.type.headline),
                  const SizedBox(height: 4),
                  Text(
                    '${session.target.endonym} · $today',
                    style: context.type.bodySmall,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          ref
              .watch(sourcesProvider)
              .maybeWhen(
                data: (items) => items.isEmpty
                    ? TlButton(
                        onPressed: onAdd,
                        icon: AppIcons.plus,
                        label: 'Add content',
                      )
                    : Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: onAdd,
                          icon: const Icon(AppIcons.plus, size: 18),
                          label: const Text('Add content'),
                        ),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
          const SizedBox(height: 30),
          if (importState.hasError) ...[
            EditorialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Could not prepare content', style: context.type.title),
                  const SizedBox(height: 8),
                  Text(
                    Failure.from(importState.error!).message,
                    style: context.type.bodySmall,
                  ),
                  TextButton(
                    onPressed: onAdd,
                    child: const Text('Try another source'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (importing) ...[
            EditorialCard(
              child: Row(
                children: [
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Preparing your content')),
                  TextButton(
                    onPressed: onAdd,
                    child: const Text('View progress'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          ref
              .watch(sourcesProvider)
              .when(
                loading: () => const ContentLoading(),
                error: (error, _) => EditorialCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Could not load your learning',
                        style: context.type.title,
                      ),
                      const SizedBox(height: 6),
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
                    if (importing) return const SizedBox.shrink();
                    return EditorialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            AppIcons.bookOpenText,
                            size: 32,
                            color: context.colors.success,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Bring something you want to talk about.',
                            style: context.type.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'A video, an article, a few lines of text. We’ll help you find the words and use them in conversation.',
                            style: context.type.body,
                          ),
                        ],
                      ),
                    );
                  }
                  final ordered = [...items]
                    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
                  final visible = ordered.take(4).toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Continue', style: context.type.title),
                      const SizedBox(height: 12),
                      for (var i = 0; i < visible.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TlStagger(
                            index: i,
                            child: _SourceRow(
                              source: visible[i],
                              featured: i == 0,
                              onRemove: () =>
                                  _removeSource(context, ref, visible[i]),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
          const SizedBox(height: 16),
          // Free-tier funding: AdSense on web, AdMob on Android/iOS.
          // Hidden until AdConfig.adsEnabled is true with real IDs.
          const AdBanner(),
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  const _SourceRow({
    required this.source,
    required this.onRemove,
    this.featured = false,
  });
  final bool featured;
  final Source source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: featured ? context.colors.surfaceRaised : context.colors.canvas,
    margin: EdgeInsets.zero,
    shape: RoundedRectangleBorder(
      side: BorderSide(color: context.colors.border),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      child: Row(
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SourceArtwork(
                source: source,
                compact: true,
                height: 64,
                decorative: true,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sourceDisplayTitle(source),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.title,
                ),
                const SizedBox(height: 3),
                SourceCaption(source: source),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Continue learning',
            onPressed: source.id == null
                ? null
                : () => context.push('/content/${source.id}'),
            icon: const Icon(AppIcons.arrowRight, size: 20),
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
                    Icon(AppIcons.trash2, size: 18),
                    SizedBox(width: 10),
                    Text('Remove'),
                  ],
                ),
              ),
            ],
            icon: const Icon(AppIcons.ellipsis, size: 20),
          ),
        ],
      ),
    ),
  );
}
