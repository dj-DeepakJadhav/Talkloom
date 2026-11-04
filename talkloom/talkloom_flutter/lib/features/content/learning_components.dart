import 'package:flutter/material.dart';

import '../../design/app_icons.dart';
import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import '../practice/exercise_widgets.dart';
import 'source_text.dart';

/// Original wording stays visually separate from the model's explanation.
class SourceQuote extends StatelessWidget {
  const SourceQuote(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: context.colors.success, width: 2)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('From your source', style: context.type.caption),
        const SizedBox(height: 6),
        SelectionArea(
          child: Text(readableSourceText(text), style: context.type.bodyStrong),
        ),
      ],
    ),
  );
}

class VocabularyPresentation extends StatelessWidget {
  const VocabularyPresentation({super.key, required this.word});
  final VocabularyItem word;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text('Vocabulary', style: context.type.caption),
      const SizedBox(height: 24),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(word.display, style: context.type.display)),
          const SizedBox(width: 12),
          SpeakerButton(text: word.display, large: true),
        ],
      ),
      const SizedBox(height: 12),
      Text(readableSourceText(word.meaning), style: context.type.body),
      if (word.sourceContext.isNotEmpty) ...[
        const SizedBox(height: 28),
        SourceQuote(word.sourceContext),
      ],
    ],
  );
}

class GrammarExplanation extends StatelessWidget {
  const GrammarExplanation({
    super.key,
    required this.concept,
    required this.explanation,
    required this.sentence,
  });
  final String concept;
  final String explanation;
  final String sentence;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Icon(AppIcons.spellCheck, size: 24, color: context.colors.success),
      const SizedBox(height: 16),
      Text(concept, style: context.type.headline),
      if (sentence.isNotEmpty) ...[
        const SizedBox(height: 20),
        SourceQuote(sentence),
      ],
      if (explanation.isNotEmpty) ...[
        const SizedBox(height: 16),
        SourceText(explanation),
      ],
    ],
  );
}

class SpeakingPrompt extends StatelessWidget {
  const SpeakingPrompt({
    super.key,
    required this.situation,
    required this.role,
  });
  final String situation;
  final String role;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Your conversation', style: context.type.caption),
      const SizedBox(height: 8),
      Text(situation, style: context.type.title),
      const SizedBox(height: 8),
      Text(
        'Your partner: $role. Start small. Mistakes are welcome.',
        style: context.type.bodySmall,
      ),
    ],
  );
}

/// Describes the check performed; it makes no independent mastery claim.
class EvaluationFeedback extends StatelessWidget {
  const EvaluationFeedback({super.key, required this.checked});
  final bool checked;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          checked ? AppIcons.circleCheck : AppIcons.messagesSquare,
          size: 16,
          color: checked
              ? context.colors.success
              : context.colors.textSecondary,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            checked
                ? 'Checked against your lesson'
                : 'Progress was not checked for this turn',
            style: context.type.caption,
          ),
        ),
      ],
    ),
  );
}
