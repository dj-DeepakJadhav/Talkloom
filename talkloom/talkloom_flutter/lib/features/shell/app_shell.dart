import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/components/tl_surface.dart';
import '../../design/theme.dart';
import '../arena/conversation_themes.dart';
import '../arena/talk_canvas_screen.dart';
import '../themes/themes_screen.dart';
import '../words/words_screen.dart';
import '../settings/api_keys_screen.dart';

/// Mural 1:1 App Shell (Matching RootView.swift & Screenshots 03-talk, 04-themes, 05-words)
///
/// Features replicated 1:1 with Talkloom styling:
/// - Top Minimal Header:
///   - Left: Warm glowing mark + "talkloom" brand text
///   - Right: Clean Sliders button to open BYOK Multi-Provider Settings (Gemini / NVIDIA / Groq)
/// - 3 Primary Tabs (Floating capsule bottom navigation matching Mural):
///   - [ 〰️ Talk ]
///   - [ ⊞ Themes ]
///   - [ 📖 Words ]
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _activeTabIndex = 0;
  final GlobalKey<_MuralTalkWrapperState> _talkKey = GlobalKey<_MuralTalkWrapperState>();

  void _onTabSelected(int index) {
    setState(() => _activeTabIndex = index);
  }

  void _startThemeConversation(ConversationTheme theme) {
    setState(() => _activeTabIndex = 0);
    _talkKey.currentState?.selectTheme(theme);
  }

  void _startGeneralTalk() {
    setState(() => _activeTabIndex = 0);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Scaffold(
      extendBody: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    // Brand Mark
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [Color(0xFFFBBF24), TlPalette.brassGold],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'talkloom',
                      style: context.type.title.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        fontSize: 20,
                      ),
                    ),
                    const Spacer(),
                    // Sliders / Settings Button matching Mural header 03-talk.png
                    TlPressable(
                      onTap: () => ApiKeysSheet.show(context),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: colors.surfaceRaised,
                          shape: BoxShape.circle,
                          border: Border.all(color: colors.border),
                        ),
                        child: Icon(
                          LucideIcons.slidersHorizontal,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: IndexedStack(
            index: _activeTabIndex,
            children: [
              _MuralTalkWrapper(key: _talkKey),
              ThemesScreen(
                onSelectTheme: _startThemeConversation,
                onStartGeneralTalk: _startGeneralTalk,
              ),
              const WordsScreen(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _MuralBottomTabBar(
        selectedIndex: _activeTabIndex,
        onTabSelected: _onTabSelected,
      ),
    );
  }
}

class _MuralTalkWrapper extends ConsumerStatefulWidget {
  const _MuralTalkWrapper({super.key});

  @override
  ConsumerState<_MuralTalkWrapper> createState() => _MuralTalkWrapperState();
}

class _MuralTalkWrapperState extends ConsumerState<_MuralTalkWrapper> {
  final GlobalKey<TalkCanvasScreenState> _canvasKey = GlobalKey<TalkCanvasScreenState>();

  void selectTheme(ConversationTheme theme) {
    _canvasKey.currentState?.setTheme(theme);
  }

  @override
  Widget build(BuildContext context) {
    return TalkCanvasScreen(key: _canvasKey);
  }
}

/// Floating Capsule 3-Tab Bar matching Mural RootView.swift & screenshots
class _MuralBottomTabBar extends StatelessWidget {
  const _MuralBottomTabBar({
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Center(
          heightFactor: 1,
          child: Container(
            height: 60,
            constraints: const BoxConstraints(maxWidth: 320),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: colors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: colors.border.withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _MuralTabItem(
                  icon: LucideIcons.audioWaveform,
                  label: 'Talk',
                  isSelected: selectedIndex == 0,
                  onTap: () => onTabSelected(0),
                ),
                _MuralTabItem(
                  icon: LucideIcons.layoutGrid,
                  label: 'Themes',
                  isSelected: selectedIndex == 1,
                  onTap: () => onTabSelected(1),
                ),
                _MuralTabItem(
                  icon: LucideIcons.bookOpen,
                  label: 'Words',
                  isSelected: selectedIndex == 2,
                  onTap: () => onTabSelected(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MuralTabItem extends StatelessWidget {
  const _MuralTabItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected ? colors.surfaceRaised : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? TlPalette.brassGold : colors.textMuted,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: context.type.caption.copyWith(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? colors.textPrimary : colors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
