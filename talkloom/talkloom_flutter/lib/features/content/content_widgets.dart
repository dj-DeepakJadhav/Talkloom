import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../design/theme.dart';

String sourcePlatform(Source source) {
  final host = Uri.tryParse(source.url ?? '')?.host.toLowerCase() ?? '';
  if (host == 'youtu.be' ||
      host == 'youtube.com' ||
      host.endsWith('.youtube.com')) {
    return 'YouTube';
  }
  if (host == 'instagram.com' || host.endsWith('.instagram.com')) {
    return 'Instagram';
  }
  if (host.isNotEmpty) return host.replaceFirst('www.', '');
  return source.type == 'text' ? 'Your text' : 'Your upload';
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
  return 'https://i.ytimg.com/vi/$id/hqdefault.jpg';
}

class SourceArtwork extends StatelessWidget {
  const SourceArtwork({super.key, required this.source, this.height = 150});
  final Source source;
  final double height;
  @override
  Widget build(BuildContext context) {
    final thumbnail = sourceThumbnail(source);
    final placeholder = Container(
      height: height,
      width: double.infinity,
      color: context.colors.primarySoft,
      child: Center(
        child: Icon(
          source.type == 'url' ? LucideIcons.play : LucideIcons.fileText,
          size: 44,
          color: context.colors.primaryText,
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: thumbnail == null
          ? placeholder
          : Image.network(
              thumbnail,
              height: height,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => placeholder,
            ),
    );
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
    '${sourcePlatform(source)} · German · ${source.cefrLevel}',
    style: context.type.caption,
  );
}
