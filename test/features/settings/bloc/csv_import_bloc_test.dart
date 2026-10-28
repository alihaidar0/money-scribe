import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_scribe/core/demo/demo_settings.dart';
import 'package:money_scribe/core/errors/data_exception.dart';
import 'package:money_scribe/features/settings/bloc/csv_import_bloc.dart';
import 'package:money_scribe/features/settings/data/fake/fake_csv_transfer_repository.dart';
import 'package:money_scribe/features/settings/domain/csv_transfer.dart';

/// A picker that is closed without a choice.
class _ClosedPicker extends FakeCsvTransferRepository {
  new({required super.demo});

  bool closed = false;

  @override
  Future<CsvFile?> chooseFile() {
    if (closed) return Future.value();
    return super.chooseFile();
  }
}

/// A file that is too long to import.
class _LongFile extends FakeCsvTransferRepository {
  new({required super.demo});

  @override
  Future<CsvFile?> chooseFile() async {
    throw const CsvFileException(CsvFileIssue.tooManyRows, limit: 20000);
  }
}

/// An import that sends its rows in steps and stops once, the way the server
/// does with a lost connection.
class _StoppingImport extends FakeCsvTransferRepository {
  new({required super.demo});

  int calls = 0;

  @override
  Future<CsvImportResult> import(
    CsvFile file, {
    void Function(int rowsDone)? onProgress,
  }) async {
    calls++;
    onProgress?.call(20);
    if (calls == 1) throw const NoConnectionException();
    onProgress?.call(file.rows);
    return CsvImportResult(imported: file.rows);
  }
}

void main() {
  late DemoController demo;
  late FakeCsvTransferRepository repository;

  setUp(() {
    demo = DemoController(latency: Duration.zero);
    repository = FakeCsvTransferRepository(demo: demo);
  });

  CsvImportBloc build() => CsvImportBloc(repository: repository);

  final first = FakeCsvTransferRepository.files.first;

  test('starts while the picker opens', () {
    final bloc = build();
    addTearDown(bloc.close);

    expect(bloc.state.status, CsvImportStatus.choosing);
    expect(bloc.state.file, isNull);
  });

  group('choosing a file', () {
    blocTest<CsvImportBloc, CsvImportState>(
      'checks the chosen file and has its estimate ready',
      build: build,
      act: (bloc) => bloc.add(const CsvImportStarted()),
      expect: () => [
        const CsvImportState(),
        CsvImportState(status: CsvImportStatus.checking, file: first),
        CsvImportState(
          status: CsvImportStatus.ready,
          file: first,
          estimate: const CsvImportResult(imported: 42),
        ),
      ],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'says why a file cannot be imported, before anything is sent',
      build: () => CsvImportBloc(repository: _LongFile(demo: demo)),
      act: (bloc) => bloc.add(const CsvImportStarted()),
      expect: () => const [
        CsvImportState(),
        CsvImportState(
          status: CsvImportStatus.fileProblem,
          fileIssue: CsvFileIssue.tooManyRows,
          fileLimit: 20000,
        ),
      ],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'chooses another file',
      build: build,
      act: (bloc) async {
        bloc.add(const CsvImportStarted());
        await bloc.stream.firstWhere((s) => s.status == CsvImportStatus.ready);
        bloc.add(const CsvFileRequested());
      },
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.ready);
        expect(bloc.state.file, FakeCsvTransferRepository.files[1]);
      },
    );

    test('closing the picker keeps the file chosen before', () async {
      final picker = _ClosedPicker(demo: demo);
      final bloc = CsvImportBloc(repository: picker);
      addTearDown(bloc.close);
      bloc.add(const CsvImportStarted());
      final ready = await bloc.stream.firstWhere(
        (s) => s.status == CsvImportStatus.ready,
      );

      picker.closed = true;
      bloc.add(const CsvFileRequested());
      await pumpEventQueue();

      expect(bloc.state, ready);
    });

    blocTest<CsvImportBloc, CsvImportState>(
      'closing it with nothing chosen before says so',
      build: () =>
          CsvImportBloc(repository: _ClosedPicker(demo: demo)..closed = true),
      act: (bloc) => bloc.add(const CsvImportStarted()),
      expect: () => const [
        CsvImportState(),
        CsvImportState(status: CsvImportStatus.noFile),
      ],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'reports no connection, and Try again opens the picker again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      act: (bloc) => bloc.add(const CsvImportStarted()),
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.noConnection);
        expect(bloc.state.failedAction, const CsvImportStarted());
      },
    );
  });

  group('CsvCheckRequested', () {
    blocTest<CsvImportBloc, CsvImportState>(
      'checks the chosen file again',
      build: build,
      seed: () => CsvImportState(
        status: CsvImportStatus.noConnection,
        file: first,
        failedAction: const CsvCheckRequested(),
      ),
      act: (bloc) => bloc.add(const CsvCheckRequested()),
      expect: () => [
        CsvImportState(status: CsvImportStatus.checking, file: first),
        CsvImportState(
          status: CsvImportStatus.ready,
          file: first,
          estimate: const CsvImportResult(imported: 42),
        ),
      ],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'a failure keeps the file and asks to check it again',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.noConnection)),
      build: build,
      seed: () => CsvImportState(status: CsvImportStatus.ready, file: first),
      act: (bloc) => bloc.add(const CsvCheckRequested()),
      verify: (bloc) {
        expect(bloc.state.status, CsvImportStatus.noConnection);
        expect(bloc.state.file, first);
        expect(bloc.state.failedAction, const CsvCheckRequested());
      },
    );
  });

  group('CsvImportConfirmed', () {
    final ready = CsvImportState(
      status: CsvImportStatus.ready,
      file: first,
      estimate: const CsvImportResult(imported: 42),
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'imports the rows, with the progress, and lists those skipped',
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const CsvImportConfirmed()),
      expect: () => [
        CsvImportState(
          status: CsvImportStatus.importing,
          file: first,
          estimate: const CsvImportResult(imported: 42),
        ),
        CsvImportState(
          status: CsvImportStatus.importing,
          file: first,
          estimate: const CsvImportResult(imported: 42),
          rowsDone: 42,
        ),
        CsvImportState(
          status: CsvImportStatus.imported,
          file: first,
          result: const CsvImportResult(
            imported: 38,
            problems: FakeCsvTransferRepository.problems,
          ),
        ),
      ],
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'does nothing without a checked file',
      build: build,
      act: (bloc) => bloc.add(const CsvImportConfirmed()),
      expect: () => <CsvImportState>[],
    );

    late _StoppingImport stopping;
    final seen = <CsvImportState>[];

    blocTest<CsvImportBloc, CsvImportState>(
      'Try again after a stop goes on, from the rows already sent',
      setUp: () {
        stopping = _StoppingImport(demo: demo);
        seen.clear();
      },
      build: () => CsvImportBloc(repository: stopping),
      seed: () => ready,
      act: (bloc) async {
        bloc.add(const CsvImportConfirmed());
        final stopped = await bloc.stream.firstWhere(
          (s) => s.status == CsvImportStatus.noConnection,
        );
        seen.add(stopped);
        bloc.add(stopped.failedAction!);
        seen.add(
          await bloc.stream.firstWhere(
            (s) => s.status == CsvImportStatus.importing,
          ),
        );
      },
      verify: (bloc) {
        final [stopped, resumed] = seen;
        expect(stopped.file, first);
        expect(stopped.rowsDone, 20);
        expect(stopped.failedAction, const CsvImportConfirmed());
        expect(resumed.rowsDone, 20);
        expect(bloc.state.status, CsvImportStatus.imported);
        expect(bloc.state.result?.imported, 42);
        expect(stopping.calls, 2);
      },
    );

    blocTest<CsvImportBloc, CsvImportState>(
      'a server failure is said, and the error reported',
      setUp: () =>
          demo.update(const DemoSettings(scenario: DemoScenario.error)),
      build: build,
      seed: () => ready,
      act: (bloc) => bloc.add(const CsvImportConfirmed()),
      errors: () => [isA<Exception>()],
      verify: (bloc) => expect(bloc.state.status, CsvImportStatus.failure),
    );
  });

  test('a result says whether its problems are in several parts', () {
    const one = CsvImportResult(
      imported: 3,
      problems: [
        CsvProblem(
          kind: CsvDataKind.debts,
          row: 2,
          reason: CsvProblemReason.missingDate,
        ),
      ],
    );
    const two = CsvImportResult(
      imported: 3,
      problems: [
        CsvProblem(
          kind: CsvDataKind.debts,
          row: 2,
          reason: CsvProblemReason.missingDate,
        ),
        CsvProblem(
          kind: CsvDataKind.salaryMonths,
          row: 2,
          reason: CsvProblemReason.duplicate,
        ),
      ],
    );

    expect(one.skipped, 1);
    expect(one.spansParts, isFalse);
    expect(two.spansParts, isTrue);
  });
}
