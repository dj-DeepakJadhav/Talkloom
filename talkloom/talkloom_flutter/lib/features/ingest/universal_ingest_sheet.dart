import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../design/app_icons.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import '../../app/providers.dart';
import '../../client.dart';
import '../../core/failure.dart';
import '../../domain/lesson_content.dart';
import '../../domain/language.dart';
import '../../design/theme.dart';
import '../content/source_detail_screen.dart' show importStageMessage;

/// Add the learner's own source. No fabricated examples or sample uploads.
class UniversalIngestSheet extends ConsumerStatefulWidget {
  const UniversalIngestSheet({
    super.key,
    this.onSuccess,
    this.initialLink,
    this.initialText,
    this.autoStart = false,
  });
  final VoidCallback? onSuccess;

  /// Prefill for the share-target flow. A link opens in link mode,
  /// otherwise the text opens in text mode.
  final String? initialLink;
  final String? initialText;
  final bool autoStart;
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onSuccess,
    String? initialLink,
    String? initialText,
    bool autoStart = false,
  }) {
    ProviderScope.containerOf(
      context,
    ).read(importControllerProvider.notifier).reset();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => UniversalIngestSheet(
          onSuccess: onSuccess,
          initialLink: initialLink,
          initialText: initialText,
          autoStart: autoStart,
        ),
      ),
    );
  }

  @override
  ConsumerState<UniversalIngestSheet> createState() =>
      _UniversalIngestSheetState();
}

class _UniversalIngestSheetState extends ConsumerState<UniversalIngestSheet> {
  final _content = TextEditingController();
  final _title = TextEditingController();
  _IngestMode _mode = _IngestMode.link;
  Uint8List? _mediaBytes;
  String? _mediaName;
  String? _validation;
  bool _authRequired = false;
  LessonContent? _result;
  bool _grammar = false;
  @override
  void initState() {
    super.initState();
    final link = widget.initialLink?.trim();
    if (link != null && link.isNotEmpty) {
      _mode = _IngestMode.link;
      _content.text = link;
    } else {
      final text = widget.initialText?.trim();
      if (text != null && text.isNotEmpty) {
        _mode = _IngestMode.text;
        _content.text = text;
      }
    }
    if (widget.autoStart) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _import();
      });
    }
  }

  @override
  void dispose() {
    _content.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _import({bool practiceLater = false}) async {
    if (ref.read(importControllerProvider).isLoading) return;
    if (_mode.isMedia && _mediaBytes == null) {
      setState(() => _validation = 'Choose an image or document first.');
      return;
    }
    final value = _content.text.trim();
    final uri = Uri.tryParse(value);
    if (!_mode.isMedia && value.isEmpty ||
        (_mode == _IngestMode.link &&
            (uri == null ||
                !['http', 'https'].contains(uri.scheme) ||
                uri.host.isEmpty))) {
      setState(
        () => _validation = _mode == _IngestMode.text
            ? 'Paste text to learn from first.'
            : 'Enter a complete video or web link.',
      );
      return;
    }
    if (!client.auth.isAuthenticated) {
      setState(() {
        _authRequired = true;
        _validation =
            'Sign in to securely save and process your learning material.';
      });
      return;
    }
    _authRequired = false;
    setState(() => _validation = null);
    final importer = ref.read(importControllerProvider.notifier);
    final title = _title.text.trim();
    final lesson = _mode == _IngestMode.text
        ? await importer.importText(
            title: title.isEmpty ? 'Your shared text' : title,
            text: value,
          )
        : _mode.isMedia
        ? await importer.importMedia(
            title: title.isEmpty ? (_mediaName ?? 'Your image') : title,
            base64Content: base64Encode(_mediaBytes!),
            type: _mode == _IngestMode.camera ? 'image' : 'document',
          )
        : await importer.importUrl(title: title, url: value);
    if (!mounted || lesson == null) return;
    if (lesson.sourceId == null) {
      setState(
        () => _validation =
            'We could not make practice from this source. Try again.',
      );
      return;
    }
    setState(() => _result = lesson);
    if (practiceLater && mounted) {
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      Navigator.pop(context);
      widget.onSuccess?.call();
    }
  }

  void _explainFailure(Object error) {
    final failure = Failure.from(error);
    // Keep the explanation in one place while the modal is open. Leaving the
    // controller error set also renders the same message in the page behind it.
    ref.read(importControllerProvider.notifier).clearError();
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          AppIcons.sparkles,
          color: context.colors.primary,
          size: 32,
        ),
        title: Text(
          failure.title ?? 'Could not finish this import',
          textAlign: TextAlign.center,
        ),
        content: Text(
          failure.message,
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _setMode(_IngestMode.link);
            },
            child: const Text('Try another link'),
          ),
          if (failure.suggestsPastingText && _mode != _IngestMode.text)
            FilledButton.icon(
              onPressed: () {
                Navigator.pop(dialogContext);
                setState(() {
                  _mode = _IngestMode.text;
                  _content.clear();
                  _validation = null;
                });
                ref.read(importControllerProvider.notifier).reset();
              },
              icon: const Icon(AppIcons.pencil, size: 16),
              label: const Text('Paste text instead'),
            ),
        ],
      ),
    );
  }

  void _setMode(_IngestMode mode) {
    setState(() {
      _mode = mode;
      _validation = null;
      ref.read(importControllerProvider.notifier).clearError();
    });
  }

  Widget _learningOptions(BuildContext context) {
    final session = ref.watch(learningSessionProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: const InputDecoration(
            labelText: 'Learn',
            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<Language>(
              value: session.target,
              isExpanded: true,
              items: LanguageCatalog.all
                  .map(
                    (language) => DropdownMenuItem(
                      value: language,
                      child: Text(
                        language.endonym,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (language) {
                if (language != null) {
                  ref
                      .read(learningSessionProvider.notifier)
                      .save(session.copyWith(target: language));
                }
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Level adapts to your content · Explanations in ${session.support.endonym}',
          style: context.type.caption,
        ),
      ],
    );
  }

  Future<void> _chooseDocument() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'txt', 'md'],
    );
    final file = result.isEmpty ? null : result.single;
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _mode = _IngestMode.document;
      _mediaBytes = bytes;
      _mediaName = file.name;
      _validation = null;
    });
  }

  Future<void> _chooseImage({required bool camera}) async {
    final image = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null) return;
    setState(() {
      _mode = camera ? _IngestMode.camera : _IngestMode.image;
      _mediaBytes = null;
      _mediaName = image.name;
      _validation = null;
    });
    final bytes = await image.readAsBytes();
    if (mounted) setState(() => _mediaBytes = bytes);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(importControllerProvider, (previous, next) {
      if (next.hasError &&
          !(previous?.hasError ?? false) &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        _explainFailure(next.error!);
      }
    });
    final state = ref.watch(importControllerProvider);
    final busy = state.isLoading;
    final stage = ref.watch(importProgressProvider);
    final result =
        _result ?? (state.isLoading || state.hasError ? null : state.value);
    if (result != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ready to learn')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(AppIcons.circleCheck),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your first activity is ready',
                        style: context.type.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: false,
                      label: Text('Vocabulary ${result.vocabulary.length}'),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Grammar ${result.grammar.length}'),
                    ),
                  ],
                  selected: {_grammar},
                  onSelectionChanged: (v) =>
                      setState(() => _grammar = v.single),
                ),
                const SizedBox(height: 12),
                if (_grammar)
                  ...result.grammar.map(
                    (item) => ListTile(
                      title: Text(item.concept),
                      subtitle: Text(item.explanation),
                    ),
                  )
                else
                  ...result.vocabulary.map(
                    (item) => ListTile(
                      title: Text(item.display),
                      subtitle: Text(item.meaning),
                    ),
                  ),
                FilledButton(
                  onPressed: () {
                    final router = GoRouter.of(context);
                    Navigator.pop(context);
                    if (widget.onSuccess != null) {
                      widget.onSuccess!();
                    } else {
                      router.push('/content/${result.sourceId}');
                    }
                  },
                  child: const Text('Start learning'),
                ),
                TextButton(
                  onPressed: () {
                    ref.invalidate(sourcesProvider);
                    ref.invalidate(lessonsProvider);
                    Navigator.pop(context);
                    widget.onSuccess?.call();
                  },
                  child: const Text('Practice later'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (busy) {
      void onLater() {
        Navigator.pop(context);
        widget.onSuccess?.call();
      }

      return Scaffold(
        appBar: AppBar(
          title: const Text('Getting ready'),
          leading: IconButton(
            tooltip: 'Practice later',
            onPressed: onLater,
            icon: const Icon(AppIcons.arrowLeft),
          ),
        ),
        body: _PreparingContent(stage: stage, onLater: onLater),
      );
    }
    int tabIndexForMode(_IngestMode mode) => switch (mode) {
      _IngestMode.link => 0,
      _IngestMode.text => 1,
      _IngestMode.camera => 2,
      _IngestMode.image => 3,
      _IngestMode.document => 3,
    };
    return DefaultTabController(
      length: 4,
      initialIndex: tabIndexForMode(_mode),
      child: Builder(
        builder: (tabContext) {
          final tabController = DefaultTabController.of(tabContext);
          void selectTab(int index) {
            final next = switch (index) {
              0 => _IngestMode.link,
              1 => _IngestMode.text,
              2 => _IngestMode.camera,
              _ => _IngestMode.document,
            };
            if (next != _mode) _setMode(next);
          }

          return Scaffold(
            appBar: AppBar(
              title: const Text('Add content'),
              bottom: TabBar(
                controller: tabController,
                onTap: busy ? null : selectTab,
                tabs: const [
                  Tab(icon: Icon(AppIcons.link, size: 18), text: 'Link'),
                  Tab(icon: Icon(AppIcons.fileText, size: 18), text: 'Text'),
                  Tab(icon: Icon(AppIcons.camera, size: 18), text: 'Scan'),
                  Tab(icon: Icon(AppIcons.fileUp, size: 18), text: 'Upload'),
                ],
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.hasError)
                      Container(
                        margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(Failure.from(state.error!).message),
                      ),
                    SizedBox(
                      // Fixed tab stage so the whole sheet scrolls
                      // (keyboard-safe) instead of flexing to overflow.
                      height: 260,
                      child: TabBarView(
                        controller: tabController,
                        physics: busy
                            ? const NeverScrollableScrollPhysics()
                            : null,
                        children: [
                          // Link
                          _TabScroll(
                            child: TextField(
                              controller: _content,
                              enabled: !busy,
                              keyboardType: TextInputType.url,
                              maxLines: 3,
                              minLines: 1,
                              onChanged: (_) {
                                if (_mode != _IngestMode.link) {
                                  _setMode(_IngestMode.link);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Paste a link',
                                hintText: 'https://www.youtube.com/watch?...',
                              ),
                            ),
                          ),
                          // Text
                          _TabScroll(
                            child: TextField(
                              controller: _content,
                              enabled: !busy,
                              keyboardType: TextInputType.multiline,
                              minLines: 5,
                              maxLines: 10,
                              onChanged: (_) {
                                if (_mode != _IngestMode.text) {
                                  _setMode(_IngestMode.text);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Text to learn from',
                                hintText:
                                    'Paste a passage from something you watched or read',
                              ),
                            ),
                          ),
                          // Scan
                          _TabScroll(
                            child: _MediaPickerCard(
                              icon: AppIcons.camera,
                              label:
                                  _mode == _IngestMode.camera &&
                                      _mediaName != null
                                  ? _mediaName!
                                  : 'Scan with camera',
                              onPressed: busy
                                  ? null
                                  : () {
                                      if (_mode != _IngestMode.camera) {
                                        _setMode(_IngestMode.camera);
                                      }
                                      _chooseImage(camera: true);
                                    },
                            ),
                          ),
                          // Upload
                          _TabScroll(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _MediaPickerCard(
                                  icon: AppIcons.image,
                                  label:
                                      _mediaName != null &&
                                          _mode == _IngestMode.image
                                      ? _mediaName!
                                      : 'Choose from gallery',
                                  onPressed: busy
                                      ? null
                                      : () {
                                          if (_mode != _IngestMode.image) {
                                            _setMode(_IngestMode.image);
                                          }
                                          _chooseImage(camera: false);
                                        },
                                ),
                                const SizedBox(height: 10),
                                _MediaPickerCard(
                                  icon: AppIcons.fileUp,
                                  label:
                                      _mediaName != null &&
                                          _mode == _IngestMode.document
                                      ? _mediaName!
                                      : 'Choose a document',
                                  onPressed: busy
                                      ? null
                                      : () {
                                          if (_mode != _IngestMode.document) {
                                            _setMode(_IngestMode.document);
                                          }
                                          _chooseDocument();
                                        },
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'PDF, doc, txt, markdown, or a photo.',
                                  style: context.type.caption,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: _title,
                            enabled: !busy,
                            decoration: const InputDecoration(
                              labelText: 'Title · optional',
                            ),
                          ),
                          const SizedBox(height: 10),
                          _learningOptions(context),
                          if (_validation != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              _authRequired
                                  ? 'Sign in to securely save and process your learning material.'
                                  : _validation!,
                              style: context.type.bodySmall.copyWith(
                                color: context.colors.dangerText,
                              ),
                            ),
                            if (_authRequired)
                              TextButton.icon(
                                onPressed: () =>
                                    GoRouter.of(context).push('/sign-in'),
                                icon: const Icon(AppIcons.userRound),
                                label: const Text(
                                  'Sign in or restore your session',
                                ),
                              ),
                          ],
                          const SizedBox(height: 10),
                          Text(
                            switch (_mode) {
                              _IngestMode.link =>
                                'Link · YouTube, article, post',
                              _IngestMode.text =>
                                'Text · paste something you read',
                              _IngestMode.camera =>
                                'Scan · photo of words in the wild',
                              _IngestMode.image =>
                                'Upload · photo from your gallery',
                              _IngestMode.document =>
                                'Upload · PDF, doc, txt, markdown',
                            },
                            style: context.type.caption,
                          ),
                          const SizedBox(height: 6),
                          FilledButton.icon(
                            onPressed: busy ? null : () => _import(),
                            icon: busy
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(AppIcons.arrowRight),
                            label: Text(busy ? 'Preparing…' : 'Learn now'),
                          ),
                          TextButton(
                            onPressed: busy
                                ? null
                                : () => _import(practiceLater: true),
                            child: const Text('Practice later'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

enum _IngestMode { link, text, image, document, camera }

extension on _IngestMode {
  bool get isMedia =>
      this == _IngestMode.image ||
      this == _IngestMode.document ||
      this == _IngestMode.camera;
}

class _MediaPickerCard extends StatelessWidget {
  const _MediaPickerCard({
    required this.icon,
    required this.label,
    required this.onPressed,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon),
    label: Text(label),
    style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(18)),
  );
}

class _TabScroll extends StatelessWidget {
  const _TabScroll({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
    child: child,
  );
}

class _PreparingContent extends StatelessWidget {
  const _PreparingContent({required this.stage, required this.onLater});
  final String stage;
  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    final readingDone = const {
      'retrieved',
      'compiling',
      'validating',
      'saved',
      'ready',
    }.contains(stage);
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 44,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 26),
                    Text(
                      'First activity coming up',
                      textAlign: TextAlign.center,
                      style: context.type.body,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      height: 172,
                      decoration: BoxDecoration(
                        color: context.colors.surfaceSunken,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _PreparationArtworkTile(
                            icon: AppIcons.fileText,
                            color: context.colors.surfaceRaised,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              AppIcons.arrowRight,
                              color: context.colors.primary,
                            ),
                          ),
                          _PreparationArtworkTile(
                            icon: AppIcons.sparkles,
                            color: context.colors.surfaceRaised,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Icon(
                              AppIcons.arrowRight,
                              color: context.colors.primary,
                            ),
                          ),
                          _PreparationArtworkTile(
                            icon: AppIcons.bookOpenText,
                            color: context.colors.surfaceRaised,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        importStageMessage(stage),
                        textAlign: TextAlign.center,
                        style: context.type.bodySmall,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _PreparationStep(
                      label: 'Reading source',
                      done: readingDone,
                      active: !readingDone && stage != 'queued',
                    ),
                    const SizedBox(height: 12),
                    _PreparationStep(
                      label: 'Building first activity',
                      done: false,
                      active: readingDone,
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: onLater,
                  child: const Text('Practice later'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PreparationArtworkTile extends StatelessWidget {
  const _PreparationArtworkTile({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox.square(
      dimension: 56,
      child: Center(
        child: Icon(icon, size: 28, color: context.colors.textPrimary),
      ),
    ),
  );
}

class _PreparationStep extends StatelessWidget {
  const _PreparationStep({
    required this.label,
    required this.done,
    required this.active,
  });
  final String label;
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(
        width: 24,
        height: 24,
        child: done
            ? Icon(AppIcons.circleCheck, color: context.colors.primary)
            : active
            ? const CircularProgressIndicator(strokeWidth: 2)
            : DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.borderStrong,
                    width: 2,
                  ),
                ),
              ),
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: context.type.bodyStrong)),
    ],
  );
}
