import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../speak/typed_reply_bar.dart';
import '../../design/app_icons.dart';
import '../../widgets/chat_message_view.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../core/platform/voice_feedback.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../speak/fluid_voice_orb.dart';
import '../settings/api_keys_screen.dart';
import 'conversation_themes.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(this.speaker, this.text);

  final _Speaker speaker;
  final String text;
}

/// Page 2: Arena Voice & Spoken Conversation Screen
///
/// Designed as a first-class screen inside the app's phone layout:
/// - Fits cleanly inside the app shell with no oversized popups
/// - Generous space for ongoing conversation between learner and AI
/// - Inline highlighting for new vocabulary
/// - Small pulsating Siri/Apple-style fluid voice orb anchored at bottom center
class VoiceArenaScreen extends ConsumerStatefulWidget {
  const VoiceArenaScreen({super.key});

  @override
  ConsumerState<VoiceArenaScreen> createState() => _VoiceArenaScreenState();
}

class _VoiceArenaScreenState extends ConsumerState<VoiceArenaScreen> {
  final ScrollController _scroll = ScrollController();
  final List<_Message> _messages = [];
  final List<String> _tutorTurns = [];

  bool _isSending = false;
  bool _isSpeaking = false;
  bool _isRecording = false;
  String _liveTranscript = '';
  String? _error;
  ConversationTheme? _currentTheme;
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
        _error = message;
      });
      showVoiceFailure(context);
    };

    // Initialize initial greeting turn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activeLesson = ref.read(activeLessonProvider);
      final role = activeLesson?.conversation.role ?? 'German Native Tutor';
      setState(() {
        _messages.add(
          _Message(
            _Speaker.tutor,
            'Hallo! Ich bin dein Sprachpartner ($role). Worüber möchtest du heute sprechen?',
          ),
        );
        _tutorTurns.add(_messages.first.text);
      });
    });
  }

  void _switchTheme(ConversationTheme theme) {
    setState(() {
      _currentTheme = theme;
      _messages.clear();
      _tutorTurns.clear();
      _messages.add(
        _Message(
          _Speaker.tutor,
          'Hallo! Ich bin dein Sprachpartner (${theme.role}). Lass uns über "${theme.title}" (${theme.subtitle}) sprechen.',
        ),
      );
      _tutorTurns.add(_messages.first.text);
    });
    WebVoiceService.instance.speak(_messages.first.text, langCode: 'de-DE');
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
      _error = null;
    });

    HapticFeedback.mediumImpact();
    final started = await WebVoiceService.instance.startListening(
      langCode: langTag,
    );
    if (!started && mounted) {
      setState(() {
        _isRecording = false;
        _error ??= WebVoiceService.instance.lastFailureMessage;
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
      _error = null;
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
          );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _isSpeaking = true;
        _messages.add(_Message(_Speaker.tutor, turn.reply));
        _tutorTurns.add(turn.reply);
      });
      _scrollToBottom();

      // Native TTS speech output
      WebVoiceService.instance.speak(turn.reply, langCode: 'de-DE');

      final speechMs = (turn.reply.length * 52).clamp(1800, 4800);
      Future.delayed(Duration(milliseconds: speechMs), () {
        if (mounted) {
          setState(() => _isSpeaking = false);
          if (WebVoiceService.instance.lastFailure != null) return;
          // Auto-resume listening for continuous conversation
          _startListening();
        }
      });
    } on Failure catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _error = 'Could not send right now. Check backend connection.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = ref.watch(activeLessonProvider);
    final effectivePlan = _currentTheme != null
        ? ConversationPlan(
            role: _currentTheme!.role,
            situation: _currentTheme!.situation,
            hiddenTargets: _currentTheme!.hiddenTargets,
            culturalNotes: const [],
          )
        : (lesson?.conversation ??
              const ConversationPlan(
                role: 'German Native Tutor',
                situation: 'Daily Conversation',
                hiddenTargets: [],
                culturalNotes: [],
              ));

    final statusText = switch (_orbState) {
      VoiceOrbState.listening =>
        _liveTranscript.isNotEmpty
            ? '"$_liveTranscript"'
            : 'Listening… speak in German',
      VoiceOrbState.thinking => 'Thinking…',
      VoiceOrbState.speaking => 'Tutor speaking…',
      VoiceOrbState.idle =>
        _error ??
            (_liveTranscript.isNotEmpty
                ? '"$_liveTranscript" · tap the orb to send'
                : 'Tap the orb to speak'),
    };

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: Column(
            children: [
              // Top Minimal Header Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TlSpace.gutter,
                  TlSpace.sm,
                  TlSpace.gutter,
                  TlSpace.xs,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _currentTheme?.icon ?? AppIcons.sparkles,
                            size: 13,
                            color: TlPalette.brassGold,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            _currentTheme?.title ?? effectivePlan.role,
                            style: context.type.labelSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Mural Theme Picker button
                    TlPressable(
                      onTap: () {
                        ThemesPickerSheet.show(
                          context,
                          onSelectTheme: _switchTheme,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              AppIcons.compass,
                              size: 13,
                              color: TlPalette.brassGold,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Themes',
                              style: context.type.caption.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TlPressable(
                      onTap: () => ApiKeysSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(
                          AppIcons.slidersHorizontal,
                          size: 14,
                          color: colors.textSecondary,
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
                    horizontal: TlSpace.gutter,
                    vertical: TlSpace.xs,
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

              // Error notification if any
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TlSpace.gutter,
                    vertical: 4,
                  ),
                  child: Text(
                    _error!,
                    style: context.type.caption.copyWith(color: colors.danger),
                  ),
                ),

              // Status Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 4,
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
                      color: _isRecording ? colors.primary : colors.textMuted,
                      fontWeight: _isRecording
                          ? FontWeight.w700
                          : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

              // Small Pulsating Siri-Style Fluid Orb at Bottom Center
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 2),
                child: TlPressable(
                  onTap: () {
                    if (_isRecording || _liveTranscript.trim().isNotEmpty) {
                      _stopAndSend(effectivePlan);
                    } else if (!_isSending && !_isSpeaking) {
                      _startListening();
                    }
                  },
                  child: FluidVoiceOrb(
                    state: _orbState,
                    size: 44, // Small, clean, non-obtrusive pulsating orb
                  ),
                ),
              ),
              TypedReplyBar(
                enabled: !_isSending,
                onSubmit: (text) => _sendTyped(effectivePlan, text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
