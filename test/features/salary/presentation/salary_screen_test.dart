import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/app/shell/floating_navigation_bar.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/theme/money_colors.dart';
import 'package:money_scribe/core/widgets/month_chip.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/salary/data/fake/fake_salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_repository.dart';
import 'package:money_scribe/features/salary/domain/salary_result.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_history_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/fake_server_salary_repository.dart';
import '../../../support/navigation_tab.dart';

const _nbsp = '\u00a0';
const _october = YearMonth(2026, 10);
const _tallPhone = Size(412, 1800);

late DemoController _demo;

/// Opens the app signed in and goes to the Salary tab.
Future<void> _pumpSalary(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = _tallPhone,
  Duration latency = Duration.zero,
  SalaryRepository? salaryRepository,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  _demo = DemoController(initial: settings, latency: latency);
  await tester.pumpWidget(
    buildApp(
      demo: _demo,
      salaryRepository: salaryRepository,
      languageRepository: FakeLanguageRepository(language),
      authRepository: FakeAuthRepository(demo: _demo, signedIn: true),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(
    navigationTab(language == AppLanguage.arabic ? 'الراتب' : 'Salary'),
  );
  await tester.pumpAndSettle();
}

/// Amounts have a no-break space before the currency symbol.
String _amount(String text) => text.replaceAll(' ₽', '$_nbsp₽');

Finder _text(String text) {
  return find.textContaining(_amount(text), findRichText: true);
}

Finder _field(String label) => find.widgetWithText(TextField, label);

String _fieldText(WidgetTester tester, String label) {
  return tester.widget<TextField>(_field(label)).controller!.text;
}

Finder get _save => find.widgetWithText(FilledButton, 'Save month');

bool _isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<FilledButton>(button).onPressed != null;
}

void main() {
  group('one payment (SAL-1)', () {
    testWidgets('shows the total, the results and the inputs', (tester) async {
      await _pumpSalary(tester);

      expect(find.byType(SalaryScreen), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Total after tax'), findsOneWidget);
      expect(_text('104,400.00 ₽'), findsOneWidget);
      expect(find.text('Food allowance'), findsOneWidget);
      expect(find.text('20 days × 500.00$_nbsp₽'), findsOneWidget);
      expect(_text('+10,000.00 ₽'), findsNWidgets(2));
      expect(find.text('8 extra hours'), findsOneWidget);
      expect(_text('120,000.00 ₽'), findsOneWidget);
      expect(find.text('Tax (13%)'), findsOneWidget);
      expect(_text('−15,600.00 ₽'), findsOneWidget);
      expect(_isEnabled(tester, _save), isTrue);
    });

    testWidgets('shows the saved numbers in the fields', (tester) async {
      await _pumpSalary(tester);

      expect(_fieldText(tester, 'Base salary'), '100,000.00');
      expect(_fieldText(tester, 'Working days in the month'), '20');
      expect(_fieldText(tester, 'Food allowance per day'), '500.00');
      expect(_fieldText(tester, 'Working hours in the month'), '160');
      expect(_fieldText(tester, 'Extra hours'), '8');
      expect(_fieldText(tester, 'Tax rate'), '13');
    });

    testWidgets('has no part cells and no first-half field', (tester) async {
      await _pumpSalary(tester);

      expect(find.textContaining('paid 20 Oct'), findsNothing);
      expect(_field('Working days, 1st–15th'), findsNothing);
      expect(find.text('Part 1 is paid on day 20'), findsNothing);
    });

    testWidgets('shows the five tabs with Salary selected', (tester) async {
      await _pumpSalary(tester);

      final bar = tester.widget<FloatingNavigationBar>(
        find.byType(FloatingNavigationBar),
      );
      expect(bar.selectedIndex, 1);
    });
  });

  group('two payments (SAL-2)', () {
    testWidgets('shows the pay of each part and its day', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('Part 1 · paid 20 Oct'), findsOneWidget);
      expect(find.text('Part 2 · paid 5 Nov'), findsOneWidget);
      expect(_text('43,500.00 ₽'), findsOneWidget);
      expect(_text('60,900.00 ₽'), findsOneWidget);
      expect(_text('104,400.00 ₽'), findsOneWidget);
    });

    testWidgets('asks for the first-half days and says the pay days', (
      tester,
    ) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(_fieldText(tester, 'Working days, 1st–15th'), '10');
      expect(find.text('Part 1 is paid on day 20'), findsOneWidget);
      expect(
        find.text('Part 2 is paid on day 5 of the next month'),
        findsOneWidget,
      );
    });

    testWidgets('typing the first-half days changes the parts', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      await tester.enterText(_field('Working days, 1st–15th'), '12');
      await tester.pumpAndSettle();

      // 12 of 20 days of the taxed base salary, and the rest: 52,200.00 each.
      expect(_text('52,200.00 ₽'), findsNWidgets(2));
    });
  });

  group('typing', () {
    testWidgets('calculates again with every change', (tester) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Extra hours'), '4');
      await tester.pumpAndSettle();

      expect(_text('100,050.00 ₽'), findsOneWidget);
      expect(find.text('4 extra hours'), findsOneWidget);
      expect(_text('+5,000.00 ₽'), findsOneWidget);
    });

    testWidgets('accepts a decimal number of extra hours and tax rate', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Extra hours'), '7.5');
      await tester.enterText(_field('Tax rate'), '13,5');
      await tester.pumpAndSettle();

      expect(find.text('7.5 extra hours'), findsOneWidget);
      expect(find.text('Tax (13.5%)'), findsOneWidget);
    });

    testWidgets('refuses letters and a third decimal', (tester) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Extra hours'), '4a');
      expect(_fieldText(tester, 'Extra hours'), '8');

      // A field being edited holds the plain number.
      await tester.enterText(_field('Base salary'), '1.234');
      expect(_fieldText(tester, 'Base salary'), '100000.00');
    });

    testWidgets('an amount is plain while edited and grouped after', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.tap(_field('Base salary'));
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'Base salary'), '100000.00');

      await tester.enterText(_field('Base salary'), '120000');
      await tester.pumpAndSettle();
      // The extra hours are paid at twice 120,000 / 160 an hour.
      expect(_text('+12,000.00 ₽'), findsOneWidget);

      await tester.tap(_field('Extra hours'));
      await tester.pumpAndSettle();
      expect(_fieldText(tester, 'Base salary'), '120,000.00');
    });

    testWidgets('clearing a required field empties the results', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Base salary'), '');
      await tester.pumpAndSettle();

      expect(
        find.text('Fill in the inputs to see the results.'),
        findsOneWidget,
      );
      expect(_text('0.00 ₽'), findsWidgets);
      expect(_isEnabled(tester, _save), isFalse);
    });

    testWidgets('a number out of range shows its error and blocks saving', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Working days in the month'), '40');
      await tester.enterText(_field('Tax rate'), '120');
      await tester.pumpAndSettle();

      expect(find.text('Enter a number from 1 to 31.'), findsOneWidget);
      expect(find.text('Enter a number from 0 to 100.'), findsOneWidget);
      expect(
        find.text('Fill in the inputs to see the results.'),
        findsOneWidget,
      );
      expect(_isEnabled(tester, _save), isFalse);
    });

    testWidgets('first-half days above the month show their error', (
      tester,
    ) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      await tester.enterText(_field('Working days, 1st–15th'), '25');
      await tester.pumpAndSettle();

      expect(
        find.text("Can't be more than the working days in the month."),
        findsOneWidget,
      );
      expect(_isEnabled(tester, _save), isFalse);
    });

    testWidgets('the empty fields show their 0 hint and the label above', (
      tester,
    ) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      final field = tester.widget<TextField>(_field('Base salary'));
      expect(field.decoration!.hintText, '0');
      expect(
        field.decoration!.floatingLabelBehavior,
        FloatingLabelBehavior.always,
      );
    });
  });

  group('the figures the server calculated', () {
    /// The server's food allowance is a ruble more than the app's, so the
    /// two can be told apart on screen.
    FakeServerSalaryRepository serverSalary({
      DemoSettings settings = const DemoSettings(),
    }) {
      final inner = FakeSalaryRepository(
        demo: DemoController(initial: settings, latency: Duration.zero),
      );
      return FakeServerSalaryRepository(inner)
        ..resultOf = (result) => SalaryResult(
          foodAllowance: result.foodAllowance + const Money(100, Currency.rub),
          extraHoursPay: result.extraHoursPay,
          incomeBeforeTax: result.incomeBeforeTax,
          tax: result.tax,
          totalAfterTax: result.totalAfterTax,
          payments: result.payments,
        );
    }

    testWidgets('a saved month shows the lines the server calculated', (
      tester,
    ) async {
      await _pumpSalary(tester, salaryRepository: serverSalary());

      expect(_text('+10,001.00 ₽'), findsOneWidget);
      expect(_text('104,400.00 ₽'), findsOneWidget);
      expect(find.text('Saved total'), findsNothing);
    });

    testWidgets('typing shows the live lines, with the saved total', (
      tester,
    ) async {
      await _pumpSalary(tester, salaryRepository: serverSalary());

      await tester.enterText(_field('Extra hours'), '4');
      await tester.pumpAndSettle();

      // What is typed is calculated here: the server's ruble is gone.
      expect(_text('+10,001.00 ₽'), findsNothing);
      expect(_text('100,050.00 ₽'), findsOneWidget);
      expect(find.text('Saved total'), findsOneWidget);
      expect(_text('104,400.00 ₽'), findsOneWidget);
    });

    testWidgets('saving shows what the server calculated for it', (
      tester,
    ) async {
      await _pumpSalary(tester, salaryRepository: serverSalary());
      await tester.enterText(_field('Extra hours'), '4');
      await tester.pumpAndSettle();

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(find.text('Month saved'), findsOneWidget);
      expect(_text('+10,001.00 ₽'), findsOneWidget);
      expect(_text('100,050.00 ₽'), findsOneWidget);
      expect(find.text('Saved total'), findsNothing);
    });

    testWidgets('a month that is not saved has no saved total', (tester) async {
      const empty = DemoSettings(scenario: DemoScenario.empty);
      await _pumpSalary(
        tester,
        salaryRepository: serverSalary(settings: empty),
        settings: empty,
      );

      await tester.enterText(_field('Extra hours'), '4');
      await tester.pumpAndSettle();

      expect(find.text('Saved total'), findsNothing);
    });

    testWidgets('the saved total is in Arabic', (tester) async {
      await _pumpSalary(
        tester,
        salaryRepository: serverSalary(),
        language: AppLanguage.arabic,
      );

      await tester.enterText(_field('الساعات الإضافية'), '4');
      await tester.pumpAndSettle();

      expect(find.text('الإجمالي المحفوظ'), findsOneWidget);
    });
  });

  group('saving (SAL-10)', () {
    testWidgets('a month changed on another device is not replaced', (
      tester,
    ) async {
      final demo = DemoController(latency: Duration.zero);
      final repository = FakeSalaryRepository(demo: demo);
      await _pumpSalary(tester, salaryRepository: repository);
      // Another device saves the month first.
      await repository.save((await repository.month(_october))!);

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(
        find.text('This month was changed on another device.'),
        findsOneWidget,
      );
      expect(find.text('Month saved'), findsNothing);
      expect(find.text('Load latest'), findsOneWidget);

      await tester.tap(find.text('Load latest'));
      await tester.pumpAndSettle();

      expect(_isEnabled(tester, _save), isTrue);
    });

    testWidgets('says the month was saved, in green, with no action', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(find.text('Month saved'), findsOneWidget);
      expect(find.byType(SnackBarAction), findsNothing);
      expect(find.text('View history'), findsNothing);
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      final income = tester
          .widget<MaterialApp>(find.byType(MaterialApp))
          .theme!
          .extension<MoneyColors>()!
          .income;
      expect(snackBar.backgroundColor, income.container);
      expect(snackBar.duration, const Duration(seconds: 2));
    });

    testWidgets('the message goes away after two seconds', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(_save);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('Month saved'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 2500));
      await tester.pumpAndSettle();

      expect(find.text('Month saved'), findsNothing);
    });

    testWidgets('shows a spinner while the server answers', (tester) async {
      await _pumpSalary(tester, latency: const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      await tester.tap(_save);
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton).last).onPressed,
        isNull,
      );

      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('a saved correction is what the month shows again', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.enterText(_field('Extra hours'), '4');
      await tester.tap(_save);
      await tester.pumpAndSettle();

      // Leave the tab and come back: the Bloc is kept, so go to another month
      // and back to load it from the server.
      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sep'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oct'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(_text('100,050.00 ₽'), findsOneWidget);
    });
  });

  group('when saving fails (ERR-1)', () {
    testWidgets('keeps the form and offers Retry', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(save: DemoSave.fails),
      );
      await tester.enterText(_field('Extra hours'), '4');

      await tester.tap(_save);
      await tester.pumpAndSettle();

      expect(
        find.text("Couldn't save. Check your connection."),
        findsOneWidget,
      );
      expect(find.text('Month saved'), findsNothing);
      expect(_fieldText(tester, 'Extra hours'), '4');
      expect(_isEnabled(tester, _save), isTrue);

      _demo.update(_demo.settings.copyWith(save: DemoSave.accepted));
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Month saved'), findsOneWidget);
    });
  });

  group('payments per month (SAL-4, SAL-5)', () {
    testWidgets('asks before splitting a saved month', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.text('Two payments'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to two payments?'), findsOneWidget);
      expect(
        find.text(
          'October 2026 will be split into Part 1 (1st–15th) and Part 2 '
          '(16th–end). Its fixed items stay in Part 1 until you move them.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(find.text('Part 1 · paid 20 Oct'), findsOneWidget);
      expect(_text('43,500.00 ₽'), findsOneWidget);
      expect(_field('Working days, 1st–15th'), findsOneWidget);
    });

    testWidgets('Cancel keeps the month as it was', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.text('Two payments'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to two payments?'), findsNothing);
      expect(find.textContaining('paid 20 Oct'), findsNothing);
    });

    testWidgets('asks before merging a saved month', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      await tester.tap(find.text('One payment'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to one payment?'), findsOneWidget);
      expect(
        find.text(
          'October 2026 will have a single payment. The two pay amounts '
          'become one total, and the fixed items of Part 1 and Part 2 move '
          'into one list.',
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      expect(find.textContaining('paid 20 Oct'), findsNothing);
      expect(_field('Working days, 1st–15th'), findsNothing);
    });

    testWidgets('a new month switches without asking', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      await tester.tap(find.text('Two payments'));
      await tester.pumpAndSettle();

      expect(find.text('Switch to two payments?'), findsNothing);
      expect(_field('Working days, 1st–15th'), findsOneWidget);
    });
  });

  group('the month picker (SAL-3)', () {
    testWidgets('lists the years and the months, with this month chosen', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();

      expect(find.text('Choose month'), findsOneWidget);
      for (final year in ['2024', '2025', '2026']) {
        expect(find.text(year), findsOneWidget);
      }
      for (final month in ['Jan', 'Jun', 'Oct']) {
        expect(find.text(month), findsOneWidget);
      }
      // Nothing after the month of today.
      expect(find.text('2027'), findsNothing);
      expect(find.text('Nov'), findsNothing);
      expect(find.text('Dec'), findsNothing);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('Done loads the chosen month', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sep'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(_text('100,050.00 ₽'), findsOneWidget);
    });

    testWidgets('a month with nothing saved starts empty', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tap(find.text('2025'));
      await tester.tap(find.text('Done'));
      await tester.pumpAndSettle();

      expect(find.text('October 2025'), findsOneWidget);
      expect(
        find.text('Fill in the inputs to see the results.'),
        findsOneWidget,
      );
      expect(_isEnabled(tester, _save), isFalse);
    });

    testWidgets('dismissing it changes nothing', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.byType(MonthChip));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(200, 100));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Choose month'), findsNothing);
    });
  });

  group('a new empty month (SAL-11)', () {
    testWidgets('asks for the inputs and cannot be saved', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(
        find.text('Fill in the inputs to see the results.'),
        findsOneWidget,
      );
      expect(_text('0.00 ₽'), findsOneWidget);
      expect(_fieldText(tester, 'Base salary'), isEmpty);
      expect(_fieldText(tester, 'Tax rate'), '13');
      expect(_isEnabled(tester, _save), isFalse);
    });

    testWidgets('typing the inputs fills the results', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      await tester.enterText(_field('Base salary'), '100000');
      await tester.enterText(_field('Working days in the month'), '20');
      await tester.enterText(_field('Working hours in the month'), '160');
      await tester.pumpAndSettle();

      expect(_text('87,000.00 ₽'), findsOneWidget);
      expect(_isEnabled(tester, _save), isTrue);
    });
  });

  group('loading, error and no connection (SAL-12 to SAL-14)', () {
    testWidgets('shows grey blocks while the month loads', (tester) async {
      await _pumpSalary(tester, size: const Size(412, 915));

      _demo.update(_demo.settings.copyWith(scenario: DemoScenario.loading));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);
      expect(find.text('Total after tax'), findsNothing);
      expect(find.byTooltip('Salary history'), findsOneWidget);

      _demo.update(const DemoSettings());
      // Let the slow answers that were asked for finish.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error says the month could not be loaded', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.error),
      );

      expect(find.text("Couldn't load this month"), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(find.text('Please try again in a moment.'), findsNothing);
    });

    testWidgets('no connection offers Try again, which loads the month', (
      tester,
    ) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);
      expect(
        find.text('Check your internet connection and try again.'),
        findsOneWidget,
      );

      _demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(_text('104,400.00 ₽'), findsOneWidget);
    });

    testWidgets('keep the app bar and the navigation bar', (tester) async {
      await _pumpSalary(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.byTooltip('Salary history'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
    });

    testWidgets('the demo panel switching to an error shows it at once', (
      tester,
    ) async {
      await _pumpSalary(tester);

      _demo.update(_demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't load this month"), findsOneWidget);
    });
  });

  group('the buttons lead where the design says', () {
    testWidgets('the History icon opens the saved months', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.byTooltip('Salary history'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryHistoryScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsNothing);
    });

    testWidgets('the Settings gear opens Settings', (tester) async {
      await _pumpSalary(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    });

    testWidgets('the Fixed items segment goes to the fixed items and back', (
      tester,
    ) async {
      await _pumpSalary(tester);

      await tester.tap(find.text('Fixed items'));
      await tester.pumpAndSettle();

      expect(find.byType(FixedItemsScreen), findsOneWidget);
      expect(find.byType(FloatingNavigationBar), findsOneWidget);
      expect(find.byTooltip('Salary history'), findsOneWidget);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
    });
  });

  group('wide layout', () {
    testWidgets('shows the results and the inputs side by side', (
      tester,
    ) async {
      await _pumpSalary(tester, size: const Size(1280, 800));

      final results = tester.getTopLeft(find.text('Results')).dx;
      final inputs = tester.getTopLeft(find.text('Inputs')).dx;

      expect(inputs, greaterThan(results));
      expect(
        tester.getTopLeft(find.text('Results')).dy,
        greaterThan(tester.getTopLeft(find.text('Inputs')).dy),
        reason: 'the inputs start at the top of their own column',
      );
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels, Western digits and mirrored layout', (
      tester,
    ) async {
      await _pumpSalary(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('الإجمالي بعد الضريبة'), findsOneWidget);
      expect(find.text('النتائج'), findsOneWidget);
      expect(find.text('المدخلات'), findsOneWidget);
      // Amounts are wrapped in direction marks, so only a part is matched.
      expect(find.textContaining('20 يومًا ×'), findsOneWidget);
      expect(find.text('8 ساعات إضافية'), findsOneWidget);
      expect(find.textContaining('20 أكتوبر'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);

      final width = tester.view.physicalSize.width;
      final title = tester.getCenter(find.text('الراتب').first).dx;
      expect(
        title,
        greaterThan(width / 2),
        reason: 'title starts at the right',
      );
    });

    testWidgets('the Arabic digits typed in a field become Western', (
      tester,
    ) async {
      await _pumpSalary(tester, language: AppLanguage.arabic);

      await tester.enterText(
        find.widgetWithText(TextField, 'الساعات الإضافية'),
        '٤',
      );
      await tester.pumpAndSettle();

      expect(find.text('4'), findsOneWidget);
      expect(find.text('4 ساعات إضافية'), findsOneWidget);
    });
  });
}
