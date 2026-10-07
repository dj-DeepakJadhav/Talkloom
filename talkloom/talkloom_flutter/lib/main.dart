import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'client.dart';
import 'design/theme.dart';
import 'core/platform/qwen_speech_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const TalkloomApp(),
    ),
  );
}

class TalkloomApp extends ConsumerWidget {
  const TalkloomApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      scaffoldMessengerKey: speechMessengerKey,
      title: 'Talkloom',
      debugShowCheckedModeBanner: false,
      theme: buildTalkloomTheme(Brightness.light),
      darkTheme: buildTalkloomTheme(Brightness.dark),
      themeMode: ref.watch(appThemeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => child ?? const SizedBox.shrink(),
    );
  }
}
