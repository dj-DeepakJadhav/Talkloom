import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import 'fluid_voice_orb.dart';
import 'mission_tracker.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(this.speaker, this.text);

  final _Speaker speaker;
  final String text;
}

/// The speaking mission that closes every lesson.
///
/// Features real Web Speech recognition (STT) for hands-free or push-to-talk
/// conversation practice, Web SpeechSynthesis (TTS) so the learner hears
/// the native German pronunciation, and in-line highlights for unlearned vocabulary.
class SpeakScreen extends ConsumerStatefulWidget {
  const SpeakScreen({super.key});

  @override
  ConsumerState<SpeakScreen> createState() => _SpeakScreenState();
}

class _SpeakScreenState extends ConsumerState<SpeakScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();

  final List<_Message> _messages = [];
  final List<String> _tutorTurns = [];
  final List<String> _captured = [];

  bool _isSending = false;
  bool _isSpeaking = false;
  bool _isRecording = false;
  String? _error;
  DateTime _turnStart = DateTime.now();
  String? _celebrating;

  late final AnimationController _micPulseController;

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initialize Web Speech API bridge
    WebVoiceService.instance.init();
    WebVoiceService.instance.onTranscriptReceived = (transcript) {
      if (mounted && _isRecording) {
        setState(() {
          _input.text = transcript;
          _input.selection = TextSelection.fromPosition(
            TextPosition(offset: _input.text.length),
          );
        });
      }
    };
  }

  @override
  void dispose() {
    WebVoiceService.instance.stopListening();
    _micPulseController.dispose();
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: TlMotion.medium,
        curve: TlMotion.standard,
      );
    });
  }

  Future<void> _send(ConversationPlan plan) async {
    final text = _input.text.trim();
    if (text.isEmpty || _isSending) return;

    // Stop recording if currently active
    if (_isRecording) {
      WebVoiceService.instance.stopListening();
      _micPulseController.stop();
      _micPulseController.reset();
      setState(() => _isRecording = false);
    }

    final session = ref.read(learningSessionProvider);

    final latency =
        (DateTime.now().difference(_turnStart).inMilliseconds / 1000.0).clamp(
          0.5,
          20.0,
        );

    setState(() {
      _messages.add(_Message(_Speaker.learner, text));
      _input.clear();
      _isSending = true;
      _error = null;
    });
    _scrollToEnd();

    try {
      final turn = await ref
          .read(lessonRepositoryProvider)
          .speak(
            session: session,
            role: plan.role,
            situation: plan.situation,
            hiddenTargets: plan.hiddenTargets,
            previousTurns: _tutorTurns,
            utterance: text,
            latencySec: latency,
          );

      if (!mounted) return;

      setState(() {
        _messages.add(_Message(_Speaker.tutor, turn.reply));
        _tutorTurns.add(turn.reply);
        _turnStart = DateTime.now();
        _isSpeaking = true;

        final target = turn.detectedTarget;
        if (turn.producedSpontaneously &&
            target != null &&
            !_captured.contains(target)) {
          _captured.add(target);
          _celebrating = target;
        }
      });

      // Speak tutor reply out loud via browser Web Speech Synthesis
      final langTag = session.target.code.toLowerCase().startsWith('de')
          ? 'de-DE'
          : session.target.code;
      WebVoiceService.instance.speak(turn.reply, langCode: langTag);

      // Viseme speaking duration proportional to utterance length (capped 1.5 - 4.5s)
      final speechMs = (turn.reply.length * 55).clamp(1800, 4500);
      Future.delayed(Duration(milliseconds: speechMs), () {
        if (mounted) setState(() => _isSpeaking = false);
      });

      if (_celebrating != null) {
        HapticFeedback.mediumImpact();
        ref.invalidate(learnerStateProvider);
        Future.delayed(const Duration(milliseconds: 1800), () {
          if (mounted) setState(() => _celebrating = null);
        });
      }
      _scrollToEnd();
    } catch (error) {
      if (mounted) setState(() => _error = Failure.from(error).message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _toggleRecording(ConversationPlan plan) async {
    if (_isSending) return;

    if (_isRecording) {
      // Stop recording
      WebVoiceService.instance.stopListening();
      _micPulseController.stop();
      _micPulseController.reset();
      setState(() => _isRecording = false);
      HapticFeedback.lightImpact();

      // If user has entered text via voice/dictation or had input, send it
      if (_input.text.trim().isNotEmpty) {
        await _send(plan);
      }
    } else {
      // Start recording
      HapticFeedback.mediumImpact();
      _turnStart = DateTime.now();
      setState(() {
        _isRecording = true;
        _error = null;
      });
      _micPulseController.repeat(reverse: true);

      final session = ref.read(learningSessionProvider);
      final langTag = session.target.code.toLowerCase().startsWith('de')
          ? 'de-DE'
          : session.target.code;

      // Start actual browser microphone recognition
      final started = WebVoiceService.instance.startListening(langCode: langTag);
      if (!started) {
        // Fallback for browsers blocking or not supporting Web Speech API
        debugPrint('[SpeakScreen] Speech recognition not available or permission denied.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = ref.watch(activeLessonProvider);
    final plan = lesson?.conversation ?? ConversationPlan.empty;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TlSpace.maxContentWidth,
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildHeader(plan),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: FluidVoiceOrb(
                        size: 92,
                        state: _isSending
                            ? VoiceOrbState.thinking
                            : (_isSpeaking
                                ? VoiceOrbState.speaking
                                : (_isRecording
                                    ? VoiceOrbState.listening
                                    : VoiceOrbState.idle)),
                      ),
                    ),
                    MissionTracker(
                      totalTargets: plan.hiddenTargets.length,
                      captured: _captured,
                    ),
                    const SizedBox(height: TlSpace.sm),
                    Expanded(child: _buildTranscript(plan)),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: TlSpace.gutter,
                          vertical: TlSpace.xs,
                        ),
                        child: TlErrorState(
                          message: _error!,
                          onRetry: () => setState(() => _error = null),
                        ),
                      ),
                    _buildComposer(plan, colors),
                  ],
                ),
                if (_celebrating != null)
                  Positioned(
                    left: TlSpace.gutter,
                    right: TlSpace.gutter,
                    top: 90,
                    child: _CaptureBanner(target: _celebrating!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ConversationPlan plan) {
    final colors = context.colors;
    return Padding(
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
              LucideIcons.chevronLeft,
              size: 24,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: TlSpace.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plan.situation,
                  style: context.type.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Speaking with a ${plan.role}',
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscript(ConversationPlan plan) {
    final colors = context.colors;

    if (_messages.isEmpty) {
      return TlEmptyState(
        icon: LucideIcons.messagesSquare,
        title: 'Say the first thing',
        message:
            'You are talking to a ${plan.role}. Start however feels natural — '
            'mistakes are fine.',
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _messages.length) {
          return Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: TlSpace.xs),
              child: TlSkeleton(height: 42, width: 120, radius: TlRadius.md),
            ),
          );
        }

        final message = _messages[index];
        final isLearner = message.speaker == _Speaker.learner;

        return TlEntrance(
          child: Align(
            alignment: isLearner ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width * 0.78,
              ),
              margin: const EdgeInsets.symmetric(vertical: TlSpace.xxs),
              padding: const EdgeInsets.symmetric(
                horizontal: TlSpace.md,
                vertical: TlSpace.sm,
              ),
              decoration: BoxDecoration(
                color: isLearner ? colors.primary : colors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(TlRadius.md),
                  topRight: const Radius.circular(TlRadius.md),
                  bottomLeft: Radius.circular(
                    isLearner ? TlRadius.md : TlRadius.sm,
                  ),
                  bottomRight: Radius.circular(
                    isLearner ? TlRadius.sm : TlRadius.md,
                  ),
                ),
                border: isLearner ? null : Border.all(color: colors.border),
              ),
              child: _buildMessageContent(message, isLearner, colors),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageContent(_Message message, bool isLearner, TlColors colors) {
    if (isLearner) {
      return Text(
        message.text,
        style: context.type.body.copyWith(color: colors.onAccent),
      );
    }

    // Tutor messages: Parse [[new:word:meaning]] or standard text
    final rawText = message.text;
    final regex = RegExp(r'\[\[new:([^:|\]]+)(?::([^\]]+))?\]\]');
    final matches = regex.allMatches(rawText).toList();

    if (matches.isEmpty) {
      return Text(
        rawText,
        style: context.type.body.copyWith(color: colors.textPrimary),
      );
    }

    final spans = <InlineSpan>[];
    int lastEnd = 0;

    for (final match in matches) {
      if (match.start > lastEnd) {
        spans.add(
          TextSpan(
            text: rawText.substring(lastEnd, match.start),
            style: context.type.body.copyWith(color: colors.textPrimary),
          ),
        );
      }

      final word = match.group(1)?.trim() ?? '';
      final meaning = match.group(2)?.trim() ?? '';

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Tooltip(
            message: meaning.isNotEmpty ? 'New word: $meaning' : 'New word introduced',
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: TlRadius.controlRadius,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    style: context.type.bodyStrong.copyWith(
                      color: colors.primary,
                      fontSize: 13.5,
                    ),
                  ),
                  if (meaning.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Text(
                      '($meaning)',
                      style: context.type.caption.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );

      lastEnd = match.end;
    }

    if (lastEnd < rawText.length) {
      spans.add(
        TextSpan(
          text: rawText.substring(lastEnd),
          style: context.type.body.copyWith(color: colors.textPrimary),
        ),
      );
    }

    return Text.rich(
      TextSpan(children: spans),
    );
  }

  Widget _buildComposer(ConversationPlan plan, TlColors colors) {
    final session = ref.watch(learningSessionProvider);
    final languageName = session.target.englishName;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        TlSpace.gutter,
        TlSpace.sm,
        TlSpace.gutter,
        TlSpace.sm,
      ),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isRecording)
              Padding(
                padding: const EdgeInsets.only(bottom: TlSpace.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: TlSpace.xs),
                    Text(
                      'Listening to your $languageName speech… (tap mic or send to finish)',
                      style: context.type.caption.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _input,
                    enabled: !_isSending,
                    minLines: 1,
                    maxLines: 4,
                    textInputAction: TextInputAction.send,
                    style: context.type.body.copyWith(color: colors.textPrimary),
                    onSubmitted: (_) => _send(plan),
                    decoration: InputDecoration(
                      hintText: _isRecording
                          ? 'Speak now in $languageName…'
                          : 'Reply in $languageName…',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: TlSpace.md,
                        vertical: TlSpace.sm,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: TlRadius.pillRadius,
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: TlRadius.pillRadius,
                        borderSide: BorderSide(
                          color: _isRecording ? colors.primary : colors.border,
                          width: _isRecording ? 1.5 : 1.0,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: TlRadius.pillRadius,
                        borderSide: BorderSide(color: colors.primary, width: 1.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: TlSpace.xs),
                // Dedicated Microphone / Voice Input Button
                AnimatedBuilder(
                  animation: _micPulseController,
                  builder: (context, child) {
                    final scale = _isRecording
                        ? 1.0 + (_micPulseController.value * 0.12)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: TlPressable(
                        onTap: () => _toggleRecording(plan),
                        child: Container(
                          height: 48,
                          width: 48,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? colors.primary
                                : colors.surfaceRaised,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isRecording
                                  ? colors.primary
                                  : colors.border,
                              width: 1.5,
                            ),
                            boxShadow: _isRecording
                                ? [
                                    BoxShadow(
                                      color: colors.primary.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: Icon(
                            _isRecording ? LucideIcons.mic : LucideIcons.mic,
                            color: _isRecording
                                ? colors.onAccent
                                : colors.primary,
                            size: 21,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: TlSpace.xs),
                // Send Button
                TlPressable(
                  onTap: () => _send(plan),
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      color: _isSending ? colors.borderStrong : colors.success,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.arrowUp,
                      color: colors.onAccent,
                      size: 21,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Fires when the learner produces a target without being prompted — the one
/// moment in the product that no flashcard app can manufacture.
class _CaptureBanner extends StatelessWidget {
  const _CaptureBanner({required this.target});

  final String target;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final label = target.contains(':') ? target.split(':').last : target;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: TlMotion.slow,
      curve: TlMotion.emphasized,
      builder: (context, value, child) => Opacity(
        opacity: value.clamp(0, 1),
        child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: TlSpace.md,
          vertical: TlSpace.sm,
        ),
        decoration: BoxDecoration(
          color: colors.success,
          borderRadius: TlRadius.controlRadius,
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(LucideIcons.sparkles, size: 19, color: colors.onAccent),
            const SizedBox(width: TlSpace.xs),
            Expanded(
              child: Text(
                'You said "$label" on your own',
                style: context.type.bodyStrong.copyWith(color: colors.onAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
