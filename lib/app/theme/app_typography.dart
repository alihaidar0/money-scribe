import 'package:flutter/material.dart';

/// The type scale of `docs/DESIGN.md` (section 3): Inter, bundled with the app
/// (weights 400, 500 and 600). Styles not listed there keep the Material 3
/// defaults and only switch to Inter.
abstract final class AppTypography {
  static const fontFamily = 'Inter';

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

extension AmountTextStyle on TextStyle {
  /// Fixed-width figures, so amounts line up in columns. Use it for every
  /// amount.
  TextStyle get amount {
    return copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
  }
}
