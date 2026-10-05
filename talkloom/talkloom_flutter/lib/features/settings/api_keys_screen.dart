import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';

/// Modal sheet for BYOK (Bring Your Own Key) Multi-Provider Settings
/// Inspired by Mural architecture (https://github.com/Chuloo/mural)
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
  late TextEditingController _geminiCtrl;
  late TextEditingController _nvidiaCtrl;
  late TextEditingController _groqCtrl;

  bool _obscureGemini = true;
  bool _obscureNvidia = true;
  bool _obscureGroq = true;

  @override
  void initState() {
    super.initState();
    final config = ref.read(byokSettingsProvider);
    _geminiCtrl = TextEditingController(text: config.geminiKey);
    _nvidiaCtrl = TextEditingController(text: config.nvidiaKey);
    _groqCtrl = TextEditingController(text: config.groqKey);
  }

  @override
  void dispose() {
    _geminiCtrl.dispose();
    _nvidiaCtrl.dispose();
    _groqCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveKeys() async {
    final notifier = ref.read(byokSettingsProvider.notifier);
    await notifier.setKey(provider: ByokProvider.gemini, key: _geminiCtrl.text);
    await notifier.setKey(provider: ByokProvider.nvidia, key: _nvidiaCtrl.text);
    await notifier.setKey(provider: ByokProvider.groq, key: _groqCtrl.text);
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
    final byok = ref.watch(byokSettingsProvider);

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
              top: BorderSide(color: colors.borderStrong.withValues(alpha: 0.5)),
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
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Advanced · AI Providers',
                          style: context.type.caption.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Bring Your Own Key',
                          style: context.type.titleLarge.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
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
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                child: Text(
                  'Choose your preferred inference backend or supply your personal keys. Keys remain on this device and are never shared.',
                  style: context.type.caption.copyWith(
                    color: colors.textMuted,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ),

              const SizedBox(height: TlSpace.md),

              // Active Provider Selector (Gemini / NVIDIA NIM / Groq)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ACTIVE PROVIDER',
                      style: context.type.caption.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                        color: colors.textMuted,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildProviderOption(
                          provider: ByokProvider.gemini,
                          title: 'Gemini',
                          subtitle: 'Google 3.1 Flash',
                          isSelected: byok.activeProvider == ByokProvider.gemini,
                          colors: colors,
                        ),
                        const SizedBox(width: 8),
                        _buildProviderOption(
                          provider: ByokProvider.nvidia,
                          title: 'NVIDIA',
                          subtitle: 'Nemotron NIM',
                          isSelected: byok.activeProvider == ByokProvider.nvidia,
                          colors: colors,
                        ),
                        const SizedBox(width: 8),
                        _buildProviderOption(
                          provider: ByokProvider.groq,
                          title: 'Groq',
                          subtitle: 'Llama 3.3 70B',
                          isSelected: byok.activeProvider == ByokProvider.groq,
                          colors: colors,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TlSpace.lg),

              // Provider Input Fields
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                child: Column(
                  children: [
                    // Gemini Field
                    _buildKeyField(
                      label: 'Google Gemini API Key',
                      placeholder: 'AIzaSy...',
                      controller: _geminiCtrl,
                      obscure: _obscureGemini,
                      onToggleObscure: () => setState(() => _obscureGemini = !_obscureGemini),
                      isActive: byok.activeProvider == ByokProvider.gemini,
                      hintUrl: 'aistudio.google.com',
                      colors: colors,
                    ),

                    const SizedBox(height: 12),

                    // NVIDIA NIM Field
                    _buildKeyField(
                      label: 'NVIDIA NIM API Key',
                      placeholder: 'nvapi-...',
                      controller: _nvidiaCtrl,
                      obscure: _obscureNvidia,
                      onToggleObscure: () => setState(() => _obscureNvidia = !_obscureNvidia),
                      isActive: byok.activeProvider == ByokProvider.nvidia,
                      hintUrl: 'build.nvidia.com',
                      colors: colors,
                    ),

                    const SizedBox(height: 12),

                    // Groq Field
                    _buildKeyField(
                      label: 'Groq Cloud API Key',
                      placeholder: 'gsk_...',
                      controller: _groqCtrl,
                      obscure: _obscureGroq,
                      onToggleObscure: () => setState(() => _obscureGroq = !_obscureGroq),
                      isActive: byok.activeProvider == ByokProvider.groq,
                      hintUrl: 'console.groq.com',
                      colors: colors,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: TlSpace.lg),

              // Save Action Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
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
                          color: TlPalette.brassGold.withValues(alpha: 0.35),
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

              // Architectural reference notice
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
                  child: Text(
                    'Reference Architecture: github.com/Chuloo/mural',
                    style: context.type.caption.copyWith(
                      color: colors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildProviderOption({
    required ByokProvider provider,
    required String title,
    required String subtitle,
    required bool isSelected,
    required TlColors colors,
  }) {
    return Expanded(
      child: TlPressable(
        onTap: () {
          ref.read(byokSettingsProvider.notifier).setProvider(provider);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? colors.primarySoft : colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? colors.primary : colors.border,
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    title,
                    style: context.type.bodyStrong.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? colors.primary : colors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (isSelected)
                    Icon(
                      LucideIcons.checkCircle2,
                      size: 14,
                      color: colors.primary,
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: context.type.caption.copyWith(
                  fontSize: 10,
                  color: isSelected ? colors.primary : colors.textMuted,
                ),
              ),
            ],
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
          color: isActive ? colors.primary.withValues(alpha: 0.6) : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: context.type.bodyStrong.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                hintUrl,
                style: context.type.caption.copyWith(
                  fontSize: 10,
                  color: colors.textMuted,
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
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
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
                  obscure ? LucideIcons.eyeOff : LucideIcons.eye,
                  size: 16,
                  color: colors.textMuted,
                ),
                onPressed: onToggleObscure,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
