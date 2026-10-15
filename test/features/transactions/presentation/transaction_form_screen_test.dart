import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/widgets/failure_snack_bar.dart';
import 'package:money_scribe/core/widgets/pill_segmented_button.dart';
import 'package:money_scribe/features/settings/domain/app_language.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/presentation/accounts_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transaction_form_screen.dart';
import 'package:money_scribe/features/transactions/presentation/transactions_screen.dart';

import '../../../support/open_screen.dart';

const twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);

Finder inSheet(Finder finder) {
  return find.descendant(of: find.byType(BottomSheet), matching: finder);
}

/// Opens the form that adds a transaction, from the list.
Future<DemoController> openAddForm(
  WidgetTester tester, {
  DemoSettings settings = const DemoSettings(),
  AppLanguage language = AppLanguage.english,
}) async {
  final demo = await openTransactions(
    tester,
    settings: settings,
    language: language,
  );
  await tester.tap(find.byType(FloatingActionButton));
  await tester.pumpAndSettle();
  return demo;
}

/// Opens the form that changes the transaction with the category [category].
Future<DemoController> openEditForm(
  WidgetTester tester,
  String category, {
  DemoSettings settings = const DemoSettings(),
}) async {
  final demo = await openTransactions(tester, settings: settings);
  await tester.tap(find.text(category));
  await tester.pumpAndSettle();
  return demo;
}

Finder saveButton() => find.widgetWithText(FilledButton, 'Save');
Finder saveChangesButton() => find.widgetWithText(FilledButton, 'Save changes');

bool isEnabled(WidgetTester tester, Finder button) {
  return tester.widget<FilledButton>(button).onPressed != null;
}

void main() {
  group('a new transaction (TX-4)', () {
    testWidgets('has the title, the back arrow and no navigation bar', (
      tester,
    ) async {
      await openAddForm(tester);

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text('Add transaction'), findsOneWidget);
      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byIcon(Icons.delete_outline), findsNothing);
    });

    testWidgets('puts the amount first, then the day, category and account', (
      tester,
    ) async {
      await openAddForm(tester);

      expect(find.text('Expense'), findsOneWidget);
      expect(find.text('Income'), findsOneWidget);
      final amount = tester.getTopLeft(find.text('Amount')).dy;
      final date = tester.getTopLeft(find.text('Date')).dy;
      final category = tester.getTopLeft(find.text('Category')).dy;
      final account = tester.getTopLeft(find.text('Account')).dy;
      final note = tester.getTopLeft(find.text('Note')).dy;
      expect(amount, lessThan(date));
      expect(date, lessThan(category));
      expect(category, lessThan(account));
      expect(account, lessThan(note));
      // Today, in the first account.
      expect(find.text('11 Oct'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
    });

    testWidgets('offers the categories for an expense', (tester) async {
      await openAddForm(tester);

      for (final name in [
        'Groceries',
        'Dining',
        'Transport',
        'Housing',
        'Utilities',
        'Other',
      ]) {
        expect(find.widgetWithText(ChoiceChip, name), findsOneWidget);
      }
      expect(find.widgetWithText(ChoiceChip, 'Scholarship'), findsNothing);
    });

    testWidgets('Income offers the categories for income', (tester) async {
      await openAddForm(tester);

      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'Scholarship'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Other'), findsOneWidget);
      expect(find.widgetWithText(ChoiceChip, 'Groceries'), findsNothing);
    });

    testWidgets('Save waits for an amount above zero and a category', (
      tester,
    ) async {
      await openAddForm(tester);
      expect(isEnabled(tester, saveButton()), isFalse);

      await tester.enterText(find.byType(TextField).first, '120');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isFalse);

      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isTrue);

      await tester.enterText(find.byType(TextField).first, '0');
      await tester.pumpAndSettle();
      expect(isEnabled(tester, saveButton()), isFalse);
      expect(find.text('Enter an amount above zero.'), findsOneWidget);
    });

    testWidgets('Save adds it and goes back to the list', (tester) async {
      await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '1200.50');
      await tester.tap(find.text('Dining'));
      await tester.enterText(find.byType(TextField).last, 'Lunch');
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('Lunch · Card'), findsOneWidget);
      expect(amountText('−1,200.50 ₽'), findsNWidgets(2));
    });

    testWidgets('an income is listed with a plus', (tester) async {
      await openAddForm(tester);
      await tester.tap(find.text('Income'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '300');
      await tester.tap(find.text('Scholarship'));
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(amountText('+300.00 ₽'), findsNWidgets(2));
    });

    testWidgets('the failure message stays when the form is left', (
      tester,
    ) async {
      final demo = await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '50');
      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      // Like a message of success, it is read on the next screen and goes away
      // by itself.
      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(failureSnackBarDuration);
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('the failure message goes away by itself', (tester) async {
      final demo = await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '50');
      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));
      await tester.tap(saveButton());
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsOneWidget);

      await tester.pump(failureSnackBarDuration);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });

    testWidgets('a failed save keeps the form and offers Retry (ERR-1)', (
      tester,
    ) async {
      final demo = await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '50');
      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text("Couldn't save. Check your connection."), findsOne);
      // The message sits above the Save button, which stays in sight.
      expect(
        tester.getRect(find.byType(SnackBar)).bottom,
        lessThanOrEqualTo(tester.getRect(saveButton()).top),
      );

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(amountText('−50.00 ₽'), findsNWidgets(2));
    });
  });

  group('the day', () {
    testWidgets('a tap opens the date picker and the chosen day is shown', (
      tester,
    ) async {
      await openAddForm(tester);

      await tester.tap(find.text('11 Oct'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('20 Oct'), findsOneWidget);
    });

    testWidgets('cancelling the picker keeps the day', (tester) async {
      await openAddForm(tester);

      await tester.tap(find.text('11 Oct'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('11 Oct'), findsOneWidget);
    });

    testWidgets('one payment shows no part under the day', (tester) async {
      await openAddForm(tester);

      expect(find.textContaining('Part 1'), findsNothing);
    });

    testWidgets('two payments show the part the day is in', (tester) async {
      await openAddForm(tester, settings: twoPayments);
      // Today is the 11th, in the first part.
      expect(find.text('Part 1 · 1st–15th'), findsOneWidget);
      expect(find.text('Part 2 · 16th–end'), findsNothing);

      await tester.tap(find.text('11 Oct'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('20'));
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('Part 2 · 16th–end'), findsOneWidget);
    });
  });

  group('the account (TX-6)', () {
    testWidgets('the row opens the sheet with the accounts', (tester) async {
      await openAddForm(tester);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Account')), findsOneWidget);
      expect(inSheet(find.text('Card')), findsOneWidget);
      expect(inSheet(find.text('Cash')), findsOneWidget);
      expect(inSheet(find.text('Add account')), findsOneWidget);
      expect(inSheet(find.text('Manage accounts')), findsOneWidget);
      // The chosen one is marked.
      expect(inSheet(find.byIcon(Icons.radio_button_checked)), findsOne);
    });

    testWidgets('choosing one closes the sheet and shows it', (tester) async {
      await openAddForm(tester);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Cash')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Card'), findsNothing);
    });

    testWidgets('choosing the chosen one closes it too', (tester) async {
      await openAddForm(tester);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Card')));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
    });

    testWidgets('the chosen account is the one saved', (tester) async {
      await openAddForm(tester);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Cash')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '75');
      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();

      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      // The new one has no note, so its row shows the account alone.
      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Coffee · Cash'), findsOneWidget);
    });

    testWidgets('Manage accounts opens the Accounts screen, and back returns', (
      tester,
    ) async {
      await openAddForm(tester);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      await tester.tap(inSheet(find.text('Manage accounts')));
      await tester.pumpAndSettle();

      expect(find.byType(AccountsScreen), findsOneWidget);
      expect(find.byType(TransactionFormScreen), findsNothing);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });

    testWidgets('an account added there is offered by the form', (
      tester,
    ) async {
      await openAddForm(tester);
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();
      await tester.tap(inSheet(find.text('Add account')));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add account'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'Savings');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('Savings')), findsOneWidget);
    });
  });

  group('changing a transaction (TX-5)', () {
    testWidgets('is filled in, with Delete and Save changes', (tester) async {
      await openEditForm(tester, 'Groceries');

      expect(find.text('Edit transaction'), findsOneWidget);
      final fields = find.byType(TextField);
      expect(
        tester.widget<TextField>(fields.first).controller?.text,
        '1,284.50',
      );
      expect(
        tester.widget<TextField>(fields.last).controller?.text,
        'Weekly shopping',
      );
      expect(find.text('5 Oct'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Groceries'))
            .selected,
        isTrue,
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(saveChangesButton(), findsOneWidget);
    });

    testWidgets('Save changes waits for a change', (tester) async {
      await openEditForm(tester, 'Groceries');
      expect(isEnabled(tester, saveChangesButton()), isFalse);

      await tester.enterText(find.byType(TextField).last, 'Big shopping');
      await tester.pumpAndSettle();

      expect(isEnabled(tester, saveChangesButton()), isTrue);
    });

    testWidgets('Save changes keeps them and goes back', (tester) async {
      await openEditForm(tester, 'Groceries');
      await tester.enterText(find.byType(TextField).first, '1300');
      await tester.pumpAndSettle();

      await tester.tap(saveChangesButton());
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(amountText('−1,300.00 ₽'), findsNWidgets(2));
      expect(amountText('−1,284.50 ₽'), findsNothing);
    });

    testWidgets('an income can be changed to an expense', (tester) async {
      await openEditForm(tester, 'Scholarship');
      expect(
        tester
            .widget<PillSegmentedButton<TransactionKind>>(
              find.byType(PillSegmentedButton<TransactionKind>),
            )
            .selected,
        {TransactionKind.income},
      );

      await tester.tap(find.text('Expense'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Housing'));
      await tester.pumpAndSettle();
      await tester.tap(saveChangesButton());
      await tester.pumpAndSettle();

      expect(amountText('−5,000.00 ₽'), findsNWidgets(2));
    });
  });

  group('deleting a transaction (TX-7)', () {
    testWidgets('the Delete icon asks first', (tester) async {
      await openEditForm(tester, 'Groceries');

      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      expect(find.text('Delete transaction?'), findsOneWidget);
      expect(
        find.text(
          'This transaction will be permanently deleted from your account. '
          'This cannot be undone.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('Cancel closes the dialog and keeps the transaction', (
      tester,
    ) async {
      await openEditForm(tester, 'Groceries');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Delete transaction?'), findsNothing);
      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });

    testWidgets('Delete removes it and goes back', (tester) async {
      await openEditForm(tester, 'Groceries');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
      expect(find.text('Mon 5 Oct'), findsNothing);
    });

    testWidgets('a failed delete keeps it and offers Retry', (tester) async {
      final demo = await openEditForm(tester, 'Groceries');
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();
      demo.update(const DemoSettings(save: DemoSave.fails));

      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionFormScreen), findsOneWidget);
      expect(find.text("Couldn't delete. Check your connection."), findsOne);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
      expect(find.text('Groceries'), findsNothing);
    });
  });

  group('leaving with changes', () {
    testWidgets('no change leaves at once', (tester) async {
      await openAddForm(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('a change asks first, and Keep editing stays', (tester) async {
      await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
      await tester.tap(find.text('Keep editing'));
      await tester.pumpAndSettle();
      expect(find.byType(TransactionFormScreen), findsOneWidget);
    });

    testWidgets('Discard leaves and drops the changes', (tester) async {
      await openAddForm(tester);
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('changing a transaction and back asks too', (tester) async {
      await openEditForm(tester, 'Groceries');
      await tester.enterText(find.byType(TextField).last, 'x');
      await tester.pumpAndSettle();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('addresses', () {
    testWidgets('a transaction that does not exist goes to the list', (
      tester,
    ) async {
      await openTransactions(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/transactions/edit/missing');
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });

    testWidgets('saving a form opened from an address goes to the list', (
      tester,
    ) async {
      await openTransactions(tester);

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/transactions/add');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, '10');
      await tester.tap(find.text('Dining'));
      await tester.pumpAndSettle();
      await tester.tap(saveButton());
      await tester.pumpAndSettle();

      expect(find.byType(TransactionsScreen), findsOneWidget);
    });
  });

  group('loading, error and no connection', () {
    testWidgets('an error offers Try again', (tester) async {
      final demo = await openEditForm(tester, 'Groceries');

      GoRouter.of(tester.element(find.byType(Scaffold).first))
          .go('/transactions/edit/seed-taxi');
      demo.update(demo.settings.copyWith(scenario: DemoScenario.error));
      await tester.pumpAndSettle();
      expect(find.text('Something went wrong'), findsOneWidget);

      demo.update(const DemoSettings());
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Edit transaction'), findsOneWidget);
    });
  });

  group('in Arabic', () {
    testWidgets('shows Arabic labels and Western digits', (tester) async {
      await openAddForm(tester, language: AppLanguage.arabic);

      expect(find.text('إضافة معاملة'), findsOneWidget);
      expect(find.text('مصروف'), findsOneWidget);
      expect(find.text('دخل'), findsOneWidget);
      expect(find.text('المبلغ'), findsOneWidget);
      expect(find.text('الفئة'), findsOneWidget);
      expect(find.text('حفظ'), findsOneWidget);
      expect(find.textContaining(RegExp('[٠-٩]')), findsNothing);
    });

    testWidgets('the date picker shows Western digits', (tester) async {
      await openAddForm(tester, language: AppLanguage.arabic);

      await tester.tap(find.byIcon(Icons.calendar_today_outlined));
      await tester.pumpAndSettle();

      expect(find.byType(DatePickerDialog), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DatePickerDialog),
          matching: find.textContaining(RegExp('[٠-٩]')),
        ),
        findsNothing,
      );
    });

    testWidgets('the account sheet is in Arabic', (tester) async {
      await openAddForm(tester, language: AppLanguage.arabic);

      await tester.tap(find.byIcon(Icons.expand_more));
      await tester.pumpAndSettle();

      expect(inSheet(find.text('إضافة حساب')), findsOneWidget);
      expect(inSheet(find.text('إدارة الحسابات')), findsOneWidget);
    });
  });
}
