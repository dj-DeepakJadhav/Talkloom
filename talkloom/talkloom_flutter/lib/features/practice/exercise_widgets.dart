import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/app_icons.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../app/providers.dart';
import '../../domain/practice_engine.dart';

/// The verdict on one exercise.
class ExerciseResult {
  const ExerciseResult({required this.correct, this.correction});
  final bool correct;

  /// What the right answer was, shown when [correct] is false.
  final String? correction;
}

/// Connects an exercise to the session's Check / Continue bar.
///
/// The exercise says when it can be checked and how to judge itself; the
/// session asks it for the verdict, then [reveal]s that verdict back so the
/// exercise can colour its answer.
class ExerciseBinding extends ChangeNotifier {
  bool _canCheck = false;
  ExerciseResult Function()? _evaluate;
  ExerciseResult? _result;

  bool get canCheck => _canCheck;
  ExerciseResult? get result => _result;
  bool get isChecked => _result != null;

  bool _disposed = false;

  void ready({required bool canCheck, ExerciseResult Function()? evaluate}) {
    _canCheck = canCheck;
    if (evaluate != null) _evaluate = evaluate;
    _notify();
  }

  ExerciseResult check() {
    final result = _evaluate!();
    _result = result;
    _notify();
    return result;
  }

  /// Exercises declare themselves in initState, which runs mid-build; telling
  /// the session then would rebuild it during its own build.
  void _notify() {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    } else {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

/// Builds the widget for [exercise].
Widget exerciseView(PracticeExercise exercise, ExerciseBinding binding) =>
    switch (exercise) {
      WordIntroExercise() => IntroCard(exercise: exercise, binding: binding),
      ChoiceExercise() => ChoiceView(exercise: exercise, binding: binding),
      MatchExercise() => MatchView(exercise: exercise, binding: binding),
      SentenceExercise() => SentenceView(exercise: exercise, binding: binding),
    };

/// A speaker button that reads the selected learning language aloud.
class SpeakerButton extends ConsumerStatefulWidget {
  const SpeakerButton({
    super.key,
    required this.text,
    this.large = false,
    this.autoPlay = false,
  });

  final String text;
  final bool large;
  final bool autoPlay;

  @override
  ConsumerState<SpeakerButton> createState() => _SpeakerButtonState();
}

class _SpeakerButtonState extends ConsumerState<SpeakerButton> {
  bool _playing = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  Future<void> _play() async {
    if (_playing || !WebVoiceService.instance.canSpeak) return;
    setState(() => _playing = true);
    try {
      await WebVoiceService.instance.speak(
        widget.text,
        langCode: ref.read(learningSessionProvider).target.voiceLocale,
      );
      // Follow real playback instead of a fixed timer; the timeout only
      // guards a wedged player so the button always settles back to idle.
      await WebVoiceService.instance.speechDone.timeout(
        const Duration(seconds: 30),
      );
    } catch (_) {
      // Playback failed or timed out: settle back to idle through the
      // same path instead of sticking on the playing state.
    }
    if (!mounted) return;
    setState(() => _playing = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final canSpeak = WebVoiceService.instance.canSpeak;
    final size = widget.large ? 84.0 : 44.0;
    return Tooltip(
      message: canSpeak
          ? 'Listen'
          : WebVoiceService.instance.speechUnavailableReason,
      child: TlPressable(
        semanticLabel: 'Listen to ${widget.text}',
        onTap: canSpeak ? _play : () {},
        child: AnimatedContainer(
          duration: TlMotion.fast,
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: _playing ? colors.info : colors.infoSoft,
            borderRadius: BorderRadius.circular(size / 2.6),
            border: Border.all(color: colors.info.withValues(alpha: 0.5)),
          ),
          child: Icon(
            _playing ? AppIcons.volume2 : AppIcons.volume1,
            size: widget.large ? 38 : 22,
            color: _playing ? colors.onAccent : colors.info,
          ),
        ),
      ),
    );
  }
}

class _Prompt extends StatelessWidget {
  const _Prompt(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: TlSpace.lg),
    child: Text(text, style: context.type.headline),
  );
}

/// A new word, shown once before it is asked about.
class IntroCard extends StatefulWidget {
  const IntroCard({super.key, required this.exercise, required this.binding});
  final WordIntroExercise exercise;
  final ExerciseBinding binding;

  @override
  State<IntroCard> createState() => _IntroCardState();
}

class _IntroCardState extends State<IntroCard> {
  @override
  void initState() {
    super.initState();
    widget.binding.ready(
      canCheck: true,
      evaluate: () => const ExerciseResult(correct: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final word = widget.exercise.word;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Prompt('New word'),
        TlCard(
          padding: const EdgeInsets.all(TlSpace.xl),
          child: Column(
            children: [
              SpeakerButton(text: word.display, large: true),
              const SizedBox(height: TlSpace.lg),
              Text(
                word.display,
                textAlign: TextAlign.center,
                style: context.type.display,
              ),
              const SizedBox(height: TlSpace.xs),
              Text(
                word.meaning,
                textAlign: TextAlign.center,
                style: context.type.titleLarge.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              if (word.sourceContext.isNotEmpty) ...[
                const SizedBox(height: TlSpace.lg),
                TlSunken(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('From your link', style: context.type.caption),
                      const SizedBox(height: 4),
                      Text(
                        word.sourceContext,
                        style: context.type.body.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Pick the right answer: meaning, translation, listening, gap or context.
class ChoiceView extends StatefulWidget {
  const ChoiceView({super.key, required this.exercise, required this.binding});
  final ChoiceExercise exercise;
  final ExerciseBinding binding;

  @override
  State<ChoiceView> createState() => _ChoiceViewState();
}

class _ChoiceViewState extends State<ChoiceView> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    widget.binding.ready(canCheck: false, evaluate: _evaluate);
  }

  ExerciseResult _evaluate() {
    final correct = _selected == widget.exercise.correctIndex;
    return ExerciseResult(
      correct: correct,
      correction: correct ? null : widget.exercise.answer,
    );
  }

  void _select(int index) {
    if (widget.binding.isChecked) return;
    HapticFeedback.selectionClick();
    setState(() => _selected = index);
    widget.binding.ready(canCheck: true);
  }

  @override
  Widget build(BuildContext context) {
    final e = widget.exercise;
    final colors = context.colors;
    return ListenableBuilder(
      listenable: widget.binding,
      builder: (context, _) {
        final checked = widget.binding.isChecked;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Prompt(e.prompt),
            if (e.kind == ChoiceKind.listen)
              Padding(
                padding: const EdgeInsets.only(bottom: TlSpace.lg),
                child: Center(
                  child: SpeakerButton(
                    text: e.audioText!,
                    large: true,
                    autoPlay: true,
                  ),
                ),
              )
            else if (e.sentence != null)
              Padding(
                padding: const EdgeInsets.only(bottom: TlSpace.lg),
                child: Row(
                  children: [
                    if (e.audioText != null &&
                        e.kind == ChoiceKind.meaning) ...[
                      SpeakerButton(text: e.audioText!),
                      const SizedBox(width: TlSpace.sm),
                    ],
                    Expanded(
                      child: Text(
                        e.sentence!,
                        style: context.type.titleLarge,
                      ),
                    ),
                  ],
                ),
              ),
            if (e.hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: TlSpace.md),
                child: Text(e.hint!, style: context.type.caption),
              ),
            for (var i = 0; i < e.options.length; i++) ...[
              _OptionTile(
                label: e.options[i],
                state: _stateFor(i, checked),
                onTap: () => _select(i),
                colors: colors,
              ),
              const SizedBox(height: TlSpace.sm),
            ],
          ],
        );
      },
    );
  }

  _TileState _stateFor(int i, bool checked) {
    if (!checked) {
      return i == _selected ? _TileState.selected : _TileState.idle;
    }
    if (i == widget.exercise.correctIndex) return _TileState.correct;
    if (i == _selected) return _TileState.wrong;
    return _TileState.dimmed;
  }
}

enum _TileState { idle, selected, correct, wrong, dimmed, matched }

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.label,
    required this.state,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final _TileState state;
  final VoidCallback onTap;
  final TlColors colors;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (state) {
      _TileState.selected => (
        colors.infoSoft,
        colors.info,
        colors.infoText,
      ),
      _TileState.correct || _TileState.matched => (
        colors.successSoft,
        colors.success,
        colors.successText,
      ),
      _TileState.wrong => (colors.dangerSoft, colors.danger, colors.dangerText),
      _TileState.dimmed => (
        colors.surface,
        colors.border,
        colors.textMuted,
      ),
      _TileState.idle => (
        colors.surface,
        colors.borderStrong,
        colors.textPrimary,
      ),
    };
    final tile = TlPressable(
      semanticLabel: label,
      selected: state == _TileState.selected,
      onTap: onTap,
      child: AnimatedContainer(
        duration: TlMotion.fast,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: TlSpace.md,
          vertical: TlSpace.md,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: TlRadius.controlRadius,
          border: Border.all(color: border, width: 2),
        ),
        child: Text(
          label,
          style: context.type.bodyStrong.copyWith(color: fg),
        ),
      ),
    );
    // Opacity/scale/translation only: the "glow" is a solid tint, no blur.
    if (state == _TileState.wrong) {
      return tile
          .animate(key: ValueKey('shake-$label'))
          .shake(
            duration: const Duration(milliseconds: 350),
            offset: const Offset(8, 0),
          );
    }
    if (state == _TileState.correct || state == _TileState.matched) {
      return tile
          .animate(key: ValueKey('pop-$label'))
          .scale(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            begin: const Offset(0.96, 0.96),
            end: const Offset(1, 1),
          )
          .tint(color: colors.success.withValues(alpha: 0.18));
    }
    return tile;
  }
}

/// Tap a German word, then its meaning. Wrong pairs are counted, not blocked.
class MatchView extends StatefulWidget {
  const MatchView({super.key, required this.exercise, required this.binding});
  final MatchExercise exercise;
  final ExerciseBinding binding;

  @override
  State<MatchView> createState() => _MatchViewState();
}

class _MatchViewState extends State<MatchView> {
  late final List<String> _lefts = [
    for (final p in widget.exercise.pairs) p.left,
  ];
  late final List<String> _rights = [
    for (final p in widget.exercise.pairs) p.right,
  ]..shuffle();
  final _matched = <String>{};
  String? _leftPick;
  String? _rightPick;
  String? _flashWrong;
  int _mistakes = 0;

  @override
  void initState() {
    super.initState();
    widget.binding.ready(canCheck: false, evaluate: _evaluate);
  }

  ExerciseResult _evaluate() => ExerciseResult(
    correct: _mistakes <= 1,
    correction: _mistakes <= 1 ? null : 'Take another look at the pairs.',
  );

  bool _isPair(String left, String right) => widget.exercise.pairs.any(
    (p) => p.left == left && p.right == right,
  );

  void _tapLeft(String left) {
    if (_matched.contains(left)) return;
    HapticFeedback.selectionClick();
    setState(() => _leftPick = left);
    _resolve();
  }

  void _tapRight(String right) {
    if (_matched.contains(right)) return;
    HapticFeedback.selectionClick();
    setState(() => _rightPick = right);
    _resolve();
  }

  void _resolve() {
    final left = _leftPick;
    final right = _rightPick;
    if (left == null || right == null) return;
    if (_isPair(left, right)) {
      setState(() {
        _matched
          ..add(left)
          ..add(right);
        _leftPick = _rightPick = null;
      });
      if (_matched.length == _lefts.length * 2) {
        widget.binding.ready(canCheck: true);
      }
    } else {
      HapticFeedback.mediumImpact();
      setState(() {
        _mistakes++;
        _flashWrong = '$left|$right';
      });
      Future<void>.delayed(const Duration(milliseconds: 450), () {
        if (mounted) {
          setState(() {
            _flashWrong = null;
            _leftPick = _rightPick = null;
          });
        }
      });
    }
  }

  _TileState _state(String value, String? pick) {
    if (_matched.contains(value)) return _TileState.matched;
    final wrong = _flashWrong;
    if (wrong != null && value == pick) return _TileState.wrong;
    if (value == pick) return _TileState.selected;
    return _TileState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Prompt('Tap the matching pairs'),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (final left in _lefts) ...[
                    _OptionTile(
                      label: left,
                      state: _state(left, _leftPick),
                      onTap: () => _tapLeft(left),
                      colors: colors,
                    ),
                    const SizedBox(height: TlSpace.sm),
                  ],
                ],
              ),
            ),
            const SizedBox(width: TlSpace.sm),
            Expanded(
              child: Column(
                children: [
                  for (final right in _rights) ...[
                    _OptionTile(
                      label: right,
                      state: _state(right, _rightPick),
                      onTap: () => _tapRight(right),
                      colors: colors,
                    ),
                    const SizedBox(height: TlSpace.sm),
                  ],
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Tap the words of a real sentence from the link into order.
class SentenceView extends StatefulWidget {
  const SentenceView({
    super.key,
    required this.exercise,
    required this.binding,
  });
  final SentenceExercise exercise;
  final ExerciseBinding binding;

  @override
  State<SentenceView> createState() => _SentenceViewState();
}

class _SentenceViewState extends State<SentenceView> {
  /// Indexes into the exercise's tokens, in the order the learner placed them.
  final _placed = <int>[];

  @override
  void initState() {
    super.initState();
    widget.binding.ready(canCheck: false, evaluate: _evaluate);
  }

  String get _built => _placed.map((i) => widget.exercise.tokens[i]).join(' ');

  ExerciseResult _evaluate() {
    final correct = _built == widget.exercise.target;
    return ExerciseResult(
      correct: correct,
      correction: correct ? null : widget.exercise.target,
    );
  }

  void _toggle(int index) {
    if (widget.binding.isChecked) return;
    HapticFeedback.selectionClick();
    setState(() {
      if (!_placed.remove(index)) _placed.add(index);
    });
    widget.binding.ready(
      canCheck: _placed.length == widget.exercise.tokens.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tokens = widget.exercise.tokens;
    return ListenableBuilder(
      listenable: widget.binding,
      builder: (context, _) {
        final result = widget.binding.result;
        final tint = result == null
            ? colors.borderStrong
            : (result.correct ? colors.success : colors.danger);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Prompt('Put the sentence in order'),
            if (widget.exercise.hint != null)
              Padding(
                padding: const EdgeInsets.only(bottom: TlSpace.md),
                child: Text(widget.exercise.hint!, style: context.type.caption),
              ),
            Container(
              constraints: const BoxConstraints(minHeight: 104),
              padding: const EdgeInsets.all(TlSpace.sm),
              decoration: BoxDecoration(
                color: colors.surfaceSunken,
                borderRadius: TlRadius.controlRadius,
                border: Border.all(color: tint, width: 2),
              ),
              child: Wrap(
                spacing: TlSpace.xs,
                runSpacing: TlSpace.xs,
                children: [
                  for (final i in _placed)
                    _TokenChip(label: tokens[i], onTap: () => _toggle(i)),
                ],
              ),
            ),
            const SizedBox(height: TlSpace.lg),
            Wrap(
              spacing: TlSpace.xs,
              runSpacing: TlSpace.xs,
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < tokens.length; i++)
                  _TokenChip(
                    label: tokens[i],
                    used: _placed.contains(i),
                    onTap: () => _toggle(i),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TokenChip extends StatelessWidget {
  const _TokenChip({
    required this.label,
    required this.onTap,
    this.used = false,
  });
  final String label;
  final VoidCallback onTap;
  final bool used;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TlPressable(
      semanticLabel: label,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TlSpace.md,
          vertical: TlSpace.sm,
        ),
        decoration: BoxDecoration(
          color: used ? colors.surfaceSunken : colors.surface,
          borderRadius: TlRadius.controlRadius,
          border: Border.all(color: colors.borderStrong, width: 2),
        ),
        child: Text(
          label,
          style: context.type.bodyStrong.copyWith(
            color: used ? Colors.transparent : colors.textPrimary,
          ),
        ),
      ),
    );
  }
}
