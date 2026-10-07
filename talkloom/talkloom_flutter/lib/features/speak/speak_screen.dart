import 'dart:convert';
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
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../content/content_widgets.dart';
import '../shell/talkloom_navigation_bar.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(this.speaker, this.text, {this.responseMode});

  final _Speaker speaker;
  final String text;
  final String? responseMode;
}

/// Speaking from the learner’s own content, with optional practice alongside it.
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
  final List<String> _captured = [];

  bool _isSending = false;
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
    WebVoiceService.instance.onListeningChanged = (listening) {
      if (!mounted || listening || !_isRecording) return;
      _micPulseController.stop();
      setState(() {
        _isRecording = false;
        _error =
            'Microphone stopped. Check browser permissions, or type your reply below.';
      });
    };
  }

  @override
  void dispose() {
    WebVoiceService.instance.onTranscriptReceived = null;
    WebVoiceService.instance.onListeningChanged = null;
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
            utterance: text,
            latencySec: latency,
          );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _Message(
            _Speaker.tutor,
            turn.reply,
            responseMode: turn.responseMode,
          ),
        );
        _turnStart = DateTime.now();

        final target = turn.detectedTarget;
        if (turn.evidenceEligible &&
            turn.producedSpontaneously &&
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
      final speechStarted = await WebVoiceService.instance.speak(
        turn.reply,
        langCode: langTag,
      );
      if (!speechStarted && mounted) {
        setState(() {
          _error = WebVoiceService.instance.speechUnavailableReason;
        });
      }

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
      final started = WebVoiceService.instance.startListening(
        langCode: langTag,
      );
      if (!started) {
        // Fallback for browsers blocking or not supporting Web Speech API
        _micPulseController.stop();
        setState(() {
          _isRecording = false;
          _error =
              'Voice input is unavailable here. Try a supported browser and allow microphone access, or type your reply.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = ref.watch(activeLessonProvider);
    final source = ref.watch(selectedSourceProvider);
    final plan = lesson?.conversation ?? ConversationPlan.empty;
    return Scaffold(
      bottomNavigationBar: TalkloomNavigationBar(
        selectedIndex: 1,
        onDestinationSelected: (index) => context.go('/?tab=$index'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to Today',
                        onPressed: () => context.go(TlRoutes.home),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Let’s talk about it.',
                          style: context.type.title,
                        ),
                      ),
                      const Text('GERMAN'),
                    ],
                  ),
                ),
                if (lesson == null)
                  const Expanded(
                    child: SingleChildScrollView(
                      child: TlEmptyState(
                        icon: LucideIcons.messagesSquare,
                        title: 'Your content starts the conversation',
                        message:
                            'Add German content and open its speaking practice to begin.',
                      ),
                    ),
                  )
                else ...[
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _scroll,
                      child: Column(
                        children: [
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 20),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              border: Border.all(color: colors.border),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.article_outlined,
                                      color: colors.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        source?.title ?? 'Your shared content',
                                        style: context.type.bodyStrong,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (source != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      '${sourcePlatform(source)} · ${source.cefrLevel} · German',
                                      style: context.type.caption,
                                    ),
                                  ),
                                const Divider(height: 16),
                                Text(
                                  'YOUR CONVERSATION GOAL',
                                  style: context.type.caption.copyWith(
                                    color: colors.primary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  plan.situation,
                                  style: context.type.bodyStrong,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Your partner: ${plan.role}. Start small. Mistakes are welcome.',
                                  style: context.type.caption,
                                ),
                                if (source != null &&
                                    source.rawText.trim().isNotEmpty)
                                  Material(
                                    color: colors.surface,
                                    child: ExpansionTile(
                                      tilePadding: EdgeInsets.zero,
                                      title: Text(
                                        'Look back at the source',
                                        style: context.type.caption,
                                      ),
                                      children: [
                                        SizedBox(
                                          height: 130,
                                          child: SingleChildScrollView(
                                            child: SelectableText(
                                              source.rawText,
                                              style: context.type.body,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          _buildTranscript(),
                          if (_celebrating != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Text(
                                'Expression detected: ${_celebrating!.split(':').last}',
                                style: context.type.caption,
                              ),
                            ),
                          if (_error != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              child: TlErrorState(
                                message: _error!,
                                onRetry: () => setState(() => _error = null),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  _buildComposer(plan),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscript() {
    final colors = context.colors;
    if (_messages.isEmpty) {
      return const TlEmptyState(
        icon: LucideIcons.messagesSquare,
        title: 'What caught your attention?',
        message:
            'Start with one sentence in German. Speak into the microphone or type below.',
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      itemCount: _messages.length + (_isSending ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Your partner is thinking…',
              style: context.type.caption,
            ),
          );
        }
        final message = _messages[index];
        final learner = message.speaker == _Speaker.learner;
        final text = message.text.replaceAllMapped(
          RegExp(r'\[\[new:([^:|\]]+)(?::([^\]]+))?\]\]'),
          (match) => match.group(1)!,
        );
        return Padding(
          padding: const EdgeInsets.only(bottom: 18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 17,
                backgroundColor: learner
                    ? colors.primarySoft
                    : colors.surfaceRaised,
                child: Icon(
                  learner ? Icons.person_outline : Icons.chat_bubble_outline,
                  size: 18,
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner ? 'You' : 'Conversation partner',
                      style: context.type.caption,
                    ),
                    if (!learner && message.responseMode == 'template_fallback')
                      Text(
                        'Practice reply · template fallback',
                        style: context.type.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    const SizedBox(height: 5),
                    SelectableText(text, style: context.type.body),
                    if (!learner)
                      IconButton(
                        tooltip: WebVoiceService.instance.canSpeak
                            ? 'Listen to this reply'
                            : WebVoiceService.instance.speechUnavailableReason,
                        onPressed: WebVoiceService.instance.canSpeak
                            ? () => WebVoiceService.instance.speak(text)
                            : null,
                        icon: const Icon(Icons.volume_up_outlined, size: 18),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComposer(ConversationPlan plan) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _isRecording
                      ? 'Listening… tap stop, then review your words.'
                      : 'Say it in German. You can also type.',
                  style: context.type.caption,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _isSending ? null : () => _toggleRecording(plan),
                icon: Icon(_isRecording ? Icons.stop : Icons.mic_none),
                label: Text(_isRecording ? 'Stop' : 'Speak'),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
                  onSubmitted: (_) => _send(plan),
                  decoration: const InputDecoration(
                    labelText: 'Your German reply',
                    hintText: 'Ich denke, dass…',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send reply',
                onPressed: _isSending ? null : () => _send(plan),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
