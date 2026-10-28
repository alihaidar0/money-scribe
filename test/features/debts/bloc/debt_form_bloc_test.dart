import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/bloc/debt_form_bloc.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';
import 'package:money_scribe/features/debts/domain/debt.dart';

Money rub(int rubles) => Money(rubles * 100, Currency.rub);

void main() {
  late DemoController demo;
  late FakeDebtsRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeDebtsRepository(demo: demo);
  });

  DebtFormBloc build({String? id}) {
    return DebtFormBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11, 12),
      id: id,
    );
  }

  /// Starts the form and waits until it can be filled in.
  Future<void> start(DebtFormBloc bloc) async {
    bloc.add(const DebtFormStarted());
    await bloc.stream.firstWhere((s) => s.status == DebtFormStatus.ready);
  }

  /// Fills in what a new debt needs.
  Future<void> fill(DebtFormBloc bloc) async {
    await start(bloc);
    bloc
      ..add(const DebtPersonChanged('Lee'))
      ..add(const DebtAmountChanged('1500'));
  }

  group('a new debt', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'starts today, as money lent',
      build: build,
      act: start,
      verify: (bloc) {
        expect(bloc.state.isEditing, isFalse);
        expect(bloc.state.values.direction, DebtDirection.lent);
        expect(bloc.state.values.startDate, DateTime(2026, 10, 11));
        expect(bloc.state.values.dueDate, isNull);
        expect(bloc.state.isEdited, isFalse);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'can be saved once it has a person and an amount',
      build: build,
      act: fill,
      verify: (bloc) {
        expect(bloc.state.canSave, isTrue);
        expect(bloc.state.draft?.person, 'Lee');
        expect(bloc.state.draft?.amount, rub(1500));
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'cannot be saved without a person',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtAmountChanged('1500'));
      },
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'the direction, the days and the note can be chosen',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const DebtDirectionSelected(DebtDirection.borrowed))
          ..add(DebtStartDateChosen(DateTime(2026, 10, 1, 8)))
          ..add(DebtDueDateChosen(DateTime(2026, 10, 31, 20)))
          ..add(const DebtNoteChanged('Lunch'));
      },
      verify: (bloc) {
        final values = bloc.state.values;

        expect(values.direction, DebtDirection.borrowed);
        expect(values.startDate, DateTime(2026, 10));
        expect(values.dueDate, DateTime(2026, 10, 31));
        expect(values.note, 'Lunch');
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'the due day can be taken away again',
      build: build,
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(DebtDueDateChosen(DateTime(2026, 10, 31)))
          ..add(const DebtDueDateCleared());
      },
      verify: (bloc) => expect(bloc.state.values.dueDate, isNull),
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'cannot be due before it starts',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(DebtDueDateChosen(DateTime(2026, 10)));
      },
      verify: (bloc) {
        expect(bloc.state.dueBeforeStart, isTrue);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'saving adds it to the debts',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.saved);
        final saved = (await repository.debts()).last;
        expect(saved.person, 'Lee');
        expect(saved.amount, rub(1500));
        expect(saved.startDate, DateTime(2026, 10, 11));
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'a failed save keeps what was typed and can be tried again',
      build: build,
      act: (bloc) async {
        await fill(bloc);
        demo.update(const DemoSettings(save: DemoSave.fails));
        bloc.add(const DebtSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == DebtFormSaveStatus.failed,
        );
        demo.update(const DemoSettings());
        bloc.add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.saved);
        expect(bloc.state.values.person, 'Lee');
      },
    );
  });

  group('an existing debt', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'is loaded into the form',
      build: () => build(id: 'sam'),
      act: start,
      verify: (bloc) {
        final values = bloc.state.values;

        expect(bloc.state.isEditing, isTrue);
        expect(values.person, 'Sam');
        expect(values.amountText, '10000.00');
        expect(values.direction, DebtDirection.lent);
        expect(values.startDate, DateTime(2026, 10));
        expect(values.dueDate, DateTime(2026, 10, 31));
        expect(values.note, 'Lunch money');
        expect(bloc.state.repaid, rub(4000));
        expect(bloc.state.isEdited, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'can have its direction corrected, and then be saved',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtDirectionSelected(DebtDirection.borrowed));
      },
      verify: (bloc) {
        expect(bloc.state.values.direction, DebtDirection.borrowed);
        expect(bloc.state.isEdited, isTrue);
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'cannot be saved until something changed',
      build: () => build(id: 'sam'),
      act: start,
      verify: (bloc) => expect(bloc.state.canSave, isFalse),
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'the amount cannot fall below what was repaid',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtAmountChanged('3999.99'));
      },
      verify: (bloc) {
        expect(bloc.state.amountBelowRepaid, isTrue);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'the amount can be exactly what was repaid',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtAmountChanged('4000'));
      },
      verify: (bloc) {
        expect(bloc.state.amountBelowRepaid, isFalse);
        expect(bloc.state.canSave, isTrue);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'saving changes the debt and keeps its repayments',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc
          ..add(const DebtPersonChanged('Samuel'))
          ..add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.saved);
        final saved = await repository.debt('sam');
        expect(saved?.person, 'Samuel');
        expect(saved?.repayments, hasLength(1));
        expect(bloc.state.isEdited, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'one that does not exist is not found',
      build: () => build(id: 'missing'),
      act: (bloc) => bloc.add(const DebtFormStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtFormStatus.notFound),
    );
  });

  group('loading', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'reports no connection and loads again on Retry',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: () => build(id: 'sam'),
      act: (bloc) async {
        bloc.add(const DebtFormStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == DebtFormStatus.noConnection,
        );
        demo.update(const DemoSettings());
        bloc.add(const DebtFormRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) => expect(bloc.state.status, DebtFormStatus.ready),
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: () => build(id: 'sam'),
      act: (bloc) => bloc.add(const DebtFormStarted()),
      verify: (bloc) => expect(bloc.state.status, DebtFormStatus.failure),
      errors: () => [isA<ServerException>()],
    );
  });

  group('the currency', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'a new debt is in the default currency of the account',
      setUp: () => repository = FakeDebtsRepository(
        demo: demo,
        defaultCurrency: () async => Currency.usd,
      ),
      build: build,
      act: fill,
      verify: (bloc) {
        expect(bloc.state.currency, Currency.usd);
        expect(bloc.state.draft?.amount, const Money(150000, Currency.usd));
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'a new debt waits for the default currency, and asks again on Retry',
      setUp: () {
        var calls = 0;
        repository = FakeDebtsRepository(
          demo: demo,
          defaultCurrency: () async {
            if (calls++ == 0) throw const NoConnectionException();
            return Currency.eur;
          },
        );
      },
      build: build,
      act: (bloc) async {
        bloc.add(const DebtFormStarted());
        await bloc.stream.firstWhere(
          (s) => s.status == DebtFormStatus.noConnection,
        );
        bloc.add(const DebtFormRetried());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.status, DebtFormStatus.ready);
        expect(bloc.state.currency, Currency.eur);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'a debt being changed keeps its own, whatever the default is',
      setUp: () => repository = FakeDebtsRepository(
        demo: demo,
        defaultCurrency: () async => Currency.usd,
      ),
      build: () => build(id: 'sam'),
      act: start,
      verify: (bloc) {
        expect(bloc.state.currency, Currency.rub);
        expect(bloc.state.version, 1);
      },
    );
  });

  group('the start day of a debt with repayments', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'cannot go past the last repayment',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(DebtStartDateChosen(DateTime(2026, 10, 13)));
      },
      verify: (bloc) {
        expect(bloc.state.lastRepaymentDate, DateTime(2026, 10, 12));
        expect(bloc.state.startAfterRepayment, isTrue);
        expect(bloc.state.canSave, isFalse);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'can be the day of the last repayment',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(DebtStartDateChosen(DateTime(2026, 10, 12)));
      },
      verify: (bloc) {
        expect(bloc.state.startAfterRepayment, isFalse);
        expect(bloc.state.canSave, isTrue);
      },
    );
  });

  group('what the server says to Save', () {
    blocTest<DebtFormBloc, DebtFormState>(
      'a debt changed on another device is not overwritten, and is read again',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtPersonChanged('Samuel'));
        // Another device changes the debt first.
        final sam = (await repository.debt('sam'))!;
        await repository.update(
          'sam',
          DebtDraft(
            direction: sam.direction,
            person: sam.person,
            amount: sam.amount,
            startDate: sam.startDate,
            dueDate: sam.dueDate,
            note: 'Other',
          ),
          version: 1,
        );
        bloc.add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) async {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.stale);
        expect((await repository.debt('sam'))?.person, 'Sam');
        // What the server holds now is on the form, at its new version.
        expect(bloc.state.status, DebtFormStatus.ready);
        expect(bloc.state.values.note, 'Other');
        expect(bloc.state.values.person, 'Sam');
        expect(bloc.state.version, 2);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'a refusal is kept with what was typed',
      setUp: () => repository = FakeDebtsRepository(demo: demo, maxDebts: 3),
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.refused);
        expect(bloc.state.refusal, DebtRefusal.limitReached);
        expect(bloc.state.values.person, 'Lee');
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'editing after a refusal clears it',
      setUp: () => repository = FakeDebtsRepository(demo: demo, maxDebts: 3),
      build: build,
      act: (bloc) async {
        await fill(bloc);
        bloc.add(const DebtSaveRequested());
        await bloc.stream.firstWhere(
          (s) => s.saveStatus == DebtFormSaveStatus.refused,
        );
        bloc.add(const DebtNoteChanged('x'));
      },
      verify: (bloc) {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.idle);
        expect(bloc.state.refusal, isNull);
      },
    );

    blocTest<DebtFormBloc, DebtFormState>(
      'more repaid elsewhere than the new amount is a refusal',
      build: () => build(id: 'sam'),
      act: (bloc) async {
        await start(bloc);
        bloc.add(const DebtAmountChanged('4500'));
        // Another device repays more than the form knows of.
        await repository.addRepayment(
          'sam',
          RepaymentDraft(amount: rub(1000), date: DateTime(2026, 10, 14)),
        );
        bloc.add(const DebtSaveRequested());
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.saveStatus, DebtFormSaveStatus.refused);
        expect(bloc.state.refusal, DebtRefusal.amountBelowRepaid);
      },
    );
  });
}
