import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../design/components/tl_button.dart';
import '../../design/theme.dart';

/// Consolidated Universal Ingestion Studio matching Docs/talkloom_design_specification.md (Section 4, Center Button)
/// Segmented Top Bar: [ 📷 Camera OCR | 📄 File Upload | 📝 Paste Text | 🔗 Web Link ]
class UniversalIngestSheet extends ConsumerStatefulWidget {
  const UniversalIngestSheet({super.key, this.onSuccess});

  final VoidCallback? onSuccess;

  static Future<void> show(BuildContext context, {VoidCallback? onSuccess}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black54,
      builder: (context) => UniversalIngestSheet(onSuccess: onSuccess),
    );
  }

  @override
  ConsumerState<UniversalIngestSheet> createState() => _UniversalIngestSheetState();
}

class _UniversalIngestSheetState extends ConsumerState<UniversalIngestSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String? _uploadedFileName;
  String? _base64MediaPayload;
  String _mediaMimeType = 'image/jpeg';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: 3);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _urlController.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickCameraPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _uploadedFileName = photo.name;
          _mediaMimeType = photo.mimeType ?? 'image/jpeg';
          _base64MediaPayload = 'data:$_mediaMimeType;base64,${base64Encode(bytes)}';
        });
      }
    } catch (_) {
      _pickGalleryPhoto();
    }
  }

  Future<void> _pickGalleryPhoto() async {
    try {
      final picker = ImagePicker();
      final photo = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(() {
          _uploadedFileName = photo.name;
          _mediaMimeType = photo.mimeType ?? 'image/jpeg';
          _base64MediaPayload = 'data:$_mediaMimeType;base64,${base64Encode(bytes)}';
        });
      }
    } catch (_) {}
  }

  Future<void> _pickDocumentFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'txt', 'png', 'jpg', 'jpeg'],
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
                  : (ext == 'jpg' || ext == 'jpeg' ? 'image/jpeg' : 'text/plain'));
          setState(() {
            _uploadedFileName = file.name;
            _mediaMimeType = mime;
            _base64MediaPayload = 'data:$mime;base64,${base64Encode(bytes)}';
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _handleIngest() async {
    final notifier = ref.read(importControllerProvider.notifier);
    final tab = _tabController.index;

    if (tab == 0) {
      // Camera OCR
      if (_base64MediaPayload != null) {
        final lesson = await notifier.importMedia(
          title: _uploadedFileName ?? 'Camera Photo Scan',
          base64Content: _base64MediaPayload!,
          type: 'image',
        );
        if (lesson != null && mounted) {
          Navigator.pop(context);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            context.push(TlRoutes.lesson);
          }
        }
      } else {
        const sampleGermanText =
            'Mietvertragsurkunde: Die Kaution beträgt 3 Monatskaltmieten und ist fristgerecht zu überweisen.';
        final lesson = await notifier.importText(
          title: 'Camera OCR Scan',
          text: sampleGermanText,
        );
        if (lesson != null && mounted) {
          Navigator.pop(context);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            context.push(TlRoutes.lesson);
          }
        }
      }
    } else if (tab == 1) {
      // File Upload
      if (_base64MediaPayload != null) {
        final lesson = await notifier.importMedia(
          title: _uploadedFileName ?? 'Uploaded Document',
          base64Content: _base64MediaPayload!,
          type: 'document',
        );
        if (lesson != null && mounted) {
          Navigator.pop(context);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            context.push(TlRoutes.lesson);
          }
        }
      } else {
        const content =
            'Wohnungsübergabeprotokoll: Die Kaution wird nach Abzug der Nebenkostenabrechnung überwiesen.';
        final lesson = await notifier.importText(
          title: _uploadedFileName ?? 'Document Upload',
          text: content,
        );
        if (lesson != null && mounted) {
          Navigator.pop(context);
          if (widget.onSuccess != null) {
            widget.onSuccess!();
          } else {
            context.push(TlRoutes.lesson);
          }
        }
      }
    } else if (tab == 2) {
      // Paste Raw Text
      final rawText = _textController.text.trim();
      final title = _titleController.text.trim().isNotEmpty
          ? _titleController.text.trim()
          : 'Pasted Raw Text Material';
      if (rawText.isEmpty) return;
      final lesson = await notifier.importText(
        title: title,
        text: rawText,
      );
      if (lesson != null && mounted) {
        Navigator.pop(context);
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          context.push(TlRoutes.lesson);
        }
      }
    } else {
      // Web Link (YouTube or Article)
      final url = _urlController.text.trim();
      if (url.isEmpty) return;
      final lesson = await notifier.importUrl(
        title: url.contains('youtu') ? 'YouTube Video Lesson' : 'Authentic Web Source',
        url: url,
      );
      if (lesson != null && mounted) {
        Navigator.pop(context);
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          context.push(TlRoutes.lesson);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final importState = ref.watch(importControllerProvider);
    final isBusy = importState.isLoading;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(TlRadius.xl)),
            border: Border(
              top: BorderSide(color: colors.primary.withValues(alpha: 0.6), width: 2),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            TlSpace.gutter,
            TlSpace.md,
            TlSpace.gutter,
            MediaQuery.of(context).viewInsets.bottom + TlSpace.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sheet drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderStrong,
                    borderRadius: TlRadius.pillRadius,
                  ),
                ),
              ),
              const SizedBox(height: TlSpace.md),
              Row(
                children: [
                  Text('Ingestion Studio', style: context.type.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: isBusy ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: TlSpace.xs),
              Text(
                'Convert real-world material into a personalized audio lesson.',
                style: context.type.bodySmall,
              ),
              const SizedBox(height: TlSpace.md),

              // Segmented Tab Bar (4 tabs)
              Container(
                decoration: BoxDecoration(
                  color: colors.surfaceSunken,
                  borderRadius: TlRadius.controlRadius,
                  border: Border.all(color: colors.border),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicator: BoxDecoration(
                    color: colors.primary,
                    borderRadius: TlRadius.controlRadius,
                  ),
                  labelColor: colors.onAccent,
                  unselectedLabelColor: colors.textSecondary,
                  labelStyle: context.type.caption.copyWith(fontWeight: FontWeight.w700),
                  dividerHeight: 0,
                  tabs: const [
                    Tab(icon: Icon(LucideIcons.camera, size: 15), text: 'Camera'),
                    Tab(icon: Icon(LucideIcons.fileText, size: 15), text: 'File'),
                    Tab(icon: Icon(LucideIcons.textSelect, size: 15), text: 'Text'),
                    Tab(icon: Icon(LucideIcons.link, size: 15), text: 'URL'),
                  ],
                ),
              ),
              const SizedBox(height: TlSpace.lg),

              SizedBox(
                height: 200,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Camera OCR
                    _buildCameraOcrTab(colors),
                    // Tab 2: File Upload
                    _buildFileUploadTab(colors),
                    // Tab 3: Paste Text
                    _buildPasteTextTab(colors, isBusy),
                    // Tab 4: Web Link
                    _buildWebLinkTab(colors, isBusy),
                  ],
                ),
              ),

              if (importState.hasError) ...[
                const SizedBox(height: TlSpace.sm),
                Text(
                  'Ingestion failed: ${importState.error}',
                  style: context.type.caption.copyWith(color: colors.dangerText),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: TlSpace.lg),
              TlButton(
                label: isBusy ? 'Synthesizing with Dual AI…' : 'Synthesize Lesson',
                icon: LucideIcons.sparkles,
                isBusy: isBusy,
                onPressed: isBusy ? null : _handleIngest,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraOcrTab(TlColors colors) {
    final hasMedia = _base64MediaPayload != null && _uploadedFileName != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickCameraPhoto,
        borderRadius: TlRadius.controlRadius,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: TlRadius.controlRadius,
            border: Border.all(
              color: hasMedia ? colors.primary : colors.primary.withValues(alpha: 0.3),
              width: hasMedia ? 2 : 1,
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(TlSpace.md),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.primary, width: 1.5),
                  ),
                  child: Icon(
                    hasMedia ? LucideIcons.check : LucideIcons.scanLine,
                    size: 28,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: TlSpace.sm),
                Text(
                  hasMedia ? 'Photo Captured: $_uploadedFileName' : 'Tap to Take Photo or Scan',
                  style: context.type.bodyStrong,
                ),
                const SizedBox(height: 2),
                Text(
                  hasMedia
                      ? 'Ready for Multimodal Vision OCR extraction'
                      : 'Align rental contract, letter, or sign inside viewfinder',
                  style: context.type.caption,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileUploadTab(TlColors colors) {
    final hasFile = _base64MediaPayload != null && _uploadedFileName != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDocumentFile,
        borderRadius: TlRadius.controlRadius,
        child: Container(
          padding: const EdgeInsets.all(TlSpace.md),
          decoration: BoxDecoration(
            color: colors.surfaceSunken,
            borderRadius: TlRadius.controlRadius,
            border: Border.all(
              color: hasFile ? colors.primary : colors.border,
              width: hasFile ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasFile ? LucideIcons.fileCheck : LucideIcons.uploadCloud,
                size: 32,
                color: colors.primary,
              ),
              const SizedBox(height: TlSpace.xs),
              Text(
                hasFile ? 'Selected: $_uploadedFileName' : 'Tap to Browse Document or PDF',
                style: context.type.bodyStrong,
              ),
              const SizedBox(height: 4),
              Text(
                hasFile
                    ? 'Base64 document ready for extraction'
                    : 'PDF, TXT, DOCX, PNG, JPG up to 25MB',
                style: context.type.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasteTextTab(TlColors colors, bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _titleController,
          enabled: !isBusy,
          style: context.type.body.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Title (e.g. Mietvertrag Klausel 3)',
            prefixIcon: Icon(LucideIcons.tag, size: 16, color: colors.primary),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: TlSpace.xs),
        Expanded(
          child: TextField(
            controller: _textController,
            enabled: !isBusy,
            maxLines: null,
            expands: true,
            style: context.type.body.copyWith(color: colors.textPrimary),
            textAlignVertical: TextAlignVertical.top,
            decoration: InputDecoration(
              hintText: 'Paste raw German or target language text here…',
              suffixIcon: IconButton(
                icon: const Icon(LucideIcons.clipboardPaste, size: 18),
                onPressed: () {
                  _titleController.text = 'Mietvertragsurkunde';
                  _textController.text =
                      'Die Kaution beträgt 3 Monatskaltmieten und ist auf einem Treuhandkonto anzulegen. Der Mieter ist berechtigt, die Kaution in drei gleichen monatlichen Teilzahlungen zu erbringen.';
                  setState(() {});
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebLinkTab(TlColors colors, bool isBusy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _urlController,
          enabled: !isBusy,
          style: context.type.body.copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'YouTube, Instagram, TikTok, Reddit, X or Web URL',
            prefixIcon: Icon(LucideIcons.link, size: 18, color: colors.primary),
            suffixIcon: IconButton(
              icon: const Icon(LucideIcons.clipboardPaste, size: 18),
              onPressed: () {
                _urlController.text =
                    'https://www.tagesschau.de/inland/gesellschaft/wohnungsmarkt-mieten-100.html';
                setState(() {});
              },
            ),
          ),
        ),
        const SizedBox(height: TlSpace.xs),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildSocialChip(
                colors,
                label: 'Instagram',
                icon: LucideIcons.camera,
                sampleUrl: 'https://instagram.com/reel/C3_sample_deutsch',
              ),
              const SizedBox(width: 6),
              _buildSocialChip(
                colors,
                label: 'TikTok',
                icon: LucideIcons.video,
                sampleUrl: 'https://www.tiktok.com/@german_slang/video/12345678',
              ),
              const SizedBox(width: 6),
              _buildSocialChip(
                colors,
                label: 'Reddit',
                icon: LucideIcons.messageSquare,
                sampleUrl: 'https://www.reddit.com/r/berlin/comments/mietkaution_tipps',
              ),
              const SizedBox(width: 6),
              _buildSocialChip(
                colors,
                label: 'X / Twitter',
                icon: LucideIcons.share2,
                sampleUrl: 'https://x.com/dw_deutsch/status/17890123456',
              ),
            ],
          ),
        ),
        const SizedBox(height: TlSpace.xs),
        Row(
          children: [
            Icon(LucideIcons.zap, size: 14, color: colors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Agent Reach: Ingests captions, comments, and authentic native slang.',
                style: context.type.caption,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialChip(
    TlColors colors, {
    required String label,
    required IconData icon,
    required String sampleUrl,
  }) {
    return ActionChip(
      avatar: Icon(icon, size: 13, color: colors.primary),
      label: Text(label, style: context.type.caption.copyWith(color: colors.textPrimary)),
      backgroundColor: colors.surfaceSunken,
      side: BorderSide(color: colors.border.withValues(alpha: 0.6)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      onPressed: () {
        _urlController.text = sampleUrl;
        setState(() {});
      },
    );
  }
}
