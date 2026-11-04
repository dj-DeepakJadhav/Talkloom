import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'typed_reply_bar.dart';
import '../../design/app_icons.dart';
import '../../widgets/chat_message_view.dart';
import '../../app/providers.dart';
import '../../core/platform/voice_feedback.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import 'fluid_voice_orb.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(this.speaker, this.text);

  final _Speaker speaker;
  final String text;
}

/// Full-Screen Immersive Voice Conversation View
///
/// Features:
/// - Conversation history occupies the main screen with clean chat bubbles
/// - Inline highlighting for new vocabulary
/// - Small pulsating Siri/Apple Intelligence fluid orb at the bottom center
/// - Tap to speak or hands-free conversational turns
class ImmersiveVoiceModal extends ConsumerStatefulWidget {
  const ImmersiveVoiceModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ImmersiveVoiceModal(),
    );
  }

  @override
  ConsumerState<ImmersiveVoiceModal> createState() =>
      _ImmersiveVoiceModalState();
}

class _ImmersiveVoiceModalState extends ConsumerState<ImmersiveVoiceModal> {
  final ScrollController _scroll = ScrollController();
  final List<_Message> _messages = [];
  final List<String> _tutorTurns = [];

  bool _isSending = false;
  bool _isSpeaking = false;
  bool _isRecording = false;
  String _liveTranscript = '';
  String? _voiceError;
  DateTime _turnStart = DateTime.now();

  @override
  void initState() {
    super.initState();
    WebVoiceService.instance.init();
    WebVoiceService.instance.onTranscriptReceived = (transcript) {
      if (mounted && _isRecording) {
        setState(() {
          _liveTranscript = transcript;
        });
      }
    };
    // Reflect the real recognizer state: it may stop on its own (pause,
    // timeout) or fail (permission, unsupported, no speech).
    WebVoiceService.instance.onListeningChanged = (listening) {
      if (!mounted || listening || !_isRecording) return;
      setState(() => _isRecording = false);
    };
    WebVoiceService.instance.onError = (failure, message) {
      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _voiceError = message;
      });
      showVoiceFailure(context);
    };

    // Auto-prompt greeting if starting fresh
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeLesson = ref.read(activeLessonProvider);
      final role = activeLesson?.conversation.role ?? 'German Native Tutor';
      setState(() {
        _messages.add(
          _Message(
            _Speaker.tutor,
            'Hallo! Ich bin dein Gesprächspartner ($role). Worüber möchtest du heute sprechen?',
          ),
        );
        _tutorTurns.add(_messages.first.text);
      });
      // Listening begins only after the learner taps the microphone.
    });
  }

  @override
  void dispose() {
    WebVoiceService.instance.onTranscriptReceived = null;
    WebVoiceService.instance.onListeningChanged = null;
    WebVoiceService.instance.onError = null;
    WebVoiceService.instance.stopListening();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: TlMotion.medium,
        curve: TlMotion.standard,
      );
    });
  }

  VoiceOrbState get _orbState {
    if (_isSending) return VoiceOrbState.thinking;
    if (_isSpeaking) return VoiceOrbState.speaking;
    if (_isRecording) return VoiceOrbState.listening;
    return VoiceOrbState.idle;
  }

  Future<void> _startListening() async {
    final session = ref.read(learningSessionProvider);
    final langTag = session.target.code.toLowerCase().startsWith('de')
        ? 'de-DE'
        : session.target.code;

    setState(() {
      _isRecording = true;
      _turnStart = DateTime.now();
      _liveTranscript = '';
      _voiceError = null;
    });

    HapticFeedback.mediumImpact();
    final started = await WebVoiceService.instance.startListening(
      langCode: langTag,
    );
    if (!started && mounted) {
      setState(() {
        _isRecording = false;
        _voiceError ??= WebVoiceService.instance.lastFailureMessage;
      });
    }
  }

  void _sendTyped(ConversationPlan plan, String text) {
    _liveTranscript = text;
    _stopAndSend(plan);
  }

  Future<void> _stopAndSend(ConversationPlan plan) async {
    WebVoiceService.instance.stopListening();
    setState(() => _isRecording = false);
    HapticFeedback.lightImpact();

    final userUtterance = _liveTranscript.trim();
    if (userUtterance.isEmpty) return;

    final session = ref.read(learningSessionProvider);
    final latency =
        (DateTime.now().difference(_turnStart).inMilliseconds / 1000.0).clamp(
          0.5,
          20.0,
        );

    setState(() {
      _messages.add(_Message(_Speaker.learner, userUtterance));
      _liveTranscript = '';
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final turn = await ref
          .read(lessonRepositoryProvider)
          .speak(
            session: session,
            role: plan.role,
            situation: plan.situation,
            hiddenTargets: plan.hiddenTargets,
            previousTurns: _tutorTurns,
            utterance: userUtterance,
            latencySec: latency,
            lessonId: ref.read(activeLessonProvider)?.lessonId,
          );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _isSpeaking = true;
        _messages.add(_Message(_Speaker.tutor, turn.reply));
        _tutorTurns.add(turn.reply);
      });
      _scrollToBottom();

      // Native TTS audio output
      WebVoiceService.instance.speak(turn.reply, langCode: 'de-DE');

      final speechMs = (turn.reply.length * 52).clamp(1800, 4800);
      Future.delayed(Duration(milliseconds: speechMs), () {
        if (mounted) {
          setState(() => _isSpeaking = false);
          if (WebVoiceService.instance.lastFailure != null) return;
          // Re-arm listener for smooth continuous natural speaking
          _startListening();
        }
      });
    } catch (_) {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeLesson = ref.watch(activeLessonProvider);
    final plan =
        activeLesson?.conversation ??
        const ConversationPlan(
          role: 'German Native Tutor',
          situation: 'Daily Conversation',
          hiddenTargets: [],
          culturalNotes: [],
        );

    final statusText = switch (_orbState) {
      VoiceOrbState.listening =>
        _liveTranscript.isNotEmpty
            ? '"$_liveTranscript"'
            : 'Listening… speak now',
      VoiceOrbState.thinking => 'Formulating response…',
      VoiceOrbState.speaking => 'Tutor speaking…',
      VoiceOrbState.idle =>
        _voiceError ??
            (_liveTranscript.isNotEmpty
                ? '"$_liveTranscript" · tap the orb to send'
                : 'Tap the pulsing orb to speak'),
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: TlSpace.maxContentWidth,
        ),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.96,
          decoration: BoxDecoration(
            color: const Color(0xFF0D0F14).withValues(alpha: 0.98),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.85),
                blurRadius: 40,
                offset: const Offset(0, -10),
              ),
            ],
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top Bar: Persona Pill + Close
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.sparkles,
                              size: 14,
                              color: TlPalette.brassGold,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              plan.role,
                              style: context.type.labelSmall.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TlPressable(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            AppIcons.x,
                            size: 16,
                            color: colors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Main Conversation Stream (me speaking to AI)
                Expanded(
                  child: ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= _messages.length) {
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: TlSkeleton(
                              height: 38,
                              width: 140,
                              radius: TlRadius.md,
                            ),
                          ),
                        );
                      }

                      final message = _messages[index];
                      final isLearner = message.speaker == _Speaker.learner;

                      return ChatMessageView(
                        isLearner: isLearner,
                        maxWidthFactor: 0.82,
                        verticalMargin: 6,
                        bubbleColor: isLearner ? null : colors.surfaceRaised,
                        bubbleBorder: isLearner
                            ? null
                            : Border.all(
                                color: colors.border.withValues(alpha: 0.6),
                              ),
                        content: isLearner
                            ? SelectableText(
                                message.text,
                                style: context.type.body.copyWith(
                                  color: colors.onAccent,
                                  fontSize: 14,
                                ),
                              )
                            : TutorMarkdown(message.text),
                      );
                    },
                  ),
                ),

                // Short landscape viewports keep the composer reachable.
                if (MediaQuery.sizeOf(context).height > 400)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 6,
                    ),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        statusText,
                        key: ValueKey(statusText),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: context.type.caption.copyWith(
                          color: _isRecording
                              ? colors.primary
                              : colors.textMuted,
                          fontWeight: _isRecording
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                // Bottom Center Pulsating Voice Orb
                Padding(
                  padding: const EdgeInsets.only(bottom: 14, top: 2),
                  child: TlPressable(
                    semanticLabel: _isRecording
                        ? 'Stop and send'
                        : 'Start speaking',
                    onTap: () {
                      if (_isRecording || _liveTranscript.trim().isNotEmpty) {
                        _stopAndSend(plan);
                      } else if (!_isSending && !_isSpeaking) {
                        _startListening();
                      }
                    },
                    child: FluidVoiceOrb(
                      state: _orbState,
                      size: 46, // Proportional compact pulsating icon
                    ),
                  ),
                ),
                TypedReplyBar(
                  enabled: !_isSending,
                  onSubmit: (text) => _sendTyped(plan, text),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
