import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../design/components/tl_button.dart';
import '../../design/components/tl_states.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../../domain/language.dart';
import '../../domain/learning_session.dart';
import '../../widgets/talkloom_logo.dart';

/// First run: choose what you are learning, in what language, at what level.
///
/// This is the screen that makes Talkloom a language app rather than a German
/// app — nothing downstream assumes a language any more.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _step = 0;
  Language? _target;
  Language _support = LanguageCatalog.byCode('en');
  CefrLevel _level = CefrLevel.a2;

  bool get _canContinue => switch (_step) {
    0 => _target != null,
    1 => _target?.code != _support.code,
    _ => true,
  };

  Future<void> _skipAsGuest() async {
    await ref
        .read(learningSessionProvider.notifier)
        .save(
          LearningSession(
            target: _target ?? LanguageCatalog.byCode('de'),
            support: _support,
            level: _level,
          ),
        );
    if (mounted) context.go(TlRoutes.home);
  }

  Future<void> _advance() async {
    if (_step < 2) {
      setState(() => _step++);
      return;
    }
    await ref
        .read(learningSessionProvider.notifier)
        .save(
          LearningSession(target: _target!, support: _support, level: _level),
        );
    if (mounted) context.go(TlRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: TlSpace.maxContentWidth,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    TlSpace.gutter,
                    TlSpace.lg,
                    TlSpace.gutter,
                    TlSpace.md,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (_step > 0)
                            TlPressable(
                              onTap: () => setState(() => _step--),
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  right: TlSpace.sm,
                                ),
                                child: Icon(
                                  LucideIcons.arrowLeft,
                                  size: 22,
                                  color: colors.textSecondary,
                                ),
                              ),
                            )
                          else
                            const TalkloomLogo(size: 34),
                          const Spacer(),
                          _StepDots(step: _step, total: 3),
                          const SizedBox(width: TlSpace.md),
                          TlPressable(
                            onTap: _skipAsGuest,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: TlSpace.xs,
                                vertical: TlSpace.xxs,
                              ),
                              child: Text(
                                'Skip',
                                style: context.type.bodySmall.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: TlSpace.xl),
                      Text(_titleForStep(), style: context.type.display),
                      const SizedBox(height: TlSpace.xs),
                      Text(_subtitleForStep(), style: context.type.body),
                    ],
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: TlMotion.medium,
                    switchInCurve: TlMotion.standard,
                    child: KeyedSubtree(
                      key: ValueKey(_step),
                      child: _buildStep(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(TlSpace.gutter),
                  child: TlButton(
                    label: _step == 2 ? 'Start learning' : 'Continue',
                    icon: _step == 2 ? LucideIcons.sparkles : null,
                    onPressed: _canContinue ? _advance : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _titleForStep() => switch (_step) {
    0 => 'What are you learning?',
    1 => 'Explain things in',
    _ => 'Where are you now?',
  };

  String _subtitleForStep() => switch (_step) {
    0 => 'Pick a language. You can add more later.',
    1 => 'Translations and hints will use this language.',
    _ => 'We will scale every lesson to this level.',
  };

  Widget _buildStep() {
    return switch (_step) {
      0 => _LanguageGrid(
        selected: _target,
        onSelect: (language) => setState(() => _target = language),
      ),
      1 => _LanguageGrid(
        selected: _support,
        disabled: _target,
        onSelect: (language) => setState(() => _support = language),
      ),
      _ => _LevelList(
        selected: _level,
        onSelect: (level) => setState(() => _level = level),
      ),
    };
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.step, required this.total});

  final int step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: List.generate(total, (index) {
        final isActive = index <= step;
        return AnimatedContainer(
          duration: TlMotion.fast,
          curve: TlMotion.standard,
          margin: const EdgeInsets.only(left: 6),
          height: 6,
          width: index == step ? 22 : 6,
          decoration: BoxDecoration(
            color: isActive ? colors.primary : colors.border,
            borderRadius: TlRadius.pillRadius,
          ),
        );
      }),
    );
  }
}

class _LanguageGrid extends StatelessWidget {
  const _LanguageGrid({
    required this.selected,
    required this.onSelect,
    this.disabled,
  });

  final Language? selected;
  final Language? disabled;
  final ValueChanged<Language> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: TlSpace.sm,
        crossAxisSpacing: TlSpace.sm,
        mainAxisExtent: 74,
      ),
      itemCount: LanguageCatalog.all.length,
      itemBuilder: (context, index) {
        final language = LanguageCatalog.all[index];
        final isSelected = language == selected;
        final isDisabled = language == disabled;

        return TlEntrance(
          index: index,
          child: Opacity(
            opacity: isDisabled ? 0.35 : 1,
            child: IgnorePointer(
              ignoring: isDisabled,
              child: TlPressable(
                onTap: () => onSelect(language),
                child: AnimatedContainer(
                  duration: TlMotion.fast,
                  curve: TlMotion.standard,
                  padding: const EdgeInsets.symmetric(horizontal: TlSpace.md),
                  decoration: BoxDecoration(
                    color: isSelected ? colors.primarySoft : colors.surface,
                    borderRadius: TlRadius.controlRadius,
                    border: Border.all(
                      color: isSelected ? colors.primary : colors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        language.flag,
                        style: const TextStyle(fontSize: TlGlyph.lg),
                      ),
                      const SizedBox(width: TlSpace.sm),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              language.endonym,
                              style: context.type.title.copyWith(
                                color: isSelected
                                    ? colors.primaryText
                                    : colors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              language.englishName,
                              style: context.type.caption,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LevelList extends StatelessWidget {
  const _LevelList({required this.selected, required this.onSelect});

  final CefrLevel selected;
  final ValueChanged<CefrLevel> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: TlSpace.gutter),
      itemCount: CefrLevel.values.length,
      separatorBuilder: (_, _) => const SizedBox(height: TlSpace.sm),
      itemBuilder: (context, index) {
        final level = CefrLevel.values[index];
        final isSelected = level == selected;

        return TlEntrance(
          index: index,
          child: TlPressable(
            onTap: () => onSelect(level),
            child: AnimatedContainer(
              duration: TlMotion.fast,
              curve: TlMotion.standard,
              padding: const EdgeInsets.all(TlSpace.md),
              decoration: BoxDecoration(
                color: isSelected ? colors.primarySoft : colors.surface,
                borderRadius: TlRadius.controlRadius,
                border: Border.all(
                  color: isSelected ? colors.primary : colors.border,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  TlPill(
                    label: level.code,
                    background: isSelected
                        ? colors.primary
                        : colors.surfaceSunken,
                    foreground: isSelected
                        ? colors.onAccent
                        : colors.textSecondary,
                  ),
                  const SizedBox(width: TlSpace.sm),
                  Expanded(
                    child: Text(
                      level.description,
                      style: context.type.bodyStrong,
                    ),
                  ),
                  if (isSelected)
                    Icon(LucideIcons.check, size: 20, color: colors.primary),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
