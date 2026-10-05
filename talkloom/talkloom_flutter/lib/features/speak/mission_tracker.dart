import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/theme.dart';

/// Progress through the speaking mission.
///
/// Replaces the old "AI Mission Radar" HUD, which listed the hidden target
/// words on screen before the conversation started — telling the learner the
/// answers defeats the point of eliciting them spontaneously. This shows how
/// many targets are left and reveals each word only once it has been said.
class MissionTracker extends StatelessWidget {
  const MissionTracker({
    super.key,
    required this.totalTargets,
    required this.captured,
  });

  final int totalTargets;
  final List<String> captured;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    if (totalTargets == 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.target, size: 15, color: colors.textMuted),
              const SizedBox(width: 6),
              Text(
                captured.length >= totalTargets
                    ? 'Mission complete'
                    : 'Work ${totalTargets - captured.length} more phrases into '
                          'the conversation',
                style: context.type.caption,
              ),
            ],
          ),
          const SizedBox(height: TlSpace.xs),
          Row(
            children: [
              for (var i = 0; i < totalTargets; i++) ...[
                Expanded(
                  child: AnimatedContainer(
                    duration: TlMotion.medium,
                    curve: TlMotion.standard,
                    height: 5,
                    decoration: BoxDecoration(
                      color: i < captured.length
                          ? colors.success
                          : colors.surfaceSunken,
                      borderRadius: TlRadius.pillRadius,
                    ),
                  ),
                ),
                if (i < totalTargets - 1) const SizedBox(width: 4),
              ],
            ],
          ),
          if (captured.isNotEmpty) ...[
            const SizedBox(height: TlSpace.xs),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final target in captured)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.xs,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: colors.successSoft,
                      borderRadius: TlRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 11,
                          color: colors.success,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          target.contains(':')
                              ? target.split(':').last
                              : target,
                          style: context.type.caption.copyWith(
                            color: colors.successText,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
