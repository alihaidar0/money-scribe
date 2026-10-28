import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Where the pictures of the screens are written. Not committed (`build/` is
/// ignored).
const renderDirectory = 'build/screens';

/// Loads Inter, IBM Plex Sans Arabic (from `assets/fonts/`), the Lucide icons
/// and the Material icons (the framework's own date picker still draws them),
/// so the pictures show the real letters and icons instead of the test font's
/// boxes. Call it once, in `setUpAll`.
Future<void> loadAppFonts() async {
  final materialIcons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await materialIcons.load();
  final lucideIcons = FontLoader('packages/lucide_icons_flutter/Lucide')
    ..addFont(
      rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
    );
  await lucideIcons.load();
  // The heavier stroke of the selected destination of the navigation bar.
  final lucideBold = FontLoader('packages/lucide_icons_flutter/Lucide600')
    ..addFont(
      rootBundle.load(
        'packages/lucide_icons_flutter/assets/build_font/LucideVariable-w600.ttf',
      ),
    );
  await lucideBold.load();

  const families = {
    'Inter': ['Inter-Regular', 'Inter-Medium', 'Inter-SemiBold'],
    'IBMPlexSansArabic': [
      'IBMPlexSansArabic-Regular',
      'IBMPlexSansArabic-Medium',
      'IBMPlexSansArabic-SemiBold',
    ],
  };
  for (final MapEntry(key: family, value: files) in families.entries) {
    final loader = FontLoader(family);
    for (final file in files) {
      loader.addFont(rootBundle.load('assets/fonts/$file.ttf'));
    }
    await loader.load();
  }
}

/// Wraps [child] so [saveScreenshot] can draw it. Put it around the app.
class RenderTarget extends StatelessWidget {
  const new({required this.boundaryKey, required this.child, super.key});

  final GlobalKey boundaryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(key: boundaryKey, child: child);
  }
}

/// Draws the [RenderTarget] with [boundaryKey] to `build/screens/[name].png`.
Future<void> saveScreenshot(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String name,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File('$renderDirectory/$name.png');
    // On a shared or scanned drive a picture can be locked for a moment, for
    // example while an editor shows it: try a few times.
    for (var attempt = 1; ; attempt++) {
      try {
        await file.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        break;
      } on FileSystemException {
        if (attempt == 5) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
    }
    image.dispose();
  });
}
