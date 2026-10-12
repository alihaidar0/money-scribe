import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/widgets/skeleton.dart';
import 'package:money_scribe/features/debts/bloc/debts_bloc.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/debts/presentation/debt_form_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';

Finder filter(String label) {
  return find.descendant(
    of: find.byType(SegmentedButton<DebtsFilter>),
    matching: find.text(label),
  );
}

void main() {
  group('the list (DB-1)', () {
    testWidgets('is the fourth tab, with the title and the settings gear', (
      tester,
    ) async {
      await openDebts(tester);

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Debts'), findsWidgets);
      expect(find.byTooltip('Settings'), findsOneWidget);
      expect(find.byType(NavigationBar), findsOneWidget);
    });

    testWidgets('shows what is owed to the person and what they owe', (
      tester,
    ) async {
      await openDebts(tester);

      expect(find.text('Owed to you'), findsOneWidget);
      expect(find.text('You owe'), findsOneWidget);
      expect(amountText('8,500.00 ₽'), findsOneWidget);
      expect(amountText('0.00 ₽'), findsWidgets);
    });

    testWidgets('has a card for each debt, those still open first', (
      tester,
    ) async {
      await openDebts(tester);

      for (final person in ['Sam', 'Maria', 'Anna']) {
        expect(find.text(person), findsOneWidget, reason: person);
      }
      final sam = tester.getTopLeft(find.text('Sam')).dy;
      final maria = tester.getTopLeft(find.text('Maria')).dy;
      final anna = tester.getTopLeft(find.text('Anna')).dy;
      expect(sam, lessThan(maria));
      expect(maria, lessThan(anna));
    });

    testWidgets('a card shows what is left, what it was and its due day', (
      tester,
    ) async {
      await openDebts(tester);

      expect(amountText('6,000.00 ₽'), findsOneWidget);
      expect(
        find.text(amount('Lent 10,000.00 ₽ · repaid 4,000.00 ₽')),
        findsOneWidget,
      );
      expect(find.text('Due 31 Oct'), findsOneWidget);
      expect(
        find.text(amount('Lent 2,500.00 ₽ · repaid 0.00 ₽')),
        findsOneWidget,
      );
      expect(find.text('Due 30 Sep'), findsOneWidget);
      expect(
        find.text(amount('Borrowed 3,000.00 ₽ · repaid 3,000.00 ₽')),
        findsOneWidget,
      );
    });

    testWidgets('each card has its badges', (tester) async {
      await openDebts(tester);

      expect(find.text('Lent'), findsWidgets);
      expect(find.text('Borrowed'), findsWidgets);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('Settled'), findsOneWidget);
    });

    testWidgets('a debt with no due day shows none', (tester) async {
      await openDebts(tester);

      // Sam and Maria are due; Anna is not.
      expect(find.textContaining('Due '), findsNWidgets(2));
    });

    testWidgets('has the segments and the Add debt button', (tester) async {
      await openDebts(tester);

      for (final label in ['All', 'Lent', 'Borrowed']) {
        expect(filter(label), findsOneWidget);
      }
      expect(
        find.widgetWithText(FloatingActionButton, 'Add debt'),
        findsOneWidget,
      );
    });
  });

  group('the segments', () {
    testWidgets('Lent lists the debts lent', (tester) async {
      await openDebts(tester);

      await tester.tap(filter('Lent'));
      await tester.pumpAndSettle();

      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Maria'), findsOneWidget);
      expect(find.text('Anna'), findsNothing);
    });

    testWidgets('Borrowed lists the debts borrowed', (tester) async {
      await openDebts(tester);

      await tester.tap(filter('Borrowed'));
      await tester.pumpAndSettle();

      expect(find.text('Anna'), findsOneWidget);
      expect(find.text('Sam'), findsNothing);
    });

    testWidgets('All lists every debt again', (tester) async {
      await openDebts(tester);
      await tester.tap(filter('Borrowed'));
      await tester.pumpAndSettle();

      await tester.tap(filter('All'));
      await tester.pumpAndSettle();

      expect(find.text('Sam'), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('the sums stay whatever the segment', (tester) async {
      await openDebts(tester);

      await tester.tap(filter('Borrowed'));
      await tester.pumpAndSettle();

      expect(amountText('8,500.00 ₽'), findsOneWidget);
    });
  });

  group('opening a debt', () {
    testWidgets('a card opens the debt (DB-3)', (tester) async {
      await openDebts(tester);

      await tester.tap(find.text('Sam'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.text('Debt details'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
    });

    testWidgets('Add debt opens the form (DB-2)', (tester) async {
      await openDebts(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text('Add debt'), findsOneWidget);
    });

    testWidgets('coming back shows what changed', (tester) async {
      await openDebts(tester);

      await tester.tap(find.text('Maria'));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Maria'), findsNothing);
      expect(amountText('6,000.00 ₽'), findsWidgets);
      expect(amountText('2,500.00 ₽'), findsNothing);
    });
  });

  group('no debts (DB-10)', () {
    const empty = DemoSettings(scenario: DemoScenario.empty);

    testWidgets('says so and offers to add a debt', (tester) async {
      await openDebts(tester, settings: empty);

      expect(find.text('No debts yet'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add a debt'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsNothing);
    });

    testWidgets('the button opens the form, and the new debt is listed', (
      tester,
    ) async {
      await openDebts(tester, settings: empty);

      await tester.tap(find.text('Add a debt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Lee');
      await tester.enterText(find.byType(TextField).at(1), '1500');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('No debts yet'), findsNothing);
      expect(find.text('Lee'), findsOneWidget);
      expect(amountText('1,500.00 ₽'), findsWidgets);
    });

    testWidgets('a segment with no debt says so', (tester) async {
      await openDebts(tester, settings: empty);
      await tester.tap(find.text('Add a debt'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(0), 'Lee');
      await tester.enterText(find.byType(TextField).at(1), '1500');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save'));
      await tester.pumpAndSettle();

      await tester.tap(filter('Borrowed'));
      await tester.pumpAndSettle();

      expect(find.text('No debts in this list.'), findsOneWidget);
    });
  });

  group('loading, error and no connection', () {
    testWidgets('shows grey blocks while the debts load (DB-9)', (
      tester,
    ) async {
      final demo = await openDebts(tester, size: const Size(412, 915));

      demo.update(demo.settings.copyWith(scenario: DemoScenario.loading));
      // Long enough for the button to finish leaving.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(SkeletonBox), findsWidgets);
      expect(find.byType(FloatingActionButton), findsNothing);

      demo.update(const DemoSettings());
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
      expect(find.byType(SkeletonBox), findsNothing);
    });

    testWidgets('an error offers Try again (DB-11)', (tester) async {
      final demo = await openDebts(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text("Couldn't load debts"), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets('no connection offers Try again (DB-12)', (tester) async {
      final demo = await openDebts(tester);

      demo.update(demo.settings.copyWith(scenario: DemoScenario.noConnection));
      await tester.pumpAndSettle();
      expect(find.text('No connection'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.pumpAndSettle();
      expect(find.text('Sam'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openDebts(tester, language: AppLanguage.arabic);

      expect(find.text('مستحق لك'), findsOneWidget);
      expect(find.text('عليك'), findsOneWidget);
      expect(find.text('الكل'), findsOneWidget);
      expect(find.text('إضافة دين'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });

    testWidgets('an empty list says so in Arabic', (tester) async {
      await openDebts(
        tester,
        language: AppLanguage.arabic,
        settings: const DemoSettings(scenario: DemoScenario.empty),
      );

      expect(find.text('لا توجد ديون بعد'), findsOneWidget);
    });
  });
}
