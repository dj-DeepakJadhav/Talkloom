import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/app_icons.dart';
import 'package:simple_icons/simple_icons.dart';
import '../../design/theme.dart';
import '../../design/components/tl_sticker.dart';
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
                child: Text(
                  'talkloom',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.titleLarge,
                ),
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
              final headline = count == null
                  ? 'Today in ${session.target.endonym}'
                  : count == 0
                  ? 'Today in ${session.target.endonym}, ready when you are'
                  : 'Today in ${session.target.endonym}, $count ${count == 1 ? 'piece' : 'pieces'} to continue';
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(headline, style: context.type.headline),
                  const SizedBox(height: 4),
                  Text(today, style: context.type.bodySmall),
                ],
              );
            },
          ),
          const SizedBox(height: 14),
          TlButton(onPressed: onAdd, icon: AppIcons.plus, label: 'Add content'),
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
                loading: () => const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(child: CircularProgressIndicator()),
                ),
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
                    // Single primary action lives above (Add content).
                    // Visual empty state: three illustrations, almost no text.
                    return EditorialCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Don\u2019t save it. Speak it.',
                            style: context.type.title,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: const [
                              _ShareVisual(
                                kind: TlStickerKind.link,
                                label: 'Share',
                              ),
                              _ShareVisual(
                                kind: TlStickerKind.book,
                                label: 'We prepare',
                              ),
                              _ShareVisual(
                                kind: TlStickerKind.speak,
                                label: 'You speak',
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Meta first: the competition we want to win.
                          // Brand glyphs in their original colors.
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _PlatformIcon(
                                icon: SimpleIcons.instagram,
                                label: 'Instagram',
                                color: const Color(0xFFE1306C),
                              ),
                              _PlatformIcon(
                                icon: SimpleIcons.facebook,
                                label: 'Facebook',
                                color: const Color(0xFF1877F2),
                              ),
                              _PlatformIcon(
                                icon: SimpleIcons.threads,
                                label: 'Threads',
                                color: null,
                              ),
                              _PlatformIcon(
                                icon: SimpleIcons.youtube,
                                label: 'YouTube',
                                color: const Color(0xFFFF0000),
                              ),
                              _PlatformIcon(
                                icon: SimpleIcons.tiktok,
                                label: 'TikTok',
                                color: null,
                              ),
                              _PlatformIcon(
                                icon: SimpleIcons.reddit,
                                label: 'Reddit',
                                color: const Color(0xFFFF4500),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const SizedBox(
                            width: double.infinity,
                            child: _PlatformMore(label: 'More'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Made for sharing from Meta apps, and the rest.',
                            style: context.type.caption,
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
                      Text('Continue', style: context.type.titleLarge),
                      const SizedBox(height: 12),
                      for (var i = 0; i < visible.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TlStagger(
                            index: i,
                            child: _SourceRow(
                              source: visible[i],
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
  const _SourceRow({required this.source, required this.onRemove});
  final Source source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: context.colors.surfaceRaised,
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
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.title,
                  maxLines: 1,
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
            icon: const Icon(AppIcons.play),
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

class _PlatformIcon extends StatelessWidget {
  const _PlatformIcon({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;

  /// Brand color. Null means the brand is monochrome (Threads, TikTok),
  /// so fall back to ink to stay visible in both themes.
  final Color? color;
  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    button: false,
    child: ExcludeSemantics(
      child: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.colors.surfaceSunken,
          shape: BoxShape.circle,
          border: Border.all(color: context.colors.border),
        ),
        child: Icon(
          icon,
          size: 20,
          color: color ?? context.colors.textPrimary,
        ),
      ),
    ),
  );
}

class _PlatformMore extends StatelessWidget {
  const _PlatformMore({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    height: 44,
    alignment: Alignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 14),
    decoration: BoxDecoration(
      color: context.colors.surfaceSunken,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: context.colors.border),
    ),
    child: Text('+more', style: context.type.labelSmall),
  );
}

class _ShareVisual extends StatelessWidget {
  const _ShareVisual({required this.kind, required this.label});
  final TlStickerKind kind;
  final String label;
  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        TlSticker(kind: kind, size: 84, animate: false),
        const SizedBox(height: 6),
        Text(label, style: context.type.labelSmall),
      ],
    ),
  );
}
