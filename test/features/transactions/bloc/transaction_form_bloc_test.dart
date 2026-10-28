import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/dates/year_month.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/pay_cycle.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/core/payments/period_scope.dart';
import 'package:money_scribe/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';
import 'package:money_scribe/features/transactions/domain/transaction_filter.dart';

void main() {
  late DemoController demo;
  late FakeTransactionsRepository transactions;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    transactions = FakeTransactionsRepository(demo: demo);
  });

  TransactionFormBloc build({String? id}) {
    return TransactionFormBloc(
      transactions: transactions,
      accounts: FakeAccountsRepository(demo: demo),
      categories: FakeCategoriesRepository(demo: demo),
      now: () => DateTime(2026, 10, 11, 15, 30),
      id: id,
    );
  }

  /// Starts the form and waits until it can be filled in.
  Future<void> start(TransactionFormBloc bloc) async {
    bloc.add(const TransactionFormStarted());
    await bloc.stream.firstWhere(
      (s) => s.status == TransactionFormStatus.ready,
    );
  }

  /// Fills in what a new transaction needs.
  Future<void> fill(TransactionFormBloc bloc) async {
    await start(bloc);
    bloc
      ..add(const TransactionAmountChanged('1200.50'))
      ..add(const TransactionCategoryChosen('dining'));
  }

  group('a new transaction', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'starts today, as an expense, in the first account',
      build: build,
      act: start,
      verify: (bloc) {
        final values = bloc.state.values;

        expect(bloc.state.isEditing, isFalse);
        expect(values.kind, TransactionKind.expense);
        expect(values.date, DateTime(2026, 10, 11));
        expect(values.accountId, 'card');
        expect(values.categoryId, isNull);
        expect(bloc.state.account?.name, 'Card');
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'can be saved once it has an amount and a category',
      build: build,
      act: fill,
      verify: (bloc) {
        expect(bloc.state.canSave, isTrue);
        expect(bloc.state.isEdited, isTrue);
        expect(bloc.state.draft?.amount, const Money(120050, Currency.rub));
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'cannot be saved with an amount of zero',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const TransactionAmountChanged('0'));
      },
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'knows when the salary is paid in two payments',
      setUp: () =>
          demo.update(const DemoSettings(paymentMode: PaymentMode.twoPayments)),
      build: build,
      act: start,
      verify: (bloc) => expect(bloc.state.twoPayments, isTrue),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'Income offers the categories for income and drops one that does not fit',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionCategoryChosen('groceries'))
          ..add(const TransactionKindSelected(TransactionKind.income));
      },
      verify: (bloc) {
        expect(bloc.state.values.kind, TransactionKind.income);
        expect(bloc.state.values.categoryId, isNull);
        expect(bloc.state.availableCategories.map((category) => category.id), [
          'scholarship',
          'other',
          'gifts',
        ]);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'Income keeps a category that fits both',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionCategoryChosen('other'))
          ..add(const TransactionKindSelected(TransactionKind.income));
      },
      verify: (bloc) => expect(bloc.state.values.categoryId, 'other'),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'the day, the account and the note can be chosen',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(TransactionDateChosen(DateTime(2026, 9, 20, 9)))
          ..add(const TransactionAccountChosen('cash'))
          ..add(const TransactionNoteChanged('Coffee'));
      },
      verify: (bloc) {
        expect(bloc.state.values.date, DateTime(2026, 9, 20));
        expect(bloc.state.account?.name, 'Cash');
        expect(bloc.state.values.note, 'Coffee');
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'saving adds it to the transactions',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const TransactionSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.saveStatus, TransactionFormSaveStatus.saved);
        final page = await transactions.transactions(const TransactionFilter());
        final saved = page.items.firstWhere(
          (item) => item.date == DateTime(2026, 10, 11),
        );
        expect(saved.amount, const Money(120050, Currency.rub));
        expect(saved.categoryId, 'dining');
        expect(saved.accountId, 'card');
        expect(saved.date, DateTime(2026, 10, 11));
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'saving does nothing while it is incomplete',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionSaveRequested());
      },
      verify: (bloc) {
        expect(bloc.state.saveStatus, TransactionFormSaveStatus.idle);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a failed save keeps what was typed and can be tried again',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.failed,
        );
        demo.update(const DemoSettings());
        bloc.add(const TransactionSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, TransactionFormSaveStatus.saved);
        expect(bloc.state.values.amountText, '1200.50');
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'typing after a failed save clears the failure',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.failed,
        );
        bloc.add(const TransactionNoteChanged('x'));
      },
      verify: (bloc) =>
          expect(bloc.state.saveStatus, TransactionFormSaveStatus.idle),
    );
  });

  group('an existing transaction', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'is loaded into the form',
      build: () => build(id: 'seed-groceries'),
      act: start,
      verify: (bloc) {
        final values = bloc.state.values;

        expect(bloc.state.isEditing, isTrue);
        expect(values.kind, TransactionKind.expense);
        expect(values.amountText, '1284.50');
        expect(values.date, DateTime(2026, 10, 5));
        expect(values.categoryId, 'groceries');
        expect(values.accountId, 'card');
        expect(values.note, 'Weekly shopping');
        expect(bloc.state.isEdited, isFalse);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'cannot be saved until something changed',
      build: () => build(id: 'seed-groceries'),
      act: start,
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'can be saved after a change, and keeps its id',
      build: () => build(id: 'seed-groceries'),
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionAmountChanged('1300'))
          ..add(const TransactionSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.saveStatus, TransactionFormSaveStatus.saved);
        final items = (await transactions.transactions(
          const TransactionFilter(),
        )).items;
        expect(items, hasLength(4));
        final saved = items.firstWhere((item) => item.id == 'seed-groceries');
        expect(saved.amount, const Money(130000, Currency.rub));
        // After saving, the form is no longer edited.
        expect(bloc.state.isEdited, isFalse);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'changing it back to what it was is not an edit',
      build: () => build(id: 'seed-groceries'),
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionNoteChanged('x'))
          ..add(const TransactionNoteChanged('Weekly shopping'));
      },
      verify: (bloc) => expect(bloc.state.isEdited, isFalse),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'deleting removes it',
      build: () => build(id: 'seed-taxi'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, TransactionFormDeleteStatus.deleted);
        expect(await transactions.transaction('seed-taxi'), isNull);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a failed delete leaves it',
      build: () => build(id: 'seed-taxi'),
      act: (bloc) async {
        await start(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const TransactionDeleteRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.deleteStatus, TransactionFormDeleteStatus.failed);
        expect(await transactions.transaction('seed-taxi'), isNotNull);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'one that does not exist is not found',
      build: () => build(id: 'missing'),
      act: (bloc) async {
        bloc.add(const TransactionFormStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == TransactionFormStatus.notFound,
        );
      },
      verify: (bloc) =>
          expect(bloc.state.status, TransactionFormStatus.notFound),
    );
  });

  group('an existing transaction on the server', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'keeps the version and the currency it was made in',
      build: () => build(id: 'seed-groceries'),
      act: start,
      verify: (bloc) {
        expect(bloc.state.version, 1);
        expect(bloc.state.currency, Currency.rub);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a transaction in another currency keeps it when changed',
      // The fake gives the first transaction it adds this id.
      build: () => build(id: 'added-1'),
      setUp: () async {
        await transactions.add(
          TransactionDraft(
            amount: const Money(1250, Currency.usd),
            kind: TransactionKind.expense,
            date: DateTime(2026, 10, 24),
            categoryId: 'dining',
            accountId: 'cash',
            note: 'Lunch',
          ),
        );
      },
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionAmountChanged('13.00'))
          ..add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.saved,
        );
      },
      verify: (bloc) async {
        final saved = await transactions.transaction('added-1');
        expect(saved?.amount, const Money(1300, Currency.usd));
        expect(saved?.version, 2);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a change made on another device reloads it and says so',
      build: () => build(id: 'seed-groceries'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionAmountChanged('1300'));
        // Another device changes the note first.
        await transactions.update(
          'seed-groceries',
          TransactionDraft(
            amount: const Money(128450, Currency.rub),
            kind: TransactionKind.expense,
            date: DateTime(2026, 10, 5),
            categoryId: 'groceries',
            accountId: 'card',
            note: 'Changed elsewhere',
          ),
          version: 1,
        );
        bloc.add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) =>
              s.saveStatus == TransactionFormSaveStatus.stale &&
              s.status == TransactionFormStatus.ready &&
              s.version == 2,
        );
      },
      verify: (bloc) {
        expect(bloc.state.values.note, 'Changed elsewhere');
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.version, 2);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'deleting a transaction that changed elsewhere reloads it instead',
      build: () => build(id: 'seed-taxi'),
      act: (bloc) async {
        await start(bloc);
        await transactions.update(
          'seed-taxi',
          TransactionDraft(
            amount: const Money(70000, Currency.rub),
            kind: TransactionKind.expense,
            date: DateTime(2026, 10, 19),
            categoryId: 'transport',
            accountId: 'card',
            note: 'Taxi',
          ),
          version: 1,
        );
        bloc.add(const TransactionDeleteRequested());
        await bloc.stream.firstWhere(
          (s) =>
              s.deleteStatus == TransactionFormDeleteStatus.stale &&
              s.status == TransactionFormStatus.ready &&
              s.version == 2,
        );
      },
      verify: (bloc) async {
        expect(await transactions.transaction('seed-taxi'), isNotNull);
        expect(bloc.state.values.amountText, '700.00');
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'one deleted on another device is not found when it reloads',
      build: () => build(id: 'seed-taxi'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionAmountChanged('1'));
        await transactions.delete('seed-taxi', version: 1);
        bloc.add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.status == TransactionFormStatus.notFound,
        );
      },
      verify: (bloc) =>
          expect(bloc.state.status, TransactionFormStatus.notFound),
    );
  });

  group('a transaction the server refuses', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'a date outside the years it keeps is reported, and what was typed stays',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc
          ..add(TransactionDateChosen(DateTime(2100, 1, 5)))
          ..add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.refused,
        );
      },
      verify: (bloc) {
        expect(bloc.state.refusal, TransactionRefusal.dateOutOfRange);
        expect(bloc.state.values.amountText, '1200.50');
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'the limit of transactions is reported',
      build: () {
        transactions = FakeTransactionsRepository(
          demo: demo,
          maxTransactions: 4,
        );
        return build();
      },
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.refused,
        );
      },
      verify: (bloc) =>
          expect(bloc.state.refusal, TransactionRefusal.limitReached),
    );
  });

  group('loading', () {
    blocTest<TransactionFormBloc, TransactionFormState>(
      'reports no connection and loads again on Retry',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const TransactionFormStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == TransactionFormStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const TransactionFormRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, TransactionFormStatus.ready),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const TransactionFormStarted()),
      verify: (bloc) =>
          expect(bloc.state.status, TransactionFormStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('the payment an income counts toward', () {
    const twoPayments = DemoSettings(paymentMode: PaymentMode.twoPayments);
    // The first payment on the 20th, the second on the 5th of the next month.
    const nearest = PayPart(YearMonth(2026, 9), PeriodScope.secondPart);
    const later = PayPart(YearMonth(2026, 10), PeriodScope.firstPart);

    blocTest<TransactionFormBloc, TransactionFormState>(
      'is chosen for an income in a month paid twice only',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        expect(bloc.state.choosesPart, isFalse, reason: 'an expense');
        bloc.add(const TransactionKindSelected(TransactionKind.income));
      },
      verify: (bloc) => expect(bloc.state.choosesPart, isTrue),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'is not chosen for one payment',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const TransactionKindSelected(TransactionKind.income));
      },
      verify: (bloc) => expect(bloc.state.choosesPart, isFalse),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a chosen payment goes into the draft, and the automatic one clears it',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionAmountChanged('1200.50'))
          ..add(const TransactionCategoryChosen('scholarship'))
          ..add(const TransactionPartChosen(later));
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.draft?.part, later);

        bloc.add(const TransactionPartChosen(null));
      },
      verify: (bloc) {
        expect(bloc.state.values.part, isNull);
        expect(bloc.state.draft?.part, isNull);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a payment that is not around a new day is dropped',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionPartChosen(later))
          ..add(TransactionDateChosen(DateTime(2026, 12, 25)));
      },
      verify: (bloc) => expect(bloc.state.values.part, isNull),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'a payment around the new day stays',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionPartChosen(later))
          ..add(TransactionDateChosen(DateTime(2026, 10, 15)));
      },
      verify: (bloc) => expect(bloc.state.values.part, later),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'turning to an expense drops the choice',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionPartChosen(later))
          ..add(const TransactionKindSelected(TransactionKind.expense));
      },
      verify: (bloc) => expect(bloc.state.values.part, isNull),
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'one payment never sends a chosen payment',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionAmountChanged('1200.50'))
          ..add(const TransactionCategoryChosen('scholarship'))
          ..add(const TransactionPartChosen(later));
      },
      verify: (bloc) {
        expect(bloc.state.draft, isNotNull);
        expect(bloc.state.draft?.part, isNull);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'saving keeps the chosen payment',
      setUp: () => demo.update(twoPayments),
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const TransactionKindSelected(TransactionKind.income))
          ..add(const TransactionAmountChanged('500'))
          ..add(const TransactionCategoryChosen('scholarship'))
          ..add(const TransactionPartChosen(later))
          ..add(const TransactionSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == TransactionFormSaveStatus.saved,
        );
      },
      verify: (bloc) async {
        final saved = (await transactions.transactions(
          const TransactionFilter(),
        )).items.firstWhere((item) => item.id.startsWith('added-'));
        expect(saved.part, later);
      },
    );

    blocTest<TransactionFormBloc, TransactionFormState>(
      'an income that joined the nearest payment loads as automatic',
      setUp: () => demo.update(twoPayments),
      build: () => build(id: 'seed-scholarship'),
      act: start,
      verify: (bloc) => expect(bloc.state.values.part, isNull),
    );

    late String chosenId;

    blocTest<TransactionFormBloc, TransactionFormState>(
      'an income that joined another payment loads as chosen',
      setUp: () async {
        demo.update(twoPayments);
        // The 11th is nearest to the pay day of the 5th, not the 20th.
        final added = await transactions.add(
          TransactionDraft(
            amount: const Money(50000, Currency.rub),
            kind: TransactionKind.income,
            date: DateTime(2026, 10, 11),
            categoryId: 'scholarship',
            accountId: 'card',
            part: later,
          ),
        );
        chosenId = added.id;
      },
      build: () => build(id: chosenId),
      act: start,
      verify: (bloc) {
        expect(nearest, isNot(later));
        expect(bloc.state.values.part, later);
        expect(bloc.state.isEdited, isFalse);
      },
    );
  });
}
