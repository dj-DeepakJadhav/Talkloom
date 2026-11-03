import 'package:flutter/material.dart';
import '../../design/app_icons.dart';
import '../../design/theme.dart';

class TalkloomNavigationBar extends StatelessWidget {
  const TalkloomNavigationBar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) => NavigationBar(
    selectedIndex: selectedIndex,
    onDestinationSelected: onDestinationSelected,
    backgroundColor: context.colors.surface,
    indicatorColor: context.colors.primarySoft,
    animationDuration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 220),
    destinations: [
      NavigationDestination(
        icon: _NavGlyph(icon: AppIcons.house, selected: selectedIndex == 0),
        label: 'Home',
      ),
      NavigationDestination(
        icon: _NavGlyph(
          icon: selectedIndex == 1 ? AppIcons.libraryBig : AppIcons.library,
          selected: selectedIndex == 1,
        ),
        label: 'My learning',
      ),
      NavigationDestination(
        icon: _NavGlyph(icon: AppIcons.userRound, selected: selectedIndex == 2),
        label: 'Profile',
      ),
    ],
  );
}

class _NavGlyph extends StatelessWidget {
  const _NavGlyph({required this.icon, required this.selected});
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: selected ? 1 : 0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 240),
    curve: Curves.easeOutBack,
    child: Icon(icon),
    builder: (context, value, child) => Transform.translate(
      offset: Offset(0, -2 * value),
      child: Transform.scale(scale: 1 + .1 * value, child: child),
    ),
  );
}
