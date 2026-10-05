import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../design/theme.dart';

/// Conversation theme data model inspired by Mural (https://github.com/Chuloo/mural)
/// Representing contextual situational conversational starters with glanceable icons and prompts.
class ConversationTheme {
  const ConversationTheme({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.category,
    required this.situation,
    required this.role,
    required this.hiddenTargets,
    required this.initialGreeting,
    required this.initialTranslation,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final String category;
  final String situation;
  final String role;
  final List<String> hiddenTargets;
  final String initialGreeting;
  final String initialTranslation;

  static const List<ConversationTheme> themes = [
    ConversationTheme(
      id: 'coffee',
      title: 'A coffee?',
      subtitle: 'Something warm, please',
      icon: LucideIcons.coffee,
      category: 'Everyday',
      situation: 'You work in a cosy café in Berlin. Help the learner order a beverage and pastry, then chat naturally.',
      role: 'Barista in Berlin',
      hiddenTargets: ['Kaffee', 'Bestellung', 'Milch', 'Zucker', 'zahlen'],
      initialGreeting: 'Hallo! Was darf es für Sie sein? Ein Espresso oder ein Cappuccino?',
      initialTranslation: 'Hello! What can I get for you? An espresso or a cappuccino?',
    ),
    ConversationTheme(
      id: 'weekend',
      title: 'The weekend',
      subtitle: 'Tell me about yours',
      icon: LucideIcons.sun,
      category: 'Connection',
      situation: 'Ask about the learner’s weekend plans or recent events. Practise past tense and follow their interests.',
      role: 'Friendly Colleague',
      hiddenTargets: ['Wochenende', 'Samstag', 'Sonntag', 'ausruhen', 'Plan'],
      initialGreeting: 'Hallo! Wie war dein Wochenende? Hast du etwas Schönes gemacht?',
      initialTranslation: 'Hello! How was your weekend? Did you do anything fun?',
    ),
    ConversationTheme(
      id: 'walk',
      title: 'A little walk',
      subtitle: 'Out into the fresh air',
      icon: LucideIcons.trees,
      category: 'Local life',
      situation: 'Take an imagined walk in the Tiergarten together. Talk about nature, weather, and daily pace.',
      role: 'Local Resident',
      hiddenTargets: ['Spaziergang', 'Park', 'Wetter', 'Bäume', 'frische Luft'],
      initialGreeting: 'Schön hier im Park! Wollen wir eine Runde um den See laufen?',
      initialTranslation: 'Lovely here in the park! Shall we take a walk around the lake?',
    ),
    ConversationTheme(
      id: 'dinner',
      title: 'Dinner plans',
      subtitle: 'Let’s make something',
      icon: LucideIcons.utensils,
      category: 'Everyday',
      situation: 'Plan dinner together. Ask about favorite ingredients, preferences, and the cooking steps.',
      role: 'Roommate / Flatmate',
      hiddenTargets: ['Abendessen', 'kochen', 'Zutaten', 'Rezept', 'lecker'],
      initialGreeting: 'Hunger! Was kochen wir heute Abend zusammen?',
      initialTranslation: 'Hungry! What are we cooking together tonight?',
    ),
    ConversationTheme(
      id: 'groceries',
      title: 'At the market',
      subtitle: 'Find fresh produce',
      icon: LucideIcons.shoppingBasket,
      category: 'Everyday',
      situation: 'Help the learner shop at a local weekly farmers market (Wochenmarkt). Practise quantities and prices.',
      role: 'Market Stall Vendor',
      hiddenTargets: ['Markt', 'Obst', 'Gemüse', 'Kilo', 'frisch'],
      initialGreeting: 'Guten Tag! Frische Äpfel und Beeren heute. Wie viel möchten Sie?',
      initialTranslation: 'Good day! Fresh apples and berries today. How much would you like?',
    ),
    ConversationTheme(
      id: 'travel',
      title: 'Next stop',
      subtitle: 'A ticket to somewhere',
      icon: LucideIcons.trainTrack,
      category: 'Everyday',
      situation: 'Help the learner navigate the train station (Hauptbahnhof), choose a ticket, and find their platform.',
      role: 'Bahn Info Agent',
      hiddenTargets: ['Fahrkarte', 'Gleis', 'Zug', 'Verspätung', 'Umsteigen'],
      initialGreeting: 'Guten Tag! Wohin soll Ihre Reise heute gehen?',
      initialTranslation: 'Good day! Where would you like to travel today?',
    ),
    ConversationTheme(
      id: 'work',
      title: 'Monday morning',
      subtitle: 'Around the office',
      icon: LucideIcons.briefcase,
      category: 'Professional',
      situation: 'Chat as colleagues before a standup meeting. Discuss tasks, deadlines, and weekend recaps.',
      role: 'Team Lead',
      hiddenTargets: ['Projekt', 'Besprechung', 'Termin', 'Aufgabe', 'Erfolg'],
      initialGreeting: 'Morgen! Bereit für die Woche? Welche Aufgaben stehen heute an?',
      initialTranslation: 'Morning! Ready for the week? What tasks are on today?',
    ),
    ConversationTheme(
      id: 'film',
      title: 'Movie night',
      subtitle: 'Something worth watching',
      icon: LucideIcons.film,
      category: 'Interests',
      situation: 'Discuss recent movies and television series. Share recommendations and reviews without spoilers.',
      role: 'Film Enthusiast',
      hiddenTargets: ['Film', 'Schauspieler', 'Kino', 'spannend', 'Empfehlung'],
      initialGreeting: 'Hey! Hast du in letzter Zeit einen richtig guten Film gesehen?',
      initialTranslation: 'Hey! Have you seen any really good movies lately?',
    ),
  ];
}

/// Mural-inspired "What's on your mind?" Conversation Themes Bottom Sheet
class ThemesPickerSheet extends StatefulWidget {
  const ThemesPickerSheet({
    super.key,
    required this.onSelectTheme,
  });

  final ValueChanged<ConversationTheme> onSelectTheme;

  static Future<void> show(
    BuildContext context, {
    required ValueChanged<ConversationTheme> onSelectTheme,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ThemesPickerSheet(onSelectTheme: onSelectTheme),
    );
  }

  @override
  State<ThemesPickerSheet> createState() => _ThemesPickerSheetState();
}

class _ThemesPickerSheetState extends State<ThemesPickerSheet> {
  String _selectedCategory = 'All';
  final String _searchQuery = '';

  List<String> get _categories => ['All', 'Everyday', 'Connection', 'Local life', 'Interests', 'Professional'];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final filteredThemes = ConversationTheme.themes.where((theme) {
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

    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: TlSpace.maxContentWidth),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.80,
          decoration: BoxDecoration(
            color: colors.canvas,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(top: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: colors.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A place to begin',
                        style: context.type.caption.copyWith(
                          color: TlPalette.brassGold,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'What’s on your mind?',
                        style: context.type.title.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Same companion, somewhere new.',
                        style: context.type.caption.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(LucideIcons.x, size: 20, color: colors.textSecondary),
                ),
              ],
            ),
          ),

          // Category Chips
          SizedBox(
            height: 38,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
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
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? colors.primary : colors.textPrimary,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Themes Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: filteredThemes.length,
              itemBuilder: (context, index) {
                final theme = filteredThemes[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Navigator.of(context).pop();
                      widget.onSelectTheme(theme);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: colors.surfaceRaised,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              theme.icon,
                              size: 20,
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
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                theme.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: context.type.caption.copyWith(
                                  color: colors.textSecondary,
                                  fontSize: 11,
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
          ),
        ],
      ),
    ),
    ),
    );
  }
}
