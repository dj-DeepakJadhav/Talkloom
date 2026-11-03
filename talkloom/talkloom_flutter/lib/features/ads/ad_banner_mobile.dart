import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'ad_config.dart';

/// AdMob banner for Android and iOS.
///
/// Uses the Google sample ad units until real IDs land in [AdConfig].
/// Remember the platform setup: `APPLICATION_ID` in AndroidManifest.xml
/// and `GADApplicationIdentifier` in Info.plist (both done, sample IDs).
class PlatformAdBanner extends StatefulWidget {
  const PlatformAdBanner({super.key});

  @override
  State<PlatformAdBanner> createState() => _PlatformAdBannerState();
}

class _PlatformAdBannerState extends State<PlatformAdBanner> {
  BannerAd? _ad;
  bool _ready = false;

  String get _unitId => Platform.isIOS
      ? AdConfig.admobIosBannerId
      : AdConfig.admobAndroidBannerId;

  @override
  void initState() {
    super.initState();
    final ad = BannerAd(
      size: AdSize.banner,
      request: const AdRequest(),
      adUnitId: _unitId,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          if (mounted) setState(() => _ready = false);
        },
      ),
    );
    _ad = ad;
    ad.load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _ad == null) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: SizedBox(
        width: _ad!.size.width.toDouble(),
        height: _ad!.size.height.toDouble(),
        child: AdWidget(ad: _ad!),
      ),
    );
  }
}
