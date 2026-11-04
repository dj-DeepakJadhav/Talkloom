import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';

import '../../design/theme.dart';

/// Decodes display escapes without rewriting the saved source or its evidence.
String readableSourceText(String text) {
  // Hide leaked subtitle presentation rules, not the learner's source words.
  text = text.replaceAll(
    RegExp(
      r'<(?:style|script)\b[^>]*>[\s\S]*?</(?:style|script)>',
      caseSensitive: false,
    ),
    '',
  );
  text = text.replaceAll(
    RegExp(
      r'(?:^|\n)(?:STYLE\s*\n)?(?:[^\n]*::cue[^\n]*\{\s*\n)?(?:[ \t]*(?:color|background-color|font-size|line-height|font-family|text-align|text-shadow|opacity)\s*:[^\n]*;[ \t]*\r?\n){2,}[ \t]*\}?[ \t]*',
      caseSensitive: false,
    ),
    '\n',
  );
  const entities = {
    'nbsp': ' ',
    'amp': '&',
    'quot': '"',
    'apos': "'",
    'lt': '<',
    'gt': '>',
    'auml': 'ä',
    'ouml': 'ö',
    'uuml': 'ü',
    'Auml': 'Ä',
    'Ouml': 'Ö',
    'Uuml': 'Ü',
    'szlig': 'ß',
    'ndash': '–',
    'mdash': '—',
    'lsquo': '‘',
    'rsquo': '’',
    'ldquo': '“',
    'rdquo': '”',
    'hellip': '…',
  };
  return text.replaceAllMapped(
    RegExp(r'&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);'),
    (m) {
      final value = m[1]!;
      if (!value.startsWith('#')) return entities[value] ?? m[0]!;
      final hex = value.startsWith('#x');
      final code = int.tryParse(
        value.substring(hex ? 2 : 1),
        radix: hex ? 16 : 10,
      );
      if (code == null ||
          code < 32 ||
          code > 0x10ffff ||
          (code >= 0xd800 && code <= 0xdfff)) {
        return m[0]!;
      }
      return code == 160 ? ' ' : String.fromCharCode(code);
    },
  );
}

/// Selectable source headings and lists, presented separately from exercises.
class SourceText extends StatelessWidget {
  const SourceText(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => SelectionArea(
    child: GptMarkdown(
      readableSourceText(text),
      style: context.type.body.copyWith(color: context.colors.textPrimary),
    ),
  );
}
