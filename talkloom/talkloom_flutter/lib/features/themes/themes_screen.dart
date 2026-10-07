import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/theme.dart';
import '../arena/conversation_themes.dart';

/// Mural 1:1 Themes Screen (matching 04-themes.png)
/// Header: "A PLACE TO BEGIN" -> "What's on your mind?" -> "Same friend. Somewhere new."
/// Quick Card: "Just talk"
/// Horizontal Category Pills: [All] [Everyday] [Connection] [Local life] [Interests] [Professional]
/// 2-Column Rounded Theme Cards with distinctive subtle backgrounds and glanceable icons
class ThemesScreen extends ConsumerStatefulWidget {
  const ThemesScreen({
    super.key,
    this.onSelectTheme,
    this.onStartGeneralTalk,
  });

  final ValueChanged<ConversationTheme>? onSelectTheme;
  final VoidCallback? onStartGeneralTalk;

  @override
  ConsumerState<ThemesScreen> createState() => _ThemesScreenState();
}

class _ThemesScreenState extends ConsumerState<ThemesScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  static const List<String> _categories = [
    'All',
    'Everyday',
    'Connection',
    'Local life',
    'Interests',
    'Professional',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final allThemes = ConversationTheme.themes;

    final filteredThemes = allThemes.where((theme) {
      if (_selectedCategory != 'All' && theme.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return theme.title.toLowerCase().contains(q) ||
            theme.subtitle.toLowerCase().contains(q) ||
            theme.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              // Search Input matching 04-themes.png
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.search,
                      size: 18,
                      color: colors.textMuted,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            setState(() => _searchQuery = val.trim()),
                        style: context.type.body.copyWith(
                          fontSize: 15,
                          color: colors.textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Find a conversation',
                          hintStyle: context.type.body.copyWith(
                            color: colors.textMuted,
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                        ),
                      ),
                    ),
                    if (_searchQuery.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Mural Eyebrow & Title
              Text(
                'A PLACE TO BEGIN',
                style: context.type.caption.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                  color: TlPalette.brassGold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                "What's on\nyour mind?",
                style: context.type.display.copyWith(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Same friend. Somewhere new.',
                style: context.type.body.copyWith(
                  color: colors.textSecondary,
                  fontSize: 15,
                ),
              ),

              const SizedBox(height: 22),

              // "Just talk" hero card matching Mural 04-themes.png
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () {
                    widget.onStartGeneralTalk?.call();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          LucideIcons.audioWaveform,
                          size: 20,
                          color: TlPalette.brassGold,
                        ),
                        const SizedBox(width: 14),
                        Text(
                          'Just talk',
                          style: context.type.title.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          LucideIcons.chevronRight,
                          size: 18,
                          color: colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Horizontal Category Chips matching 04-themes.png
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = cat == _selectedCategory;
                    return ChoiceChip(
                      label: Text(cat),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) setState(() => _selectedCategory = cat);
                      },
                      selectedColor: colors.primarySoft,
                      backgroundColor: colors.surfaceRaised,
                      side: BorderSide(
                        color: isSelected ? colors.primary : colors.border,
                      ),
                      labelStyle: context.type.caption.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected ? colors.primary : colors.textPrimary,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // 2-Column Theme Cards Grid matching 04-themes.png
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.95,
                ),
                itemCount: filteredThemes.length,
                itemBuilder: (context, index) {
                  final theme = filteredThemes[index];
                  return Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        widget.onSelectTheme?.call(theme);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: colors.border.withValues(alpha: 0.9),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: colors.surfaceRaised,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                theme.icon,
                                size: 22,
                                color: TlPalette.brassGold,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  theme.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.bodyStrong.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  theme.subtitle,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.type.caption.copyWith(
                                    color: colors.textSecondary,
                                    fontSize: 12,
                                    height: 1.25,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
