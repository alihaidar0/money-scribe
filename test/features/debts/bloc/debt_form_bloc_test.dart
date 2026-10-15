import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/debts/debt_enums.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/core/money/currency.dart';
import 'package:money_scribe/core/money/money.dart';
import 'package:money_scribe/features/debts/bloc/debt_form_bloc.dart';
import 'package:money_scribe/features/debts/data/fake/fake_debts_repository.dart';

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
}
