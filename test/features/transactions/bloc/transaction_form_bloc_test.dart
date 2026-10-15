import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/core/payments/payment_mode.dart';
import 'package:money_scribe/features/transactions/bloc/transaction_form_bloc.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_accounts_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_categories_repository.dart';
import 'package:money_scribe/features/transactions/data/fake/fake_transactions_repository.dart';
import 'package:money_scribe/features/transactions/domain/transaction.dart';

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
        final saved = (await transactions.transactions()).last;
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
        final items = await transactions.transactions();
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
}
