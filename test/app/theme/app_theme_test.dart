import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_color_schemes.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/app/theme/app_typography.dart';

void main() {
  group('colours', () {
    test('the light theme uses the light scheme', () {
      expect(AppTheme.light.colorScheme, AppColorSchemes.light);
      expect(AppTheme.light.brightness, Brightness.light);
    });

    test('the dark theme uses the dark scheme', () {
      expect(AppTheme.dark.colorScheme, AppColorSchemes.dark);
      expect(AppTheme.dark.brightness, Brightness.dark);
    });

    test('screens sit on the surface colour', () {
      expect(
        AppTheme.light.scaffoldBackgroundColor,
        AppColorSchemes.light.surface,
      );
      expect(
        AppTheme.dark.scaffoldBackgroundColor,
        AppColorSchemes.dark.surface,
      );
    });
  });

  group('typography', () {
    final textTheme = AppTheme.light.textTheme;

    test('every style, listed or not, uses Inter', () {
      for (final style in [
        textTheme.displaySmall,
        textTheme.titleLarge,
        textTheme.bodyLarge,
        textTheme.labelMedium,
        textTheme.bodySmall,
        textTheme.headlineLarge,
      ]) {
        expect(style!.fontFamily, AppTypography.fontFamily);
      }
    });

    test('text takes the on-surface colour of the scheme', () {
      expect(textTheme.bodyLarge!.color, AppColorSchemes.light.onSurface);
      expect(
        AppTheme.dark.textTheme.bodyLarge!.color,
        AppColorSchemes.dark.onSurface,
      );
    });

    test('the hero amount is 36/44 at weight 600', () {
      final style = textTheme.displaySmall!;

      expect(style.fontSize, 36);
      expect(style.fontSize! * style.height!, closeTo(44, 0.001));
      expect(style.fontWeight, FontWeight.w600);
    });

    test('buttons use label large at weight 600', () {
      expect(textTheme.labelLarge!.fontSize, 14);
      expect(textTheme.labelLarge!.fontWeight, FontWeight.w600);
    });

    test('amount turns on tabular figures', () {
      final style = textTheme.titleMedium!.amount;

      expect(style.fontFeatures, contains(const FontFeature.tabularFigures()));
      expect(style.fontSize, textTheme.titleMedium!.fontSize);
    });
  });

  group('shape', () {
    final theme = AppTheme.light;

    RoundedRectangleBorder rounded(ShapeBorder? shape) =>
        shape! as RoundedRectangleBorder;

    test('cards are flat, tonal and 16 dp round', () {
      expect(theme.cardTheme.elevation, 0);
      expect(theme.cardTheme.color, AppColorSchemes.light.surfaceContainerLow);
      expect(
        rounded(theme.cardTheme.shape).borderRadius,
        BorderRadius.circular(16),
      );
    });

    test('dialogs are 28 dp round', () {
      expect(
        rounded(theme.dialogTheme.shape).borderRadius,
        BorderRadius.circular(28),
      );
    });

    test('bottom sheets are 28 dp round on top', () {
      expect(
        rounded(theme.bottomSheetTheme.shape).borderRadius,
        const BorderRadius.vertical(top: Radius.circular(28)),
      );
    });

    test('the floating action button is 16 dp round', () {
      expect(
        rounded(theme.floatingActionButtonTheme.shape).borderRadius,
        BorderRadius.circular(16),
      );
    });

    test('chips and navigation indicators are pills', () {
      expect(theme.chipTheme.shape, const StadiumBorder());
      expect(theme.navigationBarTheme.indicatorShape, const StadiumBorder());
      expect(theme.navigationRailTheme.indicatorShape, const StadiumBorder());
    });

    test('text fields are 12 dp round in every state', () {
      final decoration = theme.inputDecorationTheme;

      for (final border in [
        decoration.border,
        decoration.enabledBorder,
        decoration.focusedBorder,
        decoration.errorBorder,
        decoration.focusedErrorBorder,
        decoration.disabledBorder,
      ]) {
        expect(
          (border! as OutlineInputBorder).borderRadius,
          BorderRadius.circular(12),
        );
      }
    });

    test('the progress bar is 4 dp tall', () {
      expect(theme.progressIndicatorTheme.linearMinHeight, 4);
    });

    test('dividers are 1 dp in the outline variant colour', () {
      expect(theme.dividerTheme.thickness, 1);
      expect(theme.dividerTheme.color, AppColorSchemes.light.outlineVariant);
    });

    test('app bar titles are left-aligned', () {
      expect(theme.appBarTheme.centerTitle, isFalse);
    });
  });

  group('buttons', () {
    for (final (name, build) in <(String, Widget Function())>[
      ('filled', () => FilledButton(onPressed: () {}, child: const Text('Go'))),
      (
        'outlined',
        () => OutlinedButton(onPressed: () {}, child: const Text('Go')),
      ),
      ('text', () => TextButton(onPressed: () {}, child: const Text('Go'))),
    ]) {
      testWidgets('the $name button is a pill at least 48 dp tall', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(body: Center(child: build())),
          ),
        );

        final button = find.byWidgetPredicate(
          (widget) => widget is ButtonStyleButton,
        );
        final material = tester.widget<Material>(
          find.descendant(of: button, matching: find.byType(Material)),
        );

        expect(tester.getSize(button).height, greaterThanOrEqualTo(48));
        expect(material.shape, isA<StadiumBorder>());
      });
    }
  });
}
