import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../design/app_icons.dart';
import '../../app/providers.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';

/// Modal sheet for BYOK (Bring Your Own Key). Meta Model API is the sole
/// AI provider: one key field, no provider picker.
class ApiKeysSheet extends ConsumerStatefulWidget {
  const ApiKeysSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ApiKeysSheet(),
    );
  }

  @override
  ConsumerState<ApiKeysSheet> createState() => _ApiKeysSheetState();
}

class _ApiKeysSheetState extends ConsumerState<ApiKeysSheet> {
  late TextEditingController _metaCtrl;

  bool _obscureMeta = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(byokSettingsProvider);
    _metaCtrl = TextEditingController(text: config.metaKey);
  }

  @override
  void dispose() {
    _metaCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    final notifier = ref.read(byokSettingsProvider.notifier);
    await notifier.setKey(provider: ByokProvider.meta, key: _metaCtrl.text);
    HapticFeedback.lightImpact();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('API keys saved securely on this device.'),
          backgroundColor: context.colors.surfaceRaised,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: TlSpace.maxContentWidth,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(TlRadius.xl),
            ),
            border: Border(
              top: BorderSide(
                color: colors.borderStrong.withValues(alpha: 0.5),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + TlSpace.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top drag pill
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: TlSpace.sm,
                        bottom: TlSpace.md,
                      ),
                      child: Container(
                        height: 4,
                        width: 40,
                        decoration: BoxDecoration(
                          color: colors.borderStrong,
                          borderRadius: TlRadius.pillRadius,
                        ),
                      ),
                    ),
                  ),

                  // Sheet Heading (Mural style)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.gutter,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Advanced · Meta AI',
                                style: context.type.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Meta Model API',
                                style: context.type.titleLarge.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primarySoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'BYOK Mode',
                            style: context.type.caption.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: TlSpace.sm),

                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.gutter,
                    ),
                    child: Text(
                      'Talkloom runs on Meta models (Muse Spark). Supply your personal Meta Model API key. The key remains on this device and is never shared.',
                      style: context.type.caption.copyWith(
                        color: colors.textMuted,
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ),

                  const SizedBox(height: TlSpace.md),

                  // Single Meta key field. No provider picker:
                  // Meta is the only backend.
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.gutter,
                    ),
                    child: _buildKeyField(
                      label: 'Meta Model API Key',
                      placeholder: 'metamodel_...',
                      controller: _metaCtrl,
                      obscure: _obscureMeta,
                      onToggleObscure: () =>
                          setState(() => _obscureMeta = !_obscureMeta),
                      isActive: true,
                      hintUrl: 'meta.ai/developers',
                      colors: colors,
                    ),
                  ),

                  const SizedBox(height: TlSpace.lg),

                  // Save Action Button
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: TlSpace.gutter,
                    ),
                    child: TlPressable(
                      onTap: _saveKeys,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              TlPalette.brassGoldLight,
                              TlPalette.brassGold,
                              TlPalette.brassGoldDeep,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: TlPalette.brassGold.withValues(
                                alpha: 0.35,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'Save & Activate Settings',
                            style: context.type.bodyStrong.copyWith(
                              color: TlPalette.obsidian,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: TlSpace.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyField({
    required String label,
    required String placeholder,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggleObscure,
    required bool isActive,
    required String hintUrl,
    required TlColors colors,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive
              ? colors.primary.withValues(alpha: 0.6)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: context.type.bodyStrong.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  hintUrl,
                  textAlign: TextAlign.end,
                  style: context.type.caption.copyWith(
                    fontSize: 10,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: obscure,
                  style: context.type.body.copyWith(
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  decoration: InputDecoration(
                    hintText: placeholder,
                    hintStyle: context.type.body.copyWith(
                      color: colors.textMuted.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                    isDense: true,
                    constraints: const BoxConstraints(minHeight: 44),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 12,
                    ),
                    filled: true,
                    fillColor: colors.surfaceRaised,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  obscure ? AppIcons.eyeOff : AppIcons.eye,
                  size: 16,
                  color: colors.textMuted,
                ),
                onPressed: onToggleObscure,
                tooltip: obscure ? 'Show key' : 'Hide key',
              ),
            ],
          ),
        ],
      ),
    );
  }
}
