import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import 'dart:ui_web' as ui_web;

import 'ad_config.dart';

@JS('adsbygoogle')
external JSObject? get _adsbygoogle;

extension type _AdsByGoogle(JSObject _) implements JSObject {
  external void push(JSObject ad);
}

/// AdSense banner for the web build.
///
/// Requires the `adsbygoogle.js` loader in `web/index.html` and real IDs in
/// [AdConfig]. The slot is responsive (`data-full-width-responsive`).
class PlatformAdBanner extends StatefulWidget {
  const PlatformAdBanner({super.key});

  @override
  State<PlatformAdBanner> createState() => _PlatformAdBannerState();
}

class _PlatformAdBannerState extends State<PlatformAdBanner> {
  static bool _registered = false;
  static const _viewType = 'talkloom-adsense-banner';

  @override
  void initState() {
    super.initState();
    if (_registered) {
      _push();
      return;
    }
    _registered = true;
    ui_web.platformViewRegistry.registerViewFactory(_viewType, (int viewId) {
      final div = web.HTMLDivElement();
      final ins = web.HTMLModElement.ins()
        ..className = 'adsbygoogle'
        ..style.display = 'block'
        ..setAttribute('data-ad-client', AdConfig.adsensePublisherId)
        ..setAttribute('data-ad-slot', AdConfig.adsenseSlotId)
        ..setAttribute('data-ad-format', 'auto')
        ..setAttribute('data-full-width-responsive', 'true');
      div.append(ins);
      // Push after the element is attached.
      Timer.run(_push);
      return div;
    });
  }

  static void _push() {
    try {
      if (_adsbygoogle != null) {
        _AdsByGoogle(_adsbygoogle!).push(JSObject());
      }
    } catch (_) {
      // Ad blockers or missing loader: leave the space collapsed.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!AdConfig.hasRealWebIds) return const SizedBox.shrink();
    return const SafeArea(
      top: false,
      child: SizedBox(
        height: 90,
        child: HtmlElementView(viewType: _viewType),
      ),
    );
  }
}
