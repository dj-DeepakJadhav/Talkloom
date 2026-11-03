/// Ad configuration for all three platforms.
///
/// Web uses Google AdSense; Android and iOS use Google AdMob
/// (`google_mobile_ads`). One banner widget ([AdBanner]) picks the engine.
///
/// Setup:
/// 1. Web: create an AdSense account, add your site, paste the publisher ID
///    below and the ad-slot ID. The `adsbygoogle.js` loader is already in
///    `web/index.html` (replace `ca-pub-XXXX` there too).
/// 2. Android/iOS: create an AdMob account + app per platform, paste the
///    banner ad-unit IDs below and the App IDs into
///    `android/app/src/main/AndroidManifest.xml` and
///    `ios/Runner/Info.plist`. Until then the Google sample IDs serve
///    test ads, so the layout can be verified without an account.
/// 3. Flip [adsEnabled] to true only after the IDs above are real.
///    With test IDs it renders test ads; with empty IDs it renders nothing.
///
/// EEA/GDPR: before enabling real ads, add a consent flow
/// (e.g. `user_messaging_platform` for AdMob UMP + a cookie banner for
/// AdSense). Serving personalized ads without consent risks account action.
abstract final class AdConfig {
  /// Master switch. Keep false until every ID below is a real one.
  static const bool adsEnabled = false;

  // --- AdSense (web) ---
  static const String adsensePublisherId = 'ca-pub-XXXXXXXXXXXXXXXX';
  static const String adsenseSlotId = 'YYYYYYYYYY';

  // --- AdMob (Android / iOS). Google sample banner units (test ads). ---
  static const String admobAndroidBannerId =
      'ca-app-pub-3940256099942544/6300978111';
  static const String admobIosBannerId =
      'ca-app-pub-3940256099942544/2934735716';

  static bool get hasRealWebIds =>
      !adsensePublisherId.contains('XXXX') &&
      !adsenseSlotId.contains('YYYY');

  static bool get hasRealMobileIds =>
      !admobAndroidBannerId.contains('3940256099942544') ||
      !admobIosBannerId.contains('3940256099942544');
}
