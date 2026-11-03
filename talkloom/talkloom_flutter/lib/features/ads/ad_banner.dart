import 'package:flutter/material.dart';

import 'ad_config.dart';
import 'ad_banner_web.dart'
    if (dart.library.io) 'ad_banner_mobile.dart' as impl;

/// One banner for every platform: AdSense on web, AdMob on Android/iOS.
///
/// Renders nothing when [AdConfig.adsEnabled] is false, so the free app
/// never shows an empty box during development.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.adsEnabled) return const SizedBox.shrink();
    return const impl.PlatformAdBanner();
  }
}
