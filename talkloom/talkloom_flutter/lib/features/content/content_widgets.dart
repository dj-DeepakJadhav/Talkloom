import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import '../../design/app_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../design/theme.dart';

enum SourceKind {
  youtubeVideo,
  youtubeShort,
  tiktok,
  instagram,
  article,
  text,
  file,
}

bool _hostIs(String host, String domain) =>
    host == domain || host.endsWith('.$domain');

/// Classifies a source from its URL host/path, falling back to its type.
SourceKind sourceKind(Source source) {
  final uri = Uri.tryParse((source.url ?? '').trim());
  final host = uri?.host.toLowerCase() ?? '';
  if (host.isNotEmpty) {
    if (host == 'youtu.be') return SourceKind.youtubeVideo;
    if (_hostIs(host, 'youtube.com')) {
      final parts = uri!.pathSegments;
      return parts.isNotEmpty && parts.first == 'shorts'
          ? SourceKind.youtubeShort
          : SourceKind.youtubeVideo;
    }
    if (_hostIs(host, 'tiktok.com')) return SourceKind.tiktok;
    if (_hostIs(host, 'instagram.com') || _hostIs(host, 'instagr.am')) {
      return SourceKind.instagram;
    }
    return SourceKind.article;
  }
  return source.type == 'text' ? SourceKind.text : SourceKind.file;
}

String sourcePlatform(Source source) {
  switch (sourceKind(source)) {
    case SourceKind.youtubeVideo:
    case SourceKind.youtubeShort:
      return 'YouTube';
    case SourceKind.tiktok:
      return 'TikTok';
    case SourceKind.instagram:
      return 'Instagram';
    case SourceKind.article:
      return Uri.parse(source.url!.trim()).host.toLowerCase().replaceFirst(
        'www.',
        '',
      );
    case SourceKind.text:
      return 'Your text';
    case SourceKind.file:
      return 'Your upload';
  }
}

IconData _kindIcon(SourceKind kind) => switch (kind) {
  SourceKind.youtubeVideo || SourceKind.youtubeShort => AppIcons.play,
  SourceKind.tiktok => AppIcons.film,
  SourceKind.instagram => AppIcons.camera,
  SourceKind.article => AppIcons.bookOpen,
  SourceKind.text => AppIcons.fileText,
  SourceKind.file => AppIcons.fileUp,
};

/// First ~90 characters of the source text, or the title when it is empty.
String sourceExcerpt(Source source, {int max = 90}) {
  final text = source.rawText.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return source.title;
  return text.length <= max ? text : '${text.substring(0, max).trimRight()}…';
}

String? sourceThumbnail(Source source) {
  final uri = Uri.tryParse(source.url ?? '');
  if (uri == null || sourcePlatform(source) != 'YouTube') return null;
  final parts = uri.pathSegments;
  final id = uri.host == 'youtu.be'
      ? (parts.isEmpty ? null : parts.first)
      : uri.queryParameters['v'] ??
            (parts.length >= 2 && ['shorts', 'embed'].contains(parts.first)
                ? parts[1]
                : null);
  if (id == null || !RegExp(r'^[a-zA-Z0-9_-]{11}$').hasMatch(id)) return null;
  // maxresdefault is a true 16:9 frame; hqdefault is 4:3 with baked-in black bars.
  return 'https://i.ytimg.com/vi/$id/maxresdefault.jpg';
}

/// Smaller but always-present 16:9 image for videos without a max-res frame.
String sourceThumbnailFallback(String thumbnail) =>
    thumbnail.replaceFirst('maxresdefault', 'mqdefault');

class SourceArtwork extends StatelessWidget {
  const SourceArtwork({
    super.key,
    required this.source,
    this.height = 150,
    this.compact = false,
  });
  final Source source;

  /// Height of the tile variant (used when there is no thumbnail).
  final double height;

  /// Fixed-[height] tile (instead of a 16:9 frame) when there is no thumbnail.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final kind = sourceKind(source);
    final thumbnail = sourceThumbnail(source);
    final fill = _SourceTile(source: source, kind: kind);
    final isShort = kind == SourceKind.youtubeShort;
    final Widget body;
    if (thumbnail == null) {
      body = compact
          ? _SourceTile(
              source: source,
              kind: kind,
              height: height,
            )
          : AspectRatio(aspectRatio: 16 / 9, child: fill);
    } else if (isShort) {
      body = AspectRatio(
        aspectRatio: 16 / 9,
        child: _ShortFrame(thumbnail: thumbnail, tile: fill),
      );
    } else {
      body = AspectRatio(
        aspectRatio: 16 / 9,
        child: _ThumbImage(thumbnail: thumbnail, tile: fill),
      );
    }
    return Semantics(
      container: true,
      label: '${sourcePlatform(source)}: ${source.title}',
      excludeSemantics: true,
      child: ClipRRect(borderRadius: BorderRadius.circular(16), child: body),
    );
  }
}

/// Network image with the max-res -> fallback -> designed tile chain and a
/// flat tile-coloured placeholder while loading.
class _ThumbImage extends StatelessWidget {
  const _ThumbImage({
    required this.thumbnail,
    required this.tile,
  });
  final String thumbnail;
  final Widget tile;

  Widget _load(BuildContext context, String url, Widget Function() onError) =>
      Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        excludeFromSemantics: true,
        frameBuilder: (context, child, frame, sync) => frame == null && !sync
            ? ColoredBox(color: context.colors.primarySoft)
            : child,
        errorBuilder: (_, _, _) => onError(),
      );

  @override
  Widget build(BuildContext context) => _load(
    context,
    thumbnail,
    () => _load(context, sourceThumbnailFallback(thumbnail), () => tile),
  );
}

class _ShortFrame extends StatelessWidget {
  const _ShortFrame({required this.thumbnail, required this.tile});
  final String thumbnail;
  final Widget tile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final h = c.maxHeight.isFinite ? c.maxHeight.clamp(0, 220.0) : 220.0;
      return Stack(
        fit: StackFit.expand,
        children: [
          ColoredBox(color: context.colors.primarySoft),
          ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 14,
              sigmaY: 14,
              tileMode: TileMode.clamp,
            ),
            child: Transform.scale(
              scale: 1.3,
              child: _ThumbImage(
                thumbnail: thumbnail,
                tile: const SizedBox.expand(),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              height: h.toDouble(),
              child: AspectRatio(
                aspectRatio: 9 / 16,
                child: _ThumbImage(thumbnail: thumbnail, tile: tile),
              ),
            ),
          ),
        ],
      );
    },
  );
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source, required this.kind, this.height});
  final Source source;
  final SourceKind kind;

  /// Fixed height for the compact variant; null keeps the 16:9 frame.
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final compact = height != null;
    final content = Padding(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_kindIcon(kind), size: 18, color: colors.primaryText),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      child: Text(
                        sourcePlatform(source),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.caption.copyWith(
                          color: colors.primaryText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              sourceExcerpt(source),
              maxLines: compact ? 2 : 3,
              overflow: TextOverflow.ellipsis,
              style: context.type.bodySmall.copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
    final box = ColoredBox(color: colors.primarySoft, child: content);
    return height == null
        ? SizedBox.expand(child: box)
        : SizedBox(height: height, width: double.infinity, child: box);
  }
}

class EditorialCard extends StatelessWidget {
  const EditorialCard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: Material(
      color: context.colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: context.colors.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    ),
  );
}

class SourceCaption extends StatelessWidget {
  const SourceCaption({super.key, required this.source});
  final Source source;
  @override
  Widget build(BuildContext context) => Text(
    '${sourcePlatform(source)} · ${source.cefrLevel}',
    style: context.type.caption,
  );
}
