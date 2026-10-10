import 'package:flutter/material.dart';

/// The type scale of `docs/DESIGN.md` (section 3): Inter, bundled with the app
/// (weights 400, 500 and 600). Styles not listed there keep the Material 3
/// defaults and only switch to Inter.
///
/// Arabic text uses IBM Plex Sans Arabic (`docs/DESIGN.md`, section 3.1),
/// bundled in the same weights. The two fonts back each other up: Inter text
/// falls back to the Arabic font for Arabic letters, and Arabic text falls
/// back to Inter for letters the Arabic font lacks, such as Cyrillic.
abstract final class AppTypography {
  static const fontFamily = 'Inter';
  static const arabicFontFamily = 'IBMPlexSansArabic';

  /// Fonts tried after Inter, for Arabic letters in an English screen.
  static const List<String> fontFamilyFallback = [arabicFontFamily];

  /// Fonts tried after the Arabic font, for letters it lacks.
  static const List<String> arabicFontFamilyFallback = [fontFamily];

  static const textTheme = TextTheme(
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      height: 44 / 36,
      fontWeight: FontWeight.w600,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 28,
      height: 36 / 28,
      fontWeight: FontWeight.w600,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      height: 28 / 22,
      fontWeight: FontWeight.w600,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w600,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 16,
      height: 24 / 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 14,
      height: 20 / 14,
      fontWeight: FontWeight.w600,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 12,
      height: 16 / 12,
      fontWeight: FontWeight.w500,
    ),
  );
}

extension ArabicTextTheme on TextTheme {
  /// This scale in the Arabic font, keeping every size, height and weight.
  TextTheme get arabic {
    return apply(
      fontFamily: AppTypography.arabicFontFamily,
      fontFamilyFallback: AppTypography.arabicFontFamilyFallback,
    );
  }
}

extension AmountTextStyle on TextStyle {
  /// Fixed-width figures, so amounts line up in columns. Use it for every
  /// amount.
  TextStyle get amount {
    return copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
