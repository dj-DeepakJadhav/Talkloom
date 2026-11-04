import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../core/failure.dart';
import '../../design/app_icons.dart';
import '../../design/theme.dart';
import '../../domain/language.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(learningSessionProvider);
    final preferences = ref.watch(sharedPreferencesProvider);
    final languageCodes =
        preferences.getStringList('talkloom.languages.v1') ??
        [session.target.code];
    final languages = languageCodes
        .map(LanguageCatalog.byCode)
        .toList(growable: false);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      children: [
        Text('Profile', style: context.type.headline),
        const SizedBox(height: 20),
        Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.colors.primarySoft,
              foregroundColor: context.colors.textPrimary,
              child: const Icon(AppIcons.userRound),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text('Your learning', style: context.type.titleLarge),
            ),
            TextButton(
              onPressed: () => context.push('/sign-in'),
              child: const Text('Account'),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _ProfileGroup(
          title: 'Learning',
          children: [
            _ProfileRow(
              icon: AppIcons.languages,
              title: 'Learning languages',
              value: languages.map((language) => language.endonym).join(', '),
              onTap: () => context.push('/profile/languages'),
            ),
            _ProfileRow(
              icon: AppIcons.messageSquare,
              title: 'Explain in',
              value: session.support.endonym,
              onTap: () => _chooseExplanationLanguage(context, ref),
            ),
            _ProfileRow(
              icon: AppIcons.refreshCw,
              title: 'Repair lessons',
              value: 'Rebuild flawed saves',
              onTap: () => _repairLessons(context, ref),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileGroup(
          title: 'App',
          children: [
            _ProfileRow(
              icon: AppIcons.audioWaveform,
              title: 'Audio & speech',
              onTap: () => _showPreferences(context, audio: true),
            ),
            _ProfileRow(
              icon: context.isDarkMode ? AppIcons.moon : AppIcons.sun,
              title: 'Appearance',
              value: switch (ref.watch(appThemeProvider)) {
                ThemeMode.system => 'System',
                ThemeMode.light => 'Light',
                ThemeMode.dark => 'Dark',
              },
              onTap: () => _chooseAppearance(context, ref),
            ),
            _ProfileRow(
              icon: AppIcons.eye,
              title: 'Accessibility',
              onTap: () => _showPreferences(context, audio: false),
            ),
            _ProfileRow(
              icon: AppIcons.shieldCheck,
              title: 'Privacy & data',
              onTap: () => _showInfo(
                context,
                'Privacy & data',
                'Your shared content is used to prepare your learning material. Account creation is optional.',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _chooseAppearance(BuildContext context, WidgetRef ref) async {
    final selected = await showModalBottomSheet<ThemeMode>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Appearance', style: context.type.headline),
                ),
                for (final mode in [
                  ThemeMode.system,
                  ThemeMode.light,
                  ThemeMode.dark,
                ])
                  ListTile(
                    leading: Icon(
                      mode == ThemeMode.dark
                          ? AppIcons.moon
                          : mode == ThemeMode.light
                          ? AppIcons.sun
                          : AppIcons.slidersHorizontal,
                    ),
                    title: Text(switch (mode) {
                      ThemeMode.system => 'System',
                      ThemeMode.light => 'Light',
                      ThemeMode.dark => 'Dark',
                    }),
                    subtitle: mode == ThemeMode.system
                        ? const Text('Follow your device’s appearance')
                        : null,
                    trailing: ref.read(appThemeProvider) == mode
                        ? const Icon(AppIcons.check)
                        : null,
                    selected: ref.read(appThemeProvider) == mode,
                    onTap: () => Navigator.pop(context, mode),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    if (selected != null && context.mounted) {
      await ref.read(appThemeProvider.notifier).setMode(selected);
    }
  }

  Future<void> _chooseExplanationLanguage(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final session = ref.read(learningSessionProvider);
    final selected = await showModalBottomSheet<Language>(
      context: context,
      useSafeArea: true,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Explain in')),
            for (final language in LanguageCatalog.all)
              ListTile(
                title: Text(language.endonym),
                trailing: language == session.support
                    ? const Icon(AppIcons.check)
                    : null,
                onTap: () => Navigator.pop(context, language),
              ),
          ],
        ),
      ),
    );
    if (selected == null || !context.mounted) return;
    await ref
        .read(learningSessionProvider.notifier)
        .save(session.copyWith(support: selected));
    ref.invalidate(sourcesProvider);
    ref.invalidate(lessonsProvider);
  }

  void _showPreferences(BuildContext context, {required bool audio}) {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(appPreferencesProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    audio ? 'Audio & speech' : 'Accessibility',
                    style: context.type.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (audio) ...[
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Read replies aloud'),
                      subtitle: const Text(
                        'Play the tutor’s reply after you send a message.',
                      ),
                      value: settings.readReplies,
                      onChanged: ref
                          .read(appPreferencesProvider.notifier)
                          .setReadReplies,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tutor voice',
                      style: context.type.body.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Open-source German voices, served from this server with on-device fallback.',
                      style: context.type.caption,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        for (final option in speechVoiceOptions)
                          ButtonSegment(
                            value: option.id,
                            label: Text(option.name),
                          ),
                      ],
                      selected: {settings.speechVoice},
                      onSelectionChanged: (selected) => ref
                          .read(appPreferencesProvider.notifier)
                          .setSpeechVoice(selected.first),
                    ),
                    Text(
                      speechVoiceOptions
                          .firstWhere(
                            (option) => option.id == settings.speechVoice,
                            orElse: () => speechVoiceOptions.first,
                          )
                          .detail,
                      style: context.type.caption,
                    ),
                  ] else
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reduce motion'),
                      subtitle: const Text(
                        'Also respects your device’s motion preference.',
                      ),
                      value: settings.reduceMotion,
                      onChanged: ref
                          .read(appPreferencesProvider.notifier)
                          .setReduceMotion,
                    ),
                  const SizedBox(height: 12),
                  Text(
                    audio
                        ? 'Microphone access is requested when you start speaking. You can always type a reply.'
                        : 'Text size follows your device settings. Learning screens scroll to keep controls reachable.',
                    style: context.type.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _showInfo(BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Future<void> _repairLessons(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repair lessons?'),
        content: const Text(
          'Talkloom checks your saved lessons against the current quality '
          'checks and rebuilds the flawed ones from their sources. '
          'This uses your daily AI allowance (up to 5 rebuilds per run).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(lessonRepositoryProvider);
    final session = ref.read(learningSessionProvider);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Expanded(child: Text('Checking and rebuilding lessons…')),
          ],
        ),
      ),
    );
    try {
      final result = await repo.repairLessons(session);
      ref.invalidate(sourcesProvider);
      ref.invalidate(lessonsProvider);
      if (!context.mounted) return;
      Navigator.pop(context);
      _showInfo(
        context,
        result.repaired == 0 && result.failed == 0
            ? 'Lessons look good'
            : 'Repair finished',
        result.repaired == 0 && result.failed == 0
            ? 'All ${result.clean} lessons already pass the quality checks.'
            : 'Rebuilt ${result.repaired}, already fine ${result.clean}, '
                  'could not rebuild ${result.failed}.',
      );
    } catch (error) {
      if (!context.mounted) return;
      Navigator.pop(context);
      _showInfo(context, 'Repair stopped', Failure.from(error).message);
    }
  }
}

class LanguagesScreen extends ConsumerStatefulWidget {
  const LanguagesScreen({super.key});

  @override
  ConsumerState<LanguagesScreen> createState() => _LanguagesScreenState();
}

class _LanguagesScreenState extends ConsumerState<LanguagesScreen> {
  late List<String> _codes;

  @override
  void initState() {
    super.initState();
    final preferences = ref.read(sharedPreferencesProvider);
    final active = ref.read(learningSessionProvider).target.code;
    _codes = preferences.getStringList('talkloom.languages.v1') ?? [active];
    if (!_codes.contains(active)) _codes.insert(0, active);
  }

  Future<void> _switch(Language language) async {
    await ref.read(learningSessionProvider.notifier).switchTarget(language);
    ref.invalidate(sourcesProvider);
    ref.invalidate(lessonsProvider);
    ref.invalidate(learnerStateProvider);
    ref.invalidate(wordEvidenceProvider);
    if (mounted) setState(() {});
  }

  Future<void> _editLevel(Language language) async {
    final selected = await showModalBottomSheet<CefrLevel>(
      context: context,
      useSafeArea: true,
      builder: (context) => ListView(
        shrinkWrap: true,
        children: [
          const ListTile(title: Text('Support level')),
          for (final level in CefrLevel.values)
            ListTile(
              title: Text('${level.code} · ${level.description}'),
              onTap: () => Navigator.pop(context, level),
            ),
        ],
      ),
    );
    if (selected == null) return;
    await ref
        .read(learningSessionProvider.notifier)
        .updateLevel(language, selected);
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(learningSessionProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Your languages')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          for (final code in _codes)
            _LanguageCard(
              language: LanguageCatalog.byCode(code),
              active: active.target.code == code,
              level:
                  _savedLevel(code) ??
                  (active.target.code == code ? active.level : null),
              onSwitch: () => _switch(LanguageCatalog.byCode(code)),
              onEditLevel: () => _editLevel(LanguageCatalog.byCode(code)),
            ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: () async {
              await context.push('/profile/languages/add');
              if (!mounted) return;
              final updated =
                  ref
                      .read(sharedPreferencesProvider)
                      .getStringList('talkloom.languages.v1') ??
                  _codes;
              setState(() => _codes = updated);
            },
            icon: const Icon(AppIcons.plus),
            label: const Text('Add a language'),
          ),
          const SizedBox(height: 10),
          Text(
            'Progress stays with each language.',
            textAlign: TextAlign.center,
            style: context.type.caption,
          ),
        ],
      ),
    );
  }

  CefrLevel? _savedLevel(String code) {
    final raw = ref
        .read(sharedPreferencesProvider)
        .getString('talkloom.language-profiles.v1');
    if (raw == null) return null;
    try {
      final profiles = jsonDecode(raw) as Map<String, dynamic>;
      final profile = profiles[code] as Map<String, dynamic>?;
      final level = profile?['level'] as String?;
      return level == null ? null : CefrLevel.fromCode(level);
    } on Object {
      return null;
    }
  }
}

class AddLanguageScreen extends ConsumerStatefulWidget {
  const AddLanguageScreen({super.key});

  @override
  ConsumerState<AddLanguageScreen> createState() => _AddLanguageScreenState();
}

class _AddLanguageScreenState extends ConsumerState<AddLanguageScreen> {
  String _query = '';
  Language? _selected;
  CefrLevel _level = CefrLevel.a1;

  Future<void> _start() async {
    final language = _selected;
    if (language == null) return;
    await ref.read(learningSessionProvider.notifier).switchTarget(language);
    final selectedSession = ref.read(learningSessionProvider);
    await ref
        .read(learningSessionProvider.notifier)
        .save(selectedSession.copyWith(target: language, level: _level));
    ref.invalidate(sourcesProvider);
    ref.invalidate(lessonsProvider);
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(learningSessionProvider);
    final added =
        ref
            .watch(sharedPreferencesProvider)
            .getStringList('talkloom.languages.v1') ??
        [current.target.code];
    final options = LanguageCatalog.all
        .where(
          (language) =>
              language.englishName.toLowerCase().contains(
                _query.toLowerCase(),
              ) ||
              language.endonym.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Add a language')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        children: [
          TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: const InputDecoration(
              prefixIcon: Icon(AppIcons.search),
              hintText: 'Search languages',
            ),
          ),
          const SizedBox(height: 12),
          for (final language in options)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 4),
              title: Text(language.endonym),
              subtitle: Text(language.englishName),
              trailing: added.contains(language.code)
                  ? Text(
                      'Added',
                      style: context.type.labelSmall.copyWith(
                        color: context.colors.textMuted,
                      ),
                    )
                  : Icon(
                      _selected == language
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: context.colors.primary,
                    ),
              selected: _selected == language,
              onTap: added.contains(language.code)
                  ? null
                  : () => setState(() => _selected = language),
            ),
          const SizedBox(height: 16),
          Text('Support level', style: context.type.title),
          const SizedBox(height: 8),
          SegmentedButton<CefrLevel>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: CefrLevel.a1, label: Text('Beginner')),
              ButtonSegment(value: CefrLevel.b1, label: Text('Intermediate')),
              ButtonSegment(value: CefrLevel.c1, label: Text('Advanced')),
            ],
            selected: {_level},
            onSelectionChanged: (value) => setState(() => _level = value.first),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Language>(
            initialValue: current.support,
            decoration: const InputDecoration(labelText: 'Explain in'),
            items: LanguageCatalog.all
                .map(
                  (language) => DropdownMenuItem(
                    value: language,
                    child: Text(language.endonym),
                  ),
                )
                .toList(),
            onChanged: (language) {
              if (language != null) {
                ref
                    .read(learningSessionProvider.notifier)
                    .save(current.copyWith(support: language));
              }
            },
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _selected == null ? null : _start,
            child: Text(
              _selected == null
                  ? 'Choose a language'
                  : 'Start ${_selected!.endonym}',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Example language options. Availability depends on the learning features used.',
            textAlign: TextAlign.center,
            style: context.type.caption,
          ),
        ],
      ),
    );
  }
}

class _ProfileGroup extends StatelessWidget {
  const _ProfileGroup({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: context.type.title),
      const SizedBox(height: 8),
      ...children,
    ],
  );
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.value,
  });
  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: Icon(icon, color: context.colors.textSecondary),
    title: Text(title, style: context.type.bodyStrong),
    subtitle: value == null
        ? null
        : Text(value!, maxLines: 1, overflow: TextOverflow.ellipsis),
    trailing: const Icon(AppIcons.chevronRight, size: 18),
    onTap: onTap,
  );
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.language,
    required this.active,
    required this.onSwitch,
    required this.onEditLevel,
    this.level,
  });
  final Language language;
  final bool active;
  final CefrLevel? level;
  final VoidCallback onSwitch;
  final VoidCallback onEditLevel;

  @override
  Widget build(BuildContext context) => Card(
    elevation: 0,
    color: context.colors.surfaceRaised,
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      title: Text(language.endonym, style: context.type.title),
      subtitle: Text(
        active
            ? 'Active${level == null ? '' : ' · ${level!.code}'}'
            : level == null
            ? 'Support level not set'
            : '${level!.code} support level',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(onPressed: onEditLevel, child: const Text('Edit')),
          if (active)
            Icon(AppIcons.circleCheck, color: context.colors.primary)
          else
            TextButton(onPressed: onSwitch, child: const Text('Switch')),
        ],
      ),
    ),
  );
}
