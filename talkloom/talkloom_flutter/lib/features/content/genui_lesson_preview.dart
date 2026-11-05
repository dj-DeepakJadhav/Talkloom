import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:genui/genui.dart';
import 'package:json_schema_builder/json_schema_builder.dart';

import '../../design/theme.dart';
import '../../domain/lesson_content.dart';
import 'learning_components.dart';

/// Only references to the current server-loaded lesson may enter this catalog.
/// Model-provided text, arbitrary widgets and progress writes are not accepted.
bool validLessonComponent(Map<String, Object?> data, LessonContent lesson) {
  if (data['component'] != 'LessonItem' || data['index'] is! int) return false;
  final index = data['index']! as int;
  final length = switch (data['kind']) {
    'word' => lesson.vocabulary.length,
    'grammar' => lesson.grammar.length,
    _ => 0,
  };
  return index >= 0 &&
      index < length &&
      data.keys.every(const {'id', 'component', 'kind', 'index'}.contains);
}

/// A small A2UI compatibility prototype over an existing Serverpod lesson.
/// The model generated the saved lesson; selection here is learner-controlled.
/// A live model-driven layout transport is deliberately not implied.
class GenUiLessonPreview extends StatefulWidget {
  const GenUiLessonPreview({super.key, required this.lesson});
  final LessonContent lesson;

  @override
  State<GenUiLessonPreview> createState() => _GenUiLessonPreviewState();
}

class _GenUiLessonPreviewState extends State<GenUiLessonPreview> {
  static const _surfaceId = 'lesson-preview';
  static const _catalogId = 'talkloom-lesson-v1';
  late final SurfaceController _controller;
  late final A2uiTransportAdapter _transport;
  late final StreamSubscription<dynamic> _messages;
  String _kind = 'word';
  int _index = 0;
  bool _failed = false;

  int get _count => _kind == 'word'
      ? widget.lesson.vocabulary.length
      : widget.lesson.grammar.length;

  @override
  void initState() {
    super.initState();
    _controller = SurfaceController(
      catalogs: [
        Catalog([
          CatalogItem(
            name: 'LessonItem',
            dataSchema: S.object(
              properties: {
                'kind': S.string(enumValues: ['word', 'grammar']),
                'index': S.integer(),
              },
              required: ['kind', 'index'],
            ),
            widgetBuilder: (item) {
              final data = <String, Object?>{
                'id': item.id,
                'component': item.type,
                ...Map<String, Object?>.from(item.data as Map),
              };
              if (!validLessonComponent(data, widget.lesson)) {
                return const Text(
                  'This preview is unavailable. Use Vocabulary or Grammar instead.',
                );
              }
              final index = data['index']! as int;
              if (data['kind'] == 'word') {
                return VocabularyPresentation(
                  word: widget.lesson.vocabulary[index],
                );
              }
              final rule = widget.lesson.grammar[index];
              return GrammarExplanation(
                concept: rule.display,
                explanation: rule.explanation,
                sentence: rule.sourceSentence,
              );
            },
          ),
        ], catalogId: _catalogId),
      ],
    );
    _transport = A2uiTransportAdapter();
    _messages = _transport.incomingMessages.listen(
      _controller.handleMessage,
      onError: (Object error) {
        if (mounted) setState(() => _failed = true);
      },
    );
    if (widget.lesson.vocabulary.isEmpty) _kind = 'grammar';
    _transport.addChunk(
      '${jsonEncode({
        'version': 'v0.9',
        'createSurface': {'surfaceId': _surfaceId, 'catalogId': _catalogId},
      })}\n',
    );
    _show();
  }

  void _show() {
    if (_count == 0) return;
    final component = <String, Object?>{
      'id': 'root',
      'component': 'LessonItem',
      'kind': _kind,
      'index': _index,
    };
    if (!validLessonComponent(component, widget.lesson)) return;
    _transport.addChunk(
      '${jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': _surfaceId,
          'components': [component],
        },
      })}\n',
    );
  }

  void _select(String kind) {
    setState(() {
      _kind = kind;
      _index = 0;
    });
    _show();
  }

  @override
  void dispose() {
    _messages.cancel();
    _transport.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Explore this lesson', style: context.type.headline),
          const SizedBox(height: 8),
          Text(
            'Preview from your saved lesson. No new AI request or progress changes.',
            style: context.type.bodySmall,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              if (widget.lesson.vocabulary.isNotEmpty)
                ChoiceChip(
                  label: const Text('Vocabulary'),
                  selected: _kind == 'word',
                  onSelected: (_) => _select('word'),
                ),
              if (widget.lesson.grammar.isNotEmpty)
                ChoiceChip(
                  label: const Text('Grammar'),
                  selected: _kind == 'grammar',
                  onSelected: (_) => _select('grammar'),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (_failed || _count == 0)
            const Text(
              'This preview is unavailable. Use Vocabulary or Grammar on the lesson page instead.',
            )
          else
            Surface(surfaceContext: _controller.contextFor(_surfaceId)),
          const SizedBox(height: 24),
          if (_count > 0)
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_index + 1} / $_count',
                    style: context.type.caption,
                  ),
                ),
                TextButton(
                  onPressed: _index + 1 < _count
                      ? () {
                          setState(() => _index++);
                          _show();
                        }
                      : null,
                  child: const Text('Next'),
                ),
              ],
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to lesson'),
          ),
        ],
      ),
    ),
  );
}
