import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:talkloom_client/talkloom_client.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/app_icons.dart';
import '../../design/components/tl_states.dart';
import '../../design/theme.dart';
import '../../domain/language.dart';
import '../../domain/source_reading.dart';
import 'source_text.dart';

/// The same reader for captions, articles, pasted text, OCR and documents.
class SourceReader extends ConsumerStatefulWidget {
  const SourceReader({super.key, required this.source});
  final Source source;

  @override
  ConsumerState<SourceReader> createState() => _SourceReaderState();
}

class _SourceReaderState extends ConsumerState<SourceReader> {
  static const _modes = {
    'original': 'Original',
    'line': 'Line by line',
    'paragraph': 'Paragraphs',
    'complete': 'Full translation',
  };
  StreamSubscription<SourceReadingBatch>? _subscription;
  final _segments = <int, SourceReadingSegment>{};
  String _mode = 'original';
  Language? _supportOverride;
  String? _error;
  int _generation = 0;
  int _total = 0;
  bool _done = true;

  Language get _language =>
      _supportOverride ?? ref.read(learningSessionProvider).support;

  void _read(String mode) {
    final generation = ++_generation;
    _subscription?.cancel();
    _subscription = null;
    setState(() {
      _mode = mode;
      _segments.clear();
      _error = null;
      _total = 0;
      _done = mode == 'original';
    });
    if (mode == 'original') return;
    final id = widget.source.id;
    if (id == null) {
      setState(() {
        _error = 'Save this source before requesting a translation.';
        _done = true;
      });
      return;
    }
    final language = _language.code;
    _subscription = ref
        .read(lessonRepositoryProvider)
        .readSource(
          sourceId: id,
          supportLanguage: language,
          mode: mode,
        )
        .listen(
          (batch) {
            if (!mounted ||
                generation != _generation ||
                batch.mode != mode ||
                batch.language != language) {
              return;
            }
            setState(() {
              for (final segment in batch.segments) {
                _segments[segment.id] = segment;
              }
              _total = batch.total;
              _done = batch.done;
            });
          },
          onError: (Object error) {
            if (mounted && generation == _generation) {
              setState(() {
                _error = Failure.from(error).message;
                _done = true;
              });
            }
          },
          onDone: () {
            if (!mounted || generation != _generation) return;
            if (!_done) {
              setState(() {
                _error =
                    'Translation stopped before finishing. Retry to continue.';
                _done = true;
              });
            }
          },
        );
  }

  @override
  void didUpdateWidget(SourceReader oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source.id != widget.source.id ||
        oldWidget.source.rawText != widget.source.rawText) {
      _generation++;
      _subscription?.cancel();
      _subscription = null;
      _mode = 'original';
      _segments.clear();
      _error = null;
      _done = true;
    }
  }

  @override
  void dispose() {
    _generation++;
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(learningSessionProvider.select((s) => s.support.code), (
      before,
      after,
    ) {
      if (_supportOverride == null && before != after && _mode != 'original') {
        _read(_mode);
      }
    });
    final support =
        _supportOverride ?? ref.watch(learningSessionProvider).support;
    final original = LanguageCatalog.byCode(widget.source.targetLanguage);
    final sorted = _segments.values.toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final mode in _modes.entries)
              ChoiceChip(
                label: Text(mode.value),
                selected: _mode == mode.key,
                onSelected: (_) {
                  if (_mode != mode.key) _read(mode.key);
                },
              ),
          ],
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: PopupMenuButton<Language>(
            tooltip: 'Choose translation language',
            onSelected: (language) {
              setState(() => _supportOverride = language);
              if (_mode != 'original') _read(_mode);
            },
            itemBuilder: (_) => [
              for (final language in LanguageCatalog.all)
                PopupMenuItem(value: language, child: Text(language.endonym)),
            ],
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(AppIcons.languages, size: 18),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Translate to ${support.endonym}',
                        style: context.type.label,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(AppIcons.chevronDown, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (_mode == 'original')
          Directionality(
            textDirection: original.isRightToLeft
                ? TextDirection.rtl
                : TextDirection.ltr,
            child: SourceText(widget.source.rawText),
          )
        else ...[
          if (_mode == 'complete' && sorted.isNotEmpty)
            Directionality(
              textDirection: support.isRightToLeft
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: SourceText(sorted.map((s) => s.translation).join('\n\n')),
            ),
          if (_mode != 'complete')
            for (final segment in sorted)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_mode != 'complete') ...[
                      Directionality(
                        textDirection: original.isRightToLeft
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: SourceText(segment.original),
                      ),
                      const SizedBox(height: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceSunken,
                        borderRadius: TlRadius.controlRadius,
                      ),
                      child: Directionality(
                        textDirection: support.isRightToLeft
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        child: SourceText(segment.translation),
                      ),
                    ),
                    if (_mode != 'complete')
                      const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Divider(),
                      ),
                  ],
                ),
              ),
          if (!_done)
            Semantics(
              liveRegion: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(
                    _total == 0
                        ? 'Preparing translation…'
                        : '${_segments.length} of $_total sections translated',
                    style: context.type.caption,
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => _read('original'),
                    child: const Text('Stop and show original'),
                  ),
                ],
              ),
            ),
          if (_error != null)
            TlErrorState(message: _error!, onRetry: () => _read(_mode)),
          if (_done && _error == null && sorted.isEmpty)
            const Text('No readable text was found in this source.'),
          if (_done && _error == null && sorted.isNotEmpty)
            Text(
              'AI translation · check the original for nuance.',
              style: context.type.caption,
            ),
        ],
      ],
    );
  }
}
