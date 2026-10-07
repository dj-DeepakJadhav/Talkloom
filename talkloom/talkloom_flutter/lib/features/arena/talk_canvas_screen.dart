import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../speak/fluid_voice_orb.dart';
import 'conversation_themes.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(
    this.speaker,
    this.text, {
    this.translation,
    this.responseMode,
  });
  final _Speaker speaker;
  final String text;
  final String? translation;
  final String? responseMode;
}

/// Mural 1:1 Talk Canvas Screen (matching 03-talk.png & RootView.swift: TalkView)
///
/// Features replicated 1:1 with Talkloom dark & brass-gold styling:
/// - Top Pill Capsule: "A little everyday German" or active theme title
/// - Central Radiant Ambient Glow Orb with breath animation & energy reaction
/// - Status text: "Ready when you are" / "Listening…" / "Tutor speaking…"
/// - Hero Target German Passage: Large bold centered text (e.g. "Hallo!")
/// - Meaning Subtitle: Live English translation toggleable with the Meaning button
/// - 3-Button Bottom Cluster:
///   1. [ Meaning ] (captions toggle)
///   2. [ 76px Amber Hero Mic Orb ] (tap to talk / mute)
///   3. [ Transcript ] (opens clean drawer of conversation turns)
/// - Sub-controls: "Type instead" and "A little help"
class TalkCanvasScreen extends ConsumerStatefulWidget {
  const TalkCanvasScreen({
    super.key,
    this.initialTheme,
  });

  final ConversationTheme? initialTheme;

  @override
  ConsumerState<TalkCanvasScreen> createState() => TalkCanvasScreenState();
}

class TalkCanvasScreenState extends ConsumerState<TalkCanvasScreen>
    with SingleTickerProviderStateMixin {
  final List<_Message> _messages = [];

  bool _isSending = false;
  bool _isSpeaking = false;
  bool _isRecording = false;
  bool _showMeaning = true;
  String _liveTranscript = '';
  String? _error;
  DateTime _turnStart = DateTime.now();

  ConversationTheme? _currentTheme;
  late AnimationController _orbAnimController;

  @override
  void initState() {
    super.initState();
    _currentTheme = widget.initialTheme;

    _orbAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    WebVoiceService.instance.init();
    WebVoiceService.instance.onTranscriptReceived = (transcript) {
      if (mounted && _isRecording) {
        setState(() {
          _liveTranscript = transcript;
        });
      }
    };

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initGreeting();
    });
  }

  void _initGreeting() {
    final activeLesson = ref.read(activeLessonProvider);
    final theme = _currentTheme;
    final greeting = theme != null
        ? theme.initialGreeting
        : (activeLesson?.conversation.role != null
              ? 'Hallo! Ich bin dein Sprachpartner (${activeLesson!.conversation.role}).'
              : 'Hallo! Was darf es für Sie sein?');
    final translation = theme?.initialTranslation;

    setState(() {
      _messages.clear();
      _messages.add(
        _Message(_Speaker.tutor, greeting, translation: translation),
      );
    });
  }

  void setTheme(ConversationTheme theme) {
    setState(() {
      _currentTheme = theme;
      _initGreeting();
    });
    WebVoiceService.instance.speak(_messages.first.text, langCode: 'de-DE');
  }

  @override
  void dispose() {
    _orbAnimController.dispose();
    WebVoiceService.instance.stopListening();
    super.dispose();
  }

  void _startListening() {
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
    final started = WebVoiceService.instance.startListening(langCode: langTag);
    if (!started && mounted) {
      setState(() {
        _isRecording = false;
        _error =
            'Microphone input is unavailable. Allow microphone access or choose “Type instead”.';
      });
    }
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

    try {
      final turn = await ref
          .read(lessonRepositoryProvider)
          .speak(
            session: session,
            role: plan.role,
            situation: plan.situation,
            hiddenTargets: plan.hiddenTargets,
            previousTurns: _messages
                .take(_messages.length - 1)
                .map(
                  (message) => jsonEncode({
                    'role': message.speaker == _Speaker.learner
                        ? 'learner'
                        : 'tutor',
                    'content': message.text,
                    'assistance': message.speaker == _Speaker.learner
                        ? 'none'
                        : 'modelled',
                  }),
                )
                .toList(),
            utterance: userUtterance,
            latencySec: latency,
          );

      if (!mounted) return;

      setState(() {
        _isSending = false;
        _isSpeaking = true;
        _messages.add(
          _Message(
            _Speaker.tutor,
            turn.reply,
            responseMode: turn.responseMode,
          ),
        );
      });

      final speechStarted = await WebVoiceService.instance.speak(
        turn.reply,
        langCode: 'de-DE',
      );

      if (speechStarted) {
        final speechMs = (turn.reply.length * 52).clamp(1800, 4800);
        Future.delayed(Duration(milliseconds: speechMs), () {
          if (mounted) setState(() => _isSpeaking = false);
        });
      } else {
        setState(() {
          _isSpeaking = false;
          _error = WebVoiceService.instance.speechUnavailableReason;
        });
      }
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
        _error = 'Could not reach server. Verify connection.';
      });
    }
  }

  void _showTypedReplyDialog(ConversationPlan plan) {
    final textController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.colors;
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: TlSpace.maxContentWidth,
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  border: Border(top: BorderSide(color: colors.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Type your reply',
                      style: ctx.type.title.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: textController,
                      autofocus: true,
                      style: ctx.type.body,
                      decoration: InputDecoration(
                        hintText: 'Antwort auf Deutsch eingeben…',
                        hintStyle: ctx.type.body.copyWith(
                          color: colors.textMuted,
                        ),
                        filled: true,
                        fillColor: colors.surfaceRaised,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.border),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          final text = textController.text.trim();
                          if (text.isNotEmpty) {
                            Navigator.of(ctx).pop();
                            setState(() {
                              _liveTranscript = text;
                            });
                            _stopAndSend(plan);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Send reply'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showTranscriptSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final colors = ctx.colors;
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TlSpace.maxContentWidth,
            ),
            child: Container(
              height: MediaQuery.sizeOf(ctx).height * 0.75,
              decoration: BoxDecoration(
                color: colors.canvas,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border(top: BorderSide(color: colors.border)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    child: Row(
                      children: [
                        Text(
                          'Our conversation',
                          style: ctx.type.title.copyWith(fontSize: 20),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 8,
                      ),
                      itemCount: _messages.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 16),
                      itemBuilder: (ctx, i) {
                        final msg = _messages[i];
                        final isUser = msg.speaker == _Speaker.learner;
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isUser ? 'YOU' : 'TALKLOOM',
                              style: ctx.type.caption.copyWith(
                                fontSize: 10,
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: isUser
                                    ? colors.primary
                                    : TlPalette.brassGold,
                              ),
                            ),
                            if (!isUser &&
                                msg.responseMode == 'template_fallback')
                              Text(
                                'Practice reply · template fallback',
                                style: ctx.type.caption.copyWith(
                                  color: colors.textMuted,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              msg.text,
                              style: ctx.type.body.copyWith(
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
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

    final themePillLabel = _currentTheme != null
        ? _currentTheme!.title
        : 'A little everyday German';

    final latestTutorMessage = _messages
        .where((m) => m.speaker == _Speaker.tutor)
        .lastOrNull
        ?.text;

    final statusLabel = switch (true) {
      _ when _isSending => 'Thinking…',
      _ when _isSpeaking => 'Speaking…',
      _ when _isRecording =>
        _liveTranscript.isNotEmpty
            ? '"$_liveTranscript"'
            : 'Listening… speak now',
      _ => 'Ready when you are',
    };

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: Column(
            children: [
              // Top Minimal Language Pill matching Mural 03-talk.png
              Padding(
                padding: const EdgeInsets.only(top: 14, bottom: 8),
                child: GestureDetector(
                  onTap: () {
                    ThemesPickerSheet.show(
                      context,
                      onSelectTheme: setTheme,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surfaceRaised,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          themePillLabel,
                          style: context.type.caption.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          LucideIcons.chevronDown,
                          size: 14,
                          color: colors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 1),

              // Proprietary Ambient Harmonic Fluid Voice Orb (Custom Talkloom Sine Deformation & Specular Rim)
              FluidVoiceOrb(
                state: switch (true) {
                  _ when _isSending => VoiceOrbState.thinking,
                  _ when _isSpeaking => VoiceOrbState.speaking,
                  _ when _isRecording => VoiceOrbState.listening,
                  _ => VoiceOrbState.idle,
                },
                size: 210,
                soundLevel: _isRecording ? 0.85 : 0.45,
              ),

              const SizedBox(height: 28),

              // Status indicator ("Ready when you are")
              Text(
                statusLabel,
                style: context.type.caption.copyWith(
                  color: _isRecording ? colors.primary : colors.textMuted,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 18),

              // Hero German Target Phrase (e.g. "¡Hola!" in Mural)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Text(
                  latestTutorMessage ?? 'Hallo!',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: context.type.display.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                ),
              ),

              // English Meaning Subtitle (matching Mural 03-talk.png)
              if (_showMeaning) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    _isRecording && _liveTranscript.isNotEmpty
                        ? 'Listening…'
                        : (_messages.isNotEmpty &&
                                  _messages.last.speaker == _Speaker.tutor
                              ? (_messages.last.translation ??
                                    'Translation is not available for this reply.')
                              : 'Your partner’s meaning will appear here when available.'),
                    textAlign: TextAlign.center,
                    style: context.type.body.copyWith(
                      color: colors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],

              const Spacer(flex: 2),

              // Error if any
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: context.type.caption.copyWith(color: colors.danger),
                  ),
                ),

              // Mural 3-Button Bottom Cluster (Meaning - Hero Mic - Transcript)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Button 1: Meaning Subtitles
                    GestureDetector(
                      onTap: () {
                        setState(() => _showMeaning = !_showMeaning);
                        HapticFeedback.lightImpact();
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: _showMeaning
                                  ? colors.primarySoft
                                  : colors.surfaceRaised,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: _showMeaning
                                    ? colors.primary
                                    : colors.border,
                              ),
                            ),
                            child: Icon(
                              _showMeaning
                                  ? LucideIcons.messageSquare
                                  : LucideIcons.messageSquareDashed,
                              size: 20,
                              color: _showMeaning
                                  ? colors.primary
                                  : colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Meaning',
                            style: context.type.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Button 2: Hero Center 76px Mic Orb matching Mural 03-talk.png
                    GestureDetector(
                      onTap: () {
                        if (_isRecording) {
                          _stopAndSend(effectivePlan);
                        } else if (!_isSending && !_isSpeaking) {
                          _startListening();
                        }
                      },
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFBBF24),
                              TlPalette.brassGold,
                              Color(0xFFD97706),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: TlPalette.brassGold.withValues(
                                alpha: 0.45,
                              ),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isRecording ? LucideIcons.square : LucideIcons.mic,
                            size: 32,
                            color: const Color(0xFF0D0F12),
                          ),
                        ),
                      ),
                    ),

                    // Button 3: Transcript
                    GestureDetector(
                      onTap: _showTranscriptSheet,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                            child: Icon(
                              LucideIcons.fileText,
                              size: 20,
                              color: colors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Transcript',
                            style: context.type.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // State hint
              Text(
                _isRecording
                    ? 'Listening… tap orb to finish'
                    : 'Microphone off',
                style: context.type.caption.copyWith(
                  fontSize: 12,
                  color: colors.textMuted,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                'Reply in whichever language comes to you.',
                style: context.type.caption.copyWith(
                  fontSize: 12,
                  color: colors.textSecondary,
                ),
              ),

              const SizedBox(height: 18),

              // Secondary actions ("Type instead" & "A little help")
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => _showTypedReplyDialog(effectivePlan),
                    icon: const Icon(LucideIcons.keyboard, size: 14),
                    label: const Text('Type instead'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      textStyle: context.type.caption.copyWith(fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: () {
                      final hint = effectivePlan.hiddenTargets.isNotEmpty
                          ? 'Try using: ${effectivePlan.hiddenTargets.take(2).join(', ')}'
                          : 'Try saying "Guten Tag, wie geht es Ihnen?"';
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(
                                LucideIcons.sparkles,
                                size: 16,
                                color: TlPalette.brassGold,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  hint,
                                  style: context.type.bodySmall.copyWith(
                                    color: colors.textPrimary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          backgroundColor: colors.surfaceRaised,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(color: colors.borderStrong),
                          ),
                          margin: const EdgeInsets.fromLTRB(24, 0, 24, 90),
                          duration: const Duration(seconds: 4),
                        ),
                      );
                    },
                    icon: const Icon(LucideIcons.sparkles, size: 14),
                    label: const Text('A little help'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.textSecondary,
                      textStyle: context.type.caption.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}
