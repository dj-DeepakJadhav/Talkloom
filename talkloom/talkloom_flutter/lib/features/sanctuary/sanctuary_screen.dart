import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/failure.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../../widgets/talkloom_logo.dart';
import '../inbox/language_sheet.dart';
import '../settings/api_keys_screen.dart';

/// Page 1: Top Google-style Omni Bar + Vault/Grammar Tabs + Recent Syntheses
class SanctuaryScreen extends ConsumerStatefulWidget {
  const SanctuaryScreen({super.key});

  @override
  ConsumerState<SanctuaryScreen> createState() => _SanctuaryScreenState();
}

class _SanctuaryScreenState extends ConsumerState<SanctuaryScreen> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  String? _detectedFileName;
  String? _detectedMediaPayload;
  String _mediaMimeType = 'application/pdf';
  String? _activeError;
  int _activeTabIndex = 0; // 0: Vocabulary, 1: Phrases, 2: Grammar

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim();
    if (text != null && text.isNotEmpty) {
      setState(() {
        _inputController.text = text;
        _activeError = null;
      });
      HapticFeedback.lightImpact();
    }
  }

  Future<void> _pickDocument({bool cameraMode = false}) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: cameraMode ? FileType.image : FileType.custom,
        allowedExtensions: cameraMode ? null : ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;
        if (bytes != null) {
          final ext = file.extension?.toLowerCase() ?? 'txt';
          final mime = (ext == 'pdf')
              ? 'application/pdf'
              : (ext == 'png'
                  ? 'image/png'
                  : (ext == 'jpg' || ext == 'jpeg'
                      ? 'image/jpeg'
                      : 'text/plain'));
          setState(() {
            _detectedFileName = file.name;
            _mediaMimeType = mime;
            _detectedMediaPayload = 'data:$mime;base64,${base64Encode(bytes)}';
            _inputController.text = file.name;
            _activeError = null;
          });
          HapticFeedback.lightImpact();
        }
      }
    } catch (_) {}
  }

  Future<void> _handleSynthesize() async {
    final raw = _inputController.text.trim();
    if (raw.isEmpty && _detectedMediaPayload == null) return;

    final notifier = ref.read(importControllerProvider.notifier);
    setState(() => _activeError = null);

    try {
      LessonContent? lesson;
      if (_detectedMediaPayload != null) {
        lesson = await notifier.importMedia(
          title: _detectedFileName ?? 'Document Upload',
          base64Content: _detectedMediaPayload!,
          type: _mediaMimeType.startsWith('image/') ? 'image' : 'document',
        );
      } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
        final isYouTube = raw.contains('youtu');
        lesson = await notifier.importUrl(
          title: isYouTube ? 'YouTube Lesson' : 'Web Lesson',
          url: raw,
        );
      } else {
        lesson = await notifier.importText(
          title: raw.length > 25 ? '${raw.substring(0, 25)}…' : raw,
          text: raw,
        );
      }

      if (lesson != null && mounted) {
        _inputController.clear();
        setState(() {
          _detectedFileName = null;
          _detectedMediaPayload = null;
        });
        ref.invalidate(sourcesProvider);
        context.push(TlRoutes.lesson);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _activeError = Failure.from(e).message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final session = ref.watch(learningSessionProvider);
    final importState = ref.watch(importControllerProvider);
    final isSynthesizing = importState.isLoading;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
            child: Column(
              children: [
                // Top Header Row: Logo & Target Language Pill
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: TlSpace.gutter,
                    vertical: TlSpace.xs,
                  ),
                  child: Row(
                    children: [
                      const TalkloomLogo(size: 28),
                      const SizedBox(width: TlSpace.xs),
                      Text(
                        'Talkloom',
                        style: context.type.title.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Spacer(),
                      TlPressable(
                        onTap: () => showLanguageSheet(context, ref),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: TlRadius.pillRadius,
                            border: Border.all(color: colors.border),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                session.target.flag,
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                '${session.target.code.toUpperCase()} • ${session.level.code}',
                                style: context.type.labelSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                LucideIcons.chevronDown,
                                size: 13,
                                color: colors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TlPressable(
                        onTap: () => ApiKeysSheet.show(context),
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(color: colors.border),
                          ),
                          child: Icon(
                            LucideIcons.slidersHorizontal,
                            size: 15,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Top Google Search-Style Omni Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TlSpace.gutter,
                    4,
                    TlSpace.gutter,
                    TlSpace.sm,
                  ),
                  child: _GoogleStyleOmniBar(
                    controller: _inputController,
                    focusNode: _focusNode,
                    isSynthesizing: isSynthesizing,
                    fileName: _detectedFileName,
                    error: _activeError,
                    onPaste: _pasteFromClipboard,
                    onPickFile: () => _pickDocument(cameraMode: false),
                    onCamera: () => _pickDocument(cameraMode: true),
                    onSynthesize: _handleSynthesize,
                    onClear: () {
                      _inputController.clear();
                      setState(() {
                        _detectedFileName = null;
                        _detectedMediaPayload = null;
                        _activeError = null;
                      });
                    },
                  ),
                ),

                // Segmented Tabs: [ 📖 Words ] [ 💬 Phrases ] [ ⚡ Grammar ]
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                  child: _VaultSegmentedTabs(
                    selectedIndex: _activeTabIndex,
                    onTabSelected: (index) {
                      setState(() => _activeTabIndex = index);
                      HapticFeedback.selectionClick();
                    },
                  ),
                ),

                const SizedBox(height: TlSpace.sm),

                // Main Tab Content (Words / Phrases / Grammar)
                Expanded(
                  child: IndexedStack(
                    index: _activeTabIndex,
                    children: const [
                      _VocabularyTabContent(),
                      _PhrasesTabContent(),
                      _GrammarTabContent(),
                    ],
                  ),
                ),

                // Recent Synthesized Lessons Gallery
                const _RecentVisualGallery(),

                const SizedBox(height: TlSpace.sm),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Google Search Bar on Android styled Omni Bar:
/// [ 🔍 Search, link or prompt... | 📋 | 📎 | 📷 | ⬆️ ]
class _GoogleStyleOmniBar extends StatelessWidget {
  const _GoogleStyleOmniBar({
    required this.controller,
    required this.focusNode,
    required this.isSynthesizing,
    required this.fileName,
    required this.error,
    required this.onPaste,
    required this.onPickFile,
    required this.onCamera,
    required this.onSynthesize,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isSynthesizing;
  final String? fileName;
  final String? error;
  final VoidCallback onPaste;
  final VoidCallback onPickFile;
  final VoidCallback onCamera;
  final VoidCallback onSynthesize;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasContent = controller.text.trim().isNotEmpty || fileName != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: hasContent
                  ? colors.primary.withValues(alpha: 0.85)
                  : colors.border,
              width: hasContent ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.08),
                blurRadius: 18,
                offset: const Offset(0, 4),
              ),
              if (hasContent)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.12),
                  blurRadius: 16,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          child: Row(
            children: [
              // Main Text Input
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  enabled: !isSynthesizing,
                  style: context.type.body.copyWith(
                    color: colors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Paste URL or attach document…',
                    hintStyle: context.type.body.copyWith(
                      color: colors.textMuted,
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (_) => onSynthesize(),
                ),
              ),

              // Clear button
              if (hasContent && !isSynthesizing) ...[
                TlPressable(
                  onTap: onClear,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 16,
                      color: colors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(width: 2),
              ],

              // Clipboard Paste Action
              if (!hasContent && !isSynthesizing) ...[
                Tooltip(
                  message: 'Paste from clipboard',
                  child: TlPressable(
                    onTap: onPaste,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.clipboard,
                        size: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // Attachment / Document Upload
              if (!isSynthesizing) ...[
                Tooltip(
                  message: 'Upload file or PDF',
                  child: TlPressable(
                    onTap: onPickFile,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.paperclip,
                        size: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
              ],

              // Camera Action Button (Google Lens style)
              if (!isSynthesizing) ...[
                Tooltip(
                  message: 'Scan with Camera / Image',
                  child: TlPressable(
                    onTap: onCamera,
                    child: Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        LucideIcons.camera,
                        size: 15,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],

              // Synthesize / Action trigger
              TlPressable(
                onTap: () {
                  if (!isSynthesizing) onSynthesize();
                },
                child: Container(
                  height: 38,
                  width: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: hasContent
                          ? [
                              TlPalette.brassGoldLight,
                              TlPalette.brassGold,
                              TlPalette.brassGoldDeep,
                            ]
                          : [
                              colors.borderStrong,
                              colors.border,
                            ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: hasContent
                        ? [
                            BoxShadow(
                              color: TlPalette.brassGold.withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isSynthesizing
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.surface,
                            ),
                          )
                        : Icon(
                            LucideIcons.arrowUp,
                            size: 18,
                            color: hasContent
                                ? TlPalette.obsidian
                                : colors.textMuted,
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Error message if any
        if (error != null) ...[
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              error!,
              style: context.type.caption.copyWith(color: colors.danger),
            ),
          ),
        ],
      ],
    );
  }
}

/// Tactile Segmented Switcher for Tabs
class _VaultSegmentedTabs extends StatelessWidget {
  const _VaultSegmentedTabs({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final tabs = [
      (LucideIcons.bookOpen, 'Words'),
      (LucideIcons.messageSquare, 'Phrases'),
      (LucideIcons.zap, 'Grammar'),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final isSelected = selectedIndex == i;
          final tab = tabs[i];

          return Expanded(
            child: TlPressable(
              onTap: () => onTabSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? colors.surfaceRaised : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: isSelected
                      ? Border.all(
                          color: colors.borderStrong.withValues(alpha: 0.5),
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      tab.$1,
                      size: 15,
                      color: isSelected ? colors.primary : colors.textMuted,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tab.$2,
                      style: context.type.labelSmall.copyWith(
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? colors.textPrimary : colors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// Tab 1: Words & Vocabulary from the Active Lesson / Learned Vault
class _VocabularyTabContent extends ConsumerWidget {
  const _VocabularyTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeLesson = ref.watch(activeLessonProvider);
    final learnerStateAsync = ref.watch(learnerStateProvider);

    final lessonWords = activeLesson?.vocabulary ?? const <VocabularyItem>[];

    if (lessonWords.isEmpty) {
      return learnerStateAsync.maybeWhen(
        data: (state) {
          final words = [
            ...?(state?.activeWords),
            ...?(state?.recognizedWords),
          ];
          if (words.isEmpty) {
            return _EmptyVaultPlaceholder(
              icon: LucideIcons.bookOpen,
              title: 'No vocabulary yet',
              message: 'Paste a link or upload a document to extract words.',
            );
          }
          return _WordChipsGrid(words: words);
        },
        orElse: () => _EmptyVaultPlaceholder(
          icon: LucideIcons.bookOpen,
          title: 'Your Vocabulary Vault',
          message: 'Synthesize your first lesson above to extract native words.',
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: TlSpace.xs,
      ),
      itemCount: lessonWords.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final item = lessonWords[index];
        final article = item.article.trim();

        Color articleColor = colors.primary;
        if (article == 'der') articleColor = colors.info;
        if (article == 'die') articleColor = colors.danger;
        if (article == 'das') articleColor = colors.success;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              if (article.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: articleColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article,
                    style: context.type.labelSmall.copyWith(
                      color: articleColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.lemma,
                      style: context.type.bodyStrong.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (item.meaning.isNotEmpty)
                      Text(
                        item.meaning,
                        style: context.type.caption.copyWith(
                          color: colors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              // Spoken Recall Strength (Mural Pattern: 1 · Fragile, 2 · Growing, 3 · Steady)
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int bar = 0; bar < 3; bar++)
                        Container(
                          width: 14,
                          height: 4,
                          margin: const EdgeInsets.only(left: 3),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            color: bar <= (index % 3)
                                ? TlPalette.brassGold
                                : colors.borderStrong.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (index % 3) == 0
                        ? '1 · Fragile'
                        : ((index % 3) == 1 ? '2 · Growing' : '3 · Steady'),
                    style: context.type.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              TlPressable(
                onTap: () {
                  final textToSpeak =
                      article.isNotEmpty ? '$article ${item.lemma}' : item.lemma;
                  WebVoiceService.instance.speak(textToSpeak, langCode: 'de-DE');
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.volume2,
                    size: 15,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Fallback grid for words stored in learner state
class _WordChipsGrid extends StatelessWidget {
  const _WordChipsGrid({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: TlSpace.xs,
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: words.map((word) {
          return TlPressable(
            onTap: () {
              WebVoiceService.instance.speak(word, langCode: 'de-DE');
              HapticFeedback.lightImpact();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    word,
                    style: context.type.bodyStrong.copyWith(fontSize: 13),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    LucideIcons.volume2,
                    size: 13,
                    color: colors.textMuted,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Tab 2: Chunks & Conversational Phrases
class _PhrasesTabContent extends ConsumerWidget {
  const _PhrasesTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeLesson = ref.watch(activeLessonProvider);

    final phrases = <String>[];
    if (activeLesson != null) {
      for (final act in activeLesson.activities) {
        if (act is SentenceBuilderActivity) {
          phrases.add(act.target);
        }
      }
      for (final item in activeLesson.vocabulary) {
        if (item.sourceContext.isNotEmpty && !phrases.contains(item.sourceContext)) {
          phrases.add(item.sourceContext);
        }
      }
    }

    if (phrases.isEmpty) {
      return const _EmptyVaultPlaceholder(
        icon: LucideIcons.messageSquare,
        title: 'No phrases yet',
        message: 'Synthesize a video or article to capture natural spoken sentences.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: TlSpace.xs,
      ),
      itemCount: phrases.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final phrase = phrases[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  phrase,
                  style: context.type.body.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              TlPressable(
                onTap: () {
                  WebVoiceService.instance.speak(phrase, langCode: 'de-DE');
                  HapticFeedback.lightImpact();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.volume2,
                    size: 15,
                    color: colors.primary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Tab 3: Visual Grammar Rules
class _GrammarTabContent extends ConsumerWidget {
  const _GrammarTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final activeLesson = ref.watch(activeLessonProvider);

    final rules = activeLesson?.grammar ?? const <GrammarRule>[];

    if (rules.isEmpty) {
      return const _EmptyVaultPlaceholder(
        icon: LucideIcons.zap,
        title: 'Grammar Patterns',
        message: 'Synthesized lessons automatically extract structural grammar blueprints.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: TlSpace.xs,
      ),
      itemCount: rules.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final rule = rules[index];
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colors.primarySoft,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      rule.concept,
                      style: context.type.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              if (rule.sourceSentence.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    rule.sourceSentence,
                    style: context.type.bodyStrong.copyWith(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
              if (rule.explanation.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  rule.explanation,
                  style: context.type.caption.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Clean Minimal Placeholder for empty tabs
class _EmptyVaultPlaceholder extends StatelessWidget {
  const _EmptyVaultPlaceholder({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(TlSpace.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceRaised,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 22, color: colors.textMuted),
            ),
            const SizedBox(height: TlSpace.sm),
            Text(
              title,
              style: context.type.bodyStrong.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.type.caption.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Recent Synthesized Lessons Gallery
class _RecentVisualGallery extends ConsumerWidget {
  const _RecentVisualGallery();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final sourcesAsync = ref.watch(sourcesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
          child: Row(
            children: [
              Text(
                'Recent Lessons',
                style: context.type.label.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0.5,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              sourcesAsync.maybeWhen(
                data: (sources) => sources.isNotEmpty
                    ? Text(
                        '${sources.length}',
                        style: context.type.caption.copyWith(
                          color: colors.textMuted,
                        ),
                      )
                    : const SizedBox.shrink(),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 96,
          child: sourcesAsync.when(
            loading: () => ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
              children: const [
                TlSkeleton(height: 86, width: 180, radius: TlRadius.md),
                SizedBox(width: TlSpace.sm),
                TlSkeleton(height: 86, width: 180, radius: TlRadius.md),
              ],
            ),
            error: (_, _) => const SizedBox.shrink(),
            data: (sources) {
              if (sources.isEmpty) {
                return Center(
                  child: Text(
                    'No recent lessons yet.',
                    style: context.type.caption.copyWith(
                      color: colors.textMuted,
                    ),
                  ),
                );
              }

              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                itemCount: sources.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final source = sources[index];
                  return _VisualSourceCard(source: source);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VisualSourceCard extends ConsumerStatefulWidget {
  const _VisualSourceCard({required this.source});

  final Source source;

  @override
  ConsumerState<_VisualSourceCard> createState() => _VisualSourceCardState();
}

class _VisualSourceCardState extends ConsumerState<_VisualSourceCard> {
  bool _opening = false;

  Future<void> _open() async {
    final id = widget.source.id;
    if (id == null || _opening) return;

    setState(() => _opening = true);
    try {
      final lesson =
          await ref.read(lessonRepositoryProvider).lessonForSource(id);
      if (lesson != null && mounted) {
        ref
            .read(activeLessonProvider.notifier)
            .open(LessonContent.fromLesson(lesson));
        context.push(TlRoutes.lesson);
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final source = widget.source;
    final isUrl = source.type == 'url';

    return TlPressable(
      onTap: _open,
      child: Container(
        width: 190,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isUrl ? colors.infoSoft : colors.primarySoft,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    isUrl ? LucideIcons.playSquare : LucideIcons.fileText,
                    size: 13,
                    color: isUrl ? colors.info : colors.primary,
                  ),
                ),
                const Spacer(),
                TlPill(label: source.cefrLevel),
              ],
            ),
            Text(
              source.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.type.bodyStrong.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                Text(
                  isUrl ? 'Video Lesson' : 'Document',
                  style: context.type.caption.copyWith(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
                const Spacer(),
                if (_opening)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: colors.primary,
                    ),
                  )
                else
                  Icon(
                    LucideIcons.arrowRight,
                    size: 12,
                    color: colors.primary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
