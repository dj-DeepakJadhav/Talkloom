import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/providers.dart';
import '../../app/router.dart';
import '../../design/components/tl_button.dart';
import '../../design/app_icons.dart';
import '../practice/practice_launcher.dart';
import '../practice/practice_session_screen.dart';

/// The guided lesson for one link: each word is introduced and asked about,
/// then mixed games from the link's own words and sentences, then the speaking
/// mission. The steps come from the stored lesson, not a fresh AI call.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key});

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  late final PracticeSessionArgs? _args = _build();

  PracticeSessionArgs? _build() {
    final lesson = ref.read(activeLessonProvider);
    if (lesson == null) return null;
    final title = ref.read(selectedSourceProvider)?.title ?? 'Your lesson';
    return PracticeLauncher.lessonFlow(
      lesson,
      ref.read(wordTrackingAnalyticsProvider),
      title: title,
      speakRoute: TlRoutes.speak,
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = _args;
    if (args != null) return PracticeSessionScreen(args: args);

    // A short source can have no words to drill; go straight to speaking.
    final hasLesson = ref.watch(activeLessonProvider) != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Lesson')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hasLesson
                    ? 'This source was short, so there is nothing to drill. '
                          'Go straight to speaking.'
                    : 'Open your shared content to start a lesson.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (hasLesson)
                TlButton(
                  label: 'Start speaking',
                  icon: AppIcons.mic,
                  tone: TlButtonTone.success,
                  onPressed: () => context.pushReplacement(TlRoutes.speak),
                )
              else
                TlButton(
                  label: 'Back to My learning',
                  onPressed: () => context.go('/?tab=1'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
