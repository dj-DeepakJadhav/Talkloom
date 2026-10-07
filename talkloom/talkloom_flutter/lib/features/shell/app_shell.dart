import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/theme.dart';
import '../../app/providers.dart';
import '../content/content_home.dart';
import '../content/my_german_screen.dart';
import '../ingest/universal_ingest_sheet.dart';
import 'talkloom_navigation_bar.dart';

/// Content shared by the learner is the entry point to speaking.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  late int _index = widget.initialIndex.clamp(0, 2);
  @override
  void didUpdateWidget(covariant AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _index = widget.initialIndex.clamp(0, 2);
    }
  }

  void _add() => UniversalIngestSheet.show(context);
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text('talkloom', style: context.type.titleLarge),
      actions: [
        TextButton.icon(
          onPressed: () async {
            await context.push('/sign-in');
            if (context.mounted) {
              ref.invalidate(sourcesProvider);
              ref.invalidate(lessonsProvider);
              ref.invalidate(learnerStateProvider);
            }
          },
          icon: const Icon(LucideIcons.userRound),
          label: const Text('Account'),
        ),
        IconButton(
          tooltip: 'Switch light or dark appearance',
          onPressed: () => ref.read(appThemeProvider.notifier).toggle(),
          icon: Icon(
            context.isDarkMode ? LucideIcons.sun : LucideIcons.moon,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextButton.icon(
            onPressed: _add,
            icon: const Icon(LucideIcons.plus, size: 18),
            label: const Text('Add'),
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: IndexedStack(
          index: _index,
          children: [
            ContentHome(today: true, onAdd: _add),
            ContentHome(today: false, onAdd: _add),
            const MyGermanScreen(),
          ],
        ),
      ),
    ),
    bottomNavigationBar: TalkloomNavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) => context.go('/?tab=$index'),
    ),
  );
}
