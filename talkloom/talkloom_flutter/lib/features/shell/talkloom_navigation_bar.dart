import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    destinations: const [
      NavigationDestination(
        icon: Icon(LucideIcons.sun),
        selectedIcon: Icon(LucideIcons.sunMedium),
        label: 'Today',
      ),
      NavigationDestination(
        icon: Icon(LucideIcons.library),
        selectedIcon: Icon(LucideIcons.libraryBig),
        label: 'My content',
      ),
      NavigationDestination(
        icon: Icon(LucideIcons.bookOpen),
        selectedIcon: Icon(LucideIcons.bookOpenCheck),
        label: 'My German',
      ),
    ],
  );
}
