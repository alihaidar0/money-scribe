import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';
import 'package:money_scribe/features/debts/domain/debts_repository.dart';
import 'package:money_scribe/features/debts/presentation/debt_details_screen.dart';
import 'package:money_scribe/features/debts/presentation/debt_form_screen.dart';
import 'package:money_scribe/features/debts/presentation/debts_screen.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';

import '../../../support/open_screen.dart';
import '../../../support/refusing_debts_repository.dart';

Finder inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

/// Opens the debt of [person] from the list.
Future<DemoController> openDebt(
  WidgetTester tester,
  String person, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
  DebtsRepository Function(DemoController demo)? debtsRepository,
}) async {
  final demo = await openDebts(
    tester,
    settings: settings,
    language: language,
    debtsRepository: debtsRepository,
  );
  await tester.tap(find.text(person));
  await tester.pumpAndSettle();
  return demo;
}

/// Opens the sheet that adds a repayment.
Future<void> openAddRepaymentSheet(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(FilledButton, 'Add repayment'));
  await tester.pumpAndSettle();
}

Finder sheetSave() => inSheet(find.widgetWithText(FilledButton, 'Save'));

bool isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<FilledButton>(button).onPressed != null;
}

void main() {
  group('the debt (DB-3)', () {
    testWidgets('shows the person, what was lent and how much is repaid', (
      tester,
    ) async {
      await openDebt(tester, 'Sam');

      expect(find.text('Debt details'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
      expect(find.text(amount('Lent 10,000.00 ₽')), findsOneWidget);
      expect(
        find.text(amount('4,000.00 ₽ of 10,000.00 ₽ repaid')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<LinearProgressIndicator>(
              find.byType(LinearProgressIndicator),
            )
            .value,
        closeTo(0.4, 1e-9),
      );
    });

    testWidgets('shows what is left, the status and the facts', (tester) async {
      await openDebt(tester, 'Sam');

      expect(find.text('Remaining'), findsOneWidget);
      expect(amountText('6,000.00 ₽'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(find.text('Start date'), findsOneWidget);
      expect(find.text('1 Oct'), findsOneWidget);
      expect(find.text('Due date'), findsOneWidget);
      expect(find.text('31 Oct'), findsOneWidget);
      expect(find.text('Note'), findsOneWidget);
      expect(find.text('Lunch money'), findsOneWidget);
    });

    testWidgets('lists the repayments, each tappable', (tester) async {
      await openDebt(tester, 'Sam');

      expect(find.text('Repayments'), findsOneWidget);
      expect(find.text(amount('4,000.00 ₽ · 12 Oct')), findsOneWidget);
    });

    testWidgets('has the overflow menu and Add repayment', (tester) async {
      await openDebt(tester, 'Sam');

      expect(find.byIcon(Icons.more_vert), findsOneWidget);
      expect(
        find.widgetWithText(FilledButton, 'Add repayment'),
        findsOneWidget,
      );
      expect(find.byType(BackButton), findsOneWidget);
    });

    testWidgets('a debt that is overdue says so', (tester) async {
      await openDebt(tester, 'Maria');

      expect(find.text('Overdue'), findsOneWidget);
      expect(find.text('No repayments yet.'), findsOneWidget);
      // No note, so no Note fact.
      expect(find.text('Note'), findsNothing);
    });

    testWidgets('a settled debt has nothing left and no Add repayment', (
      tester,
    ) async {
      await openDebt(tester, 'Anna');

      expect(find.text('Settled'), findsOneWidget);
      expect(find.text(amount('Borrowed 3,000.00 ₽')), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add repayment'), findsNothing);
      // No due day, so no Due date fact.
      expect(find.text('Due date'), findsNothing);
    });

    testWidgets('the back arrow returns to the list', (tester) async {
      await openDebt(tester, 'Sam');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
    });
  });

  group('adding a repayment (DB-4)', () {
    testWidgets('opens a sheet with an amount and a day', (tester) async {
      await openDebt(tester, 'Sam');

      await openAddRepaymentSheet(tester);

      expect(find.text('Add repayment'), findsWidgets);
      expect(inSheet(find.text('Amount')), findsOneWidget);
      expect(inSheet(find.text('Date')), findsOneWidget);
      expect(inSheet(find.text('11 Oct')), findsOneWidget);
      expect(inSheet(find.text('Cancel')), findsOneWidget);
      expect(inSheet(find.text('Delete')), findsNothing);
      expect(isEnabled(tester, sheetSave()), isFalse);
    });

    testWidgets('Save adds it and reduces what is left', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), '1500');
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(amount('1,500.00 ₽ · 11 Oct')), findsOneWidget);
      expect(amountText('4,500.00 ₽'), findsOneWidget);
      expect(
        find.text(amount('5,500.00 ₽ of 10,000.00 ₽ repaid')),
        findsOneWidget,
      );
    });

    testWidgets('the day can be chosen', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), '100');
      await tester.tap(inSheet(find.text('11 Oct')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('15'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(find.text(amount('100.00 ₽ · 15 Oct')), findsOneWidget);
    });

    testWidgets('it cannot be more than what is left', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), '6000.01');
      await tester.pumpAndSettle();

      expect(
        find.text(amount('More than the 6,000.00 ₽ still to be repaid.')),
        findsOneWidget,
      );
      expect(isEnabled(tester, sheetSave()), isFalse);

      await tester.enterText(inSheet(find.byType(TextField)), '6000');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, sheetSave()), isTrue);
    });

    testWidgets('it cannot be zero', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), '0');
      await tester.pumpAndSettle();

      expect(find.text('Enter an amount above zero.'), findsOneWidget);
      expect(isEnabled(tester, sheetSave()), isFalse);
    });

    testWidgets('paying the rest settles the debt', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);

      await tester.enterText(inSheet(find.byType(TextField)), '6000');
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(find.text('Settled'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Add repayment'), findsNothing);
    });

    testWidgets('Cancel and a tap outside close it', (tester) async {
      await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);
      await tester.enterText(inSheet(find.byType(TextField)), '10');

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);

      await openAddRepaymentSheet(tester);
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(amount('10.00 ₽ · 11 Oct')), findsNothing);
    });

    testWidgets('a failed save keeps the debt and offers Retry (ERR-1)', (
      tester,
    ) async {
      final demo = await openDebt(tester, 'Sam');
      await openAddRepaymentSheet(tester);
      await tester.enterText(inSheet(find.byType(TextField)), '500');
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(find.text("Couldn't save. Check your connection."), findsOne);
      expect(find.text(amount('500.00 ₽ · 11 Oct')), findsNothing);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text(amount('500.00 ₽ · 11 Oct')), findsOneWidget);
    });
  });

  group('changing a repayment (DB-5)', () {
    testWidgets('a row opens the sheet filled in, with Delete', (tester) async {
      await openDebt(tester, 'Sam');

      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();

      expect(find.text('Edit repayment'), findsOneWidget);
      expect(
        tester
            .widget<TextField>(inSheet(find.byType(TextField)))
            .controller
            ?.text,
        '4,000.00',
      );
      expect(inSheet(find.text('12 Oct')), findsOneWidget);
      expect(inSheet(find.text('Delete')), findsOneWidget);
      expect(isEnabled(tester, sheetSave()), isTrue);
    });

    testWidgets('Save keeps the change', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();

      await tester.enterText(inSheet(find.byType(TextField)), '2500');
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(find.text(amount('2,500.00 ₽ · 12 Oct')), findsOneWidget);
      expect(amountText('7,500.00 ₽'), findsOneWidget);
    });

    testWidgets('it can be as much as what is left plus itself', (
      tester,
    ) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();

      await tester.enterText(inSheet(find.byType(TextField)), '10000');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, sheetSave()), isTrue);

      await tester.enterText(inSheet(find.byType(TextField)), '10000.01');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, sheetSave()), isFalse);
    });
  });

  group('deleting a repayment (DB-6)', () {
    testWidgets('Delete asks first, with the amount', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete repayment?'), findsOneWidget);
      expect(
        find.text(
          amount(
            'The repayment of 4,000.00 ₽ will be permanently deleted from '
            'your account. This cannot be undone.',
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel goes back to the sheet', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel').last);
      await tester.pumpAndSettle();

      expect(find.text('Delete repayment?'), findsNothing);
      expect(find.text('Edit repayment'), findsOneWidget);
    });

    testWidgets('Delete removes it and puts the money back on the debt', (
      tester,
    ) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(amount('4,000.00 ₽ · 12 Oct')), findsNothing);
      expect(find.text('No repayments yet.'), findsOneWidget);
      expect(amountText('10,000.00 ₽'), findsWidgets);
    });

    testWidgets('a failed delete keeps it and offers Retry', (tester) async {
      final demo = await openDebt(tester, 'Sam');
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Delete')));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.text("Couldn't delete. Check your connection."), findsOne);
      expect(find.text(amount('4,000.00 ₽ · 12 Oct')), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text(amount('4,000.00 ₽ · 12 Oct')), findsNothing);
    });
  });

  group('the menu', () {
    testWidgets('has Edit and Delete', (tester) async {
      await openDebt(tester, 'Sam');

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('Edit opens the form for the debt (DB-8)', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtFormScreen), findsOneWidget);
      expect(find.text('Edit debt'), findsOneWidget);
    });

    testWidgets('changing the debt shows the change when coming back', (
      tester,
    ) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'Samuel');
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Save changes'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.text('Samuel'), findsOneWidget);
    });

    testWidgets('Delete asks first, with the person (DB-7)', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(find.text('Delete this debt?'), findsOneWidget);
      expect(
        find.text(
          'The debt with Sam and its repayments will be permanently deleted '
          'from your account. This cannot be undone.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel keeps the debt', (tester) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
    });

    testWidgets('Delete removes the debt and goes back to the list', (
      tester,
    ) async {
      await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
      expect(find.text('Sam'), findsNothing);
    });

    testWidgets('a failed delete keeps the debt and offers Retry', (
      tester,
    ) async {
      final demo = await openDebt(tester, 'Sam');
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.text("Couldn't delete. Check your connection."), findsOne);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
    });
  });

  group('addresses', () {
    testWidgets('a debt that does not exist goes to the list', (tester) async {
      await openDebts(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/debts/missing');
      await tester.pumpAndSettle();

      expect(find.byType(DebtsScreen), findsOneWidget);
    });

    testWidgets('the address of a debt opens it', (tester) async {
      await openDebts(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/debts/anna');
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.text('Anna'), findsOneWidget);
    });

    testWidgets('with a repayment asked for, the sheet opens over the debt', (
      tester,
    ) async {
      await openDebts(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/debts/sam?repay=1');
      await tester.pumpAndSettle();

      expect(find.byType(DebtDetailsScreen), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.text('Add repayment'), findsWidgets);
      expect(find.text('Sam'), findsOneWidget);
    });

    testWidgets('the sheet opens once, not again after it is closed', (
      tester,
    ) async {
      await openDebts(tester);
      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/debts/sam?repay=1');
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('loading, error and no connection', () {
    testWidgets('an error offers Try again', (tester) async {
      final demo = await openDebt(tester, 'Sam');

      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Debt details'), findsOneWidget);
      expect(find.text('Sam'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openDebt(tester, 'Sam', language: AppLanguage.arabic);

      expect(find.text('تفاصيل الدين'), findsOneWidget);
      expect(find.text('المتبقي'), findsOneWidget);
      expect(find.text('السدادات'), findsOneWidget);
      expect(find.text('إضافة سداد'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });

    testWidgets('the repayment sheet is in Arabic', (tester) async {
      await openDebt(tester, 'Sam', language: AppLanguage.arabic);

      await tester.tap(find.text('إضافة سداد'));
      await tester.pumpAndSettle();

      expect(find.text('إضافة سداد'), findsWidgets);
      expect(inSheet(find.text('المبلغ')), findsOneWidget);
      expect(inSheet(find.text('حفظ')), findsOneWidget);
    });
  });

  group('what the server says to a repayment', () {
    testWidgets('more than what is left says how much is left', (tester) async {
      await openDebt(
        tester,
        'Sam',
        debtsRepository: (demo) => RefusingDebtsRepository(
          demo: demo,
          failure: const DebtRefusedException(
            DebtRefusal.exceedsRemaining,
            remaining: Money(50000, Currency.rub),
          ),
        ),
      );
      await openAddRepaymentSheet(tester);

      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(
        find.text(amount('More than the 500.00 ₽ still to be repaid.')),
        findsOneWidget,
      );
    });

    testWidgets('a debt that has all the repayments allowed says so', (
      tester,
    ) async {
      await openDebt(
        tester,
        'Sam',
        debtsRepository: (demo) => RefusingDebtsRepository(
          demo: demo,
          failure: const DebtRefusedException(
            DebtRefusal.repaymentLimitReached,
          ),
        ),
      );
      await openAddRepaymentSheet(tester);

      await tester.enterText(find.byType(TextField), '100');
      await tester.pumpAndSettle();
      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(
        find.text('This debt has the most repayments allowed.'),
        findsOneWidget,
      );
    });

    testWidgets('a debt changed on another device is loaded again', (
      tester,
    ) async {
      await openDebt(
        tester,
        'Sam',
        debtsRepository: (demo) => RefusingDebtsRepository(
          demo: demo,
          failure: const StaleRecordException(),
        ),
      );
      await tester.tap(find.text(amount('4,000.00 ₽ · 12 Oct')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1000');
      await tester.pumpAndSettle();

      await tester.tap(sheetSave());
      await tester.pumpAndSettle();

      expect(
        find.text(
          'This debt was changed on another device. It has been loaded again.',
        ),
        findsOneWidget,
      );
      // Nothing was changed.
      expect(find.text(amount('4,000.00 ₽ · 12 Oct')), findsOneWidget);
    });
  });

  group('a debt that has not started yet', () {
    testWidgets('suggests its start day for a repayment', (tester) async {
      await openDebt(
        tester,
        'Lee',
        debtsRepository: (demo) {
          final repository = FakeDebtsRepository(demo: demo);
          unawaited(
            repository.add(
              DebtDraft(
                direction: DebtDirection.lent,
                person: 'Lee',
                amount: const Money(100000, Currency.rub),
                // The clock of the tests is the 11th of October 2026.
                startDate: DateTime(2026, 12),
              ),
            ),
          );
          return repository;
        },
      );
      await openAddRepaymentSheet(tester);

      expect(inSheet(find.text('1 Dec')), findsOneWidget);
    });
  });
}
