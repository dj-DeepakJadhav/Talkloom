import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart';
import '../../app/providers.dart';
import '../../client.dart';
import '../../core/failure.dart';
import '../../domain/lesson_content.dart';
import '../../design/theme.dart';

/// Add the learner's own source. No fabricated examples or sample uploads.
class UniversalIngestSheet extends ConsumerStatefulWidget {
  const UniversalIngestSheet({super.key, this.onSuccess});
  final VoidCallback? onSuccess;
  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    ProviderScope.containerOf(
      context,
    ).read(importControllerProvider.notifier).reset();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => UniversalIngestSheet(onSuccess: onSuccess),
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
  void dispose() {
    _content.dispose();
    _title.dispose();
    super.dispose();
  }

  Future<void> _import() async {
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
            ? 'Paste your German text first.'
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
            title: title.isEmpty ? 'Your German passage' : title,
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
            'The source could not be linked to its practice. Try again.',
      );
      return;
    }
    setState(() => _result = lesson);
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
    final state = ref.watch(importControllerProvider);
    final busy = state.isLoading;
    final stage = ref.watch(importProgressProvider);
    final result =
        _result ?? (state.isLoading || state.hasError ? null : state.value);
    if (result != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.circleCheck),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your content is ready',
                    style: context.type.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(LucideIcons.x),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: [
                ButtonSegment(
                  value: false,
                  label: Text('Words ${result.vocabulary.length}'),
                ),
                ButtonSegment(
                  value: true,
                  label: Text('Grammar ${result.grammar.length}'),
                ),
              ],
              selected: {_grammar},
              onSelectionChanged: (v) => setState(() => _grammar = v.single),
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
              child: const Text('Open my content'),
            ),
          ],
        ),
      );
    }
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Bring your world in.',
                  style: context.type.headline,
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: busy ? null : () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Choose a source. We’ll make it speakable.',
            style: context.type.body,
          ),
          const SizedBox(height: 24),
          if (state.hasError)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Could not finish this import. ${Failure.from(state.error!).message}',
              ),
            ),
          if (busy)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                stage == 'retrieved'
                    ? 'Content retrieved. Preparing your words and grammar…'
                    : stage == 'ready'
                    ? 'Ready. Opening your takeaways…'
                    : stage == 'failed'
                    ? 'Lesson preparation failed.'
                    : 'Checking saved content and reading your source…',
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SegmentedButton<_IngestMode>(
              segments: const [
                ButtonSegment(
                  value: _IngestMode.link,
                  icon: Icon(LucideIcons.link),
                  label: Text('Link'),
                ),
                ButtonSegment(
                  value: _IngestMode.text,
                  icon: Icon(LucideIcons.fileText),
                  label: Text('Text'),
                ),
                ButtonSegment(
                  value: _IngestMode.image,
                  icon: Icon(LucideIcons.image),
                  label: Text('Image'),
                ),
                ButtonSegment(
                  value: _IngestMode.document,
                  icon: Icon(LucideIcons.fileUp),
                  label: Text('File'),
                ),
                ButtonSegment(
                  value: _IngestMode.camera,
                  icon: Icon(LucideIcons.camera),
                  label: Text('Camera'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: busy
                  ? null
                  : (value) => setState(() {
                      _mode = value.first;
                      _content.clear();
                      _mediaBytes = null;
                      _mediaName = null;
                      _validation = null;
                      ref.read(importControllerProvider.notifier).clearError();
                    }),
            ),
          ),
          const SizedBox(height: 20),
          if (_mode == _IngestMode.image || _mode == _IngestMode.camera)
            _MediaPickerCard(
              icon: _mode == _IngestMode.camera
                  ? LucideIcons.camera
                  : LucideIcons.image,
              label: _mediaName ?? 'Choose an image',
              onPressed: busy
                  ? null
                  : () => _chooseImage(camera: _mode == _IngestMode.camera),
            )
          else if (_mode == _IngestMode.document)
            _MediaPickerCard(
              icon: LucideIcons.fileUp,
              label: _mediaName ?? 'Choose a document',
              onPressed: busy ? null : _chooseDocument,
            )
          else
            TextField(
              controller: _content,
              enabled: !busy,
              minLines: _mode == _IngestMode.text ? 4 : 1,
              maxLines: _mode == _IngestMode.text ? 8 : 3,
              keyboardType: _mode == _IngestMode.text
                  ? TextInputType.multiline
                  : TextInputType.url,
              decoration: InputDecoration(
                labelText: _mode == _IngestMode.text
                    ? 'Your German text'
                    : 'Video or web link',
                hintText: _mode == _IngestMode.text
                    ? 'Paste a passage from something you watched or read'
                    : 'https://www.youtube.com/watch?...',
              ),
            ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            enabled: !busy,
            decoration: const InputDecoration(
              labelText: 'A name for this content (optional)',
            ),
          ),
          const SizedBox(height: 16),
          if (_mode == _IngestMode.link)
            Text(
              'YouTube is supported first. Paste a transcript if the link cannot be read.',
              style: context.type.bodySmall,
            ),
          if (_validation != null || state.hasError) ...[
            const SizedBox(height: 16),
            Text(
              _authRequired
                  ? 'Sign in to securely save and process your learning material.'
                  : (_validation ?? Failure.from(state.error!).message),
              style: context.type.bodySmall.copyWith(
                color: context.colors.dangerText,
              ),
            ),
            if (_authRequired)
              TextButton.icon(
                onPressed: () => GoRouter.of(context).push('/sign-in'),
                icon: const Icon(LucideIcons.userRound),
                label: const Text('Sign in or restore your session'),
              ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: busy ? null : _import,
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(LucideIcons.arrowRight),
            label: Text(
              busy
                  ? 'Preparing your conversation…'
                  : 'Make this something to speak about',
            ),
          ),
        ],
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
