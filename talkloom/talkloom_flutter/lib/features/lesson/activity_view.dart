import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../core/platform/web_voice_service.dart';
import '../../domain/lesson_content.dart';

/// Renders one activity. Adding a new activity type means adding a case here
/// and a branch in [LessonActivity.fromJson] — nothing else changes.
class ActivityView extends StatelessWidget {
  const ActivityView({
    super.key,
    required this.activity,
    required this.onCompleted,
  });

  final LessonActivity activity;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return switch (activity) {
      SentenceBuilderActivity(:final target, :final scrambledTokens) =>
        _SentenceBuilder(
          target: target,
          tokens: scrambledTokens,
          onCompleted: onCompleted,
        ),
      ContextChoiceActivity(
        :final question,
        :final options,
        :final correctIndex,
      ) =>
        _ContextChoice(
          question: question,
          options: options,
          correctIndex: correctIndex,
          onCompleted: onCompleted,
        ),
      SpeakResponseActivity(:final objective) => _SpeakPrompt(
        objective: objective,
        onCompleted: onCompleted,
      ),
    };
  }
}

/// Shared header so every activity type reads the same way.
class _ActivityFrame extends StatelessWidget {
  const _ActivityFrame({
    required this.icon,
    required this.kicker,
    required this.prompt,
    required this.child,
    this.targetAudioText,
  });

  final IconData icon;
  final String kicker;
  final String prompt;
  final Widget child;
  final String? targetAudioText;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: TlSpace.sm),
        Row(
          children: [
            Icon(icon, size: 17, color: colors.info),
            const SizedBox(width: 6),
            Text(
              kicker,
              style: context.type.caption.copyWith(
                color: colors.info,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(),
            if (targetAudioText != null)
              _AudioPronunciationButton(text: targetAudioText!),
          ],
        ),
        const SizedBox(height: TlSpace.xs),
        Text(prompt, style: context.type.headline),
        const SizedBox(height: TlSpace.lg),
        child,
        const SizedBox(height: TlSpace.xxl),
      ],
    );
  }
}

/// Audio / Pronunciation Prompt Widget with animated sound waves & haptics
class _AudioPronunciationButton extends StatefulWidget {
  const _AudioPronunciationButton({required this.text});

  final String text;

  @override
  State<_AudioPronunciationButton> createState() =>
      _AudioPronunciationButtonState();
}

class _AudioPronunciationButtonState extends State<_AudioPronunciationButton>
    with SingleTickerProviderStateMixin {
  bool _isPlaying = false;
  late AnimationController _anim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _playAudio() async {
    if (_isPlaying || !WebVoiceService.instance.canSpeak) return;
    setState(() => _isPlaying = true);
    final started = await WebVoiceService.instance.speak(
      widget.text,
      langCode: 'de-DE',
    );
    if (!mounted) return;
    if (!started) { setState(() => _isPlaying = false); return; }
    HapticFeedback.lightImpact();
    setState(() => _isPlaying = true);
    _anim.repeat(reverse: true);

    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        _anim.stop();
        _anim.reset();
        setState(() => _isPlaying = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return TlPressable(
      onTap: _playAudio,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _isPlaying ? colors.primarySoft : colors.surfaceRaised,
          borderRadius: TlRadius.pillRadius,
          border: Border.all(
            color: _isPlaying ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _isPlaying ? LucideIcons.volume2 : LucideIcons.volume1,
              size: 15,
              color: _isPlaying ? colors.primary : colors.textSecondary,
            ),
            const SizedBox(width: 4),
            Text(
              _isPlaying ? 'Playing…' : 'Listen',
              style: context.type.caption.copyWith(
                color: _isPlaying ? colors.primary : colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive Drag-and-Drop / Tap-to-Order Sentence Builder Mini-Game
class _SentenceBuilder extends StatefulWidget {
  const _SentenceBuilder({
    required this.target,
    required this.tokens,
    required this.onCompleted,
  });

  final String target;
  final List<String> tokens;
  final VoidCallback onCompleted;

  @override
  State<_SentenceBuilder> createState() => _SentenceBuilderState();
}

class _SentenceBuilderState extends State<_SentenceBuilder> {
  late List<String> _available = List.of(widget.tokens);
  final List<String> _selected = [];
  bool? _isCorrect;
  bool _isDraggingOverWell = false;

  void _place(String token) {
    setState(() {
      _available.remove(token);
      _selected.add(token);
      _isCorrect = null;
    });
    HapticFeedback.selectionClick();
  }

  void _remove(int index) {
    if (_isCorrect == true) return;
    setState(() {
      _available.add(_selected.removeAt(index));
      _isCorrect = null;
    });
  }

  void _check() {
    List<String> normalise(String value) => value
        .toLowerCase()
        .replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), '')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    final isCorrect =
        normalise(_selected.join(' ')).join(' ') ==
        normalise(widget.target).join(' ');

    setState(() => _isCorrect = isCorrect);

    if (isCorrect) {
      HapticFeedback.mediumImpact();
      Future.delayed(TlMotion.slow, () {
        if (mounted) widget.onCompleted();
      });
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  void _reset() {
    setState(() {
      _available = List.of(widget.tokens);
      _selected.clear();
      _isCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDone = _isCorrect == true;
    final isWrong = _isCorrect == false;

    final wellBorder = isDone
        ? colors.success
        : isWrong
        ? colors.danger
        : _isDraggingOverWell
        ? colors.primary
        : colors.border;
    final wellBackground = isDone
        ? colors.successSoft
        : isWrong
        ? colors.dangerSoft
        : _isDraggingOverWell
        ? colors.primarySoft
        : colors.surfaceSunken;

    return _ActivityFrame(
      icon: LucideIcons.puzzle,
      kicker: 'SYNTAX MINI-GAME',
      prompt: 'Drag or tap words into correct word order',
      targetAudioText: widget.target,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag-and-Drop Drop Zone Well
          DragTarget<String>(
            onWillAcceptWithDetails: (details) => !isDone,
            onAcceptWithDetails: (details) {
              setState(() => _isDraggingOverWell = false);
              _place(details.data);
            },
            onMove: (_) {
              if (!_isDraggingOverWell) {
                setState(() => _isDraggingOverWell = true);
              }
            },
            onLeave: (_) {
              setState(() => _isDraggingOverWell = false);
            },
            builder: (context, candidateData, rejectedData) {
              return TlSunken(
                padding: const EdgeInsets.all(TlSpace.md),
                borderColor: wellBorder,
                backgroundColor: wellBackground,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 80),
                  child: _selected.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                LucideIcons.mousePointerClick,
                                size: 20,
                                color: colors.textMuted,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Drag words here or tap to order',
                                style: context.type.bodySmall.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        )
                      : Wrap(
                          spacing: TlSpace.xs,
                          runSpacing: TlSpace.xs,
                          children: [
                            for (var i = 0; i < _selected.length; i++)
                              _DraggableToken(
                                label: _selected[i],
                                isPlaced: true,
                                onTap: () => _remove(i),
                              ),
                          ],
                        ),
                ),
              );
            },
          ),
          if (isWrong) ...[
            const SizedBox(height: TlSpace.sm),
            Text(
              'Not quite right — tap a word to return it or hit start over.',
              style: context.type.bodySmall.copyWith(color: colors.dangerText),
            ),
          ],
          if (isDone) ...[
            const SizedBox(height: TlSpace.sm),
            Row(
              children: [
                Icon(LucideIcons.checkCheck, size: 18, color: colors.success),
                const SizedBox(width: 6),
                Text(
                  'Perfect Syntax!',
                  style: context.type.bodyStrong.copyWith(
                    color: colors.successText,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: TlSpace.lg),
          Text(
            'Available Bank:',
            style: context.type.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: TlSpace.xs),
          Wrap(
            spacing: TlSpace.xs,
            runSpacing: TlSpace.xs,
            children: [
              for (final token in _available)
                _DraggableToken(
                  label: token,
                  onTap: () => _place(token),
                ),
            ],
          ),
          const SizedBox(height: TlSpace.xl),
          if (isDone)
            TlButton(
              label: 'Continue',
              tone: TlButtonTone.success,
              onPressed: widget.onCompleted,
            )
          else if (isWrong)
            TlButton(
              label: 'Start over',
              tone: TlButtonTone.neutral,
              onPressed: _reset,
            )
          else
            TlButton(
              label: 'Check Order',
              onPressed: _available.isEmpty ? _check : null,
            ),
        ],
      ),
    );
  }
}

class _DraggableToken extends StatelessWidget {
  const _DraggableToken({
    required this.label,
    required this.onTap,
    this.isPlaced = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPlaced;

  @override
  Widget build(BuildContext context) {
    final tokenWidget = _Token(label: label, onTap: onTap, isPlaced: isPlaced);

    return Draggable<String>(
      data: label,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(
          opacity: 0.9,
          child: _Token(label: label, onTap: () {}, isPlaced: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: tokenWidget,
      ),
      child: tokenWidget,
    );
  }
}

class _Token extends StatelessWidget {
  const _Token({
    required this.label,
    required this.onTap,
    this.isPlaced = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPlaced;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TlPressable(
      onTap: onTap,
      scale: 0.93,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TlSpace.md,
          vertical: TlSpace.sm,
        ),
        decoration: BoxDecoration(
          color: isPlaced ? colors.surfaceSunken : colors.surfaceRaised,
          borderRadius: TlRadius.controlRadius,
          border: Border.all(
            color: isPlaced ? colors.info : colors.borderStrong,
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isPlaced ? colors.infoPressed : colors.borderStrong,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaced ? LucideIcons.check : LucideIcons.gripVertical,
              size: 12,
              color: isPlaced ? colors.info : colors.textMuted,
            ),
            const SizedBox(width: 4),
            Text(label, style: context.type.bodyStrong),
          ],
        ),
      ),
    );
  }
}

class _ContextChoice extends StatefulWidget {
  const _ContextChoice({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.onCompleted,
  });

  final String question;
  final List<String> options;
  final int correctIndex;
  final VoidCallback onCompleted;

  @override
  State<_ContextChoice> createState() => _ContextChoiceState();
}

class _ContextChoiceState extends State<_ContextChoice> {
  int? _picked;

  bool get _isCorrect => _picked == widget.correctIndex;

  void _pick(int index) {
    if (_picked != null) return;
    setState(() => _picked = index);
    if (index == widget.correctIndex) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return _ActivityFrame(
      icon: LucideIcons.listChecks,
      kicker: 'CHOOSE THE MEANING',
      prompt: widget.question,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < widget.options.length; i++) ...[
            _Option(
              label: widget.options[i],
              state: _picked == null
                  ? _OptionState.idle
                  : i == widget.correctIndex
                  ? _OptionState.correct
                  : i == _picked
                  ? _OptionState.wrong
                  : _OptionState.dimmed,
              onTap: () => _pick(i),
            ),
            const SizedBox(height: TlSpace.xs),
          ],
          const SizedBox(height: TlSpace.md),
          if (_picked != null)
            TlButton(
              label: _isCorrect ? 'Continue' : 'Got it, continue',
              tone: _isCorrect ? TlButtonTone.success : TlButtonTone.neutral,
              onPressed: widget.onCompleted,
            )
          else
            Text(
              'Pick one to continue.',
              style: context.type.caption.copyWith(color: colors.textMuted),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }
}

enum _OptionState { idle, correct, wrong, dimmed }

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.state,
    required this.onTap,
  });

  final String label;
  final _OptionState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final (background, border, icon) = switch (state) {
      _OptionState.idle => (colors.surface, colors.border, null),
      _OptionState.correct => (
        colors.successSoft,
        colors.success,
        LucideIcons.check,
      ),
      _OptionState.wrong => (colors.dangerSoft, colors.danger, LucideIcons.x),
      _OptionState.dimmed => (colors.surface, colors.border, null),
    };

    return Opacity(
      opacity: state == _OptionState.dimmed ? 0.45 : 1,
      child: TlPressable(
        onTap: onTap,
        child: AnimatedContainer(
          duration: TlMotion.fast,
          curve: TlMotion.standard,
          padding: const EdgeInsets.all(TlSpace.md),
          decoration: BoxDecoration(
            color: background,
            borderRadius: TlRadius.controlRadius,
            border: Border.all(
              color: border,
              width: state == _OptionState.idle ? 1 : 2,
            ),
          ),
          child: Row(
            children: [
              Expanded(child: Text(label, style: context.type.body)),
              if (icon != null)
                Icon(
                  icon,
                  size: 19,
                  color: state == _OptionState.correct
                      ? colors.success
                      : colors.danger,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpeakPrompt extends StatelessWidget {
  const _SpeakPrompt({required this.objective, required this.onCompleted});

  final String objective;
  final VoidCallback onCompleted;

  @override
  Widget build(BuildContext context) {
    return _ActivityFrame(
      icon: LucideIcons.mic,
      kicker: 'YOUR MISSION',
      prompt: objective,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'You will do this in a real conversation next. Say it your own '
            'way — being understood matters more than being perfect.',
            style: context.type.body,
          ),
          const SizedBox(height: TlSpace.xl),
          TlButton(
            label: 'I am ready',
            icon: LucideIcons.arrowRight,
            tone: TlButtonTone.success,
            onPressed: onCompleted,
          ),
        ],
      ),
    );
  }
}
