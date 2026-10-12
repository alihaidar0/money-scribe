import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/features/settings/bloc/csv_import_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

void main() {
  late DemoController demo;
  late FakeCsvTransferRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeCsvTransferRepository(demo: demo);
  });

  CsvImportBloc build() => CsvImportBloc(repository: repository);

  test('starts while the picker opens', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, CsvImportStatus.choosing);
    expect(bloc.state.file, isNull);
  });

  group('CsvImportStarted', () {
    blocTest<CsvImportBloc, CsvImportState>(
      'has the chosen file ready',
      build: build,
      act: (bloc) => bloc.add(const CsvImportStarted()),
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.ready);
        expect(bloc.state.file, FakeCsvTransferRepository.files.first);
      },
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'reports no connection and tries the picker again on Try again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CsvImportStarted()),
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.noConnection);
        expect(bloc.state.failedAction, const CsvImportStarted());
      },
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'reports a server failure and the error',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      act: (bloc) => bloc.add(const CsvImportStarted()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, CsvImportStatus.failure),
    );
  });

  group('CsvFileRequested', () {
    blocTest<CsvImportBloc, CsvImportState>(
      'chooses another file',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvFileRequested());
      },
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.ready);
        expect(bloc.state.file, FakeCsvTransferRepository.files.last);
      },
    );
  });

  group('CsvImportConfirmed', () {
    blocTest<CsvImportBloc, CsvImportState>(
      'imports the rows and lists those that were skipped',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvImportConfirmed());
      },
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.imported);
        expect(bloc.state.result?.imported, 40);
        expect(bloc.state.result?.skipped, 2);
        expect(bloc.state.result?.problems, FakeCsvTransferRepository.problems);
      },
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'a file with no problem skips nothing',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvFileRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CsvImportConfirmed());
      },
      verify: (bloc) {
        expect(bloc.state.result?.imported, 12);
        expect(bloc.state.result?.skipped, 0);
      },
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'does nothing without a file',
      build: build,
      act: (bloc) => bloc.add(const CsvImportConfirmed()),
      expect: () => <CsvImportState>[],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'a failure keeps the file, and Try again imports it again',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings(scenario: DemoScenario.noConnection));
        bloc.add(const CsvImportConfirmed());
        await Future<void>.delayed(Duration.zero);
        expect(bloc.state.status, CsvImportStatus.noConnection);
        expect(bloc.state.file, isNotNull);
        expect(bloc.state.failedAction, const CsvImportConfirmed());

        demo.update(const DemoSettings());
        bloc.add(bloc.state.failedAction!);
      },
      verify: (bloc) => expect(bloc.state.status, CsvImportStatus.imported),
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'reports a server failure and the error',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await Future<void>.delayed(Duration.zero);
        demo.update(const DemoSettings(scenario: DemoScenario.error));
        bloc.add(const CsvImportConfirmed());
      },
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, CsvImportStatus.failure),
    );
  });

  test('the import result counts the skipped rows', () {
    const result = CsvImportResult(
      imported: 3,
      problems: [CsvProblem(row: 2, kind: CsvProblemKind.missingDate)],
    );

    expect(result.skipped, 1);
  });
}
