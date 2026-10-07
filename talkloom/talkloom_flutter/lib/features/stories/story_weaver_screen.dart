import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';

/// Story audio is not connected to user-owned source material yet.
class StoryWeaverScreen extends ConsumerWidget {
  const StoryWeaverScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: Padding(
            padding: const EdgeInsets.all(TlSpace.gutter),
            child: TlCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.headphones, size: 36, color: colors.primary),
                  const SizedBox(height: TlSpace.md),
                  Text(
                    'Stories from your content are not available yet',
                    style: context.type.title,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: TlSpace.xs),
                  Text(
                    'Talkloom is focused on speaking and practice from the material you add. Story audio will return when it is connected to your saved content.',
                    style: context.type.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
