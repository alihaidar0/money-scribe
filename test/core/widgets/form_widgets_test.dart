import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/state_view.dart';
import 'package:money_scribe/core/widgets/success_snack_bar.dart';

Widget _host(Widget child, {Locale locale = const Locale('en')}) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  group('AmountField', () {
    late TextEditingController controller;
    late List<String> changes;

    setUp(() {
      controller = TextEditingController(text: '100000.5');
      changes = [];
    });

    tearDown(() => controller.dispose());

    Widget field() {
      return _host(
        Column(
          children: [
            AmountField(
              controller: controller,
              label: 'Base salary',
              currency: Currency.rub,
              onChanged: changes.add,
            ),
            const TextField(key: Key('other')),
          ],
        ),
      );
    }

    testWidgets('shows the starting number grouped with every decimal', (
      tester,
    ) async {
      await tester.pumpWidget(field());

      expect(controller.text, '100,000.50');
      expect(find.text('₽'), findsOneWidget);
    });

    testWidgets('is plain while focused, grouped when it loses focus', (
      tester,
    ) async {
      await tester.pumpWidget(field());

      await tester.tap(find.widgetWithText(TextField, 'Base salary'));
      await tester.pump();
      expect(controller.text, '100000.50');

      await tester.enterText(
        find.widgetWithText(TextField, 'Base salary'),
        '2500.5',
      );
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();

      expect(controller.text, '2,500.50');
    });

    testWidgets('regrouping is not reported as a change', (tester) async {
      await tester.pumpWidget(field());

      await tester.tap(find.widgetWithText(TextField, 'Base salary'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();

      expect(changes, isEmpty);
    });

    testWidgets('only lets an amount be typed', (tester) async {
      await tester.pumpWidget(field());
      final finder = find.widgetWithText(TextField, 'Base salary');

      await tester.tap(finder);
      await tester.pump();
      await tester.enterText(finder, '12a');
      await tester.pump();
      expect(controller.text, '100000.50');

      await tester.enterText(finder, '١٢٫٥');
      await tester.pump();
      expect(controller.text, '12.5');
      expect(changes.last, '12.5');
    });

    testWidgets('keeps the symbol after the number in both directions', (
      tester,
    ) async {
      InputDecoration decoration() => tester
          .widget<TextField>(find.widgetWithText(TextField, 'Base salary'))
          .decoration!;

      await tester.pumpWidget(field());
      expect(decoration().suffixText, '₽');
      expect(decoration().prefixText, isNull);

      // In a right-to-left screen the start of the field is its right side,
      // which is the one after a number read left to right.
      await tester.pumpWidget(
        _host(
          AmountField(
            controller: controller,
            label: 'Base salary',
            currency: Currency.rub,
          ),
          locale: const Locale('ar'),
        ),
      );
      expect(decoration().prefixText, '₽');
      expect(decoration().suffixText, isNull);
      expect(
        tester
            .widget<TextField>(find.widgetWithText(TextField, 'Base salary'))
            .textDirection,
        TextDirection.ltr,
      );
    });

    testWidgets('leaves text that is not an amount alone', (tester) async {
      controller.text = '';
      await tester.pumpWidget(field());

      await tester.tap(find.widgetWithText(TextField, 'Base salary'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('other')));
      await tester.pump();

      expect(controller.text, isEmpty);
    });
  });

  group('showSuccessSnackBar', () {
    Future<void> show(WidgetTester tester, ThemeData theme) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showSuccessSnackBar(context, 'Done it'),
                child: const Text('Show'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Show'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    testWidgets('is green with a check, and has no action', (tester) async {
      await show(tester, AppTheme.light);

      expect(find.text('Done it'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, MoneyColors.light.income.container);
      expect(
        tester.widget<Text>(find.text('Done it')).style!.color,
        MoneyColors.light.income.onContainer,
      );
    });

    testWidgets('follows the dark theme', (tester) async {
      await show(tester, AppTheme.dark);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.backgroundColor, MoneyColors.dark.income.container);
    });

    testWidgets('stays for two seconds', (tester) async {
      await show(tester, AppTheme.light);
      expect(successSnackBarDuration, const Duration(seconds: 2));

      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Done it'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Done it'), findsNothing);
    });

    testWidgets('replaces the message that is showing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Column(
                children: [
                  TextButton(
                    onPressed: () => showSuccessSnackBar(context, 'First'),
                    child: const Text('One'),
                  ),
                  TextButton(
                    onPressed: () => showSuccessSnackBar(context, 'Second'),
                    child: const Text('Two'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('One'));
      await tester.pump();
      await tester.tap(find.text('Two'));
      await tester.pumpAndSettle();

      expect(find.text('First'), findsNothing);
      expect(find.text('Second'), findsOneWidget);
    });
  });

  group('MonthChip', () {
    testWidgets('shows the month and opens on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _host(
          Center(
            child: MonthChip(
              month: const YearMonth(2026, 10),
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsOneWidget);

      await tester.tap(find.byType(MonthChip));
      expect(taps, 1);
    });

    testWidgets('has a spoken label and a touch target of 48 dp', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Center(
            child: MonthChip(
              month: const YearMonth(2026, 10),
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('October 2026, choose month'),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(MonthChip)).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('a MonthChip that only shows the month', () {
    testWidgets('has no chevron and does not react to a tap', (tester) async {
      await tester.pumpWidget(
        _host(const Center(child: MonthChip(month: YearMonth(2026, 9)))),
      );

      expect(find.text('September 2026'), findsOneWidget);
      expect(find.byIcon(Icons.expand_more), findsNothing);
      expect(tester.widget<InkWell>(find.byType(InkWell)).onTap, isNull);
      // It is read as plain text, not as a button.
      expect(find.bySemanticsLabel('September 2026'), findsOneWidget);
      expect(
        find.bySemanticsLabel('September 2026, choose month'),
        findsNothing,
      );
    });
  });

  group('the month picker', () {
    Future<void> open(
      WidgetTester tester,
      List<YearMonth?> results, {
      Locale locale = const Locale('en'),
    }) async {
      await tester.pumpWidget(
        _host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => results.add(
                await showMonthPickerSheet(
                  context,
                  selected: const YearMonth(2026, 10),
                  last: const YearMonth(2026, 10),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
          locale: locale,
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
    }

    testWidgets('offers the last three years, none of them in the future', (
      tester,
    ) async {
      await open(tester, []);

      for (final year in ['2024', '2025', '2026']) {
        expect(find.text(year), findsOneWidget);
      }
      expect(find.text('2027'), findsNothing);
    });

    testWidgets('stops the current year at the current month', (tester) async {
      await open(tester, []);

      expect(find.text('Jan'), findsOneWidget);
      expect(find.text('Oct'), findsOneWidget);
      expect(find.text('Nov'), findsNothing);
      expect(find.text('Dec'), findsNothing);
    });

    testWidgets('an earlier year has all twelve months', (tester) async {
      await open(tester, []);

      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();

      expect(find.text('Nov'), findsOneWidget);
      expect(find.text('Dec'), findsOneWidget);
    });

    testWidgets('going back to the current year keeps a month that exists', (
      tester,
    ) async {
      final results = <YearMonth?>[];
      await open(tester, results);

      await tester.tap(find.text('2025'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dec'));
      await tester.tap(find.text('2026'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results, [const YearMonth(2026, 10)]);
    });

    testWidgets('Done answers with the chosen year and month', (tester) async {
      final results = <YearMonth?>[];
      await open(tester, results);

      await tester.tap(find.text('2025'));
      await tester.tap(find.text('Mar'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results, [const YearMonth(2025, 3)]);
    });

    testWidgets('Done without a change answers with the same month', (
      tester,
    ) async {
      final results = <YearMonth?>[];
      await open(tester, results);

      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(results, [const YearMonth(2026, 10)]);
    });

    testWidgets('dismissing it answers null', (tester) async {
      final results = <YearMonth?>[];
      await open(tester, results);

      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(results, [null]);
    });

    testWidgets('names the months in Arabic with Western digits', (
      tester,
    ) async {
      await open(tester, [], locale: const Locale('ar'));

      expect(find.text('2026'), findsOneWidget);
      expect(find.text('أكتوبر'), findsOneWidget);
      expect(find.text('تم'), findsOneWidget);
    });

    testWidgets('the months are spoken in full', (tester) async {
      await open(tester, []);

      expect(find.bySemanticsLabel('October'), findsOneWidget);
    });
  });

  group('FailureView', () {
    testWidgets('can say what could not be done instead of the usual words', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FailureView(
            kind: FailureKind.error,
            errorTitle: 'Could not load',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('Could not load'), findsOneWidget);
      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Please try again in a moment.'), findsNothing);
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('can show its action as a filled button', (tester) async {
      await tester.pumpWidget(
        _host(
          StateView(
            icon: Icons.history,
            title: 'Nothing yet',
            actionLabel: 'Start',
            filledAction: true,
            onAction: () {},
          ),
        ),
      );

      expect(find.widgetWithText(FilledButton, 'Start'), findsOneWidget);
      expect(find.text('Nothing yet'), findsOneWidget);
    });

    testWidgets('keeps the usual words for no connection', (tester) async {
      await tester.pumpWidget(
        _host(
          FailureView(
            kind: FailureKind.noConnection,
            errorTitle: 'Could not load',
            onRetry: () {},
          ),
        ),
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(find.text('Could not load'), findsNothing);
    });
  });
}
