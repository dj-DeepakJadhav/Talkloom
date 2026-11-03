import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../design/components/tl_sticker.dart';
import '../../design/theme.dart';

/// Memoized house-style scene art per source. The server caches the bytes;
/// this provider memoizes the base64 within the session. Null (or any
/// failure) means "show the designed sticker banner instead".
final sourceArtworkProvider =
    FutureProvider.autoDispose.family<String?, ({int id, String subject})>((
      ref,
      key,
    ) async {
      return ref
          .watch(lessonRepositoryProvider)
          .illustrateSource(key.subject);
    });

/// 16:9 scene hero for the source detail. Shows a tonal shimmer while
/// Muse Image renders, the illustration when ready, and the designed
/// sticker banner whenever illustration is unavailable.
class SourceArtworkHero extends ConsumerWidget {
  const SourceArtworkHero({
    super.key,
    required this.sourceId,
    required this.subject,
  });

  final int sourceId;
  final String subject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final artwork = ref.watch(
      sourceArtworkProvider((id: sourceId, subject: subject)),
    );
    return artwork.when(
      loading: () => Container(
        height: 180,
        decoration: BoxDecoration(
          color: context.colors.surfaceSunken,
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, _) => const _StickerBanner(),
      data: (base64Image) {
        if (base64Image == null || base64Image.isEmpty) {
          return const _StickerBanner();
        }
        try {
          return ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.memory(
                base64Decode(base64Image),
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => const _StickerBanner(),
              ),
            ),
          );
        } catch (_) {
          return const _StickerBanner();
        }
      },
    );
  }
}

class _StickerBanner extends StatelessWidget {
  const _StickerBanner();

  @override
  Widget build(BuildContext context) => Container(
    height: 112,
    decoration: BoxDecoration(
      color: context.colors.surfaceSunken,
      borderRadius: BorderRadius.circular(22),
    ),
    child: const Center(
      child: TlSticker(kind: TlStickerKind.book, size: 132),
    ),
  );
}
