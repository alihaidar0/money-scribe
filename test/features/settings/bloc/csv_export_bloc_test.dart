import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/bloc/csv_export_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

void main() {
  late DemoController demo;
  late FakeCsvTransferRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeCsvTransferRepository(demo: demo);
  });

  CsvExportBloc build() {
    return CsvExportBloc(
      repository: repository,
      now: () => DateTime(2026, 10, 11),
    );
  }

  test('starts with everything chosen, for all time', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.kinds, CsvDataKind.values.toSet());
    expect(bloc.state.period, CsvPeriod.allTime);
    expect(bloc.state.canExport, isTrue);
  });

  group('the kinds', () {
    blocTest<CsvExportBloc, CsvExportState>(
      'a kind is ticked and unticked',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvKindToggled(CsvDataKind.debts))
        ..add(const CsvKindToggled(CsvDataKind.debts)),
      verify: (bloc) => expect(bloc.state.kinds, CsvDataKind.values.toSet()),
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'nothing chosen cannot be exported',
      build: build,
      act: (bloc) {
        for (final kind in CsvDataKind.values) {
          bloc.add(CsvKindToggled(kind));
        }
      },
      verify: (bloc) {
        expect(bloc.state.kinds, isEmpty);
        expect(bloc.state.canExport, isFalse);
      },
    );
  });

  group('a custom period', () {
    blocTest<CsvExportBloc, CsvExportState>(
      'needs both days',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvPeriodSelected(CsvPeriod.custom))
        ..add(CsvDatesChosen(from: DateTime(2026, 3))),
      verify: (bloc) => expect(bloc.state.canExport, isFalse),
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'cannot end before it starts',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvPeriodSelected(CsvPeriod.custom))
        ..add(CsvDatesChosen(from: DateTime(2026, 5), to: DateTime(2026, 3))),
      verify: (bloc) {
        expect(bloc.state.hasReversedDates, isTrue);
        expect(bloc.state.canExport, isFalse);
      },
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'with both days in order can be exported',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvPeriodSelected(CsvPeriod.custom))
        ..add(CsvDatesChosen(from: DateTime(2026, 3), to: DateTime(2026, 5))),
      verify: (bloc) {
        expect(bloc.state.hasReversedDates, isFalse);
        expect(bloc.state.canExport, isTrue);
      },
    );
  });

  group('CsvExportRequested', () {
    blocTest<CsvExportBloc, CsvExportState>(
      'exports everything for all time',
      build: build,
      act: (bloc) => bloc.add(const CsvExportRequested()),
      verify: (bloc) {
        expect(bloc.state.status, CsvExportStatus.exported);
        expect(
          repository.lastExport,
          CsvExportRequest(
            kinds: CsvDataKind.values.toSet(),
            period: CsvPeriod.allTime,
          ),
        );
      },
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'this year covers January to December of the year of today',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvKindToggled(CsvDataKind.salaryMonths))
        ..add(const CsvPeriodSelected(CsvPeriod.thisYear))
        ..add(const CsvExportRequested()),
      verify: (bloc) {
        expect(
          repository.lastExport,
          CsvExportRequest(
            kinds: const {CsvDataKind.transactions, CsvDataKind.debts},
            period: CsvPeriod.thisYear,
            from: DateTime(2026),
            to: DateTime(2026, 12, 31),
          ),
        );
      },
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'a custom period is exported with its days',
      build: build,
      act: (bloc) => bloc
        ..add(const CsvPeriodSelected(CsvPeriod.custom))
        ..add(
          CsvDatesChosen(from: DateTime(2026, 3), to: DateTime(2026, 5, 31)),
        )
        ..add(const CsvExportRequested()),
      verify: (bloc) {
        expect(repository.lastExport?.from, DateTime(2026, 3));
        expect(repository.lastExport?.to, DateTime(2026, 5, 31));
      },
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'does nothing while the choices cannot be exported',
      build: build,
      act: (bloc) async {
        for (final kind in CsvDataKind.values) {
          bloc.add(CsvKindToggled(kind));
        }
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvExportRequested());
      },
      verify: (bloc) {
        expect(bloc.state.status, CsvExportStatus.editing);
        expect(repository.lastExport, isNull);
      },
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'reports no connection',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CsvExportRequested()),
      verify: (bloc) => expect(bloc.state.status, CsvExportStatus.noConnection),
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const CsvExportRequested()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, CsvExportStatus.failure),
    );

    blocTest<CsvExportBloc, CsvExportState>(
      'a change after a failure starts a new try',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) async {
        bloc.add(const CsvExportRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvKindToggled(CsvDataKind.debts));
      },
      verify: (bloc) => expect(bloc.state.status, CsvExportStatus.editing),
    );
  });
}
