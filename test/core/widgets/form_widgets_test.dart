import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/theme/app_theme.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/l10n/l10n.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/widgets/amount_field.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/month_picker_sheet.dart';
import 'package:money_scribe/core/widgets/state_view.dart';

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
