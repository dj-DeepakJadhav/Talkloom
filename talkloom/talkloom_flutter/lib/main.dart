import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app/app_viewport.dart';
import 'app/providers.dart';
import 'app/router.dart';
import 'client.dart';
import 'design/theme.dart';
import 'core/platform/device_voice_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeClient();
  // AdMob for Android/iOS. Web uses AdSense instead (see index.html).
  // Initialized early so the first banner never waits on SDK startup.
  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }
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
    // Keep the speech service's selected open voice in sync. Rebuilds
    // on every preference change, so the assignment always follows.
    DeviceVoiceService.serverVoiceId = ref
        .watch(appPreferencesProvider)
        .speechVoice;
    return MaterialApp.router(
      scaffoldMessengerKey: speechMessengerKey,
      title: 'Talkloom',
      debugShowCheckedModeBanner: false,
      theme: buildTalkloomTheme(Brightness.light),
      darkTheme: buildTalkloomTheme(Brightness.dark),
      themeMode: ref.watch(appThemeProvider),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          disableAnimations:
              MediaQuery.of(context).disableAnimations ||
              ref.watch(appPreferencesProvider).reduceMotion,
        ),
        child: TlAppViewport(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
