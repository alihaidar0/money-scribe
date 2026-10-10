import 'package:flutter/material.dart';
import 'package:money_scribe/app/theme/app_color_schemes.dart';
import 'package:money_scribe/app/theme/app_typography.dart';
import 'package:money_scribe/app/theme/money_colors.dart';

/// The Material 3 themes of Money Scribe, built from `docs/DESIGN.md`.
abstract final class AppTheme {
  static final ThemeData light = _build(
    AppColorSchemes.light,
    MoneyColors.light,
  );

  static final ThemeData dark = _build(AppColorSchemes.dark, MoneyColors.dark);

  /// [theme] for the language shown: Arabic switches the type scale to the
  /// Arabic font, every other language keeps [theme] unchanged.
  static ThemeData forLocale(ThemeData theme, Locale locale) {
    if (locale.languageCode != 'ar') {
      return theme;
    }
    return theme.copyWith(
      textTheme: theme.textTheme.arabic,
      primaryTextTheme: theme.primaryTextTheme.arabic,
    );
  }

  static ThemeData _build(ColorScheme scheme, MoneyColors moneyColors) {
    const pill = StadiumBorder();
    const card = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    );
    const dialog = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(28)),
    );
    const fieldRadius = BorderRadius.all(Radius.circular(12));
    const topSheet = RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    );
    const buttonStyle = ButtonStyle(
      minimumSize: WidgetStatePropertyAll(Size(64, 48)),
      shape: WidgetStatePropertyAll(pill),
    );

    OutlineInputBorder fieldBorder(Color color, {double width = 1}) {
      return OutlineInputBorder(
        borderRadius: fieldRadius,
        borderSide: BorderSide(color: color, width: width),
      );
    }

    return ThemeData(
      colorScheme: scheme,
      fontFamily: AppTypography.fontFamily,
      fontFamilyFallback: AppTypography.fontFamilyFallback,
      textTheme: AppTypography.textTheme,
      scaffoldBackgroundColor: scheme.surface,
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      extensions: [moneyColors],
      appBarTheme: const AppBarTheme(centerTitle: false),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        shape: card,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: dialog,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        shape: topSheet,
      ),
      filledButtonTheme: const FilledButtonThemeData(style: buttonStyle),
      outlinedButtonTheme: const OutlinedButtonThemeData(style: buttonStyle),
      textButtonTheme: const TextButtonThemeData(style: buttonStyle),
      elevatedButtonTheme: const ElevatedButtonThemeData(style: buttonStyle),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        shape: card,
      ),
      chipTheme: const ChipThemeData(shape: pill),
      navigationBarTheme: const NavigationBarThemeData(indicatorShape: pill),
      navigationRailTheme: const NavigationRailThemeData(indicatorShape: pill),
      inputDecorationTheme: InputDecorationTheme(
        border: fieldBorder(scheme.outline),
        enabledBorder: fieldBorder(scheme.outline),
        focusedBorder: fieldBorder(scheme.primary, width: 2),
        errorBorder: fieldBorder(scheme.error),
        focusedErrorBorder: fieldBorder(scheme.error, width: 2),
        disabledBorder: fieldBorder(scheme.onSurface.withValues(alpha: 0.12)),
      ),
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHigh),
        elevation: const WidgetStatePropertyAll(0),
        shape: const WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: fieldRadius),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.surfaceContainerHighest,
        linearMinHeight: 4,
      ),
    );
  }
}
