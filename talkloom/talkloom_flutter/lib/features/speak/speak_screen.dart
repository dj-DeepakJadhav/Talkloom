import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../design/app_icons.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../core/platform/voice_feedback.dart';
import '../../core/platform/web_voice_service.dart';
import '../../core/platform/muse_transcription.dart';
import '../../design/components/tl_states.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../content/content_widgets.dart';
import '../content/source_reader.dart';
import '../content/learning_components.dart';
import '../../widgets/chat_message_view.dart';

enum _Speaker { learner, tutor }

class _Message {
  const _Message(
    this.speaker,
    this.text, {
    this.responseMode,
    this.evaluationStatus,
  });

  final _Speaker speaker;
  final String text;
  final String? responseMode;

  /// Server evaluator status, so the UI can show what the agent checked.
  final String? evaluationStatus;
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
  bool _isTranscribing = false;
  bool _useMuseVoice = false;
  String? _museHeardNote;
  String _livePartial = '';
  String? _error;
  DateTime _turnStart = DateTime.now();
  String? _celebrating;

  late final AnimationController _micPulseController;
  final MuseVoiceRecorder _museRecorder = MuseVoiceRecorder();

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
          _livePartial = transcript;
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
        _error = WebVoiceService.instance.lastFailureMessage;
      });
    };
    WebVoiceService.instance.onError = (failure, message) {
      if (!mounted) return;
      _micPulseController.stop();
      setState(() {
        _isRecording = false;
        _error = message;
      });
      showVoiceFailure(context);
    };
  }

  @override
  void dispose() {
    WebVoiceService.instance.onTranscriptReceived = null;
    WebVoiceService.instance.onListeningChanged = null;
    WebVoiceService.instance.onError = null;
    WebVoiceService.instance.stopListening();
    _museRecorder.dispose();
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
            lessonId: ref.read(activeLessonProvider)?.lessonId,
          );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _Message(
            _Speaker.tutor,
            turn.reply,
            responseMode: turn.responseMode,
            evaluationStatus: turn.evaluationStatus,
          ),
        );
        _turnStart = DateTime.now();
        if (turn.evaluatorUnavailable) {
          _error =
              'This turn could not be checked for progress, so it will not count toward your words.';
        }

        final target = turn.detectedTarget;
        if (turn.evidenceEligible &&
            turn.producedSpontaneously &&
            target != null &&
            !_captured.contains(target)) {
          _captured.add(target);
          _celebrating = target;
        }
      });

      // Speak tutor reply out loud in the device voice
      final langTag = session.target.voiceLocale;
      final readReplies = ref.read(appPreferencesProvider).readReplies;
      final speechStarted =
          !readReplies ||
          await WebVoiceService.instance.speak(
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
    if (_isSending || _isTranscribing) return;

    if (_isRecording) {
      // Stop recording
      if (_useMuseVoice) {
        await _stopMuseRecording(plan);
      } else {
        WebVoiceService.instance.stopListening();
      }
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
        _livePartial = '';
        _museHeardNote = null;
        _error = null;
      });
      if (!MediaQuery.disableAnimationsOf(context)) {
        _micPulseController.repeat(reverse: true);
      }

      if (_useMuseVoice) {
        final started = await _museRecorder.start();
        if (!started && mounted) {
          // WAV capture unsupported here: fall back to OS recognition.
          _micPulseController.stop();
          _micPulseController.reset();
          setState(() {
            _isRecording = false;
            _livePartial = '';
            _useMuseVoice = false;
            _error =
                'Muse recording is unavailable here. Using on-device speech instead.';
          });
          _toggleRecording(plan);
        }
        return;
      }

      final session = ref.read(learningSessionProvider);
      final langTag = session.target.voiceLocale;

      // Browser Web Speech API on Web, on-device recognizer on Android/iOS.
      final started = await WebVoiceService.instance.startListening(
        langCode: langTag,
      );
      if (!started && mounted) {
        // Honest failure: the typed composer below stays available.
        _micPulseController.stop();
        _micPulseController.reset();
        setState(() {
          _isRecording = false;
          _error =
              WebVoiceService.instance.lastFailureMessage ??
              'Voice input is unavailable here. Type your reply instead.';
        });
      }
    }
  }

  /// Stops the Muse WAV capture, transcribes it with Muse Voice Transcribe
  /// (biased toward this lesson's target words), and fills the composer.
  Future<void> _stopMuseRecording(ConversationPlan plan) async {
    setState(() => _isTranscribing = true);
    try {
      final base64Audio = await _museRecorder.stopAndRead();
      if (!mounted) return;
      if (base64Audio == null) {
        setState(() => _error = 'Nothing was recorded. Try again.');
        return;
      }
      final vocabulary = plan.hiddenTargets
          .map((id) => id.split(':').last.trim())
          .where((lemma) => lemma.isNotEmpty)
          .toList();
      final transcript = await ref
          .read(lessonRepositoryProvider)
          .transcribeLearnerAudio(
            session: ref.read(learningSessionProvider),
            base64Audio: base64Audio,
            vocabulary: vocabulary,
          );
      if (!mounted) return;
      setState(() {
        _input.text = transcript;
        _input.selection = TextSelection.fromPosition(
          TextPosition(offset: _input.text.length),
        );
        _museHeardNote = 'Heard by Muse Voice Transcribe';
        _livePartial = '';
      });
    } catch (error) {
      if (mounted) setState(() => _error = Failure.from(error).message);
    } finally {
      if (mounted) setState(() => _isTranscribing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final lesson = ref.watch(activeLessonProvider);
    final source = ref.watch(selectedSourceProvider);
    final session = ref.watch(learningSessionProvider);
    final plan = lesson?.conversation ?? ConversationPlan.empty;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            // Short viewports (keyboard open, landscape phone) cannot afford
            // the title row and the two-row composer; compact mode keeps the
            // transcript and the reply field usable instead of overflowing.
            child: LayoutBuilder(
              builder: (context, box) {
                final compact = box.maxHeight < 400;
                return Column(
                  children: [
                    if (!compact)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                        child: Row(
                          children: [
                            IconButton(
                              tooltip: 'Back to Home',
                              onPressed: () => context.go(TlRoutes.home),
                              icon: const Icon(AppIcons.arrowLeft),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Let’s talk about it.',
                                style: context.type.title,
                              ),
                            ),
                            Text(session.target.endonym),
                          ],
                        ),
                      ),
                    if (lesson == null)
                      Expanded(
                        child: SingleChildScrollView(
                          child: const TlEmptyState(
                            icon: AppIcons.messagesSquare,
                            title: 'Your content starts the conversation',
                            message:
                                'Add content, then open its speaking practice.',
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
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                ),
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
                                          AppIcons.fileText,
                                          color: colors.primary,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            source == null
                                                ? 'Your shared content'
                                                : sourceDisplayTitle(source),
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
                                          '${sourcePlatform(source)} · ${source.cefrLevel} · ${session.target.endonym}',
                                          style: context.type.caption,
                                        ),
                                      ),
                                    const Divider(height: 16),
                                    SpeakingPrompt(
                                      situation: plan.situation,
                                      role: plan.role,
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
                                              height: 320,
                                              child: SingleChildScrollView(
                                                child: SourceReader(
                                                  source: source,
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
                                    actionLabel: 'Dismiss',
                                    onRetry: () =>
                                        setState(() => _error = null),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      _buildComposer(plan, compact: compact),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTranscript() {
    final colors = context.colors;
    final session = ref.read(learningSessionProvider);
    if (_messages.isEmpty) {
      return TlEmptyState(
        icon: AppIcons.messagesSquare,
        title: 'What caught your attention?',
        message:
            'Start with one sentence in ${session.target.endonym}. Speak or type below.',
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
        final spokenText = stripVocabMarkup(message.text);
        return ChatMessageView(
          isLearner: learner,
          showAvatar: true,
          label: learner ? 'You' : 'Conversation partner',
          headerExtra:
              !learner &&
                  (message.responseMode == 'template_fallback' ||
                      message.evaluationStatus == 'evaluated')
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.responseMode == 'template_fallback')
                      Text(
                        'Practice reply · template fallback',
                        style: context.type.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    if (message.evaluationStatus != null)
                      EvaluationFeedback(
                        checked: message.evaluationStatus == 'evaluated',
                      ),
                  ],
                )
              : null,
          content: learner
              ? SelectableText(message.text, style: context.type.body)
              : TutorMarkdown(message.text),
          replayButton: learner
              ? null
              : IconButton(
                  tooltip: WebVoiceService.instance.canSpeak
                      ? 'Listen to this reply'
                      : WebVoiceService.instance.speechUnavailableReason,
                  onPressed: WebVoiceService.instance.canSpeak
                      ? () => WebVoiceService.instance.speak(
                          spokenText,
                          langCode: session.target.voiceLocale,
                        )
                      : null,
                  icon: const Icon(AppIcons.volume2, size: 18),
                ),
        );
      },
    );
  }

  Widget _buildComposer(ConversationPlan plan, {bool compact = false}) {
    final colors = context.colors;
    final session = ref.read(learningSessionProvider);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.canvas,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!compact) ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _isTranscribing
                        ? 'Transcribing your recording…'
                        : _isRecording
                        ? (_useMuseVoice
                              ? 'Recording for Muse… tap stop, then review your words.'
                              : 'Listening… tap stop, then review your words.')
                        : 'Say it in ${session.target.endonym}. You can also type.',
                    style: context.type.caption,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Muse'),
                      tooltip:
                          'Transcribe with Muse Voice (biased to this lesson’s words)',
                      selected: _useMuseVoice,
                      onSelected: _isSending || _isTranscribing
                          ? null
                          : (selected) => setState(() {
                              _useMuseVoice = selected;
                              _museHeardNote = null;
                            }),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: _isSending || _isTranscribing
                          ? null
                          : () => _toggleRecording(plan),
                      icon: Icon(
                        _isRecording
                            ? AppIcons.square
                            : (_isTranscribing
                                  ? AppIcons.refreshCw
                                  : AppIcons.mic),
                      ),
                      label: Text(
                        _isRecording
                            ? 'Stop'
                            : (_isTranscribing ? 'Check…' : 'Speak'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (_museHeardNote != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(
                    AppIcons.sparkles,
                    size: 14,
                    color: colors.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(_museHeardNote!, style: context.type.caption),
                ],
              ),
            ],
            // Live partial transcript: OS recognition interim results today,
            // Muse realtime partials tomorrow. Same widget, same place.
            if (_isRecording && _livePartial.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Hearing: ${_livePartial.trim()}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: context.type.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 10),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  enabled: !_isSending && !_isTranscribing,
                  minLines: 1,
                  maxLines: 4,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _send(plan),
                  decoration: const InputDecoration(
                    labelText: 'Your reply',
                    hintText: 'Type or speak',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              if (compact) ...[
                IconButton.outlined(
                  tooltip: _isRecording ? 'Stop' : 'Speak',
                  onPressed: _isSending || _isTranscribing
                      ? null
                      : () => _toggleRecording(plan),
                  icon: Icon(_isRecording ? AppIcons.square : AppIcons.mic),
                ),
                const SizedBox(width: 10),
              ],
              IconButton.filled(
                tooltip: 'Send reply',
                onPressed: _isSending || _isTranscribing
                    ? null
                    : () => _send(plan),
                icon: const Icon(AppIcons.arrowUp),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
