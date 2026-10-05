import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';

/// Words the learner understands, and how many they have actually said.
///
/// Named for what it renders. The previous version was titled "Speaking
/// Streak" with a flame icon while showing a vocabulary ratio; real streak
/// mechanics are Phase 7 work and deliberately absent here.
class MasteryCard extends ConsumerWidget {
  const MasteryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final session = ref.watch(learningSessionProvider);
    final learnerState = ref.watch(learnerStateProvider);

    return TlCard(
      child: learnerState.when(
        loading: () => const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TlSkeleton(height: 18, width: 160),
            SizedBox(height: TlSpace.md),
            TlSkeleton(height: 10),
          ],
        ),
        error: (_, _) => Text(
          'Progress is unavailable right now.',
          style: context.type.bodySmall,
        ),
        data: (state) {
          final recognised = state?.recognizedWords.length ?? 0;
          final spoken = state?.activeWords.length ?? 0;
          final total = recognised + spoken;
          final ratio = total == 0 ? 0.0 : spoken / total;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    '${session.target.endonym} progress',
                    style: context.type.title,
                  ),
                  const Spacer(),
                  if (total > 0)
                    Text(
                      '${(ratio * 100).round()}% spoken',
                      style: context.type.caption.copyWith(
                        color: colors.success,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: TlSpace.md),
              ClipRRect(
                borderRadius: TlRadius.pillRadius,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: ratio),
                  duration: TlMotion.slow,
                  curve: TlMotion.standard,
                  builder: (context, value, _) => LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    backgroundColor: colors.surfaceSunken,
                    valueColor: AlwaysStoppedAnimation(colors.success),
                  ),
                ),
              ),
              const SizedBox(height: TlSpace.md),
              if (total == 0)
                Text(
                  'Finish a speaking mission and the words you actually use '
                  'will show up here.',
                  style: context.type.bodySmall,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: _Metric(
                        icon: LucideIcons.eye,
                        value: recognised,
                        label: 'understood',
                      ),
                    ),
                    const SizedBox(width: TlSpace.xs),
                    Expanded(
                      child: _Metric(
                        icon: LucideIcons.mic,
                        value: spoken,
                        label: 'spoken',
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.value, required this.label});

  final IconData icon;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TlSunken(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.sm,
        vertical: TlSpace.sm,
      ),
      child: Row(
        children: [
          Icon(icon, size: 17, color: colors.textMuted),
          const SizedBox(width: TlSpace.xs),
          Text('$value', style: context.type.numeric),
          const SizedBox(width: TlSpace.xxs),
          Flexible(
            child: Text(
              label,
              style: context.type.caption,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
