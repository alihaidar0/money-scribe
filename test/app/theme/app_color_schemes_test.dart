import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_color_schemes.dart';

import 'design_file_parser.dart';

Map<String, Color> _roles(ColorScheme scheme) => {
  'primary': scheme.primary,
  'onPrimary': scheme.onPrimary,
  'primaryContainer': scheme.primaryContainer,
  'onPrimaryContainer': scheme.onPrimaryContainer,
  'secondary': scheme.secondary,
  'onSecondary': scheme.onSecondary,
  'secondaryContainer': scheme.secondaryContainer,
  'onSecondaryContainer': scheme.onSecondaryContainer,
  'tertiary': scheme.tertiary,
  'onTertiary': scheme.onTertiary,
  'tertiaryContainer': scheme.tertiaryContainer,
  'onTertiaryContainer': scheme.onTertiaryContainer,
  'error': scheme.error,
  'onError': scheme.onError,
  'errorContainer': scheme.errorContainer,
  'onErrorContainer': scheme.onErrorContainer,
  'surface': scheme.surface,
  'onSurface': scheme.onSurface,
  'onSurfaceVariant': scheme.onSurfaceVariant,
  'outline': scheme.outline,
  'outlineVariant': scheme.outlineVariant,
  'surfaceDim': scheme.surfaceDim,
  'surfaceBright': scheme.surfaceBright,
  'surfaceContainerLowest': scheme.surfaceContainerLowest,
  'surfaceContainerLow': scheme.surfaceContainerLow,
  'surfaceContainer': scheme.surfaceContainer,
  'surfaceContainerHigh': scheme.surfaceContainerHigh,
  'surfaceContainerHighest': scheme.surfaceContainerHighest,
  'inverseSurface': scheme.inverseSurface,
  'inverseOnSurface': scheme.onInverseSurface,
  'inversePrimary': scheme.inversePrimary,
};

void main() {
  final rows = designColorRows(2);
  final light = _roles(AppColorSchemes.light);
  final dark = _roles(AppColorSchemes.dark);

  test('the schemes have the brightness they are named after', () {
    expect(AppColorSchemes.light.brightness, Brightness.light);
    expect(AppColorSchemes.dark.brightness, Brightness.dark);
  });

  test('every colour role of DESIGN.md is in the schemes', () {
    // Flutter has deprecated surfaceVariant, so the schemes leave it out.
    expect(
      rows.keys.toSet().difference({'surfaceVariant'}),
      light.keys.toSet(),
    );
  });

  for (final MapEntry(key: role, value: colors) in rows.entries) {
    if (role == 'surfaceVariant') continue;

    test('$role matches DESIGN.md in light mode', () {
      expect(light[role]!.toARGB32(), colors[0].toARGB32());
    });

    test('$role matches DESIGN.md in dark mode', () {
      expect(dark[role]!.toARGB32(), colors[1].toARGB32());
    });
  }
}
