import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../app/router.dart';
import '../../design/app_icons.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../design/components/tl_sticker.dart';
import '../../design/components/tl_arrival.dart';
import '../../domain/lesson_content.dart';
import '../../domain/practice_engine.dart';
import 'exercise_widgets.dart';

/// Everything a session needs, passed through the router.
@immutable
class PracticeSessionArgs {
  const PracticeSessionArgs({
    required this.title,
    required this.set,
    this.finishLabel,
    this.finishRoute,
    this.voiceLocale = 'de-DE',
  });

  final String title;
  final PracticeSet set;

  /// An optional closing action, such as starting the speaking mission.
  final String? finishLabel;
  final String? finishRoute;
  final String voiceLocale;
}

/// A Duolingo-style run through a [PracticeSet]: one exercise at a time, a
/// Check bar that turns green or red, missed questions that come back, and a
/// summary at the end. Nothing here is saved as mastery; the summary reports
/// only what happened in this session.
class PracticeSessionScreen extends StatefulWidget {
  const PracticeSessionScreen({super.key, required this.args});
  final PracticeSessionArgs args;

  @override
  State<PracticeSessionScreen> createState() => _PracticeSessionScreenState();
}

class _PracticeSessionScreenState extends State<PracticeSessionScreen> {
  late final List<PracticeExercise> _queue = [...widget.args.set.exercises];
  final _retried = <PracticeExercise>{};
  var _index = 0;
  var _correct = 0;
  var _asked = 0;
  var _binding = ExerciseBinding();

  bool get _finished => _index >= _queue.length;
  PracticeExercise get _current => _queue[_index];
  bool get _isIntro => !_finished && _current is WordIntroExercise;

  @override
  void dispose() {
    _binding.dispose();
    super.dispose();
  }

  void _check() {
    if (!_binding.canCheck || _binding.isChecked) return;
    final result = _binding.check();
    if (_isIntro) return;
    _asked++;
    if (result.correct) {
      _correct++;
      // Fire at the scale/glow peak (~150 ms into the 280 ms pop).
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        HapticFeedback.lightImpact();
      });
    } else {
      // Fire at the shake midpoint (~175 ms into the 350 ms shake).
      Future<void>.delayed(const Duration(milliseconds: 175), () {
        HapticFeedback.heavyImpact();
      });
      // A missed question comes back once at the end, as in Duolingo.
      if (_retried.add(_current)) _queue.add(_current);
    }
    setState(() {});
  }

  void _next() {
    setState(() {
      _index++;
      _binding.dispose();
      _binding = ExerciseBinding();
    });
  }

  Future<void> _confirmQuit() async {
    if (_asked == 0 || _finished) return context.pop();
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this practice?'),
        content: const Text('Your progress in this session will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep going'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (quit == true && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final total = _queue.length;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TlSpace.maxContentWidth,
            ),
            child: _finished
                ? _Summary(
                    args: widget.args,
                    correct: _correct,
                    asked: _asked,
                  )
                : Column(
                    children: [
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
                              semanticLabel: 'Close practice',
                              onTap: _confirmQuit,
                              child: Icon(
                                AppIcons.x,
                                size: 24,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: TlSpace.md),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: TlRadius.pillRadius,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(end: _index / total),
                                  duration: TlMotion.medium,
                                  curve: TlMotion.standard,
                                  builder: (context, value, _) =>
                                      LinearProgressIndicator(
                                        value: value,
                                        minHeight: 12,
                                        backgroundColor: colors.surfaceSunken,
                                        valueColor: AlwaysStoppedAnimation(
                                          colors.success,
                                        ),
                                      ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: TlSpace.gutter,
                            vertical: TlSpace.md,
                          ),
                          child: AnimatedSwitcher(
                            duration: TlMotion.medium,
                            switchInCurve: TlMotion.standard,
                            child: KeyedSubtree(
                              key: ValueKey(_index),
                              child: exerciseView(
                                _current,
                                _binding,
                              ),
                            ),
                          ),
                        ),
                      ),
                      ListenableBuilder(
                        listenable: _binding,
                        builder: (context, _) => _CheckBar(
                          binding: _binding,
                          isIntro: _isIntro,
                          isLast: _index == _queue.length - 1,
                          onCheck: _check,
                          onContinue: _next,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class _CheckBar extends StatelessWidget {
  const _CheckBar({
    required this.binding,
    required this.isIntro,
    required this.isLast,
    required this.onCheck,
    required this.onContinue,
  });

  final ExerciseBinding binding;
  final bool isIntro;
  final bool isLast;
  final VoidCallback onCheck;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final result = binding.result;

    // New words are simply acknowledged.
    if (isIntro) {
      return Padding(
        padding: const EdgeInsets.all(TlSpace.gutter),
        child: TlButton(label: 'Got it', onPressed: onContinue),
      );
    }

    if (result == null) {
      return Padding(
        padding: const EdgeInsets.all(TlSpace.gutter),
        child: TlButton(
          label: 'Check',
          onPressed: binding.canCheck ? onCheck : null,
        ),
      );
    }

    final ok = result.correct;
    return TlArrival(
      key: ValueKey(binding),
      child: AnimatedContainer(
        duration: TlMotion.fast,
        width: double.infinity,
        padding: const EdgeInsets.all(TlSpace.gutter),
        color: ok ? colors.successSoft : colors.dangerSoft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (ok)
                  const TlSticker(kind: TlStickerKind.celebrate, size: 38)
                else
                  Icon(AppIcons.circleX, color: colors.dangerText),
                const SizedBox(width: TlSpace.xs),
                Expanded(
                  child: Text(
                    ok ? 'Nice!' : 'Not quite',
                    style: context.type.title.copyWith(
                      color: ok ? colors.successText : colors.dangerText,
                    ),
                  ),
                ),
              ],
            ),
            if (!ok && result.correction != null) ...[
              const SizedBox(height: 4),
              Text(
                'Answer: ${result.correction}',
                style: context.type.body.copyWith(color: colors.dangerText),
              ),
            ],
            const SizedBox(height: TlSpace.sm),
            TlButton(
              label: 'Continue',
              tone: ok ? TlButtonTone.success : TlButtonTone.primary,
              onPressed: onContinue,
            ),
          ],
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.args,
    required this.correct,
    required this.asked,
  });

  final PracticeSessionArgs args;
  final int correct;
  final int asked;

  /// Shares a short text summary of this session via the OS share sheet.
  Future<void> _share(BuildContext context) async {
    final pct = asked == 0 ? 0 : (correct * 100 / asked).round();
    final words = [
      for (final VocabularyItem w in args.set.words) w.display,
    ].take(12).join(', ');
    final text = StringBuffer()
      ..writeln('Meine Talkloom-Übung: ${args.title}')
      ..writeln('Genauigkeit: $pct% ($correct/$asked richtig)')
      ..write(words.isEmpty ? 'Weiter geht’s!' : 'Wörter: $words');
    await SharePlus.instance.share(ShareParams(text: text.toString()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final pct = asked == 0 ? 0 : (correct * 100 / asked).round();
    return ListView(
      padding: const EdgeInsets.all(TlSpace.gutter),
      children: [
        const SizedBox(height: TlSpace.xl),
        Center(
          child: Animate(
            effects: [
              ScaleEffect(
                duration: Duration(milliseconds: 600),
                curve: Curves.elasticOut,
                begin: Offset(0.4, 0.4),
                end: Offset(1, 1),
              ),
              FadeEffect(duration: Duration(milliseconds: 250)),
            ],
            child: const TlSticker(kind: TlStickerKind.celebrate, size: 144),
          ),
        ),
        const SizedBox(height: TlSpace.md),
        Text(
          'Practice complete',
          textAlign: TextAlign.center,
          style: context.type.headline,
        ),
        const SizedBox(height: 4),
        Text(
          args.title,
          textAlign: TextAlign.center,
          style: context.type.caption,
        ),
        const SizedBox(height: TlSpace.xl),
        Row(
          children: [
            Expanded(
              child: _Stat(
                label: 'Accuracy',
                value: '$pct%',
                tone: colors.success,
              ),
            ),
            const SizedBox(width: TlSpace.sm),
            Expanded(
              child: _Stat(
                label: 'Correct',
                value: '$correct/$asked',
                tone: colors.info,
              ),
            ),
          ],
        ),
        if (args.set.words.isNotEmpty) ...[
          const SizedBox(height: TlSpace.xl),
          Text('Words you practised', style: context.type.title),
          const SizedBox(height: TlSpace.xs),
          Wrap(
            spacing: TlSpace.xs,
            runSpacing: TlSpace.xs,
            children: [
              for (final VocabularyItem w in args.set.words)
                TlPill(
                  label: w.display,
                  background: colors.surfaceSunken,
                  foreground: colors.textPrimary,
                ),
            ],
          ),
        ],
        const SizedBox(height: TlSpace.xxl),
        TlButton(
          label: 'Teilen',
          icon: Icons.share,
          tone: TlButtonTone.neutral,
          onPressed: () => _share(context),
        ),
        const SizedBox(height: TlSpace.sm),
        if (args.finishLabel != null && args.finishRoute != null) ...[
          TlButton(
            label: args.finishLabel!,
            icon: AppIcons.mic,
            tone: TlButtonTone.success,
            onPressed: () => context.pushReplacement(args.finishRoute!),
          ),
          const SizedBox(height: TlSpace.sm),
        ],
        TlButton(
          label: 'Done',
          tone: args.finishLabel == null
              ? TlButtonTone.primary
              : TlButtonTone.neutral,
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(TlRoutes.home),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.tone});
  final String label;
  final String value;
  final Color tone;

  @override
  Widget build(BuildContext context) => TlCard(
    padding: const EdgeInsets.all(TlSpace.md),
    child: Column(
      children: [
        Text(value, style: context.type.display.copyWith(color: tone)),
        Text(label, style: context.type.caption),
      ],
    ),
  );
}
