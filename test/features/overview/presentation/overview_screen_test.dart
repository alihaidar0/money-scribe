import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/auth/data/fake/fake_auth_repository.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/overview/domain/overview_repository.dart';
import 'package:money_scribe/features/overview/presentation/overview_screen.dart';
import 'package:money_scribe/features/salary/presentation/fixed_items_screen.dart';
import 'package:money_scribe/features/salary/presentation/salary_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/presentation/add_transaction_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../../../support/build_app.dart';
import '../../../support/fake_language_repository.dart';
import '../../../support/other_currency_repositories.dart';

const _nbsp = ' ';

late DemoController _demo;

Future<void> _pumpOverview(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  Size size = const Size(412, 915),
  Duration latency = Duration.zero,
  OverviewRepository Function(DemoController demo)? overviewRepository,
}) async {
  tester.view
    ..devicePixelRatio = 1
    ..physicalSize = size;
  addTearDown(tester.view.reset);
  _demo = DemoController(initial: settings, latency: latency);
  await tester.pumpWidget(
    buildApp(
      demo: _demo,
      languageRepository: FakeLanguageRepository(language),
      authRepository: FakeAuthRepository(demo: _demo, signedIn: true),
      overviewRepository: overviewRepository?.call(_demo),
    ),
  );
  await tester.pumpAndSettle();
}

/// Amounts have a no-break space before the currency symbol.
String _amount(String text) => text.replaceAll(' ₽', '$_nbsp₽');

/// Finds an amount, also inside a rich text.
Finder _text(String text) {
  return find.textContaining(_amount(text), findRichText: true);
}

Finder _inRow(String title, String amount) {
  return find.descendant(
    of: find.ancestor(of: find.text(title), matching: find.byType(InkWell)),
    matching: _text(amount),
  );
}

void main() {
  group('one payment (OV-1)', () {
    testWidgets('shows the balance, income, spending and the six rows', (
      tester,
    ) async {
      await _pumpOverview(tester);

      expect(find.byType(OverviewScreen), findsOneWidget);
      expect(find.text('October 2026'), findsOneWidget);
      expect(find.text('Balance'), findsOneWidget);
      expect(_text('60,650.00 ₽'), findsOneWidget);
      expect(find.textContaining('Income', findRichText: true), findsWidgets);
      expect(_text('+109,400.00 ₽'), findsOneWidget);
      expect(_text('−52,750.00 ₽'), findsOneWidget);
      expect(_inRow('Salary', '+104,400.00 ₽'), findsOneWidget);
      expect(_inRow('Recurring income', '+5,000.00 ₽'), findsOneWidget);
      expect(_inRow('Other income', '+0.00 ₽'), findsOneWidget);
      expect(_inRow('Fixed costs', '−34,500.00 ₽'), findsOneWidget);
      expect(_inRow('Purchases', '−18,250.00 ₽'), findsOneWidget);
      // The last row is below the fold of a phone.
      await tester.scrollUntilVisible(find.text('Debt movements'), 200);
      expect(_inRow('Debt movements', '+4,000.00 ₽'), findsOneWidget);
    });

    testWidgets('has no part selector and no period cards', (tester) async {
      await _pumpOverview(tester);

      expect(find.byType(PillSegmentedButton<Object>), findsNothing);
      expect(find.text('Part 1'), findsNothing);
      expect(find.textContaining('Part 1', findRichText: true), findsNothing);
    });

    testWidgets('shows the five tabs with Overview selected', (tester) async {
      await _pumpOverview(tester);

      final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));

      expect(bar.selectedIndex, 0);
      expect(bar.destinations, hasLength(5));
    });
  });

  group('the month switcher', () {
    testWidgets('goes to the previous month, with other figures', (
      tester,
    ) async {
      await _pumpOverview(tester);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
      expect(_text('60,650.00 ₽'), findsNothing);
    });

    testWidgets('goes forward again, but not past the month of today', (
      tester,
    ) async {
      await _pumpOverview(tester);
      IconButton next() => tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.chevron_right),
      );
      expect(next().onPressed, isNull);

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();
      expect(next().onPressed, isNotNull);

      await tester.tap(find.byTooltip('Next month'));
      await tester.pumpAndSettle();

      expect(find.text('October 2026'), findsOneWidget);
      expect(next().onPressed, isNull);
    });

    testWidgets('is the only place with arrows: the rows have chevrons', (
      tester,
    ) async {
      await _pumpOverview(tester);

      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Next month'), findsOneWidget);
    });
  });

  group('two payments (OV-2)', () {
    const two = DemoSettings(paymentMode: PaymentMode.twoPayments);

    testWidgets('shows the selector and the two period cards', (tester) async {
      await _pumpOverview(tester, settings: two);

      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Part 1'), findsOneWidget);
      expect(find.text('Part 2'), findsOneWidget);
      expect(find.text('Part 1 · 1st–15th'), findsOneWidget);
      expect(find.text('Part 2 · 16th–end'), findsOneWidget);
      expect(_text('4,750.00 ₽'), findsOneWidget);
      expect(_text('55,900.00 ₽'), findsOneWidget);
      expect(_text('+43,500.00 ₽'), findsOneWidget);
      expect(_text('−42,750.00 ₽'), findsOneWidget);
      expect(_text('+65,900.00 ₽'), findsOneWidget);
      expect(_text('−10,000.00 ₽'), findsOneWidget);
      expect(_text('+0.00 ₽'), findsOneWidget);
    });

    testWidgets('choosing a part shows its figures and hides the cards', (
      tester,
    ) async {
      await _pumpOverview(tester, settings: two);

      await tester.tap(find.text('Part 1'));
      await tester.pumpAndSettle();

      expect(find.text('Part 1 · 1st–15th'), findsNothing);
      expect(_text('4,750.00 ₽'), findsOneWidget);
      expect(_inRow('Salary', '+43,500.00 ₽'), findsOneWidget);
      expect(_inRow('Fixed costs', '−34,500.00 ₽'), findsOneWidget);

      await tester.tap(find.text('Part 2'));
      await tester.pumpAndSettle();
      expect(_text('55,900.00 ₽'), findsOneWidget);
      expect(_inRow('Recurring income', '+5,000.00 ₽'), findsOneWidget);

      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();
      expect(_text('60,650.00 ₽'), findsOneWidget);
      expect(find.text('Part 1 · 1st–15th'), findsOneWidget);
    });

    testWidgets('a period card opens the transactions', (tester) async {
      await _pumpOverview(tester, settings: two);

      await tester.tap(find.text('Part 2 · 16th–end'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });
  });

  group('the first launch (OV-3)', () {
    const empty = DemoSettings(scenario: DemoScenario.empty);

    testWidgets('welcomes a new account and leads to the salary', (
      tester,
    ) async {
      await _pumpOverview(tester, settings: empty);

      expect(find.text('Welcome to Money Scribe'), findsOneWidget);
      expect(
        find.text('Add your first salary month to see your balance.'),
        findsOneWidget,
      );
      // An empty month can be left for another one.
      expect(find.byTooltip('Previous month'), findsOneWidget);
      expect(find.byTooltip('Settings'), findsOneWidget);

      await tester.tap(find.text('Enter your first salary month'));
      await tester.pumpAndSettle();

      expect(find.byType(SalaryScreen), findsOneWidget);
    });

    testWidgets('shows the balance once the account has data', (tester) async {
      await _pumpOverview(tester, settings: empty);

      _demo.update(const DemoSettings());
      await tester.pumpAndSettle();

      expect(find.byType(OverviewScreen), findsOneWidget);
      expect(_text('60,650.00 ₽'), findsOneWidget);
    });
  });

  group('the buttons and rows lead where the design says', () {
    testWidgets('Add purchase opens the add form', (tester) async {
      await _pumpOverview(tester);

      await tester.tap(find.text('Add purchase'));
      await tester.pumpAndSettle();

      expect(find.byType(AddTransactionScreen), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('the rows open the salary, fixed items, transactions, debts', (
      tester,
    ) async {
      await _pumpOverview(tester);
      final destinations = {
        'Salary': SalaryScreen,
        'Recurring income': FixedItemsScreen,
        'Fixed costs': FixedItemsScreen,
        'Purchases': TransactionsScreen,
        'Debt movements': DebtsScreen,
      };

      for (final MapEntry(key: row, value: screen) in destinations.entries) {
        final finder = find.descendant(
          of: find.byType(ListView),
          matching: find.text(row),
        );
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(find.byType(screen), findsOneWidget, reason: row);

        await tester.tap(find.text('Overview').last);
        await tester.pumpAndSettle();
        expect(find.byType(OverviewScreen), findsOneWidget, reason: row);
      }
    });

    testWidgets('the Settings gear opens Settings', (tester) async {
      await _pumpOverview(tester);

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(AppBar, 'Settings'), findsOneWidget);
    });
  });

  group('Choose a debt (OV-4)', () {
    testWidgets('lists the debts with their badges', (tester) async {
      await _pumpOverview(tester);

      await tester.tap(find.text('Add repayment'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a debt'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Lent'), findsNWidgets(2));
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(_text('Remaining 6,000.00 ₽'), findsOneWidget);
      expect(_text('Remaining 2,500.00 ₽'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('Cancel closes the sheet', (tester) async {
      await _pumpOverview(tester);
      await tester.tap(find.text('Add repayment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a debt'), findsNothing);
      expect(find.byType(OverviewScreen), findsOneWidget);
    });

    testWidgets('choosing a debt opens it with the repayment sheet', (
      tester,
    ) async {
      await _pumpOverview(tester);
      await tester.tap(find.text('Add repayment'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();

      expect(find.text('Choose a debt'), findsNothing);
      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Add repayment'), findsWidgets);
    });
  });

  group('loading, error and no connection (OV-5 to OV-7)', () {
    testWidgets('shows grey blocks while the month loads', (tester) async {
      await _pumpOverview(tester, latency: const Duration(milliseconds: 200));
      await tester.pumpWidget(
        buildApp(
          demo: _demo,
          authRepository: FakeAuthRepository(demo: _demo, signedIn: true),
        ),
      );
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.bySemanticsLabel('Loading'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
      expect(_text('60,650.00 ₽'), findsOneWidget);
    });

    testWidgets('forcing Loading from the demo panel shows the blocks', (
      tester,
    ) async {
      await _pumpOverview(tester);

      _demo.update(const DemoSettings(scenario: DemoScenario.loading));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SkeletonBox), findsWidgets);

      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();
    });

    testWidgets('forcing Error from the demo panel shows the error', (
      tester,
    ) async {
      await _pumpOverview(tester);

      _demo.update(const DemoSettings(scenario: DemoScenario.error));
      await tester.pumpAndSettle();

      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('no connection offers Try again', (tester) async {
      await _pumpOverview(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.noConnection),
      );

      expect(find.text('No connection'), findsOneWidget);

      _demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();

      expect(_text('60,650.00 ₽'), findsOneWidget);
    });

    testWidgets('Try again loads the month once more', (tester) async {
      await _pumpOverview(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.error),
      );
      expect(find.text('Something went wrong'), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels, a Western-digit month and the amounts', (
      tester,
    ) async {
      await _pumpOverview(tester, language: AppLanguage.arabic);

      expect(find.text('الرصيد'), findsOneWidget);
      expect(find.text('الدخل المتكرر'), findsOneWidget);
      expect(find.textContaining('2026'), findsWidgets);
      expect(find.textContaining('٢'), findsNothing);
      expect(
        find.textContaining('60,650.00', findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('the month arrows mirror: previous is on the right', (
      tester,
    ) async {
      await _pumpOverview(tester, language: AppLanguage.arabic);

      final previous = tester.getCenter(find.byTooltip('الشهر السابق')).dx;
      final next = tester.getCenter(find.byTooltip('الشهر التالي')).dx;

      expect(previous, greaterThan(next));
    });

    testWidgets('two payments in Arabic', (tester) async {
      await _pumpOverview(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(paymentMode: PaymentMode.twoPayments),
      );

      expect(find.text('الجزء 1'), findsOneWidget);
      expect(find.text('الجزء 1 · من 1 إلى 15'), findsOneWidget);
    });
  });

  group('layout', () {
    testWidgets('puts the rows in a second column on a wide window', (
      tester,
    ) async {
      await _pumpOverview(tester, size: const Size(1280, 800));

      final hero = tester.getTopLeft(find.text('Balance'));
      final salary = tester.getTopLeft(find.text('Salary').last);

      expect(find.byType(NavigationRail), findsOneWidget);
      expect(salary.dx, greaterThan(hero.dx + 300));
    });

    for (final mode in PaymentMode.values) {
      testWidgets('fits at 200% text size, ${mode.name}', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pumpOverview(
          tester,
          size: const Size(360, 640),
          settings: DemoSettings(paymentMode: mode),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('fits at 200% text size in Arabic, ${mode.name}', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await _pumpOverview(
          tester,
          size: const Size(360, 640),
          language: AppLanguage.arabic,
          settings: DemoSettings(paymentMode: mode),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('income transactions and other currencies', () {
    testWidgets('Other income is a row, and the income counts it', (
      tester,
    ) async {
      await _pumpOverview(
        tester,
        overviewRepository: (demo) =>
            OtherCurrencyOverviewRepository(demo: demo),
      );

      expect(_inRow('Other income', '+2,000.00 ₽'), findsOneWidget);
      // 104,400 pay + 5,000 recurring + 2,000 other.
      expect(_text('+111,400.00 ₽'), findsOneWidget);
    });

    testWidgets('a month with records in other currencies says so', (
      tester,
    ) async {
      await _pumpOverview(
        tester,
        overviewRepository: (demo) =>
            OtherCurrencyOverviewRepository(demo: demo),
      );

      expect(
        find.text(
          'Records in other currencies are not included in these figures.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('an ordinary month does not', (tester) async {
      await _pumpOverview(tester);

      expect(find.textContaining('other currencies'), findsNothing);
    });

    testWidgets('a month with nothing in it can be left for another', (
      tester,
    ) async {
      await _pumpOverview(
        tester,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      await tester.tap(find.byTooltip('Previous month'));
      await tester.pumpAndSettle();

      expect(find.text('September 2026'), findsOneWidget);
    });
  });
}
