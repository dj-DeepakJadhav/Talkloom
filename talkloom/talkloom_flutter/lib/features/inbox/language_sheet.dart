import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/language.dart';

/// Switches the active target language.
///
/// The backend already isolates learner state per language, so switching is
/// free — a learner can be B2 in one language and a beginner in another
/// without their evidence mixing.
Future<void> showLanguageSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (sheetContext) => const _LanguageSheet(),
  );
}

class _LanguageSheet extends ConsumerWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final session = ref.watch(learningSessionProvider);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.75,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(TlRadius.xl),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(
                top: TlSpace.sm,
                bottom: TlSpace.md,
              ),
              child: Container(
                height: 4,
                width: 40,
                decoration: BoxDecoration(
                  color: colors.borderStrong,
                  borderRadius: TlRadius.pillRadius,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
              child: Row(
                children: [
                  Text('I am learning', style: context.type.titleLarge),
                  const Spacer(),
                  Text(
                    'Explained in ${session.support.englishName}',
                    style: context.type.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: TlSpace.sm),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(
                  TlSpace.gutter,
                  TlSpace.xs,
                  TlSpace.gutter,
                  TlSpace.lg,
                ),
                itemCount: LanguageCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(height: TlSpace.xs),
                itemBuilder: (context, index) {
                  final language = LanguageCatalog.all[index];
                  final isActive = language == session.target;
                  final isSupport = language == session.support;

                  return Opacity(
                    opacity: isSupport ? 0.35 : 1,
                    child: IgnorePointer(
                      ignoring: isSupport,
                      child: TlPressable(
                        onTap: () async {
                          await ref
                              .read(learningSessionProvider.notifier)
                              .switchTarget(language);
                          if (context.mounted) Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TlSpace.md,
                            vertical: TlSpace.sm,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? colors.primarySoft
                                : colors.surface,
                            borderRadius: TlRadius.controlRadius,
                            border: Border.all(
                              color: isActive ? colors.primary : colors.border,
                              width: isActive ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Text(
                                language.flag,
                                style: const TextStyle(fontSize: TlGlyph.md),
                              ),
                              const SizedBox(width: TlSpace.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      language.endonym,
                                      style: context.type.bodyStrong,
                                    ),
                                    Text(
                                      language.englishName,
                                      style: context.type.caption,
                                    ),
                                  ],
                                ),
                              ),
                              if (isActive)
                                Icon(
                                  LucideIcons.check,
                                  size: 20,
                                  color: colors.primary,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
