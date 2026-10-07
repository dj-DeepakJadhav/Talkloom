import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';

/// Mural 1:1 Words View (matching 05-words.png & LibraryViews.swift: WordsView)
///
/// Features:
/// - Eyebrow: "LITTLE BY LITTLE · GERMAN"
/// - Title: "Your words."
/// - Subtitle: "Familiar words, ready for another conversation."
/// - Search: "Find a word"
/// - Sage/Dark Panel: "They'll grow from here." leaf banner when starting
/// - Word List: persisted vocabulary with its meaning and source context.
/// - 1-tap Word detail sheet with context and available pronunciation.
class WordsScreen extends ConsumerStatefulWidget {
  const WordsScreen({super.key});

  @override
  ConsumerState<WordsScreen> createState() => _WordsScreenState();
}

class _WordsScreenState extends ConsumerState<WordsScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showWordDetail(VocabularyItem item) {
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
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 36),
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
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.article.isNotEmpty
                              ? '${item.article} ${item.lemma}'
                              : item.lemma,
                          style: ctx.type.display.copyWith(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (WebVoiceService.instance.canSpeak)
                        TlPressable(
                          onTap: () {
                            final text = item.article.isNotEmpty
                                ? '${item.article} ${item.lemma}'
                                : item.lemma;
                            WebVoiceService.instance.speak(
                              text,
                              langCode: 'de-DE',
                            );
                            HapticFeedback.lightImpact();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                            child: const Icon(
                              LucideIcons.volume2,
                              size: 20,
                              color: TlPalette.brassGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.meaning,
                    style: ctx.type.title.copyWith(
                      fontSize: 18,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Saved from your content',
                    style: ctx.type.caption.copyWith(color: colors.textMuted),
                  ),
                  const SizedBox(height: 20),
                  if (item.sourceContext.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: colors.surfaceRaised,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '“${item.sourceContext}”',
                        style: ctx.type.body.copyWith(
                          fontSize: 15,
                          height: 1.4,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 12),
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
    final savedLessons = ref.watch(lessonsProvider);
    final allWords =
        savedLessons.asData?.value
            .expand((lesson) => LessonContent.fromLesson(lesson).vocabulary)
            .toList() ??
        const <VocabularyItem>[];

    final filtered = allWords.where((w) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return w.lemma.toLowerCase().contains(q) ||
            w.meaning.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 100),
            children: [
              // Search field matching 05-words.png
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 18,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: context.type.body.copyWith(
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Find a word',
                          hintStyle: context.type.body.copyWith(
                            color: colors.textMuted,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Eyebrow and Headline matching 05-words.png
              Text(
                'LITTLE BY LITTLE · GERMAN',
                style: context.type.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: TlPalette.brassGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your words.',
                style: context.type.display.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Familiar words, ready for another conversation.',
                style: context.type.body.copyWith(
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 24),

              // "They'll grow from here" Banner matching 05-words.png
              if (savedLessons.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (savedLessons.hasError)
                Text(
                  'Your words could not be loaded. Pull to refresh or reopen this screen.',
                  style: context.type.body,
                )
              else if (filtered.isEmpty && _searchQuery.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        LucideIcons.leaf,
                        size: 32,
                        color: TlPalette.brassGold,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Your words start here.',
                        style: context.type.title.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a video, link or document to collect words and phrases from your own material.',
                        style: context.type.body.copyWith(
                          color: colors.textSecondary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

              // Words List matching Mural 05-words.png
              if (filtered.isNotEmpty)
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => Divider(
                    color: colors.border.withValues(alpha: 0.5),
                    height: 1,
                  ),
                  itemBuilder: (context, i) {
                    final item = filtered[i];
                    final article = item.article.trim();
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showWordDetail(item),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (article.isNotEmpty) ...[
                                          Text(
                                            '$article ',
                                            style: context.type.title.copyWith(
                                              fontSize: 18,
                                              color: colors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                        Text(
                                          item.lemma,
                                          style: context.type.title.copyWith(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item.meaning,
                                      style: context.type.body.copyWith(
                                        color: colors.textSecondary,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              Icon(
                                LucideIcons.chevronRight,
                                size: 18,
                                color: colors.textMuted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
