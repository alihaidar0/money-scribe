import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/app/theme/app_typography.dart';

List<TextStyle> _styles(TextTheme textTheme) {
  return [
    textTheme.displaySmall!,
    textTheme.headlineMedium!,
    textTheme.titleLarge!,
    textTheme.titleMedium!,
    textTheme.bodyLarge!,
    textTheme.bodyMedium!,
    textTheme.bodySmall!,
    textTheme.labelLarge!,
    textTheme.labelMedium!,
  ];
}

void main() {
  const arabic = Locale('ar');
  const english = Locale('en');

  group('the English screens', () {
    test('fall back to the Arabic font for Arabic letters', () {
      for (final style in _styles(AppTheme.light.textTheme)) {
        expect(style.fontFamily, AppTypography.fontFamily);
        expect(style.fontFamilyFallback, AppTypography.fontFamilyFallback);
      }
    });

    test('keep the theme unchanged', () {
      expect(AppTheme.forLocale(AppTheme.light, english), AppTheme.light);
      expect(AppTheme.forLocale(AppTheme.dark, english), AppTheme.dark);
    });
  });

  group('the Arabic screens', () {
    final light = AppTheme.forLocale(AppTheme.light, arabic);

    test('use the Arabic font for every style, with Inter as the fallback', () {
      for (final style in [
        ..._styles(light.textTheme),
        ..._styles(light.primaryTextTheme),
      ]) {
        expect(style.fontFamily, AppTypography.arabicFontFamily);
        expect(
          style.fontFamilyFallback,
          AppTypography.arabicFontFamilyFallback,
        );
      }
    });

    test('keep the sizes, heights and weights of the type scale', () {
      final inter = AppTheme.light.textTheme;
      final plex = light.textTheme;

      for (final (before, after) in [
        (inter.displaySmall!, plex.displaySmall!),
        (inter.titleLarge!, plex.titleLarge!),
        (inter.bodyLarge!, plex.bodyLarge!),
        (inter.labelLarge!, plex.labelLarge!),
        (inter.labelMedium!, plex.labelMedium!),
      ]) {
        expect(after.fontSize, before.fontSize);
        expect(after.height, before.height);
        expect(after.fontWeight, before.fontWeight);
      }
    });

    test('keep the colours and the dark theme', () {
      final dark = AppTheme.forLocale(AppTheme.dark, arabic);

      expect(light.colorScheme, AppTheme.light.colorScheme);
      expect(dark.colorScheme, AppTheme.dark.colorScheme);
      expect(
        dark.textTheme.bodyLarge!.fontFamily,
        AppTypography.arabicFontFamily,
      );
    });
  });
}
