import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/platform/web_voice_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import 'activity_view.dart';
import '../shell/talkloom_navigation_bar.dart';

/// Walks the learner through the targets, vocabulary with audio prompts,
/// sentence builder mini-games, and speaking mission.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  int _index = 0;

  void _next(List<LessonActivity> activities) {
    if (_index < activities.length - 1) {
      setState(() => _index++);
      return;
    }
    context.pushReplacement(TlRoutes.speak);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = ref.watch(activeLessonProvider);
    if (lesson == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        bottomNavigationBar: TalkloomNavigationBar(
          selectedIndex: 1,
          onDestinationSelected: (index) => context.go('/?tab=$index'),
        ),
        body: const Center(
          child: Text('Open your shared content to start a practice.'),
        ),
      );
    }

    final activities = lesson.activities;
    final total = activities.isEmpty ? 1 : activities.length;
    final progress = (_index + 1) / total;

    return Scaffold(
      bottomNavigationBar: TalkloomNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) => context.go('/?tab=$index'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TlSpace.maxContentWidth,
            ),
            child: Column(
              children: [
                // Top App Bar & Progress Indicator
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TlSpace.gutter,
                    TlSpace.sm,
                    TlSpace.gutter,
                    TlSpace.sm,
                  ),
                  child: Row(
                    children: [
                      TlPressable(
                        onTap: () => context.go(TlRoutes.home),
                        child: Icon(
                          LucideIcons.x,
                          size: 22,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: TlSpace.md),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: TlRadius.pillRadius,
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: TlMotion.medium,
                            curve: TlMotion.standard,
                            builder: (context, value, _) =>
                                LinearProgressIndicator(
                                  value: value,
                                  minHeight: 8,
                                  backgroundColor: colors.surfaceSunken,
                                  valueColor: AlwaysStoppedAnimation(
                                    colors.primary,
                                  ),
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: TlSpace.md),
                      Text(
                        '${_index + 1}/$total',
                        style: context.type.caption,
                      ),
                    ],
                  ),
                ),

                // Main Lesson Content Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.gutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (ref.watch(selectedSourceProvider)
                            case final source?) ...[
                          Text(
                            'From ${source.title}',
                            style: context.type.caption,
                          ),
                          const SizedBox(height: 12),
                        ],
                        // Targets & Objectives Card (rendered if first step or always accessible)
                        if (_index == 0) ...[
                          _ObjectivesCard(lesson: lesson),
                          const SizedBox(height: TlSpace.md),
                          if (lesson.vocabulary.isNotEmpty) ...[
                            _VocabularyAudioSection(
                              vocabulary: lesson.vocabulary,
                            ),
                            const SizedBox(height: TlSpace.md),
                          ],
                          _SpeakingMissionBanner(
                            conversation: lesson.conversation,
                          ),
                          const SizedBox(height: TlSpace.lg),
                        ],

                        // Interactive Activity Mini-Game
                        if (activities.isNotEmpty)
                          AnimatedSwitcher(
                            duration: TlMotion.medium,
                            switchInCurve: TlMotion.standard,
                            child: ActivityView(
                              key: ValueKey(_index),
                              activity: activities[_index],
                              onCompleted: () => _next(activities),
                            ),
                          )
                        else
                          _buildNoActivities(lesson),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoActivities(LessonContent lesson) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('What you will learn', style: context.type.titleLarge),
              const SizedBox(height: TlSpace.sm),
              if (lesson.objectives.isEmpty)
                Text(
                  'This source was short, so we will go straight to speaking.',
                  style: context.type.bodySmall,
                )
              else
                ...lesson.objectives.map(
                  (objective) => Padding(
                    padding: const EdgeInsets.only(bottom: TlSpace.xs),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          LucideIcons.check,
                          size: 17,
                          color: context.colors.success,
                        ),
                        const SizedBox(width: TlSpace.xs),
                        Expanded(
                          child: Text(objective, style: context.type.body),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: TlSpace.lg),
        TlButton(
          label: 'Start speaking',
          icon: LucideIcons.mic,
          tone: TlButtonTone.success,
          onPressed: () => context.pushReplacement(TlRoutes.speak),
        ),
      ],
    );
  }
}

class _ObjectivesCard extends StatefulWidget {
  const _ObjectivesCard({required this.lesson});

  final LessonContent lesson;

  @override
  State<_ObjectivesCard> createState() => _ObjectivesCardState();
}

class _ObjectivesCardState extends State<_ObjectivesCard> {
  bool _expandedTranscript = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = widget.lesson;

    return Column(
      children: [
        TlCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.target, size: 18, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Synthesized Lesson Targets', style: context.type.title),
                ],
              ),
              const SizedBox(height: TlSpace.xs),
              if (lesson.objectives.isEmpty)
                Text(
                  'Master essential syntax and key vocabulary from this video/source.',
                  style: context.type.bodySmall,
                )
              else
                ...lesson.objectives.map(
                  (obj) => Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.checkCircle2,
                          size: 14,
                          color: colors.success,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(obj, style: context.type.bodySmall),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (lesson.vocabulary.isNotEmpty &&
            lesson.vocabulary.any((v) => v.sourceContext.isNotEmpty)) ...[
          const SizedBox(height: TlSpace.sm),
          TlPressable(
            onTap: () =>
                setState(() => _expandedTranscript = !_expandedTranscript),
            child: TlCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.fileText, size: 16, color: colors.info),
                      const SizedBox(width: 8),
                      Text(
                        'Source Context & Lines',
                        style: context.type.bodyStrong,
                      ),
                      const Spacer(),
                      Icon(
                        _expandedTranscript
                            ? LucideIcons.chevronUp
                            : LucideIcons.chevronDown,
                        size: 16,
                        color: colors.textMuted,
                      ),
                    ],
                  ),
                  if (_expandedTranscript) ...[
                    const SizedBox(height: TlSpace.sm),
                    Text(
                      'Original context sentences extracted from the source material:',
                      style: context.type.caption,
                    ),
                    const SizedBox(height: TlSpace.xs),
                    for (final item in lesson.vocabulary.where(
                      (v) => v.sourceContext.isNotEmpty,
                    )) ...[
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: colors.surfaceSunken,
                          borderRadius: TlRadius.controlRadius,
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '• ',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                item.sourceContext,
                                style: context.type.bodySmall.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VocabularyAudioSection extends StatelessWidget {
  const _VocabularyAudioSection({required this.vocabulary});

  final List<VocabularyItem> vocabulary;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TlCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.volume2, size: 18, color: colors.info),
              const SizedBox(width: 8),
              Text('Expressions from your content', style: context.type.title),
              const Spacer(),
              TlPill(
                label: '${vocabulary.length} Words',
                background: colors.infoSoft,
                foreground: colors.info,
              ),
            ],
          ),
          const SizedBox(height: TlSpace.xs),
          Text(
            'Listen to the expressions from your content:',
            style: context.type.caption,
          ),
          const SizedBox(height: TlSpace.sm),
          for (final item in vocabulary) ...[
            _VocabularyItemRow(item: item),
            const SizedBox(height: TlSpace.xs),
          ],
        ],
      ),
    );
  }
}

class _VocabularyItemRow extends StatefulWidget {
  const _VocabularyItemRow({required this.item});

  final VocabularyItem item;

  @override
  State<_VocabularyItemRow> createState() => _VocabularyItemRowState();
}

class _VocabularyItemRowState extends State<_VocabularyItemRow> {
  bool _isPlaying = false;

  Future<void> _playAudio() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    final started = await WebVoiceService.instance.speak(
      widget.item.display,
      langCode: 'de-DE',
    );
    if (!mounted) return;
    if (!started) { setState(() => _isPlaying = false); return; }
    setState(() => _isPlaying = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.sm,
        vertical: TlSpace.xs,
      ),
      decoration: BoxDecoration(
        color: _isPlaying ? colors.primarySoft : colors.surfaceSunken,
        borderRadius: TlRadius.controlRadius,
        border: Border.all(
          color: _isPlaying ? colors.primary : colors.border,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.item.display,
                  style: context.type.bodyStrong.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  widget.item.meaning,
                  style: context.type.caption,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              _isPlaying ? LucideIcons.volume2 : LucideIcons.volume1,
              size: 18,
              color: _isPlaying ? colors.primary : colors.textSecondary,
            ),
            tooltip: 'Listen to this expression',
            onPressed: WebVoiceService.instance.canSpeak
                ? _playAudio
                : null,
          ),
        ],
      ),
    );
  }
}

class _SpeakingMissionBanner extends StatelessWidget {
  const _SpeakingMissionBanner({required this.conversation});

  final ConversationPlan conversation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      padding: const EdgeInsets.all(TlSpace.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.primarySoft,
            colors.surfaceRaised,
          ],
        ),
        borderRadius: TlRadius.cardRadius,
        border: Border.all(color: colors.primary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.mic, size: 22, color: colors.primary),
          const SizedBox(width: TlSpace.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upcoming Mission: ${conversation.role}',
                  style: context.type.bodyStrong.copyWith(
                    color: colors.primaryText,
                  ),
                ),
                Text(
                  conversation.situation,
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
