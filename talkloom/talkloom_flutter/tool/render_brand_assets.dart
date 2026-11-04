// Run explicitly with: flutter test tool/render_brand_assets.dart
// Uses Flutter's rasterizer to export the same original mark at native sizes.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:talkloom_flutter/design/brand.dart';

Future<void> render(String path, int size) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder)..scale(size / 1024);
  canvas.drawColor(const ui.Color(0xfffffcf5), ui.BlendMode.src);
  const TalkloomMarkPainter(ink: ui.Color(0xff30251d), thread: ui.Color(0xff646f4b),
    background: ui.Color(0xfffffcf5)).paint(canvas, const ui.Size(1024, 1024));
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File(path);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
  picture.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('export Talkloom brand assets', () async {
    await render('assets/brand/talkloom-mark.png', 1024);
    await render('web/favicon.png', 32);
    for (final size in [192, 512]) {
      await render('web/icons/Icon-$size.png', size);
      await render('web/icons/Icon-maskable-$size.png', size);
    }
    const densities = {
      'mdpi': 48,
      'hdpi': 72,
      'xhdpi': 96,
      'xxhdpi': 144,
      'xxxhdpi': 192,
    };
    for (final entry in densities.entries) {
      await render(
        'android/app/src/main/res/mipmap-${entry.key}/ic_launcher.png',
        entry.value,
      );
    }
    for (final platform in ['ios', 'macos']) {
      final directory = '$platform/Runner/Assets.xcassets/AppIcon.appiconset';
      final json =
          jsonDecode(await File('$directory/Contents.json').readAsString())
              as Map;
      for (final item in (json['images'] as List).cast<Map>()) {
        if (item['filename'] is! String) continue;
        final size = double.parse((item['size'] as String).split('x').first);
        final scale = double.parse(
          (item['scale'] as String).replaceAll('x', ''),
        );
        await render('$directory/${item['filename']}', (size * scale).round());
      }
    }
  });
}
