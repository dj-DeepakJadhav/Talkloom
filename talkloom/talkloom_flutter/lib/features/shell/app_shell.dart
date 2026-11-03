import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../content/content_home.dart';
import '../content/my_german_screen.dart';
import '../ingest/shared_intent.dart';
import '../ingest/universal_ingest_sheet.dart';
import '../profile/profile_screen.dart';
import 'talkloom_navigation_bar.dart';

/// Content shared by the learner is the entry point to speaking.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key, this.initialIndex = 0});
  final int initialIndex;
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell>
    with WidgetsBindingObserver {
  late int _index = widget.initialIndex.clamp(0, 2);
  final _shareIntake = ShareIntake();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Cold start from the share sheet: the intent arrived with onCreate.
    _drainSharedText();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Warm share: the sheet opened this activity while it was alive.
    if (state == AppLifecycleState.resumed) _drainSharedText();
  }

  /// Share-target flow: a link or text shared from another app opens the
  /// import sheet prefilled and starts analysis at once. A known link
  /// resolves from the saved database through the normal import cache.
  Future<void> _drainSharedText() async {
    final shared = await _shareIntake.takeSharedText();
    if (!mounted || shared == null || shared.isEmpty) return;
    final split = splitSharedText(shared);
    if (split.url == null && split.text.isEmpty) return;
    UniversalIngestSheet.show(
      context,
      initialLink: split.url,
      initialText: split.url == null ? shared : null,
      autoStart: true,
    );
  }

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
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              const _OfflineBanner(),
              Expanded(
                child: IndexedStack(
                  index: _index,
                  children: [
                    TickerMode(
                      enabled: _index == 0,
                      child: ContentHome(onAdd: _add),
                    ),
                    TickerMode(
                      enabled: _index == 1,
                      child: const MyGermanScreen(),
                    ),
                    TickerMode(
                      enabled: _index == 2,
                      child: const ProfileScreen(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: TalkloomNavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (index) => context.go('/?tab=$index'),
    ),
  );
}

/// Display-only offline notice. Never gates requests: learning content
/// stays usable, only fresh loads may wait for connectivity.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner();

  static bool _offline(List<ConnectivityResult> results) =>
      results.isEmpty || results.every((r) => r == ConnectivityResult.none);

  @override
  Widget build(BuildContext context) => StreamBuilder<List<ConnectivityResult>>(
    stream: Connectivity().onConnectivityChanged,
    initialData: const [ConnectivityResult.wifi],
    builder: (context, snapshot) {
      final results = snapshot.data ?? const [ConnectivityResult.wifi];
      if (!_offline(results)) return const SizedBox.shrink();
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text(
          'Offline: du lernst weiter, Neues lädt später. / Offline: keep learning, new content loads later.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      );
    },
  );
}
