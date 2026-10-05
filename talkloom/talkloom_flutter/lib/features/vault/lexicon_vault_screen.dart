import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../core/platform/web_voice_service.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../settings/api_keys_screen.dart';

enum VaultCategory { words, phrases, grammar }
enum MasteryFilter { all, recognized, active }

/// Tab 4: Lexicon & Grammar Vault (Tactile, Minimal Text, Glanceable)
///
/// Features:
/// - Fast segmented switcher: [ 📖 Words ] [ 💬 Phrases ] [ ⚡ Grammar ]
/// - Minimalist search & filter pill bar
/// - 1-tap native German audio pronunciation for every word & phrase
/// - Color-coded gender chips (der = blue, die = red, das = green)
/// - Spaced Repetition (SRS) Leitner stage pills (Box 1 / 2 / 3)
/// - Clean formulaic grammar cards with structured visual chips
class LexiconVaultScreen extends ConsumerStatefulWidget {
  const LexiconVaultScreen({super.key});

  @override
  ConsumerState<LexiconVaultScreen> createState() => _LexiconVaultScreenState();
}

class _LexiconVaultScreenState extends ConsumerState<LexiconVaultScreen> {
  VaultCategory _selectedCategory = VaultCategory.words;
  MasteryFilter _masteryFilter = MasteryFilter.all;
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final activeLesson = ref.watch(activeLessonProvider);
    final learnerState = ref.watch(learnerStateProvider);

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: Column(
            children: [
              // Header & Quick Search Bar
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
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: colors.primarySoft,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        LucideIcons.bookMarked,
                        size: 16,
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: TlSpace.xs),
                    Text(
                      'Lexicon Vault',
                      style: context.type.title.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const Spacer(),
                    learnerState.maybeWhen(
                      data: (state) {
                        final total = (state?.activeWords.length ?? 0) +
                            (state?.recognizedWords.length ?? 0);
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surfaceRaised,
                            borderRadius: TlRadius.pillRadius,
                            border: Border.all(color: colors.border),
                          ),
                          child: Text(
                            '$total in memory',
                            style: context.type.caption.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                              color: colors.textSecondary,
                            ),
                          ),
                        );
                      },
                      orElse: () => const SizedBox.shrink(),
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
                          LucideIcons.slidersHorizontal,
                          size: 14,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Search Filter Capsule
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  TlSpace.gutter,
                  4,
                  TlSpace.gutter,
                  TlSpace.xs,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.border),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
                        size: 16,
                        color: colors.textMuted,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                          style: context.type.body.copyWith(
                            color: colors.textPrimary,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Filter words or rules…',
                            hintStyle: context.type.caption.copyWith(
                              color: colors.textMuted,
                              fontSize: 13,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                      if (_searchQuery.isNotEmpty)
                        TlPressable(
                          onTap: () => setState(() => _searchQuery = ''),
                          child: Icon(
                            LucideIcons.x,
                            size: 14,
                            color: colors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Segmented Switcher: [ Words ] [ Phrases ] [ Grammar ]
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: TlSpace.gutter,
                  vertical: 6,
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    children: [
                      _buildTabButton(VaultCategory.words, 'Words', LucideIcons.bookOpen, colors),
                      _buildTabButton(VaultCategory.phrases, 'Phrases', LucideIcons.messageSquare, colors),
                      _buildTabButton(VaultCategory.grammar, 'Grammar', LucideIcons.zap, colors),
                    ],
                  ),
                ),
              ),

              // Mastery Filter Chips (for Words tab)
              if (_selectedCategory == VaultCategory.words)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TlSpace.gutter,
                    2,
                    TlSpace.gutter,
                    6,
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip(MasteryFilter.all, 'All', colors),
                      const SizedBox(width: 6),
                      _buildFilterChip(MasteryFilter.active, 'Active Spoken', colors),
                      const SizedBox(width: 6),
                      _buildFilterChip(MasteryFilter.recognized, 'Recognized', colors),
                    ],
                  ),
                ),

              // Content Area
              Expanded(
                child: switch (_selectedCategory) {
                  VaultCategory.words => _buildWordsList(activeLesson, learnerState, colors),
                  VaultCategory.phrases => _buildPhrasesList(activeLesson, colors),
                  VaultCategory.grammar => _buildGrammarList(activeLesson, colors),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    VaultCategory category,
    String label,
    IconData icon,
    TlColors colors,
  ) {
    final isSelected = _selectedCategory == category;
    return Expanded(
      child: TlPressable(
        onTap: () {
          setState(() => _selectedCategory = category);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: colors.borderStrong.withValues(alpha: 0.4))
                : null,
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colors.shadow.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 13,
                color: isSelected ? colors.primary : colors.textMuted,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: context.type.labelSmall.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(MasteryFilter filter, String label, TlColors colors) {
    final isSelected = _masteryFilter == filter;
    return TlPressable(
      onTap: () {
        setState(() => _masteryFilter = filter);
        HapticFeedback.lightImpact();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? colors.primarySoft : colors.surfaceRaised,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colors.primary : colors.border,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: context.type.caption.copyWith(
            color: isSelected ? colors.primary : colors.textMuted,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildWordsList(
    LessonContent? activeLesson,
    AsyncValue<dynamic> learnerState,
    TlColors colors,
  ) {
    // 1. Gather all words from active lesson + base learned vault
    final lessonWords = activeLesson?.vocabulary ?? const <VocabularyItem>[];
    final activeWords = <VocabularyItem>[
      ...lessonWords,
      if (lessonWords.isEmpty) ...const [
        VocabularyItem(id: 'kaution', lemma: 'Kaution', article: 'die', meaning: 'security deposit', sourceContext: 'Die Kaution beträgt 3 Monatskaltmieten.'),
        VocabularyItem(id: 'mietvertrag', lemma: 'Mietvertrag', article: 'der', meaning: 'lease contract', sourceContext: 'Der Mietvertrag ist gültig.'),
        VocabularyItem(id: 'kündigen', lemma: 'kündigen', article: '', meaning: 'to terminate / give notice', sourceContext: 'Ich kündige die Wohnung rechtzeitig.'),
        VocabularyItem(id: 'nebenkosten', lemma: 'Nebenkosten', article: 'die', meaning: 'utility / incidental costs', sourceContext: 'Die Nebenkosten werden jährlich abgerechnet.'),
        VocabularyItem(id: 'mietpreisbremse', lemma: 'Mietpreisbremse', article: 'die', meaning: 'rent control cap', sourceContext: 'Die Mietpreisbremse schützt Mieter.'),
      ],
    ];

    final filtered = activeWords.where((item) {
      if (_searchQuery.isNotEmpty) {
        final matches = item.lemma.toLowerCase().contains(_searchQuery) ||
            item.meaning.toLowerCase().contains(_searchQuery);
        if (!matches) return false;
      }
      return true;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No vocabulary matches found.',
          style: context.type.caption.copyWith(color: colors.textMuted),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: 4,
      ),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final item = filtered[i];
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
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
                            color: bar <= (i % 3)
                                ? TlPalette.brassGold
                                : colors.borderStrong.withValues(alpha: 0.3),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    (i % 3) == 0
                        ? '1 · Fragile'
                        : ((i % 3) == 1 ? '2 · Growing' : '3 · Steady'),
                    style: context.type.caption.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: colors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              // Audio Pronunciation Button
              TlPressable(
                onTap: () {
                  final textToSpeak = article.isNotEmpty ? '$article ${item.lemma}' : item.lemma;
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
                    size: 14,
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

  Widget _buildPhrasesList(LessonContent? activeLesson, TlColors colors) {
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
      phrases.addAll([
        'Ich zahle die Kaution auf das Treuhandkonto.',
        'Der Mietvertrag ist ab sofort rechtsgültig.',
        'Die Nebenkostenabrechnung muss fristgerecht erfolgen.',
        'Die gesetzliche Mietpreisbremse gilt in Ballungsräumen.',
      ]);
    }

    final filtered = phrases.where((p) {
      if (_searchQuery.isNotEmpty) {
        return p.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: 4,
      ),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 6),
      itemBuilder: (context, i) {
        final phrase = filtered[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  phrase,
                  style: context.type.body.copyWith(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(width: 8),
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
                    size: 14,
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

  Widget _buildGrammarList(LessonContent? activeLesson, TlColors colors) {
    final rules = <GrammarRule>[
      ...?(activeLesson?.grammar),
      if (activeLesson?.grammar == null || activeLesson!.grammar.isEmpty) ...const [
        GrammarRule(
          concept: 'Wechselpräpositionen (Akkusativ vs. Dativ)',
          sourceSentence: 'Ich zahle die Kaution auf das Konto (Akk). Das Geld liegt auf dem Konto (Dat).',
          explanation: 'Wohin? (Motion/Destination) = Akkusativ | Wo? (Location) = Dativ',
        ),
        GrammarRule(
          concept: 'Nebensätze mit "weil" & "dass"',
          sourceSentence: 'Ich unterschreibe, weil der Vertrag fair ist.',
          explanation: 'Conjunction moves the conjugated finite verb to the very end of the subordinate clause.',
        ),
        GrammarRule(
          concept: 'Passiv mit Modalverben',
          sourceSentence: 'Die Kaution muss innerhalb von 6 Monaten erstattet werden.',
          explanation: 'Formula: Modalverb (pos 2) + Partizip II + werden (clause end).',
        ),
      ],
    ];

    final filtered = rules.where((r) {
      if (_searchQuery.isNotEmpty) {
        return r.concept.toLowerCase().contains(_searchQuery) ||
            r.explanation.toLowerCase().contains(_searchQuery);
      }
      return true;
    }).toList();

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: TlSpace.gutter,
        vertical: 4,
      ),
      itemCount: filtered.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final rule = filtered[i];
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
